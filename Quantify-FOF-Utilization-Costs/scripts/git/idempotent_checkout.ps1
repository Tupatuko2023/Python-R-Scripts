<#
.SYNOPSIS
    Idempotently checks out a git branch.

.PARAMETER TargetBranch
    The branch to switch to.

.PARAMETER BaseBranch
    The base branch to branch off if Target doesn't exist. Defaults to "main".
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetBranch,

    [string]$BaseBranch = "main"
)

$ErrorActionPreference = 'Stop'

function Get-CurrentBranch {
    git branch --show-current
}

function Test-LocalBranch {
    param([string]$Name)
    git show-ref --verify --quiet "refs/heads/$Name"
    return $LASTEXITCODE -eq 0
}

function Test-RemoteBranch {
    param([string]$Name)
    git show-ref --verify --quiet "refs/remotes/origin/$Name"
    return $LASTEXITCODE -eq 0
}

# 1. Check current branch
$current = Get-CurrentBranch
if ($current -eq $TargetBranch) {
    Write-Host "Already on branch '$TargetBranch'."
    exit 0
}

# 2. Check Local existence
if (Test-LocalBranch -Name $TargetBranch) {
    Write-Host "Branch '$TargetBranch' exists locally. Switching..."
    git checkout "$TargetBranch"
    exit 0
}

# Fetch to see remotes
git fetch origin --prune

# 3. Check Remote existence
if (Test-RemoteBranch -Name $TargetBranch) {
    Write-Host "Branch '$TargetBranch' found on remote. Tracking..."
    git checkout -b "$TargetBranch" "origin/$TargetBranch"
    exit 0
}

# 4. Create New Branch
Write-Host "Branch '$TargetBranch' not found. Creating from '$BaseBranch'..."

# Switch to base, pull, branch
git checkout "$BaseBranch"
git pull origin "$BaseBranch"
git checkout -b "$TargetBranch"

Write-Host "Successfully created and switched to '$TargetBranch'."
exit 0