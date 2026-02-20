# Electron 打包指南

## 概述

本文档介绍如何将 Vue 3 + Vite 应用打包为 Windows Electron 桌面应用。

## 前置要求

### 必需软件
- Node.js (推荐 v16+)
- npm 或 yarn
- Git Bash (Windows 用户)

### 项目依赖
```json
{
  "devDependencies": {
    "electron": "^40.5.0",
    "electron-builder": "^26.8.1",
    "vite": "^6.0.3"
  }
}
```

## 关键配置

### 1. Vite 配置 (vite.config.js)

```javascript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  base: './', // 关键：Electron 需要相对路径
})
```

**重要说明**：`base: './'` 是必需的，否则打包后会出现白屏问题。

### 2. Electron 主进程 (electron/main.js)

```javascript
const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow() {
  const mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    }
  });

  if (process.env.NODE_ENV === 'development') {
    mainWindow.loadURL('http://localhost:5173');
  } else {
    // 打包后使用相对路径加载
    mainWindow.loadFile(path.join(__dirname, '../dist/index.html'));
  }
}

app.whenReady().then(createWindow);
```

### 3. package.json 配置

```json
{
  "main": "electron/main.js",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "electron:dev": "electron .",
    "electron:build-win": "npm run build && electron-builder --win"
  },
  "build": {
    "appId": "com.todo.app",
    "productName": "TODO App",
    "directories": {
      "output": "release"
    },
    "files": [
      "dist/**/*",
      "electron/**/*"
    ],
    "win": {
      "target": [
        {
          "target": "nsis",
          "arch": ["x64"]
        }
      ],
      "icon": "public/icon.png",
      "signAndEditExecutable": false
    },
    "nsis": {
      "oneClick": false,
      "allowToChangeInstallationDirectory": true,
      "createDesktopShortcut": true,
      "createStartMenuShortcut": true
    }
  }
}
```

**配置说明**：
- `signAndEditExecutable: false` - 跳过代码签名（需要证书）
- `files` - 指定打包时包含的文件
- `nsis` - Windows 安装程序配置

## 打包流程

### 方法一：使用脚本（推荐）

#### Windows 用户
```bash
# Git Bash
./build-electron-win.sh

# 或 CMD/PowerShell
build-electron-win.bat
```

#### 脚本执行步骤
1. 清理旧的构建文件 (release, dist)
2. 使用 Vite 构建前端资源
3. 使用 electron-builder 打包应用

### 方法二：手动执行

```bash
# 1. 清理旧文件
rm -rf release dist

# 2. 构建前端
npm run build

# 3. 打包 Electron
electron-builder --win
```

### 方法三：使用 npm 脚本

```bash
npm run electron:build-win
```

## 常见问题

### 1. 白屏问题

**原因**：资源路径不正确

**解决方案**：
- 确保 `vite.config.js` 中设置了 `base: './'`
- 检查 `electron/main.js` 中的路径是否正确

### 2. 代码签名错误

**错误信息**：
```
ERROR: Cannot create symbolic link : 客户端没有所需的特权
```

**解决方案**：
- 在 `package.json` 的 `win` 配置中添加 `"signAndEditExecutable": false`
- 或使用管理员权限运行

### 3. 文件被占用

**错误信息**：
```
EBUSY: resource busy or locked
```

**解决方案**：
- 关闭正在运行的应用
- 删除 `release` 目录后重新构建

### 4. Electron 下载慢

**解决方案**：
```bash
# 使用淘宝镜像
npm config set electron_mirror https://npmmirror.com/mirrors/electron/

# 或使用环境变量
export ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/
```

## 输出文件

构建成功后，在 `release` 目录下会生成：

```
release/
├── TODO App Setup 1.5.7.exe          # Windows 安装程序
├── TODO App Setup 1.5.7.exe.blockmap # 增量更新文件
├── win-unpacked/                      # 未打包的应用文件
│   └── TODO App.exe                   # 可执行文件
└── builder-effective-config.yaml      # 构建配置
```

## 测试应用

### 测试未打包版本
```bash
cd release/win-unpacked
"TODO App.exe"
```

### 测试安装程序
双击运行 `TODO App Setup 1.5.7.exe`

## 调试技巧

### 开启开发者工具

在 `electron/main.js` 中添加：
```javascript
mainWindow.webContents.openDevTools();
```

### 查看日志

Electron 应用的日志位置：
- Windows: `%APPDATA%\TODO App\logs`

## 版本更新

修改 `package.json` 中的 `version` 字段：
```json
{
  "version": "1.5.8"
}
```

重新构建后，安装包名称会自动更新。

## 进阶配置

### 自动更新

使用 `electron-updater` 实现自动更新功能：

```bash
npm install electron-updater
```

### 多平台打包

```bash
# macOS
electron-builder --mac

# Linux
electron-builder --linux

# 全平台
electron-builder -mwl
```

### 自定义图标

1. 准备图标文件：
   - Windows: `.ico` 格式 (256x256)
   - macOS: `.icns` 格式
   - Linux: `.png` 格式

2. 在 `package.json` 中配置：
```json
{
  "build": {
    "win": {
      "icon": "build/icon.ico"
    }
  }
}
```

## 参考资源

- [Electron 官方文档](https://www.electronjs.org/docs)
- [electron-builder 文档](https://www.electron.build/)
- [Vite 官方文档](https://vitejs.dev/)

## 故障排查清单

- [ ] 检查 Node.js 版本
- [ ] 检查 `vite.config.js` 中的 `base` 配置
- [ ] 检查 `package.json` 中的 `main` 字段
- [ ] 检查 `electron/main.js` 中的路径
- [ ] 清理 `node_modules` 并重新安装
- [ ] 清理构建缓存 (`release`, `dist`)
- [ ] 检查防火墙和杀毒软件设置

## 性能优化

### 减小包体积

1. 排除不必要的依赖：
```json
{
  "build": {
    "files": [
      "dist/**/*",
      "electron/**/*",
      "!node_modules/**/*"
    ]
  }
}
```

2. 使用 asar 打包：
```json
{
  "build": {
    "asar": true
  }
}
```

### 加快构建速度

1. 使用本地缓存
2. 配置 electron-builder 缓存目录
3. 使用增量构建

## 总结

本指南涵盖了从配置到打包的完整流程。关键点：
1. Vite 必须配置 `base: './'`
2. 使用相对路径加载资源
3. 跳过代码签名或使用证书
4. 使用脚本自动化构建流程
