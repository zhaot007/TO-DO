# TO-DO App (Android离线版) | Android离线待办事项管理应用

[English](#english) | [中文](#中文)

---

<a name="english"></a>
## English Description

This is an **offline Android To-Do management application** built with **Vue 3** and **Capacitor**. All data is stored locally on the device using Capacitor Preferences API, requiring **no internet connection or backend server**.

### 🌟 Key Features
- **User Registration & Login**: 
  - Dynamic gradient avatar based on username initials
  - Auto-login with session persistence
  - Optional security questions for password recovery
  - **Phone Number Login**: SMS verification code login (simulated via LocalNotifications)
  - **Phone Binding**: Bind phone number during registration or in profile settings
  - **User Data Isolation**: Each user's tasks are completely isolated
- **Offline Operation**: Fully functional without internet connection
- **Smart Refresh**: Top refresh button with rotation animation
- **Smart Reminders**: 
  - Overdue alerts with humorous messages ("Tomatoes are escaping!")
  - 1-hour warning before deadline
  - Anti-spam mechanism (one notification per task per status)
- **Dashboard & Stats**:
  - Grid layout with 5 stat cards (Completion Rate, All, Completed, Pending, Overdue)
  - Search bar with filter and add buttons
  - Interactive filtering by clicking any stat item
  - Advanced filter modal with date range, category, priority, and keyword search
- **Task Management**:
  - **7 Task Types**: Today, Tomorrow, This Week, Custom Date, Daily Repeat, Weekday Repeat, Weekly Repeat
  - **Custom Date & Time**: Specify exact date and time for tasks
  - **Category support**: Work 💼, Study 📚, Life 🏠
  - **Priority levels**: High, Medium, Low
  - **Task descriptions**: Inline display with full editing support
  - **Deadline Display**: Auto-calculated deadline with color-coded urgency
  - **Pomodoro System**: Visual tomato count based on priority (🍅🍅🍅🍅)
- **Advanced Filtering**:
  - Filter by status (All, Pending, Completed, Overdue)
  - Filter by category (Work, Study, Life)
  - Filter by priority (High, Medium, Low)
  - Filter by date range
  - Keyword search (fuzzy match on title and description)
  - All filters can be combined
- **Pomodoro Statistics**:
  - Earned pomodoros from completed tasks
  - Pending pomodoros from active tasks
  - Lost pomodoros from overdue tasks
  - Net pomodoro achievement tracking
- **Local Storage**: All data persists on device using Capacitor Preferences API
- **Data Import/Export**: 
  - Export tasks to Excel for backup
  - Import tasks from Excel in batch
  - Download import template with 100 sample tasks
- **Soft Delete (Recycle Bin)**: 
  - Deleted tasks are moved to the trash first
  - Supports restoring or permanent deletion
- **Mobile Optimized**: Full-width layout optimized for mobile screens

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
- **用户注册与登录**: 
  - 动态首字母渐变头像
  - 自动登录和会话保持
  - 可选的密保问题（用于密码找回）
  - **手机号登录**: 短信验证码登录（通过LocalNotifications模拟）
  - **手机号绑定**: 注册时或个人主页绑定手机号
  - **用户数据隔离**: 每个用户的任务完全隔离
- **完全离线运行**: 无需网络连接即可使用全部功能
- **智能刷新**: 顶部刷新按钮，环形箭头旋转动画
- **智能提醒**: 
  - 逾期提醒（幽默话术："番茄要逃跑啦"）
  - 1小时前预警提醒
  - 防刷屏机制（每个任务每种状态只提醒1次）
- **任务看板**:
  - Grid布局，5列统计卡片（完成占比、全部、已完成、待办、已逾期）
  - 搜索框 + 筛选按钮 + 添加按钮
  - 交互式筛选：点击任何统计项直接筛选列表
  - 高级筛选弹窗：日期范围、分类、优先级、关键字搜索
- **任务管理**:
  - **7种任务类型**: 今天、明天、本周内、指定日期、每天重复、工作日重复、每周重复
  - **自定义日期时间**: 可指定具体日期和时间
  - 支持任务分类（💼工作、📚学习、🏠生活）
  - 支持优先级设置（高、中、低）
  - 任务详细描述，直接在列表中显示
  - **截止时间显示**: 自动计算截止时间，颜色分级提醒
  - **番茄钟系统**: 根据优先级显示番茄数（🍅🍅🍅🍅）
- **高级筛选**:
  - 按状态筛选（全部、待办、已完成、已逾期）
  - 按分类筛选（工作、学习、生活）
  - 按优先级筛选（高、中、低）
  - 按日期范围筛选
  - 关键字搜索（模糊匹配任务名称和描述）
  - 所有筛选条件可组合使用
- **番茄钟统计**:
  - 已获得番茄（完成任务获得）
  - 待获得番茄（待完成任务）
  - 逾期扣除（逾期任务扣除）
  - 净获得番茄（成就追踪）
- **本地存储**: 所有数据持久化存储在设备本地
- **数据导入导出**:
  - 导出任务到Excel文件进行备份
  - 从Excel批量导入任务
  - 下载导入模板（内含100条示例任务）
- **逻辑删除 (回收站)**: 
  - 删除的任务会先移入回收站
  - 支持从回收站中一键恢复或彻底删除任务
- **移动端优化**: 全屏宽度布局，完美适配手机屏幕

### 🛠️ 技术栈
- **前端框架**: Vue 3 (Composition API), Pinia, Vue Router
- **移动端框架**: Capacitor 8.x
- **数据存储**: Capacitor Preferences API（本地存储）
- **构建工具**: Vite
- **目标平台**: Android (APK)

## 📱 安装使用（最终用户）

### Android 版本
1. 下载 `TODO-App.apk` 安装包
2. 在Android设备上开启"允许安装未知来源应用"
3. 安装APK文件
4. 打开应用并注册新账号
5. 开始离线管理您的任务！

### Windows 版本
1. 下载 `TODO App Setup 1.4.0.exe` 安装程序
2. 双击运行安装程序
3. 选择安装目录并完成安装
4. 从桌面快捷方式启动应用
5. 开始管理您的任务！

### 🚀 开发环境搭建
1. **安装依赖**: `npm install`
2. **运行开发服务器**: `npm run dev`
3. **生产环境构建**: `npm run build`
4. **同步到Android**: `npx cap sync android`
5. **一键打包APK**: 
   ```bash
   ./build-apk.sh
   ```
6. **APK位置**: `TODO-App.apk`（项目根目录）

**详细打包流程**: 请查看 [APK打包快速指南](APK_BUILD_QUICK.md) 或 [完整指南](APK_BUILD_GUIDE.md)

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
├── scripts/                      # 实用脚本 | Utility scripts
│   ├── 清理本地数据.js          # 清空任务数据 | Clear local data
│   └── 统计任务数据.js          # 统计任务信息 | Task statistics
├── server/                       # 已废弃的后端代码 | Deprecated backend code
├── capacitor.config.json         # Capacitor配置 | Capacitor config
├── TODO导入模板示例.xlsx        # 官方导入模板 | Official import template
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
- `tasks_{username}`: 按用户隔离的任务数据
- `deletedTasks_{username}`: 按用户隔离的回收站数据
- `userInfo`: 用户详细信息（注册时间、修改时间、绑定手机号等）
- `phoneMapping`: 手机号→用户名映射 `{ phone: username }`
- `security`: 安全问题答案（可选）

### 用户信息结构 | User Info Structure
```javascript
userInfo[username] = {
  username: String,              // 用户名
  registerTime: String,          // 注册时间（ISO格式，不变）
  usernameModifiedTime: String,  // 用户名修改时间（可选）
  lastLoginTime: String,         // 最后登录时间
  boundPhone: String             // 绑定的手机号（可选）
}
```

### 路由模式 | Router Mode
使用 Hash 模式 (`createWebHashHistory`) 以适配 Capacitor 环境。

### 任务数据结构 | Task Data Structure
```javascript
{
  id: Number,              // 任务ID（时间戳）
  text: String,            // 任务标题
  description: String,     // 任务描述
  type: String,            // 类型: 'today' | 'tomorrow' | 'this_week' | 'custom_date' | 'daily' | 'weekday' | 'weekly'
  category: String,        // 分类: 'work' | 'study' | 'life'
  priority: String,        // 优先级: 'high' | 'medium' | 'low'
  weekdays: Array,         // 周期（仅weekly类型）
  customDate: String,      // 指定日期（YYYY-MM-DD格式，仅custom_date类型）
  customTime: String,      // 指定时间（HH:MM格式，仅custom_date类型）
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

### v1.5.7 (2026-02-20)
- ✅ **UI布局全面优化**:
  - 添加/收起按钮简化为箭头图标(▲/▼)，宽度缩小至50px
  - 统计区域改用flex布局，左侧5卡片平分空间，按钮右对齐
  - 统一表单元素高度：搜索框/输入框/属性组36px，统计卡片44px
  - 统一字体大小：所有输入框0.85rem
- ✅ **表单区域紧凑化**:
  - 删除属性配置图标(📅🏷️⚡)，界面更简洁
  - 优化属性选择器宽度：日期110px，分类/优先级42px
  - 缩小内边距至0.5rem，提升空间利用率
- ✅ **日期显示增强**:
  - 指定日期格式改为"年/月/日 时:分"（如：2026/2/20 13:30）
  - 增加选择器宽度以完整显示日期时间
- ✅ **筛选功能精简**:
  - 删除高级筛选中的"全部"选项
  - 分类仅保留：工作/学习/生活
  - 优先级仅保留：高/中/低

### v1.5.6 (2026-02-20)
- ✅ **扁平化设计重构**:
  - 消除统计区、搜索栏、任务创建区的"俄罗斯套娃"效应
  - 去掉所有外层容器，组件直接浮在背景上
  - 空间利用率提升40%
- ✅ **筛选弹窗全面优化**:
  - 按钮强制撑满整行（Grid 3列平分宽度）
  - 弹窗宽度增至560px，边距压减至0.6rem
  - 按钮全宽自适应平铺，消除右侧留白
- ✅ **UI精制化**:
  - KPI指标去冒号，全宽对齐
  - 刷新按钮图标：3rem → 2.5rem
  - 刷新动画：公转 → 自转
  - 添加/收起按钮移至统计栏
- ✅ **交互优化**:
  - 特殊任务类型（指定日期、每周重复）改为弹窗化
  - 修复首页统计区换行问题
  - 移除下拉菜单重复图标

### v1.5.5 (2026-02-20)
- ✅ **右上角按钮组精致化**:
  - 统一视觉风格：所有按钮44x44px圆形，半透明白色背景
  - 回收站优化：只显示🗑️图标，右上角红色数字气泡
  - 刷新动画优化：只自转不放大，图标3rem
  - 交互增强：悬停上浮+阴影，点击缩小反馈

### v1.5.4 (2026-02-20)
- ✅ **两行布局重构**:
  - 第一行：任务输入框（90%宽）+ 绿色提交按钮
  - 第二行：图标引导的属性配置（📅日期 🏷️分类 ⚡优先级）
  - 白色卡片容器，圆角10px
- ✅ **统计区轻量化**:
  - 高度减少30%（48px→42px）
  - 标签和数字颜色加深，字重增强

### v1.5.3 (2026-02-20)
- ✅ **筛选弹窗精致化**:
  - 统一10px圆角
  - 提升对比度（占位符#999，边框#d0d0d0）
  - Grid布局优化（日期4列，按钮自适应）
  - 模块化分区，section间分割线
  - 底部按钮重构：重置+确定并排

### v1.5.2 (2026-02-20)
- ✅ **Grid布局优化**:
  - 第一行：Grid统计卡片（5列均匀分布）
  - 第二行：搜索框 + 筛选按钮 + 添加按钮
- ✅ **对比度增强（符合WCAG）**:
  - 标签文字：白色→#666深灰
  - 数字文字：白色→#333深色
  - 卡片背景：半透明→白色(0.9透明度)
- ✅ **统一按钮颜色**：绿色→紫色系渐变

### v1.5.1 (2026-02-20)
- ✅ **单行布局优化**:
  - 合并为一行：状态统计 + 图标按钮
  - 筛选/添加按钮改为纯图标（🔍/➕/✕）
- ✅ **筛选弹窗美化**:
  - 添加数字统计（分类:数量、优先级:数量）
  - 优化按钮样式：悬停上浮、激活渐变、彩色阴影
- ✅ **刷新按钮点击放大效果**（1.4倍）

### v1.5.0 (2026-02-19)
- ✅ **极简状态栏**:
  - 将三行筛选区域简化为两行
  - 第一行：完成占比 + 核心状态（全部/已完成/待办/已逾期）
  - 第二行：筛选和添加按钮（紧凑布局）
- ✅ **高级筛选弹窗**:
  - 点击"🔍 筛选"后弹出
  - 包含：日期/分类/优先级/搜索
- ✅ **删除下拉刷新**：改为顶部刷新按钮（环形箭头+旋转动画）
- ✅ **移除首页退出登录**：移至个人主页底部
- ✅ **空间优化**：筛选区域高度减少72%，任务列表可见行数增加75%

### v1.4.0 (2026-02-19)
- ✅ **手机号登录系统**:
  - 注册时可选绑定手机号（验证码验证）
  - 个人主页支持绑定/解绑手机号
  - 手机号登录自动识别绑定账号
  - 使用LocalNotifications模拟短信验证码
- ✅ **下拉刷新**: 
  - 支持移动端手势刷新数据
  - 刷新指示器动画（下拉/准备/刷新中）
- ✅ **智能逾期提醒**:
  - 1小时内即将逾期提醒（幽默话术："番茄要逃跑啦"）
  - 已逾期提醒（"番茄已经逃跑了"）
  - 防刷屏机制（每个任务每种状态只提醒1次）
  - 每分钟检查一次
- ✅ **用户数据隔离**: 
  - 任务数据按用户完全隔离（tasks_{username}）
  - 用户名修改时间记录
  - 保留原始注册时间
- ✅ **个人主页优化**:
  - 紧凑化布局（纵向高度缩减30%）
  - 横向布局优化（空间利用率提升25%）
  - 联系与支持改版（入口+弹窗）
  - 字体全面精简
- ✅ **任务类型扩展**: 新增明天、本周内、指定日期、工作日重复类型
- ✅ **日期时间选择**: 指定日期支持同时选择日期和时间（datetime-local）
- ✅ **任务截止时间系统**: 
  - 根据任务类型自动计算截止时间
  - 颜色分级：正常/警告/紧急/已逾期/已完成
  - 显示格式：今天 23:59 / 明天 23:59 / 2/25 14:30
- ✅ **番茄钟激励系统**:
  - 任务卡片显示预估番茄数（🍅🍅🍅🍅）
  - 根据优先级自动建议：高4/中2/低1
  - 个人主页番茄统计：已获得/待获得/逾期扣除/净获得
- ✅ **增强筛选功能**:
  - 新增优先级筛选（全部/高/中/低）
  - 新增关键字搜索（模糊匹配任务名称和描述）
  - 所有筛选条件可组合使用
- ✅ **任务编辑增强**: 支持编辑所有字段（分类、优先级、类型、周期、日期时间）
- ✅ **会话管理**: 自动登录、路由守卫、会话保持
- ✅ **密保问题优化**: 密保问题改为可选项
- ✅ **一键打包**: 新增 build-apk.sh 脚本
- ✅ **UI优化**: 多项布局和样式优化

### v1.3.1 (2026-02-19)
- ✅ **UI 重构与层级调整**: 重新排列统计区域（分类统计上移，状态下移）
- ✅ **全站视觉标准化**: 所有统计项统一为 `图标 + 数字 + 标签` 结构，移除环形进度条
- ✅ **现代感头像**: 动态首字母渐变头像，替代旧版 Emoji
- ✅ **分类专属图标**: 为工作、学习、生活添加专属图标

## v1.3.0 (2026-02-19)
- ✅ 新增任务批量导入功能
- ✅ 支持从Excel导入任务（任务名称、描述、分类、优先级、类型、状态、创建时间）
- ✅ 数据管理区域新增"下载模板"按钮（三按钮布局）
- ✅ 提供官方导入模板（100条示例任务，时间范围2026-01-01至2026-02-25）
- ✅ 智能解析Excel数据格式
- ✅ 导入结果统计（成功/失败数量）
- 🐛 修复addTask方法保留导入数据完整字段
- 🐛 修复待办统计逻辑，避免与已逾期重复计数
- 📄 新增导入模板使用说明文档
- 🛠️ 新增清理数据和统计数据脚本

### v1.2.1 (2026-02-18)
- 🐛 修复小屏手机上统计数字被截断的问题
- 🔄 优化统计区域字体和间距，确保文字完整显示

### v1.2.0 (2026-02-18)
- ✅ 统计数据垂直排列+图标化
- ✅ 任务卡片图标化（⚡ 优先级、🏷️ 分类）
- ✅ 剩余时间颜色分级（蓝/橙/红）
- ✅ 触摸热区优化（44x44px）
- ✅ 统计栏卡片感增强
- ✅ 字体比例优化
- ✅ 安卓体验优化

### v1.1.0 (2026-02-17)
- ✅ 统计数据交互式筛选功能
- ✅ 统计和筛选区域完全融合
- ✅ 点击统计数字直接筛选任务
- ✅ 胶囊按钮样式的分类筛选
- ✅ 添加表单默认展开
- ✅ 内联表单设计（一行输入）
- ✅ 空间优化（节省约130px）

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
