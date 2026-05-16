import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import zhCn from 'element-plus/dist/locale/zh-cn.mjs'
import 'element-plus/dist/index.css'
import router from './router'
import App from './App.vue'
import { authDirective } from '@/composables/usePermission'

// ── 全局错误处理器：所有未捕获 JS 错误同时打印到控制台（调试用）────

const app = createApp(App)

// Register all Element Plus icons
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

const pinia = createPinia()
app.use(pinia)
app.use(router)
app.use(ElementPlus, { locale: zhCn })

// Register permission directive v-auth="['perm1', 'perm2']"
app.directive('auth', authDirective)

// ── Auth guard: redirect to login if no token ──
const rawToken = localStorage.getItem('token')
if (!rawToken) {
  router.replace('/login')
}

// ── Global error handler: ALL uncaught JS errors (setTimeout/Promise/Script/iframe) ──
window.addEventListener('error', (event) => {
  const msg = String(event.message || '')
  // Skip known benign browser messages
  if (msg.includes('ResizeObserver') || msg.includes('Non-Error')) return
  const stack = event.error?.stack ? event.error.stack.slice(0, 500) : ''
  const level = (event.lineno === 0 && event.colno === 0) ? 'warn' : 'error'
  fetch('/api/v1/frontend-logs', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      level,
      message: `[GlobalError] ${msg}`,
      stack,
      url: window.location.href,
      ua: navigator.userAgent,
      userId: localStorage.getItem('userId') || null
    })
  }).catch(() => {})
  // 调试：同时打印到控制台，暴露被吞掉的错误
  console.error(`[GlobalError] ${msg}`, stack)
}, false)

app.mount('#app')
