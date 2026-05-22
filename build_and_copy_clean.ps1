#!/usr/bin/env pwsh
# Dynamic build and copy script for Recovery App
# This script compiles the App Bundle (AAB) and copies it to the user's Downloads directory.

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   ⚙️ BUILDING AND DEPLOYING ANDROID AAB ⚙️" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Resolve Flutter executable
$flutterPath = "..\flutter\bin\flutter.bat"
if (!(Test-Path $flutterPath)) {
    $flutterPath = "flutter"
}
Write-Host "Using Flutter executable at: $flutterPath" -ForegroundColor Gray

# 2. Compile Release AppBundle (AAB)
Write-Host "`nRunning: flutter build appbundle --release" -ForegroundColor Yellow
& $flutterPath build appbundle --release

# 3. Resolve Downloads directory dynamically
$userProfile = [System.Environment]::GetFolderPath("UserProfile")
$downloadsDir = Join-Path $userProfile "Downloads"
Write-Host "`nTarget Downloads Directory: $downloadsDir" -ForegroundColor Gray

# 4. Copy Output files
$aabSource = "build\app\outputs\bundle\release\app-release.aab"
$aabDest = Join-Path $downloadsDir "recovery_app.aab"

if (Test-Path $aabSource) {
    if (!(Test-Path $downloadsDir)) {
        New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null
    }
    Copy-Item -Path $aabSource -Destination $aabDest -Force
    Write-Host "`n✅ SUCCESS: Copied AAB bundle to $aabDest" -ForegroundColor Green
} else {
    Write-Error "❌ Error: App Bundle output file not found at $aabSource!"
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "🎉 ANDROID BUILD COMPLETED SUCCESSFULLY! 🎉" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
