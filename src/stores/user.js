import { defineStore } from 'pinia'
import request from '@/utils/request'
import { setAuthConfirmed } from '@/utils/request'
import { ElMessage } from 'element-plus'

export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem('token') || '',
    userInfo: JSON.parse(localStorage.getItem('userInfo') || '{}'),
    menus: JSON.parse(localStorage.getItem('menus') || '[]')
  }),
  actions: {
    async login(username, password) {
      const res = await request.post('/auth/login', { username, password })
      this.token = res.data.token
      this.userInfo = res.data.user
      localStorage.setItem('token', this.token)
      localStorage.setItem('userInfo', JSON.stringify(this.userInfo))
      setAuthConfirmed(true)  // mark auth ready before any API call
      return res
    },
    logout() {
      this.token = ''
      this.userInfo = {}
      this.menus = []
      localStorage.removeItem('token')
      localStorage.removeItem('userInfo')
      localStorage.removeItem('menus')
      setAuthConfirmed(false)
    }
  }
})