Write-Host "🚀 Starting Optimized Release Builds..."

$flutterPath = "C:\Users\yusf2000.runnervm2p0d8\Documents\qalay muslman\flutter\bin\flutter.bat"

# Build APK
Write-Host "📦 Building APK..."
& $flutterPath build apk --release

# Build AAB
Write-Host "📦 Building App Bundle (AAB)..."
& $flutterPath build appbundle --release

# Destination
$destDir = "$HOME\Documents"
if (!(Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir
}

# Copy and rename for clarity
$date = Get-Date -Format "yyyyMMdd_HHmm"
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "$destDir\qalay_muslman_pro_optimized_$date.apk"
Copy-Item "build\app\outputs\bundle\release\app-release.aab" "$destDir\qalay_muslman_pro_optimized_$date.aab"

Write-Host "✅ Done! Files copied to $destDir"
Write-Host "📄 APK: qalay_muslman_pro_optimized_$date.apk"
Write-Host "📄 AAB: qalay_muslman_pro_optimized_$date.aab"
