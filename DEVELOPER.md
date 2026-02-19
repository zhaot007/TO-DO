# 开发者文档 | Developer Documentation

## 🏗️ 架构概览

### 技术栈 (v1.4.0)
- **前端框架**: Vue 3.5.13 (Composition API)
- **状态管理**: Pinia 3.0.4
- **路由**: Vue Router 4.4.5 (Hash模式)
- **移动框架**: Capacitor 8.1.0
- **桌面框架**: Electron 40.5.0
- **构建工具**: Vite 6.0.3
- **存储方案**: Capacitor Preferences (移动端/桌面端统一)

### 架构模式
- **全离线化 (Pure Offline)**: 从 CS 架构完全迁移至本地优先。
- **用户数据隔离**: 使用 `tasks_{username}` 键名实现多账号本地隔离。
- **跨平台适配**: 统一逻辑代码，通过 Capacitor 和 Electron 分别打包 Android 和 Windows 端。

---

## 📁 项目结构详解

```
TO-DO/
├── electron/                         # Electron 桌面端配置
├── src/                              # 前端源码
│   ├── views/                        # 页面组件
│   │   ├── LoginView.vue            # 登录/注册（含密保/手机绑定逻辑）
│   │   └── TodoView.vue             # 核心业务（含番茄钟统计/Excel导入导出）
│   ├── stores/                       # Pinia Store
│   │   ├── offlineTaskStore.js      # 任务核心逻辑（按用户隔离存储）
│   │   └── offlineUserStore.js      # 用户状态管理
│   ├── assets/                       # 静态资源（含 icons/images）
│   └── main.js                       # 入口文件
├── android/                          # Capacitor Android 原生工程
├── scripts/                          # 数据清理与统计实用脚本
├── TODO导入模板示例.xlsx             # 官方导入模板
├── capacitor.config.json            # Capacitor 配置
└── package.json                      # 项目元数据与依赖
```

---

## 🔧 开发环境配置

### 系统要求
- **Node.js**: >= 22.0.0 (推荐)
- **Java**: JDK 17 (Android 构建必需)
- **平台**: macOS (推荐) / Windows

### 常用开发命令
```bash
# 1. 启动 Web 开发预览
npm run dev

# 2. 启动 Electron 桌面开发模式
npm run electron:dev

# 3. Android 同步与打包
npm run build && npx cap sync android
./build-apk.sh
```

---

## 💾 数据存储结构 (Capacitor Preferences)

### 1. 核心键值 (Storage Keys)
- `users`: `{ "zhaosj": "pass123" }`
- `currentUser`: `"zhaosj"`
- `tasks_{username}`: 任务数组。
- `deletedTasks_{username}`: 回收站数组。
- `userInfo`: 存储详细资料（注册时间、手机号、用户名修改记录）。
- `phoneMapping`: `{ "17858441076": "zhaosj" }`（用于手机号登录检索）。

### 2. 任务对象模型 (Task Object)
```javascript
{
  id: Number,              // 时间戳
  text: String,            // 任务标题
  description: String,     // 详细描述
  type: String,            // 'today'|'tomorrow'|'this_week'|'custom_date'|'daily'|'weekday'|'weekly'
  category: String,        // 'work'|'study'|'life'
  priority: String,        // 'high'|'medium'|'low'
  status: String,          // 'pending'|'completed'|'overdue'
  created_at: String,      // ISO 格式创建时间
  customDate: String,      // 仅用于 custom_date 类型
  customTime: String,      // 仅用于 custom_date 类型
  weekdays: Array          // 仅用于 weekly 类型 [0, 1, 2...]
}
```

---

## 🍅 番茄钟激励系统逻辑

### 计算规则
- **高优先级**: 4 🍅 | **中优先级**: 2 🍅 | **低优先级**: 1 🍅
- **奖励**: 任务状态转为 `completed` 时获得。
- **惩罚**: 任务状态转为 `overdue` 时扣除相应分值。
- **等级公式**: 
  - `totalPomodoros = earned - lost`
  - 根据 `total` 映射至 5 个勋章等级。

---

## 🛠️ 打包指南

### Android 打包
请参考 `APK_BUILD_GUIDE.md`。必须确保 `JAVA_HOME` 指向 JDK 17。

### Windows 打包 (Electron)
```bash
# 构建 Windows 安装程序 (.exe)
npm run electron:build-win
```
输出文件位于 `release/` 目录。

---

**版本**: v1.4.0  
**更新日期**: 2026-02-19  
**维护者**: zhaosj 的助手
