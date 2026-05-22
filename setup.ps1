#!/usr/bin/env pwsh
# Laabrah Project Setup Automation
# This script initializes all project dependencies for both the Flutter app and the React chat app.

$ErrorActionPreference = "Continue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   🚀 LAABRAH PROJECT SETUP AUTOMATION 🚀" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Setup Flutter App
Write-Host "`n[1/3] Setting up Flutter Recovery App..." -ForegroundColor Yellow
$flutterPath = "..\flutter\bin\flutter.bat"
if (!(Test-Path $flutterPath)) {
    # Fallback to system flutter if not found in parent directory
    $flutterPath = "flutter"
}
Write-Host "Running: flutter pub get" -ForegroundColor Gray
& $flutterPath pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Flutter App setup completed successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to install Flutter dependencies!" -ForegroundColor Red
}

# 2. Setup React Chat App
Write-Host "`n[2/3] Setting up React Chat App (laabrah-chat)..." -ForegroundColor Yellow
if (Test-Path "laabrah-chat") {
    Push-Location "laabrah-chat"
    Write-Host "Running: npm install" -ForegroundColor Gray
    npm install
    Pop-Location
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ React Chat App setup completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to install React Chat App dependencies!" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️ laabrah-chat directory not found!" -ForegroundColor Red
}

# 3. Setup CLI Deploy Tools
Write-Host "`n[3/3] Setting up global CLI deployment tools (Firebase & Wrangler)..." -ForegroundColor Yellow
Write-Host "Running: npm install -g firebase-tools wrangler" -ForegroundColor Gray
npm install -g firebase-tools wrangler
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Global deployment tools setup completed successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to install deployment tools globally!" -ForegroundColor Red
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "🎉 ALL DEPLOYMENT & DEV ENVIRONMENTS ARE READY! 🎉" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "`nCommands to run the projects:" -ForegroundColor Yellow
Write-Host "• Run Flutter Web: flutter run -d chrome" -ForegroundColor White
Write-Host "• Run React Chat:  cd laabrah-chat; npm run dev" -ForegroundColor White
Write-Host "• Auto-Deploy All: ./deploy.ps1" -ForegroundColor White
