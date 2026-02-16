@echo off
title SolarAgri NeuroTwin - Fix & Build APK
color 0B

echo ============================================
echo  SolarAgri NeuroTwin - Final Fix & Build
echo ============================================
echo.

cd /d "c:\Users\Mohammed26\Desktop\PI-Hybrid-3D-Viz"

echo [1/4] Moving app OUT of SDK folder...
mkdir flutter_app_clean 2>nul
xcopy "flutter\flutter_application_1" "flutter_app_clean" /E /I /Y /Q /Excludefile:.gitignore

echo.
echo [2/4] Updating GitHub Workflow...
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
echo         working-directory: flutter_app_clean
echo         run: flutter pub get
echo.
echo       - name: Build APK (Debug)
echo         working-directory: flutter_app_clean
echo         run: flutter build apk --debug
echo.
echo       - name: Build APK (Release)
echo         working-directory: flutter_app_clean
echo         run: flutter build apk --release
echo.
echo       - name: Upload Debug APK
echo         uses: actions/upload-artifact@v4
echo         with:
echo           name: SolarAgri-NeuroTwin-Debug-APK
echo           path: flutter_app_clean/build/app/outputs/flutter-apk/app-debug.apk
echo.
echo       - name: Upload Release APK
echo         uses: actions/upload-artifact@v4
echo         with:
echo           name: SolarAgri-NeuroTwin-Release-APK
echo           path: flutter_app_clean/build/app/outputs/flutter-apk/app-release.apk
) > .github\workflows\build_flutter_apk.yml

echo.
echo [3/4] Staging files for Git...
git add flutter_app_clean/
git add .github/workflows/build_flutter_apk.yml

echo.
echo [4/4] Committing & Pushing...
git commit -m "fix: Relocate Flutter app to root for CI build"
git push origin main

echo.
echo ============================================
echo  DONE! Check GitHub Actions tab now.
echo ============================================
pause
