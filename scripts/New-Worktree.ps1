# MAINTENANCE: If you add a new gitignored file required for local development,
# add a corresponding Copy-Item line in the "Copy dev files" block below.
# See also: CONTRIBUTING.md and CLAUDE.md for the rationale.

param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,

    [Parameter(Mandatory = $false)]
    [string]$Branch
)

if (-not $Branch) {
    $Branch = $TaskName
}

# Resolve main worktree root (first entry in git worktree list)
$mainWorktree = (git worktree list --porcelain | Select-String '^worktree ' | Select-Object -First 1).Line -replace '^worktree ', ''

$worktreePath = Join-Path (Split-Path $mainWorktree -Parent) "tennis-point-logger-$TaskName"

Write-Host "Creating worktree at $worktreePath on branch $Branch..."
git worktree add $worktreePath -b $Branch
if ($LASTEXITCODE -ne 0) {
    Write-Error "git worktree add failed."
    exit 1
}

# Copy dev files — gitignored files needed for local development
$filesToCopy = @(
    "android\local.properties",
    "android\app\google-services.json"
)

foreach ($file in $filesToCopy) {
    $src = Join-Path $mainWorktree $file
    $dst = Join-Path $worktreePath $file
    if (Test-Path $src) {
        $dstDir = Split-Path $dst -Parent
        if (-not (Test-Path $dstDir)) {
            New-Item -ItemType Directory -Path $dstDir | Out-Null
        }
        Copy-Item $src $dst
        Write-Host "Copied $file"
    } else {
        Write-Warning "$file not found in main worktree — copy it manually if needed."
    }
}

Write-Host ""
Write-Host "Worktree ready: $worktreePath"
