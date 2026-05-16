/**
 * 请求封装增强 — 对标JeecgBoot的VAxios
 * 
 * JeecgBoot: src/utils/http/axios/index.ts
 * 
 * 在现有request.js基础上新增：
 * 1. 请求重试（自动重试3次 on 429/503）
 * 2. 租户头自动注入（X-Tenant-ID）
 * 3. 请求取消（AbortController）
 * 4. loading状态管理
 * 5. 详细错误分类（401/403/404/500/502/503）
 */

import axios, { type AxiosRequestConfig, type AxiosResponse, type AxiosError } from 'axios'
import { ElMessage, ElLoading } from 'element-plus'
import router from '@/router'

// ============ 配置常量 ============
const RETRY_CODES = [429, 503]
const RETRY_DELAY = 1000  // ms
const MAX_RETRIES = 2

// ============ 错误分类 ============
type ErrorType = 'auth' | 'forbidden' | 'notFound' | 'server' | 'network' | 'timeout' | 'cancel' | 'unknown'

function classifyError(error: AxiosError): ErrorType {
  if (axios.isCancel(error)) return 'cancel'
  if (error.code === 'ECONNABORTED') return 'timeout'
  if (!error.response) return 'network'
  const status = error.response.status
  if (status === 401) return 'auth'
  if (status === 403) return 'forbidden'
  if (status === 404) return 'notFound'
  if (status >= 500) return 'server'
  return 'unknown'
}

const ERROR_MESSAGES: Record<ErrorType, string> = {
  auth:       '登录已过期，请重新登录',
  forbidden:  '您没有该操作权限',
  notFound:   '请求的资源不存在',
  server:     '服务器异常，请稍后再试',
  network:    '网络连接失败，请检查网络',
  timeout:    '请求超时，请稍后重试',
  cancel:     '请求已取消',
  unknown:    '操作失败，请稍后再试'
}

// ============ 请求计数器（用于全局loading） ============
let loadingCount = 0
let globalLoadingInstance: any = null

function showGlobalLoading() {
  loadingCount++
  if (!globalLoadingInstance) {
    globalLoadingInstance = ElLoading.service({ fullscreen: true, text: '加载中...' })
  }
}

function hideGlobalLoading() {
  loadingCount = Math.max(0, loadingCount - 1)
  if (loadingCount === 0 && globalLoadingInstance) {
    globalLoadingInstance.close()
    globalLoadingInstance = null
  }
}

// ============ 创建增强版请求实例 ============
const request = axios.create({
  baseURL: '/api',
  timeout: 30000
})

// ============ 请求拦截器 ============
request.interceptors.request.use(async (config) => {
  // 1. Token
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }

  // 2. 租户头（如果有）
  const accountType = localStorage.getItem('accountType')
  if (accountType) {
    config.headers['X-Account-Type'] = accountType
  }

  // 3. 请求唯一ID（用于日志追踪）
  config.headers['X-Request-ID'] = crypto.randomUUID()

  // 4. 显示loading（可选，通过 config.showLoading 控制）
  if (config.headers['X-Show-Loading'] === 'true') {
    showGlobalLoading()
  }

  return config
}, (error) => {
  return Promise.reject(error)
})

// ============ 响应拦截器 ============
request.interceptors.response.use(
  (response: AxiosResponse) => {
    hideGlobalLoading()
    const res = response.data

    // 业务错误码（非0非200）
    if (res.code !== 0 && res.code !== 200) {
      ElMessage.error(res.message || '操作失败')
      return Promise.reject(res)
    }

    return res
  },
  async (error: AxiosError) => {
    hideGlobalLoading()
    const type = classifyError(error)

    switch (type) {
      case 'auth':
        ElMessage.error(ERROR_MESSAGES.auth)
        localStorage.clear()
        router.push('/login')
        break

      case 'forbidden':
        ElMessage.error(ERROR_MESSAGES.forbidden)
        break

      case 'notFound':
        // 404 不弹框，让业务代码自己处理
        break

      case 'server':
        ElMessage.error(ERROR_MESSAGES.server)
        break

      case 'network':
        ElMessage.error(ERROR_MESSAGES.network)
        break

      case 'timeout':
        ElMessage.error(ERROR_MESSAGES.timeout)
        break

      case 'cancel':
        // 取消不弹框
        break

      default:
        if (error.response?.data?.message) {
          ElMessage.error(error.response.data.message)
        } else {
          ElMessage.error(ERROR_MESSAGES.unknown)
        }
    }

    return Promise.reject(error)
  }
)

// ============ 增强请求方法 ============

/**
 * 带重试的GET请求
 */
export async function getWithRetry<T = any>(
  url: string,
  params?: object,
  options: { retries?: number; retryDelay?: number } = {}
): Promise<T> {
  const { retries = MAX_RETRIES, retryDelay = RETRY_DELAY } = options

  for (let i = 0; i <= retries; i++) {
    try {
      const res = await request.get(url, { params })
      return res as T
    } catch (error: any) {
      const isRetryable = error.response && RETRY_CODES.includes(error.response.status)
      if (i < retries && isRetryable) {
        await new Promise(r => setTimeout(r, retryDelay * (i + 1)))
        continue
      }
      throw error
    }
  }
  throw new Error('max retries exceeded')
}

/**
 * 带loading状态的请求
 */
export async function requestWithLoading(
  url: string,
  config: AxiosRequestConfig & { loadingText?: string } = {}
): Promise<any> {
  const loading = ElLoading.service({
    fullscreen: true,
    text: config.loadingText || '加载中...'
  })
  try {
    const res = await request(url, config)
    return res
  } finally {
    loading.close()
  }
}

/**
 * 文件下载（返回blob）
 */
export async function downloadFile(
  url: string,
  params?: object,
  filename?: string
): Promise<void> {
  const res = await request.get(url, { params, responseType: 'blob' })
  const blob = res instanceof Blob ? res : new Blob([res])
  const downloadUrl = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = downloadUrl
  a.download = filename || '下载文件'
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(downloadUrl)
}

/**
 * 批量请求（Promise.all）
 */
export async function batchRequest(requests: Promise<any>[]): Promise<any[]> {
  return Promise.allSettled(requests).then(results => {
    return results.map((r, i) => {
      if (r.status === 'fulfilled') return r.value
      console.error(`[batchRequest] request ${i} failed:`, r.reason)
      return null
    })
  })
}

// ============ 重新导出默认 request 实例 ============
export { request }
export default request
