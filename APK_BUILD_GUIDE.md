# Android APK 打包流程文档 | APK Build Process

**文档版本**: v1.4.0  
**最后更新**: 2026-02-19  
**适用项目**: TO-DO App (Vue 3 + Capacitor 8 + Vite 6)  
**验证状态**: ✅ 已在 v1.4.0 代码基准上验证成功

---

## 🔧 环境要求

- **Node.js**: >= 22.0.0
- **Java JDK**: 17 (必须，不支持 21)
- **Android SDK**: API Level 34+

---

## 🚀 自动化打包 (推荐)

项目根目录提供了一键打包脚本 `build-apk.sh`，它会自动执行 Vue 构建、Capacitor 同步、Java 版本修复以及 APK 生成。

```bash
# 添加权限
chmod +x build-apk.sh

# 执行打包
./build-apk.sh
```

### 脚本核心修复逻辑 (Java 17 兼容)
由于 Capacitor 8 默认生成 Java 21 配置，脚本会自动修复以下文件以兼容 Java 17 环境：
1. `android/app/capacitor.build.gradle`
2. `android/capacitor-cordova-android-plugins/build.gradle`
3. `node_modules/@capacitor/` 目录下的所有插件配置

---

## 📦 手动打包步骤

1. **构建前端**: `npm run build`
2. **同步平台**: `npx cap sync android`
3. **修复 Java**: 将上述文件的 `JavaVersion.VERSION_21` 改为 `JavaVersion.VERSION_17`。
4. **生成 APK**:
   ```bash
   cd android
   ./gradlew assembleDebug
   ```
5. **获取结果**: APK 位于 `android/app/build/outputs/apk/debug/app-debug.apk`。

---

## 🔍 常见问题

- **错误: invalid source release: 21**: 说明 Java 版本未修复，请确保运行了脚本中的 `sed` 替换逻辑。
- **构建卡死**: 请尝试运行 `cd android && ./gradlew clean`。

---

**维护者**: zhaosj 的助手
