@echo off
title SolarAgri NeuroTwin - FINAL FIX
color 0D

echo ============================================
echo  SolarAgri NeuroTwin - ROOT FLUTTER FIX
echo ============================================
echo.

cd /d "c:\Users\Mohammed26\Desktop\PI-Hybrid-3D-Viz"

echo [1/5] Creating root app folder 'solar_app'...
if not exist "solar_app" mkdir "solar_app"

echo [2/5] Moving Flutter app out of SDK folder...
xcopy "flutter\flutter_application_1" "solar_app" /E /I /Y /Q /Excludefile:.gitignore

echo.
echo [3/5] Fixing GitHub Workflow path...
(
echo name: Build Flutter APK
echo.
echo on:
echo   push:
echo     branches: [ main, master ]
echo   workflow_dispatch:
echo.
echo jobs:
echo   build:
echo     runs-on: ubuntu-latest
echo     steps:
echo       - name: Checkout repository
echo         uses: actions/checkout@v4
echo.
echo       - name: Set up Java
echo         uses: actions/setup-java@v4
echo         with:
echo           distribution: 'temurin'
echo           java-version: '17'
echo.
echo       - name: Set up Flutter
echo         uses: subosito/flutter-action@v2
echo         with:
echo           flutter-version: '3.27.3'
echo           channel: 'stable'
echo           cache: true
echo.
echo       - name: Get dependencies
echo         working-directory: solar_app
echo         run: flutter pub get
echo.
echo       - name: Build APK (Debug)
echo         working-directory: solar_app
echo         run: flutter build apk --debug --no-android-studio-check
echo.
echo       - name: Build APK (Release)
echo         working-directory: solar_app
echo         run: flutter build apk --release --no-android-studio-check
echo.
echo       - name: Upload Debug APK
echo         uses: actions/upload-artifact@v4
echo         with:
echo           name: SolarAgri-NeuroTwin-Debug-APK
echo           path: solar_app/build/app/outputs/flutter-apk/app-debug.apk
echo.
echo       - name: Upload Release APK
echo         uses: actions/upload-artifact@v4
echo         with:
echo           name: SolarAgri-NeuroTwin-Release-APK
echo           path: solar_app/build/app/outputs/flutter-apk/app-release.apk
) > .github\workflows\build_flutter_apk.yml

echo.
echo [4/5] Removing old submodule references (if any)...
git rm --cached flutter 2>nul
rmdir /s /q .git\modules\flutter 2>nul

echo.
echo [5/5] Pushing to GitHub...
git add solar_app/
git add .github/workflows/build_flutter_apk.yml
git commit -m "fix: Move Flutter app to root 'solar_app' to fix submodule issues"
git push origin main

echo.
echo ============================================
echo  DONE! Check GitHub Actions tab now.
echo ============================================
pause
