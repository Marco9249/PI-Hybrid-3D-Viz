@echo off
title SolarAgri NeuroTwin - Push & Build APK
color 0A

echo ============================================
echo  SolarAgri NeuroTwin - Cloud APK Builder
echo ============================================
echo.

cd /d "c:\Users\Mohammed26\Desktop\PI-Hybrid-3D-Viz"

echo [1/3] Adding Flutter app files to Git...
git add -f .github/workflows/build_flutter_apk.yml
git add -f flutter/flutter_application_1/pubspec.yaml
git add -f flutter/flutter_application_1/pubspec.lock
git add -f flutter/flutter_application_1/analysis_options.yaml
git add -f flutter/flutter_application_1/lib/
git add -f flutter/flutter_application_1/android/app/build.gradle
git add -f flutter/flutter_application_1/android/build.gradle
git add -f flutter/flutter_application_1/android/settings.gradle
git add -f flutter/flutter_application_1/android/gradle.properties
git add -f flutter/flutter_application_1/android/local.properties
git add -f flutter/flutter_application_1/android/app/src/
git add -f flutter/flutter_application_1/web/
git add -f flutter/flutter_application_1/assets/
echo    Done!

echo.
echo [2/3] Committing...
git commit -m "feat: Add SolarAgri NeuroTwin Flutter app with full digital twin UI"
echo    Done!

echo.
echo [3/3] Pushing to GitHub...
git push origin main
echo    Done!

echo.
echo ============================================
echo  SUCCESS! Go to your GitHub repo:
echo  Actions tab - Download APK artifact
echo ============================================
echo.
pause
