<template>
  <el-container class="layout-container">

    <!-- ==================== 顶部栏 ==================== -->
    <el-header class="layout-header">
      <div class="header-left">
        <div class="logo-area">
          <div class="logo-icon">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
              <rect x="3" y="3" width="8" height="8" rx="2" fill="#409EFF"/>
              <rect x="13" y="3" width="8" height="8" rx="2" fill="#409EFF" opacity="0.6"/>
              <rect x="3" y="13" width="8" height="8" rx="2" fill="#409EFF" opacity="0.6"/>
              <rect x="13" y="13" width="8" height="8" rx="2" fill="#409EFF" opacity="0.3"/>
            </svg>
          </div>
          <span class="logo-text">星海ERP</span>
        </div>
        <div class="header-divider"></div>
        <span class="page-title">{{ currentTitle }}</span>
      </div>

      <div class="header-right">
        <!-- 模式切换 -->
        <div class="mode-toggle">
          <button
            :class="['mode-btn', { active: !isTiledMode }]"
            @click="setMode(false)"
            title="经典模式"
          >
            <el-icon :size="14"><Grid /></el-icon>
            <span>经典</span>
          </button>
          <button
            :class="['mode-btn', { active: isTiledMode }]"
            @click="setMode(true)"
            title="平铺模式"
          >
            <el-icon :size="14"><Menu /></el-icon>
            <span>平铺</span>
          </button>
        </div>

        <div class="header-sep"></div>

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
    </el-header>

    <!-- ==================== 标签栏（始终显示） ==================== -->
    <TabBar />

    <!-- ==================== 主区域 ==================== -->
    <el-container class="main-area">

      <!-- 左侧导航 -->
      <transition name="sidebar-collapse">
        <el-aside class="layout-aside" :style="{ width: asideWidth + 'px' }">

          <!-- ===== 经典模式：el-menu ===== -->
          <el-menu
            v-if="!isTiledMode"
            :default-active="activeMenuPath"
            :collapse="false"
            router
            class="sidebar-menu"
          >
            <el-menu-item index="/dashboard" class="dashboard-item">
              <el-icon><DataAnalysis /></el-icon>
              <template #title>驾驶舱</template>
            </el-menu-item>

            <template v-for="menu in userStore.filteredMenus" :key="menu.id">
              <el-sub-menu v-if="menu.children?.length" :index="menu.path || String(menu.id)">
                <template #title>
                  <el-icon><component :is="getIcon(menu.icon)" /></el-icon>
                  <span>{{ menu.name }}</span>
                </template>
                <el-menu-item
                  v-for="child in menu.children"
                  :key="child.id"
                  :index="child.path"
                  :disabled="!hasPermission(child)"
                >
                  {{ child.name }}
                </el-menu-item>
              </el-sub-menu>
              <el-menu-item
                v-else
                :index="menu.path"
                :disabled="!hasPermission(menu)"
              >
                <el-icon><component :is="getIcon(menu.icon)" /></el-icon>
                <template #title>{{ menu.name }}</template>
              </el-menu-item>
            </template>
          </el-menu>

          <!-- ===== 平铺模式：图标栏 ===== -->
          <div v-else class="icon-sidebar" @mouseleave="onSidebarLeave">
            <!-- 图标列表 -->
            <div
              v-for="item in navItems"
              :key="item.path"
              class="nav-icon-item"
              :class="{ active: hoveredNav === item.path }"
              @mouseenter="onNavHover(item)"
            >
              <el-tooltip :content="item.name" placement="right" :show-after="200">
                <div class="nav-icon-inner">
                  <el-icon :size="18"><component :is="getIcon(item.icon)" /></el-icon>
                </div>
              </el-tooltip>
            </div>

            <!-- hover展开面板（定位在图标栏右侧） -->
            <transition name="panel-slide">
              <div
                v-if="hoveredNav && activePanel"
                class="expand-panel"
                @mouseenter="cancelLeaveTimer"
                @mouseleave="onSidebarLeave"
              >
                <div class="panel-header">
                  <el-icon :size="16" :color="'#409EFF'"><component :is="getIcon(activePanel.icon)" /></el-icon>
                  <span class="panel-title">{{ activePanel.name }}</span>
                </div>

                <!-- 无子菜单：直接跳转 -->
                <div
                  v-if="!activePanel.children?.length"
                  class="panel-direct"
                  @click="navigateTo(activePanel.path, activePanel.name)"
                >
                  <el-icon><ArrowRight /></el-icon>
                  <span>进入 {{ activePanel.name }}</span>
                </div>

                <!-- 有子菜单：网格卡片 -->
                <div v-else class="panel-grid">
                  <div
                    v-for="child in activePanel.children"
                    :key="child.path"
                    class="panel-card"
                    :class="{ 'is-active': currentPath === child.path }"
                    @click="navigateTo(child.path, child.name)"
                  >
                    <div class="card-icon-wrap">
                      <el-icon :size="16" color="#409EFF"><ArrowRight /></el-icon>
                    </div>
                    <div class="card-text">
                      <div class="card-name">{{ child.name }}</div>
                    </div>
                  </div>
                </div>
              </div>
            </transition>
          </div>
        </el-aside>
      </transition>

      <!-- 主内容 -->
      <el-main class="layout-main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useTabStore } from '@/stores/tab'
import TabBar from '@/components/tab/TabBar.vue'
import {
  DataAnalysis, Grid, Menu, UserFilled, ArrowRight,
  ArrowDown, OfficeBuilding, Money, Setting, Tools, Box,
  Guide, User, Shop, Medal, Van, Phone, Stamp,
  CircleCheck, ChatDotRound, Connection, Box as BoxIcon
} from '@element-plus/icons-vue'

const userStore = useUserStore()
const tabStore = useTabStore()
const router = useRouter()
const route = useRoute()

// ========== 模式控制 ==========
const STORAGE_KEY = 'xinghai_layout_mode'
const isTiledMode = ref(localStorage.getItem(STORAGE_KEY) === 'tiled')

function setMode(tiled) {
  isTiledMode.value = tiled
  localStorage.setItem(STORAGE_KEY, tiled ? 'tiled' : 'classic')
}

// ========== 侧边栏宽度 ==========
const asideWidth = computed(() => isTiledMode.value ? 56 : 220)

// ========== 权限 ==========
const isSuperAdmin = computed(() => userStore.userInfo?.username === 'admin')
function hasPermission(menu) {
  if (isSuperAdmin.value) return true
  if (!menu.permissionCode) return true
  return userStore.permissions?.includes(menu.permissionCode) ?? true
}

// ========== 图标映射 ==========
const iconMap = {
  Tools, Box: BoxIcon, Guide, Money, User, UserFilled, Shop, Medal, Van, Phone,
  Stamp, CircleCheck, Setting, ChatDotRound, Connection
}
function getIcon(name) {
  return iconMap[name] || Setting
}

// ========== 当前路由 ==========
const currentPath = computed(() => route.path)
const activeMenuPath = computed(() => route.path)

const routeNameMap = {
  '/dashboard': '驾驶舱',
  '/fsm/work-orders': '工单管理',
  '/wms/parts': '配件管理',
  '/wms/warehouses': '仓库管理',
  '/wms/stock': '库存台账',
  '/finance/vouchers': '凭证管理',
  '/finance/reports': '财务报表',
  '/hr/employees': '员工管理',
  '/hr/attendance': '考勤管理',
  '/hr/salary': '薪资管理',
  '/hr/commission': '提成管理',
  '/crm/customers': '客户管理',
  '/crm/contacts': '联系人管理',
  '/retail/orders': '销售订单',
  '/retail/products': '商品管理',
  '/retail/stores': '门店管理',
  '/member/members': '会员管理',
  '/logistics/drivers': '司机管理',
  '/logistics/delivery': '配送单',
  '/callcenter/records': '来电记录',
  '/qa/inspections': '质量检查',
  '/qa/feedback': '客户反馈',
  '/approval/list': '审批流程',
  '/approval/definition': '流程模板',
  '/system/users': '用户管理',
  '/system/roles': '角色管理',
  '/system/menus': '权限管理',
  '/system/role-config': '角色配置',
  '/system/config': '系统配置',
  '/system/upgrade': '升级管理',
  '/ai/chat': 'AI助手',
  '/dispatch/board': '智能派工',
  '/sales/customers': '工程客户',
  '/sales/quotes': '报价单',
  '/sales/project-orders': '项目订单',
  '/sales/receivables': '应收款',
  '/haier/sync': '海尔同步',
  '/haier/accounts': '海尔账号',
  '/haier/logs': '同步日志',
  '/report/work-orders': '工单报表',
}
const currentTitle = computed(() => routeNameMap[route.path] || route.meta?.title || '星海ERP')

// ========== 平铺模式导航 ==========
const hoveredNav = ref(null)
const activePanel = ref(null)
let leaveTimer = null

// 构建平铺导航项
const navItems = computed(() => {
  const items = [{ path: '/dashboard', name: '驾驶舱', icon: 'DataAnalysis', path: '/dashboard' }]
  userStore.filteredMenus.forEach(menu => {
    if (hasPermission(menu)) {
      items.push({
        path: menu.path,
        name: menu.name,
        icon: menu.icon,
        children: menu.children?.filter(c => hasPermission(c)) || []
      })
    }
  })
  return items
})

function onNavHover(item) {
  cancelLeaveTimer()
  hoveredNav.value = item.path
  activePanel.value = item
}

function onSidebarLeave() {
  leaveTimer = setTimeout(() => {
    hoveredNav.value = null
    activePanel.value = null
  }, 180)
}

function cancelLeaveTimer() {
  if (leaveTimer) {
    clearTimeout(leaveTimer)
    leaveTimer = null
  }
}

function navigateTo(path, name) {
  if (!path) return
  router.push(path)
  // TabStore里已经有addTab逻辑（路由守卫），这里直接推即可
  hoveredNav.value = null
  activePanel.value = null
}

// ========== 用户菜单 ==========
function handleCommand(cmd) {
  if (cmd === 'logout') {
    userStore.logout()
    router.push('/login')
  }
}

// ========== 路由变化时同步Tab ==========
watch(() => route.path, (path) => {
  if (path && path !== '/login') {
    tabStore.addTab({
      path,
      title: routeNameMap[path] || route.meta?.title || '未命名',
      name: route.name
    })
  }
}, { immediate: true })
</script>

<style scoped>
/* ========== 布局容器 ========== */
.layout-container {
  height: 100vh;
  display: flex;
  flex-direction: column;
  --primary: #409EFF;
  --primary-light: #53A8FF;
  --primary-dark: #337ECC;
  --sidebar-bg: #0f1011;
  --sidebar-text: #d0d6e0;
  --sidebar-text-dim: #6b7280;
  --sidebar-hover-bg: rgba(255,255,255,0.06);
  --sidebar-active-bg: rgba(64,158,255,0.15);
  --header-h: 52px;
  --tabbar-h: 40px;
}

/* ========== 顶部栏 ========== */
.layout-header {
  height: var(--header-h);
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 16px;
  box-shadow: 0 1px 0 rgba(0,0,0,0.06);
  flex-shrink: 0;
  z-index: 100;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logo-area {
  display: flex;
  align-items: center;
  gap: 8px;
}

.logo-icon {
  width: 28px;
  height: 28px;
  background: linear-gradient(135deg, #409EFF 0%, #337ECC 100%);
  border-radius: 7px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.logo-text {
  font-size: 14px;
  font-weight: 600;
  color: #1a1a1a;
  letter-spacing: -0.01em;
  white-space: nowrap;
}

.header-divider {
  width: 1px;
  height: 20px;
  background: #e4e7ed;
}

.page-title {
  font-size: 14px;
  font-weight: 600;
  color: #333;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.header-sep {
  width: 1px;
  height: 18px;
  background: #e4e7ed;
  margin: 0 2px;
}

/* ========== 模式切换按钮 ========== */
.mode-toggle {
  display: flex;
  align-items: center;
  background: #f5f7fa;
  border-radius: 8px;
  padding: 3px;
  gap: 2px;
}

.mode-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  border: none;
  background: transparent;
  border-radius: 6px;
  font-size: 12px;
  color: #909399;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.mode-btn:hover {
  color: #409EFF;
  background: rgba(64,158,255,0.08);
}

.mode-btn.active {
  background: #fff;
  color: #409EFF;
  font-weight: 600;
  box-shadow: 0 1px 4px rgba(0,0,0,0.1);
}

/* ========== 账套切换 ========== */
.account-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  border-radius: 6px;
  border: 1px solid #e4e7ed;
  font-size: 12px;
  color: #409EFF;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.account-btn:hover {
  background: #ecf5ff;
  border-color: #409EFF;
}

/* ========== 用户 ========== */
.user-chip {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  color: #666;
  cursor: pointer;
  transition: all 0.2s;
}

.user-chip:hover {
  background: #f5f7fa;
  color: #333;
}

/* ========== 主区域 ========== */
.main-area {
  flex: 1;
  overflow: hidden;
  display: flex;
}

/* ========== 侧边栏 ========== */
.layout-aside {
  background: var(--sidebar-bg);
  border-right: 1px solid rgba(255,255,255,0.06);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  flex-shrink: 0;
  transition: width 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  z-index: 50;
}

/* ========== 经典菜单 ========== */
.sidebar-menu {
  border-right: none !important;
  background: transparent !important;
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  padding: 8px 0;
}

.sidebar-menu::-webkit-scrollbar {
  width: 4px;
}

.sidebar-menu::-webkit-scrollbar-thumb {
  background: rgba(255,255,255,0.1);
  border-radius: 2px;
}

:deep(.el-menu-item),
:deep(.el-sub-menu__title) {
  color: var(--sidebar-text) !important;
  height: 40px;
  line-height: 40px;
  padding-left: 16px !important;
  border-radius: 0;
  transition: background 0.15s, color 0.15s;
}

:deep(.el-menu-item:hover),
:deep(.el-sub-menu__title:hover) {
  background: var(--sidebar-hover-bg) !important;
  color: #fff !important;
}

:deep(.el-menu-item.is-active) {
  background: var(--sidebar-active-bg) !important;
  color: var(--primary) !important;
}

:deep(.el-sub-menu .el-menu) {
  background: rgba(0,0,0,0.15) !important;
}

:deep(.el-sub-menu .el-menu-item) {
  padding-left: 44px !important;
  font-size: 13px;
}

.dashboard-item {
  margin-bottom: 4px;
}

/* ========== 平铺图标栏 ========== */
.icon-sidebar {
  width: 56px;
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 8px 0;
  position: relative;
  overflow: visible;
}

.nav-icon-item {
  position: relative;
  padding: 4px;
}

.nav-icon-inner {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
  cursor: pointer;
  color: var(--sidebar-text-dim);
  transition: all 0.18s;
}

.nav-icon-inner:hover {
  background: var(--sidebar-hover-bg);
  color: #fff;
  transform: scale(1.05);
}

.nav-icon-item.active .nav-icon-inner {
  background: var(--sidebar-active-bg);
  color: var(--primary);
}

/* ========== 展开面板 ========== */
.expand-panel {
  position: absolute;
  left: 56px;
  top: 0;
  width: 260px;
  min-height: 200px;
  max-height: calc(100vh - 52px - 40px);
  background: #191a1b;
  border: 1px solid rgba(255,255,255,0.08);
  border-left: none;
  border-radius: 0 12px 12px 0;
  box-shadow: 4px 0 24px rgba(0,0,0,0.4);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  z-index: 200;
}

.panel-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 16px 16px 12px;
  border-bottom: 1px solid rgba(255,255,255,0.06);
  flex-shrink: 0;
}

.panel-title {
  font-size: 14px;
  font-weight: 600;
  color: #f7f8f8;
}

.panel-direct {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 12px;
  padding: 12px 14px;
  border-radius: 8px;
  background: rgba(64,158,255,0.1);
  border: 1px solid rgba(64,158,255,0.2);
  color: var(--primary-light);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
}

.panel-direct:hover {
  background: rgba(64,158,255,0.18);
  border-color: rgba(64,158,255,0.35);
}

.panel-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 6px;
  padding: 12px;
  overflow-y: auto;
  flex: 1;
}

.panel-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 10px;
  border-radius: 8px;
  background: rgba(255,255,255,0.04);
  border: 1px solid transparent;
  cursor: pointer;
  transition: all 0.15s;
}

.panel-card:hover {
  background: rgba(64,158,255,0.12);
  border-color: rgba(64,158,255,0.3);
}

.panel-card.is-active {
  background: rgba(64,158,255,0.18);
  border-color: rgba(64,158,255,0.4);
}

.card-icon-wrap {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  background: rgba(64,158,255,0.15);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.card-text {
  flex: 1;
  min-width: 0;
}

.card-name {
  font-size: 12px;
  font-weight: 500;
  color: #e8eaed;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* ========== 主内容区 ========== */
.layout-main {
  flex: 1;
  background: #f0f2f5;
  overflow-y: auto;
  padding: 16px;
}

/* ========== 过渡动画 ========== */
.panel-slide-enter-active {
  transition: opacity 0.18s ease, transform 0.18s ease;
}
.panel-slide-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}
.panel-slide-enter-from {
  opacity: 0;
  transform: translateX(-8px);
}
.panel-slide-leave-to {
  opacity: 0;
  transform: translateX(-8px);
}

.sidebar-collapse-enter-active,
.sidebar-collapse-leave-active {
  transition: width 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}
</style>
