# v1.5.9 代码修改对比

## 📁 修改文件清单

1. `package.json` - 版本号更新
2. `src/stores/offlineTaskStore.js` - Bug修复
3. `src/views/TodoView.vue` - UI/UX优化

---

## 1️⃣ package.json

```diff
- "version": "1.5.7",
+ "version": "1.5.9",
```

---

## 2️⃣ src/stores/offlineTaskStore.js

### Bug修复：待办筛选逻辑

```diff
  if (statusFilter === 'pending') {
-   filtered = filtered.filter(t => t.status !== 'completed')
+   filtered = filtered.filter(t => t.status === 'pending')
  }
```

**说明**: 
- 修复前：`!== 'completed'` 会包含 `pending` 和 `overdue` 两种状态
- 修复后：`=== 'pending'` 只显示真正的待办任务

---

## 3️⃣ src/views/TodoView.vue

### A. 新建任务输入框 (HTML)

```diff
  <input 
    type="text" 
    v-model="newTaskText" 
    class="task-input-main"
-   placeholder="输入任务名称..."
+   placeholder="➕ 新建任务：输入任务名称..."
    @keyup.enter="addTask"
  >
```

### B. 全局弹窗样式 (CSS)

```diff
  .modal-content {
-   padding: 2rem;
-   width: 90%;
-   max-width: 600px;
+   padding: 1.2rem;
+   width: 96%;
+   max-width: 650px;
    max-height: 80vh;
    overflow-y: auto;
  }
```

### C. 个人主页弹窗 (CSS)

```diff
  .profile-modal {
-   max-width: 90%;
-   width: 90%;
-   padding: 1.5rem;
+   max-width: 96%;
+   width: 96%;
+   padding: 1rem;
  }
```

### D. 番茄钟统计弹窗 (HTML内联样式)

```diff
- <div class="modal-content glass-card" style="background: white; max-width: 600px;">
+ <div class="modal-content glass-card" style="background: white; max-width: 650px;">
```

### E. 联系与支持弹窗 (HTML内联样式)

```diff
- <div class="modal-content glass-card" style="background: white; max-width: 500px;">
+ <div class="modal-content glass-card" style="background: white; max-width: 550px; padding: 0.8rem;">
```

### F. 修改密码弹窗 (HTML内联样式)

```diff
- <div class="modal-content glass-card" style="background: white; max-width: 400px;">
+ <div class="modal-content glass-card" style="background: white; max-width: 450px;">
```

### G. 绑定手机号弹窗 (HTML内联样式)

```diff
- <div class="modal-content glass-card" style="background: white; max-width: 400px;">
+ <div class="modal-content glass-card" style="background: white; max-width: 450px;">
```

### H. 星期选择弹窗 (HTML内联样式)

```diff
- <div class="modal-content glass-card" style="background: white; max-width: 400px; padding: 1.5rem;">
+ <div class="modal-content glass-card" style="background: white; max-width: 450px; padding: 1rem;">
```

### I. 任务编辑弹窗 (HTML内联样式)

```diff
- <div class="modal-content glass-card" style="background: white; max-width: 500px;">
+ <div class="modal-content glass-card" style="background: white; max-width: 550px;">
```

### J. 隐私政策弹窗 (CSS)

```diff
  .privacy-modal {
    background: white;
-   max-width: 700px;
+   max-width: 750px;
    max-height: 80vh;
    overflow-y: auto;
  }
```

### K. 二维码区域 (CSS)

```diff
  .qr-codes {
    display: flex;
    justify-content: space-between;
    gap: 1rem;
    margin-bottom: 1rem;
-   padding: 0 1rem;
+   padding: 0;
  }
```

---

## 📊 修改统计

| 类型 | 数量 | 文件 |
|------|------|------|
| Bug修复 | 1处 | offlineTaskStore.js |
| HTML修改 | 7处 | TodoView.vue |
| CSS修改 | 4处 | TodoView.vue |
| 版本更新 | 1处 | package.json |
| **总计** | **13处** | **3个文件** |

---

## 🎯 影响范围

- ✅ 功能修复：待办筛选逻辑
- ✅ 视觉优化：9个弹窗空间利用率
- ✅ 交互优化：输入框功能区分
- ✅ 无破坏性变更
- ✅ 向后兼容
