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

      <!-- 左侧一级导航 -->
      <el-aside class="layout-aside">
        <!-- 侧边栏容器：hover事件在document级处理（避免el-menu-item内部.stopPropagation冲突） -->
        <div class="nav-sidebar">
          <!-- 一级菜单：只显示父级，hover悬浮面板 -->
          <el-menu
            :default-active="activeMenuPath"
            :collapse="false"
            :router="false"
            class="sidebar-menu"
          >
            <el-menu-item
              index="/dashboard"
              class="dashboard-item nav-item"
            >
              <el-icon><DataAnalysis /></el-icon>
              <template #title>驾驶舱</template>
            </el-menu-item>

            <template v-for="menu in userStore.filteredMenus" :key="menu.id">
              <el-menu-item
                v-if="menu.children?.length"
                :index="menu.path || String(menu.id)"
                class="nav-item has-children"
              >
                <el-icon><component :is="getIcon(menu.icon)" /></el-icon>
                <template #title>{{ menu.name }}</template>
              </el-menu-item>
              <el-menu-item
                v-else
                :index="menu.path"
                class="nav-item no-children"
              >
                <el-icon><component :is="getIcon(menu.icon)" /></el-icon>
                <template #title>{{ menu.name }}</template>
              </el-menu-item>
            </template>
          </el-menu>
        </div>

        <!-- 悬浮面板：从左侧菜单右侧展开，覆盖主内容区 -->
        <transition name="panel-slide">
          <div
            v-if="hoveredNav && activePanel"
            class="float-panel"
            @mouseenter="cancelLeaveTimer"
            @mouseleave="onSidebarLeave"
            @click.stop
          >
            <!-- 面板头部 -->
            <div class="panel-header">
              <div class="panel-header-icon">
                <el-icon :size="16" color="#fff"><component :is="getIcon(activePanel.icon)" /></el-icon>
              </div>
              <div class="panel-header-text">
                <span class="panel-title">{{ activePanel.name }}</span>
                <span class="panel-subtitle">{{ activePanel.children?.length || 0 }} 个功能</span>
              </div>
              <button class="panel-close" @click="closePanel">
                <el-icon :size="14"><Close /></el-icon>
              </button>
            </div>

            <!-- 子菜单网格（无子菜单时显示直接进入提示） -->
            <div
              v-if="!activePanel.children?.length"
              class="panel-direct"
              @click.stop="handleMenuClick(activePanel.path, activePanel.path)"
            >
              <el-icon><ArrowRight /></el-icon>
              <span>进入 {{ activePanel.name }}</span>
            </div>
            <div v-else class="panel-grid">
              <div
                v-for="child in activePanel.children"
                :key="child.path"
                class="panel-card"
                :class="{ 'is-active': currentPath === child.path }"
                @click.stop="handleMenuClick(child.path, child.path)"
              >
                <div class="card-icon-wrap">
                  <el-icon :size="20" color="#409EFF"><component :is="getIcon(child.icon)" /></el-icon>
                </div>
                <div class="card-text">
                  <div class="card-name">{{ child.name }}</div>
                </div>
              </div>
            </div>
          </div>
        </transition>
      </el-aside>

      <!-- ==================== 内容区 ==================== -->
      <el-container class="content-wrapper">
        <el-main class="layout-main">
          <router-view />
        </el-main>
      </el-container>
    </el-container>
  </el-container>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useTabStore } from '@/stores/tab'
import TabBar from '@/components/tab/TabBar.vue'
import {
  DataAnalysis, Grid, Menu, UserFilled, ArrowRight,
  ArrowDown, OfficeBuilding, Money, Setting, Tools, Box,
  Guide, User, Shop, Medal, Van, Phone, Stamp,
  CircleCheck, ChatDotRound, Connection, Box as BoxIcon, Close
} from '@element-plus/icons-vue'

const userStore = useUserStore()
const tabStore = useTabStore()
const router = useRouter()
const route = useRoute()

// ========== 悬浮面板状态 ==========
const hoveredNav = ref(null)
const activePanel = ref(null)
let leaveTimer = null
const STORAGE_KEY = 'xinghai_layout_mode'
const isTiledMode = ref(localStorage.getItem(STORAGE_KEY) === 'tiled')

function setMode(tiled) {
  isTiledMode.value = tiled
  localStorage.setItem(STORAGE_KEY, tiled ? 'tiled' : 'classic')
}

// ========== 侧边栏宽度 ==========
const asideWidth = computed(() => 220)

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



function onMenuHover(menu) {
  cancelLeaveTimer()
  hoveredNav.value = menu.path
  activePanel.value = menu
}

function closePanel() {
  hoveredNav.value = null
  activePanel.value = null
}

function handleMenuClick(menuPath, targetPath) {
  if (!targetPath) return
  const base = window.location.origin
  window.location.href = base + targetPath
}

onMounted(() => {
  const sidebar = document.querySelector('.nav-sidebar')
  if (!sidebar) return
  sidebar.addEventListener('mouseover', onSidebarMouseOver, true)
  sidebar.addEventListener('click', onSidebarClick, true)
})

onUnmounted(() => {
  const sidebar = document.querySelector('.nav-sidebar')
  if (!sidebar) return
  sidebar.removeEventListener('mouseover', onSidebarMouseOver, true)
  sidebar.removeEventListener('click', onSidebarClick, true)
  cancelLeaveTimer()
})

// sidebar容器拦截hover事件（capture阶段，优先于el-menu的事件处理）
function onSidebarMouseOver(e) {
  const menuItem = e.target.closest('.el-menu-item')
  if (!menuItem) return
  cancelLeaveTimer()
  const index = menuItem.getAttribute('index')
  if (!index) return
  let menuData = null
  if (index === '/dashboard') {
    menuData = { path: '/dashboard', name: '驾驶舱', icon: 'DataAnalysis', children: [] }
  } else {
    const found = userStore.filteredMenus.find(m => m.path === index)
    if (!found) return
    menuData = { path: found.path, name: found.name, icon: found.icon, children: found.children || [] }
  }
  hoveredNav.value = menuData.path
  activePanel.value = menuData
}

// sidebar容器拦截点击事件（capture阶段，阻止el-menu的document委托）
function onSidebarClick(e) {
  const menuItem = e.target.closest('.el-menu-item')
  if (!menuItem) return
  e.stopPropagation()
  e.preventDefault()
  const index = menuItem.getAttribute('index')
  if (!index) return
  window.location.href = window.location.origin + index
}

function onSidebarLeave() {
  leaveTimer = setTimeout(() => {
    hoveredNav.value = null
    activePanel.value = null
  }, 180)
}

function cancelLeaveTimer() {
  if (leaveTimer) { clearTimeout(leaveTimer); leaveTimer = null }
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
  // 路由变化时自动关闭悬浮面板
  hoveredNav.value = null
  activePanel.value = null
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
  background: linear-gradient(to right, #fff 0%, #f8f9fb 60%, #e8eaef 100%);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 16px;
  box-shadow: 0 1px 0 rgba(0,0,0,0.06);
  flex-shrink: 0;
  z-index: 100;
  position: relative;
}
.layout-header::after {
  content: '';
  position: absolute;
  right: 0; top: 0; bottom: 0;
  width: 220px;
  background: linear-gradient(to right, transparent, rgba(15,16,17,0.08));
  pointer-events: none;
}
.header-left { display: flex; align-items: center; gap: 12px; position: relative; z-index: 1; }
.logo-area { display: flex; align-items: center; gap: 8px; }
.logo-icon { width: 28px; height: 28px; background: linear-gradient(135deg, #409EFF 0%, #337ECC 100%); border-radius: 7px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; box-shadow: 0 2px 8px rgba(64,158,255,0.35); }
.logo-text { font-size: 14px; font-weight: 700; color: #1a1a1a; letter-spacing: -0.01em; white-space: nowrap; }
.header-divider { width: 1px; height: 20px; background: #d0d5de; }
.page-title { font-size: 14px; font-weight: 600; color: #333; }
.header-right { display: flex; align-items: center; gap: 6px; position: relative; z-index: 1; background: rgba(15,16,17,0.04); border-radius: 8px; padding: 3px 6px; border: 1px solid rgba(0,0,0,0.06); }
.header-sep { width: 1px; height: 18px; background: rgba(0,0,0,0.08); margin: 0 2px; }
.account-btn { display: flex; align-items: center; gap: 4px; padding: 4px 10px; border-radius: 6px; border: 1px solid rgba(64,158,255,0.25); font-size: 12px; color: #409EFF; font-weight: 600; cursor: pointer; transition: all 0.2s; background: rgba(64,158,255,0.05); }
.account-btn:hover { background: rgba(64,158,255,0.12); border-color: #409EFF; }
.user-chip { display: flex; align-items: center; gap: 5px; padding: 4px 10px; border-radius: 6px; font-size: 12px; color: #555; cursor: pointer; transition: all 0.2s; }
.user-chip:hover { background: rgba(0,0,0,0.05); color: #333; }

/* ========== 主区域 ========== */
.main-area { flex: 1; overflow: hidden; display: flex; }

/* ========== 侧边栏（固定220px） ========== */
.layout-aside {
  width: 220px;
  background: var(--sidebar-bg);
  border-right: 1px solid rgba(255,255,255,0.06);
  display: flex;
  flex-direction: column;
  flex-shrink: 0;
  position: relative;
  z-index: 50;
  overflow: visible;
}
.nav-sidebar { display: flex; flex-direction: column; flex: 1; min-height: 0; overflow: hidden; }

/* ========== 菜单（一级13px） ========== */
.sidebar-menu { border-right: none !important; width: 100% !important; flex: 1; min-height: 0; overflow-y: auto; overflow-x: hidden; background: transparent !important; padding: 8px 0; }
.sidebar-menu::-webkit-scrollbar { width: 4px; }
.sidebar-menu::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 2px; }

.nav-item,
.dashboard-item {
  height: 40px;
  line-height: 40px;
  padding-left: 16px !important;
  font-size: 13px;
  font-weight: 500;
  color: var(--sidebar-text) !important;
  border-radius: 0;
  transition: background 0.15s, color 0.15s;
  margin: 0 !important;
}
.dashboard-item { margin-bottom: 4px !important; }
.nav-item:hover, .dashboard-item:hover { background: var(--sidebar-hover-bg) !important; color: #fff !important; }
.nav-item.is-active, .dashboard-item.is-active { background: var(--sidebar-active-bg) !important; color: var(--primary) !important; }

/* ========== 悬浮面板（520px宽，向右展开） ========== */
.float-panel {
  position: absolute;
  left: 220px;
  top: 0;
  width: 520px;
  height: calc(100vh - 52px - 40px);
  background: rgba(26, 27, 30, 0.92);
  backdrop-filter: blur(20px) saturate(1.4);
  -webkit-backdrop-filter: blur(20px) saturate(1.4);
  border: 1px solid rgba(255,255,255,0.10);
  border-left: none;
  border-radius: 0 12px 12px 0;
  box-shadow: 8px 0 40px rgba(0,0,0,0.5);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  z-index: 200;
}

.panel-header { display: flex; align-items: center; gap: 12px; padding: 20px 20px 16px; border-bottom: 1px solid rgba(255,255,255,0.08); flex-shrink: 0; }
.panel-header-icon { width: 36px; height: 36px; border-radius: 10px; background: linear-gradient(135deg, #409EFF 0%, #337ECC 100%); display: flex; align-items: center; justify-content: center; flex-shrink: 0; box-shadow: 0 2px 8px rgba(64,158,255,0.4); }
.panel-header-text { flex: 1; display: flex; flex-direction: column; gap: 2px; }
.panel-title { font-size: 13px; font-weight: 700; color: #f0f2f5; }
.panel-subtitle { font-size: 12px; color: rgba(255,255,255,0.35); }
.panel-close { width: 28px; height: 28px; border-radius: 50%; border: none; background: rgba(255,255,255,0.06); color: rgba(255,255,255,0.5); cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.15s; flex-shrink: 0; }
.panel-close:hover { background: rgba(255,255,255,0.12); color: #fff; }
.panel-direct { display: flex; align-items: center; gap: 10px; margin: 16px 20px 0; padding: 12px 16px; border-radius: 10px; background: rgba(64,158,255,0.12); border: 1px solid rgba(64,158,255,0.25); color: #53A8FF; font-size: 13px; font-weight: 600; cursor: pointer; transition: all 0.15s; }
.panel-direct:hover { background: rgba(64,158,255,0.22); border-color: rgba(64,158,255,0.45); }

/* 4列图标网格 */
.panel-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; padding: 16px 20px; overflow-y: auto; flex: 1; }
.panel-card { display: flex; flex-direction: column; align-items: center; gap: 8px; padding: 16px 8px 12px; border-radius: 12px; background: rgba(255,255,255,0.04); border: 1px solid transparent; cursor: pointer; transition: all 0.18s; text-align: center; }
.panel-card:hover { background: rgba(64,158,255,0.14); border-color: rgba(64,158,255,0.35); transform: translateY(-2px); }
.panel-card.is-active { background: rgba(64,158,255,0.20); border-color: rgba(64,158,255,0.50); }
.card-icon-wrap { width: 44px; height: 44px; border-radius: 12px; background: rgba(64,158,255,0.12); display: flex; align-items: center; justify-content: center; flex-shrink: 0; transition: background 0.15s; }
.panel-card:hover .card-icon-wrap { background: rgba(64,158,255,0.22); }
.card-text { flex: 1; min-width: 0; width: 100%; }
.card-name { font-size: 12px; font-weight: 600; color: #e8eaed; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; line-height: 1.3; }

/* ========== 内容区 ========== */
.content-wrapper { flex: 1; display: flex; flex-direction: column; min-width: 0; overflow: hidden; }
.layout-main { flex: 1; background: #f0f2f5; overflow-y: auto; padding: 16px; }

/* ========== 过渡动画 ========== */
.panel-slide-enter-active { transition: opacity 0.18s ease, transform 0.18s ease; }
.panel-slide-leave-active { transition: opacity 0.15s ease, transform 0.15s ease; }
.panel-slide-enter-from { opacity: 0; transform: translateX(-8px); }
.panel-slide-leave-to { opacity: 0; transform: translateX(-8px); }
</style>
