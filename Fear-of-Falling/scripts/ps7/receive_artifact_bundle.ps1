#requires -Version 7.4
<#
Receive a strict POSIX USTAR bundle into a new staging run. No import or cleanup.
Bundle: transfer-manifest.jsonl plus payload/<FOF-relative path>, regular files only.
JSONL rows have exactly path (string), sha256 (lowercase hex), size (integer).
The staging root must already exist and be controlled by the receiving user.
Use -BundlePath for local tests; otherwise binary standard input is consumed.
This script and all staging ancestors must be protected from concurrent writers.
#>
[CmdletBinding()]
param(
    [string]$StagingDir = $env:WINDOWS_STAGING_DIR,
    [string]$BundlePath,
    [string]$TransferId,
    [long]$MaxBundleBytes = 1073741824
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8 = [Text.UTF8Encoding]::new($false, $true)

function Assert-SafePath([string]$Path) {
    if ([string]::IsNullOrEmpty($Path) -or $Path -cne $Path.Trim() -or
        $Path -cne $Path.Normalize([Text.NormalizationForm]::FormC)) { throw 'Unsafe path' }
    foreach ($part in $Path.Split('/')) {
        if ($part -in @('', '.', '..') -or $part.EndsWith('.') -or $part.EndsWith(' ') -or
            $part -match '[\x00-\x1f\x7f\\:<>"|*?\[\]]' -or
            $part -match '^(con|prn|aux|nul|com[0-9]|lpt[0-9])(?:\.|$)') { throw 'Unsafe path' }
        if ($part -match '^(data|dataset|raw_data|external_data|\.git|\.ssh|\.aws|\.azure)$' -or
            $part -match 'secret|credential' -or $part -match '^\.env(?:\.|$)' -or
            $part -match '^\.(renviron|netrc|npmrc)$' -or
            $part -match '^id_(rsa|ed25519|ecdsa|dsa)' -or
            $part -match '\.(rdata|rda|rds|sqlite3?|db|sav|dta|xlsx?|pem|key|secret|p12|pfx|kdbx|r|py|sh|ps1)$') {
            throw 'Hard-denied path'
        }
    }
    if ($Path -match '\.csv$' -and 'outputs' -cnotin $Path.Split('/')[0..($Path.Split('/').Count - 2)]) {
        throw 'CSV outside outputs'
    }
}

function Assert-NoReparse([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    while ($null -ne $current) {
        if ([IO.File]::Exists($current) -or [IO.Directory]::Exists($current)) {
            if (([IO.File]::GetAttributes($current) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'Reparse point rejected'
            }
        }
        $parent = [IO.Directory]::GetParent($current)
        $current = if ($null -eq $parent) { $null } else { $parent.FullName }
    }
}

function Read-Block([IO.Stream]$Stream) {
    $block = [byte[]]::new(512)
    $n = 0
    while ($n -lt 512) {
        $got = $Stream.Read($block, $n, 512 - $n)
        if ($got -eq 0) { throw 'Partial tar block' }
        $n += $got
    }
    return ,$block
}

function Test-Zero([byte[]]$Block) {
    foreach ($b in $Block) { if ($b -ne 0) { return $false } }
    return $true
}

function Get-TarText([byte[]]$Block, [int]$Start, [int]$Count) {
    $bytes = $Block[$Start..($Start + $Count - 1)]
    $zero = [Array]::IndexOf($bytes, [byte]0)
    if ($zero -ge 0) {
        for ($i = $zero; $i -lt $Count; $i++) {
            if ($bytes[$i] -ne 0) { throw 'Nonzero bytes after tar field terminator' }
        }
        if ($zero -eq 0) { return '' }
        $bytes = $bytes[0..($zero - 1)]
    }
    return $utf8.GetString([byte[]]$bytes)
}

function Get-Octal([byte[]]$Block, [int]$Start, [int]$Count) {
    $s = [Text.Encoding]::ASCII.GetString($Block, $Start, $Count).Trim([char[]]@([char]0, [char]32))
    if ($s -notmatch '^[0-7]+$') { throw 'Invalid tar octal field' }
    return [Convert]::ToInt64($s, 8)
}

function Copy-Count([IO.Stream]$From, [IO.Stream]$To, [long]$Count) {
    $buffer = [byte[]]::new(65536)
    while ($Count -gt 0) {
        $n = $From.Read($buffer, 0, [int][Math]::Min($buffer.Length, $Count))
        if ($n -eq 0) { throw 'Partial file body' }
        $To.Write($buffer, 0, $n)
        $Count -= $n
    }
}

$archive = $null
$run = $null
$runId = $null
$ownsRun = $false
$published = $false
try {
    if ([string]::IsNullOrWhiteSpace($StagingDir) -or -not [IO.Path]::IsPathFullyQualified($StagingDir) -or
        -not [IO.Directory]::Exists($StagingDir) -or $MaxBundleBytes -lt 1024) {
        throw 'An existing absolute staging root and valid size limit are required'
    }
    Assert-NoReparse $StagingDir
    $incoming = [IO.Path]::Combine($StagingDir, 'incoming')
    Assert-NoReparse $incoming
    [void][IO.Directory]::CreateDirectory($incoming)
    if ($TransferId -and $TransferId -cnotmatch '^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}$') { throw 'Invalid transfer ID' }
    $runId = if ($TransferId) { $TransferId } else {
        [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [Guid]::NewGuid().ToString('N')
    }
    $run = [IO.Path]::Combine($incoming, $runId)
    # The CreateNew claim arbitrates concurrent invocations. It is retained.
    $claim = [IO.File]::Open($run + '.claim', [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    $claim.Dispose()
    if (Test-Path -LiteralPath $run) { throw 'Run already exists' }
    [void][IO.Directory]::CreateDirectory($run)
    $ownsRun = $true
    $archivePath = [IO.Path]::Combine($run, 'bundle.tar')
    $archive = [IO.File]::Open($archivePath, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $inputStream = if ($BundlePath) { [IO.File]::OpenRead($BundlePath) } else { [Console]::OpenStandardInput() }
    try {
        $buffer = [byte[]]::new(65536)
        while (($n = $inputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            if ($archive.Length + $n -gt $MaxBundleBytes) { throw 'Bundle size limit exceeded' }
            $archive.Write($buffer, 0, $n)
        }
    } finally { $inputStream.Dispose() }
    if ($archive.Length -lt 1024 -or $archive.Length % 512 -ne 0) { throw 'Partial tar' }
    $archive.Position = 0
    $entries = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
    # Scan all headers and the complete terminator before any extraction.
    while ($true) {
        $header = Read-Block $archive
        if (Test-Zero $header) {
            if (-not (Test-Zero (Read-Block $archive))) { throw 'Missing tar terminator' }
            while ($archive.Position -lt $archive.Length) {
                if (-not (Test-Zero (Read-Block $archive))) { throw 'Trailing archive data' }
            }
            break
        }
        $expectedChecksum = Get-Octal $header 148 8
        [long]$checksum = 0
        for ($i = 0; $i -lt 512; $i++) { $checksum += $(if ($i -ge 148 -and $i -lt 156) { 32 } else { $header[$i] }) }
        if ($checksum -ne $expectedChecksum -or (Get-TarText $header 257 6) -cne 'ustar' -or
            [Text.Encoding]::ASCII.GetString($header, 263, 2) -cne '00' -or
            $header[156] -notin @(0, 48) -or (Get-TarText $header 157 100) -ne '') {
            throw 'Only regular POSIX USTAR entries are accepted'
        }
        $name = Get-TarText $header 0 100
        $prefix = Get-TarText $header 345 155
        if ($prefix) { $name = $prefix + '/' + $name }
        if ($name -cne 'transfer-manifest.jsonl') {
            if (-not $name.StartsWith('payload/', [StringComparison]::Ordinal)) { throw 'Unexpected archive member' }
            Assert-SafePath $name.Substring(8)
        }
        if ($entries.ContainsKey($name)) { throw 'Duplicate or case-colliding archive member' }
        $size = Get-Octal $header 124 12
        $padded = $size + ((512 - ($size % 512)) % 512)
        if ($padded -gt $archive.Length - $archive.Position - 1024) { throw 'Partial tar member' }
        $entries.Add($name, @{ Path = $name; Size = $size; Offset = $archive.Position })
        $archive.Position += $padded
    }
    if (-not $entries.ContainsKey('transfer-manifest.jsonl')) { throw 'Missing manifest' }
    $manifest = $entries['transfer-manifest.jsonl']
    if ($manifest.Path -cne 'transfer-manifest.jsonl' -or $manifest.Size -gt 16777216) { throw 'Invalid manifest' }
    $memory = [IO.MemoryStream]::new()
    try {
        $archive.Position = $manifest.Offset
        Copy-Count $archive $memory $manifest.Size
        $manifestText = $utf8.GetString($memory.ToArray())
    } finally { $memory.Dispose() }
    $metadata = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($line in $manifestText.Split([char]10)) {
        if ($line -eq '') { continue }
        $doc = [Text.Json.JsonDocument]::Parse($line)
        try {
            $obj = $doc.RootElement
            if ($obj.ValueKind -ne [Text.Json.JsonValueKind]::Object) { throw 'Manifest row must be an object' }
            $keys = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            foreach ($prop in $obj.EnumerateObject()) {
                if (-not $keys.Add($prop.Name)) { throw 'Duplicate JSON key' }
            }
            if ($keys.Count -ne 3 -or -not $keys.Contains('path') -or -not $keys.Contains('sha256') -or -not $keys.Contains('size')) {
                throw 'Unexpected metadata schema'
            }
            $path = $obj.GetProperty('path').GetString()
            $hash = $obj.GetProperty('sha256').GetString()
            $size = $obj.GetProperty('size').GetInt64()
            Assert-SafePath $path
            if ($null -eq $hash -or $hash -cnotmatch '^[0-9a-f]{64}$' -or $size -lt 0) { throw 'Invalid metadata' }
            if ($metadata.ContainsKey($path)) { throw 'Duplicate metadata path' }
            $member = 'payload/' + $path
            if (-not $entries.ContainsKey($member) -or $entries[$member].Path -cne $member -or $entries[$member].Size -ne $size) {
                throw 'Manifest/archive mismatch'
            }
            $metadata.Add($path, @{ Hash = $hash; Size = $size })
        } finally { $doc.Dispose() }
    }
    if ($metadata.Count -eq 0 -or $entries.Count -ne $metadata.Count + 1) { throw 'Empty or inexact archive set' }
    foreach ($entry in $entries.Values) {
        $destination = [IO.Path]::GetFullPath([IO.Path]::Combine($run, $entry.Path))
        if (-not $destination.StartsWith($run + [IO.Path]::DirectorySeparatorChar, [StringComparison]::Ordinal)) { throw 'Path escaped run' }
        Assert-NoReparse $destination
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))
        $out = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $archive.Position = $entry.Offset; Copy-Count $archive $out $entry.Size }
        finally { $out.Dispose() }
    }
    $payload = [IO.Path]::Combine($run, 'payload')
    $received = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($item in Get-ChildItem -LiteralPath $payload -Recurse -Force) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Received reparse point' }
        if ($item.PSIsContainer) { continue }
        $relative = [IO.Path]::GetRelativePath($payload, $item.FullName).Replace('\', '/')
        if (-not $received.Add($relative) -or -not $metadata.ContainsKey($relative)) { throw 'Unexpected received file' }
        if ($item.Length -ne $metadata[$relative].Size -or
            (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash.ToLowerInvariant() -cne $metadata[$relative].Hash) {
            throw 'Received size or SHA-256 mismatch'
        }
    }
    if ($received.Count -ne $metadata.Count) { throw 'Missing received file' }
    $receipt = @{ status = 'VERIFIED'; run_id = $runId; files = $received.Count;
        verified_at = [DateTime]::UtcNow.ToString('o') }
    $bytes = $utf8.GetBytes(($receipt | ConvertTo-Json -Compress) + "`n")
    $out = [IO.File]::Open([IO.Path]::Combine($run, 'receipt.pending'), [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $out.Write($bytes, 0, $bytes.Length); $out.Flush($true) } finally { $out.Dispose() }
    [IO.File]::Move([IO.Path]::Combine($run, 'receipt.pending'), [IO.Path]::Combine($run, 'VERIFIED.json'))
    $published = $true
    # Content verification is durable before the return-channel response.
    Write-Output ($receipt | ConvertTo-Json -Compress)
} catch {
    # Only an owned, not-yet-published run can be positively rejected.
    # A response/output failure after publication must not downgrade the receipt.
    $state = if ($ownsRun -and -not $published) { 'FAILED' } else { 'UNKNOWN_REMOTE_STATE' }
    [Console]::Out.WriteLine((@{ status = $state; run_id = $runId } | ConvertTo-Json -Compress))
    [Console]::Error.WriteLine($state + ': receiver did not return confirmed success.')
    exit 1
} finally {
    if ($null -ne $archive) { $archive.Dispose() }
}
