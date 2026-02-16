@echo off
title SolarAgri NeuroTwin - Quick Fix & Push
color 0E

echo ============================================
echo  SolarAgri NeuroTwin - Quick Fix
echo ============================================
echo.

cd /d "c:\Users\Mohammed26\Desktop\PI-Hybrid-3D-Viz"

echo [1/3] Adding files to Git (Forcing add)...
git add -f flutter/flutter_application_1/
git add .github/workflows/build_flutter_apk.yml
git add .gitignore

echo.
echo [2/3] Committing...
git commit -m "fix: Unlock flutter app directory for CI build"

echo.
echo [3/3] Pushing to GitHub...
git push origin main

echo.
echo ============================================
echo  DONE! Check GitHub Actions tab now.
echo ============================================
pause
