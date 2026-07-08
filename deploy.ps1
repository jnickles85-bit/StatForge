# StatForge deploy script — copies the addon to the WoW addon folder.
# Usage: powershell -ExecutionPolicy Bypass -File C:\Projects\StatForge\deploy.ps1 [-NoPull]
#   -NoPull : skip "git pull" and deploy the local working tree as-is
#             (use while testing uncommitted changes)

param([switch]$NoPull)

$ErrorActionPreference = "Stop"

$repoPath   = "C:\Projects\StatForge"
$addonPath  = "C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\StatForge"

Write-Host "StatForge Deploy" -ForegroundColor Cyan
Write-Host "----------------"

# Step 1: Pull latest (unless -NoPull)
if ($NoPull) {
    Write-Host "Skipping git pull (-NoPull) — deploying local files." -ForegroundColor Yellow
} else {
    Write-Host "Pulling latest from GitHub..." -ForegroundColor Yellow
    Push-Location $repoPath
    git pull origin main
    if ($LASTEXITCODE -ne 0) { Write-Host "Git pull failed!" -ForegroundColor Red; Pop-Location; exit 1 }
    $commit = git rev-parse --short HEAD
    Write-Host "  -> commit $commit" -ForegroundColor Green
    Pop-Location
}

# Step 2: Copy files to addon folder
Write-Host "Copying to WoW addon folder..." -ForegroundColor Yellow
if (-not (Test-Path $addonPath)) {
    Write-Host "Addon folder not found: $addonPath" -ForegroundColor Red
    Write-Host "Create it first, or adjust the path in this script." -ForegroundColor Red
    exit 1
}

$files = @("Core.lua", "StatForge.toc")
foreach ($f in $files) {
    $src = Join-Path $repoPath $f
    $dst = Join-Path $addonPath $f
    if (Test-Path $src) {
        Copy-Item $src $dst -Force
        Write-Host "  -> $f" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Done! Restart WoW to load the updated addon." -ForegroundColor Green
Write-Host "Use /statforge or /sf in-game." -ForegroundColor Cyan