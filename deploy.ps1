#!/usr/bin/env pwsh
# Auto-deploy script with automatic version update
# This script automatically generates a new version based on timestamp,
# builds the Flutter web app, and deploys to Firebase

$ErrorActionPreference = "Stop"

# Navigate to project directory
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectDir

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Auto Deploy with Version Update" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Generate version from timestamp
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$version = "v$timestamp"
Write-Host "`n[1/4] Generated version: $version" -ForegroundColor Green

# Update index.html with new version
Write-Host "[2/4] Updating version in index.html..." -ForegroundColor Yellow
$indexPath = "web\index.html"
$indexContent = Get-Content $indexPath -Raw
$indexContent = $indexContent -replace "const APP_VERSION = '[^']*'", "const APP_VERSION = '$version'"
Set-Content $indexPath $indexContent -NoNewline
Write-Host "       Version updated successfully!" -ForegroundColor Green

# Build Flutter web
Write-Host "[3/4] Building Flutter web..." -ForegroundColor Yellow
$flutterPath = "..\flutter\bin\flutter.bat"
& $flutterPath build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "       Build completed successfully!" -ForegroundColor Green

# Deploy to Firebase
Write-Host "[4/4] Deploying to Firebase..." -ForegroundColor Yellow
npx firebase-tools deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "Deploy failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "  Version: $version" -ForegroundColor Green
Write-Host "  URL: https://laabrah.web.app" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

Write-Host "[5/5] Deploying to Cloudflare..." -ForegroundColor Yellow
npx wrangler pages deploy build/web --project-name laabrah
