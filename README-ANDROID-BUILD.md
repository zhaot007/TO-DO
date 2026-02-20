# Android APK 构建快速指南

> 本项目支持一键构建Android APK，适用于Windows、macOS和Linux系统。

## 🚀 快速开始

### Windows用户

```bash
# 方式1：批处理脚本（推荐）
.\build-apk.bat

# 方式2：PowerShell脚本
powershell -ExecutionPolicy Bypass -File build-apk.ps1
```

### macOS/Linux用户

```bash
# 添加执行权限（首次运行）
chmod +x build-apk.sh

# 运行脚本
./build-apk.sh
```

构建完成后，APK文件将生成在项目根目录：`TODO-App.apk`

---

## 📋 环境要求

在运行构建脚本前，请确保已安装：

- ✅ **Node.js** (v16+)
- ✅ **Java JDK 17** 
- ✅ **Android Studio** (提供Android SDK)
- ✅ **Gradle 8.14.3** (通过gradlew自动管理)

### 环境变量配置

**Windows:**
```
JAVA_HOME=C:\Program Files\Java\jdk-17
ANDROID_HOME=C:\Users\<用户名>\AppData\Local\Android\Sdk
```

**macOS:**
```bash
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
export ANDROID_HOME=$HOME/Library/Android/sdk
```

---

## 🔧 首次构建配置

### 1. 创建Android SDK配置文件

创建 `android/local.properties` 文件：

**Windows:**
```properties
sdk.dir=C\:\\Users\\<用户名>\\AppData\\Local\\Android\\Sdk
```

**macOS:**
```properties
sdk.dir=/Users/<用户名>/Library/Android/sdk
```

### 2. 配置Gradle（可选）

如果已下载Gradle，可在 `android/gradle/wrapper/gradle-wrapper.properties` 中配置本地路径：

```properties
distributionUrl=file\:///C:/Users/<用户名>/Downloads/gradle-8.14.3-all.zip
```

---

## 📦 构建流程说明

脚本会自动执行以下5个步骤：

1. **📦 构建Vue项目** - 生成dist目录
2. **🔄 同步到Android** - 将web资源复制到Android项目
3. **🔧 修复Java版本** - 自动修改Capacitor插件配置（Java 21 → Java 17）
4. **🏗️ 构建APK** - 使用Gradle构建debug版本
5. **📋 复制APK** - 将APK复制到项目根目录

---

## ❓ 常见问题

### Q1: 提示"SDK location not found"

**解决方案：** 创建 `android/local.properties` 文件并配置SDK路径（见上方"首次构建配置"）

### Q2: 提示"Cannot find Java installation matching languageVersion=21"

**解决方案：** 脚本会自动修复此问题。如果仍然失败，请确保：
- 已安装Java 17
- JAVA_HOME环境变量正确设置

### Q3: Gradle下载缓慢

**解决方案：** 
1. 手动下载Gradle：https://gradle.org/releases/
2. 配置本地路径（见上方"首次构建配置"）

### Q4: 构建失败

**排查步骤：**
```bash
# 检查Java版本
java -version

# 检查环境变量
echo %JAVA_HOME%        # Windows
echo $JAVA_HOME         # macOS/Linux

# 清理缓存重试
cd android
.\gradlew.bat clean --refresh-dependencies  # Windows
./gradlew clean --refresh-dependencies      # macOS/Linux
```

---

## 📚 详细文档

- **[完整构建指南](docs/android-apk-build-guide.md)** - 详细的环境配置、故障排查和优化建议
- **[脚本参考文档](docs/android-build-scripts-reference.md)** - 脚本实现细节和自定义方法

---

## 🔄 构建Release版本

如需构建生产版本APK：

```bash
# Windows
cd android
.\gradlew.bat assembleRelease

# macOS/Linux
cd android
./gradlew assembleRelease
```

Release APK位置：`android/app/build/outputs/apk/release/app-release.apk`

**注意：** Release版本需要配置签名才能安装到设备。

---

## 📱 安装APK到设备

### 方法1：通过USB连接

```bash
# 确保已启用USB调试
adb install TODO-App.apk
```

### 方法2：直接传输

将 `TODO-App.apk` 文件传输到Android设备，直接点击安装。

---

## 🛠️ 项目结构

```
项目根目录/
├── build-apk.bat              # Windows批处理脚本
├── build-apk.sh               # macOS/Linux Bash脚本
├── build-apk.ps1              # Windows PowerShell脚本
├── README-ANDROID-BUILD.md    # 本文档
├── docs/
│   ├── android-apk-build-guide.md          # 完整构建指南
│   └── android-build-scripts-reference.md  # 脚本参考文档
├── android/
│   ├── local.properties       # SDK配置（需手动创建）
│   ├── gradle.properties      # Gradle配置
│   └── app/build.gradle       # 应用构建配置
└── capacitor.config.json      # Capacitor配置
```

---

## 🤝 贡献

如果您在构建过程中遇到问题或有改进建议，欢迎：
- 提交Issue
- 提交Pull Request
- 完善文档

---

## 📄 许可证

MIT License

---

**最后更新：** 2026年2月21日  
**项目版本：** 1.5.7
