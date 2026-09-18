#requires -Version 7.4
<#
Receive a strict FOF_ARTIFACT_HANDOFF/2 POSIX USTAR bundle into a new staging run.
The v2 wire format is manifest.json followed by files/<staging_path> members.
The sender supplies TransferId; the manifest and receipt must use that exact id.
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
}

function Assert-SafeSourcePath([string]$Path) {
    Assert-SafePath $Path
    $parts = $Path.Split('/')
    if ($Path -match '\.csv$' -and 'outputs' -cnotin $parts[0..($parts.Count - 2)]) {
        throw 'CSV outside outputs'
    }
}

function Assert-SafeStagingName([string]$Path) {
    Assert-SafePath $Path
    if ($Path.Contains('/')) { throw 'Staging path must be a filename' }
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
    $block = [byte[]]::new(512); $n = 0
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
        $To.Write($buffer, 0, $n); $Count -= $n
    }
}

function Get-Sha256([byte[]]$Bytes) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Get-CanonicalManifestBase([object]$Manifest) {
    $rows = @($Manifest.files | Sort-Object source_path, staging_path)
    $fileRows = @()
    foreach ($row in $rows) {
        $fileRows += [ordered]@{
            sha256 = [string]$row.sha256
            size_bytes = [int64]$row.size_bytes
            source_path = [string]$row.source_path
            staging_path = [string]$row.staging_path
        }
    }
    # Keys are inserted in ASCII order, matching sender sort_keys canonical JSON.
    return [ordered]@{
        files = $fileRows
        profile_id = [string]$Manifest.profile_id
        profile_sha256 = [string]$Manifest.profile_sha256
        profile_version = [string]$Manifest.profile_version
        protocol_version = [string]$Manifest.protocol_version
        source_head = [string]$Manifest.source_head
        source_repository_id = [string]$Manifest.source_repository_id
        workstream = [string]$Manifest.workstream
    }
}

function Get-RunCorrelation([string]$Protocol, [string]$Run, [string]$Content) {
    $value = [ordered]@{ content_digest = $Content; protocol_version = $Protocol; run_id = $Run }
    return Get-Sha256 ([Text.Encoding]::UTF8.GetBytes(($value | ConvertTo-Json -Compress -Depth 10)))
}

$archive = $null; $run = $null; $runId = $TransferId; $ownsRun = $false; $published = $false
$manifestObject = $null; $contentDigest = $null; $runCorrelationDigest = $null
try {
    if ([string]::IsNullOrWhiteSpace($TransferId) -or
        $TransferId -cnotmatch '^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}$') { throw 'TransferId is required for v2' }
    if ([string]::IsNullOrWhiteSpace($StagingDir) -or -not [IO.Path]::IsPathFullyQualified($StagingDir) -or
        -not [IO.Directory]::Exists($StagingDir) -or $MaxBundleBytes -lt 1024) {
        throw 'An existing absolute staging root and valid size limit are required'
    }
    Assert-NoReparse $StagingDir
    $incoming = [IO.Path]::Combine($StagingDir, 'incoming'); Assert-NoReparse $incoming
    [void][IO.Directory]::CreateDirectory($incoming)
    $run = [IO.Path]::Combine($incoming, $TransferId)
    $claim = [IO.File]::Open($run + '.claim', [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    $claim.Dispose()
    if (Test-Path -LiteralPath $run) { throw 'Run already exists' }
    [void][IO.Directory]::CreateDirectory($run); $ownsRun = $true
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
    while ($true) {
        $header = Read-Block $archive
        if (Test-Zero $header) {
            if (-not (Test-Zero (Read-Block $archive))) { throw 'Missing tar terminator' }
            while ($archive.Position -lt $archive.Length) { if (-not (Test-Zero (Read-Block $archive))) { throw 'Trailing archive data' } }
            break
        }
        $expectedChecksum = Get-Octal $header 148 8; [long]$checksum = 0
        for ($i = 0; $i -lt 512; $i++) { $checksum += $(if ($i -ge 148 -and $i -lt 156) { 32 } else { $header[$i] }) }
        if ($checksum -ne $expectedChecksum -or (Get-TarText $header 257 6) -cne 'ustar' -or
            [Text.Encoding]::ASCII.GetString($header, 263, 2) -cne '00' -or
            $header[156] -notin @(0, 48) -or (Get-TarText $header 157 100) -ne '') {
            throw 'Only regular POSIX USTAR entries are accepted'
        }
        $name = Get-TarText $header 0 100; $prefix = Get-TarText $header 345 155
        if ($prefix) { $name = $prefix + '/' + $name }
        if ($name -cne 'manifest.json') {
            if (-not $name.StartsWith('files/', [StringComparison]::Ordinal)) { throw 'Unexpected archive member' }
            Assert-SafePath $name.Substring(6)
        }
        if ($entries.ContainsKey($name)) { throw 'Duplicate or case-colliding archive member' }
        $size = Get-Octal $header 124 12; $padded = $size + ((512 - ($size % 512)) % 512)
        if ($padded -gt $archive.Length - $archive.Position - 1024) { throw 'Partial tar member' }
        $entries.Add($name, @{ Path = $name; Size = $size; Offset = $archive.Position }); $archive.Position += $padded
    }
    if (-not $entries.ContainsKey('manifest.json')) { throw 'Missing manifest' }
    $manifestEntry = $entries['manifest.json']
    if ($manifestEntry.Path -cne 'manifest.json') { throw 'Manifest member casing mismatch' }
    if ($manifestEntry.Size -gt 16777216) { throw 'Invalid manifest' }
    $memory = [IO.MemoryStream]::new()
    try { $archive.Position = $manifestEntry.Offset; Copy-Count $archive $memory $manifestEntry.Size; $manifestText = $utf8.GetString($memory.ToArray()) }
    finally { $memory.Dispose() }
    if ($manifestText.Length -gt 0 -and $manifestText[0] -eq [char]0xFEFF) { throw 'Manifest BOM rejected' }
    $jsonDoc = [Text.Json.JsonDocument]::Parse($manifestText)
    try {
        if ($jsonDoc.RootElement.ValueKind -ne [Text.Json.JsonValueKind]::Object) { throw 'Manifest must be an object' }
        $jsonKeys = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($property in $jsonDoc.RootElement.EnumerateObject()) {
            if (-not $jsonKeys.Add($property.Name)) { throw 'Duplicate manifest key' }
        }
    } finally { $jsonDoc.Dispose() }
    $manifestObject = $manifestText | ConvertFrom-Json
    $required = @('content_digest','files','profile_id','profile_sha256','profile_version','protocol_version','run_correlation_digest','run_id','source_head','source_repository_id','workstream')
    $actual = @($manifestObject.PSObject.Properties.Name)
    $actualKeys = @($actual | Sort-Object) -join ','
    $requiredKeys = @($required | Sort-Object) -join ','
    if ($actualKeys -cne $requiredKeys) { throw 'Manifest schema mismatch' }
    if ($manifestObject.protocol_version -cne 'FOF_ARTIFACT_HANDOFF/2' -or $manifestObject.run_id -cne $TransferId) { throw 'Manifest run/protocol mismatch' }
    foreach ($field in @('content_digest','profile_sha256','run_correlation_digest')) { if ([string]$manifestObject.$field -cnotmatch '^[0-9a-f]{64}$') { throw 'Manifest digest invalid' } }
    if ([string]$manifestObject.source_head -cnotmatch '^[0-9a-f]{40,64}$') { throw 'Manifest source head invalid' }
    $baseJson = Get-CanonicalManifestBase $manifestObject | ConvertTo-Json -Compress -Depth 10
    $contentDigest = Get-Sha256 ([Text.Encoding]::UTF8.GetBytes($baseJson))
    if ($contentDigest -cne $manifestObject.content_digest) { throw 'Manifest content digest mismatch' }
    $runCorrelationDigest = Get-RunCorrelation $manifestObject.protocol_version $TransferId $contentDigest
    if ($runCorrelationDigest -cne $manifestObject.run_correlation_digest) { throw 'Manifest run correlation mismatch' }
    $metadata = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($row in @($manifestObject.files)) {
        $keys = @($row.PSObject.Properties.Name)
        $rowKeys = @($keys | Sort-Object) -join ','
        if ($rowKeys -cne 'sha256,size_bytes,source_path,staging_path') { throw 'Manifest row schema mismatch' }
        Assert-SafeSourcePath ([string]$row.source_path); Assert-SafeStagingName ([string]$row.staging_path)
        if ([string]$row.sha256 -cnotmatch '^[0-9a-f]{64}$' -or [int64]$row.size_bytes -lt 0) { throw 'Manifest row invalid' }
        if ($metadata.ContainsKey([string]$row.staging_path)) { throw 'Duplicate manifest path' }
        $member = 'files/' + [string]$row.staging_path
        if (-not $entries.ContainsKey($member) -or $entries[$member].Path -cne $member -or $entries[$member].Size -ne [int64]$row.size_bytes) { throw 'Manifest/archive mismatch' }
        $metadata.Add([string]$row.staging_path, @{ Hash = [string]$row.sha256; Size = [int64]$row.size_bytes })
    }
    if ($metadata.Count -eq 0 -or $entries.Count -ne $metadata.Count + 1) { throw 'Empty or inexact archive set' }
    foreach ($entry in $entries.Values) {
        $destination = [IO.Path]::GetFullPath([IO.Path]::Combine($run, $entry.Path))
        if (-not $destination.StartsWith($run + [IO.Path]::DirectorySeparatorChar, [StringComparison]::Ordinal)) { throw 'Path escaped run' }
        Assert-NoReparse $destination; [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))
        $out = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $archive.Position = $entry.Offset; Copy-Count $archive $out $entry.Size } finally { $out.Dispose() }
    }
    $payload = [IO.Path]::Combine($run, 'files'); $received = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($item in Get-ChildItem -LiteralPath $payload -Recurse -Force) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Received reparse point' }
        if ($item.PSIsContainer) { continue }
        $relative = [IO.Path]::GetRelativePath($payload, $item.FullName).Replace('\', '/')
        if (-not $received.Add($relative) -or -not $metadata.ContainsKey($relative)) { throw 'Unexpected received file' }
        if ($item.Length -ne $metadata[$relative].Size -or (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash.ToLowerInvariant() -cne $metadata[$relative].Hash) { throw 'Received size or SHA-256 mismatch' }
    }
    if ($received.Count -ne $metadata.Count) { throw 'Missing received file' }
    $verifiedAt = [DateTime]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", [Globalization.CultureInfo]::InvariantCulture)
    $receipt = [ordered]@{ content_digest = $contentDigest; file_count = $received.Count; protocol_version = 'FOF_ARTIFACT_HANDOFF/2'; run_correlation_digest = $runCorrelationDigest; run_id = $TransferId; status = 'VERIFIED'; verified_at = $verifiedAt }
    $bytes = $utf8.GetBytes(($receipt | ConvertTo-Json -Compress) + "`n")
    $out = [IO.File]::Open([IO.Path]::Combine($run, 'receipt.pending'), [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $out.Write($bytes, 0, $bytes.Length); $out.Flush($true) } finally { $out.Dispose() }
    [IO.File]::Move([IO.Path]::Combine($run, 'receipt.pending'), [IO.Path]::Combine($run, 'VERIFIED.json')); $published = $true
    Write-Output ($receipt | ConvertTo-Json -Compress)
} catch {
    $errorCode = $_.Exception.Message -replace '[^A-Za-z0-9_]', '_'
    if ($errorCode.Length -gt 128) { $errorCode = $errorCode.Substring(0, 128) }
    if ($null -ne $manifestObject -and $null -ne $contentDigest -and $null -ne $runCorrelationDigest) {
        $failure = [ordered]@{ content_digest = $contentDigest; file_count = 0; protocol_version = 'FOF_ARTIFACT_HANDOFF/2'; run_correlation_digest = $runCorrelationDigest; run_id = $TransferId; status = 'FAILED'; error_code = $errorCode }
        [Console]::Out.WriteLine(($failure | ConvertTo-Json -Compress))
    } else { [Console]::Out.WriteLine((@{ status = 'UNKNOWN_REMOTE_STATE'; run_id = $TransferId } | ConvertTo-Json -Compress)) }
    [Console]::Error.WriteLine('Receiver failure: ' + $errorCode); exit 1
} finally { if ($null -ne $archive) { $archive.Dispose() } }
