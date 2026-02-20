# Android APK 构建完整指南

## 目录
- [环境要求](#环境要求)
- [Windows 构建步骤](#windows-构建步骤)
- [macOS 构建步骤](#macos-构建步骤)
- [常见问题解决](#常见问题解决)
- [构建脚本说明](#构建脚本说明)

---

## 环境要求

### 必需软件

1. **Node.js** (推荐 v16+)
   - 用于构建Vue项目
   - 下载：https://nodejs.org/

2. **Android Studio**
   - 提供Android SDK和构建工具
   - 下载：https://developer.android.com/studio
   - 安装后确保SDK路径：`C:\Users\<用户名>\AppData\Local\Android\Sdk` (Windows)

3. **Java JDK 17**
   - 项目配置为使用Java 17
   - 下载：https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html
   - 设置环境变量 `JAVA_HOME=C:\Program Files\Java\jdk-17`

4. **Gradle 8.14.3**
   - 项目已配置使用此版本
   - 可通过gradlew自动下载，或手动下载：https://gradle.org/releases/

### 环境变量配置

**Windows:**
```bash
# 系统环境变量
JAVA_HOME=C:\Program Files\Java\jdk-17
ANDROID_HOME=C:\Users\<用户名>\AppData\Local\Android\Sdk

# Path中添加
%JAVA_HOME%\bin
%ANDROID_HOME%\platform-tools
%ANDROID_HOME%\tools
```

**macOS/Linux:**
```bash
# 添加到 ~/.bash_profile 或 ~/.zshrc
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools
```

---

## Windows 构建步骤

### 方式一：使用一键构建脚本（推荐）

1. 确保已安装所有必需软件
2. 在项目根目录运行：
   ```bash
   .\build-apk.bat
   ```
3. 等待构建完成，APK将生成在项目根目录：`TODO-App.apk`

### 方式二：手动构建

```bash
# 1. 构建Vue项目
npm run build

# 2. 同步到Android
npx cap sync android

# 3. 修复Java版本配置（如果需要）
# 见下方"Java版本修复"章节

# 4. 构建APK
cd android
.\gradlew.bat clean assembleDebug
cd ..

# 5. 复制APK
copy android\app\build\outputs\apk\debug\app-debug.apk TODO-App.apk
```

---

## macOS 构建步骤

### 使用一键构建脚本

1. 给脚本添加执行权限：
   ```bash
   chmod +x build-apk.sh
   ```

2. 运行脚本：
   ```bash
   ./build-apk.sh
   ```

3. APK将生成在项目根目录：`TODO-App.apk`

---

## 常见问题解决

### 问题1：SDK location not found

**错误信息：**
```
SDK location not found. Define a valid SDK location with an ANDROID_HOME 
environment variable or by setting the sdk.dir path in your project's 
local properties file
```

**解决方案：**

创建 `android/local.properties` 文件：

**Windows:**
```properties
sdk.dir=C\:\\Users\\<用户名>\\AppData\\Local\\Android\\Sdk
```

**macOS:**
```properties
sdk.dir=/Users/<用户名>/Library/Android/sdk
```

### 问题2：Cannot find Java installation matching languageVersion=21

**错误信息：**
```
Cannot find a Java installation on your machine matching: 
{languageVersion=21, vendor=any vendor, implementation=vendor-specific}
```

**原因：**
Capacitor 8.x 默认使用Java 21，但系统安装的是Java 17。

**解决方案：**

#### 方案A：修改Gradle配置（推荐）

在 `android/gradle.properties` 中添加：
```properties
# Force Java 17 for all modules
org.gradle.java.home=C\:\\Program Files\\Java\\jdk-17
org.gradle.java.installations.auto-detect=false
org.gradle.java.installations.auto-download=false
```

#### 方案B：修改Capacitor插件配置

需要修改以下文件中的Java版本：

1. `node_modules/@capacitor/android/capacitor/build.gradle`
2. `node_modules/@capacitor/filesystem/android/build.gradle`
3. `node_modules/@capacitor/local-notifications/android/build.gradle`
4. `node_modules/@capacitor/preferences/android/build.gradle`

将 `JavaVersion.VERSION_21` 替换为 `JavaVersion.VERSION_17`

**特别注意：** `filesystem` 插件还需要修改Kotlin配置：
```gradle
kotlin {
    jvmToolchain(17)  // 从21改为17
}
```

### 问题3：Gradle下载缓慢

**解决方案：**

1. 手动下载Gradle：https://gradle.org/releases/
2. 修改 `android/gradle/wrapper/gradle-wrapper.properties`：
   ```properties
   distributionUrl=file\:///C:/Users/<用户名>/Downloads/gradle-8.14.3-all.zip
   ```

### 问题4：构建过程中内存不足

**解决方案：**

在 `android/gradle.properties` 中调整内存：
```properties
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m
```

---

## 构建脚本说明

### build-apk.bat (Windows)

脚本执行5个步骤：

1. **构建Vue项目** - 生成dist目录
2. **同步到Android** - 将web资源复制到Android项目
3. **修复Java版本配置** - 自动修改Capacitor插件的Java版本要求
4. **构建APK** - 使用Gradle构建debug版本APK
5. **复制APK** - 将APK复制到项目根目录

### build-apk.sh (macOS/Linux)

功能与Windows版本相同，使用bash语法。

### 关键修复逻辑

脚本会自动执行以下修复：

```batch
:: 修复Capacitor核心
node_modules\@capacitor\android\capacitor\build.gradle
VERSION_21 → VERSION_17

:: 修复filesystem插件
node_modules\@capacitor\filesystem\android\build.gradle
VERSION_21 → VERSION_17
jvmToolchain(21) → jvmToolchain(17)

:: 修复其他插件
node_modules\@capacitor\local-notifications\android\build.gradle
node_modules\@capacitor\preferences\android\build.gradle
VERSION_21 → VERSION_17
```

---

## 构建产物说明

### Debug APK
- 文件名：`TODO-App.apk` 或 `app-debug.apk`
- 位置：项目根目录 或 `android/app/build/outputs/apk/debug/`
- 大小：约4-5 MB
- 用途：测试和开发

### Release APK（生产版本）

如需构建生产版本：

```bash
# Windows
cd android
.\gradlew.bat assembleRelease

# macOS/Linux
cd android
./gradlew assembleRelease
```

Release APK位置：`android/app/build/outputs/apk/release/app-release.apk`

**注意：** Release版本需要签名才能安装。

---

## 签名配置（可选）

### 生成签名密钥

```bash
keytool -genkey -v -keystore todo-app.keystore -alias todo-app -keyalg RSA -keysize 2048 -validity 10000
```

### 配置签名

在 `android/app/build.gradle` 中添加：

```gradle
android {
    signingConfigs {
        release {
            storeFile file("../../todo-app.keystore")
            storePassword "your-password"
            keyAlias "todo-app"
            keyPassword "your-password"
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## 版本管理

### 修改应用版本

编辑 `android/app/build.gradle`：

```gradle
defaultConfig {
    applicationId "com.todo.app"
    minSdkVersion 24
    targetSdkVersion 36
    versionCode 2        // 每次发布递增
    versionName "1.5.8"  // 显示给用户的版本号
}
```

### 修改应用名称

编辑 `android/app/src/main/res/values/strings.xml`：

```xml
<resources>
    <string name="app_name">TODO App</string>
    <string name="title_activity_main">TODO App</string>
</resources>
```

---

## 性能优化建议

### 1. 启用代码混淆（Release版本）

```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### 2. 启用多APK支持

```gradle
android {
    splits {
        abi {
            enable true
            reset()
            include 'armeabi-v7a', 'arm64-v8a', 'x86', 'x86_64'
            universalApk true
        }
    }
}
```

### 3. 优化Vue构建

在 `vite.config.js` 中：

```javascript
export default {
  build: {
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true
      }
    },
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor': ['vue', 'vue-router', 'pinia']
        }
      }
    }
  }
}
```

---

## 故障排查清单

构建失败时，按顺序检查：

- [ ] Java版本是否为17？ `java -version`
- [ ] JAVA_HOME是否正确设置？ `echo %JAVA_HOME%` (Windows) 或 `echo $JAVA_HOME` (macOS)
- [ ] Android SDK是否安装？检查路径是否存在
- [ ] `android/local.properties` 是否正确配置？
- [ ] Node.js依赖是否安装？ `npm install`
- [ ] Gradle缓存是否损坏？尝试 `.\gradlew.bat clean --refresh-dependencies`
- [ ] 是否有足够的磁盘空间？（至少需要5GB）

---

## 相关文件清单

```
项目根目录/
├── build-apk.bat              # Windows构建脚本
├── build-apk.sh               # macOS/Linux构建脚本
├── build-apk.ps1              # PowerShell构建脚本
├── android/
│   ├── local.properties       # Android SDK配置（需创建）
│   ├── gradle.properties      # Gradle配置
│   ├── build.gradle           # 项目级构建配置
│   ├── app/build.gradle       # 应用级构建配置
│   └── gradle/wrapper/
│       └── gradle-wrapper.properties  # Gradle版本配置
├── capacitor.config.json      # Capacitor配置
└── package.json               # 项目依赖
```

---

## 更新日志

### 2026-02-21
- 初始版本
- 支持Java 17构建
- 添加自动修复脚本
- 完善Windows和macOS构建流程

---

## 技术支持

如遇到问题，请检查：
1. 本文档的"常见问题解决"章节
2. Capacitor官方文档：https://capacitorjs.com/docs/android
3. Android开发者文档：https://developer.android.com/studio/build

---

**最后更新：** 2026年2月21日
