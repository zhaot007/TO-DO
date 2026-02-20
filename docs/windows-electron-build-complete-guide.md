# Windows Electron 构建完整指南

## 目录
- [问题背景](#问题背景)
- [解决方案](#解决方案)
- [关键配置](#关键配置)
- [构建脚本](#构建脚本)
- [常见问题及解决](#常见问题及解决)
- [验证清单](#验证清单)

---

## 问题背景

### 遇到的问题
1. **白屏问题**：Electron 应用打包后启动显示白屏
2. **代码签名错误**：winCodeSign 工具解压失败，提示权限不足
3. **文件占用**：构建时 exe 文件被占用
4. **脚本兼容性**：bat 脚本找不到 electron-builder 命令

### 根本原因
- Vite 默认使用绝对路径 `/`，Electron 需要相对路径 `./`
- electron-builder 需要管理员权限创建符号链接
- 未清理旧的构建文件导致冲突
- 本地 node_modules 的命令需要通过 npx 调用

---

## 解决方案

### 1. 修复 Vite 配置（关键！）

**文件：`vite.config.js`**

```javascript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  base: './', // 必须设置为相对路径，否则 Electron 会白屏
})
```

**为什么必须这样做？**
- Vite 默认 `base: '/'` 生成的是绝对路径：`/assets/index.js`
- Electron 使用 `file://` 协议加载本地文件
- 绝对路径会变成 `file:///assets/index.js`（错误）
- 相对路径会变成 `file:///.../dist/assets/index.js`（正确）

### 2. 配置 Electron 主进程

**文件：`electron/main.js`**

```javascript
const { app, BrowserWindow } = require('electron');
const path = require('path');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    icon: path.join(__dirname, '../public/icon.png')
  });

  // 加载应用
  if (process.env.NODE_ENV === 'development') {
    mainWindow.loadURL('http://localhost:5173');
    mainWindow.webContents.openDevTools();
  } else {
    // 打包后的路径：electron 文件夹和 dist 文件夹是平级的
    const indexPath = path.join(__dirname, '../dist/index.html');
    mainWindow.loadFile(indexPath);
    
    // 调试时可以临时开启开发者工具
    // mainWindow.webContents.openDevTools();
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});
```

**路径说明：**
```
打包后的目录结构：
app.asar/
├── dist/
│   ├── index.html
│   └── assets/
└── electron/
    └── main.js  (当前位置)

所以需要 ../dist/index.html
```

### 3. 配置 package.json

**文件：`package.json`**

```json
{
  "name": "todo-app",
  "version": "1.5.7",
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
  },
  "dependencies": {
    "@capacitor/android": "^8.1.0",
    "@capacitor/cli": "^8.1.0",
    "@capacitor/core": "^8.1.0",
    "pinia": "^3.0.4",
    "vue": "^3.5.13",
    "vue-router": "^4.4.5"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.2.1",
    "electron": "^40.5.0",
    "electron-builder": "^26.8.1",
    "vite": "^6.0.3"
  }
}
```

**关键配置说明：**
- `signAndEditExecutable: false` - 跳过代码签名（避免权限问题）
- `files` - 只打包必要的文件
- `nsis.oneClick: false` - 允许用户选择安装路径

---

## 构建脚本

### Windows Batch 脚本

**文件：`build-electron-win.bat`**

```batch
@echo off
chcp 65001 >nul
REM Windows Electron Build Script
REM Purpose: Build Windows Electron installer

echo =========================================
echo Starting Windows Electron Build
echo =========================================

REM Step 1: Clean old build files
echo Step 1/3: Cleaning old build files...
if exist release rmdir /s /q release
if exist dist rmdir /s /q dist

REM Step 2: Build frontend resources
echo Step 2/3: Building frontend resources...
call npm run build
if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)

REM Step 3: Package Electron app
echo Step 3/3: Packaging Electron app...
call npx electron-builder --win
if errorlevel 1 (
    echo Packaging failed!
    pause
    exit /b 1
)

echo =========================================
echo Build completed successfully!
echo Output: release\TODO App Setup 1.5.7.exe
echo =========================================
pause
```

**使用方法：**
```cmd
# 双击运行或命令行执行
build-electron-win.bat
```

### Bash 脚本

**文件：`build-electron-win.sh`**

```bash
#!/bin/bash

# Windows Electron 打包脚本
# 用途：构建 Windows 平台的 Electron 安装包

echo "========================================="
echo "开始构建 Windows Electron 安装包"
echo "========================================="

# 1. 清理旧的构建文件
echo "步骤 1/3: 清理旧的构建文件..."
rm -rf release dist

# 2. 构建前端资源
echo "步骤 2/3: 构建前端资源..."
npm run build
if [ $? -ne 0 ]; then
    echo "构建失败！"
    exit 1
fi

# 3. 打包 Electron 应用
echo "步骤 3/3: 打包 Electron 应用..."
npx electron-builder --win
if [ $? -ne 0 ]; then
    echo "打包失败！"
    exit 1
fi

echo "========================================="
echo "构建完成！"
echo "安装包位置: release/TODO App Setup 1.5.7.exe"
echo "========================================="
```

**使用方法：**
```bash
# Git Bash / Linux / macOS
chmod +x build-electron-win.sh
./build-electron-win.sh
```

---

## 常见问题及解决

### 问题 1：白屏问题

**现象：**
- Electron 应用启动后显示白屏
- 没有任何内容显示

**原因：**
- Vite 使用了绝对路径打包
- 资源文件加载失败

**解决方案：**
```javascript
// vite.config.js
export default defineConfig({
  base: './', // 添加这一行
})
```

**验证方法：**
1. 打开开发者工具（F12）
2. 查看 Console 是否有 404 错误
3. 检查 Network 标签页的资源加载情况

### 问题 2：代码签名错误

**现象：**
```
ERROR: Cannot create symbolic link : 客户端没有所需的特权
```

**原因：**
- winCodeSign 工具需要管理员权限创建符号链接
- 这是 electron-builder 的代码签名工具

**解决方案：**
```json
// package.json
{
  "build": {
    "win": {
      "signAndEditExecutable": false
    }
  }
}
```

**说明：**
- 跳过代码签名（开发阶段可以这样做）
- 正式发布时需要购买代码签名证书

### 问题 3：文件被占用

**现象：**
```
EBUSY: resource busy or locked, open 'release\win-unpacked\TODO App.exe'
```

**原因：**
- 之前构建的应用还在运行
- 杀毒软件占用文件

**解决方案：**
```bash
# 方案 1：关闭正在运行的应用
# 方案 2：删除 release 目录
rm -rf release

# 方案 3：使用脚本自动清理
# 脚本已包含清理步骤
```

### 问题 4：electron-builder 命令找不到

**现象：**
```
'electron-builder' 不是内部或外部命令
```

**原因：**
- electron-builder 安装在本地 node_modules
- 不在系统 PATH 中

**解决方案：**
```batch
REM 错误写法
electron-builder --win

REM 正确写法
npx electron-builder --win

REM 或使用 npm script
npm run electron:build-win
```

### 问题 5：Electron 下载慢

**现象：**
- 构建时卡在下载 Electron

**解决方案：**
```bash
# 使用淘宝镜像
npm config set electron_mirror https://npmmirror.com/mirrors/electron/

# 或设置环境变量
export ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/

# Windows CMD
set ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/

# Windows PowerShell
$env:ELECTRON_MIRROR="https://npmmirror.com/mirrors/electron/"
```

**或者手动下载：**
1. 下载 Electron：https://github.com/electron/electron/releases
2. 放到缓存目录：`%LOCALAPPDATA%\electron\Cache\`

---

## 验证清单

### 构建前检查

- [ ] Node.js 版本 >= 16
- [ ] 已安装依赖：`npm install`
- [ ] `vite.config.js` 中设置了 `base: './'`
- [ ] `package.json` 中 `main` 字段指向 `electron/main.js`
- [ ] `package.json` 中配置了 `signAndEditExecutable: false`

### 构建步骤

```bash
# 1. 清理旧文件
rm -rf release dist

# 2. 构建前端
npm run build

# 3. 检查 dist 目录
ls dist/  # 应该有 index.html 和 assets/

# 4. 打包 Electron
npx electron-builder --win

# 5. 检查输出
ls release/  # 应该有 .exe 安装包
```

### 构建后验证

- [ ] `release` 目录存在
- [ ] `release/TODO App Setup 1.5.7.exe` 存在
- [ ] 安装包大小合理（通常 100-200MB）
- [ ] 双击安装包可以正常安装
- [ ] 安装后应用可以正常启动
- [ ] 应用界面正常显示（无白屏）
- [ ] 应用功能正常工作

### 调试技巧

**开启开发者工具：**
```javascript
// electron/main.js
mainWindow.webContents.openDevTools();
```

**查看构建日志：**
```bash
# 详细日志
DEBUG=electron-builder npx electron-builder --win
```

**测试未打包版本：**
```bash
# 先构建前端
npm run build

# 直接运行 Electron
npm run electron:dev
```

---

## 构建输出说明

### 目录结构

```
release/
├── TODO App Setup 1.5.7.exe          # Windows 安装程序（NSIS）
├── TODO App Setup 1.5.7.exe.blockmap # 增量更新映射文件
├── win-unpacked/                      # 未打包的应用文件
│   ├── TODO App.exe                   # 可执行文件
│   ├── resources/                     # 资源文件
│   │   └── app.asar                   # 打包的应用代码
│   ├── locales/                       # 语言文件
│   └── ...                            # 其他 Electron 文件
└── builder-effective-config.yaml      # 实际使用的构建配置
```

### 文件说明

- **TODO App Setup 1.5.7.exe**：最终的安装程序，分发给用户
- **win-unpacked/**：可以直接运行，用于测试
- **.blockmap**：用于增量更新（如果配置了自动更新）

### 文件大小参考

- 安装包：约 150-200 MB
- 安装后：约 200-250 MB

---

## 性能优化

### 减小包体积

```json
{
  "build": {
    "asar": true,
    "compression": "maximum",
    "files": [
      "dist/**/*",
      "electron/**/*",
      "!node_modules/**/*"
    ]
  }
}
```

### 排除不必要的文件

```json
{
  "build": {
    "files": [
      "dist/**/*",
      "electron/**/*",
      "!**/*.map",
      "!**/*.md",
      "!**/test/**"
    ]
  }
}
```

---

## 版本发布流程

### 1. 更新版本号

```json
// package.json
{
  "version": "1.5.8"
}
```

### 2. 构建应用

```bash
./build-electron-win.bat
```

### 3. 测试安装包

- 在干净的 Windows 系统上测试安装
- 验证所有功能正常工作
- 检查卸载是否干净

### 4. 发布

- 上传到文件服务器
- 或使用 GitHub Releases
- 或使用自动更新服务

---

## 故障排查流程

```
遇到问题
    ↓
1. 查看错误信息
    ↓
2. 检查本文档的"常见问题"部分
    ↓
3. 开启开发者工具查看 Console
    ↓
4. 检查构建日志
    ↓
5. 清理缓存重新构建
    ↓
6. 检查配置文件
```

### 清理缓存命令

```bash
# 清理构建文件
rm -rf release dist

# 清理 node_modules
rm -rf node_modules
npm install

# 清理 electron-builder 缓存
rm -rf ~/AppData/Local/electron-builder/Cache
```

---

## 参考资源

- [Electron 官方文档](https://www.electronjs.org/docs)
- [electron-builder 文档](https://www.electron.build/)
- [Vite 官方文档](https://vitejs.dev/)
- [NSIS 文档](https://nsis.sourceforge.io/Docs/)

---

## 总结

### 关键要点

1. **Vite 配置**：必须设置 `base: './'`
2. **路径处理**：使用相对路径加载资源
3. **代码签名**：开发阶段可以跳过
4. **清理文件**：每次构建前清理旧文件
5. **使用 npx**：调用本地安装的命令

### 成功标志

- ✅ 构建无错误
- ✅ 安装包生成
- ✅ 应用正常启动
- ✅ 界面正常显示
- ✅ 功能正常工作

### 下一步

- 配置应用图标
- 添加自动更新功能
- 配置代码签名证书
- 优化包体积
- 添加崩溃报告

---

**文档版本**：1.0  
**最后更新**：2025-02-21  
**适用版本**：Electron 40.5.0, electron-builder 26.8.1, Vite 6.0.3
