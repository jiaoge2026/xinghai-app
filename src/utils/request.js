import axios from 'axios'
import { ElMessage } from 'element-plus'
import router from '@/router'

const request = axios.create({
  baseURL: '/api',
  timeout: 30000
})

// Track whether router has confirmed auth state
let authConfirmed = false

// Call this from router after token check passes
export const setAuthConfirmed = (v) => { authConfirmed = v }

// Block requests until auth is confirmed by router guard
request.interceptors.request.use(config => {
  if (!authConfirmed) {
    // Token exists in localStorage but router hasn't cleared the guard yet
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
      ElMessage.error(res.message || '请求失败')
      return Promise.reject(res)
    }
    return res
  },
  error => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      authConfirmed = false
      router.push('/login')
      ElMessage.error('登录已过期，请重新登录')
    } else if (error.response?.status === 403) {
      // 403 on refresh: auth confirmed=false → token existed but backend rejected
      // Don't show error toast, let router guard redirect silently
      return Promise.reject(error)
    } else {
      ElMessage.error(error.response?.data?.message || '网络异常')
    }
    return Promise.reject(error)
  }
)

export default request
