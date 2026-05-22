
Write-Host 'Building APK...'
cmd /c ""c:\Users\yusf2000.runnervmsit9q\Downloads\qalay muslman\flutter\bin\flutter.bat" build apk --release"

Write-Host 'Building AppBundle (AAB)...'
cmd /c ""c:\Users\yusf2000.runnervmsit9q\Downloads\qalay muslman\flutter\bin\flutter.bat" build appbundle --release"

 = "c:\Users\yusf2000.runnervmsit9q\Downloads"
 = "build\app\outputs\bundle\release\app-release.aab"
 = "build\app\outputs\flutter-apk\app-release.apk"

if (Test-Path ) {
    Copy-Item -Path  -Destination \recovery_app.aab -Force
    Write-Host 'Copied AAB to Downloads'
}
if (Test-Path ) {
    Copy-Item -Path  -Destination \recovery_app.apk -Force
    Write-Host 'Copied APK to Downloads'
}
Write-Host 'Build script finished.'

