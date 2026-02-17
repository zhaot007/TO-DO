# Android APK 打包流程文档 | APK Build Process

**文档版本**: v1.1  
**创建日期**: 2026-02-17  
**适用项目**: TO-DO App (Vue 3 + Capacitor)  
**验证状态**: ✅ 已验证成功

---

## 📋 目录

1. [环境要求](#环境要求)
2. [前置准备](#前置准备)
3. [完整打包流程](#完整打包流程)
4. [关键问题与解决方案](#关键问题与解决方案)
5. [自动化脚本](#自动化脚本)
6. [验证与测试](#验证与测试)
7. [常见问题排查](#常见问题排查)

---

## 🔧 环境要求

### 必需软件
- **Node.js**: >= 16.0.0
- **npm**: >= 8.0.0
- **Java JDK**: 17 (必须是17，不能是11或21)
- **Gradle**: 由项目自带，无需单独安装

### 环境变量配置
```bash
# 查看已安装的Java版本
/usr/libexec/java_home -V

# 应该看到类似输出：
# 17.0.2 (arm64) "Eclipse Temurin" - "Eclipse Temurin 17"

# 设置JAVA_HOME（临时）
export JAVA_HOME=/Users/你的用户名/Library/Java/JavaVirtualMachines/jdk-17.0.2+8/Contents/Home

# 验证Java版本
java -version
# 应该显示: openjdk version "17.0.2"
```

### 项目依赖检查
```bash
# 进入项目目录
cd /path/to/TO-DO

# 检查package.json中的依赖
cat package.json | grep -A 10 "dependencies"

# 必需的依赖：
# - @capacitor/core: ^8.1.0
# - @capacitor/cli: ^8.1.0
# - @capacitor/android: ^8.1.0
# - @capacitor/preferences: ^8.0.1
```

---

## 📦 前置准备

### 步骤1: 安装项目依赖
```bash
# 在项目根目录执行
npm install

# 验证安装成功
ls node_modules/@capacitor
# 应该看到: android  cli  core  preferences
```

### 步骤2: 检查Capacitor配置
```bash
# 查看配置文件
cat capacitor.config.json
```

**正确的配置内容**：
```json
{
  "appId": "com.todo.app",
  "appName": "TODO App",
  "webDir": "dist",
  "server": {
    "androidScheme": "https",
    "cleartext": true
  }
}
```

### 步骤3: 确认Android项目存在
```bash
# 检查android目录
ls -la android/

# 如果不存在，需要先添加Android平台
npx cap add android
```

---

## 🚀 完整打包流程

### 第一步: 构建Vue项目

```bash
# 清理旧的构建产物（可选）
rm -rf dist/

# 构建生产版本
npm run build

# 验证构建成功
ls -la dist/
# 应该看到: index.html, assets/目录
```

**预期输出**：
```
vite v6.4.1 building for production...
✓ 1458 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                     0.47 kB │ gzip:   0.32 kB
dist/assets/index-xxx.css         363.18 kB │ gzip:  50.08 kB
dist/assets/web-xxx.js              1.25 kB │ gzip:   0.58 kB
dist/assets/index-xxx.js        1,048.48 kB │ gzip: 342.35 kB
✓ built in 1.68s
```

---

### 第二步: 同步到Android项目

```bash
# 同步Web资源到Android
npx cap sync android
```

**预期输出**：
```
✔ Copying web assets from dist to android/app/src/main/assets/public in 2.64ms
✔ Creating capacitor.config.json in android/app/src/main/assets in 245.67μs
✔ copy android in 6.16ms
✔ Updating Android plugins in 1.08ms
[info] Found 1 Capacitor plugin for android:
       @capacitor/preferences@8.0.1
✔ update android in 18.56ms
[info] Sync finished in 0.029s
```

---

### 第三步: 修复Java版本配置 ⚠️ 关键步骤

**问题原因**: Capacitor默认使用Java 21，但系统只有Java 17

**解决方案**: 批量修改Gradle配置文件

```bash
# 方法1: 使用sed命令批量替换（推荐）
sed -i '' 's/VERSION_21/VERSION_17/g' android/app/capacitor.build.gradle
sed -i '' 's/VERSION_21/VERSION_17/g' android/capacitor-cordova-android-plugins/build.gradle
sed -i '' 's/VERSION_21/VERSION_17/g' node_modules/@capacitor/android/capacitor/build.gradle
sed -i '' 's/VERSION_21/VERSION_17/g' node_modules/@capacitor/preferences/android/build.gradle

# 方法2: 手动编辑（备选）
# 编辑以下文件，将所有 JavaVersion.VERSION_21 改为 JavaVersion.VERSION_17
# - android/app/capacitor.build.gradle
# - android/capacitor-cordova-android-plugins/build.gradle
# - node_modules/@capacitor/android/capacitor/build.gradle
# - node_modules/@capacitor/preferences/android/build.gradle
```

**验证修改成功**：
```bash
# 检查是否还有VERSION_21
grep -r "VERSION_21" android/ node_modules/@capacitor/android/ node_modules/@capacitor/preferences/ --include="*.gradle"

# 如果没有输出，说明修改成功
```

---

### 第四步: 构建Android APK

```bash
# 设置Java 17环境变量
export JAVA_HOME=/Users/你的用户名/Library/Java/JavaVirtualMachines/jdk-17.0.2+8/Contents/Home

# 或使用自动查找（推荐）
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

# 验证Java版本
java -version
# 必须显示: openjdk version "17.0.2"

# 进入Android目录
cd android

# 清理旧的构建（可选，首次构建可跳过）
./gradlew clean

# 构建Debug版APK
./gradlew assembleDebug

# 返回项目根目录
cd ..
```

**预期输出**：
```
BUILD SUCCESSFUL in 30s
123 actionable tasks: 93 executed, 30 up-to-date
```

**如果失败，查看错误信息**：
```bash
# 查看详细错误
cd android
./gradlew assembleDebug --stacktrace
```

---

### 第五步: 获取APK文件

```bash
# APK位置
ls -lh android/app/build/outputs/apk/debug/app-debug.apk

# 复制到项目根目录（方便分发）
cp android/app/build/outputs/apk/debug/app-debug.apk ./TODO-App.apk

# 查看APK信息
ls -lh TODO-App.apk
# 应该显示: 4.4M TODO-App.apk
```

---

## ⚠️ 关键问题与解决方案

### 问题1: Java版本不匹配

**错误信息**：
```
error: invalid source release: 21
```

**原因**: Capacitor生成的配置使用Java 21，但系统只有Java 17

**解决方案**: 执行第三步的sed命令，将所有VERSION_21改为VERSION_17

**验证**: 
```bash
grep -r "VERSION_17" android/app/capacitor.build.gradle
# 应该看到: sourceCompatibility JavaVersion.VERSION_17
```

---

### 问题2: Gradle缓存导致构建失败

**错误信息**：
```
BUILD FAILED in 1s
```

**解决方案**：
```bash
# 清理Gradle缓存
cd android
rm -rf .gradle build
./gradlew clean

# 重新构建
./gradlew assembleDebug
```

---

### 问题3: npx cap sync后配置被重置

**现象**: 每次执行`npx cap sync`后，Java版本配置又变回VERSION_21

**原因**: Capacitor会重新生成配置文件

**解决方案**: 在每次sync后都执行sed命令
```bash
npx cap sync android
sed -i '' 's/VERSION_21/VERSION_17/g' android/app/capacitor.build.gradle
sed -i '' 's/VERSION_21/VERSION_17/g' android/capacitor-cordova-android-plugins/build.gradle
```

---

### 问题4: node_modules中的配置也需要修改

**原因**: Capacitor插件的配置也使用VERSION_21

**必须修改的文件**：
1. `node_modules/@capacitor/android/capacitor/build.gradle`
2. `node_modules/@capacitor/preferences/android/build.gradle`

**解决方案**: 使用完整的sed命令（见第三步）

---

## 🤖 自动化脚本

### 一键打包脚本

创建文件 `build-apk.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 开始构建Android APK..."
echo "================================"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 步骤1: 检查Java版本
echo -e "${YELLOW}📋 步骤1: 检查Java版本...${NC}"
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
echo "Java版本: $JAVA_VERSION"

if [[ ! $JAVA_VERSION == 17.* ]]; then
    echo -e "${RED}❌ 错误: 需要Java 17，当前版本: $JAVA_VERSION${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Java版本检查通过${NC}"
echo ""

# 步骤2: 清理旧构建
echo -e "${YELLOW}📋 步骤2: 清理旧构建产物...${NC}"
rm -rf dist/
echo -e "${GREEN}✅ 清理完成${NC}"
echo ""

# 步骤3: 构建Vue项目
echo -e "${YELLOW}📋 步骤3: 构建Vue项目...${NC}"
npm run build
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Vue构建失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Vue构建成功${NC}"
echo ""

# 步骤4: 同步到Android
echo -e "${YELLOW}📋 步骤4: 同步到Android项目...${NC}"
npx cap sync android
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 同步失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 同步成功${NC}"
echo ""

# 步骤5: 修复Java版本配置
echo -e "${YELLOW}📋 步骤5: 修复Java版本配置...${NC}"
sed -i '' 's/VERSION_21/VERSION_17/g' android/app/capacitor.build.gradle
sed -i '' 's/VERSION_21/VERSION_17/g' android/capacitor-cordova-android-plugins/build.gradle
sed -i '' 's/VERSION_21/VERSION_17/g' node_modules/@capacitor/android/capacitor/build.gradle
sed -i '' 's/VERSION_21/VERSION_17/g' node_modules/@capacitor/preferences/android/build.gradle
echo -e "${GREEN}✅ 配置修复完成${NC}"
echo ""

# 步骤6: 构建APK
echo -e "${YELLOW}📋 步骤6: 构建Android APK...${NC}"
cd android
./gradlew clean assembleDebug
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ APK构建失败${NC}"
    exit 1
fi
cd ..
echo -e "${GREEN}✅ APK构建成功${NC}"
echo ""

# 步骤7: 复制APK
echo -e "${YELLOW}📋 步骤7: 复制APK到项目根目录...${NC}"
cp android/app/build/outputs/apk/debug/app-debug.apk ./TODO-App.apk
APK_SIZE=$(ls -lh TODO-App.apk | awk '{print $5}')
echo -e "${GREEN}✅ APK已生成: TODO-App.apk (${APK_SIZE})${NC}"
echo ""

# 完成
echo "================================"
echo -e "${GREEN}🎉 构建完成！${NC}"
echo ""
echo "📱 APK位置: $(pwd)/TODO-App.apk"
echo "📦 APK大小: $APK_SIZE"
echo ""
echo "安装方法:"
echo "1. 将APK传输到Android设备"
echo "2. 开启'允许安装未知来源应用'"
echo "3. 点击APK文件安装"
```

**使用方法**：
```bash
# 添加执行权限
chmod +x build-apk.sh

# 执行脚本
./build-apk.sh
```

---

### 快速打包命令（单行）

```bash
# 适合熟练后使用
npm run build && npx cap sync android && sed -i '' 's/VERSION_21/VERSION_17/g' android/app/capacitor.build.gradle android/capacitor-cordova-android-plugins/build.gradle node_modules/@capacitor/android/capacitor/build.gradle node_modules/@capacitor/preferences/android/build.gradle && export JAVA_HOME=$(/usr/libexec/java_home -v 17) && cd android && ./gradlew assembleDebug && cd .. && cp android/app/build/outputs/apk/debug/app-debug.apk ./TODO-App.apk && ls -lh TODO-App.apk
```

---

## ✅ 验证与测试

### 构建成功的标志

1. **终端输出**：
```
BUILD SUCCESSFUL in 30s
123 actionable tasks: 93 executed, 30 up-to-date
```

2. **APK文件存在**：
```bash
ls -lh TODO-App.apk
# 输出: -rw-r--r--  1 user  staff   4.4M Feb 17 19:53 TODO-App.apk
```

3. **APK大小合理**：约4.4MB

---

### 安装测试

```bash
# 方法1: 使用adb安装（需要连接设备）
adb devices
adb install TODO-App.apk

# 方法2: 传输到手机手动安装
# 1. 通过USB、云盘、微信等方式传输APK到手机
# 2. 在手机上点击APK文件
# 3. 允许安装未知来源应用
# 4. 点击安装
```

---

### 功能测试清单

安装后测试以下功能：

- [ ] 应用能正常启动
- [ ] 显示登录页面
- [ ] 能注册新用户
- [ ] 能登录已注册用户
- [ ] 能添加任务
- [ ] 能编辑任务
- [ ] 能删除任务
- [ ] 能查看回收站
- [ ] 能恢复任务
- [ ] 数据持久化（关闭重开应用数据还在）
- [ ] 筛选功能正常
- [ ] 退出登录正常

---

## 🔍 常见问题排查

### 问题: BUILD FAILED

**排查步骤**：

1. **查看详细错误**：
```bash
cd android
./gradlew assembleDebug --stacktrace
```

2. **检查Java版本**：
```bash
java -version
# 必须是17.x.x
```

3. **检查配置文件**：
```bash
grep "VERSION_" android/app/capacitor.build.gradle
# 应该全是VERSION_17
```

4. **清理重建**：
```bash
cd android
rm -rf .gradle build
./gradlew clean
./gradlew assembleDebug
```

---

### 问题: APK安装失败

**可能原因**：

1. **未开启未知来源安装**
   - 解决: 设置 → 安全 → 允许安装未知来源应用

2. **APK损坏**
   - 解决: 重新构建APK

3. **签名问题**
   - 解决: Debug版本无需签名，如果是Release版本需要配置签名

---

### 问题: 应用闪退

**排查方法**：

```bash
# 连接设备查看日志
adb logcat | grep "Capacitor"

# 或查看完整日志
adb logcat > app.log
```

**常见原因**：
- JavaScript错误
- 路由配置问题
- 本地存储权限问题

---

## 📝 打包检查清单

每次打包前检查：

- [ ] 代码已提交到Git
- [ ] package.json版本号已更新
- [ ] CHANGELOG.md已更新
- [ ] Java 17环境已配置
- [ ] node_modules已安装
- [ ] dist目录已清理

打包过程中：

- [ ] Vue构建成功
- [ ] Capacitor同步成功
- [ ] Java版本配置已修复
- [ ] Gradle构建成功
- [ ] APK文件已生成

打包完成后：

- [ ] APK大小正常（约4.4MB）
- [ ] APK能正常安装
- [ ] 应用能正常启动
- [ ] 核心功能测试通过
- [ ] APK已备份

---

## 📚 参考资料

- [Capacitor官方文档](https://capacitorjs.com/docs)
- [Android Gradle插件文档](https://developer.android.com/studio/build)
- [Vite构建文档](https://vitejs.dev/guide/build.html)

---

## 📋 版本记录

| 版本 | 日期 | 说明 |
|-----|------|------|
| v1.0 | 2026-02-17 | 初始版本，记录成功的打包流程 |

---

**文档维护者**: 开发团队  
**最后更新**: 2026-02-17  
**验证状态**: ✅ 已在macOS上验证成功
