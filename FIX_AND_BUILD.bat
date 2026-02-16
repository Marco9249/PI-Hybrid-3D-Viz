@echo off
title SolarAgri NeuroTwin - Move & Build
color 0B

echo ============================================
echo  MOVING APP TO 'mobile_app' & FIXING BUILD
echo ============================================
echo.

cd /d "c:\Users\Mohammed26\Desktop\PI-Hybrid-3D-Viz"

echo [1/4] Creating separate folder 'mobile_app'...
if not exist "mobile_app" mkdir "mobile_app"

echo [2/4] Moving Flutter app files...
xcopy "flutter\flutter_application_1" "mobile_app" /E /I /Y /Q /Excludefile:.gitignore

echo.
echo [3/4] Updating GitHub Workflow to use 'mobile_app'...
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
echo         working-directory: mobile_app
echo         run: flutter pub get
echo.
echo       - name: Build APK (Debug)
echo         working-directory: mobile_app
echo         run: flutter build apk --debug --no-android-studio-check
echo.
echo       - name: Build APK (Release)
echo         working-directory: mobile_app
echo         run: flutter build apk --release --no-android-studio-check
echo.
echo       - name: Upload Debug APK
echo         uses: actions/upload-artifact@v4
echo         with:
echo           name: SolarAgri-NeuroTwin-Debug-APK
echo           path: mobile_app/build/app/outputs/flutter-apk/app-debug.apk
echo.
echo       - name: Upload Release APK
echo         uses: actions/upload-artifact@v4
echo         with:
echo           name: SolarAgri-NeuroTwin-Release-APK
echo           path: mobile_app/build/app/outputs/flutter-apk/app-release.apk
) > .github\workflows\build_flutter_apk.yml

echo.
echo [4/4] Pushing to GitHub...
git add mobile_app/
git add .github/workflows/build_flutter_apk.yml
git commit -m "fix: Move flutter app to mobile_app folder to fix CI build"
git push origin main

echo.
echo ============================================
echo  DONE! Go to GitHub Actions tab now.
echo ============================================
pause
