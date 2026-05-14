import { defineStore } from 'pinia'
import { setAuthConfirmed } from '@/utils/request'
import { ElMessage } from 'element-plus'
import request from '@/utils/request'

export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem('token') || '',
    userInfo: JSON.parse(localStorage.getItem('userInfo') || '{}'),
    menus: JSON.parse(localStorage.getItem('menus') || '[]'),
    permissions: JSON.parse(localStorage.getItem('permissions') || '[]'),
    accountType: localStorage.getItem('accountType') || 'BUSINESS'
  }),
  getters: {
    isLoggedIn: (state) => !!state.token,
    hasPermission: (state) => (perm) => state.permissions.includes(perm),
    hasAnyPermission: (state) => (perms) => perms.some(p => state.permissions.includes(p)),
    // menus 已由后端按账套过滤，直接使用
    filteredMenus: (state) => state.menus
  },
  actions: {
    async fetchMenus() {
      // 调用后端导航菜单接口（自动按用户账套过滤，返回叶子节点）
      const res = await request.get('/system/menus/nav')
      if (res.code === 0) {
        this.menus = res.data || []
        localStorage.setItem('menus', JSON.stringify(this.menus))
      }
    },
    async login(username, password) {
      const res = await fetch('/api/v1/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
      })
      const data = await res.json()
      if (data.code !== 0) {
        ElMessage.error(data.message || '登录失败')
        throw new Error(data.message || '登录失败')
      }
      this.token = data.data.token
      this.userInfo = data.data.user || {}
      this.permissions = data.data.permissions || []
      // 登录响应里已有完整菜单树，直接使用（避免二次请求触发认证拦截）
      this.menus = data.data.menus || []
      localStorage.setItem('token', this.token)
      localStorage.setItem('menus', JSON.stringify(this.menus))
      localStorage.setItem('userInfo', JSON.stringify(this.userInfo))
      localStorage.setItem('permissions', JSON.stringify(this.permissions))
      setAuthConfirmed(true)
      return data
    },
    setAccountType(type) {
      this.accountType = type
      localStorage.setItem('accountType', type)
    },
    logout() {
      this.token = ''
      this.userInfo = {}
      this.menus = []
      this.permissions = []
      localStorage.removeItem('token')
      localStorage.removeItem('userInfo')
      localStorage.removeItem('menus')
      localStorage.removeItem('permissions')
      localStorage.removeItem('accountType')
      setAuthConfirmed(false)
    }
  }
})
