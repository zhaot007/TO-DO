# 项目打包说明

本项目支持多平台打包，包括 Android APK 和 Windows Electron 应用。

## 快速开始

### Android APK 打包

```bash
# 使用脚本（推荐）
./build-release-apk.sh

# 或手动执行
npm run build
npx cap sync android
cd android
./gradlew assembleRelease
```

输出文件：`android/app/build/outputs/apk/release/app-release.apk`

### Windows Electron 打包

```bash
# 使用脚本（推荐）
./build-electron-win.sh

# 或使用 bat 脚本（Windows CMD）
build-electron-win.bat

# 或使用 npm 命令
npm run electron:build-win
```

输出文件：`release/TODO App Setup 1.5.7.exe`

## 打包脚本说明

### Android 打包脚本
- `build-release-apk.sh` - Android APK 构建脚本

### Windows 打包脚本
- `build-electron-win.sh` - Windows Electron 构建脚本（Git Bash）
- `build-electron-win.bat` - Windows Electron 构建脚本（CMD/PowerShell）✅ 已测试

## 详细文档

- [Electron 打包完整指南](docs/windows-electron-build-complete-guide.md) - 从零到一的完整构建指南
  - 问题背景和解决方案
  - 关键配置详解
  - 构建脚本说明
  - 常见问题及解决
  - 验证清单
  - 性能优化
  - 版本发布流程

- [构建问题排查手册](docs/build-troubleshooting.md) - 快速诊断和解决构建问题
  - 快速诊断流程
  - 问题速查表
  - 详细排查步骤
  - 日志分析
  - 预防措施

- [Electron 打包指南](docs/electron-build-guide.md) - 基础打包指南

## 环境要求

### 通用要求
- Node.js v16+
- npm 或 yarn

### Android 打包
- JDK 17
- Android SDK
- Gradle

### Windows 打包
- Windows 10/11
- Git Bash（可选）

## 常见问题

### Electron 白屏
**原因**：Vite 路径配置错误  
**解决**：确保 `vite.config.js` 中配置了 `base: './'`

### Android 构建失败
**原因**：JDK 版本不匹配  
**解决**：检查 JDK 版本是否为 17

### 代码签名错误
**原因**：Windows 权限不足  
**解决**：在 `package.json` 中设置 `"signAndEditExecutable": false`

### 命令找不到
**原因**：本地命令未在 PATH 中  
**解决**：使用 `npx electron-builder` 而不是 `electron-builder`

更多问题请查看 [构建问题排查手册](docs/build-troubleshooting.md)

## 关键配置文件

### Vite 配置（必须）
```javascript
// vite.config.js
export default defineConfig({
  base: './', // Electron 必需
})
```

### Package.json 配置
```json
{
  "main": "electron/main.js",
  "build": {
    "win": {
      "signAndEditExecutable": false
    }
  }
}
```

## 版本管理

修改 `package.json` 中的 `version` 字段来更新版本号：
```json
{
  "version": "1.5.7"
}
```

## 构建流程

### 完整构建流程
```bash
# 1. 清理旧文件
rm -rf dist release

# 2. 构建前端
npm run build

# 3. 打包应用
npx electron-builder --win

# 4. 验证输出
ls release/
```

### 使用脚本（推荐）
```bash
# Windows
build-electron-win.bat

# Git Bash / Linux / macOS
./build-electron-win.sh
```

## 技术栈

- Vue 3 + Vite - 前端框架
- Capacitor - 跨平台移动应用
- Electron - 桌面应用
- electron-builder - Electron 打包工具

## 支持平台

- ✅ Android (APK)
- ✅ Windows (Electron) - 已完整测试
- 🚧 iOS (需要 macOS + Xcode)
- 🚧 macOS (需要 macOS 系统)
- 🚧 Linux (理论支持)

## 故障排查

遇到问题时的排查顺序：
1. 查看 [构建问题排查手册](docs/build-troubleshooting.md)
2. 检查 [完整指南](docs/windows-electron-build-complete-guide.md) 中的常见问题
3. 清理缓存重新构建
4. 查看详细日志：`DEBUG=electron-builder npm run electron:build-win`

## 贡献

欢迎提交 Issue 和 Pull Request！

---

**文档更新日期**：2025-02-21  
**构建脚本版本**：1.0（已验证可用）
