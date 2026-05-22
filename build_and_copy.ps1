
Write-Host 'Building AppBundle (AAB)...'
& "c:\Users\yusf2000.runnervmsit9q\Downloads\qalay muslman\flutter\bin\flutter.bat" build appbundle --release
Write-Host 'Building APK...'
& "c:\Users\yusf2000.runnervmsit9q\Downloads\qalay muslman\flutter\bin\flutter.bat" build apk --release

$DestDir = "c:\Users\yusf2000.runnervmsit9q\Downloads"
$AabPath = "build\app\outputs\bundle\release\app-release.aab"
$ApkPath = "build\app\outputs\flutter-apk\app-release.apk"

if (Test-Path $AabPath) {
    Copy-Item -Path $AabPath -Destination "$DestDir\recovery_app.aab" -Force
    Write-Host 'Copied AAB to Downloads'
}
if (Test-Path $ApkPath) {
    Copy-Item -Path $ApkPath -Destination "$DestDir\recovery_app.apk" -Force
    Write-Host 'Copied APK to Downloads'
}
Write-Host 'Build script finished.'

