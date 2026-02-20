# Android 构建脚本参考文档

本文档详细说明项目中各个Android构建脚本的实现细节和使用方法。

---

## 脚本文件概览

| 脚本文件 | 平台 | 语言 | 推荐度 |
|---------|------|------|--------|
| `build-apk.bat` | Windows | Batch | ⭐⭐⭐⭐⭐ |
| `build-apk.ps1` | Windows | PowerShell | ⭐⭐⭐⭐ |
| `build-apk.sh` | macOS/Linux | Bash | ⭐⭐⭐⭐⭐ |

---

## build-apk.bat (Windows批处理脚本)

### 完整代码

```batch
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

:: 修复 Capacitor 核心和所有插件的 Java 版本
if exist "node_modules\@capacitor\android\capacitor\build.gradle" (
    powershell -Command "(Get-Content 'node_modules\@capacitor\android\capacitor\build.gradle') -replace 'JavaVersion.VERSION_21', 'JavaVersion.VERSION_17' | Set-Content 'node_modules\@capacitor\android\capacitor\build.gradle'"
)

if exist "node_modules\@capacitor\local-notifications\android\build.gradle" (
    powershell -Command "(Get-Content 'node_modules\@capacitor\local-notifications\android\build.gradle') -replace 'JavaVersion.VERSION_21', 'JavaVersion.VERSION_17' | Set-Content 'node_modules\@capacitor\local-notifications\android\build.gradle'"
)

if exist "node_modules\@capacitor\filesystem\android\build.gradle" (
    powershell -Command "(Get-Content 'node_modules\@capacitor\filesystem\android\build.gradle') -replace 'JavaVersion.VERSION_21', 'JavaVersion.VERSION_17' | Set-Content 'node_modules\@capacitor\filesystem\android\build.gradle'"
    powershell -Command "(Get-Content 'node_modules\@capacitor\filesystem\android\build.gradle') -replace 'jvmToolchain\(21\)', 'jvmToolchain(17)' | Set-Content 'node_modules\@capacitor\filesystem\android\build.gradle'"
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
```

### 关键技术点

#### 1. 字符编码设置
```batch
chcp 65001 >nul
```
设置为UTF-8编码，支持中文显示。

#### 2. 错误处理
```batch
if errorlevel 1 (
    echo ❌ 构建失败！
    exit /b 1
)
```
每个步骤都检查返回值，失败时立即退出。

#### 3. PowerShell文本替换
```batch
powershell -Command "(Get-Content 'file.gradle') -replace 'old', 'new' | Set-Content 'file.gradle'"
```
使用PowerShell进行文件内容替换，比纯批处理更强大。

#### 4. 路径处理
Windows使用反斜杠 `\` 作为路径分隔符。

---

## build-apk.ps1 (PowerShell脚本)

### 完整代码

```powershell
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
    "node_modules\@capacitor\android\capacitor\build.gradle",
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

# 特别处理filesystem的Kotlin配置
if (Test-Path "node_modules\@capacitor\filesystem\android\build.gradle") {
    (Get-Content "node_modules\@capacitor\filesystem\android\build.gradle") -replace 'jvmToolchain\(21\)', 'jvmToolchain(17)' | Set-Content "node_modules\@capacitor\filesystem\android\build.gradle"
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
```

### 关键技术点

#### 1. 错误处理策略
```powershell
$ErrorActionPreference = "Stop"
```
遇到错误立即停止执行。

#### 2. 彩色输出
```powershell
Write-Host "消息" -ForegroundColor Green
```
支持多种颜色：Cyan, Yellow, Red, Green, Gray等。

#### 3. 数组批量处理
```powershell
$files = @("file1", "file2", "file3")
foreach ($file in $files) {
    # 处理每个文件
}
```

#### 4. 目录切换
```powershell
Push-Location android  # 进入目录
# 执行操作
Pop-Location          # 返回原目录
```

#### 5. 文件大小计算
```powershell
$fileSize = (Get-Item "file.apk").Length
$fileSizeMB = [math]::Round($fileSize / 1MB, 2)
```

---

## build-apk.sh (macOS/Linux Bash脚本)

### 完整代码

```bash
#!/bin/bash
# TO-DO App APK 一键打包脚本
# 使用方法: ./build-apk.sh

set -e

echo "=========================================="
echo "  TO-DO App APK 一键打包"
echo "=========================================="

# 1. 构建Vue项目
echo ""
echo "📦 [1/5] 构建Vue项目..."
npm run build

# 2. 同步到Android
echo ""
echo "🔄 [2/5] 同步到Android项目..."
npx cap sync android

# 3. 修复Java版本配置（确保全局使用Java 17）
echo ""
echo "🔧 [3/5] 修复Java版本配置..."

# 修复 Capacitor 自动生成的配置文件
if [ -f "android/app/capacitor.build.gradle" ]; then
    sed -i '' 's/JavaVersion.VERSION_21/JavaVersion.VERSION_17/g' android/app/capacitor.build.gradle
fi

if [ -f "android/capacitor-cordova-android-plugins/build.gradle" ]; then
    sed -i '' 's/JavaVersion.VERSION_21/JavaVersion.VERSION_17/g' android/capacitor-cordova-android-plugins/build.gradle
fi

# 修复 Capacitor 核心和插件的 Java 版本
if [ -f "node_modules/@capacitor/android/capacitor/build.gradle" ]; then
    sed -i '' 's/JavaVersion.VERSION_21/JavaVersion.VERSION_17/g' node_modules/@capacitor/android/capacitor/build.gradle
fi

if [ -f "node_modules/@capacitor/local-notifications/android/build.gradle" ]; then
    sed -i '' 's/JavaVersion.VERSION_21/JavaVersion.VERSION_17/g' node_modules/@capacitor/local-notifications/android/build.gradle
fi

if [ -f "node_modules/@capacitor/filesystem/android/build.gradle" ]; then
    sed -i '' 's/JavaVersion.VERSION_21/JavaVersion.VERSION_17/g' node_modules/@capacitor/filesystem/android/build.gradle
    sed -i '' 's/jvmToolchain(21)/jvmToolchain(17)/g' node_modules/@capacitor/filesystem/android/build.gradle
fi

if [ -f "node_modules/@capacitor/preferences/android/build.gradle" ]; then
    sed -i '' 's/JavaVersion.VERSION_21/JavaVersion.VERSION_17/g' node_modules/@capacitor/preferences/android/build.gradle
fi

# 4. 构建APK
echo ""
echo "🏗️  [4/5] 构建APK..."
cd android
./gradlew clean assembleDebug
cd ..

# 5. 复制APK到项目根目录
echo ""
echo "📋 [5/5] 复制APK到项目根目录..."
cp android/app/build/outputs/apk/debug/app-debug.apk TODO-App.apk

# 完成
echo ""
echo "=========================================="
echo "✅ 打包完成！"
echo "📦 APK位置: $(pwd)/TODO-App.apk"
echo "📊 文件大小: $(ls -lh TODO-App.apk | awk '{print $5}')"
echo "=========================================="
```

### 关键技术点

#### 1. Shebang和错误处理
```bash
#!/bin/bash
set -e  # 遇到错误立即退出
```

#### 2. sed文本替换
```bash
sed -i '' 's/old/new/g' file.gradle
```
- `-i ''`: macOS需要空字符串参数
- `s/old/new/g`: 全局替换
- Linux使用 `sed -i` (不需要空字符串)

#### 3. 文件存在检查
```bash
if [ -f "file.gradle" ]; then
    # 文件存在时执行
fi
```

#### 4. 路径处理
Unix系统使用正斜杠 `/` 作为路径分隔符。

---

## 配置文件说明

### android/local.properties

此文件指定Android SDK位置，不应提交到版本控制。

**Windows示例：**
```properties
sdk.dir=C\:\\Users\\username\\AppData\\Local\\Android\\Sdk
```

**macOS示例：**
```properties
sdk.dir=/Users/username/Library/Android/sdk
```

**Linux示例：**
```properties
sdk.dir=/home/username/Android/Sdk
```

### android/gradle.properties

项目级Gradle配置。

```properties
# 内存配置
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m

# AndroidX支持
android.useAndroidX=true

# 强制使用Java 17
org.gradle.java.home=C\:\\Program Files\\Java\\jdk-17
org.gradle.java.installations.auto-detect=false
org.gradle.java.installations.auto-download=false
```

### android/gradle/wrapper/gradle-wrapper.properties

Gradle版本配置。

**使用在线下载：**
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14.3-all.zip
```

**使用本地文件：**
```properties
distributionUrl=file\:///C:/Users/username/Downloads/gradle-8.14.3-all.zip
```

---

## 自动化修复逻辑详解

### 为什么需要修复？

Capacitor 8.x 默认配置使用Java 21，但很多开发环境使用Java 17。需要自动修复以下问题：

1. **Java版本不匹配**
   - Capacitor核心：`JavaVersion.VERSION_21` → `VERSION_17`
   - 各个插件：同样的修改

2. **Kotlin Toolchain版本**
   - filesystem插件：`jvmToolchain(21)` → `jvmToolchain(17)`

### 修复的文件列表

| 文件路径 | 修复内容 |
|---------|---------|
| `android/app/capacitor.build.gradle` | Java版本 |
| `android/capacitor-cordova-android-plugins/build.gradle` | Java版本 |
| `node_modules/@capacitor/android/capacitor/build.gradle` | Java版本 |
| `node_modules/@capacitor/filesystem/android/build.gradle` | Java版本 + Kotlin Toolchain |
| `node_modules/@capacitor/local-notifications/android/build.gradle` | Java版本 |
| `node_modules/@capacitor/preferences/android/build.gradle` | Java版本 |

### 修复时机

脚本在每次构建时都会执行修复，因为：
1. `npx cap sync` 可能会重新生成某些配置文件
2. `npm install` 会重新安装node_modules
3. 确保构建环境一致性

---

## 扩展和自定义

### 添加新的Capacitor插件

如果添加了新的Capacitor插件，需要在脚本中添加修复逻辑：

**Windows (build-apk.bat):**
```batch
if exist "node_modules\@capacitor\new-plugin\android\build.gradle" (
    powershell -Command "(Get-Content 'node_modules\@capacitor\new-plugin\android\build.gradle') -replace 'JavaVersion.VERSION_21', 'JavaVersion.VERSION_17' | Set-Content 'node_modules\@capacitor\new-plugin\android\build.gradle'"
)
```

**macOS (build-apk.sh):**
```bash
if [ -f "node_modules/@capacitor/new-plugin/android/build.gradle" ]; then
    sed -i '' 's/JavaVersion.VERSION_21/JavaVersion.VERSION_17/g' node_modules/@capacitor/new-plugin/android/build.gradle
fi
```

### 构建Release版本

修改脚本中的构建命令：

```batch
:: Debug版本
call gradlew.bat clean assembleDebug

:: Release版本
call gradlew.bat clean assembleRelease
```

Release APK位置：`android/app/build/outputs/apk/release/app-release.apk`

### 添加签名配置

在脚本中添加签名步骤：

```batch
:: 签名APK
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore todo-app.keystore android\app\build\outputs\apk\release\app-release-unsigned.apk todo-app

:: 对齐APK
zipalign -v 4 android\app\build\outputs\apk\release\app-release-unsigned.apk TODO-App-signed.apk
```

---

## 性能优化建议

### 1. 并行构建

在 `android/gradle.properties` 中启用：
```properties
org.gradle.parallel=true
org.gradle.configureondemand=true
```

### 2. 构建缓存

```properties
org.gradle.caching=true
```

### 3. 增量构建

避免每次都执行 `clean`：
```batch
:: 仅在需要时clean
call gradlew.bat assembleDebug
```

### 4. 使用Gradle Daemon

```properties
org.gradle.daemon=true
```

---

## 故障排查命令

### 查看详细构建日志

```batch
.\gradlew.bat assembleDebug --info
```

### 查看依赖树

```batch
.\gradlew.bat :app:dependencies
```

### 清理所有缓存

```batch
.\gradlew.bat clean cleanBuildCache
rd /s /q .gradle
rd /s /q android\.gradle
```

### 验证Java配置

```batch
.\gradlew.bat -version
java -version
echo %JAVA_HOME%
```

---

## 最佳实践

1. **版本控制**
   - 提交 `build-apk.bat`, `build-apk.sh`, `build-apk.ps1`
   - 不提交 `android/local.properties`
   - 不提交 `TODO-App.apk`

2. **团队协作**
   - 在README中说明构建步骤
   - 统一Java版本（推荐Java 17）
   - 共享Gradle配置

3. **持续集成**
   - 在CI/CD中使用这些脚本
   - 设置环境变量
   - 缓存Gradle依赖

4. **安全性**
   - 不在脚本中硬编码密码
   - 使用环境变量存储敏感信息
   - Release版本使用独立的签名配置

---

**文档版本：** 1.0  
**最后更新：** 2026年2月21日
