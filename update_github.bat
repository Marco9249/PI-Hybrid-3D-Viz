@echo off
chcp 65001 >nul
color 0B
cls
echo ========================================================
echo       🚀 PI-Hybrid 3D Viz - GitHub Updater
echo ========================================================
echo.
echo 1. التحقق من حالة المستودع (Checking Git Status)...
git remote set-url origin https://github.com/Marco9249/PI-Hybrid-3D-Viz.git 2>nul
echo.
echo 2. إضافة كافة الملفات الجديدة والتعديلات...
git add .
echo.
echo 3. حفظ التغييرات (Commit)...
set /p msg="أدخل رسالة التحديث (أو اضغط Enter لاستخدام الرسالة الافتراضية): "
if "%msg%"=="" set msg=تحديث المشروع: إضافة ميزات وواجهات جديدة
git commit -m "%msg%"
echo.
echo 4. رفع الملفات إلى GitHub (Push)...
git push origin main --force
echo.
echo ========================================================
echo       ✨ تم التحديث بنجاح! جميع الملفات مرفوعة الآن.
echo ========================================================
echo.
pause
