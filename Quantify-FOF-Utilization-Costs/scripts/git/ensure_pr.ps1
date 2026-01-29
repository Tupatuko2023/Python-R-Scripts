<#
.SYNOPSIS
    Ensures a GitHub PR exists for the current branch.

.PARAMETER Title
    Title for the PR.

.PARAMETER Body
    Body for the PR.
#>

param(
    [string]$Title,
    [string]$Body
)

$ErrorActionPreference = 'Stop'

# Get current branch
$currentBranch = git branch --show-current
if ([string]::IsNullOrWhiteSpace($currentBranch)) {
    throw "Could not determine current branch."
}

Write-Host "Checking PR status for '$currentBranch'..."

# 1. Check existing
$existingPr = gh pr list --head "$currentBranch" --json url --state open | ConvertFrom-Json

if ($existingPr -and $existingPr.Count -gt 0) {
    Write-Host "PR exists: $($existingPr[0].url)"
    exit 0
}

# 2. Create PR
Write-Host "No open PR found. Creating..."

# Build arguments
$args = @("--head", "$currentBranch", "--fill") # fill uses commit info as fallback

if (![string]::IsNullOrWhiteSpace($Title)) {
    $args += "--title"
    $args += "$Title"
}

if (![string]::IsNullOrWhiteSpace($Body)) {
    $args += "--body"
    $args += "$Body"
}

gh pr create @args

Write-Host "PR created successfully."