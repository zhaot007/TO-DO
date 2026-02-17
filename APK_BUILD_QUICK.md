# APK打包快速参考 | Quick Reference

**适用项目**: TO-DO App  
**验证状态**: ✅ 已验证成功

---

## ⚡ 快速打包（5步）

### 1️⃣ 构建Vue
```bash
npm run build
```

### 2️⃣ 同步Android
```bash
npx cap sync android
```

### 3️⃣ 修复Java版本 ⚠️ 必须执行
```bash
sed -i '' 's/VERSION_21/VERSION_17/g' android/app/capacitor.build.gradle
sed -i '' 's/VERSION_21/VERSION_17/g' android/capacitor-cordova-android-plugins/build.gradle
sed -i '' 's/VERSION_21/VERSION_17/g' node_modules/@capacitor/android/capacitor/build.gradle
sed -i '' 's/VERSION_21/VERSION_17/g' node_modules/@capacitor/preferences/android/build.gradle
```

### 4️⃣ 构建APK
```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
cd android
./gradlew assembleDebug
cd ..
```

### 5️⃣ 获取APK
```bash
cp android/app/build/outputs/apk/debug/app-debug.apk ./TODO-App.apk
ls -lh TODO-App.apk
```

---

## 🤖 一键打包

```bash
./build-apk.sh
```

或单行命令：
```bash
npm run build && npx cap sync android && sed -i '' 's/VERSION_21/VERSION_17/g' android/app/capacitor.build.gradle android/capacitor-cordova-android-plugins/build.gradle node_modules/@capacitor/android/capacitor/build.gradle node_modules/@capacitor/preferences/android/build.gradle && export JAVA_HOME=$(/usr/libexec/java_home -v 17) && cd android && ./gradlew assembleDebug && cd .. && cp android/app/build/outputs/apk/debug/app-debug.apk ./TODO-App.apk
```

---

## ⚠️ 关键注意事项

1. **必须使用Java 17**（不能是11或21）
2. **每次sync后必须执行步骤3**（修复Java版本）
3. **4个文件都要修改**（android/、node_modules/下各2个）
4. **APK大小约4.4MB**（如果差异很大说明有问题）

---

## 🔍 快速排查

**构建失败？**
```bash
# 检查Java版本
java -version  # 必须是17.x.x

# 检查配置
grep "VERSION_" android/app/capacitor.build.gradle

# 清理重建
cd android && rm -rf .gradle build && ./gradlew clean && cd ..
```

**APK位置？**
```bash
android/app/build/outputs/apk/debug/app-debug.apk
```

---

## 📱 安装测试

```bash
# USB安装
adb install TODO-App.apk

# 或传输到手机手动安装
```

---

详细文档请查看: `APK_BUILD_GUIDE.md`
