import { createRouter, createWebHashHistory } from 'vue-router'
import LoginView from '../views/LoginView.vue'
import TodoView from '../views/TodoView.vue'
import { useOfflineUserStore } from '../stores/offlineUserStore'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    {
      path: '/',
      name: 'login',
      component: LoginView
    },
    {
      path: '/todo',
      name: 'todo',
      component: TodoView,
      meta: { requiresAuth: true }
    }
  ]
})

// 路由守卫：检查登录状态
router.beforeEach(async (to, from, next) => {
  const userStore = useOfflineUserStore()
  
  // 首次加载时检查本地存储的登录状态
  if (!userStore.isLoggedIn) {
    await userStore.checkLogin()
  }
  
  // 如果目标路由需要登录且用户未登录，跳转到登录页
  if (to.meta.requiresAuth && !userStore.isLoggedIn) {
    next({ name: 'login' })
  }
  // 如果已登录且访问登录页，跳转到待办页
  else if (to.name === 'login' && userStore.isLoggedIn) {
    next({ name: 'todo' })
  }
  else {
    next()
  }
})

export default router