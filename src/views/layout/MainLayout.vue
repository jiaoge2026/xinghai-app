<template>
  <el-container class="layout-container">

    <!-- 左侧导航 -->
    <el-aside :width="isTileMode ? '64px' : '220px'" class="layout-aside">
      <div class="logo">
        <span v-if="!isTileMode">星海ERP</span>
        <el-icon v-else color="#fff" :size="20"><Box /></el-icon>
      </div>

      <!-- 动态菜单（根据用户权限渲染）-->
      <el-menu
        v-if="!isTileMode"
        :default-active="$route.path"
        router
        background-color="#304156"
        text-color="#bfcbd9"
        active-text-color="#409EFF"
      >
        <el-menu-item index="/dashboard">
          <el-icon><DataAnalysis /></el-icon>
          <span>驾驶舱</span>
        </el-menu-item>

        <template v-for="menu in userStore.filteredMenus" :key="menu.id">
          <el-sub-menu v-if="menu.children && menu.children.length > 0" :index="menu.path || String(menu.id)">
            <template #title>
              <el-icon><component :is="getIcon(menu.icon)" /></el-icon>
              {{ menu.name }}
            </template>
            <el-menu-item
              v-for="child in menu.children"
              :key="child.id"
              :index="child.path"
              v-if="hasMenuPermission(child)"
            >
              {{ child.name }}
            </el-menu-item>
          </el-sub-menu>
          <el-menu-item v-else :index="menu.path" v-if="hasMenuPermission(menu)">
            <el-icon><component :is="getIcon(menu.icon)" /></el-icon>
            <span>{{ menu.name }}</span>
          </el-menu-item>
        </template>
      </el-menu>


      <!-- 平铺模式：图标+一级菜单，点击展开右侧面板 -->
      <div v-else class="tile-nav">
        <div
          v-for="item in tileMenuComputed"
          :key="item.index"
          class="tile-nav-item"
          :class="{ active: activeTileIndex === item.index }"
          @click="toggleTileMenu(item)"
        >
          <el-icon :size="20">
            <component :is="item.icon" />
          </el-icon>
          <span class="tile-nav-label">{{ item.label }}</span>
        </div>
      </div>
    </el-aside>

    <!-- 右侧平铺展开面板（覆盖层，不挤占主内容） -->
    <teleport to="body">
      <transition name="fade-slide">
        <div v-if="isTileMode && activeTileMenu" class="tile-overlay" @click.self="activeTileMenu = null">
          <div class="tile-panel">
            <div class="tile-panel-header">
              <span class="tile-panel-title">{{ activeTileMenu.label }}</span>
              <el-icon class="close-btn" @click="activeTileMenu = null"><Close /></el-icon>
            </div>
            <div class="tile-panel-body">
              <!-- 无子菜单：直接跳转 -->
              <div v-if="!activeTileMenu.children || activeTileMenu.children.length === 0" class="tile-direct-link" @click="goToPath(activeTileMenu.path)">
                <el-icon><ArrowRight /></el-icon>
                <span>{{ activeTileMenu.label }}</span>
              </div>
              <!-- 有子菜单：多列平铺 -->
              <div v-else class="tile-grid">
                <div
                  v-for="child in activeTileMenu.children"
                  :key="child.path"
                  class="tile-card"
                  @click="goToPath(child.path)"
                >
                  <div class="tile-card-icon">
                    <el-icon><ArrowRight /></el-icon>
                  </div>
                  <div class="tile-card-content">
                    <div class="tile-card-title">{{ child.label }}</div>
                    <div class="tile-card-sub" v-if="child.sub">{{ child.sub }}</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </transition>
    </teleport>

    <el-container>
      <!-- 顶部 -->
      <el-header class="layout-header">
        <div class="header-left">
          <span class="page-title">{{ $route.meta.title || '星海ERP' }}</span>
        </div>
        <div class="header-right">
          <!-- 菜单模式切换 -->
          <div class="menu-mode-switch">
            <span class="switch-label" :class="{ active: !isTileMode }">
              <el-icon><Grid /></el-icon> 经典
            </span>
            <el-switch v-model="isTileMode" active-text="" inactive-text="" size="small" />
            <span class="switch-label" :class="{ active: isTileMode }">
              <el-icon><Menu /></el-icon> 平铺
            </span>
          </div>
          <el-divider direction="vertical" />
          <!-- 账套切换 -->
          <el-dropdown @command="userStore.setAccountType" size="small">
            <span class="account-type-switch">
              <el-icon><OfficeBuilding /></el-icon>
              {{ userStore.accountType === 'BUSINESS' ? '业务端' : '财务端' }}
              <el-icon><ArrowDown /></el-icon>
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
          <el-divider direction="vertical" />
          <el-dropdown @command="handleCommand">
            <span class="user-info">
              <el-icon><UserFilled /></el-icon>
              {{ userStore.userInfo.realName || '管理员' }}
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <!-- 主内容 -->
      <el-main class="layout-main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import {
  DataAnalysis, Tools, Box, Guide, Money, User, UserFilled,
  Shop, Medal, Van, Phone, Stamp, CircleCheck, Setting,
  ArrowRight, Close, Grid, Menu, ChatDotRound, Connection,
  OfficeBuilding, ArrowDown
} from '@element-plus/icons-vue'

const userStore = useUserStore()
const router = useRouter()
const route = useRoute()

// 模式切换
const isTileMode = ref(false)
const isSuperAdmin = computed(() => userStore.userInfo?.username === 'admin')
const hasPermission = (code) => {
  if (isSuperAdmin.value) return true
  if (!userStore.permissions || userStore.permissions.length === 0) return true
  return userStore.permissions.includes(code)
}
const activeTileMenu = ref(null)


const getIcon = (iconName) => {
  const iconMap = {
    Tools, Box, Guide, Money, User, UserFilled, Shop, Medal, Van, Phone, Stamp, CircleCheck, Setting, ChatDotRound, Connection
  };
  return iconMap[iconName] || Setting;
};
const hasMenuPermission = (menu) => {
  if (isSuperAdmin.value) return true;
  if (!menu.permissionCode) return true;
  return hasPermission(menu.permissionCode);
};
const toggleTileMenu = (item) => {
  if (activeTileMenu.value?.index === item.index) {
    activeTileMenu.value = null
  } else {
    activeTileMenu.value = item
  }
}

const goToPath = (path) => {
  if (!path) return
  router.push(path)
  activeTileMenu.value = null
}

// 平铺菜单：动态从 filteredMenus 生成（不再硬编码）
const tileMenuComputed = computed(() => {
  const iconMap = { Tools, Box, Guide, Money, User, UserFilled, Shop, Medal, Van, Phone, Stamp, CircleCheck, Setting, ChatDotRound, Connection }
  const getIconEl = (iconName) => iconMap[iconName] || Setting
  return userStore.filteredMenus.map(menu => ({
    index: menu.path || menu.name,
    label: menu.name,
    icon: getIconEl(menu.icon),
    path: menu.path,
    children: menu.children && menu.children.length > 0
      ? menu.children.map(child => ({ label: child.name, path: child.path, sub: '' }))
      : undefined
  }))
})

const handleCommand = (command) => {
  if (command === 'logout') {
    userStore.logout()
    router.push('/login')
  }
}
</script>

<style scoped>
.layout-container { height: 100vh; }
.layout-aside { background: #304156; overflow: hidden; transition: width 0.3s; }
.logo { height: 60px; line-height: 60px; text-align: center; color: #fff; font-size: 18px; font-weight: bold; border-bottom: 1px solid #3a4a5c; overflow: hidden; white-space: nowrap; }
.layout-header { background: #fff; display: flex; align-items: center; justify-content: space-between; padding: 0 16px; box-shadow: 0 1px 4px rgba(0,0,0,.08); }
.header-left .page-title { font-size: 16px; font-weight: 600; color: #333; }
.header-right { display: flex; align-items: center; gap: 12px; }
.user-info { cursor: pointer; display: flex; align-items: center; gap: 6px; color: #333; font-size: 14px; }
.layout-main { background: #f0f2f5; padding: 16px; overflow-y: auto; }

/* 平铺导航 */
.tile-nav { padding: 8px 0; }
.tile-nav-item {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  padding: 12px 4px; cursor: pointer; color: #bfcbd9;
  transition: background 0.2s, color 0.2s; border-radius: 4px; margin: 2px 6px;
}
.tile-nav-item:hover, .tile-nav-item.active { background: #263445; color: #409EFF; }
.tile-nav-label { font-size: 10px; margin-top: 4px; text-align: center; line-height: 1.2; }

/* 平铺展开面板（覆盖层） */
.tile-overlay {
  position: fixed;
  left: 64px;        /* 从侧边栏右边缘开始 */
  top: 0;
  right: 0;
  bottom: 0;
  z-index: 900;
  display: flex;
}
.tile-panel {
  width: 380px;
  height: 100%;
  background: #fff;
  border-right: 1px solid #e8e8e8;
  box-shadow: 4px 0 16px rgba(0,0,0,0.1);
  display: flex; flex-direction: column;
  overflow: hidden;
}
.tile-panel-header {
  height: 60px; display: flex; align-items: center; justify-content: space-between;
  padding: 0 20px; border-bottom: 1px solid #f0f0f0;
}
.tile-panel-title { font-size: 16px; font-weight: 600; color: #333; }
.close-btn { cursor: pointer; color: #999; font-size: 16px; }
.close-btn:hover { color: #333; }
.tile-panel-body { flex: 1; overflow-y: auto; padding: 16px; }

/* 直接跳转项 */
.tile-direct-link {
  display: flex; align-items: center; gap: 10px;
  padding: 14px 16px; border-radius: 8px; cursor: pointer;
  background: #f5f7fa; color: #333; font-size: 14px; font-weight: 500;
  transition: background 0.2s;
}
.tile-direct-link:hover { background: #ecf5ff; color: #409EFF; }

/* 多列平铺卡片网格 */
.tile-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.tile-card {
  display: flex; align-items: flex-start; gap: 12px;
  padding: 14px; border-radius: 8px; cursor: pointer;
  background: #f5f7fa; border: 1px solid transparent;
  transition: all 0.2s;
}
.tile-card:hover {
  background: #ecf5ff; border-color: #409EFF;
  box-shadow: 0 2px 8px rgba(64,158,255,0.15);
}
.tile-card-icon {
  width: 32px; height: 32px; border-radius: 6px; background: #409EFF;
  display: flex; align-items: center; justify-content: center; color: #fff; flex-shrink: 0;
}
.tile-card-title { font-size: 13px; font-weight: 600; color: #333; line-height: 1.4; }
.tile-card-sub { font-size: 11px; color: #999; margin-top: 3px; line-height: 1.3; }

/* 菜单模式切换开关 */
.menu-mode-switch { display: flex; align-items: center; gap: 8px; }
.switch-label { font-size: 12px; color: #999; display: flex; align-items: center; gap: 3px; transition: color 0.2s; }
.switch-label.active { color: #409EFF; font-weight: 600; }

/* 账套切换按钮 */
.account-type-switch {
  cursor: pointer;
  display: flex; align-items: center; gap: 4px;
  font-size: 13px; color: #409EFF; font-weight: 600;
  padding: 4px 8px; border-radius: 4px; border: 1px solid #409EFF;
  transition: all 0.2s;
}
.account-type-switch:hover { background: #ecf5ff; }

/* 平铺面板覆盖层 — 过渡动画（淡入+左侧滑入） */
.fade-slide-enter-active, .fade-slide-leave-active { transition: all 0.25s ease; }
.fade-slide-enter-from { opacity: 0; }
.fade-slide-enter-from .tile-panel { transform: translateX(-20px); }
.fade-slide-leave-to { opacity: 0; }
.fade-slide-leave-to .tile-panel { transform: translateX(-20px); }
</style>
