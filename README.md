# TO-DO App (Full-Stack) | 全栈待办事项管理系统

[English](#english) | [中文](#中文)

---

<a name="english"></a>
## English Description

This is a full-stack To-Do management system built with **Vue 3** and **Node.js (Express)**. It features persistent storage using **SQLite** and a logical delete (Recycle Bin) mechanism.

### 🌟 Key Features
- **User Management**: Simple username-based login/registration with user-isolated tasks.
- **Task Management**:
  - Category support (Work, Study, Life).
  - Priority levels (High, Medium, Low).
  - Recurrence types: Today, Daily, and custom Weekly cycles.
- **Persistent Storage**: Use SQLite local database, no need to install any database software.
- **Soft Delete (Recycle Bin)**: 
  - Deleted tasks are moved to the trash first.
  - Supports restoring or permanent deletion from the trash.
- **Dynamic UI**: Real-time countdown for today's tasks and a beautiful gradient interface.

### 🛠️ Tech Stack
- **Frontend**: Vue 3 (Composition API), Pinia, Vue Router, Element Plus, Axios.
- **Backend**: Node.js, Express, SQLite.

### 🚀 Quick Start
1. **Database**: No setup required! SQLite will automatically create `database.sqlite` in the server folder.
2. **Backend**: `cd server && npm install && npm start`
3. **Frontend**: `npm install && npm run dev`

---

<a name="中文"></a>
## 中文说明

这是一个基于 **Vue 3** 和 **Node.js (Express)** 构建的全栈待办事项管理系统。项目实现了数据持久化存储至 **SQLite** 数据库，并具备逻辑删除（回收站）功能。

### 🌟 核心功能
- **用户管理**: 简单的用户名登录/注册，任务按用户隔离。
- **任务管理**:
  - 支持任务分类（工作、学习、生活）。
  - 支持优先级设置（高、中、低）。
  - 支持周期类型：仅今天、每天、自定义每周周期。
- **持久化存储**: 使用 SQLite 本地数据库，无需安装任何数据库软件，零配置开箱即用。
- **逻辑删除 (回收站)**: 
  - 删除的任务会先移入回收站。
  - 支持从回收站中一键恢复或彻底删除任务。
- **动态 UI**: 实时倒计时显示（针对今日任务），美观的渐变色交互界面。

### 🛠️ 技术栈
- **前端**: Vue 3 (Composition API), Pinia, Vue Router, Element Plus, Axios.
- **后端**: Node.js, Express, SQLite.

### 🚀 快速启动
1. **数据库准备**: 无需任何配置！后端启动时会自动在 `server` 目录下生成 `database.sqlite` 文件。
2. **后端启动**: `cd server && npm install && npm start`
3. **前端启动**: `npm install && npm run dev`

## 📂 Project Structure | 项目结构
- `/src`: Frontend source code | 前端源码
- `/server`: Backend source code & SQLite DB | 后端源码与 SQLite 数据库
- `/dist`: Compiled static assets | 编译产物

## 📄 License | 授权协议
MIT License
