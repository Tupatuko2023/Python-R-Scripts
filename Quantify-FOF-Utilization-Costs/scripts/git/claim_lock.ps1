<#
.SYNOPSIS
    Claims the agent lock file.
    
.DESCRIPTION
    Ensures exclusive access by creating a .agent.lock file.
    Fails if the lock already exists.

.EXAMPLE
    .\claim_lock.ps1
#>

$ErrorActionPreference = 'Stop'
$LockFile = ".agent.lock"

if (Test-Path $LockFile) {
    Write-Warning "Lock file '$LockFile' already exists. Another agent may be active."
    exit 1
}

try {
    $content = "PID=$($PID);Date=$(Get-Date -Format 'o')"
    Set-Content -Path $LockFile -Value $content -NoNewline
    Write-Host "Lock claimed successfully." -ForegroundColor Green
    exit 0
} catch {
    Write-Error "Failed to write lock file: $_"
    exit 1
}