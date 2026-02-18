<template>
  <div class="login-container">
    <div class="glass-card login-box">
      <h2>{{ isRegister ? '注册账号' : 'Welcome Back' }}</h2>
      <div class="input-group">
        <label for="username">用户名</label>
        <input 
          type="text" 
          id="username" 
          v-model="username" 
          class="input"
          placeholder="请输入用户名"
          @keyup.enter="handleSubmit"
        >
      </div>
      <div class="input-group">
        <label for="password">密码</label>
        <input 
          type="password" 
          id="password" 
          v-model="password" 
          class="input"
          placeholder="请输入密码"
          @keyup.enter="handleSubmit"
        >
      </div>
      <button class="btn btn-primary" @click="handleSubmit">
        {{ isRegister ? '注册' : '登录' }}
      </button>
      <p class="error-message" v-if="error">{{ error }}</p>
      <p class="switch-mode" @click="isRegister = !isRegister">
        {{ isRegister ? '已有账号？去登录' : '没有账号？去注册' }}
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { Preferences } from '@capacitor/preferences'

const emit = defineEmits(['notify'])

const username = ref('')
const password = ref('')
const error = ref('')
const isRegister = ref(false)

const handleSubmit = async () => {
  error.value = ''
  
  if (!username.value.trim() || !password.value.trim()) {
    error.value = '请输入用户名和密码'
    emit('notify', { message: '请输入用户名和密码', type: 'error' })
    return
  }
  
  if (isRegister.value) {
    await handleRegister()
  } else {
    await handleLogin()
  }
}

const handleRegister = async () => {
  const { value } = await Preferences.get({ key: 'users' })
  const users = value ? JSON.parse(value) : {}
  
  if (users[username.value]) {
    error.value = '用户名已存在'
    emit('notify', { message: '用户名已存在', type: 'error' })
    return
  }
  
  // 保存用户密码
  users[username.value] = password.value
  await Preferences.set({ key: 'users', value: JSON.stringify(users) })
  
  // 保存用户详细信息
  const { value: userInfoData } = await Preferences.get({ key: 'userInfo' })
  const userInfo = userInfoData ? JSON.parse(userInfoData) : {}
  userInfo[username.value] = {
    username: username.value,
    registerTime: new Date().toISOString(),
    lastLoginTime: new Date().toISOString()
  }
  await Preferences.set({ key: 'userInfo', value: JSON.stringify(userInfo) })
  
  emit('notify', { message: '注册成功！', type: 'success' })
  isRegister.value = false
}

const handleLogin = async () => {
  const { value } = await Preferences.get({ key: 'users' })
  const users = value ? JSON.parse(value) : {}
  
  if (users[username.value] === password.value) {
    await Preferences.set({ key: 'currentUser', value: username.value })
    
    // 更新最后登录时间
    const { value: userInfoData } = await Preferences.get({ key: 'userInfo' })
    const userInfo = userInfoData ? JSON.parse(userInfoData) : {}
    if (userInfo[username.value]) {
      userInfo[username.value].lastLoginTime = new Date().toISOString()
      await Preferences.set({ key: 'userInfo', value: JSON.stringify(userInfo) })
    }
    
    emit('notify', { message: '登录成功！', type: 'success' })
    setTimeout(() => {
      window.location.hash = '#/todo'
    }, 300)
  } else {
    error.value = '用户名或密码错误'
    emit('notify', { message: '用户名或密码错误', type: 'error' })
  }
}
</script>

<style scoped>
.debug-panel {
  display: none;
}

.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 1rem;
}

.login-box {
  padding: 2rem;
  width: 100%;
  max-width: 400px;
}

.login-box h2 {
  text-align: center;
  margin-bottom: 2rem;
  background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  font-size: 1.8rem;
  font-weight: 800;
}

.input-group {
  margin-bottom: 1.5rem;
}

.input-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: var(--text-light);
  font-size: 0.9rem;
}

.btn-primary {
  width: 100%;
  padding: 0.9rem;
  font-size: 1rem;
  margin-top: 1rem;
  border-radius: 12px;
}

.error-message {
  color: var(--error-color);
  text-align: center;
  margin-top: 1rem;
  font-size: 0.9rem;
  font-weight: 500;
}

.switch-mode {
  text-align: center;
  margin-top: 1rem;
  color: var(--primary-color);
  cursor: pointer;
  font-size: 0.9rem;
  text-decoration: underline;
}

.switch-mode:hover {
  opacity: 0.8;
}
</style>