<template>
  <div class="app">
    <div class="bg-decoration">
      <div class="blob blob-1"></div>
      <div class="blob blob-2"></div>
      <div class="blob blob-3"></div>
    </div>
    
    <!-- 全局通知 -->
    <div v-if="notification.show" class="notification-toast glass-card" :class="notification.type">
      {{ notification.message }}
    </div>

    <router-view v-slot="{ Component }">
      <transition name="fade" mode="out-in">
        <component :is="Component" @notify="showNotify" />
      </transition>
    </router-view>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'

const notification = reactive({
  show: false,
  message: '',
  type: 'info'
})

let timer = null

const showNotify = (data) => {
  if (timer) clearTimeout(timer)
  
  notification.message = data.message
  notification.type = data.type || 'info'
  notification.show = true
  
  timer = setTimeout(() => {
    notification.show = false
  }, 3000)
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #f0f2f5;
  color: #333;
  line-height: 1.6;
  min-height: 100vh;
  overflow-x: hidden;
  width: 100vw;
  max-width: 100%;
}

.app {
  min-height: 100vh;
  width: 100vw;
  max-width: 100%;
  display: flex;
  flex-direction: column;
  position: relative;
  z-index: 1;
  overflow-x: hidden;
}

.bg-decoration {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: -1;
  overflow: hidden;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.blob {
  position: absolute;
  width: min(500px, 80vw);
  height: min(500px, 80vw);
  background: rgba(255, 255, 255, 0.1);
  filter: blur(80px);
  border-radius: 50%;
  z-index: -1;
  animation: move 20s infinite alternate;
}

.blob-1 {
  top: -100px;
  left: -100px;
  background: rgba(102, 126, 234, 0.3);
}

.blob-2 {
  bottom: -150px;
  right: -100px;
  background: rgba(118, 75, 162, 0.3);
  animation-delay: -5s;
}

.blob-3 {
  top: 40%;
  left: 30%;
  width: min(300px, 60vw);
  height: min(300px, 60vw);
  background: rgba(231, 76, 60, 0.1);
  animation-delay: -10s;
}

@keyframes move {
  from { transform: translate(0, 0) scale(1); }
  to { transform: translate(100px, 100px) scale(1.2); }
}

/* 通知吐司样式 */
.notification-toast {
  position: fixed;
  top: 2rem;
  right: 2rem;
  padding: 1rem 2rem;
  z-index: 2000;
  animation: slideIn 0.3s ease-out;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.notification-toast.success { border-left: 4px solid var(--success-color); color: var(--success-color); }
.notification-toast.error { border-left: 4px solid var(--error-color); color: var(--error-color); }
.notification-toast.info { border-left: 4px solid var(--primary-color); color: var(--primary-color); }

@keyframes slideIn {
  from { transform: translateX(100%); opacity: 0; }
  to { transform: translateX(0); opacity: 1; }
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>