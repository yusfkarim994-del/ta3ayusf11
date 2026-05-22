@echo off
echo Building APK...
call "c:\Users\yusf2000.runnervmsit9q\Downloads\qalay muslman\flutter\bin\flutter.bat" build apk --release

echo Building AppBundle (AAB)...
call "c:\Users\yusf2000.runnervmsit9q\Downloads\qalay muslman\flutter\bin\flutter.bat" build appbundle --release

set DOWNLOADS=c:\Users\yusf2000.runnervmsit9q\Downloads\

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy /Y "build\app\outputs\flutter-apk\app-release.apk" "%DOWNLOADS%recovery_app.apk"
    echo Copied APK to Downloads!
)

if exist "build\app\outputs\bundle\release\app-release.aab" (
    copy /Y "build\app\outputs\bundle\release\app-release.aab" "%DOWNLOADS%recovery_app.aab"
    echo Copied AAB to Downloads!
)
echo Build finished.
