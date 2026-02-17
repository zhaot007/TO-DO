<template>
  <div class="todo-layout">
    <!-- 左侧侧边栏: 分类与统计 -->
    <aside class="sidebar">
      <div class="glass-card card-padding">
        <h3 class="card-title">📊 任务统计</h3>
        <div class="progress-container">
          <div class="progress-bar">
            <div class="progress-fill" :style="{ width: completionPercentage + '%' }"></div>
          </div>
          <p style="font-size: 0.9rem; color: var(--text-light); text-align: center;">
            今日已完成 {{ completionPercentage }}%
          </p>
        </div>
      </div>
    </aside>

    <!-- 中间核心任务列表 -->
    <main class="main-content glass-card">
      <!-- 顶部栏 -->
      <header class="header">
        <div class="user-info">
          <h1>My Tasks</h1>
        </div>
        <div class="header-actions">
          <button class="btn btn-info" @click="showTrash = true">回收站 ({{ taskStore.deletedTasks.length }})</button>
          <button class="btn btn-danger" @click="handleLogout">退出登录</button>
        </div>
      </header>

      <!-- 筛选与添加区域容器 -->
      <div class="interaction-area">
        <!-- 移动端 App 风格的单行筛选工具栏 -->
        <section class="filter-toolbar">
          <div class="filter-item">
            <select v-model="currentFilter" class="mobile-select">
              <option v-for="f in filters" :key="f.value" :value="f.value">{{ f.label }}</option>
            </select>
          </div>

          <div class="filter-item">
            <select v-model="currentCategoryFilter" class="mobile-select">
              <option value="all">全部分类</option>
              <option value="work">工作</option>
              <option value="study">学习</option>
              <option value="life">生活</option>
            </select>
          </div>

          <div class="filter-item">
            <div class="mobile-time-range">
              <input type="datetime-local" v-model="startDate" step="3600" class="mini-date" title="开始时间">
              <span class="range-sep">-</span>
              <input type="datetime-local" v-model="endDate" step="3600" class="mini-date" title="结束时间">
              <button v-if="startDate || endDate" class="clear-icon" @click="clearDateFilter">×</button>
            </div>
          </div>
        </section>

        <!-- 任务添加区域 -->
        <div class="task-input-section">
        <div class="input-row">
          <input 
            type="text" 
            v-model="newTaskText" 
            class="input"
            placeholder="有什么新计划吗？"
            @keyup.enter="addTask"
          >
        </div>
        <div class="input-row">
          <select v-model="newTaskType" class="select">
            <option value="today">仅今天</option>
            <option value="daily">每天</option>
            <option value="weekly">自定义</option>
          </select>
          <select v-model="newTaskCategory" class="select">
            <option value="work">工作</option>
            <option value="study">学习</option>
            <option value="life">生活</option>
          </select>
          <select v-model="newTaskPriority" class="select">
            <option value="medium">中优先级</option>
            <option value="high">高优先级</option>
            <option value="low">低优先级</option>
          </select>
          <button class="btn btn-primary" @click="addTask">添加任务</button>
        </div>
        
        <div v-if="newTaskType === 'weekly'" class="weekday-select" style="margin-top: 0.5rem;">
          <label style="font-size: 0.85rem; margin-bottom: 0.3rem;">选择重复周期:</label>
          <div class="weekday-checkboxes">
            <label 
              v-for="(day, index) in weekdays" 
              :key="index"
              class="weekday-checkbox-item"
            >
              <input type="checkbox" :value="index" v-model="selectedWeekdays"> {{ day }}
            </label>
          </div>
        </div>
      </div>
    </div>

    <!-- 任务列表 -->
    <div class="task-list">
        <ul v-if="filteredTasks.length > 0">
          <li 
            v-for="task in filteredTasks" 
            :key="task.id"
            class="task-item"
            :class="{
              'task-completed': task.status === TaskStatus.COMPLETED,
              'task-overdue': task.status === TaskStatus.OVERDUE
            }"
          >
            <input 
              type="checkbox" 
              class="task-checkbox" 
              :checked="task.status === TaskStatus.COMPLETED"
              @change="toggleTaskCompletion(task.id)"
            >
            <div class="task-content">
              <span class="task-title">{{ task.text }}</span>
              <div class="task-meta">
                <span class="task-time" :title="'创建于 ' + new Date(task.created_at).toLocaleString()">🕒 {{ formatDateTime(task.created_at) }}</span>
                <span class="task-type">{{ getTaskTypeText(task) }}</span>
                <span class="badge" :class="`priority-${task.priority}`">{{ getPriorityText(task.priority) }}</span>
                <span class="badge" :class="`category-${task.category}`">{{ getCategoryText(task.category) }}</span>
                <span v-if="task.type === 'today' && task.status !== TaskStatus.COMPLETED" class="task-countdown">
                  {{ getCountdown(task) }}
                </span>
              </div>
            </div>
            <button class="btn btn-danger" style="width: 32px; height: 32px; padding: 0; border-radius: 50%;" @click="deleteTask(task.id)">
              ×
            </button>
          </li>
        </ul>
        <div v-else class="empty-state">
          <img src="https://illustrations.popsy.co/purple/taking-notes.svg" alt="empty" style="width: 150px; opacity: 0.5; margin-bottom: 1rem;">
          <p>任务清单空空如也，开启高效的一天吧！</p>
        </div>
      </div>
    </main>

    <!-- 右侧挂件区 -->
    <aside class="widgets-area">
      <div class="glass-card card-padding">
        <h3 class="card-title">⏰ 当前时间</h3>
        <div style="text-align: center;">
          <div style="font-size: 2.5rem; font-weight: 800; color: var(--primary-color);">{{ currentTime }}</div>
          <div style="font-size: 1rem; color: var(--text-light);">{{ currentDay }}</div>
        </div>
      </div>

      <div class="glass-card card-padding">
        <h3 class="card-title">💡 每日灵感</h3>
        <p style="font-style: italic; color: var(--text-light); line-height: 1.8;">
          "{{ randomMotto }}"
        </p>
      </div>

      <div class="glass-card card-padding">
        <h3 class="card-title">📅 今日概览</h3>
        <div style="display: flex; flex-direction: column; gap: 0.8rem;">
          <div style="display: flex; justify-content: space-between;">
            <span>待办:</span>
            <span style="font-weight: 700;">{{ pendingCount }}</span>
          </div>
          <div style="display: flex; justify-content: space-between;">
            <span>已完成:</span>
            <span style="font-weight: 700; color: var(--success-color);">{{ completedCount }}</span>
          </div>
          <div style="display: flex; justify-content: space-between;">
            <span>已逾期:</span>
            <span style="font-weight: 700; color: var(--error-color);">{{ overdueCount }}</span>
          </div>
        </div>
      </div>
    </aside>

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
                <span class="trash-meta">原分类: {{ getCategoryText(task.category) }}</span>
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
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '../stores/userStore'
import { useTaskStore } from '../stores/taskStore'

const router = useRouter()
const userStore = useUserStore()
const taskStore = useTaskStore()

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
const clockInterval = ref(null)
const showTrash = ref(false)
const timeNow = ref(new Date())

// 筛选选项
const filters = [
  { label: '全部任务', value: 'all' },
  { label: '未完成', value: 'pending' },
  { label: '已完成', value: 'completed' }
]

// 星期几选项
const weekdays = ['日', '一', '二', '三', '四', '五', '六']

// 每日灵感
const mottos = [
  "种一棵树最好的时间是十年前，其次是现在。",
  "不积跬步，无以至千里。",
  "越努力，越幸运。",
  "每一个不曾起舞的日子，都是对生命的辜负。",
  "成功不是终点，失败也非末日。"
]
const randomMotto = mottos[Math.floor(Math.random() * mottos.length)]

// 时间显示
const currentTime = computed(() => {
  return timeNow.value.toLocaleTimeString('zh-CN', { hour12: false })
})
const currentDay = computed(() => {
  return timeNow.value.toLocaleDateString('zh-CN', { weekday: 'long', month: 'long', day: 'numeric' })
})

// 统计数据
const completionPercentage = computed(() => {
  const total = taskStore.tasks.length
  if (total === 0) return 0
  const completed = taskStore.tasks.filter(t => t.status === TaskStatus.COMPLETED).length
  return Math.round((completed / total) * 100)
})

const pendingCount = computed(() => taskStore.tasks.filter(t => t.status !== TaskStatus.COMPLETED).length)
const completedCount = computed(() => taskStore.tasks.filter(t => t.status === TaskStatus.COMPLETED).length)
const overdueCount = computed(() => taskStore.tasks.filter(t => t.status === TaskStatus.OVERDUE).length)

// 计算属性：筛选后的任务
const filteredTasks = computed(() => {
  return taskStore.getFilteredTasks(currentFilter.value, currentCategoryFilter.value, {
    start: startDate.value,
    end: endDate.value
  })
})

// 方法：设置筛选条件
const setFilter = (filter) => {
  currentFilter.value = filter
}

// 方法：清除时间筛选
const clearDateFilter = () => {
  startDate.value = ''
  endDate.value = ''
}

// 方法：筛选任务
const filterTasks = () => {
  // 筛选逻辑已在taskStore中实现
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

// 方法：退出登录
const handleLogout = () => {
  userStore.logout()
  router.push('/')
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

// 方法：格式化日期时间
const formatDateTime = (dateStr) => {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  return date.toLocaleString('zh-CN', {
    month: 'numeric',
    day: 'numeric',
    hour: '2-digit'
  }) + '时'
}

// 方法：获取倒计时
const getCountdown = (task) => {
  const now = new Date()
  const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59)
  const remainingTime = endOfDay - now
  
  if (remainingTime > 0) {
    const hours = Math.floor(remainingTime / (1000 * 60 * 60))
    const minutes = Math.floor((remainingTime % (1000 * 60 * 60)) / (1000 * 60))
    const seconds = Math.floor((remainingTime % (1000 * 60)) / 1000)
    return `剩余: ${hours}h ${minutes}m`
  } else {
    return '已过期'
  }
}

// 方法：显示通知
const emit = defineEmits(['notify'])
const showNotification = (message, type = 'info') => {
  emit('notify', { message, type })
}

// 生命周期钩子：组件挂载时
onMounted(() => {
  taskStore.loadTasks()
  
  countdownInterval.value = setInterval(() => {
    taskStore.checkOverdueTasks()
  }, 1000)

  clockInterval.value = setInterval(() => {
    timeNow.value = new Date()
  }, 1000)
})

// 生命周期钩子：组件卸载时
onUnmounted(() => {
  if (countdownInterval.value) clearInterval(countdownInterval.value)
  if (clockInterval.value) clearInterval(clockInterval.value)
})
</script>

<style scoped>
.interaction-area {
  background: rgba(255, 255, 255, 0.2);
  border-radius: 16px;
  padding: 1.2rem;
  margin-bottom: 1.5rem;
  border: 1px solid rgba(255, 255, 255, 0.3);
}

.interaction-area {
  background: rgba(255, 255, 255, 0.2);
  border-radius: 16px;
  padding: 1.2rem;
  margin-bottom: 1.5rem;
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.05);
}

.filter-toolbar {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  padding: 0 0 1rem 0;
  margin-bottom: 1rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
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
  font-size: 0.75rem;
  color: var(--text-dark);
  width: 135px;
  outline: none;
}

.range-sep {
  color: var(--text-light);
  font-size: 0.8rem;
}

.clear-icon {
  background: var(--error-color);
  color: white;
  border: none;
  border-radius: 50%;
  width: 18px;
  height: 18px;
  line-height: 16px;
  text-align: center;
  cursor: pointer;
  font-size: 12px;
  margin-left: 0.3rem;
  transition: transform 0.2s;
}

.clear-icon:hover {
  transform: scale(1.1);
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
  font-size: 0.75rem;
  color: var(--text-light);
  background: rgba(0, 0, 0, 0.05);
  padding: 0.1rem 0.4rem;
  border-radius: 4px;
  margin-right: 0.3rem;
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

.task-checkbox {
  margin-right: 1rem;
  transform: scale(1.2);
  cursor: pointer;
}

.task-content {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.task-title {
  font-size: 1.1rem;
  font-weight: 600;
}

.task-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  align-items: center;
  margin-top: 0.3rem;
}

.header-actions {
  display: flex;
  gap: 0.8rem;
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
</style>