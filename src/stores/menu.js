import { defineStore } from 'pinia'

export const useMenuStore = defineStore('menu', {
  state: () => ({
    defaultActive: '',
    menuList: []
  }),
  actions: {
    setActive(path) {
      this.defaultActive = path
    }
  }
})