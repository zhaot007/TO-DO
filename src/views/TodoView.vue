<template>
  <div class="todo-layout">
    <!-- 核心内容区 -->
    <main class="main-content glass-card">
      <!-- 顶部标题栏 -->
      <header class="header">
        <div class="user-info">
          <h1>{{ taskTitle }}</h1>
        </div>
        <div class="header-actions">
          <button class="btn btn-info" @click="showTrash = true">回收站 ({{ taskStore.deletedTasks.length }})</button>
          <button class="btn btn-danger" @click="handleLogout">退出登录</button>
          <button class="btn-icon" @click="showProfile = true" title="个人主页">👨‍💼</button>
        </div>
      </header>

      <!-- 统计+筛选+添加 - 融合区域 v1.2优化 -->
      <section class="dashboard-area">
        <!-- 第一行：统计数据（可点击筛选） + 添加按钮 -->
        <div class="stats-all-in-one">
          <!-- 环形进度圈 -->
          <div class="progress-ring-mini" @click="setFilter('all')" :class="{ active: currentFilter === 'all' }">
            <div class="progress-value-mini">{{ completionPercentage }}%</div>
          </div>
          
          <!-- 统计数据横向排列 -->
          <div class="stat-row clickable" @click="setFilter('pending')" :class="{ active: currentFilter === 'pending' }">
            <span class="stat-icon">⏳</span>
            <span class="stat-count-mini">{{ pendingCount }}</span>
            <span class="stat-label-mini">待办</span>
          </div>
          <div class="stat-row clickable" @click="setFilter('completed')" :class="{ active: currentFilter === 'completed' }">
            <span class="stat-icon">✅</span>
            <span class="stat-count-mini success">{{ completedCount }}</span>
            <span class="stat-label-mini">已完成</span>
          </div>
          <div class="stat-row clickable" @click="setFilter('overdue')" :class="{ active: currentFilter === 'overdue' }">
            <span class="stat-icon">⚠️</span>
            <span class="stat-count-mini danger">{{ overdueCount }}</span>
            <span class="stat-label-mini">已逾期</span>
          </div>
          
          <button class="add-btn-text" @click="showAddForm = !showAddForm">{{ showAddForm ? '收起' : '添加' }}</button>
        </div>

        <!-- 第二行：分类和时间筛选 -->
        <div class="filter-row">
          <div class="category-filters">
            <button 
              v-for="cat in categories" 
              :key="cat.value"
              class="category-btn"
              :class="{ active: currentCategoryFilter === cat.value }"
              @click="setCategoryFilter(cat.value)"
            >
              {{ cat.label }} ({{ getCategoryCount(cat.value) }})
            </button>
          </div>
          <div class="time-filter-compact">
            <div class="date-input-wrapper" @click="$refs.startDateInput.showPicker()">
              <input 
                ref="startDateInput"
                type="date" 
                v-model="startDate" 
                class="mini-date"
                @click.stop
              >
              <span class="calendar-icon">📅</span>
            </div>
            <span class="range-sep">至</span>
            <div class="date-input-wrapper" @click="$refs.endDateInput.showPicker()">
              <input 
                ref="endDateInput"
                type="date" 
                v-model="endDate" 
                class="mini-date"
                @click.stop
              >
              <span class="calendar-icon">📅</span>
            </div>
            <button v-if="startDate || endDate" class="clear-icon" @click="clearDateFilter">✕</button>
          </div>
        </div>

        <!-- 添加任务表单 -->
        <div v-if="showAddForm" class="add-form-inline">
          <input 
            type="text" 
            v-model="newTaskText" 
            class="input-inline"
            placeholder="任务名称"
            @keyup.enter="addTask"
          >
          <select v-model="newTaskType" class="select-inline">
            <option value="today">仅今天</option>
            <option value="daily">每天</option>
            <option value="weekly">自定义</option>
          </select>
          <select v-model="newTaskCategory" class="select-inline">
            <option value="work">工作</option>
            <option value="study">学习</option>
            <option value="life">生活</option>
          </select>
          <select v-model="newTaskPriority" class="select-inline">
            <option value="high">高</option>
            <option value="medium">中</option>
            <option value="low">低</option>
          </select>
          <button class="btn-inline btn-add" @click="addTask">✓</button>
          <button class="btn-inline btn-cancel" @click="showAddForm = false">×</button>
        </div>
        
        <div v-if="showAddForm && newTaskType === 'weekly'" class="weekday-select-inline">
          <label 
            v-for="(day, index) in weekdays" 
            :key="index"
            class="weekday-checkbox-item"
          >
            <input type="checkbox" :value="index" v-model="selectedWeekdays"> {{ day }}
          </label>
        </div>
      </section>

    <!-- 任务列表 -->
    <div class="task-list">
        <ul v-if="paginatedTasks.length > 0">
          <li 
            v-for="task in paginatedTasks" 
            :key="task.id"
            class="task-item"
            :class="{
              'task-completed': task.status === TaskStatus.COMPLETED,
              'task-overdue': task.status === TaskStatus.OVERDUE
            }"
          >
            <!-- v1.2: 增大点击热区 -->
            <label class="checkbox-wrapper">
              <input 
                type="checkbox" 
                class="task-checkbox" 
                :checked="task.status === TaskStatus.COMPLETED"
                @change="toggleTaskCompletion(task.id)"
              >
            </label>
            <div class="task-content">
              <span class="task-title" @click="openEditModal(task)" title="点击编辑详情">{{ task.text }}</span>
              <div v-if="task.description" class="task-description">{{ task.description }}</div>
              <div class="task-meta">
                <span class="task-time">🕒 {{ formatDateTime(task.created_at) }}</span>
                <span class="task-type badge">{{ getTaskTypeText(task) }}</span>
                <span class="badge badge-icon" :class="`priority-${task.priority}`" :title="`优先级: ${getPriorityText(task.priority)}`">
                  ⚡ {{ getPriorityText(task.priority) }}
                </span>
                <span class="badge badge-icon" :class="`category-${task.category}`" :title="`分类: ${getCategoryText(task.category)}`">
                  🏷️ {{ getCategoryText(task.category) }}
                </span>
                <span 
                  v-if="task.type === 'today' && task.status !== TaskStatus.COMPLETED" 
                  class="task-countdown"
                  :class="getCountdownClass(task)"
                >
                  {{ getCountdown(task) }}
                </span>
              </div>
            </div>
            <!-- v1.2: 增大删除按钮点击区域 -->
            <button class="btn-delete-touch" @click="deleteTask(task.id)" title="删除任务">
              ×
            </button>
          </li>
        </ul>
        <div v-else class="empty-state">
          <img src="https://illustrations.popsy.co/purple/taking-notes.svg" alt="empty" style="width: 150px; opacity: 0.5; margin-bottom: 1rem;">
          <p>任务清单空空如也，开启高效的一天吧！</p>
        </div>
        
        <!-- 分页控件 -->
        <div v-if="totalPages > 1" class="pagination">
          <button 
            class="page-btn" 
            :disabled="currentPage === 1" 
            @click="currentPage--"
          >
            ‹
          </button>
          <span class="page-info">{{ currentPage }} / {{ totalPages }}</span>
          <button 
            class="page-btn" 
            :disabled="currentPage === totalPages" 
            @click="currentPage++"
          >
            ›
          </button>
        </div>
      </div>
    </main>

    <!-- 回收站模态框 -->
    <div v-if="showTrash" class="modal-overlay" @click.self="showTrash = false">
      <div class="modal-content glass-card" style="background: white;">
        <div class="modal-header">
          <h3>回收站</h3>
          <button class="close-btn" @click="showTrash = false">&times;</button>
        </div>
        <div class="modal-body">
          <ul v-if="taskStore.deletedTasks.length > 0">
            <li v-for="task in taskStore.deletedTasks" :key="task.id" class="trash-item">
              <div class="trash-info">
                <span class="trash-title">{{ task.text }}</span>
                <span class="trash-meta:">原分类: {{ getCategoryText(task.category) }}</span>
              </div>
              <div class="trash-actions">
                <button class="btn btn-success btn-sm" @click="restoreTask(task.id)">恢复</button>
                <button class="btn btn-danger btn-sm" @click="permanentDelete(task.id)">彻底删除</button>
              </div>
            </li>
          </ul>
          <p v-else class="empty-state">回收站空空如也</p>
        </div>
      </div>
    </div>

    <!-- 个人主页弹窗 -->
    <div v-if="showProfile" class="modal-overlay" @click.self="showProfile = false">
      <div class="modal-content glass-card" style="background: white; max-width: 500px;">
        <div class="modal-header">
          <h3>个人主页</h3>
          <button class="close-btn" @click="showProfile = false">&times;</button>
        </div>
        <div class="modal-body">
          <!-- 用户信息展示 -->
          <div class="profile-section">
            <div class="profile-avatar">
              <div class="avatar-circle">{{ currentUsername ? currentUsername.charAt(0).toUpperCase() : 'U' }}</div>
            </div>
            <div class="profile-info">
              <h2>{{ currentUsername }}</h2>
              <div class="profile-details">
                <p class="profile-meta">📅 注册时间：{{ formatDate(userProfileInfo.registerTime) }}</p>
                <p class="profile-meta">🕐 最后登录：{{ formatDate(userProfileInfo.lastLoginTime) }}</p>
                <p class="profile-meta">📊 使用天数：{{ usageDays }}天</p>
              </div>
            </div>
          </div>

          <!-- 统计信息 -->
          <div class="profile-stats">
            <div class="stat-item">
              <div class="stat-value">{{ taskStore.tasks.length }}</div>
              <div class="stat-label">总任务</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">{{ completedCount }}</div>
              <div class="stat-label">已完成</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">{{ pendingCount }}</div>
              <div class="stat-label">待完成</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">{{ completionRate }}%</div>
              <div class="stat-label">完成率</div>
            </div>
          </div>

          <!-- 修改用户名 -->
          <div class="profile-form">
            <div class="form-group">
              <label>修改用户名</label>
              <input 
                v-model="newUsername" 
                class="input" 
                placeholder="输入新用户名"
              >
            </div>

            <!-- 修改密码 -->
            <div class="form-group">
              <label>修改密码</label>
              <input 
                v-model="oldPassword" 
                type="password" 
                class="input" 
                placeholder="输入当前密码"
              >
              <input 
                v-model="newPassword" 
                type="password" 
                class="input" 
                placeholder="输入新密码"
                style="margin-top: 0.5rem;"
              >
            </div>

            <div class="modal-actions">
              <button class="btn btn-secondary" @click="showProfile = false">取消</button>
              <button class="btn btn-primary" @click="updateProfile">保存修改</button>
            </div>
          </div>

          <!-- 数据导出与导入 -->
          <div class="export-section">
            <h4 class="export-title">📊 数据管理</h4>
            <p class="export-desc">导出或导入您的任务数据，轻松备份与迁移</p>
            <div class="data-buttons">
              <button class="btn btn-export" @click="exportToExcel">
                <span class="export-icon">📥</span>
                导出任务
              </button>
              <button class="btn btn-import" @click="triggerImport">
                <span class="export-icon">📤</span>
                导入任务
              </button>
              <button class="btn btn-template" @click="downloadTemplate">
                <span class="export-icon">📋</span>
                下载模板
              </button>
            </div>
            <input 
              ref="fileInput" 
              type="file" 
              accept=".xlsx,.xls" 
              style="display: none" 
              @change="importFromExcel"
            />
          </div>

          <!-- 联系与支持 -->
          <div class="support-section">
            <h4 class="support-title">💝 联系与支持</h4>
            <p class="support-desc">遇到bug别慌，扫码找我唠唠；用得爽了，请我喝杯奶茶呗 ☕</p>
            
            <div class="qr-codes">
              <div class="qr-item">
                <img src="../assets/images/wechat-qr.png" alt="微信二维码" class="qr-image">
                <p class="qr-label">💬 添加微信</p>
              </div>
              <div class="qr-item">
                <img src="../assets/images/payment-qr.png" alt="打赏二维码" class="qr-image">
                <p class="qr-label">💰 打赏支持</p>
              </div>
            </div>

            <div class="contact-info">
              <span class="contact-icon">📞</span>
              <span class="contact-text">联系电话：17858441076</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 任务详情编辑模态框 -->
    <div v-if="editingTask" class="modal-overlay" @click.self="editingTask = null">
      <div class="modal-content glass-card" style="background: white;">
        <div class="modal-header">
          <h3>编辑任务详情</h3>
          <button class="close-btn" @click="editingTask = null">&times;</button>
        </div>
        <div class="modal-body">
          <div class="edit-field">
            <label>任务名称</label>
            <input 
              v-model="editText" 
              class="input" 
              placeholder="任务名称"
            >
          </div>
          <div class="edit-field">
            <label>详细描述</label>
            <textarea 
              v-model="editDescription" 
              class="input textarea" 
              placeholder="添加更多细节描述..."
              rows="5"
            ></textarea>
          </div>
          <div class="modal-actions">
            <button class="btn btn-secondary" @click="editingTask = null">取消</button>
            <button class="btn btn-primary" @click="saveDescription">保存更改</button>
          </div>
        </div>
      </div>
    </div>

    <!-- 底部抽屉 - 添加任务 -->
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useOfflineTaskStore } from '../stores/offlineTaskStore'
import { useOfflineUserStore } from '../stores/offlineUserStore'
import { Preferences } from '@capacitor/preferences'
import { Filesystem, Directory } from '@capacitor/filesystem'
import * as XLSX from 'xlsx'

const router = useRouter()
const taskStore = useOfflineTaskStore()
const userStore = useOfflineUserStore()

// 任务状态枚举
const TaskStatus = {
  PENDING: 'pending',
  IN_PROGRESS: 'in_progress',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled',
  OVERDUE: 'overdue'
}

// 响应式数据
const newTaskText = ref('')
const newTaskType = ref('today')
const newTaskCategory = ref('work')
const newTaskPriority = ref('medium')
const selectedWeekdays = ref([])
const currentFilter = ref('all')
const currentCategoryFilter = ref('all')
const startDate = ref('')
const endDate = ref('')
const countdownInterval = ref(null)
const showTrash = ref(false)
const showProfile = ref(false)
const editingTask = ref(null)
const editDescription = ref('')
const editText = ref('')
const showAddForm = ref(true)
const currentPage = ref(1)
const pageSize = 6
const fileInput = ref(null)

// 个人主页相关
const newUsername = ref('')
const oldPassword = ref('')
const newPassword = ref('')
const userProfileInfo = ref({
  registerTime: null,
  lastLoginTime: null
})

// 获取当前用户名
const currentUsername = computed(() => userStore.currentUser)

// 智能生成标题
const taskTitle = computed(() => {
  const username = currentUsername.value
  if (!username) return '我的任务'
  // 判断是否为中文用户名
  const isChinese = /[\u4e00-\u9fa5]/.test(username)
  return isChinese ? `${username}的任务` : `${username}'s Tasks`
})

// 筛选选项
const filters = [
  { label: '全部任务', value: 'all' },
  { label: '未完成', value: 'pending' },
  { label: '已完成', value: 'completed' },
  { label: '已逾期', value: 'overdue' }
]

// 分类选项
const categories = [
  { label: '全部', value: 'all' },
  { label: '工作', value: 'work' },
  { label: '学习', value: 'study' },
  { label: '生活', value: 'life' }
]

// 星期几选项
const weekdays = ['日', '一', '二', '三', '四', '五', '六']

// 计算属性：按分类和时间筛选的任务（不按状态筛选，用于统计）
const baseFilteredTasks = computed(() => {
  return taskStore.getFilteredTasks('all', currentCategoryFilter.value, {
    start: startDate.value,
    end: endDate.value
  })
})

// 计算属性：完全筛选后的任务（包括状态筛选，用于显示）
const filteredTasks = computed(() => {
  return taskStore.getFilteredTasks(currentFilter.value, currentCategoryFilter.value, {
    start: startDate.value,
    end: endDate.value
  })
})

// 统计数据（基于baseFilteredTasks，不受状态筛选影响）
const completionPercentage = computed(() => {
  const total = baseFilteredTasks.value.length
  if (total === 0) return 0
  const completed = baseFilteredTasks.value.filter(t => t.status === TaskStatus.COMPLETED).length
  return Math.round((completed / total) * 100)
})

const pendingCount = computed(() => baseFilteredTasks.value.filter(t => t.status === TaskStatus.PENDING).length)
const completedCount = computed(() => baseFilteredTasks.value.filter(t => t.status === TaskStatus.COMPLETED).length)
const overdueCount = computed(() => baseFilteredTasks.value.filter(t => t.status === TaskStatus.OVERDUE).length)

// 分类统计（基于当前时间筛选）
const getCategoryCount = (category) => {
  const filtered = taskStore.getFilteredTasks('all', category, {
    start: startDate.value,
    end: endDate.value
  })
  return filtered.length
}

// 个人主页统计（基于所有任务）
const completionRate = computed(() => {
  const total = taskStore.tasks.length
  if (total === 0) return 0
  const completed = taskStore.tasks.filter(t => t.status === TaskStatus.COMPLETED).length
  return Math.round((completed / total) * 100)
})

const usageDays = computed(() => {
  if (!userProfileInfo.value.registerTime) return 0
  const registerDate = new Date(userProfileInfo.value.registerTime)
  const today = new Date()
  const diffTime = Math.abs(today - registerDate)
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  return diffDays
})

// 计算属性：总页数
const totalPages = computed(() => {
  return Math.ceil(filteredTasks.value.length / pageSize)
})

// 计算属性：当前页的任务
const paginatedTasks = computed(() => {
  const start = (currentPage.value - 1) * pageSize
  const end = start + pageSize
  return filteredTasks.value.slice(start, end)
})

// 方法：设置筛选条件
const setFilter = (filter) => {
  currentFilter.value = filter
  currentPage.value = 1
}

// 方法：设置分类筛选
const setCategoryFilter = (category) => {
  currentCategoryFilter.value = category
  currentPage.value = 1
}

// 方法：清除时间筛选
const clearDateFilter = () => {
  startDate.value = ''
  endDate.value = ''
  currentPage.value = 1
}

// 方法：筛选任务
const filterTasks = () => {
  // 筛选逻辑已在taskStore中实现
}

// 方法：添加任务并关闭表单
const addTaskAndClose = async () => {
  await addTask()
  if (newTaskText.value.trim()) {
    showAddForm.value = false
  }
}

// 方法：添加任务
const addTask = async () => {
  if (!newTaskText.value.trim()) return
  
  if (newTaskType.value === 'weekly' && selectedWeekdays.value.length === 0) {
    showNotification('请至少选择一个星期几！', 'error')
    return
  }
  
  const task = {
    text: newTaskText.value.trim(),
    type: newTaskType.value,
    category: newTaskCategory.value,
    priority: newTaskPriority.value,
    weekdays: newTaskType.value === 'weekly' ? selectedWeekdays.value : null
  }
  
  await taskStore.addTask(task)
  
  // 清空输入
  newTaskText.value = ''
  newTaskType.value = 'today'
  newTaskCategory.value = 'work'
  newTaskPriority.value = 'medium'
  selectedWeekdays.value = []
  
  showNotification('任务添加成功！', 'success')
}

// 方法：切换任务完成状态
const toggleTaskCompletion = async (taskId) => {
  await taskStore.toggleTaskCompletion(taskId)
}

// 方法：删除任务
const deleteTask = async (taskId) => {
  await taskStore.deleteTask(taskId)
  showNotification('任务已移至回收站！', 'info')
}

// 方法：恢复任务
const restoreTask = async (taskId) => {
  await taskStore.restoreTask(taskId)
  showNotification('任务已恢复！', 'success')
}

// 方法：彻底删除
const permanentDelete = async (taskId) => {
  if (confirm('确定要永久删除此任务吗？此操作不可撤销。')) {
    await taskStore.permanentDeleteTask(taskId)
    showNotification('任务已永久删除！', 'error')
  }
}

// 方法：打开编辑模态框
const openEditModal = (task) => {
  editingTask.value = { ...task }
  editText.value = task.text
  editDescription.value = task.description || ''
}

// 方法：保存描述
const saveDescription = async () => {
  if (!editingTask.value) return
  if (!editText.value.trim()) {
    showNotification('任务名称不能为空！', 'error')
    return
  }
  
  await taskStore.updateTask(editingTask.value.id, {
    text: editText.value.trim(),
    description: editDescription.value
  })
  
  editingTask.value = null
  showNotification('任务已更新！', 'success')
}

// 方法：退出登录
const handleLogout = () => {
  router.push('/')
}

// 方法：加载用户信息
const loadUserInfo = async () => {
  const username = currentUsername.value
  if (!username) return
  
  const { value: userInfoData } = await Preferences.get({ key: 'userInfo' })
  const userInfo = userInfoData ? JSON.parse(userInfoData) : {}
  
  if (userInfo[username]) {
    userProfileInfo.value = userInfo[username]
  } else {
    // 如果是老用户没有信息，创建默认信息
    userProfileInfo.value = {
      username: username,
      registerTime: new Date().toISOString(),
      lastLoginTime: new Date().toISOString()
    }
    userInfo[username] = userProfileInfo.value
    await Preferences.set({ key: 'userInfo', value: JSON.stringify(userInfo) })
  }
}

// 方法：格式化日期
const formatDate = (dateString) => {
  if (!dateString) return '未知'
  const date = new Date(dateString)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 方法：更新个人信息
const updateProfile = async () => {
  const username = currentUsername.value
  
  // 修改用户名
  if (newUsername.value && newUsername.value !== username) {
    // 检查新用户名是否已存在
    const { value: usersData } = await Preferences.get({ key: 'users' })
    const users = usersData ? JSON.parse(usersData) : {}
    
    if (users[newUsername.value]) {
      alert('用户名已存在，请选择其他用户名')
      return
    }
    
    // 更新用户名
    const password = users[username]
    delete users[username]
    users[newUsername.value] = password
    
    await Preferences.set({ key: 'users', value: JSON.stringify(users) })
    await Preferences.set({ key: 'currentUser', value: newUsername.value })
    
    // 更新任务的user_id
    taskStore.tasks.forEach(task => {
      if (task.user_id === username) {
        task.user_id = newUsername.value
      }
    })
    await taskStore.saveTasks()
    
    userStore.currentUser = newUsername.value
    alert('用户名修改成功')
  }
  
  // 修改密码
  if (oldPassword.value && newPassword.value) {
    const { value: usersData } = await Preferences.get({ key: 'users' })
    const users = usersData ? JSON.parse(usersData) : {}
    const currentUser = newUsername.value || username
    
    if (users[currentUser] !== oldPassword.value) {
      alert('当前密码错误')
      return
    }
    
    users[currentUser] = newPassword.value
    await Preferences.set({ key: 'users', value: JSON.stringify(users) })
    alert('密码修改成功')
  }
  
  // 重置表单
  newUsername.value = ''
  oldPassword.value = ''
  newPassword.value = ''
  showProfile.value = false
}

// 方法：导出任务到Excel
// 方法：导出任务到Excel
const exportToExcel = async () => {
  const tasks = taskStore.tasks
  
  if (tasks.length === 0) {
    alert('暂无任务数据可导出')
    return
  }
  
  try {
    // 准备导出数据
    const exportData = tasks.map(task => ({
      '任务名称': task.text,
      '详细描述': task.description || '',
      '分类': getCategoryText(task.category),
      '优先级': getPriorityText(task.priority),
      '类型': getTaskTypeText(task),
      '状态': task.status === 'completed' ? '已完成' : task.status === 'overdue' ? '已逾期' : '待办',
      '创建时间': formatDate(task.created_at)
    }))
    
    // 创建工作簿
    const ws = XLSX.utils.json_to_sheet(exportData)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, '我的任务')
    
    // 生成文件名
    const filename = `TODO任务_${currentUsername.value}_${new Date().toLocaleDateString('zh-CN').replace(/\//g, '-')}.xlsx`
    
    // 生成二进制数据
    const wbout = XLSX.write(wb, { bookType: 'xlsx', type: 'base64' })
    
    // 保存到Android下载目录
    await Filesystem.writeFile({
      path: filename,
      data: wbout,
      directory: Directory.Documents
    })
    
    showNotification(`文件已保存到：文档/${filename}`, 'success')
  } catch (error) {
    console.error('导出失败:', error)
    showNotification('导出失败，请重试', 'error')
  }
}

// 方法：获取任务类型文本
const getTaskTypeText = (task) => {
  switch (task.type) {
    case 'today':
      return '仅今天'
    case 'daily':
      return '每天'
    case 'weekly':
      if (task.weekdays) {
        const selectedDays = task.weekdays.map(day => weekdays[day]).join(', ')
        return `每周: ${selectedDays}`
      }
      return '每周'
    default:
      return ''
  }
}

// 方法：获取优先级文本
const getPriorityText = (priority) => {
  const priorityMap = {
    high: '高',
    medium: '中',
    low: '低'
  }
  return priorityMap[priority] || priority
}

// 方法：获取分类文本
const getCategoryText = (category) => {
  const categoryMap = {
    work: '工作',
    study: '学习',
    life: '生活'
  }
  return categoryMap[category] || category
}

// 方法：触发文件选择
const triggerImport = () => {
  fileInput.value?.click()
}

// 方法：下载导入模板
const downloadTemplate = () => {
  const templateUrl = 'https://github.com/zhaosj0315/TO-DO/raw/main/TODO%E5%AF%BC%E5%85%A5%E6%A8%A1%E6%9D%BF%E7%A4%BA%E4%BE%8B.xlsx'
  const link = document.createElement('a')
  link.href = templateUrl
  link.download = 'TODO导入模板示例.xlsx'
  link.click()
  showNotification('开始下载导入模板...', 'success')
}

// 方法：导入任务
const importFromExcel = async (event) => {
  const file = event.target.files?.[0]
  if (!file) return
  
  try {
    const reader = new FileReader()
    reader.onload = async (e) => {
      try {
        const data = new Uint8Array(e.target.result)
        const workbook = XLSX.read(data, { type: 'array' })
        const sheet = workbook.Sheets[workbook.SheetNames[0]]
        const rows = XLSX.utils.sheet_to_json(sheet)
        
        if (rows.length === 0) {
          showNotification('文件中没有数据', 'error')
          return
        }
        
        let successCount = 0
        let errorCount = 0
        
        for (const row of rows) {
          try {
            const taskName = row['任务名称']?.trim()
            if (!taskName) {
              errorCount++
              continue
            }
            
            const category = parseCategoryText(row['分类'])
            const priority = parsePriorityText(row['优先级'])
            const type = parseTypeText(row['类型'])
            const status = parseStatusText(row['状态'])
            const createdAt = parseDateTime(row['创建时间'])
            
            const newTask = {
              id: Date.now() + successCount,
              text: taskName,
              description: row['详细描述'] || '',
              type: type,
              category: category,
              priority: priority,
              weekdays: type === 'weekly' ? parseWeekdays(row['类型']) : [],
              status: status,
              created_at: createdAt,
              user_id: currentUsername.value
            }
            
            await taskStore.addTask(newTask)
            successCount++
          } catch (err) {
            console.error('导入单条任务失败:', err)
            errorCount++
          }
        }
        
        showNotification(`导入完成：成功 ${successCount} 条，失败 ${errorCount} 条`, 'success')
        fileInput.value.value = ''
      } catch (error) {
        console.error('解析文件失败:', error)
        showNotification('文件格式错误，请使用导出的模板', 'error')
      }
    }
    reader.readAsArrayBuffer(file)
  } catch (error) {
    console.error('读取文件失败:', error)
    showNotification('读取文件失败', 'error')
  }
}

// 解析分类文本
const parseCategoryText = (text) => {
  const map = { '工作': 'work', '学习': 'study', '生活': 'life' }
  return map[text] || 'work'
}

// 解析优先级文本
const parsePriorityText = (text) => {
  const map = { '高': 'high', '中': 'medium', '低': 'low' }
  return map[text] || 'medium'
}

// 解析类型文本
const parseTypeText = (text) => {
  if (!text) return 'today'
  if (text === '仅今天') return 'today'
  if (text === '每天') return 'daily'
  if (text.includes('每周')) return 'weekly'
  return 'today'
}

// 解析状态文本
const parseStatusText = (text) => {
  if (text === '已完成') return 'completed'
  if (text === '已逾期') return 'overdue'
  return 'pending'
}

// 解析周期（从类型字段提取）
const parseWeekdays = (text) => {
  if (!text || !text.includes('每周')) return []
  const dayMap = { '周一': 1, '周二': 2, '周三': 3, '周四': 4, '周五': 5, '周六': 6, '周日': 0 }
  const days = []
  for (const [key, value] of Object.entries(dayMap)) {
    if (text.includes(key)) days.push(value)
  }
  return days
}

// 解析日期时间
const parseDateTime = (text) => {
  if (!text) return new Date().toISOString()
  try {
    // 处理字符串格式
    if (typeof text === 'string') {
      // 替换斜杠为横杠，统一格式
      const normalized = text.replace(/\//g, '-')
      const date = new Date(normalized)
      if (!isNaN(date.getTime())) {
        return date.toISOString()
      }
    }
    // 处理Excel日期数字格式
    if (typeof text === 'number') {
      // Excel日期是从1900-01-01开始的天数
      const excelEpoch = new Date(1900, 0, 1)
      const date = new Date(excelEpoch.getTime() + (text - 2) * 86400000)
      return date.toISOString()
    }
    // 直接尝试转换
    const date = new Date(text)
    return isNaN(date.getTime()) ? new Date().toISOString() : date.toISOString()
  } catch {
    return new Date().toISOString()
  }
}

// 方法：格式化日期时间
const formatDateTime = (dateStr) => {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  return date.toLocaleString('zh-CN', {
    timeZone: 'Asia/Shanghai',
    month: 'numeric',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  })
}

// 方法：获取倒计时
const getCountdown = (task) => {
  const now = new Date()
  const created = new Date(task.created_at)
  const endOfDay = new Date(created.getFullYear(), created.getMonth(), created.getDate(), 23, 59, 59)
  const remainingTime = endOfDay - now
  
  if (remainingTime > 0) {
    const hours = Math.floor(remainingTime / (1000 * 60 * 60))
    const minutes = Math.floor((remainingTime % (1000 * 60 * 60)) / (1000 * 60))
    return `剩余: ${hours}h ${minutes}m`
  } else {
    const overdueTime = Math.abs(remainingTime)
    const hours = Math.floor(overdueTime / (1000 * 60 * 60))
    const minutes = Math.floor((overdueTime % (1000 * 60 * 60)) / (1000 * 60))
    return `逾期: ${hours}h ${minutes}m`
  }
}

// v1.2: 获取倒计时颜色类
const getCountdownClass = (task) => {
  const now = new Date()
  const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59)
  const remainingTime = endOfDay - now
  const hours = remainingTime / (1000 * 60 * 60)
  
  if (hours <= 1) return 'countdown-urgent'      // 小于1小时：红色
  if (hours <= 3) return 'countdown-warning'     // 小于3小时：橙色
  return 'countdown-normal'                       // 正常：蓝色
}

// 方法：显示通知
const emit = defineEmits(['notify'])
const showNotification = (message, type = 'info') => {
  emit('notify', { message, type })
}

// 生命周期钩子：组件挂载时
onMounted(async () => {
  await userStore.checkLogin()
  await loadUserInfo()
  taskStore.loadTasks()
  
  countdownInterval.value = setInterval(() => {
    taskStore.checkOverdueTasks()
  }, 1000)
})

// 生命周期钩子：组件卸载时
onUnmounted(() => {
  if (countdownInterval.value) clearInterval(countdownInterval.value)
})
</script>

<style scoped>
.todo-layout {
  display: flex;
  justify-content: center;
  padding: 0.5rem;
  min-height: 100vh;
  width: 100%;
  max-width: 100vw;
  overflow-x: hidden;
}

.main-content {
  width: 100%;
  max-width: 100%;
  flex: none;
  padding: 0.5rem;
  box-sizing: border-box;
}

/* v1.2: 统计栏卡片感增强 */
.dashboard-area {
  background: rgba(255, 255, 255, 0.35);
  border-radius: 12px;
  padding: 0.8rem;
  margin-bottom: 1rem;
  border: 1.5px solid rgba(255, 255, 255, 0.5);
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
}

.stats-all-in-one {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  justify-content: space-between;
  margin-bottom: 0.8rem;
  flex-wrap: nowrap;
}

/* v1.2: 统计数据横向紧凑排列 */
.stat-row {
  display: flex;
  align-items: center;
  gap: 0.15rem;
  padding: 0.2rem 0.3rem;
  border-radius: 8px;
  transition: all 0.3s;
  flex-shrink: 1;
  min-width: 0;
}

.stat-row.clickable {
  cursor: pointer;
}

.stat-row.clickable:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: scale(1.05);
}

.stat-row.active {
  background: rgba(255, 255, 255, 0.5);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.stat-icon {
  font-size: 0.8rem;
  flex-shrink: 0;
}

.stat-count-mini {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--text-dark);
  min-width: 16px;
}

.stat-count-mini.success { color: var(--success-color); }
.stat-count-mini.danger { color: var(--error-color); }

.stat-label-mini {
  font-size: 0.65rem;
  color: var(--text-light);
  white-space: nowrap;
}

/* 第二行：分类和时间筛选 */
.filter-row {
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
  width: 100%;
}

.category-filters {
  display: flex;
  gap: 0.5rem;
  flex-wrap: nowrap;
  flex: 1;
  width: 100%;
}

.category-btn {
  flex: 1;
  padding: 0.5rem 0.8rem;
  border-radius: 18px;
  border: 1px solid rgba(255, 255, 255, 0.4);
  background: rgba(255, 255, 255, 0.3);
  color: var(--text-dark);
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.3s;
  white-space: nowrap;
  flex-shrink: 0;
  text-align: center;
  min-width: 0;
}

.category-btn:hover {
  background: rgba(255, 255, 255, 0.5);
}

.category-btn.active {
  background: white;
  border-color: var(--primary-color);
  color: var(--primary-color);
  font-weight: 600;
}

.time-filter-compact {
  display: flex;
  align-items: center;
  background: rgba(255, 255, 255, 0.4);
  border: 1px solid rgba(255, 255, 255, 0.5);
  border-radius: 20px;
  padding: 0.4rem 0.6rem;
  gap: 0.4rem;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.05);
  transition: all 0.3s;
  flex-wrap: nowrap;
  justify-content: center;
  max-width: 100%;
}

.time-filter-compact:hover {
  background: rgba(255, 255, 255, 0.5);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.date-input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  background: rgba(255, 255, 255, 0.6);
  border-radius: 12px;
  padding: 0.35rem 0.5rem;
  cursor: pointer;
  transition: all 0.3s;
  min-width: 100px;
  flex: 1;
  max-width: 130px;
}

.date-input-wrapper:hover {
  background: rgba(255, 255, 255, 0.8);
  transform: translateY(-1px);
}

.date-input-wrapper:active {
  transform: translateY(0);
}

.mini-date {
  border: none;
  background: transparent;
  font-size: 0.8rem;
  color: var(--text-dark);
  font-weight: 500;
  outline: none;
  cursor: pointer;
  flex: 1;
  min-width: 0;
}

.mini-date::-webkit-calendar-picker-indicator {
  display: none;
}

.calendar-icon {
  font-size: 0.9rem;
  margin-left: 0.25rem;
  pointer-events: none;
  opacity: 0.7;
  flex-shrink: 0;
}

.range-sep {
  color: var(--text-light);
  font-size: 0.8rem;
  font-weight: 500;
  padding: 0 0.1rem;
  flex-shrink: 0;
}

.clear-icon {
  background: var(--error-color);
  color: white;
  border: none;
  border-radius: 50%;
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 12px;
  font-weight: bold;
  transition: all 0.2s;
  flex-shrink: 0;
}

.clear-icon:hover {
  transform: scale(1.15);
  box-shadow: 0 2px 6px rgba(239, 68, 68, 0.4);
}

.clear-icon:active {
  transform: scale(0.95);
}

.add-btn-text {
  padding: 0.4rem 1rem;
  border-radius: 20px;
  background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
  border: none;
  color: white;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  white-space: nowrap;
}

.add-btn-text:hover {
  transform: scale(1.05);
  box-shadow: 0 2px 8px rgba(102, 126, 234, 0.4);
}

.add-btn-text:active {
  transform: scale(0.95);
}

.progress-ring-mini {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 50px;
  height: 50px;
  background: white;
  border-radius: 50%;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  flex-shrink: 0;
  padding: 0;
  cursor: pointer;
  transition: all 0.3s;
}

.progress-ring-mini:hover {
  background: rgba(255, 255, 255, 0.95);
  transform: scale(1.05);
}

.progress-ring-mini.active {
  background: rgba(255, 255, 255, 1);
  box-shadow: 0 2px 12px rgba(102, 126, 234, 0.3);
}

.progress-value-mini {
  font-size: 0.85rem;
  font-weight: 800;
  color: var(--primary-color);
}

.interaction-area {
  background: rgba(255, 255, 255, 0.2);
  border-radius: 16px;
  padding: 1.2rem;
  margin-bottom: 1.5rem;
  border: 1px solid rgba(255, 255, 255, 0.3);
}

.interaction-area {
  display: none;
}

.filter-toolbar {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  overflow-x: auto;
  white-space: nowrap;
  scrollbar-width: none;
}

.filter-toolbar::-webkit-scrollbar {
  display: none;
}

.mobile-select {
  background: rgba(255, 255, 255, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 8px;
  padding: 0.5rem 0.8rem;
  font-size: 0.85rem;
  color: var(--text-dark);
  cursor: pointer;
  transition: all 0.3s;
}

.mobile-select:focus {
  outline: none;
  background: white;
  border-color: var(--primary-color);
}

.mobile-time-range {
  display: flex;
  align-items: center;
  background: rgba(255, 255, 255, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 8px;
  padding: 0.3rem 0.6rem;
  gap: 0.3rem;
}

.mini-date {
  border: none;
  background: transparent;
  font-size: 0.8rem;
  color: var(--text-dark);
  font-weight: 500;
  outline: none;
  cursor: pointer;
  flex: 1;
  min-width: 0;
}

.mini-date::-webkit-calendar-picker-indicator {
  display: none;
}

.range-sep {
  color: var(--text-light);
  font-size: 0.85rem;
  font-weight: 500;
  padding: 0 0.2rem;
}

.clear-icon {
  background: var(--error-color);
  color: white;
  border: none;
  border-radius: 50%;
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 12px;
  font-weight: bold;
  transition: all 0.2s;
  flex-shrink: 0;
}

.clear-icon:hover {
  transform: scale(1.15);
  box-shadow: 0 2px 6px rgba(239, 68, 68, 0.4);
}

.clear-icon:active {
  transform: scale(0.95);
}

.task-input-section {
  padding: 0;
  background: transparent;
  border-radius: 0;
  box-shadow: none;
}

.btn-text {
  background: none;
  border: none;
  color: var(--primary-color);
  font-size: 0.85rem;
  cursor: pointer;
  padding: 0;
  text-decoration: underline;
}

.date-input-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.date-input-item .input {
  flex: 1;
}

.task-time {
  font-size: 0.8rem;
  color: var(--text-light);
  padding: 0.2rem 0.4rem;
  border-radius: 4px;
}

.task-filters {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 2rem;
  margin-bottom: 2.5rem;
  flex-wrap: wrap;
}

.weekday-select {
  display: flex;
  flex-direction: column;
  padding: 0.8rem;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.3);
}

.weekday-checkboxes {
  display: flex;
  gap: 0.4rem;
  flex-wrap: wrap;
}

.weekday-checkbox-item {
  display: flex;
  align-items: center;
  padding: 0.3rem 0.6rem;
  background: white;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
  font-size: 0.8rem;
}

.weekday-checkbox-item:has(input:checked) {
  background: var(--primary-color);
  color: white;
}

/* v1.2: 触摸优化 - 增大点击热区 */
.checkbox-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0.5rem;
  margin: -0.5rem 0.5rem -0.5rem -0.5rem;
  cursor: pointer;
}

/* v1.2: 任务卡片触摸反馈 */
.task-item {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  padding: 1rem;
  background: white;
  border-radius: 12px;
  margin-bottom: 0.8rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.3s;
  -webkit-tap-highlight-color: transparent;
}

.task-item:active {
  transform: scale(0.98);
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.1);
}

.task-checkbox {
  transform: scale(1.3);
  cursor: pointer;
}

/* v1.2: 触摸优化 - 删除按钮 */
.btn-delete-touch {
  min-width: 44px;
  min-height: 44px;
  width: 44px;
  height: 44px;
  padding: 0;
  border-radius: 50%;
  border: none;
  background: linear-gradient(135deg, #f44336, #e91e63);
  color: white;
  font-size: 1.5rem;
  font-weight: 300;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.btn-delete-touch:hover {
  transform: scale(1.1);
  box-shadow: 0 4px 12px rgba(244, 67, 54, 0.4);
}

.btn-delete-touch:active {
  transform: scale(0.95);
}

.task-content {
  flex: 1;
  display: flex;
  flex-direction: column;
}

/* v1.2: 字体比例优化 */
.task-title {
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: color 0.2s;
  line-height: 1.4;
}

.task-title:hover {
  color: var(--primary-color);
}

.task-description {
  font-size: 0.85rem;
  color: #888;
  margin-top: 0.4rem;
  line-height: 1.4;
  max-width: 100%;
  word-wrap: break-word;
}

.task-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.6rem;
  align-items: center;
  margin-top: 0.5rem;
}

/* v1.2: 图标化徽章 */
.badge-icon {
  display: inline-flex;
  align-items: center;
  gap: 0.2rem;
}

/* v1.2: 倒计时颜色分级 */
.task-countdown {
  font-size: 0.85rem;
  font-weight: 600;
  padding: 0.2rem 0.5rem;
  border-radius: 12px;
  transition: all 0.3s;
}

.countdown-normal {
  background: rgba(102, 126, 234, 0.1);
  color: var(--primary-color);
}

.countdown-warning {
  background: rgba(255, 152, 0, 0.1);
  color: #ff9800;
  animation: pulse 2s infinite;
}

.countdown-urgent {
  background: rgba(244, 67, 54, 0.1);
  color: #f44336;
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

.header-actions {
  display: flex;
  gap: 0.8rem;
  align-items: center;
}

.btn-icon {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  border: 2px solid rgba(102, 126, 234, 0.3);
  background: white;
  font-size: 1.5rem;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
}

.btn-icon:hover {
  background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
  border-color: transparent;
  transform: scale(1.1);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.btn-icon:active {
  transform: scale(0.95);
}

/* 个人主页样式 */
.profile-section {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  padding: 1.5rem;
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.1), rgba(118, 75, 162, 0.1));
  border-radius: 12px;
  margin-bottom: 1.5rem;
}

.profile-avatar {
  flex-shrink: 0;
}

.avatar-circle {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
  font-weight: bold;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.profile-info h2 {
  margin: 0 0 0.8rem 0;
  font-size: 1.5rem;
  color: var(--text-dark);
}

.profile-details {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.profile-meta {
  margin: 0;
  color: var(--text-light);
  font-size: 0.85rem;
  display: flex;
  align-items: center;
  gap: 0.3rem;
}

.profile-stats {
  display: flex;
  justify-content: space-around;
  padding: 1.5rem;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  margin-bottom: 1.5rem;
}

.stat-item {
  text-align: center;
}

.stat-value {
  font-size: 2rem;
  font-weight: bold;
  color: var(--primary-color);
  margin-bottom: 0.5rem;
}

.stat-label {
  font-size: 0.85rem;
  color: var(--text-light);
}

.profile-form {
  padding: 0 1rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: var(--text-dark);
}

.btn-primary {
  background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
  color: white;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

/* 支持与联系区域 */
/* 数据导出区域 */
.export-section {
  margin-top: 1.5rem;
  padding: 1rem;
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.1), rgba(118, 75, 162, 0.1));
  border-radius: 12px;
  border: 2px solid rgba(102, 126, 234, 0.2);
  text-align: center;
}

.export-title {
  margin: 0 0 0.5rem 0;
  font-size: 0.95rem;
  color: var(--text-dark);
}

.export-desc {
  margin: 0 0 1rem 0;
  font-size: 0.8rem;
  color: var(--text-light);
  line-height: 1.4;
}

.data-buttons {
  display: flex;
  gap: 0.8rem;
  justify-content: center;
}

.btn-export, .btn-import, .btn-template {
  background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
  color: white;
  border: none;
  padding: 0.6rem 1.5rem;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  flex: 1;
  justify-content: center;
}

.btn-import {
  background: linear-gradient(135deg, #10b981, #059669);
}

.btn-template {
  background: linear-gradient(135deg, #f59e0b, #d97706);
}

.btn-export:hover, .btn-import:hover, .btn-template:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.btn-import:hover {
  box-shadow: 0 4px 12px rgba(16, 185, 129, 0.4);
}

.btn-template:hover {
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.4);
}

.btn-export:active, .btn-import:active, .btn-template:active {
  transform: translateY(0);
}

.export-icon {
  font-size: 1.2rem;
}

/* 支持与联系区域 */
.support-section {
  margin-top: 1.5rem;
  padding: 1rem;
  background: linear-gradient(135deg, rgba(255, 193, 7, 0.1), rgba(255, 152, 0, 0.1));
  border-radius: 12px;
  border: 2px dashed rgba(255, 193, 7, 0.3);
}

.support-title {
  margin: 0 0 0.3rem 0;
  font-size: 0.95rem;
  color: var(--text-dark);
  text-align: center;
}

.support-desc {
  margin: 0 0 1rem 0;
  font-size: 0.8rem;
  color: var(--text-light);
  text-align: center;
  line-height: 1.3;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.qr-codes {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 1rem;
  padding: 0 1rem;
}

.qr-item {
  text-align: center;
  flex: 1;
}

.qr-image {
  width: 100%;
  max-width: 160px;
  height: auto;
  aspect-ratio: 1;
  border-radius: 8px;
  border: 2px solid rgba(255, 255, 255, 0.8);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  background: white;
  padding: 4px;
}

.qr-label {
  margin: 0.3rem 0 0 0;
  font-size: 0.8rem;
  color: var(--text-dark);
  font-weight: 600;
}

.contact-info {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.6rem;
  background: rgba(255, 255, 255, 0.6);
  border-radius: 8px;
}

.contact-icon {
  font-size: 1rem;
}

.contact-text {
  font-size: 0.8rem;
  color: var(--text-dark);
  font-weight: 600;
}

/* 模态框样式 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
  backdrop-filter: blur(8px);
}

.modal-content {
  padding: 2rem;
  width: 90%;
  max-width: 600px;
  max-height: 80vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  border-bottom: 1px solid #eee;
  padding-bottom: 1rem;
}

.close-btn {
  background: none;
  border: none;
  font-size: 2rem;
  cursor: pointer;
  color: #999;
}

.trash-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-bottom: 1px solid #f5f5f5;
}

.trash-info {
  display: flex;
  flex-direction: column;
}

.trash-title {
  font-weight: 600;
}

.trash-meta {
  font-size: 0.85rem;
  color: #888;
}

.trash-actions {
  display: flex;
  gap: 0.5rem;
}

.btn-sm {
  padding: 0.4rem 0.8rem;
  font-size: 0.85rem;
}

.btn-success {
  background-color: var(--success-color);
  color: white;
}

.btn-info {
  background-color: var(--primary-color);
  color: white;
  opacity: 0.9;
}

.btn-info:hover {
  opacity: 1;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem 2rem;
  color: var(--text-light);
  text-align: center;
}

.edit-field {
  margin-bottom: 1.5rem;
}

.edit-field label {
  display: block;
  font-weight: 600;
  margin-bottom: 0.5rem;
  color: var(--text-dark);
}

.task-name-static {
  padding: 0.8rem;
  background: #f8f9fa;
  border-radius: 8px;
  color: #666;
}

.textarea {
  width: 100%;
  resize: vertical;
  min-height: 120px;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 2rem;
}

.btn-secondary {
  background-color: #e9ecef;
  color: #495057;
}

.btn-secondary:hover {
  background-color: #dee2e6;
}

/* 内联添加表单 */
.add-form-inline {
  display: flex;
  gap: 0.3rem;
  margin-top: 0.8rem;
  padding-top: 0.8rem;
  border-top: 1px solid rgba(255, 255, 255, 0.3);
  flex-wrap: nowrap;
  align-items: center;
  width: 100%;
  box-sizing: border-box;
}

.input-inline {
  flex: 1.2;
  min-width: 0;
  padding: 0.4rem 0.5rem;
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.6);
  font-size: 0.85rem;
  box-sizing: border-box;
}

.input-inline:focus {
  outline: none;
  background: white;
  border-color: var(--primary-color);
}

.select-inline {
  padding: 0.4rem 0.3rem;
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.6);
  font-size: 0.8rem;
  cursor: pointer;
  min-width: 0;
  box-sizing: border-box;
  flex-shrink: 1;
}

.select-inline:focus {
  outline: none;
  background: white;
  border-color: var(--primary-color);
}

.btn-inline {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: none;
  font-size: 1.1rem;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-sizing: border-box;
}

.btn-add {
  background: var(--success-color);
  color: white;
}

.btn-add:hover {
  transform: scale(1.1);
}

.btn-cancel {
  background: #e9ecef;
  color: #666;
}

.btn-cancel:hover {
  background: #dee2e6;
}

.weekday-select-inline {
  display: flex;
  gap: 0.5rem;
  margin-top: 0.5rem;
  flex-wrap: wrap;
}

.weekday-select-inline .weekday-checkbox-item {
  padding: 0.3rem 0.6rem;
  background: white;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
  font-size: 0.8rem;
}

.weekday-select-inline .weekday-checkbox-item:has(input:checked) {
  background: var(--primary-color);
  color: white;
}

/* 悬浮添加按钮 - 已移除，改为顶部按钮 */

/* 底部抽屉 - 已移除，改为内联表单 */

/* 分页控件 */
.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
  margin-top: 1.5rem;
  padding: 1rem 0;
}

.page-btn {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 1px solid rgba(102, 126, 234, 0.3);
  background: white;
  color: var(--primary-color);
  font-size: 1.2rem;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.page-btn:hover:not(:disabled) {
  background: var(--primary-color);
  color: white;
  transform: scale(1.1);
}

.page-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.page-info {
  font-size: 0.9rem;
  color: var(--text-dark);
  font-weight: 600;
  min-width: 60px;
  text-align: center;
}
</style>