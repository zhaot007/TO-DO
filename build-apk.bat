@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ==========================================
echo   TO-DO App APK 一键打包 (Windows版)
echo ==========================================

:: 1. 构建Vue项目
echo.
echo 📦 [1/5] 构建Vue项目...
call npm run build
if errorlevel 1 (
    echo ❌ Vue项目构建失败！
    exit /b 1
)

:: 2. 同步到Android
echo.
echo 🔄 [2/5] 同步到Android项目...
call npx cap sync android
if errorlevel 1 (
    echo ❌ 同步到Android失败！
    exit /b 1
)

:: 3. 修复Java版本配置
echo.
echo 🔧 [3/5] 修复Java版本配置...

:: 修复 Capacitor 自动生成的配置文件
if exist "android\app\capacitor.build.gradle" (
    powershell -Command "(Get-Content 'android\app\capacitor.build.gradle') -replace 'JavaVersion.VERSION_21', 'JavaVersion.VERSION_17' | Set-Content 'android\app\capacitor.build.gradle'"
)

if exist "android\capacitor-cordova-android-plugins\build.gradle" (
    powershell -Command "(Get-Content 'android\capacitor-cordova-android-plugins\build.gradle') -replace 'JavaVersion.VERSION_21', 'JavaVersion.VERSION_17' | Set-Content 'android\capacitor-cordova-android-plugins\build.gradle'"
)

:: 修复 Capacitor 插件的 Java 版本
if exist "node_modules\@capacitor\local-notifications\android\build.gradle" (
    powershell -Command "(Get-Content 'node_modules\@capacitor\local-notifications\android\build.gradle') -replace 'JavaVersion.VERSION_21', 'JavaVersion.VERSION_17' | Set-Content 'node_modules\@capacitor\local-notifications\android\build.gradle'"
)

if exist "node_modules\@capacitor\filesystem\android\build.gradle" (
    powershell -Command "(Get-Content 'node_modules\@capacitor\filesystem\android\build.gradle') -replace 'JavaVersion.VERSION_21', 'JavaVersion.VERSION_17' | Set-Content 'node_modules\@capacitor\filesystem\android\build.gradle'"
)

if exist "node_modules\@capacitor\preferences\android\build.gradle" (
    powershell -Command "(Get-Content 'node_modules\@capacitor\preferences\android\build.gradle') -replace 'JavaVersion.VERSION_21', 'JavaVersion.VERSION_17' | Set-Content 'node_modules\@capacitor\preferences\android\build.gradle'"
)

:: 4. 构建APK
echo.
echo 🏗️  [4/5] 构建APK...
cd android
call gradlew.bat clean assembleDebug
if errorlevel 1 (
    echo ❌ APK构建失败！
    cd ..
    exit /b 1
)
cd ..

:: 5. 复制APK到项目根目录
echo.
echo 📋 [5/5] 复制APK到项目根目录...
copy /Y "android\app\build\outputs\apk\debug\app-debug.apk" "TODO-App.apk"

:: 完成
echo.
echo ==========================================
echo ✅ 打包完成！
echo 📦 APK位置: %CD%\TODO-App.apk
for %%A in (TODO-App.apk) do echo 📊 文件大小: %%~zA 字节
echo ==========================================

endlocal
