# TO-DO App (Android离线版) | Android离线待办事项管理应用

[English](#english) | [中文](#中文)

---

<a name="english"></a>
## English Description

This is an **offline Android To-Do management application** built with **Vue 3** and **Capacitor**. All data is stored locally on the device using Capacitor Preferences API, requiring **no internet connection or backend server**.

### 🌟 Key Features
- **User Registration & Login**: Free registration with username and password stored locally.
- **Offline Operation**: Fully functional without internet connection.
- **Task Management**:
  - Category support (Work, Study, Life).
  - Priority levels (High, Medium, Low).
  - Recurrence types: Today, Daily, and custom Weekly cycles.
  - Task descriptions with inline display.
- **Local Storage**: All data persists on device using Capacitor Preferences API.
- **Soft Delete (Recycle Bin)**: 
  - Deleted tasks are moved to the trash first.
  - Supports restoring or permanent deletion from the trash.
- **Mobile Optimized**: Full-width layout optimized for mobile screens.
- **Real-time Updates**: Live countdown for today's tasks.

### 🛠️ Tech Stack
- **Frontend**: Vue 3 (Composition API), Pinia, Vue Router
- **Mobile Framework**: Capacitor 8.x
- **Storage**: Capacitor Preferences API (Local Storage)
- **Build Tool**: Vite
- **Platform**: Android (APK)

### 📱 Installation (End Users)
1. Download `TODO-App.apk` from the releases
2. Enable "Install from Unknown Sources" on your Android device
3. Install the APK
4. Open the app and register a new account
5. Start managing your tasks offline!

### 🚀 Development Setup
1. **Install Dependencies**: `npm install`
2. **Run Development Server**: `npm run dev`
3. **Build for Production**: `npm run build`
4. **Sync to Android**: `npx cap sync android`
5. **Build APK**: 
   ```bash
   cd android
   ./gradlew assembleDebug
   ```
6. **APK Location**: `android/app/build/outputs/apk/debug/app-debug.apk`

### ⚙️ Configuration
- **Java Version**: Requires Java 17
- **Capacitor Config**: `capacitor.config.json`
- **App ID**: com.todo.app
- **App Name**: TODO App

---

<a name="中文"></a>
## 中文说明

这是一个基于 **Vue 3** 和 **Capacitor** 构建的 **Android离线待办事项管理应用**。所有数据使用 Capacitor Preferences API 存储在设备本地，**无需网络连接或后端服务器**。

### 🌟 核心功能
- **用户注册与登录**: 自由注册，用户名和密码存储在本地设备。
- **完全离线运行**: 无需网络连接即可使用全部功能。
- **任务管理**:
  - 支持任务分类（工作、学习、生活）。
  - 支持优先级设置（高、中、低）。
  - 支持周期类型：仅今天、每天、自定义每周周期。
  - 任务详细描述，直接在列表中显示。
- **本地存储**: 所有数据持久化存储在设备本地。
- **逻辑删除 (回收站)**: 
  - 删除的任务会先移入回收站。
  - 支持从回收站中一键恢复或彻底删除任务。
- **移动端优化**: 全屏宽度布局，完美适配手机屏幕。
- **实时更新**: 今日任务实时倒计时显示。

### 🛠️ 技术栈
- **前端框架**: Vue 3 (Composition API), Pinia, Vue Router
- **移动端框架**: Capacitor 8.x
- **数据存储**: Capacitor Preferences API（本地存储）
- **构建工具**: Vite
- **目标平台**: Android (APK)

### 📱 安装使用（最终用户）
1. 下载 `TODO-App.apk` 安装包
2. 在Android设备上开启"允许安装未知来源应用"
3. 安装APK文件
4. 打开应用并注册新账号
5. 开始离线管理您的任务！

### 🚀 开发环境搭建
1. **安装依赖**: `npm install`
2. **运行开发服务器**: `npm run dev`
3. **生产环境构建**: `npm run build`
4. **同步到Android**: `npx cap sync android`
5. **构建APK**: 
   ```bash
   # 使用自动化脚本（推荐）
   ./build-apk.sh
   
   # 或手动构建
   cd android
   ./gradlew assembleDebug
   ```
6. **APK位置**: `android/app/build/outputs/apk/debug/app-debug.apk`

**详细打包流程**: 请查看 [APK打包指南](APK_BUILD_GUIDE.md) 或 [快速参考](APK_BUILD_QUICK.md)

### ⚙️ 配置要求
- **Java版本**: 需要 Java 17
- **Capacitor配置**: `capacitor.config.json`
- **应用ID**: com.todo.app
- **应用名称**: TODO App

## 📂 项目结构 | Project Structure
```
TO-DO/
├── src/                          # 前端源码 | Frontend source code
│   ├── views/                    # 页面组件 | Page components
│   │   ├── LoginView.vue        # 登录/注册页面 | Login/Register page
│   │   └── TodoView.vue         # 任务管理页面 | Task management page
│   ├── stores/                   # Pinia状态管理 | Pinia stores
│   │   ├── offlineTaskStore.js  # 离线任务Store | Offline task store
│   │   └── offlineUserStore.js  # 离线用户Store | Offline user store
│   ├── router/                   # 路由配置 | Router config
│   ├── assets/                   # 静态资源 | Static assets
│   ├── App.vue                   # 根组件 | Root component
│   └── main.js                   # 入口文件 | Entry file
├── android/                      # Android项目目录 | Android project
├── server/                       # 已废弃的后端代码 | Deprecated backend code
├── capacitor.config.json         # Capacitor配置 | Capacitor config
├── TODO-App.apk                  # Android安装包 | Android APK
├── package.json                  # 项目依赖 | Project dependencies
├── vite.config.js               # Vite配置 | Vite config
└── README.md                     # 项目说明 | Project documentation
```

## 🔧 技术细节 | Technical Details

### 数据存储结构 | Data Storage Structure
使用 Capacitor Preferences API 存储以下数据：
- `users`: 用户账号密码映射 `{ username: password }`
- `currentUser`: 当前登录用户
- `tasks`: 任务列表数组
- `deletedTasks`: 回收站任务数组

### 路由模式 | Router Mode
使用 Hash 模式 (`createWebHashHistory`) 以适配 Capacitor 环境。

### 任务数据结构 | Task Data Structure
```javascript
{
  id: Number,              // 任务ID（时间戳）
  text: String,            // 任务标题
  description: String,     // 任务描述
  type: String,            // 类型: 'today' | 'daily' | 'weekly'
  category: String,        // 分类: 'work' | 'study' | 'life'
  priority: String,        // 优先级: 'high' | 'medium' | 'low'
  weekdays: Array,         // 周期（仅weekly类型）
  status: String,          // 状态: 'pending' | 'completed' | 'overdue'
  created_at: String,      // 创建时间（ISO格式）
  user_id: String          // 所属用户
}
```

## 🎯 功能特性详解 | Feature Details

### 用户系统
- ✅ 本地注册（无限制）
- ✅ 本地登录验证
- ✅ 用户数据隔离
- ❌ 无密码加密（本地存储）
- ❌ 无云端同步

### 任务管理
- ✅ 添加任务（标题、描述、分类、优先级、周期）
- ✅ 编辑任务（点击任务标题）
- ✅ 完成/取消完成
- ✅ 删除到回收站
- ✅ 从回收站恢复
- ✅ 永久删除
- ✅ 筛选（状态、分类、时间范围）
- ✅ 自动排序（完成状态、优先级、创建时间）
- ✅ 逾期检测（仅今天类型任务）

### 界面特性
- ✅ 全屏宽度布局（移动端优化）
- ✅ 渐变色背景
- ✅ 毛玻璃效果卡片
- ✅ 实时倒计时
- ✅ 任务进度统计
- ✅ 通知提示

## 📝 版本历史 | Version History

### v1.0.0 (2026-02-17)
- ✅ 实现Android离线版APP
- ✅ 用户注册与登录功能
- ✅ 完整的任务管理功能
- ✅ 本地数据持久化
- ✅ 回收站功能
- ✅ 移动端UI优化
- ✅ 完全离线运行

## ⚠️ 注意事项 | Important Notes

1. **数据安全**: 所有数据存储在本地设备，卸载应用会丢失数据。
2. **无云同步**: 数据不会在多设备间同步。
3. **密码安全**: 密码以明文存储在本地，请勿使用重要密码。
4. **Java版本**: 构建APK需要Java 17环境。
5. **已废弃**: `/server` 目录中的后端代码已不再使用。

## 🤝 贡献指南 | Contributing

欢迎提交Issue和Pull Request！

## 📄 开源协议 | License

MIT License

---

**注意**: 本项目已从全栈架构迁移至纯前端离线Android应用。`/server` 目录中的代码仅作历史参考，不再维护。
