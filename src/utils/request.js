import axios from 'axios'
import { ElMessage } from 'element-plus'
import router from '@/router'

const request = axios.create({
  baseURL: '/api/v1',
  timeout: 30000
})

// Track whether router has confirmed auth state
let authConfirmed = false

// Call this from router after token check passes
export const setAuthConfirmed = (v) => { authConfirmed = v }

// Report error to backend log table (uses raw axios to avoid interceptor loops)
const reportError = (level, message, stack) => {
  axios.post('/api/v1/frontend-logs', {
    level,
    message,
    stack: stack || '',
    url: window.location.href,
    ua: navigator.userAgent,
    userId: localStorage.getItem('userId') || null
  }).catch(() => {}) //上报失败不阻塞
}

// Block requests until auth is confirmed by router guard
request.interceptors.request.use(config => {
  if (!authConfirmed) {
    const token = localStorage.getItem('token')
    if (token) {
      // Token is there, just wait for router guard (≤ 1 tick)
      return new Promise((resolve) => {
        const unwatch = router.afterEach(() => {
          unwatch()
          authConfirmed = true
          config.headers.Authorization = `Bearer ${token}`
          resolve(config)
        })
        // Safety timeout: if router doesn't fire in 500ms, proceed anyway
        setTimeout(() => {
          unwatch()
          authConfirmed = true
          config.headers.Authorization = `Bearer ${token}`
          resolve(config)
        }, 500)
      })
    }
    // No token: router guard will handle redirect, don't block
    return config
  }
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

request.interceptors.response.use(
  response => {
    const res = response.data
    if (res.code !== 0 && res.code !== 200) {
      // 业务错误 code 非0，也上报
      const msg = res.message || `接口异常[code=${res.code}]`
      reportError('error', `[${response.config.url}] ${msg}`)
      ElMessage.error(msg)
      return Promise.reject(res)
    }
    return res
  },
  error => {
    const status = error.response?.status
    const serverMsg = error.response?.data?.message
    const url = error.config?.url || 'unknown'

    if (status === 401) {
      // If already on login page, don't clear token or redirect — avoid redirect loops
      if (router.currentRoute.value.path === '/login') {
        return Promise.reject(error)
      }
      localStorage.removeItem('token')
      authConfirmed = false
      router.push('/login')
      ElMessage.error('登录已过期，请重新登录')
    } else if (status === 403) {
      reportError('error', `[${url}] 无权限[403] ${serverMsg || ''}`)
      return Promise.reject(error)
    } else if (status === 500) {
      reportError('error', `[${url}] 服务器错误[500] ${serverMsg || ''}`)
      ElMessage.error(serverMsg || '服务器异常')
    } else if (status === 400) {
      reportError('error', `[${url}] 请求参数错误[400] ${serverMsg || ''}`)
      ElMessage.error(serverMsg || '请求参数错误')
    } else if (status) {
      reportError('error', `[${url}] 请求失败[${status}] ${serverMsg || ''}`)
      ElMessage.error(serverMsg || `请求失败[${status}]`)
    } else {
      // 网络错误（断网、超时等）
      reportError('error', `[${url}] 网络异常 ${error.message}`)
      ElMessage.error('网络异常，请检查网络连接')
    }
    return Promise.reject(error)
  }
)

export default request
