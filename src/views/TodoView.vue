<template>
  <div class="todo-layout">
    <!-- 核心内容区 -->
    <main class="main-content glass-card">
      <!-- 顶部标题栏 -->
      <header class="header">
        <div class="user-info">
          <h1>My Tasks</h1>
        </div>
        <div class="header-actions">
          <button class="btn btn-info" @click="showTrash = true">回收站 ({{ taskStore.deletedTasks.length }})</button>
          <button class="btn btn-danger" @click="handleLogout">退出登录</button>
        </div>
      </header>

      <!-- 统计+筛选+添加 - 融合区域 -->
      <section class="dashboard-area">
        <!-- 第一行：统计数据（可点击筛选） + 添加按钮 -->
        <div class="stats-all-in-one">
          <div class="progress-ring-mini" @click="currentFilter = 'all'" :class="{ active: currentFilter === 'all' }">
            <div class="progress-value-mini">{{ completionPercentage }}%</div>
          </div>
          <div class="stat-item-inline clickable" @click="currentFilter = 'pending'" :class="{ active: currentFilter === 'pending' }">
            <span class="stat-count-mini">{{ pendingCount }}</span>
            <span class="stat-label-mini">待办</span>
          </div>
          <div class="stat-item-inline clickable" @click="currentFilter = 'completed'" :class="{ active: currentFilter === 'completed' }">
            <span class="stat-count-mini success">{{ completedCount }}</span>
            <span class="stat-label-mini">已完成</span>
          </div>
          <div class="stat-item-inline clickable" @click="currentFilter = 'overdue'" :class="{ active: currentFilter === 'overdue' }">
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
              @click="currentCategoryFilter = cat.value"
            >
              {{ cat.label }}
            </button>
          </div>
          <div class="time-filter-compact">
            <input type="datetime-local" v-model="startDate" step="3600" class="mini-date" title="开始">
            <span class="range-sep">-</span>
            <input type="datetime-local" v-model="endDate" step="3600" class="mini-date" title="结束">
            <button v-if="startDate || endDate" class="clear-icon" @click="clearDateFilter">×</button>
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
              <span class="task-title" @click="openEditModal(task)" title="点击编辑详情">{{ task.text }}</span>
              <div v-if="task.description" class="task-description">{{ task.description }}</div>
              <div class="task-meta">
                <span class="task-time">🕒 {{ formatDateTime(task.created_at) }}</span>
                <span class="task-type badge">{{ getTaskTypeText(task) }}</span>
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

const router = useRouter()
const taskStore = useOfflineTaskStore()

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
const editingTask = ref(null)
const editDescription = ref('')
const editText = ref('')
const showAddForm = ref(true)

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
}

.main-content {
  width: 100%;
  max-width: 100%;
  flex: none;
  padding: 1rem;
}

.dashboard-area {
  background: rgba(255, 255, 255, 0.2);
  border-radius: 12px;
  padding: 0.8rem;
  margin-bottom: 1rem;
  border: 1px solid rgba(255, 255, 255, 0.3);
}

.stats-all-in-one {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  justify-content: space-between;
  margin-bottom: 0.8rem;
}

.stat-item-inline {
  display: flex;
  align-items: center;
  gap: 0.3rem;
}

.stat-item-inline.clickable,
.progress-ring-mini {
  cursor: pointer;
  transition: all 0.3s;
  padding: 0.3rem 0.5rem;
  border-radius: 8px;
}

.stat-item-inline.clickable:hover,
.progress-ring-mini:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: scale(1.05);
}

.stat-item-inline.active,
.progress-ring-mini.active {
  background: rgba(255, 255, 255, 0.5);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

/* 第二行：分类和时间筛选 */
.filter-row {
  display: flex;
  gap: 0.8rem;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
}

.category-filters {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.category-btn {
  padding: 0.4rem 0.8rem;
  border-radius: 16px;
  border: 1px solid rgba(255, 255, 255, 0.4);
  background: rgba(255, 255, 255, 0.3);
  color: var(--text-dark);
  font-size: 0.85rem;
  cursor: pointer;
  transition: all 0.3s;
  white-space: nowrap;
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
  background: rgba(255, 255, 255, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 16px;
  padding: 0.3rem 0.6rem;
  gap: 0.3rem;
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
}

.progress-value-mini {
  font-size: 0.85rem;
  font-weight: 800;
  color: var(--primary-color);
}

.stats-vertical {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  flex: 1;
}

.stat-item-mini {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.stat-count-mini {
  font-size: 1rem;
  font-weight: 700;
  color: var(--text-dark);
  min-width: 20px;
}

.stat-count-mini.success { color: var(--success-color); }
.stat-count-mini.danger { color: var(--error-color); }

.stat-label-mini {
  font-size: 0.75rem;
  color: var(--text-light);
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
  cursor: pointer;
  transition: color 0.2s;
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
  gap: 0.5rem;
  margin-top: 0.8rem;
  padding-top: 0.8rem;
  border-top: 1px solid rgba(255, 255, 255, 0.3);
  flex-wrap: wrap;
  align-items: center;
}

.input-inline {
  flex: 1;
  min-width: 120px;
  padding: 0.5rem;
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.6);
  font-size: 0.85rem;
}

.input-inline:focus {
  outline: none;
  background: white;
  border-color: var(--primary-color);
}

.select-inline {
  padding: 0.5rem;
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.6);
  font-size: 0.85rem;
  cursor: pointer;
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
  font-size: 1.2rem;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
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
</style>