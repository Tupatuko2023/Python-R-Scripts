<#
.SYNOPSIS
Runs K40 with a clean R startup on this workstation.
.DESCRIPTION
Forces vanilla startup and disables user-level R profile/environment loading
before invoking the current K40 entrypoint.
#>
param(
  [string]$DataRoot = "C:/GitWork/FOF_LOCAL_DATA"
)

$ErrorActionPreference = "Stop"

$currentPath = (Get-Location).Path
if (-not $currentPath.EndsWith("Fear-of-Falling")) {
  throw "Run this script from the Fear-of-Falling project root. Current path: $currentPath"
}

$scriptPath = ".\R-scripts\K40\K40.V2_frailty-index.R"
if (-not (Test-Path $scriptPath)) {
  throw "K40 entrypoint not found at $scriptPath"
}

$env:R_PROFILE_USER = "NUL"
$env:R_ENVIRON_USER = "NUL"
$env:DATA_ROOT = $DataRoot

Write-Host "Running K40 via Rscript --vanilla"
Write-Host "  DATA_ROOT=$($env:DATA_ROOT)"
& Rscript --vanilla $scriptPath
