@echo off
chcp 65001 >nul
REM Windows Electron Build Script
REM Purpose: Build Windows Electron installer

echo =========================================
echo Starting Windows Electron Build
echo =========================================

REM Step 1: Clean old build files
echo Step 1/3: Cleaning old build files...
if exist release rmdir /s /q release
if exist dist rmdir /s /q dist

REM Step 2: Build frontend resources
echo Step 2/3: Building frontend resources...
call npm run build
if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)

REM Step 3: Package Electron app
echo Step 3/3: Packaging Electron app...
call npx electron-builder --win
if errorlevel 1 (
    echo Packaging failed!
    pause
    exit /b 1
)

echo =========================================
echo Build completed successfully!
echo Output: release\TODO App Setup 1.5.7.exe
echo =========================================
pause
