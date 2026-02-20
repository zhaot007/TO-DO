# TO-DO App APK 一键打包脚本 (PowerShell版)
# 使用方法: .\build-apk.ps1

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  TO-DO App APK 一键打包 (Windows版)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. 构建Vue项目
Write-Host ""
Write-Host "📦 [1/5] 构建Vue项目..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Vue项目构建失败！" -ForegroundColor Red
    exit 1
}

# 2. 同步到Android
Write-Host ""
Write-Host "🔄 [2/5] 同步到Android项目..." -ForegroundColor Yellow
npx cap sync android
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 同步到Android失败！" -ForegroundColor Red
    exit 1
}

# 3. 修复Java版本配置
Write-Host ""
Write-Host "🔧 [3/5] 修复Java版本配置..." -ForegroundColor Yellow

# 修复 Capacitor 自动生成的配置文件
$files = @(
    "android\app\capacitor.build.gradle",
    "android\capacitor-cordova-android-plugins\build.gradle",
    "node_modules\@capacitor\local-notifications\android\build.gradle",
    "node_modules\@capacitor\filesystem\android\build.gradle",
    "node_modules\@capacitor\preferences\android\build.gradle"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  修复: $file" -ForegroundColor Gray
        (Get-Content $file) -replace 'JavaVersion.VERSION_21', 'JavaVersion.VERSION_17' | Set-Content $file
    }
}

# 4. 构建APK
Write-Host ""
Write-Host "🏗️  [4/5] 构建APK..." -ForegroundColor Yellow
Push-Location android
.\gradlew.bat clean assembleDebug
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ APK构建失败！" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# 5. 复制APK到项目根目录
Write-Host ""
Write-Host "📋 [5/5] 复制APK到项目根目录..." -ForegroundColor Yellow
Copy-Item "android\app\build\outputs\apk\debug\app-debug.apk" "TODO-App.apk" -Force

# 完成
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "✅ 打包完成！" -ForegroundColor Green
Write-Host "📦 APK位置: $PWD\TODO-App.apk" -ForegroundColor Green
$fileSize = (Get-Item "TODO-App.apk").Length
$fileSizeMB = [math]::Round($fileSize / 1MB, 2)
Write-Host "📊 文件大小: $fileSizeMB MB ($fileSize 字节)" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
