<template>
  <div class="layout-container" :class="{ 'is-collapsed': isCollapsed }">

    <!-- ========== 侧边栏 ========== -->
    <aside class="ls-sidebar" :class="{ 'is-collapsed': isCollapsed }">
      <!-- Logo区 -->
      <div class="ls-logo">
        <div class="ls-logo-icon">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
            <rect x="3" y="3" width="8" height="8" rx="2" fill="white"/>
            <rect x="13" y="3" width="8" height="8" rx="2" fill="white" opacity="0.6"/>
            <rect x="3" y="13" width="8" height="8" rx="2" fill="white" opacity="0.6"/>
            <rect x="13" y="13" width="8" height="8" rx="2" fill="white" opacity="0.3"/>
          </svg>
        </div>
        <transition name="ls-label-fade">
          <span v-if="!isCollapsed" class="ls-logo-text">星海ERP</span>
        </transition>
      </div>

      <!-- 导航区 -->
      <div class="ls-nav">
        <template v-for="menu in userStore.filteredMenus" :key="menu.id">
          <!-- 有子菜单：hover显示悬浮面板 -->
          <template v-if="menu.children && menu.children.length">
            <div
              class="ls-item ls-item--group"
              :class="{ 'is-open': openGroups.includes(menu.path) }"
              :data-path="menu.path"
              @click="showPanel(menu, $event)"
              @mouseenter="showPanel(menu, $event)"
            >
              <div class="ls-item-row">
                <el-icon class="ls-item-icon" :size="16"><component :is="getIcon(menu.icon)" /></el-icon>
                <transition name="ls-label-fade">
                  <span v-if="!isCollapsed">{{ menu.name }}</span>
                </transition>
              </div>
              <transition name="ls-label-fade">
                <el-icon v-if="!isCollapsed" class="ls-item-arrow" :size="12"><ArrowRight /></el-icon>
              </transition>
            </div>
          </template>
          <!-- 无子菜单 -->
          <div
            v-if="!menu.children || !menu.children.length"
            class="ls-item"
            :class="{ 'is-active': currentPath === menu.path }"
            :data-path="menu.path"
            @click="handleNavClick(menu.path)"
          >
            <el-icon class="ls-item-icon" :size="16"><component :is="getIcon(menu.icon)" /></el-icon>
            <transition name="ls-label-fade">
              <span v-if="!isCollapsed" class="ls-item-row">{{ menu.name }}</span>
            </transition>
          </div>
        </template>
      </div>

      <!-- 底部折叠按钮 -->
      <div class="ls-footer">
        <div
          class="ls-item ls-item--toggle"
          @click="toggleCollapse"
        >
          <el-icon class="ls-item-icon" :size="16">
            <DArrowLeft v-if="!isCollapsed" />
            <DArrowRight v-else />
          </el-icon>
          <transition name="ls-label-fade">
            <span v-if="!isCollapsed">收起</span>
          </transition>
        </div>
      </div>
    </aside>

    <!-- ========== 主区域 ========== -->
    <div class="layout-main-wrapper">
      <!-- 顶栏 -->
      <header class="layout-header">
        <div class="header-left">
          <div class="logo-area">
            <div class="logo-icon">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                <rect x="3" y="3" width="8" height="8" rx="2" fill="#5e6ad2"/>
                <rect x="13" y="3" width="8" height="8" rx="2" fill="#5e6ad2" opacity="0.6"/>
                <rect x="3" y="13" width="8" height="8" rx="2" fill="#5e6ad2" opacity="0.6"/>
                <rect x="13" y="13" width="8" height="8" rx="2" fill="#5e6ad2" opacity="0.3"/>
              </svg>
            </div>
            <span class="logo-text">星海ERP</span>
          </div>
          <div class="header-divider"></div>
          <span class="page-title">{{ currentTitle }}</span>
        </div>
        <div class="header-right">
          <!-- 账套切换 -->
          <el-dropdown trigger="click" @command="userStore.setAccountType">
            <span class="account-btn">
              <el-icon :size="13"><OfficeBuilding /></el-icon>
              {{ userStore.accountType === 'BUSINESS' ? '业务' : '财务' }}
              <el-icon :size="11"><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="BUSINESS" :disabled="userStore.accountType === 'BUSINESS'">
                  <el-icon><Grid /></el-icon> 业务端
                </el-dropdown-item>
                <el-dropdown-item command="FINANCE" :disabled="userStore.accountType === 'FINANCE'">
                  <el-icon><Money /></el-icon> 财务端
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
          <div class="header-sep"></div>
          <!-- 用户 -->
          <el-dropdown trigger="click" @command="handleCommand">
            <span class="user-chip">
              <el-icon :size="13"><UserFilled /></el-icon>
              {{ userStore.userInfo?.realName || '管理员' }}
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </header>

      <!-- 标签栏 -->
      <TabBar />

      <!-- 内容区 -->
      <main class="layout-main">
        <router-view />
      </main>
    </div>

    <!-- ========== 悬浮面板（3列卡片网格） ========== -->
    <transition name="flat-fade">
      <div
        v-if="activePanel"
        class="flat-panel"
        @mouseover="hoverPanel"
        @mouseleave="leavePanel"
        @click.stop
      >
        <div class="flat-panel-header">
          <el-icon class="flat-panel-icon" :size="20" color="#7170ff"><component :is="getIcon(activePanel.icon)" /></el-icon>
          <span class="flat-panel-title">{{ activePanel.name }}</span>
          <span class="flat-panel-hint">{{ activePanel.children?.length || 0 }} 个功能</span>
          <el-icon class="flat-panel-close" :size="14" @click="closePanel"><Close /></el-icon>
        </div>
        <div class="flat-panel-grid">
          <div
            v-for="child in (activePanel.children || [])"
            :key="child.path"
            class="flat-item"
            :class="{ 'is-active': currentPath === child.path }"
            @click="handlePanelClick(child.path)"
          >
            <div class="flat-item-icon">
              <el-icon :size="18"><component :is="getIcon(child.icon || activePanel.icon)" /></el-icon>
            </div>
            <div class="flat-item-info">
              <div class="flat-item-name">{{ child.name }}</div>
              <div class="flat-item-desc">功能模块</div>
            </div>
          </div>
        </div>
      </div>
    </transition>

  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import TabBar from '@/components/tab/TabBar.vue'
import {
  // 导航图标
  ArrowDown, ArrowRight, DArrowLeft, DArrowRight, Close,
  // 业务模块图标
  DataAnalysis, Grid, OfficeBuilding, Money, UserFilled,
  Tools, Box, Van, Shop, Postcard, CreditCard,
  Phone, CircleCheck, DataBoard, Setting, ChatDotSquare,
  MessageBox, Upload, Document, List, Location, Coin,
  DataLine, Connection,
  // 子菜单图标
  User, Briefcase, ShoppingBag, Tickets, Collection,
  TrendCharts, PriceTag, Histogram, PieChart, Timer,
  Calendar, Guide, Search, Bell, Memo, Promotion,
  Medal, Trophy, Compass, Stamp,
} from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

// 折叠状态
const isCollapsed = ref(false)

// 当前路由
const currentPath = computed(() => route.path)
const currentTitle = computed(() => {
  const nameMap = {
    '/dashboard': '驾驶舱',
    '/fsm/work-orders': '工单管理',
    '/wms/parts': '配件管理',
    '/wms/warehouses': '仓库管理',
    '/wms/inventory': '库存查询',
    '/sales/customer': '客户管理',
    '/sales/opportunity': '商机管理',
    '/sales/quote': '报价管理',
    '/retail/pos': '零售收银',
    '/crm/contacts': '联系人',
    '/finance/vouchers': '凭证管理',
    '/hr/employees': '员工管理',
    '/system/settings': '系统设置',
  }
  return nameMap[currentPath.value] || '星海ERP'
})

// 展开的分组
const openGroups = ref([])

// 悬浮面板
const activePanel = ref(null)
let hoverTimer = null

// 图标映射
const iconMap = {
  // 导航
  ArrowDown, ArrowRight, DArrowLeft, DArrowRight, Close,
  // 业务模块一级
  DataAnalysis, Grid, OfficeBuilding, Money, UserFilled,
  Tools, Box, Van, Shop, Postcard, CreditCard,
  Phone, CircleCheck, DataBoard, Setting, ChatDotSquare,
  MessageBox, Upload, Document, List, Location, Coin,
  DataLine, Connection,
  // 子菜单图标
  User, Briefcase, ShoppingBag, Tickets, Collection,
  TrendCharts, PriceTag, Histogram, PieChart, Timer,
  Calendar, Guide, Search, Bell, Memo, Promotion,
  Medal, Trophy, Compass, Stamp,
}

function getIcon(name) {
  const icon = iconMap[name]
  if (icon) return icon
  // 兜底：尝试 Element Plus 原名注册
  const ep = name && name.charAt(0).toUpperCase() + name.slice(1)
  return iconMap[ep] ? iconMap[ep] : Grid
}

// 悬浮面板显示
function showPanel(menu, e) {
  if (!menu.children?.length) return
  e?.stopPropagation()
  clearTimeout(hoverTimer)
  activePanel.value = menu
  openGroups.value = []
}

function hoverPanel() {
  clearTimeout(hoverTimer)
}

function leavePanel() {
  clearTimeout(hoverTimer)
  hoverTimer = setTimeout(() => {
    activePanel.value = null
  }, 200)
}

// 切换分组展开/收起
function toggleGroup(path) {
  if (isCollapsed.value) {
    toggleCollapse()
    return
  }
  const idx = openGroups.value.indexOf(path)
  if (idx >= 0) {
    openGroups.value.splice(idx, 1)
  } else {
    openGroups.value.push(path)
  }
}

// 导航点击
function handleNavClick(path) {
  if (!path) return
  router.push(path)
  closePanel()
}

// 面板点击
function handlePanelClick(path) {
  if (!path) return
  router.push(path)
  closePanel()
}

// 折叠
function toggleCollapse() {
  isCollapsed.value = !isCollapsed.value
  if (isCollapsed.value) {
    closePanel()
    openGroups.value = []
  }
}

// 关闭面板
function closePanel() {
  clearTimeout(hoverTimer)
  activePanel.value = null
  openGroups.value = []
}

onMounted(() => {
  // 点击主内容区关闭面板（不在侧边栏区域）
  const mainArea = document.querySelector('.layout-main')
  if (mainArea) {
    mainArea.addEventListener('click', () => {
      if (activePanel.value) closePanel()
    })
  }
})

// 路由变化关闭面板
watch(() => route.path, () => closePanel())

// 账套切换时关闭面板
watch(() => userStore.accountType, () => closePanel())

// 指令处理
function handleCommand(cmd) {
  if (cmd === 'logout') {
    userStore.logout()
    router.push('/login')
  }
}
</script>

<style scoped>
/* ========== 布局容器 ========== */
.layout-container {
  --sidebar-w: 220px;
  --sidebar-collapsed-w: 56px;
  --header-h: 52px;
  --tabbar-h: 40px;
  --ls-bg: #0f1011;
  --ls-surface: #191a1b;
  --ls-elevated: #28282c;
  --ls-border: rgba(255,255,255,.06);
  --ls-border-std: rgba(255,255,255,.08);
  --ls-text-pri: #f7f8f8;
  --ls-text-sec: #d0d6e0;
  --ls-text-ter: #8a8f98;
  --ls-text-muted: #62666d;
  --ls-accent: #7170ff;
  --ls-accent-bg: rgba(113,112,255,.15);

  display: flex;
  height: 100vh;
  overflow: hidden;
  font-family: Inter, system-ui, -apple-system, sans-serif;
}

/* ========== 侧边栏 ========== */
.ls-sidebar {
  width: var(--sidebar-w);
  background: var(--ls-bg);
  border-right: 1px solid var(--ls-border);
  display: flex;
  flex-direction: column;
  flex-shrink: 0;
  overflow: hidden;
  transition: width .22s cubic-bezier(.4,0,.2,1);
  position: relative;
  z-index: 100;
}
.ls-sidebar.is-collapsed {
  width: var(--sidebar-collapsed-w);
}

/* ========== Logo区 ========== */
.ls-logo {
  height: var(--header-h);
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 16px;
  border-bottom: 1px solid var(--ls-border);
  flex-shrink: 0;
  overflow: hidden;
}
.ls-logo-icon {
  width: 28px;
  height: 28px;
  background: var(--ls-accent);
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: #fff;
}
.ls-logo-text {
  color: var(--ls-text-pri);
  font-size: 14px;
  font-weight: 590;
  letter-spacing: -.01em;
  white-space: nowrap;
}

/* ========== 导航区 ========== */
.ls-nav {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  padding: 8px 0;
}
.ls-nav::-webkit-scrollbar { width: 4px; }
.ls-nav::-webkit-scrollbar-track { background: transparent; }
.ls-nav::-webkit-scrollbar-thumb { background: #ffffff14; border-radius: 2px; }

/* ========== 菜单项 ========== */
.ls-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 0 8px;
  height: 34px;
  border-radius: 6px;
  margin: 1px 8px;
  cursor: pointer;
  color: var(--ls-text-ter);
  font-size: 13px;
  font-weight: 510;
  letter-spacing: -.01em;
  transition: background .1s, color .1s;
  white-space: nowrap;
  user-select: none;
}
.ls-item-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex: 1;
  min-width: 0;
  overflow: hidden;
}
.ls-item:hover {
  background: #ffffff0d;
  color: var(--ls-text-sec);
}
.ls-item.is-active {
  background: var(--ls-accent-bg);
  color: var(--ls-text-pri);
}
.ls-item.is-active .ls-item-icon {
  color: var(--ls-accent);
}

.ls-item--group {
  font-size: 12px;
  font-weight: 590;
  letter-spacing: .01em;
  text-transform: uppercase;
  color: var(--ls-text-ter);
}
.ls-item--group:hover {
  color: var(--ls-text-sec);
}
.ls-item--group.is-open .ls-item-arrow {
  transform: rotate(90deg);
}
.ls-item-arrow {
  color: var(--ls-text-muted);
  flex-shrink: 0;
  transition: transform .15s;
}

.ls-item--child {
  height: 30px;
  font-size: 13px;
  font-weight: 400;
  padding-left: 36px;
  color: var(--ls-text-ter);
}
.ls-item--child:hover {
  color: var(--ls-text-sec);
}
.ls-item--child.is-active {
  background: var(--ls-accent-bg);
  color: var(--ls-text-pri);
}
.ls-item--child.is-active .ls-item-icon {
  color: var(--ls-accent);
}

.ls-children {
  overflow: hidden;
  margin-bottom: 2px;
}

.ls-item-icon {
  width: 16px;
  height: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: var(--ls-text-muted);
  transition: color .1s;
}
.ls-item:hover .ls-item-icon {
  color: var(--ls-text-ter);
}

/* ========== 底部 ========== */
.ls-footer {
  padding: 8px 0;
  border-top: 1px solid var(--ls-border);
  flex-shrink: 0;
}
.ls-item--toggle {
  color: var(--ls-text-muted);
  font-size: 12px;
  justify-content: flex-start;
}
.ls-item--toggle:hover {
  color: var(--ls-text-ter);
  background: #ffffff0d;
}

/* ========== 主区域 ========== */
.layout-main-wrapper {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

/* ========== 顶栏 ========== */
.layout-header {
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 16px;
  box-shadow: 0 1px 4px #00000014;
  height: var(--header-h);
  gap: 8px;
  flex-shrink: 0;
}
.header-left {
  display: flex;
  align-items: center;
  gap: 8px;
}
.header-right {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}
.logo-area {
  display: flex;
  align-items: center;
  gap: 8px;
}
.logo-icon {
  width: 28px;
  height: 28px;
  background: linear-gradient(135deg, #5e6ad2, #7170ff);
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.logo-text {
  font-size: 15px;
  font-weight: 600;
  color: #2c2d2e;
  letter-spacing: -.01em;
}
.header-divider {
  width: 1px;
  height: 18px;
  background: #e4e7ed;
}
.page-title {
  font-size: 14px;
  color: #606266;
}
.account-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  border-radius: 6px;
  border: 1px solid rgba(94,106,210,.3);
  color: #7170ff;
  font-size: 13px;
  cursor: pointer;
  transition: all .15s;
}
.account-btn:hover {
  background: rgba(94,106,210,.08);
}
.header-sep {
  width: 1px;
  height: 18px;
  background: #e4e7ed;
}
.user-chip {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 13px;
  color: #606266;
  cursor: pointer;
  transition: background .15s;
}
.user-chip:hover {
  background: #f5f7fa;
}

/* ========== 内容区 ========== */
.layout-main {
  background: #f0f2f5;
  overflow-y: auto;
  height: calc(100vh - var(--header-h) - var(--tabbar-h));
  flex: 1;
  min-height: 0;
}

/* ========== 悬浮面板 ========== */
.flat-panel {
  position: fixed;
  left: var(--sidebar-w);
  top: var(--header-h);
  width: 640px;
  max-height: calc(100vh - var(--header-h));
  overflow-y: auto;
  z-index: 200;
  background: rgba(25,26,27,0.97);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-left: 1px solid rgba(255,255,255,.06);
  border-right: 1px solid rgba(255,255,255,.06);
  box-shadow: 4px 0 32px rgba(0,0,0,.4);
}
.is-collapsed .flat-panel {
  left: var(--sidebar-collapsed-w);
}

.flat-panel::-webkit-scrollbar { width: 4px; }
.flat-panel::-webkit-scrollbar-thumb { background: rgba(255,255,255,.1); border-radius: 2px; }

.flat-panel-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 16px 20px;
  border-bottom: 1px solid rgba(255,255,255,.06);
  position: sticky;
  top: 0;
  background: rgba(25,26,27,.98);
}
.flat-panel-icon {
  color: var(--ls-accent);
}
.flat-panel-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--ls-text-pri);
}
.flat-panel-hint {
  font-size: 12px;
  color: var(--ls-text-ter);
  margin-left: auto;
}
.flat-panel-close {
  color: var(--ls-text-muted);
  cursor: pointer;
  padding: 2px;
  border-radius: 4px;
}
.flat-panel-close:hover {
  color: var(--ls-text-ter);
  background: rgba(255,255,255,.06);
}

.flat-panel-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  padding: 16px 20px;
}

.flat-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  border-radius: 10px;
  cursor: pointer;
  transition: background .15s, border-color .15s;
  border: 1px solid transparent;
  background: rgba(255,255,255,.04);
}
.flat-item:hover {
  background: rgba(113,112,255,.15);
  border-color: rgba(113,112,255,.3);
}
.flat-item.is-active {
  background: rgba(113,112,255,.2);
  border-color: rgba(113,112,255,.4);
}
.flat-item-icon {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background: rgba(113,112,255,.15);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: var(--ls-accent);
}
.flat-item.is-active .flat-item-icon {
  background: rgba(113,112,255,.25);
}
.flat-item-info {
  flex: 1;
  min-width: 0;
}
.flat-item-name {
  font-size: 13px;
  font-weight: 500;
  color: var(--ls-text-pri);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.flat-item-desc {
  font-size: 11px;
  color: var(--ls-text-ter);
  margin-top: 2px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* ========== 过渡动画 ========== */
.ls-label-fade-enter-active,
.ls-label-fade-leave-active {
  transition: opacity .15s, transform .15s;
  overflow: hidden;
}
.ls-label-fade-enter-from,
.ls-label-fade-leave-to {
  opacity: 0;
  transform: translateX(-4px);
}

.ls-children-enter-active,
.ls-children-leave-active {
  transition: max-height .2s ease, opacity .2s;
  max-height: 500px;
  overflow: hidden;
}
.ls-children-enter-from,
.ls-children-leave-to {
  max-height: 0;
  opacity: 0;
}

.flat-fade-enter-active,
.flat-fade-leave-active {
  transition: opacity .2s ease, transform .2s ease;
}
.flat-fade-enter-from,
.flat-fade-leave-to {
  opacity: 0;
  transform: translateX(-8px);
}
</style>
