// ===== 本地存储 =====
// TabStore - 标签页状态管理 (Linear Design版本)
import { reactive, computed } from 'vue'

let tabIdCounter = 1  // 用于刷新时生成新tab ID

const state = reactive({
  tabs: [],       // [{ id, title, path, component, closable }]
  activeTabId: null,
})

const saveActiveTabId = () => {
  try {
    localStorage.setItem('activeTabId', state.activeTabId || '')
  } catch (e) {}
}

const loadActiveTabId = () => {
  try {
    const saved = localStorage.getItem('activeTabId')
    if (saved) state.activeTabId = saved
  } catch (e) {}
}

const save = () => {
  try {
    const data = state.tabs.map(t => ({ id: t.id, title: t.title, path: t.path, name: t.name, closable: t.closable }))
    localStorage.setItem('tabs', JSON.stringify(data))
    localStorage.setItem('activeTabId', state.activeTabId || '')
  } catch (e) {}
}

const saveTabs = () => {
  save()
}

const loadTabs = () => {
  try {
    const saved = localStorage.getItem('tabs')
    if (saved) {
      const data = JSON.parse(saved)
      state.tabs = data
      state.activeTabId = data[0]?.id || null
    }
  } catch (e) {}
}

// 初始加载
loadTabs()
loadActiveTabId()

export const newTabId = () => tabIdCounter++

// 组件映射表（从 tab.js 加载）
let COMPONENT_MAP = {}

export const loadComponentMap = (map) => {
  COMPONENT_MAP = map
}

// ===== 命名导出（供 router/其他模块使用）=====
export const addTab = (tab) => {
  const existing = state.tabs.find(t => t.path === tab.path)
  if (existing) {
    state.activeTabId = existing.id
    saveActiveTabId()
    return existing
  }
  const newTab = {
    id: tab.path,
    title: tab.title || tab.name || '未命名',
    path: tab.path,
    name: tab.name,
    closable: tab.closable !== false,
    ...tab,
  }
  state.tabs.push(newTab)
  state.activeTabId = newTab.id
  saveTabs()
  saveActiveTabId()
  return newTab
}
export const removeTab = (tabId) => {
  const idx = state.tabs.findIndex(t => t.id === tabId)
  if (idx === -1) return
  const wasActive = state.activeTabId === tabId
  state.tabs.splice(idx, 1)
  if (wasActive) {
    const next = state.tabs.find(t => t.id === '/dashboard') || state.tabs[0]
    state.activeTabId = next ? next.id : '/dashboard'
  }
  saveTabs()
}
export const clearTabs = () => {
  state.tabs = state.tabs.filter(t => t.path === '/' || t.path === '/dashboard')
  state.activeTabId = state.tabs[0]?.id || null
  saveTabs()
}
export const getTabs = () => state.tabs
export const getActiveTabId = () => state.activeTabId
export const setActiveTab = (tabId) => { state.activeTabId = tabId; saveActiveTabId() }

export const useTabStore = () => {
  const addTab = (tab) => {
    const existing = state.tabs.find(t => t.path === tab.path)
    if (existing) {
      state.activeTabId = existing.id
      return existing
    }
    const newTab = {
      id: tab.path,
      title: tab.title || tab.name || '未命名',
      path: tab.path,
      name: tab.name,
      closable: tab.closable !== false,
      ...tab,
    }
    state.tabs.push(newTab)
    state.activeTabId = newTab.id
    saveTabs()
    return newTab
  }

  const closeTab = (tabId) => {
    const idx = state.tabs.findIndex(t => t.id === tabId)
    if (idx === -1) return
    const wasActive = state.activeTabId === tabId
    state.tabs.splice(idx, 1)
    // 如果关闭的是当前激活的 Tab，切换到剩余的任一 Tab（优先找 Dashboard）
    if (wasActive) {
      const next = state.tabs.find(t => t.id === '/dashboard') || state.tabs[0]
      state.activeTabId = next ? next.id : '/dashboard'
    }
    saveTabs()
  }

  const setActiveTab = (tabId) => {
    state.activeTabId = tabId
    saveActiveTabId()
  }

  const getActiveTab = () => {
    return state.tabs.find(t => t.id === state.activeTabId)
  }

  const closeActiveTab = () => {
    const id = state.activeTabId
    if (id !== null) {
      closeTab(id)
    }
  }

  const closeOtherTabs = (keepId) => {
    state.tabs = state.tabs.filter(t => t.id === keepId)
    if (state.activeTabId !== keepId) {
      state.activeTabId = keepId
    }
    save()
  }

  const switchTab = (tabId) => {
    state.activeTabId = tabId
    saveActiveTabId()
  }

  const clearTabs = () => {
    // 保留首页 tab
    state.tabs = state.tabs.filter(t => t.path === '/' || t.path === '/dashboard')
    state.activeTabId = state.tabs[0]?.id || null
    save()
  }

  return {
    // 直接引用state属性（脚本中可读写，如 tabs.splice()）
    tabs: state.tabs,
    // 用getter函数代替快照，保证总是读到最新响应式值
    get activeTabId() { return state.activeTabId },
    // 计算属性（模板中自动解包，保持响应式）
    tabsComputed: computed(() => state.tabs),
    activeTabIdComputed: computed(() => state.activeTabId),
    addTab,
    closeTab,
    closeActiveTab,
    closeOtherTabs,
    setActiveTab,
    switchTab,
    getActiveTab,
    clearTabs,
    newTabId,
  }
}
