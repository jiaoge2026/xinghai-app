import { defineStore } from 'pinia'
import { setAuthConfirmed } from '@/utils/request'
import { ElMessage } from 'element-plus'

export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem('token') || '',
    userInfo: JSON.parse(localStorage.getItem('userInfo') || '{}'),
    menus: JSON.parse(localStorage.getItem('menus') || '[]'),
    permissions: JSON.parse(localStorage.getItem('permissions') || '[]')
  }),
  getters: {
    isLoggedIn: (state) => !!state.token,
    hasPermission: (state) => (perm) => state.permissions.includes(perm),
    hasAnyPermission: (state) => (perms) => perms.some(p => state.permissions.includes(p))
  },
  actions: {
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
      this.menus = data.data.menus || []
      this.permissions = data.data.permissions || []
      localStorage.setItem('token', this.token)
      localStorage.setItem('userInfo', JSON.stringify(this.userInfo))
      localStorage.setItem('menus', JSON.stringify(this.menus))
      localStorage.setItem('permissions', JSON.stringify(this.permissions))
      setAuthConfirmed(true)
      return data
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
      setAuthConfirmed(false)
    }
  }
})
