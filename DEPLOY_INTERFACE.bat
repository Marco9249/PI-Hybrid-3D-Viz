@echo off
chcp 65001 >nul
title GitHub Pro Deployer - PI-Hybrid
color 0B
echo.
echo ============================================================
echo.
echo     ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗
echo     ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝
echo     ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝ 
echo     ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝  
echo     ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║   
echo     ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝   
echo.
echo ============================================================
echo              PREMIUM GITHUB DEPLOYMENT SYSTEM
echo                   نظام الرفع الاحترافي
echo ============================================================
echo.

set REPO_URL=https://github.com/Marco9249/PI-Hybrid-3D-Viz.git

echo [STEP 1] 🧹 SANITIZING REPOSITORY...
echo ------------------------------------------------------------
if exist .git (
    attrib -h .git /s /d >nul 2>&1
    rd /s /q .git >nul 2>&1
)
git init
echo [OK] Local repository initialized.
echo.

echo [STEP 2] 🔑 IDENTITY CONFIGURATION...
echo ------------------------------------------------------------
git config user.name "Marco9249"
git config user.email "izzeldeenm@gmail.com"
git remote add origin %REPO_URL%
echo [OK] Identity and Remote set.
echo.

echo [STEP 3] 📦 COMPILING CONTENT ^& ARTWORK...
echo ------------------------------------------------------------
echo Staging premium README and research assets...
git add .
git commit -m "💎 ULTIMATE RELEASE: Premium Interface ^& Scientific Visualization (%date% %time%)"

if %errorlevel% neq 0 (
    echo.
    echo [!] Commit failed! Retrying with explicit identity...
    git commit -m "💎 ULTIMATE RELEASE: Premium Interface (%date% %time%)" --author="Marco9249 <izzeldeenm@gmail.com>"
)
echo.

echo [STEP 4] 🚀 LAUNCHING TO CLOUD...
echo ------------------------------------------------------------
echo Initiating secure transfer to GitHub...
git branch -M main
git push -u origin main --force

if %errorlevel% neq 0 (
    echo.
    echo [!] Standard launch failed. Attempting alternative route...
    git push -u origin master --force
)

echo.
echo [STEP 5] ✨ FINALIZING DEPLOYMENT...
echo ------------------------------------------------------------
if %errorlevel% equ 0 (
    cls
    color 0A
    echo.
    echo ============================================================
    echo        🎉 MISSION ACCOMPLISHED! YOUR REPO IS LIVE 🎉
    echo ============================================================
    echo.
    echo  The new professional interface is now visible to the world.
    echo.
    echo  🔗 REPOSITORY: https://github.com/Marco9249/PI-Hybrid-3D-Viz
    echo  🔗 LIVE DEMO:  https://marco9249.github.io/PI-Hybrid-3D-Viz/
    echo.
    echo ============================================================
) else (
    color 0C
    echo.
    echo [!] ERROR: Deployment Interrupted.
    echo ------------------------------------------------------------
    echo 1. Please CHECK your internet connection.
    echo 2. Ensure you have PERMISSION to push to Marco9249.
    echo 3. Verify GitHub is not asking for login in a background window.
)
echo.
pause
