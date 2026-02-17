# TO-DO App (Full-Stack)

这是一个基于 **Vue 3** 和 **Node.js (Express)** 构建的全栈待办事项管理系统。项目实现了数据持久化存储至 **MySQL** 数据库，并具备逻辑删除（回收站）功能。

## 🌟 核心功能

- **用户管理**: 简单的用户名登录/注册，任务按用户隔离。
- **任务管理**:
  - 支持任务分类（工作、学习、生活）。
  - 支持优先级设置（高、中、低）。
  - 支持周期类型：仅今天、每天、自定义每周周期。
- **持久化存储**: 所有任务数据均存储在 MySQL 数据库中。
- **逻辑删除 (回收站)**: 
  - 删除的任务会先移入回收站。
  - 支持从回收站中一键恢复或彻底删除任务。
- **动态 UI**: 实时倒计时显示（针对今日任务），美观的渐变色交互界面。

## 🛠️ 技术栈

### 前端 (Frontend)
- **Vue 3**: 组合式 API (Setup)。
- **Pinia**: 状态管理。
- **Vue Router**: 路由导航控制。
- **Element Plus**: 部分 UI 组件。
- **Axios**: 与后端 API 通信。

### 后端 (Backend)
- **Node.js + Express**: RESTful API 服务。
- **MySQL 8.0**: 数据持久化。
- **dotenv**: 环境参数配置。

## 🚀 快速启动

### 1. 数据库准备
确保您的 MySQL 实例正在运行，并创建了对应的用户：
- 默认数据库: `todo_db`
- 默认用户: `zhaot`
- 默认密码: `zt060816`

### 2. 后端启动
```bash
cd server
npm install
npm start
```
或者在根目录下运行：
```bash
npm run backend
```

### 3. 前端启动
```bash
npm install
npm run dev
```

## 📂 项目结构
- `/src`: 前端 Vue 源码。
- `/server`: 后端 Express 源码及数据库配置。
- `/dist`: 编译后的静态资源。

## 📄 开源协议
MIT License
