<template>
  <div class="todo-layout">
    <!-- 下拉刷新指示器 -->
    <div class="pull-refresh-indicator" :class="{ active: pullRefreshState !== 'idle' }">
      <div class="refresh-icon" :class="pullRefreshState">
        {{ pullRefreshState === 'pulling' ? '↓' : pullRefreshState === 'ready' ? '↑' : '⟳' }}
      </div>
      <span class="refresh-text">
        {{ pullRefreshState === 'pulling' ? '下拉刷新' : pullRefreshState === 'ready' ? '松开刷新' : '刷新中...' }}
      </span>
    </div>

    <!-- 核心内容区 -->
    <main class="main-content glass-card" ref="mainContent">
      <!-- 顶部标题栏 -->
      <header class="header">
        <div class="user-info">
          <h1>{{ taskTitle }}</h1>
        </div>
        <div class="header-actions">
          <button class="btn btn-info" @click="showTrash = true">回收站 :{{ taskStore.deletedTasks.length }}</button>
          <button class="btn btn-danger" @click="handleLogout">退出登录</button>
          <button class="btn-avatar" @click="showProfile = true" title="个人主页">
            <div class="avatar-mini">{{ currentUsername ? currentUsername.charAt(0).toUpperCase() : 'U' }}</div>
          </button>
        </div>
      </header>

      <!-- 统计+筛选+添加 - 融合区域 v1.2优化 -->
      <section class="dashboard-area">
        <!-- 第一行：全局统计 + 分类筛选 -->
        <div class="stats-all-in-one">
          <!-- 占比 -->
          <div class="stat-row">
            <span class="stat-label-mini">占比</span>
            <span class="stat-count-plain">:{{ completionPercentage }}%</span>
          </div>

          <!-- 全部 -->
          <div class="stat-row clickable" @click="setFilter('all')" :class="{ active: currentFilter === 'all' }">
            <span class="stat-label-mini">全部</span>
            <span class="stat-count">:{{ baseFilteredTasks.length }}</span>
          </div>

          <!-- 分类统计 -->
          <div 
            v-for="cat in categories" 
            :key="cat.value"
            class="stat-row clickable"
            :class="{ active: currentCategoryFilter === cat.value }"
            @click="setCategoryFilter(cat.value)"
          >
            <span class="stat-label-mini">{{ cat.label }}</span>
            <span class="stat-count">:{{ getCategoryCount(cat.value) }}</span>
          </div>
          
          <button class="add-btn-text" @click="showAddForm = !showAddForm">{{ showAddForm ? '收起' : '添加' }}</button>
        </div>

        <!-- 第二行：状态筛选和时间筛选 (合并为一行) -->
        <div class="filter-row-unified">
          <div class="stat-row clickable" @click="setFilter('pending')" :class="{ active: currentFilter === 'pending' }">
            <span class="stat-label-mini">待办</span>
            <span class="stat-count">:{{ pendingCount }}</span>
          </div>
          <div class="stat-row clickable" @click="setFilter('completed')" :class="{ active: currentFilter === 'completed' }">
            <span class="stat-label-mini">已完成</span>
            <span class="stat-count success">:{{ completedCount }}</span>
          </div>
          <div class="stat-row clickable" @click="setFilter('overdue')" :class="{ active: currentFilter === 'overdue' }">
            <span class="stat-label-mini">已逾期</span>
            <span class="stat-count danger">:{{ overdueCount }}</span>
          </div>
          
          <!-- 二合一日期区间选择器 (合并到状态行) -->
          <div class="date-range-display">
            <div class="range-values">
              <div 
                class="date-clickable-area" 
                :class="{ 'placeholder': !startDate }" 
                @click="showDatePicker('start')"
              >
                {{ startDate ? formatDisplayDate(startDate) : '查询日期起' }}
              </div>
              <span class="range-sep">-</span>
              <div 
                class="date-clickable-area" 
                :class="{ 'placeholder': !endDate }" 
                @click="showDatePicker('end')"
              >
                {{ endDate ? formatDisplayDate(endDate) : '查询日期止' }}
              </div>
            </div>
            <button v-if="startDate || endDate" class="clear-date-icon" @click.stop="clearDateFilter">✕</button>
          </div>
          <input ref="hiddenStartDate" type="date" style="display:none" @change="handleStartDateChange">
          <input ref="hiddenEndDate" type="date" style="display:none" @change="handleEndDateChange">
        </div>

        <!-- 第三行：优先级筛选和关键字搜索 -->
        <div class="filter-row-unified">
          <div class="stat-row clickable" @click="setPriorityFilter('all')" :class="{ active: currentPriorityFilter === 'all' }">
            <span class="stat-label-mini">全部优先级</span>
          </div>
          <div class="stat-row clickable" @click="setPriorityFilter('high')" :class="{ active: currentPriorityFilter === 'high' }">
            <span class="stat-label-mini">⚡高</span>
            <span class="stat-count danger">:{{ highPriorityCount }}</span>
          </div>
          <div class="stat-row clickable" @click="setPriorityFilter('medium')" :class="{ active: currentPriorityFilter === 'medium' }">
            <span class="stat-label-mini">⚡中</span>
            <span class="stat-count">:{{ mediumPriorityCount }}</span>
          </div>
          <div class="stat-row clickable" @click="setPriorityFilter('low')" :class="{ active: currentPriorityFilter === 'low' }">
            <span class="stat-label-mini">⚡低</span>
            <span class="stat-count success">:{{ lowPriorityCount }}</span>
          </div>
          
          <!-- 关键字搜索 -->
          <div class="search-box">
            <input 
              v-model="searchKeyword" 
              type="text" 
              class="search-input" 
              placeholder="🔍 搜索任务..."
              @input="handleSearch"
            >
            <button v-if="searchKeyword" class="clear-search" @click="clearSearch">✕</button>
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
          <select v-model="newTaskType" class="select-inline" @change="handleTaskTypeChange">
            <option value="today">今天</option>
            <option value="tomorrow">明天</option>
            <option value="this_week">本周内</option>
            <option value="custom_date">指定日期</option>
            <option value="daily">每天重复</option>
            <option value="weekday">工作日重复</option>
            <option value="weekly">每周重复</option>
          </select>
          <div 
            v-if="newTaskType === 'custom_date'" 
            class="date-picker-inline"
            :class="{ 'placeholder': !customDateTime }"
            @click="showCustomDateTimePicker"
          >
            {{ customDateTime ? formatDisplayDateTime(customDateTime) : '选择日期时间' }}
          </div>
          <input ref="hiddenCustomDateTime" type="datetime-local" style="display:none" :min="getTodayDateTime()" @change="handleCustomDateTimeChange">
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
                <span class="task-time" title="添加时间">📝 {{ formatDateTime(task.created_at) }}</span>
                <span class="task-deadline" :class="getDeadlineClass(task)" title="计划完成时间">⏰ {{ getDeadlineText(task) }}</span>
                <span class="task-type badge">{{ getTaskTypeText(task) }}</span>
                <span class="badge badge-icon" :class="`priority-${task.priority}`" :title="`优先级: ${getPriorityText(task.priority)}`">
                  ⚡ {{ getPriorityText(task.priority) }}
                </span>
                <span class="badge badge-icon" :class="`category-${task.category}`" :title="`分类: ${getCategoryText(task.category)}`">
                  🏷️ {{ getCategoryText(task.category) }}
                </span>
                <span class="badge badge-pomodoro" :class="`pomodoro-${task.priority}`" :title="`预估番茄数: ${getPomodoroCount(task.priority)}个`">
                  <span v-for="n in getPomodoroCount(task.priority)" :key="n">🍅</span>
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

        <!-- 页脚版权信息 -->
        <footer class="app-footer">
          <div class="footer-content">
            <p class="footer-version">TO-DO App v1.4.0</p>
            <p class="footer-copyright">© 2026 TO-DO App. All rights reserved.</p>
            <p class="footer-license">
              MIT License | 离线存储，数据安全 | 
              <span class="privacy-link" @click="showPrivacyPolicy = true">隐私政策</span>
            </p>
          </div>
        </footer>
      </div>
    </main>

    <!-- 隐私政策模态框 -->
    <div v-if="showPrivacyPolicy" class="modal-overlay" @click.self="showPrivacyPolicy = false">
      <div class="modal-content privacy-modal">
        <div class="modal-header">
          <h3>🔒 隐私政策</h3>
          <button class="close-btn" @click="showPrivacyPolicy = false">&times;</button>
        </div>
        <div class="modal-body privacy-content">
          <p class="update-date"><strong>更新日期：2026年2月19日</strong></p>
          
          <h4>1. 概述</h4>
          <p>TODO App（以下简称"本应用"）尊重并保护用户隐私。本隐私政策说明我们如何收集、使用和保护您的信息。</p>
          
          <div class="highlight-box">
            <strong>核心承诺：</strong>本应用完全离线运行，<strong>不收集任何用户数据</strong>，所有数据仅存储在您的设备本地。
          </div>
          
          <h4>2. 信息收集</h4>
          <p>本应用完全离线运行，<strong>不收集任何用户数据</strong>。具体包括：</p>
          <ul>
            <li>不收集个人身份信息（姓名、邮箱、电话等）</li>
            <li>不收集设备信息</li>
            <li>不收集位置信息</li>
            <li>不收集使用行为数据</li>
            <li>不使用任何分析工具或统计服务</li>
          </ul>
          
          <h4>3. 数据存储</h4>
          <p>所有任务数据存储在您的设备本地存储中：</p>
          <ul>
            <li>✓ 数据存储在设备本地</li>
            <li>✓ 数据不会上传到任何服务器</li>
            <li>✓ 数据不会与第三方共享</li>
            <li>✓ 卸载应用会删除所有本地数据</li>
            <li>✓ 您完全控制自己的数据</li>
          </ul>
          
          <h4>4. 权限说明</h4>
          <p>本应用申请的权限及用途：</p>
          <ul>
            <li><strong>存储权限</strong>：用于保存任务数据到设备本地，以及导入导出Excel文件</li>
            <li><strong>通知权限</strong>：用于任务提醒功能（可选，用户可在系统设置中关闭）</li>
          </ul>
          
          <h4>5. 数据安全</h4>
          <div class="highlight-box">
            <p><strong>本应用不联网，数据完全在本地，不存在数据泄露风险。</strong></p>
          </div>
          
          <h4>6. 第三方服务</h4>
          <p>本应用<strong>不使用任何第三方服务或 SDK</strong>。</p>
          
          <h4>7. 联系我们</h4>
          <div class="contact-box">
            <p>如对本隐私政策有任何疑问，请联系：</p>
            <p><strong>📧 邮箱：</strong>17858441076@163.com</p>
            <p><strong>📞 电话：</strong>17858441076</p>
          </div>
        </div>
      </div>
    </div>

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
              <h2>
                {{ editingUsername ? '' : currentUsername }}
                <input 
                  v-if="editingUsername"
                  v-model="newUsername"
                  class="username-edit-input"
                  @blur="saveUsername"
                  @keyup.enter="saveUsername"
                  ref="usernameInput"
                >
                <span class="edit-icon" @click="startEditUsername">✏️</span>
              </h2>
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

          <!-- 番茄统计入口 -->
          <div class="pomodoro-entry" @click="showPomodoroStats = true">
            <div class="entry-icon">🍅</div>
            <div class="entry-content">
              <div class="entry-title">番茄钟统计</div>
              <div class="entry-summary">
                已获得 {{ earnedPomodoros }} 个 | 净获得 {{ totalPomodoros }} 个
              </div>
            </div>
            <div class="entry-arrow">›</div>
          </div>

          <!-- 修改密码 -->
          <div class="profile-form">
            <div class="form-group">
              <label>修改密码</label>
              <div class="password-row">
                <input 
                  v-model="oldPassword" 
                  type="password" 
                  class="input" 
                  placeholder="当前密码"
                >
                <input 
                  v-model="newPassword" 
                  type="password" 
                  class="input" 
                  placeholder="新密码"
                >
                <button class="btn btn-primary btn-compact" @click="updatePassword">保存</button>
              </div>
            </div>
          </div>

          <!-- 绑定手机号 -->
          <div class="profile-form">
            <div class="form-group">
              <label>📱 绑定手机号</label>
              <div v-if="userProfileInfo.boundPhone" class="bound-phone-info">
                <span class="phone-display">{{ userProfileInfo.boundPhone }}</span>
                <button class="btn btn-secondary btn-compact" @click="unbindPhone">解绑</button>
              </div>
              <div v-else class="bind-phone-row">
                <input 
                  v-model="bindPhoneNumber" 
                  type="tel" 
                  class="input" 
                  placeholder="手机号"
                  maxlength="11"
                >
                <input 
                  v-model="bindVerificationCode" 
                  type="text" 
                  class="input" 
                  placeholder="验证码"
                  maxlength="6"
                >
                <button 
                  class="btn btn-secondary btn-compact" 
                  :disabled="bindCountdown > 0"
                  @click="sendBindSMS"
                >
                  {{ bindCountdown > 0 ? `${bindCountdown}s` : '获取' }}
                </button>
                <button class="btn btn-primary btn-compact" @click="confirmBindPhone">绑定</button>
              </div>
              <p class="bind-hint">绑定后可使用手机号+验证码登录此账号</p>
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

    <!-- 番茄统计详情弹窗 -->
    <div v-if="showPomodoroStats" class="modal-overlay" @click.self="showPomodoroStats = false">
      <div class="modal-content glass-card" style="background: white; max-width: 600px;">
        <div class="modal-header">
          <h3>🍅 番茄钟统计</h3>
          <button class="close-btn" @click="showPomodoroStats = false">&times;</button>
        </div>
        <div class="modal-body">
          <!-- 总览 -->
          <div class="pomodoro-overview">
            <div class="overview-item earned">
              <div class="overview-icon">✅</div>
              <div class="overview-value">{{ earnedPomodoros }}</div>
              <div class="overview-label">已获得</div>
            </div>
            <div class="overview-item pending">
              <div class="overview-icon">⏳</div>
              <div class="overview-value">{{ pendingPomodoros }}</div>
              <div class="overview-label">待获得</div>
            </div>
            <div class="overview-item lost">
              <div class="overview-icon">❌</div>
              <div class="overview-value">{{ lostPomodoros }}</div>
              <div class="overview-label">逾期扣除</div>
            </div>
            <div class="overview-item total">
              <div class="overview-icon">🏆</div>
              <div class="overview-value">{{ totalPomodoros }}</div>
              <div class="overview-label">净获得</div>
            </div>
          </div>

          <!-- 等级徽章 -->
          <div class="level-badge">
            <div class="level-badge-icon">{{ getLevelBadge().icon }}</div>
            <div class="badge-info">
              <div class="badge-title">{{ getLevelBadge().title }}</div>
              <div class="badge-desc">累计获得 {{ earnedPomodoros }} 个番茄</div>
            </div>
          </div>

          <!-- 近7天趋势 -->
          <div class="stats-section">
            <h4 class="section-title">📈 近7天趋势</h4>
            <div class="trend-chart">
              <div v-for="(day, index) in getLast7DaysTrend()" :key="index" class="trend-bar-wrapper">
                <div class="trend-bar" :style="{ height: (day.count / getMaxDailyInWeek() * 100) + '%' }">
                  <span class="trend-value">{{ day.count }}</span>
                </div>
                <div class="trend-label">{{ day.label }}</div>
              </div>
            </div>
          </div>

          <!-- 时间维度统计 -->
          <div class="stats-section">
            <h4 class="section-title">📅 时间统计</h4>
            <div class="stats-grid">
              <div class="stats-card time-today">
                <div class="stats-icon">☀️</div>
                <div class="stats-info">
                  <div class="stats-value">{{ getPomodorosByTime('today') }}</div>
                  <div class="stats-label">今日</div>
                </div>
              </div>
              <div class="stats-card time-week">
                <div class="stats-icon">📊</div>
                <div class="stats-info">
                  <div class="stats-value">{{ getPomodorosByTime('week') }}</div>
                  <div class="stats-label">本周</div>
                </div>
              </div>
              <div class="stats-card time-month">
                <div class="stats-icon">📈</div>
                <div class="stats-info">
                  <div class="stats-value">{{ getPomodorosByTime('month') }}</div>
                  <div class="stats-label">本月</div>
                </div>
              </div>
            </div>
          </div>

          <!-- 分类占比 -->
          <div class="stats-section">
            <h4 class="section-title">📊 分类占比</h4>
            <div class="category-bars">
              <div class="category-bar-item">
                <div class="category-bar-header">
                  <span>💼 工作</span>
                  <span class="category-bar-value">{{ getPomodorosByCategory('work') }} ({{ getCategoryPercent('work') }}%)</span>
                </div>
                <div class="category-bar-bg">
                  <div class="category-bar-fill work" :style="{ width: getCategoryPercent('work') + '%' }"></div>
                </div>
              </div>
              <div class="category-bar-item">
                <div class="category-bar-header">
                  <span>📚 学习</span>
                  <span class="category-bar-value">{{ getPomodorosByCategory('study') }} ({{ getCategoryPercent('study') }}%)</span>
                </div>
                <div class="category-bar-bg">
                  <div class="category-bar-fill study" :style="{ width: getCategoryPercent('study') + '%' }"></div>
                </div>
              </div>
              <div class="category-bar-item">
                <div class="category-bar-header">
                  <span>🏠 生活</span>
                  <span class="category-bar-value">{{ getPomodorosByCategory('life') }} ({{ getCategoryPercent('life') }}%)</span>
                </div>
                <div class="category-bar-bg">
                  <div class="category-bar-fill life" :style="{ width: getCategoryPercent('life') + '%' }"></div>
                </div>
              </div>
            </div>
          </div>

          <!-- 按分类统计 -->
          <div class="stats-section">
            <h4 class="section-title">🏷️ 分类明细</h4>
            <div class="stats-grid">
              <div class="stats-card">
                <div class="stats-icon">💼</div>
                <div class="stats-info">
                  <div class="stats-value">{{ getPomodorosByCategory('work') }}</div>
                  <div class="stats-label">工作</div>
                </div>
              </div>
              <div class="stats-card">
                <div class="stats-icon">📚</div>
                <div class="stats-info">
                  <div class="stats-value">{{ getPomodorosByCategory('study') }}</div>
                  <div class="stats-label">学习</div>
                </div>
              </div>
              <div class="stats-card">
                <div class="stats-icon">🏠</div>
                <div class="stats-info">
                  <div class="stats-value">{{ getPomodorosByCategory('life') }}</div>
                  <div class="stats-label">生活</div>
                </div>
              </div>
            </div>
          </div>

          <!-- 按优先级统计 -->
          <div class="stats-section">
            <h4 class="section-title">⚡ 按优先级统计</h4>
            <div class="stats-grid">
              <div class="stats-card priority-high">
                <div class="stats-icon">🔴</div>
                <div class="stats-info">
                  <div class="stats-value">{{ getPomodorosByPriority('high') }}</div>
                  <div class="stats-label">高优先级</div>
                </div>
              </div>
              <div class="stats-card priority-medium">
                <div class="stats-icon">🟠</div>
                <div class="stats-info">
                  <div class="stats-value">{{ getPomodorosByPriority('medium') }}</div>
                  <div class="stats-label">中优先级</div>
                </div>
              </div>
              <div class="stats-card priority-low">
                <div class="stats-icon">🔵</div>
                <div class="stats-info">
                  <div class="stats-value">{{ getPomodorosByPriority('low') }}</div>
                  <div class="stats-label">低优先级</div>
                </div>
              </div>
            </div>
          </div>

          <!-- 成就统计 -->
          <div class="stats-section">
            <h4 class="section-title">🎯 成就统计</h4>
            <div class="achievement-grid">
              <div class="achievement-card">
                <div class="achievement-icon">🔥</div>
                <div class="achievement-info">
                  <div class="achievement-value">{{ getConsecutiveDays() }}</div>
                  <div class="achievement-label">连续打卡</div>
                </div>
              </div>
              <div class="achievement-card">
                <div class="achievement-icon">⭐</div>
                <div class="achievement-info">
                  <div class="achievement-value">{{ getMaxDailyPomodoros() }}</div>
                  <div class="achievement-label">单日最高</div>
                </div>
              </div>
              <div class="achievement-card">
                <div class="achievement-icon">📊</div>
                <div class="achievement-info">
                  <div class="achievement-value">{{ getCompletionRate() }}%</div>
                  <div class="achievement-label">完成率</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 任务详情编辑模态框 -->
    <div v-if="editingTask" class="modal-overlay" @click.self="editingTask = null">
      <div class="modal-content glass-card" style="background: white; max-width: 500px;">
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
              rows="4"
            ></textarea>
          </div>
          <div class="edit-field">
            <label>任务分类</label>
            <select v-model="editCategory" class="input">
              <option value="work">💼 工作</option>
              <option value="study">📚 学习</option>
              <option value="life">🏠 生活</option>
            </select>
          </div>
          <div class="edit-field">
            <label>优先级</label>
            <select v-model="editPriority" class="input">
              <option value="high">高</option>
              <option value="medium">中</option>
              <option value="low">低</option>
            </select>
          </div>
          <div class="edit-field">
            <label>任务类型</label>
            <select v-model="editType" class="input" @change="handleEditTypeChange">
              <option value="today">今天</option>
              <option value="tomorrow">明天</option>
              <option value="this_week">本周内</option>
              <option value="custom_date">指定日期</option>
              <option value="daily">每天重复</option>
              <option value="weekday">工作日重复</option>
              <option value="weekly">每周重复</option>
            </select>
          </div>
          <div v-if="editType === 'custom_date'" class="edit-field">
            <label>指定日期时间</label>
            <input v-model="editCustomDateTime" type="datetime-local" class="input" :min="getTodayDateTime()">
          </div>
          <div v-if="editType === 'weekly'" class="edit-field">
            <label>重复周期</label>
            <div class="weekday-selector">
              <label v-for="(day, index) in weekdays" :key="index" class="weekday-label">
                <input type="checkbox" :value="index" v-model="editWeekdays">
                <span>{{ day }}</span>
              </label>
            </div>
          </div>
          <div class="modal-actions">
            <button class="btn btn-secondary" @click="editingTask = null">取消</button>
            <button class="btn btn-primary" @click="saveTaskEdit">保存更改</button>
          </div>
        </div>
      </div>
    </div>

    <!-- 底部抽屉 - 添加任务 -->
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { useOfflineTaskStore } from '../stores/offlineTaskStore'
import { useOfflineUserStore } from '../stores/offlineUserStore'
import { Preferences } from '@capacitor/preferences'
import { Filesystem, Directory } from '@capacitor/filesystem'
import { LocalNotifications } from '@capacitor/local-notifications'
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
const customDateTime = ref('')
const newTaskCategory = ref('work')
const newTaskPriority = ref('medium')
const selectedWeekdays = ref([])
const currentFilter = ref('all')
const currentCategoryFilter = ref('all')
const currentPriorityFilter = ref('all')
const searchKeyword = ref('')
const startDate = ref('')
const endDate = ref('')
const countdownInterval = ref(null)
const showTrash = ref(false)
const showProfile = ref(false)
const showPomodoroStats = ref(false)
const showPrivacyPolicy = ref(false)
const editingTask = ref(null)
const editDescription = ref('')
const editText = ref('')
const editCategory = ref('work')
const editPriority = ref('medium')
const editType = ref('today')
const editCustomDateTime = ref('')
const editWeekdays = ref([])
const showAddForm = ref(true)
const currentPage = ref(1)
const pageSize = 6
const fileInput = ref(null)
const mainContent = ref(null)

// 下拉刷新相关
const pullRefreshState = ref('idle') // idle, pulling, ready, refreshing
let startY = 0
let currentY = 0
const pullThreshold = 80

// 个人主页相关
const newUsername = ref('')
const oldPassword = ref('')
const newPassword = ref('')
const userProfileInfo = ref({
  registerTime: null,
  lastLoginTime: null,
  boundPhone: null
})

// 绑定手机号相关
const bindPhoneNumber = ref('')
const bindVerificationCode = ref('')
const bindGeneratedCode = ref('')
const bindCountdown = ref(0)
let bindTimer = null

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
  { label: '工作', value: 'work', icon: '💼' },
  { label: '学习', value: 'study', icon: '📚' },
  { label: '生活', value: 'life', icon: '🏠' }
]

// 星期几选项
const weekdays = ['日', '一', '二', '三', '四', '五', '六']

// 提醒记录（防止重复提醒）
const notifiedTasks = new Set() // 存储已提醒的任务ID

// 计算属性：按分类和时间筛选的任务（不按状态筛选，用于统计）
const baseFilteredTasks = computed(() => {
  return taskStore.getFilteredTasks('all', currentCategoryFilter.value, {
    start: startDate.value,
    end: endDate.value
  })
})

// 计算属性：完全筛选后的任务（包括状态筛选，用于显示）
const filteredTasks = computed(() => {
  let tasks = taskStore.getFilteredTasks(currentFilter.value, currentCategoryFilter.value, {
    start: startDate.value,
    end: endDate.value
  })
  
  // 优先级筛选
  if (currentPriorityFilter.value !== 'all') {
    tasks = tasks.filter(t => t.priority === currentPriorityFilter.value)
  }
  
  // 关键字搜索（模糊匹配任务名称和描述）
  if (searchKeyword.value.trim()) {
    const keyword = searchKeyword.value.toLowerCase().trim()
    tasks = tasks.filter(t => 
      t.text.toLowerCase().includes(keyword) || 
      (t.description && t.description.toLowerCase().includes(keyword))
    )
  }
  
  return tasks
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

// 优先级统计（基于baseFilteredTasks）
const highPriorityCount = computed(() => baseFilteredTasks.value.filter(t => t.priority === 'high').length)
const mediumPriorityCount = computed(() => baseFilteredTasks.value.filter(t => t.priority === 'medium').length)
const lowPriorityCount = computed(() => baseFilteredTasks.value.filter(t => t.priority === 'low').length)

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

// 番茄统计
const earnedPomodoros = computed(() => {
  // 已完成任务获得的番茄数
  return taskStore.tasks
    .filter(t => t.status === TaskStatus.COMPLETED)
    .reduce((sum, t) => sum + getPomodoroCount(t.priority), 0)
})

const pendingPomodoros = computed(() => {
  // 待完成任务可获得的番茄数
  return taskStore.tasks
    .filter(t => t.status === TaskStatus.PENDING)
    .reduce((sum, t) => sum + getPomodoroCount(t.priority), 0)
})

const lostPomodoros = computed(() => {
  // 逾期任务扣除的番茄数
  return taskStore.tasks
    .filter(t => t.status === TaskStatus.OVERDUE)
    .reduce((sum, t) => sum + getPomodoroCount(t.priority), 0)
})

const totalPomodoros = computed(() => {
  // 净获得番茄数 = 已获得 - 逾期扣除
  return earnedPomodoros.value - lostPomodoros.value
})

// 按分类统计番茄数
const getPomodorosByCategory = (category) => {
  return taskStore.tasks
    .filter(t => t.category === category && t.status === TaskStatus.COMPLETED)
    .reduce((sum, t) => sum + getPomodoroCount(t.priority), 0)
}

// 按优先级统计番茄数
const getPomodorosByPriority = (priority) => {
  return taskStore.tasks
    .filter(t => t.priority === priority && t.status === TaskStatus.COMPLETED)
    .reduce((sum, t) => sum + getPomodoroCount(t.priority), 0)
}

// 按时间统计番茄数
const getPomodorosByTime = (period) => {
  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  
  return taskStore.tasks
    .filter(t => {
      if (t.status !== TaskStatus.COMPLETED) return false
      const completedDate = new Date(t.created_at)
      
      if (period === 'today') {
        return completedDate >= today
      } else if (period === 'week') {
        const weekStart = new Date(today)
        weekStart.setDate(today.getDate() - today.getDay())
        return completedDate >= weekStart
      } else if (period === 'month') {
        const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)
        return completedDate >= monthStart
      }
      return false
    })
    .reduce((sum, t) => sum + getPomodoroCount(t.priority), 0)
}

// 连续打卡天数
const getConsecutiveDays = () => {
  const completedTasks = taskStore.tasks
    .filter(t => t.status === TaskStatus.COMPLETED)
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
  
  if (completedTasks.length === 0) return 0
  
  let consecutive = 1
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  
  let currentDate = new Date(completedTasks[0].created_at)
  currentDate.setHours(0, 0, 0, 0)
  
  // 如果最近完成的任务不是今天或昨天，返回0
  const daysDiff = Math.floor((today - currentDate) / (1000 * 60 * 60 * 24))
  if (daysDiff > 1) return 0
  
  for (let i = 1; i < completedTasks.length; i++) {
    const prevDate = new Date(completedTasks[i].created_at)
    prevDate.setHours(0, 0, 0, 0)
    
    const diff = Math.floor((currentDate - prevDate) / (1000 * 60 * 60 * 24))
    if (diff === 1) {
      consecutive++
      currentDate = prevDate
    } else if (diff > 1) {
      break
    }
  }
  
  return consecutive
}

// 单日最高番茄数
const getMaxDailyPomodoros = () => {
  const dailyStats = {}
  
  taskStore.tasks
    .filter(t => t.status === TaskStatus.COMPLETED)
    .forEach(t => {
      const date = new Date(t.created_at).toDateString()
      if (!dailyStats[date]) dailyStats[date] = 0
      dailyStats[date] += getPomodoroCount(t.priority)
    })
  
  return Object.keys(dailyStats).length > 0 
    ? Math.max(...Object.values(dailyStats)) 
    : 0
}

// 完成率
const getCompletionRate = () => {
  const total = taskStore.tasks.length
  if (total === 0) return 0
  const completed = taskStore.tasks.filter(t => t.status === TaskStatus.COMPLETED).length
  return Math.round((completed / total) * 100)
}

// 近7天趋势数据
const getLast7DaysTrend = () => {
  const trend = []
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  
  for (let i = 6; i >= 0; i--) {
    const date = new Date(today)
    date.setDate(today.getDate() - i)
    const dateStr = date.toDateString()
    
    const count = taskStore.tasks
      .filter(t => {
        if (t.status !== TaskStatus.COMPLETED) return false
        const taskDate = new Date(t.created_at)
        return taskDate.toDateString() === dateStr
      })
      .reduce((sum, t) => sum + getPomodoroCount(t.priority), 0)
    
    const label = i === 0 ? '今天' : i === 1 ? '昨天' : `${date.getMonth() + 1}/${date.getDate()}`
    trend.push({ label, count, date: dateStr })
  }
  
  return trend
}

// 获取7天内最大值（用于柱状图高度计算）
const getMaxDailyInWeek = () => {
  const trend = getLast7DaysTrend()
  const max = Math.max(...trend.map(d => d.count))
  return max || 1 // 避免除以0
}

// 分类占比
const getCategoryPercent = (category) => {
  const total = earnedPomodoros.value
  if (total === 0) return 0
  const categoryCount = getPomodorosByCategory(category)
  return Math.round((categoryCount / total) * 100)
}

// 等级徽章
const getLevelBadge = () => {
  const total = earnedPomodoros.value
  if (total >= 500) return { icon: '👑', title: '番茄大师' }
  if (total >= 300) return { icon: '🏆', title: '番茄专家' }
  if (total >= 150) return { icon: '⭐', title: '番茄达人' }
  if (total >= 50) return { icon: '🌟', title: '番茄新星' }
  return { icon: '🌱', title: '番茄新手' }
}

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
  if (filter === 'all') {
    currentCategoryFilter.value = 'all'
  }
  currentPage.value = 1
}

// 格式化显示日期
const formatDisplayDate = (dateStr) => {
  if (!dateStr) return ''
  return dateStr.replace(/-/g, '/')
}

// 方法：设置分类筛选
const setCategoryFilter = (category) => {
  currentCategoryFilter.value = category
  currentPage.value = 1
}

// 方法：设置优先级筛选
const setPriorityFilter = (priority) => {
  currentPriorityFilter.value = priority
  currentPage.value = 1
}

// 方法：处理搜索
const handleSearch = () => {
  currentPage.value = 1
}

// 方法：清除搜索
const clearSearch = () => {
  searchKeyword.value = ''
  currentPage.value = 1
}

// 方法：清除时间筛选
const clearDateFilter = () => {
  startDate.value = ''
  endDate.value = ''
  currentPage.value = 1
}

// 显示日期选择器
const showDatePicker = (type) => {
  const pickerRef = type === 'start' ? hiddenStartDate : hiddenEndDate
  pickerRef.value?.showPicker()
}

// 显示自定义日期时间选择器
const showCustomDateTimePicker = () => {
  hiddenCustomDateTime.value?.showPicker()
}

// 处理自定义日期时间变更
const handleCustomDateTimeChange = (e) => {
  customDateTime.value = e.target.value
}

// 方法：获取今天的日期时间（YYYY-MM-DDTHH:MM格式）
const getTodayDateTime = () => {
  const now = new Date()
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')
  const hours = String(now.getHours()).padStart(2, '0')
  const minutes = String(now.getMinutes()).padStart(2, '0')
  return `${year}-${month}-${day}T${hours}:${minutes}`
}

// 方法：格式化显示日期时间
const formatDisplayDateTime = (dateTimeStr) => {
  if (!dateTimeStr) return ''
  const dt = new Date(dateTimeStr)
  const month = dt.getMonth() + 1
  const day = dt.getDate()
  const hours = String(dt.getHours()).padStart(2, '0')
  const minutes = String(dt.getMinutes()).padStart(2, '0')
  return `${month}/${day} ${hours}:${minutes}`
}

// 处理起始日期变更
const handleStartDateChange = (e) => {
  const dateStr = e.target.value
  if (dateStr) {
    startDate.value = dateStr
    currentPage.value = 1
    // 自动触发选择结束日期
    setTimeout(() => {
      showDatePicker('end')
    }, 300)
  }
}

// 处理结束日期变更
const handleEndDateChange = (e) => {
  const dateStr = e.target.value
  if (dateStr) {
    endDate.value = dateStr
    currentPage.value = 1
  }
}

// refs
const hiddenStartDate = ref(null)
const hiddenEndDate = ref(null)
const hiddenCustomDateTime = ref(null)

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
  
  // 验证指定日期
  if (newTaskType.value === 'custom_date' && !customDateTime.value) {
    showNotification('请选择任务日期时间！', 'error')
    return
  }
  
  // 验证每周重复
  if (newTaskType.value === 'weekly' && selectedWeekdays.value.length === 0) {
    showNotification('请至少选择一个星期几！', 'error')
    return
  }
  
  // 解析日期时间
  let customDate = null
  let customTime = null
  if (newTaskType.value === 'custom_date' && customDateTime.value) {
    const dt = new Date(customDateTime.value)
    customDate = customDateTime.value.split('T')[0]
    customTime = `${String(dt.getHours()).padStart(2, '0')}:${String(dt.getMinutes()).padStart(2, '0')}`
  }
  
  const task = {
    text: newTaskText.value.trim(),
    type: newTaskType.value,
    category: newTaskCategory.value,
    priority: newTaskPriority.value,
    weekdays: newTaskType.value === 'weekly' ? selectedWeekdays.value : null,
    customDate: customDate,
    customTime: customTime
  }
  
  await taskStore.addTask(task)
  
  // 清空输入
  newTaskText.value = ''
  newTaskType.value = 'today'
  customDateTime.value = ''
  newTaskCategory.value = 'work'
  newTaskPriority.value = 'medium'
  selectedWeekdays.value = []
  
  showNotification('任务添加成功！', 'success')
}

// 方法：处理任务类型变化
const handleTaskTypeChange = () => {
  // 切换类型时清空相关数据
  if (newTaskType.value !== 'custom_date') {
    customDateTime.value = ''
  }
  if (newTaskType.value !== 'weekly') {
    selectedWeekdays.value = []
  }
}

// 方法：获取今天日期（YYYY-MM-DD格式）
const getTodayDate = () => {
  const today = new Date()
  return today.toISOString().split('T')[0]
}

// 方法：切换任务完成状态
const toggleTaskCompletion = async (taskId) => {
  await taskStore.toggleTaskCompletion(taskId)
  // 完成任务时清除提醒记录
  notifiedTasks.delete(`urgent_${taskId}`)
  notifiedTasks.delete(`overdue_${taskId}`)
}

// 方法：删除任务
const deleteTask = async (taskId) => {
  await taskStore.deleteTask(taskId)
  // 删除任务时清除提醒记录
  notifiedTasks.delete(`urgent_${taskId}`)
  notifiedTasks.delete(`overdue_${taskId}`)
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
  editCategory.value = task.category
  editPriority.value = task.priority
  editType.value = task.type
  
  // 组合日期和时间为datetime-local格式
  if (task.customDate) {
    editCustomDateTime.value = task.customDate + (task.customTime ? `T${task.customTime}` : 'T00:00')
  } else {
    editCustomDateTime.value = ''
  }
  
  editWeekdays.value = task.weekdays ? [...task.weekdays] : []
}

// 方法：处理编辑类型变化
const handleEditTypeChange = () => {
  if (editType.value !== 'custom_date') {
    editCustomDateTime.value = ''
  }
  if (editType.value !== 'weekly') {
    editWeekdays.value = []
  }
}

// 方法：保存任务编辑
const saveTaskEdit = async () => {
  if (!editingTask.value) return
  if (!editText.value.trim()) {
    showNotification('任务名称不能为空！', 'error')
    return
  }
  
  // 验证指定日期
  if (editType.value === 'custom_date' && !editCustomDateTime.value) {
    showNotification('请选择任务日期时间！', 'error')
    return
  }
  
  // 如果是每周类型，必须选择至少一天
  if (editType.value === 'weekly' && editWeekdays.value.length === 0) {
    showNotification('每周任务至少选择一天！', 'error')
    return
  }
  
  // 解析日期时间
  let customDate = null
  let customTime = null
  if (editType.value === 'custom_date' && editCustomDateTime.value) {
    const dt = new Date(editCustomDateTime.value)
    customDate = editCustomDateTime.value.split('T')[0]
    customTime = `${String(dt.getHours()).padStart(2, '0')}:${String(dt.getMinutes()).padStart(2, '0')}`
  }
  
  await taskStore.updateTask(editingTask.value.id, {
    text: editText.value.trim(),
    description: editDescription.value,
    category: editCategory.value,
    priority: editPriority.value,
    type: editType.value,
    customDate: customDate,
    customTime: customTime,
    weekdays: editType.value === 'weekly' ? editWeekdays.value : []
  })
  
  editingTask.value = null
  showNotification('任务已更新！', 'success')
}

// 方法：退出登录
const handleLogout = async () => {
  await userStore.logout()
  taskStore.clearUser()
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
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hour = String(date.getHours()).padStart(2, '0')
  const minute = String(date.getMinutes()).padStart(2, '0')
  return `${year}/${month}/${day} ${hour}:${minute}`
}

// 方法：编辑用户名
const editingUsername = ref(false)
const usernameInput = ref(null)

const startEditUsername = () => {
  newUsername.value = currentUsername.value
  editingUsername.value = true
  nextTick(() => {
    usernameInput.value?.focus()
  })
}

const saveUsername = async () => {
  if (!newUsername.value || newUsername.value === currentUsername.value) {
    editingUsername.value = false
    return
  }
  
  const username = currentUsername.value
  const { value: usersData } = await Preferences.get({ key: 'users' })
  const users = usersData ? JSON.parse(usersData) : {}
  
  if (users[newUsername.value]) {
    alert('用户名已存在')
    editingUsername.value = false
    return
  }
  
  const password = users[username]
  delete users[username]
  users[newUsername.value] = password
  
  await Preferences.set({ key: 'users', value: JSON.stringify(users) })
  await Preferences.set({ key: 'currentUser', value: newUsername.value })
  
  taskStore.tasks.forEach(task => {
    if (task.user_id === username) {
      task.user_id = newUsername.value
    }
  })
  await taskStore.saveTasks()
  
  userStore.currentUser = newUsername.value
  editingUsername.value = false
  alert('用户名修改成功')
}

// 方法：修改密码
const updatePassword = async () => {
  if (!oldPassword.value || !newPassword.value) {
    alert('请输入当前密码和新密码')
    return
  }
  
  const { value: usersData } = await Preferences.get({ key: 'users' })
  const users = usersData ? JSON.parse(usersData) : {}
  const username = currentUsername.value
  
  if (users[username] !== oldPassword.value) {
    alert('当前密码错误')
    return
  }
  
  users[username] = newPassword.value
  await Preferences.set({ key: 'users', value: JSON.stringify(users) })
  
  oldPassword.value = ''
  newPassword.value = ''
  alert('密码修改成功')
}

// 方法：发送绑定手机验证码
const sendBindSMS = async () => {
  if (!/^1[3-9]\d{9}$/.test(bindPhoneNumber.value)) {
    showNotification('请输入正确的手机号', 'error')
    return
  }

  // 检查手机号是否已被其他账号绑定
  const { value: userInfoData } = await Preferences.get({ key: 'userInfo' })
  const allUserInfo = userInfoData ? JSON.parse(userInfoData) : {}
  
  for (const [user, info] of Object.entries(allUserInfo)) {
    if (info.boundPhone === bindPhoneNumber.value && user !== currentUsername.value) {
      showNotification('该手机号已被其他账号绑定', 'error')
      return
    }
  }

  bindGeneratedCode.value = Math.floor(100000 + Math.random() * 900000).toString()
  
  const { LocalNotifications } = await import('@capacitor/local-notifications')
  await LocalNotifications.schedule({
    notifications: [{
      title: '【TO-DO 绑定验证码】',
      body: `您的绑定验证码为：${bindGeneratedCode.value}，请在5分钟内完成验证。`,
      id: 2,
      schedule: { at: new Date(Date.now() + 1000) }
    }]
  })

  showNotification('验证码已发送', 'info')
  
  bindCountdown.value = 60
  bindTimer = setInterval(() => {
    bindCountdown.value--
    if (bindCountdown.value <= 0) clearInterval(bindTimer)
  }, 1000)
}

// 方法：确认绑定手机号
const confirmBindPhone = async () => {
  if (String(bindVerificationCode.value) !== String(bindGeneratedCode.value) || !bindGeneratedCode.value) {
    showNotification('验证码错误或已失效', 'error')
    return
  }

  const username = currentUsername.value
  const { value: userInfoData } = await Preferences.get({ key: 'userInfo' })
  const userInfo = userInfoData ? JSON.parse(userInfoData) : {}
  
  if (!userInfo[username]) {
    userInfo[username] = {}
  }
  
  userInfo[username].boundPhone = bindPhoneNumber.value
  await Preferences.set({ key: 'userInfo', value: JSON.stringify(userInfo) })
  
  // 创建手机号到用户名的映射
  const { value: phoneMappingData } = await Preferences.get({ key: 'phoneMapping' })
  const phoneMapping = phoneMappingData ? JSON.parse(phoneMappingData) : {}
  phoneMapping[bindPhoneNumber.value] = username
  await Preferences.set({ key: 'phoneMapping', value: JSON.stringify(phoneMapping) })
  
  userProfileInfo.value.boundPhone = bindPhoneNumber.value
  bindPhoneNumber.value = ''
  bindVerificationCode.value = ''
  bindGeneratedCode.value = ''
  
  showNotification('手机号绑定成功！', 'success')
}

// 方法：解绑手机号
const unbindPhone = async () => {
  if (!confirm('确定要解绑手机号吗？')) return
  
  const username = currentUsername.value
  const phone = userProfileInfo.value.boundPhone
  
  const { value: userInfoData } = await Preferences.get({ key: 'userInfo' })
  const userInfo = userInfoData ? JSON.parse(userInfoData) : {}
  
  if (userInfo[username]) {
    delete userInfo[username].boundPhone
    await Preferences.set({ key: 'userInfo', value: JSON.stringify(userInfo) })
  }
  
  // 删除手机号映射
  const { value: phoneMappingData } = await Preferences.get({ key: 'phoneMapping' })
  const phoneMapping = phoneMappingData ? JSON.parse(phoneMappingData) : {}
  delete phoneMapping[phone]
  await Preferences.set({ key: 'phoneMapping', value: JSON.stringify(phoneMapping) })
  
  userProfileInfo.value.boundPhone = null
  showNotification('手机号已解绑', 'success')
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
      return '今天'
    case 'tomorrow':
      return '明天'
    case 'this_week':
      return '本周内'
    case 'custom_date':
      if (task.customDate) {
        const date = new Date(task.customDate)
        const month = date.getMonth() + 1
        const day = date.getDate()
        let text = `${month}/${day}`
        // 如果有具体时间，也显示时间
        if (task.customTime) {
          text += ` ${task.customTime}`
        }
        return text
      }
      return '指定日期'
    case 'daily':
      return '每天'
    case 'weekday':
      return '工作日'
    case 'weekly':
      if (task.weekdays) {
        const selectedDays = task.weekdays.map(day => weekdays[day]).join(',')
        return `每周${selectedDays}`
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

// 方法：获取番茄数（根据优先级）
const getPomodoroCount = (priority) => {
  const pomodoroMap = {
    high: 4,
    medium: 2,
    low: 1
  }
  return pomodoroMap[priority] || 2
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
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hour = String(date.getHours()).padStart(2, '0')
  const minute = String(date.getMinutes()).padStart(2, '0')
  return `${year}/${month}/${day} ${hour}:${minute}`
}

// 方法：获取任务截止时间文本
const getDeadlineText = (task) => {
  const deadline = calculateDeadline(task)
  if (!deadline) return '无截止'
  
  const now = new Date()
  const diff = deadline - now
  
  if (diff < 0) {
    // 已逾期
    const absDiff = Math.abs(diff)
    const hours = Math.floor(absDiff / (1000 * 60 * 60))
    const days = Math.floor(hours / 24)
    const remainingHours = hours % 24
    
    if (days > 0) return `逾期 ${days}天 ${remainingHours}小时`
    return `逾期 ${hours}小时`
  } else {
    // 未逾期
    const hours = Math.floor(diff / (1000 * 60 * 60))
    const days = Math.floor(hours / 24)
    const remainingHours = hours % 24
    
    const date = new Date(deadline)
    const year = date.getFullYear()
    const month = date.getMonth() + 1
    const day = date.getDate()
    const hour = String(date.getHours()).padStart(2, '0')
    const minute = String(date.getMinutes()).padStart(2, '0')
    
    // 基础日期格式
    let dateStr = `${year}/${month}/${day} ${hour}:${minute}`
    if (date.toDateString() === now.toDateString()) {
      dateStr = `今天 ${hour}:${minute}`
    } else if (new Date(now.getTime() + 86400000).toDateString() === date.toDateString()) {
      dateStr = `明天 ${hour}:${minute}`
    }
    
    // 添加剩余时间提醒
    if (days > 0) return `${dateStr} (还剩 ${days}天)`
    return `${dateStr} (仅剩 ${hours}小时)`
  }
}

// 方法：计算任务截止时间
const calculateDeadline = (task) => {
  const now = new Date()
  
  switch (task.type) {
    case 'today':
      return new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59)
    
    case 'tomorrow':
      const tomorrow = new Date(now)
      tomorrow.setDate(tomorrow.getDate() + 1)
      return new Date(tomorrow.getFullYear(), tomorrow.getMonth(), tomorrow.getDate(), 23, 59, 59)
    
    case 'this_week':
      const endOfWeek = new Date(now)
      const dayOfWeek = now.getDay()
      const daysUntilSunday = dayOfWeek === 0 ? 0 : 7 - dayOfWeek
      endOfWeek.setDate(endOfWeek.getDate() + daysUntilSunday)
      return new Date(endOfWeek.getFullYear(), endOfWeek.getMonth(), endOfWeek.getDate(), 23, 59, 59)
    
    case 'custom_date':
      if (task.customDate) {
        const date = new Date(task.customDate)
        if (task.customTime) {
          const [hours, minutes] = task.customTime.split(':')
          date.setHours(parseInt(hours), parseInt(minutes), 0)
        } else {
          date.setHours(23, 59, 59)
        }
        return date
      }
      return null
    
    case 'daily':
      return new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59)
      
    case 'weekday':
      const isWeekend = now.getDay() === 0 || now.getDay() === 6
      if (isWeekend) {
        // 如果是周末看工作日任务，截止日期应该是上周五
        const lastFriday = new Date(now)
        const diff = now.getDay() === 0 ? 2 : 1
        lastFriday.setDate(now.getDate() - diff)
        return new Date(lastFriday.getFullYear(), lastFriday.getMonth(), lastFriday.getDate(), 23, 59, 59)
      }
      return new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59)

    case 'weekly':
      if (task.weekdays && task.weekdays.length > 0) {
        const currentDay = now.getDay()
        // 找到最近的一个设定的星期几（过去或今天）
        const pastDays = task.weekdays
          .map(d => (currentDay >= d ? currentDay - d : currentDay + 7 - d))
          .sort((a, b) => a - b)
        
        const lastOccurrence = new Date(now)
        lastOccurrence.setDate(now.getDate() - pastDays[0])
        return new Date(lastOccurrence.getFullYear(), lastOccurrence.getMonth(), lastOccurrence.getDate(), 23, 59, 59)
      }
      return new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59)
    
    default:
      return null
  }
}

// 方法：获取截止时间颜色类
const getDeadlineClass = (task) => {
  if (task.status === TaskStatus.COMPLETED) return 'deadline-completed'
  
  const deadline = calculateDeadline(task)
  if (!deadline) return ''
  
  const now = new Date()
  const diff = deadline - now
  const hours = diff / (1000 * 60 * 60)
  
  if (diff < 0) return 'deadline-overdue'        // 已逾期：红色
  if (hours <= 1) return 'deadline-urgent'       // 小于1小时：红色
  if (hours <= 6) return 'deadline-warning'      // 小于6小时：橙色
  return 'deadline-normal'                        // 正常：蓝色
}

// 方法：显示通知
const emit = defineEmits(['notify'])
const showNotification = (message, type = 'info') => {
  emit('notify', { message, type })
}

// 生命周期钩子：组件挂载时
// 下拉刷新方法
const handleTouchStart = (e) => {
  if (mainContent.value && mainContent.value.scrollTop === 0) {
    startY = e.touches[0].clientY
  }
}

const handleTouchMove = (e) => {
  if (startY === 0) return
  
  currentY = e.touches[0].clientY
  const diff = currentY - startY
  
  if (diff > 0 && mainContent.value.scrollTop === 0) {
    e.preventDefault()
    
    if (diff < pullThreshold) {
      pullRefreshState.value = 'pulling'
    } else {
      pullRefreshState.value = 'ready'
    }
  }
}

const handleTouchEnd = async () => {
  if (pullRefreshState.value === 'ready') {
    pullRefreshState.value = 'refreshing'
    await refreshData()
    setTimeout(() => {
      pullRefreshState.value = 'idle'
    }, 500)
  } else {
    pullRefreshState.value = 'idle'
  }
  startY = 0
  currentY = 0
}

const refreshData = async () => {
  await taskStore.setCurrentUser(userStore.currentUser)
  await loadUserInfo()
  taskStore.checkOverdueTasks()
}

// 检查并发送逾期提醒
const checkAndNotifyDeadline = async () => {
  const now = new Date()
  const notifications = []
  
  // 幽默话术库
  const urgentMessages = [
    '🍅 番茄要逃跑啦！快来抓住它！',
    '⏰ 时间在偷偷溜走，番茄也要跟着跑了！',
    '🏃 番茄已经在打包行李了，快去完成任务！',
    '😱 再不做，番茄就要被别人抢走了！',
    '🚨 紧急！番茄正在倒计时，快救救它！'
  ]
  
  const overdueMessages = [
    '💔 番茄已经逃跑了...快去把它追回来！',
    '😭 番茄伤心地离开了，赶紧去道歉吧！',
    '🏃‍♂️ 番茄跑远了，但还来得及追！',
    '⚠️ 番茄已出走，速度追回还有机会！',
    '😢 番茄等累了已经走了，快去挽回！'
  ]
  
  taskStore.tasks.forEach(task => {
    if (task.status === 'completed') return
    
    const deadline = calculateDeadline(task)
    if (!deadline) return
    
    const timeLeft = deadline - now
    const hoursLeft = timeLeft / (1000 * 60 * 60)
    const tomatoCount = task.priority === 'high' ? 4 : task.priority === 'medium' ? 2 : 1
    
    // 1小时内即将逾期的任务
    if (hoursLeft > 0 && hoursLeft <= 1) {
      const notifyKey = `urgent_${task.id}`
      if (notifiedTasks.has(notifyKey)) return // 已提醒过，跳过
      
      const minutes = Math.floor((timeLeft / (1000 * 60)) % 60)
      const randomMsg = urgentMessages[Math.floor(Math.random() * urgentMessages.length)]
      notifications.push({
        title: `⏰ ${task.text}`,
        body: `还剩 ${minutes} 分钟！${randomMsg}\n${tomatoCount}个番茄岌岌可危 ${'🍅'.repeat(tomatoCount)}`,
        id: task.id,
        schedule: { at: new Date(Date.now() + 100) }
      })
      notifiedTasks.add(notifyKey) // 记录已提醒
    }
    // 已逾期但还未标记的任务
    else if (timeLeft < 0 && task.status !== 'overdue') {
      const notifyKey = `overdue_${task.id}`
      if (notifiedTasks.has(notifyKey)) return // 已提醒过，跳过
      
      const randomMsg = overdueMessages[Math.floor(Math.random() * overdueMessages.length)]
      notifications.push({
        title: `❌ ${task.text}`,
        body: `${randomMsg}\n损失 ${tomatoCount}个番茄 ${'💔'.repeat(tomatoCount)}`,
        id: task.id + 100000,
        schedule: { at: new Date(Date.now() + 100) }
      })
    }
  })
  
  if (notifications.length > 0) {
    await LocalNotifications.schedule({ notifications })
  }
}

onMounted(async () => {
  await userStore.checkLogin()
  await loadUserInfo()
  
  // 设置任务Store的当前用户并加载该用户的任务
  await taskStore.setCurrentUser(userStore.currentUser)
  
  // 请求通知权限
  await LocalNotifications.requestPermissions()
  
  countdownInterval.value = setInterval(() => {
    taskStore.checkOverdueTasks()
    checkAndNotifyDeadline()
  }, 60000) // 每分钟检查一次
  
  // 首次立即检查
  checkAndNotifyDeadline()
  
  // 添加下拉刷新事件监听
  if (mainContent.value) {
    mainContent.value.addEventListener('touchstart', handleTouchStart, { passive: false })
    mainContent.value.addEventListener('touchmove', handleTouchMove, { passive: false })
    mainContent.value.addEventListener('touchend', handleTouchEnd)
  }
})

// 生命周期钩子：组件卸载时
onUnmounted(() => {
  if (countdownInterval.value) clearInterval(countdownInterval.value)
  
  // 移除下拉刷新事件监听
  if (mainContent.value) {
    mainContent.value.removeEventListener('touchstart', handleTouchStart)
    mainContent.value.removeEventListener('touchmove', handleTouchMove)
    mainContent.value.removeEventListener('touchend', handleTouchEnd)
  }
})
</script>

<style scoped>
.pull-refresh-indicator {
  position: fixed;
  top: -60px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.8rem 1.5rem;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transition: top 0.3s ease;
  z-index: 9999;
}

.pull-refresh-indicator.active {
  top: 20px;
}

.refresh-icon {
  font-size: 1.2rem;
  transition: transform 0.3s ease;
}

.refresh-icon.pulling {
  transform: rotate(0deg);
}

.refresh-icon.ready {
  transform: rotate(180deg);
}

.refresh-icon.refreshing {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.refresh-text {
  font-size: 0.9rem;
  color: #333;
  font-weight: 500;
}

.todo-layout {
  display: flex;
  justify-content: center;
  padding: 0;
  min-height: 100vh;
  width: 100%;
  max-width: 100vw;
  overflow-x: hidden;
}

.main-content {
  width: 100%;
  max-width: 100%;
  flex: none;
  padding: 0.5rem 0.8rem;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  gap: 0;
}

/* 任务列表与统计区域内容完全对齐（像素级） */
.task-list {
  width: 100% !important;
  max-width: none !important;
  padding: 0 !important;
  margin: 0 !important;
  box-sizing: border-box;
}

.task-list ul {
  width: 100%;
  max-width: none;
  list-style: none;
  padding: 0;
  margin: 0;
}

/* v1.2: 统计栏卡片感增强 */
.dashboard-area {
  background: rgba(255, 255, 255, 0.35);
  border-radius: 12px;
  padding: 0.8rem;
  margin: 0 0 1rem 0;
  border: 1.5px solid rgba(255, 255, 255, 0.5);
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  width: 100%;
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
  font-size: 0.85rem;
  flex-shrink: 0;
}

.stat-count {
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--text-dark);
}

.stat-count.success { color: var(--success-color); }
.stat-count.danger { color: var(--error-color); }

.stat-count-plain {
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--text-light);
  opacity: 0.7;
}

.stat-label-mini {
  font-size: 0.7rem;
  color: var(--text-light);
  white-space: nowrap;
}

/* 第二行：状态和时间筛选 (合并为一行) */
.filter-row-unified {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  width: 100%;
  margin-top: 0.4rem;
  flex-wrap: nowrap;
}

.filter-row-unified .stat-row {
  flex: 0.8;
  justify-content: center;
  background: rgba(255, 255, 255, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.3);
  padding: 0.2rem 0.2rem;
}

/* 搜索框 */
.search-box {
  flex: 2;
  position: relative;
  display: flex;
  align-items: center;
}

.search-input {
  width: 100%;
  padding: 0.2rem 2rem 0.2rem 0.5rem;
  border: 1px solid rgba(255, 255, 255, 0.5);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.4);
  font-size: 0.7rem;
  transition: all 0.3s;
}

.search-input:focus {
  outline: none;
  background: rgba(255, 255, 255, 0.6);
  border-color: var(--primary-color);
}

.search-input::placeholder {
  color: var(--text-light);
  opacity: 0.7;
}

.clear-search {
  position: absolute;
  right: 0.5rem;
  background: none;
  border: none;
  color: var(--text-light);
  cursor: pointer;
  font-size: 0.9rem;
  padding: 0.2rem;
  transition: color 0.2s;
}

.clear-search:hover {
  color: var(--error-color);
}

.date-range-display {
  display: flex;
  align-items: center;
  background: rgba(255, 255, 255, 0.4);
  border: 1px solid rgba(255, 255, 255, 0.5);
  border-radius: 8px;
  padding: 0.2rem 0;
  gap: 0;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.05);
  transition: all 0.3s;
  flex: 2.5;
  position: relative;
  overflow: hidden;
}

.date-range-display:hover {
  background: rgba(255, 255, 255, 0.6);
  border-color: var(--primary-color);
}

.range-values {
  display: flex;
  align-items: center;
  flex: 1;
  height: 100%;
}

.date-clickable-area {
  flex: 1;
  height: 100%;
  padding: 0 0.3rem;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.7rem;
  font-weight: 600;
  color: var(--text-dark);
  cursor: pointer;
  transition: background 0.2s;
  white-space: nowrap;
}

.date-clickable-area:hover {
  background: rgba(102, 126, 234, 0.1);
}

.date-clickable-area.placeholder {
  color: var(--text-light);
  font-weight: 400;
  opacity: 0.6;
}

.range-sep {
  color: var(--text-light);
  opacity: 0.5;
}

.clear-date-icon {
  background: var(--error-color);
  color: white;
  border: none;
  border-radius: 50%;
  width: 18px;
  height: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 10px;
  font-weight: bold;
  margin-left: auto;
}

.calendar-icon {
  font-size: 1rem;
  opacity: 0.7;
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
  margin: -0.5rem 0.2rem -0.5rem -0.5rem; /* 微调间距以对齐统计按钮 */
  cursor: pointer;
}

/* v1.2: 任务卡片触摸反馈 */
.task-item {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  padding: 0.8rem; /* 与 dashboard-area 保持一致 */
  background: white;
  border-radius: 12px;
  margin: 0 0 0.8rem 0 !important; /* 强制覆盖全局 1.5rem margin */
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.3s;
  -webkit-tap-highlight-color: transparent;
  width: 100%;
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
  font-size: 0.75rem;
}

/* 番茄数徽章 */
.badge-pomodoro {
  display: inline-flex;
  align-items: center;
  gap: 0.2rem;
  font-size: 0.75rem;
  font-weight: 600;
  padding: 0.2rem 0.5rem;
  border-radius: 12px;
  transition: all 0.3s;
}

.pomodoro-high {
  background: rgba(244, 67, 54, 0.1);
  color: #f44336;
}

.pomodoro-medium {
  background: rgba(255, 152, 0, 0.1);
  color: #ff9800;
}

.pomodoro-low {
  background: rgba(102, 126, 234, 0.1);
  color: var(--primary-color);
}

/* 任务截止时间显示 */
.task-deadline {
  font-size: 0.8rem;
  font-weight: 600;
  padding: 0.2rem 0.5rem;
  border-radius: 12px;
  transition: all 0.3s;
}

.deadline-normal {
  background: rgba(102, 126, 234, 0.1);
  color: var(--primary-color);
}

.deadline-warning {
  background: rgba(255, 152, 0, 0.1);
  color: #ff9800;
}

.deadline-urgent {
  background: rgba(244, 67, 54, 0.1);
  color: #f44336;
  animation: pulse 2s infinite;
}

.deadline-overdue {
  background: rgba(244, 67, 54, 0.15);
  color: #d32f2f;
  font-weight: 700;
}

.deadline-completed {
  background: rgba(76, 175, 80, 0.1);
  color: var(--success-color);
  text-decoration: line-through;
  opacity: 0.7;
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

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.2rem 0.8rem;
  margin-bottom: 0;
  border-bottom: 1px solid var(--glass-border);
  width: 100%;
}

.user-info h1 {
  font-size: 1.4rem;
  margin: 0;
}

.btn-avatar {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  border: 2px solid rgba(255, 255, 255, 0.8);
  background: white;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.avatar-mini {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.1rem;
  font-weight: 800;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.btn-avatar:hover {
  transform: translateY(-2px) scale(1.05);
  border-color: var(--primary-color);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.btn-avatar:active {
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
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.username-edit-input {
  border: 1px solid #ddd;
  border-radius: 4px;
  padding: 0.3rem 0.5rem;
  font-size: 1.5rem;
  font-weight: 600;
  width: 200px;
}

.edit-icon {
  font-size: 1rem;
  cursor: pointer;
  opacity: 0.6;
  transition: opacity 0.2s;
}

.edit-icon:hover {
  opacity: 1;
}

.password-row {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.password-row .input {
  flex: 1;
  margin: 0;
}

.btn-compact {
  padding: 0.6rem 1rem;
  white-space: nowrap;
}

.bind-phone-row {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.bind-phone-row .input {
  flex: 1;
  margin: 0;
}

.bound-phone-info {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.phone-display {
  font-size: 1rem;
  color: #333;
  font-weight: 500;
}

.bind-hint {
  margin: 0.5rem 0 0 0;
  font-size: 0.75rem;
  color: #999;
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

/* 番茄统计入口 */
.pomodoro-entry {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.2rem;
  background: linear-gradient(135deg, rgba(255, 107, 107, 0.1) 0%, rgba(255, 193, 7, 0.1) 100%);
  border-radius: 12px;
  margin-bottom: 1.5rem;
  cursor: pointer;
  transition: all 0.3s;
}

.pomodoro-entry:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.entry-icon {
  font-size: 2.5rem;
  flex-shrink: 0;
}

.entry-content {
  flex: 1;
}

.entry-title {
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--text-dark);
  margin-bottom: 0.3rem;
}

.entry-summary {
  font-size: 0.85rem;
  color: var(--text-light);
}

.entry-arrow {
  font-size: 1.5rem;
  color: var(--text-light);
}

/* 等级徽章 */
.level-badge {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  margin-bottom: 1.5rem;
  color: white;
}

.level-badge-icon {
  font-size: 3rem;
}

.badge-title {
  font-size: 1.3rem;
  font-weight: 700;
  margin-bottom: 0.3rem;
}

.badge-desc {
  font-size: 0.9rem;
  opacity: 0.9;
}

/* 趋势图 */
.trend-chart {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  height: 180px;
  padding: 1rem;
  background: rgba(0, 0, 0, 0.02);
  border-radius: 10px;
  gap: 0.5rem;
}

.trend-bar-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  height: 100%;
}

.trend-bar {
  width: 100%;
  min-height: 20px;
  background: linear-gradient(to top, var(--primary-color), rgba(102, 126, 234, 0.6));
  border-radius: 6px 6px 0 0;
  position: relative;
  transition: all 0.3s;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 0.3rem;
}

.trend-bar:hover {
  background: linear-gradient(to top, #5568d3, var(--primary-color));
}

.trend-value {
  font-size: 0.75rem;
  font-weight: 700;
  color: white;
}

.trend-label {
  margin-top: 0.5rem;
  font-size: 0.7rem;
  color: var(--text-light);
  text-align: center;
}

/* 分类占比条 */
.category-bars {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.category-bar-item {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.category-bar-header {
  display: flex;
  justify-content: space-between;
  font-size: 0.9rem;
  color: var(--text-dark);
}

.category-bar-value {
  font-weight: 600;
  color: var(--primary-color);
}

.category-bar-bg {
  height: 24px;
  background: rgba(0, 0, 0, 0.05);
  border-radius: 12px;
  overflow: hidden;
}

.category-bar-fill {
  height: 100%;
  border-radius: 12px;
  transition: width 0.5s ease;
}

.category-bar-fill.work {
  background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
}

.category-bar-fill.study {
  background: linear-gradient(90deg, #f093fb 0%, #f5576c 100%);
}

.category-bar-fill.life {
  background: linear-gradient(90deg, #4facfe 0%, #00f2fe 100%);
}

/* 番茄统计详情弹窗 */
.pomodoro-overview {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1rem;
  margin-bottom: 2rem;
}

.overview-item {
  text-align: center;
  padding: 1rem;
  border-radius: 10px;
  transition: all 0.3s;
}

.overview-item:hover {
  transform: translateY(-2px);
}

.overview-item.earned {
  background: rgba(76, 175, 80, 0.1);
}

.overview-item.pending {
  background: rgba(255, 152, 0, 0.1);
}

.overview-item.lost {
  background: rgba(244, 67, 54, 0.1);
}

.overview-item.total {
  background: rgba(102, 126, 234, 0.15);
}

.overview-icon {
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.overview-value {
  font-size: 1.8rem;
  font-weight: 700;
  margin-bottom: 0.3rem;
}

.overview-item.earned .overview-value {
  color: #4caf50;
}

.overview-item.pending .overview-value {
  color: #ff9800;
}

.overview-item.lost .overview-value {
  color: #f44336;
}

.overview-item.total .overview-value {
  color: var(--primary-color);
}

.overview-label {
  font-size: 0.75rem;
  color: var(--text-light);
}

.stats-section {
  margin-bottom: 1.5rem;
}

.section-title {
  font-size: 1rem;
  font-weight: 600;
  margin-bottom: 1rem;
  color: var(--text-dark);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}

.stats-card {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  padding: 1rem;
  background: rgba(0, 0, 0, 0.02);
  border-radius: 10px;
  transition: all 0.3s;
}

.stats-card:hover {
  background: rgba(0, 0, 0, 0.05);
  transform: translateY(-2px);
}

.stats-icon {
  font-size: 1.8rem;
}

.stats-info {
  flex: 1;
}

.stats-value {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--primary-color);
  margin-bottom: 0.2rem;
}

.stats-label {
  font-size: 0.8rem;
  color: var(--text-light);
}

.achievement-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}

.achievement-card {
  text-align: center;
  padding: 1.5rem 1rem;
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(118, 75, 162, 0.1) 100%);
  border-radius: 12px;
  transition: all 0.3s;
}

.achievement-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 6px 16px rgba(102, 126, 234, 0.2);
}

.achievement-icon {
  font-size: 2.5rem;
  margin-bottom: 0.8rem;
}

.achievement-value {
  font-size: 2rem;
  font-weight: 700;
  color: var(--primary-color);
  margin-bottom: 0.3rem;
}

.achievement-label {
  font-size: 0.85rem;
  color: var(--text-light);
  font-weight: 500;
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

.date-picker-inline {
  padding: 0.4rem 0.5rem;
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.6);
  font-size: 0.8rem;
  cursor: pointer;
  min-width: 80px;
  text-align: center;
  transition: all 0.2s;
  white-space: nowrap;
}

.date-picker-inline:hover {
  background: white;
  border-color: var(--primary-color);
}

.date-picker-inline.placeholder {
  color: var(--text-light);
  opacity: 0.7;
}

.time-picker-inline {
  padding: 0.4rem 0.5rem;
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.6);
  font-size: 0.8rem;
  cursor: pointer;
  min-width: 70px;
  text-align: center;
  transition: all 0.2s;
  white-space: nowrap;
}

.time-picker-inline:hover {
  background: white;
  border-color: var(--primary-color);
}

.time-picker-inline.placeholder {
  color: var(--text-light);
  opacity: 0.7;
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

/* 页脚版权信息 */
.app-footer {
  margin-top: 2rem;
  padding: 1.5rem 0 1rem;
  border-top: 1px solid rgba(255, 255, 255, 0.2);
}

.footer-content {
  text-align: center;
}

.footer-version {
  font-size: 0.7rem;
  color: rgba(255, 255, 255, 0.6);
  margin-bottom: 0.3rem;
  font-weight: 500;
}

.footer-copyright {
  font-size: 0.65rem;
  color: rgba(255, 255, 255, 0.5);
  margin-bottom: 0.2rem;
}

.footer-license {
  font-size: 0.6rem;
  color: rgba(255, 255, 255, 0.4);
  line-height: 1.4;
}

.privacy-link {
  color: rgba(255, 255, 255, 0.7);
  cursor: pointer;
  text-decoration: underline;
  transition: color 0.3s;
}

.privacy-link:hover {
  color: rgba(255, 255, 255, 1);
}

/* 隐私政策模态框 */
.privacy-modal {
  background: white;
  max-width: 700px;
  max-height: 80vh;
  overflow-y: auto;
}

.privacy-content {
  padding: 1.5rem;
  line-height: 1.8;
}

.privacy-content .update-date {
  text-align: center;
  color: #666;
  margin-bottom: 1.5rem;
  font-size: 0.9rem;
}

.privacy-content h4 {
  color: #667eea;
  font-size: 1.1rem;
  margin-top: 1.5rem;
  margin-bottom: 0.8rem;
  padding-bottom: 0.5rem;
  border-bottom: 2px solid #667eea;
}

.privacy-content p {
  margin: 0.8rem 0;
  color: #333;
  text-align: justify;
}

.privacy-content ul {
  margin: 0.8rem 0;
  padding-left: 2rem;
}

.privacy-content li {
  margin: 0.5rem 0;
  color: #555;
}

.highlight-box {
  background: #f0f4ff;
  padding: 1rem;
  border-left: 4px solid #667eea;
  margin: 1rem 0;
  border-radius: 4px;
}

.contact-box {
  background: #f8f9fa;
  padding: 1rem;
  border-radius: 8px;
  margin: 1rem 0;
}

.contact-box p {
  margin: 0.5rem 0;
}

/* 编辑模态框周期选择器 */
.weekday-selector {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.weekday-label {
  display: flex;
  align-items: center;
  gap: 0.3rem;
  padding: 0.4rem 0.6rem;
  border: 1px solid #ddd;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 0.85rem;
}

.weekday-label:has(input:checked) {
  background: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.weekday-label input[type="checkbox"] {
  margin: 0;
  cursor: pointer;
}
</style>