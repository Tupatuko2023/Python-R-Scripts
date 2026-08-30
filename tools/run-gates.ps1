[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $GateArgs
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$gateScript = Join-Path $PSScriptRoot 'run-gates.sh'

if (-not (Test-Path -LiteralPath $gateScript -PathType Leaf)) {
    Write-Error "Gate script not found: $gateScript"
    exit 2
}

$candidates = @(
    'C:\Program Files\Git\bin\bash.exe',
    'C:\Program Files\Git\usr\bin\bash.exe'
)

$bash = $candidates |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
    Select-Object -First 1

if (-not $bash) {
    $pathBash = Get-Command bash.exe -ErrorAction SilentlyContinue
    $systemBash = Join-Path $env:WINDIR 'System32\bash.exe'

    if ($pathBash -and
        $pathBash.Source -and
        -not [System.StringComparer]::OrdinalIgnoreCase.Equals(
            $pathBash.Source,
            $systemBash
        )) {
        $bash = $pathBash.Source
    }
}

if (-not $bash) {
    Write-Error @'
Git Bash was not found.

Install Git for Windows or make a usable bash.exe available on PATH.
The Windows System32 bash.exe / WSL launcher is not accepted for repository gates.
'@
    exit 2
}

Push-Location $repoRoot
try {
    & $bash 'tools/run-gates.sh' @GateArgs
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
