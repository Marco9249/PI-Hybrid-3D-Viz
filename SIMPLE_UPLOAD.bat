@echo off
title Simple Force Upload
color 0E

echo ==============================================
echo   SIMPLE UPLOAD FIX (No Moving Files)
echo ==============================================
echo.

cd /d "c:\Users\Mohammed26\Desktop\PI-Hybrid-3D-Viz"

:: 1. Remove the nested .git directory that blocks the upload
if exist "flutter\.git" (
    echo [FIX] Removing nested .git folder inside flutter...
    attrib -h "flutter\.git" /S /D
    rmdir /s /q "flutter\.git"
)

:: 2. Clear cached git index for flutter folder
echo [FIX] Clearing git cache...
git rm --cached flutter -r 2>nul

:: 3. Force add ALL files
echo [GIT] Adding all files...
git add .
git add flutter\ --force

:: 4. Commit and Push
echo [GIT] Committing and Pushing...
git commit -m "Force upload of flutter SDK and App"
git push origin main

echo.
echo ==============================================
echo   DONE! Files should be uploading now.
echo ==============================================
pause
