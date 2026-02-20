# 构建问题排查手册

## 快速诊断

### 问题分类

```
构建失败
├── 白屏问题 → 检查 vite.config.js 的 base 配置
├── 命令找不到 → 使用 npx 或 npm run
├── 文件占用 → 关闭应用，清理 release 目录
├── 权限错误 → 跳过代码签名
└── 下载慢 → 配置镜像源
```

---

## 问题速查表

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| 白屏 | Vite 路径配置错误 | `base: './'` |
| Cannot create symbolic link | 权限不足 | `signAndEditExecutable: false` |
| EBUSY: resource busy | 文件被占用 | 关闭应用，删除 release |
| electron-builder 不是命令 | 命令未找到 | 使用 `npx electron-builder` |
| 404 错误 | 资源加载失败 | 检查路径配置 |
| 下载超时 | 网络问题 | 配置镜像源 |

---

## 详细排查步骤

### 1. 白屏问题

#### 症状
- 应用启动后显示空白页面
- 没有任何内容

#### 诊断步骤
```bash
# 1. 打开开发者工具
# 在 electron/main.js 中添加：
mainWindow.webContents.openDevTools();

# 2. 重新构建
npm run electron:build-win

# 3. 安装并运行，查看 Console
```

#### 检查点
- [ ] Console 是否有 404 错误
- [ ] Network 标签页资源是否加载失败
- [ ] 路径是否以 `file:///` 开头

#### 解决方案
```javascript
// vite.config.js
export default defineConfig({
  base: './', // 必须添加
})
```

#### 验证
```bash
# 重新构建
rm -rf dist release
npm run build
npx electron-builder --win

# 检查 dist/index.html
# 资源路径应该是 ./assets/xxx 而不是 /assets/xxx
```

---

### 2. 代码签名错误

#### 症状
```
ERROR: Cannot create symbolic link : 客户端没有所需的特权
winCodeSign 解压失败
```

#### 原因
- electron-builder 尝试创建符号链接
- Windows 需要管理员权限

#### 解决方案 A：跳过签名（推荐开发阶段）
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

#### 解决方案 B：使用管理员权限
```bash
# 以管理员身份运行 PowerShell
# 然后执行构建命令
```

#### 解决方案 C：清理缓存
```bash
# 删除 winCodeSign 缓存
rm -rf ~/AppData/Local/electron-builder/Cache/winCodeSign
```

---

### 3. 文件占用错误

#### 症状
```
EBUSY: resource busy or locked
Cannot open 'release\win-unpacked\TODO App.exe'
```

#### 原因
- 之前构建的应用还在运行
- 杀毒软件扫描文件
- 文件资源管理器打开了目录

#### 解决步骤
```bash
# 1. 关闭所有 TODO App 进程
taskkill /F /IM "TODO App.exe"

# 2. 删除 release 目录
rm -rf release

# 3. 重新构建
npm run electron:build-win
```

#### PowerShell 命令
```powershell
# 查找进程
Get-Process | Where-Object {$_.ProcessName -like "*TODO*"}

# 强制结束
Stop-Process -Name "TODO App" -Force
```

---

### 4. 命令找不到

#### 症状
```
'electron-builder' 不是内部或外部命令
```

#### 原因
- electron-builder 安装在本地 node_modules
- 不在系统 PATH 中

#### 解决方案
```bash
# 方案 1：使用 npx（推荐）
npx electron-builder --win

# 方案 2：使用 npm script
npm run electron:build-win

# 方案 3：全局安装（不推荐）
npm install -g electron-builder
```

#### 检查安装
```bash
# 检查是否安装
npm list electron-builder

# 重新安装
npm install electron-builder --save-dev
```

---

### 5. 资源加载 404

#### 症状
- Console 显示 404 错误
- 图片、CSS、JS 加载失败

#### 检查 dist/index.html
```html
<!-- 错误：绝对路径 -->
<script src="/assets/index.js"></script>

<!-- 正确：相对路径 -->
<script src="./assets/index.js"></script>
```

#### 解决方案
```javascript
// vite.config.js
export default defineConfig({
  base: './',
})
```

#### 验证构建结果
```bash
# 构建后检查
cat dist/index.html | grep "assets"

# 应该看到 ./assets 而不是 /assets
```

---

### 6. Electron 下载慢/超时

#### 症状
```
Downloading electron...
Request timeout
```

#### 解决方案 A：配置镜像
```bash
# npm 配置
npm config set electron_mirror https://npmmirror.com/mirrors/electron/

# 环境变量（临时）
export ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/
```

#### 解决方案 B：手动下载
```bash
# 1. 下载 Electron
# https://github.com/electron/electron/releases/download/v40.5.0/electron-v40.5.0-win32-x64.zip

# 2. 放到缓存目录
# Windows: %LOCALAPPDATA%\electron\Cache\
# 文件名格式: electron-v40.5.0-win32-x64.zip
```

#### 解决方案 C：使用代理
```bash
# 设置代理
npm config set proxy http://proxy.example.com:8080
npm config set https-proxy http://proxy.example.com:8080
```

---

### 7. 构建卡住不动

#### 症状
- 构建过程卡在某个步骤
- 没有错误信息

#### 诊断
```bash
# 开启详细日志
DEBUG=electron-builder npx electron-builder --win
```

#### 常见卡住点
1. **下载 Electron** → 配置镜像
2. **下载 winCodeSign** → 跳过签名
3. **下载 NSIS** → 配置镜像
4. **打包 asar** → 检查文件权限

#### 解决方案
```bash
# 1. 清理缓存
rm -rf ~/AppData/Local/electron-builder/Cache

# 2. 重新构建
npm run electron:build-win
```

---

### 8. 依赖安装失败

#### 症状
```
npm ERR! code ELIFECYCLE
electron-builder 安装失败
```

#### 解决步骤
```bash
# 1. 清理 npm 缓存
npm cache clean --force

# 2. 删除 node_modules
rm -rf node_modules package-lock.json

# 3. 重新安装
npm install

# 4. 如果还失败，尝试使用 yarn
npm install -g yarn
yarn install
```

---

### 9. 版本冲突

#### 症状
```
Peer dependency warning
Version mismatch
```

#### 检查版本
```bash
# 查看已安装版本
npm list electron
npm list electron-builder
npm list vite
```

#### 推荐版本组合
```json
{
  "devDependencies": {
    "electron": "^40.5.0",
    "electron-builder": "^26.8.1",
    "vite": "^6.0.3",
    "@vitejs/plugin-vue": "^5.2.1"
  }
}
```

---

### 10. 打包后应用崩溃

#### 症状
- 安装成功
- 启动后立即崩溃或闪退

#### 诊断步骤
```bash
# 1. 运行未打包版本
cd release/win-unpacked
"TODO App.exe"

# 2. 查看日志
# Windows: %APPDATA%\TODO App\logs
```

#### 常见原因
1. **缺少依赖** → 检查 package.json 的 files 配置
2. **路径错误** → 检查 electron/main.js 的路径
3. **权限问题** → 以管理员身份运行

---

## 完整排查流程

```bash
# 步骤 1：清理环境
rm -rf dist release node_modules package-lock.json
npm cache clean --force

# 步骤 2：重新安装依赖
npm install

# 步骤 3：检查配置
# - vite.config.js: base: './'
# - package.json: main: 'electron/main.js'
# - package.json: signAndEditExecutable: false

# 步骤 4：测试构建前端
npm run build
ls dist/  # 检查是否有 index.html

# 步骤 5：测试 Electron 开发模式
npm run electron:dev

# 步骤 6：打包
npx electron-builder --win

# 步骤 7：测试安装包
cd release
ls  # 检查是否有 .exe 文件
```

---

## 日志分析

### 开启详细日志
```bash
# 方式 1：环境变量
DEBUG=electron-builder npm run electron:build-win

# 方式 2：命令行参数
npx electron-builder --win --verbose
```

### 关键日志信息
```
✓ loaded configuration  # 配置加载成功
✓ packaging            # 打包中
✓ building             # 构建安装包
✓ building block map   # 生成更新映射
```

### 错误日志位置
- 构建日志：终端输出
- 应用日志：`%APPDATA%\TODO App\logs`
- Electron 日志：开发者工具 Console

---

## 预防措施

### 构建前检查清单
- [ ] Node.js 版本正确（v16+）
- [ ] 依赖已安装（npm install）
- [ ] vite.config.js 配置正确
- [ ] package.json 配置正确
- [ ] 没有应用在运行
- [ ] 磁盘空间充足（>2GB）

### 配置验证脚本
```bash
#!/bin/bash
# check-config.sh

echo "检查 Node.js 版本..."
node --version

echo "检查 npm 版本..."
npm --version

echo "检查 Vite 配置..."
grep "base:" vite.config.js

echo "检查 package.json..."
grep "main" package.json
grep "signAndEditExecutable" package.json

echo "检查依赖..."
npm list electron electron-builder vite

echo "检查完成！"
```

---

## 获取帮助

### 收集信息
```bash
# 系统信息
node --version
npm --version
electron --version

# 依赖版本
npm list electron electron-builder vite

# 构建日志
DEBUG=electron-builder npm run electron:build-win > build.log 2>&1
```

### 提问模板
```
**环境信息**
- OS: Windows 10/11
- Node.js: v18.x.x
- npm: v9.x.x
- electron: v40.5.0
- electron-builder: v26.8.1

**问题描述**
[详细描述问题]

**重现步骤**
1. ...
2. ...

**错误信息**
```
[粘贴错误日志]
```

**已尝试的解决方案**
- [ ] 清理缓存
- [ ] 重新安装依赖
- [ ] 检查配置文件
```

---

## 参考资源

- [Electron 官方文档](https://www.electronjs.org/docs)
- [electron-builder 文档](https://www.electron.build/)
- [Vite 文档](https://vitejs.dev/)
- [GitHub Issues](https://github.com/electron-userland/electron-builder/issues)

---

**最后更新**：2025-02-21
