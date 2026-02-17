# 开发者文档 | Developer Documentation

## 🏗️ 架构概览

### 技术栈
- **前端框架**: Vue 3.5.13 (Composition API)
- **状态管理**: Pinia 3.0.4
- **路由**: Vue Router 4.4.5 (Hash模式)
- **移动框架**: Capacitor 8.1.0
- **构建工具**: Vite 6.0.3
- **目标平台**: Android

### 架构模式
- **MVVM模式**: Vue组件作为View，Pinia Store作为ViewModel
- **单页应用 (SPA)**: 使用Vue Router管理路由
- **离线优先**: 所有数据存储在本地，无需网络连接

---

## 📁 项目结构详解

```
TO-DO/
├── src/                              # 源代码目录
│   ├── views/                        # 页面组件
│   │   ├── LoginView.vue            # 登录/注册页面
│   │   └── TodoView.vue             # 任务管理主页面
│   ├── stores/                       # Pinia状态管理
│   │   ├── offlineTaskStore.js      # 任务数据管理
│   │   ├── offlineUserStore.js      # 用户数据管理
│   │   ├── taskStore.js             # (废弃) 原在线版Store
│   │   └── userStore.js             # (废弃) 原在线版Store
│   ├── router/                       # 路由配置
│   │   └── index.js                 # 路由定义
│   ├── assets/                       # 静态资源
│   │   └── main.css                 # 全局样式
│   ├── App.vue                       # 根组件
│   └── main.js                       # 应用入口
├── android/                          # Android项目 (Capacitor生成)
│   ├── app/                          # Android应用模块
│   │   ├── src/main/                # Android源码
│   │   └── build.gradle             # 应用构建配置
│   ├── gradle/                       # Gradle配置
│   ├── build.gradle                 # 项目构建配置
│   └── settings.gradle              # 项目设置
├── server/                           # (废弃) 原后端代码
├── dist/                             # 构建输出目录
├── node_modules/                     # 依赖包
├── capacitor.config.json            # Capacitor配置
├── package.json                      # 项目配置
├── vite.config.js                   # Vite配置
├── index.html                        # HTML入口
├── README.md                         # 项目说明
├── CHANGELOG.md                      # 版本记录
├── USER_MANUAL.md                    # 用户手册
└── DEVELOPER.md                      # 本文档
```

---

## 🔧 开发环境配置

### 系统要求
- **Node.js**: >= 16.0.0
- **npm**: >= 8.0.0
- **Java**: JDK 17 (用于Android构建)
- **Android Studio**: 可选，用于调试

### 安装依赖
```bash
# 安装前端依赖
npm install

# 如需构建Android，确保已安装Java 17
java -version
```

### 开发服务器
```bash
# 启动开发服务器 (浏览器预览)
npm run dev

# 访问 http://localhost:5173
```

### 构建生产版本
```bash
# 构建Web版本
npm run build

# 同步到Android项目
npx cap sync android

# 构建Android APK
cd android
./gradlew assembleDebug

# APK位置: android/app/build/outputs/apk/debug/app-debug.apk
```

---

## 📦 核心模块说明

### 1. 路由模块 (`src/router/index.js`)

```javascript
// 使用Hash模式以适配Capacitor
import { createRouter, createWebHashHistory } from 'vue-router'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', name: 'login', component: LoginView },
    { path: '/todo', name: 'todo', component: TodoView }
  ]
})
```

**关键点**：
- 使用 `createWebHashHistory` 而非 `createWebHistory`
- Capacitor环境下必须使用Hash模式
- 无路由守卫，登录状态由组件自行管理

---

### 2. 用户Store (`src/stores/offlineUserStore.js`)

```javascript
import { defineStore } from 'pinia'
import { Preferences } from '@capacitor/preferences'

export const useOfflineUserStore = defineStore('offlineUser', {
  state: () => ({
    currentUser: null,
    isLoggedIn: false
  }),
  
  actions: {
    async login(username) { /* ... */ },
    async logout() { /* ... */ },
    async checkLogin() { /* ... */ }
  }
})
```

**数据存储**：
- `users`: `{ "username1": "password1", "username2": "password2" }`
- `currentUser`: `"username"`

**API说明**：
- `login(username)`: 登录用户，设置currentUser
- `logout()`: 退出登录，清除currentUser
- `checkLogin()`: 检查是否已登录

---

### 3. 任务Store (`src/stores/offlineTaskStore.js`)

```javascript
export const useOfflineTaskStore = defineStore('offlineTask', {
  state: () => ({
    tasks: [],           // 任务列表
    deletedTasks: [],    // 回收站
    currentUser: null
  }),
  
  actions: {
    async loadTasks() { /* 从本地加载 */ },
    async saveTasks() { /* 保存到本地 */ },
    async addTask(taskData) { /* 添加任务 */ },
    async toggleTaskCompletion(taskId) { /* 切换完成状态 */ },
    async updateTask(taskId, updates) { /* 更新任务 */ },
    async deleteTask(taskId) { /* 删除到回收站 */ },
    async restoreTask(taskId) { /* 从回收站恢复 */ },
    async permanentDeleteTask(taskId) { /* 永久删除 */ },
    checkOverdueTasks() { /* 检查逾期任务 */ },
    getFilteredTasks(statusFilter, categoryFilter, dateRange) { /* 筛选任务 */ }
  }
})
```

**任务数据结构**：
```javascript
{
  id: 1708171234567,              // 时间戳作为ID
  text: "完成项目文档",            // 任务标题
  description: "包括README和API文档", // 详细描述
  type: "today",                   // today | daily | weekly
  category: "work",                // work | study | life
  priority: "high",                // high | medium | low
  weekdays: [1, 3, 5],            // 仅weekly类型有效
  status: "pending",               // pending | completed | overdue
  created_at: "2026-02-17T10:30:00.000Z",
  user_id: "username"
}
```

---

### 4. 本地存储 (Capacitor Preferences)

**存储键值对**：
```javascript
// 用户数据
await Preferences.set({ 
  key: 'users', 
  value: JSON.stringify({ "user1": "pass1" }) 
})

// 当前用户
await Preferences.set({ 
  key: 'currentUser', 
  value: 'user1' 
})

// 任务列表
await Preferences.set({ 
  key: 'tasks', 
  value: JSON.stringify([...tasks]) 
})

// 回收站
await Preferences.set({ 
  key: 'deletedTasks', 
  value: JSON.stringify([...deletedTasks]) 
})
```

**读取数据**：
```javascript
const { value } = await Preferences.get({ key: 'tasks' })
const tasks = value ? JSON.parse(value) : []
```

---

## 🎨 UI组件说明

### LoginView.vue

**功能**：
- 用户登录
- 用户注册
- 登录/注册模式切换

**关键代码**：
```vue
<script setup>
const isRegister = ref(false)  // 切换登录/注册模式

const handleRegister = async () => {
  const { value } = await Preferences.get({ key: 'users' })
  const users = value ? JSON.parse(value) : {}
  users[username.value] = password.value
  await Preferences.set({ key: 'users', value: JSON.stringify(users) })
}

const handleLogin = async () => {
  const { value } = await Preferences.get({ key: 'users' })
  const users = value ? JSON.parse(value) : {}
  if (users[username.value] === password.value) {
    window.location.hash = '#/todo'
  }
}
</script>
```

---

### TodoView.vue

**功能**：
- 任务列表展示
- 添加任务
- 编辑任务
- 删除任务
- 筛选任务
- 回收站管理
- 数据统计

**关键组件**：
```vue
<template>
  <!-- 数据统计仪表盘 -->
  <section class="dashboard-area">
    <div class="progress-value">{{ completionPercentage }}%</div>
    <div class="stat-count">{{ pendingCount }}</div>
  </section>
  
  <!-- 筛选工具栏 -->
  <section class="filter-toolbar">
    <select v-model="currentFilter">...</select>
    <select v-model="currentCategoryFilter">...</select>
  </section>
  
  <!-- 任务输入 -->
  <div class="task-input-section">
    <input v-model="newTaskText" />
    <select v-model="newTaskType">...</select>
  </div>
  
  <!-- 任务列表 -->
  <ul>
    <li v-for="task in filteredTasks" :key="task.id">
      <input type="checkbox" @change="toggleTaskCompletion(task.id)" />
      <span @click="openEditModal(task)">{{ task.text }}</span>
      <button @click="deleteTask(task.id)">×</button>
    </li>
  </ul>
</template>
```

---

## 🔌 Capacitor配置

### capacitor.config.json
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

**配置说明**：
- `appId`: Android应用包名
- `appName`: 应用显示名称
- `webDir`: Web资源目录（Vite构建输出）
- `androidScheme`: 使用HTTPS协议
- `cleartext`: 允许HTTP请求（虽然本应用不需要网络）

---

## 🛠️ 构建流程

### 完整构建步骤

```bash
# 1. 安装依赖
npm install

# 2. 构建Web资源
npm run build
# 输出: dist/

# 3. 同步到Android项目
npx cap sync android
# 操作: 复制dist/到android/app/src/main/assets/public/

# 4. 修改Java版本配置 (如需要)
# 编辑以下文件，将VERSION_21改为VERSION_17:
# - android/app/capacitor.build.gradle
# - android/capacitor-cordova-android-plugins/build.gradle
# - node_modules/@capacitor/android/capacitor/build.gradle
# - node_modules/@capacitor/preferences/android/build.gradle

# 5. 构建APK
export JAVA_HOME=/path/to/jdk-17
cd android
./gradlew assembleDebug

# 6. 获取APK
# 位置: android/app/build/outputs/apk/debug/app-debug.apk
```

### 自动化脚本

创建 `build-apk.sh`:
```bash
#!/bin/bash
set -e

echo "🔨 开始构建Android APK..."

# 构建Web
echo "📦 构建Web资源..."
npm run build

# 同步到Android
echo "🔄 同步到Android项目..."
npx cap sync android

# 修复Java版本
echo "🔧 修复Java版本配置..."
sed -i '' 's/VERSION_21/VERSION_17/g' android/app/capacitor.build.gradle
sed -i '' 's/VERSION_21/VERSION_17/g' android/capacitor-cordova-android-plugins/build.gradle
sed -i '' 's/VERSION_21/VERSION_17/g' node_modules/@capacitor/android/capacitor/build.gradle
sed -i '' 's/VERSION_21/VERSION_17/g' node_modules/@capacitor/preferences/android/build.gradle

# 构建APK
echo "🏗️ 构建APK..."
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
cd android
./gradlew assembleDebug

# 复制APK
echo "📱 复制APK到项目根目录..."
cd ..
cp android/app/build/outputs/apk/debug/app-debug.apk ./TODO-App.apk

echo "✅ 构建完成！APK位置: TODO-App.apk"
```

---

## 🧪 调试技巧

### 浏览器调试
```bash
npm run dev
# 访问 http://localhost:5173
# 使用Chrome DevTools调试
```

### Android设备调试
```bash
# 1. 启用USB调试
# 2. 连接设备
adb devices

# 3. 安装APK
adb install TODO-App.apk

# 4. 查看日志
adb logcat | grep "Capacitor"

# 5. Chrome远程调试
# 访问 chrome://inspect
```

### 添加调试日志
```javascript
// 在组件中添加
const addLog = (message) => {
  console.log(`[DEBUG] ${new Date().toLocaleTimeString()} - ${message}`)
}

// 在关键位置调用
addLog('用户点击登录按钮')
addLog(`当前hash: ${window.location.hash}`)
```

---

## 📝 代码规范

### Vue组件规范
```vue
<template>
  <!-- 使用语义化HTML -->
  <!-- 使用kebab-case命名class -->
</template>

<script setup>
// 1. 导入
import { ref, computed, onMounted } from 'vue'

// 2. Props和Emits
const props = defineProps({...})
const emit = defineEmits([...])

// 3. 响应式数据
const data = ref(...)

// 4. 计算属性
const computed = computed(() => ...)

// 5. 方法
const method = () => {...}

// 6. 生命周期
onMounted(() => {...})
</script>

<style scoped>
/* 使用scoped避免样式污染 */
/* 使用CSS变量统一主题 */
</style>
```

### 命名规范
- **组件**: PascalCase (LoginView.vue)
- **文件**: camelCase (offlineTaskStore.js)
- **变量**: camelCase (currentUser)
- **常量**: UPPER_SNAKE_CASE (TASK_STATUS)
- **CSS类**: kebab-case (task-item)

---

## 🚀 性能优化

### 已实现的优化
- ✅ 使用Vite快速构建
- ✅ 使用Composition API减少运行时开销
- ✅ 使用scoped CSS避免全局污染
- ✅ 本地存储避免网络请求

### 可优化项
- 📅 使用虚拟滚动处理大量任务
- 📅 使用Web Worker处理数据计算
- 📅 使用懒加载优化首屏加载
- 📅 使用图片压缩减小APK体积

---

## 🔐 安全考虑

### 当前安全措施
- ✅ 数据仅存储在本地设备
- ✅ 无网络传输，避免中间人攻击
- ✅ 用户数据隔离

### 安全风险
- ⚠️ 密码明文存储
- ⚠️ 无数据加密
- ⚠️ 卸载应用数据丢失

### 改进建议
- 📅 使用加密算法加密密码
- 📅 使用生物识别登录
- 📅 提供数据导出功能

---

## 📚 参考资料

- [Vue 3 官方文档](https://vuejs.org/)
- [Pinia 官方文档](https://pinia.vuejs.org/)
- [Capacitor 官方文档](https://capacitorjs.com/)
- [Vite 官方文档](https://vitejs.dev/)
- [Android Gradle 插件](https://developer.android.com/studio/build)

---

**版本**: v1.0.0  
**更新日期**: 2026-02-17  
**维护者**: 开发团队
