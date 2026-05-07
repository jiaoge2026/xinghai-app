import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import zhCn from 'element-plus/dist/locale/zh-cn.mjs'
import 'element-plus/dist/index.css'
import router from './router'
import App from './App.vue'

const app = createApp(App)

// Register all Element Plus icons
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

const pinia = createPinia()
app.use(pinia)
app.use(router)
app.use(ElementPlus, { locale: zhCn })

// ── Auth guard: block API calls until router confirms token ──
// 1. Sync check localStorage token before any component mounts
const rawToken = localStorage.getItem('token')
if (!rawToken) {
  // No token → router guard will redirect to /login immediately
  // Force router to use hash mode so initial render goes to login
  router.replace('/login')
}

app.mount('#app')
