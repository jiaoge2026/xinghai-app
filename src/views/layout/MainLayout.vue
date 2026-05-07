<template>
  <el-container class="layout-container">

    <!-- 左侧导航 -->
    <el-aside :width="isTileMode ? '64px' : '220px'" class="layout-aside">
      <div class="logo">
        <span v-if="!isTileMode">星海ERP</span>
        <el-icon v-else color="#fff" :size="20"><Box /></el-icon>
      </div>

      <!-- 经典模式：el-sub-menu 下拉展开 -->
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

        <el-sub-menu index="fsm">
          <template #title><el-icon><Tools /></el-icon>FSM工单</template>
          <el-menu-item index="/fsm/work-orders">工单列表</el-menu-item>
          <el-menu-item index="/fsm/work-orders/create">新建工单</el-menu-item>
          <el-menu-item index="/fsm/engineers">工程师管理</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="wms">
          <template #title><el-icon><Box /></el-icon>仓储管理</template>
          <el-menu-item index="/wms/parts">配件管理</el-menu-item>
          <el-menu-item index="/wms/warehouses">仓库管理</el-menu-item>
          <el-menu-item index="/wms/stock">库��台账</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="dispatch">
          <template #title><el-icon><Guide /></el-icon>智能派工</template>
          <el-menu-item index="/dispatch/board">派工看板</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="finance">
          <template #title><el-icon><Money /></el-icon>财务管理</template>
          <el-menu-item index="/finance/vouchers">凭证管理</el-menu-item>
          <el-menu-item index="/finance/reports">财务报表</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="hr">
          <template #title><el-icon><User /></el-icon>人事管理</template>
          <el-menu-item index="/hr/employees">员工管理</el-menu-item>
          <el-menu-item index="/hr/attendance">考勤管理</el-menu-item>
          <el-menu-item index="/hr/salary">薪资管理</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="crm">
          <template #title><el-icon><UserFilled /></el-icon>客户管理</template>
          <el-menu-item index="/crm/customers">客户列表</el-menu-item>
          <el-menu-item index="/crm/contacts">联系人</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="retail">
          <template #title><el-icon><Shop /></el-icon>零售门店</template>
          <el-menu-item index="/retail/stores">门店管理</el-menu-item>
          <el-menu-item index="/retail/products">商品管理</el-menu-item>
          <el-menu-item index="/retail/orders">销售订单</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="member">
          <template #title><el-icon><Medal /></el-icon>会员管理</template>
          <el-menu-item index="/member/members">会员列表</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="logistics">
          <template #title><el-icon><Van /></el-icon>物流配送</template>
          <el-menu-item index="/logistics/drivers">司机管理</el-menu-item>
          <el-menu-item index="/logistics/delivery">配送单</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="callcenter">
          <template #title><el-icon><Phone /></el-icon>呼叫中心</template>
          <el-menu-item index="/callcenter/records">来电记录</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="qa">
          <template #title><el-icon><Stamp /></el-icon>质量管理</template>
          <el-menu-item index="/qa/inspections">质量检查</el-menu-item>
          <el-menu-item index="/qa/feedback">客户反馈</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="approval">
          <template #title><el-icon><CircleCheck /></el-icon>审批流</template>
          <el-menu-item index="/approval/list">审批列表</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="system">
          <template #title><el-icon><Setting /></el-icon>系统设置</template>
          <el-menu-item index="/system/users">用户管理</el-menu-item>
          <el-menu-item index="/system/roles">角色管理</el-menu-item>
          <el-menu-item index="/system/menus">权限配置</el-menu-item>
          <el-menu-item index="/system/config">系统配置</el-menu-item>
        </el-sub-menu>
      </el-menu>

      <!-- 平铺模式：图标+一级菜单，点击展开右侧面板 -->
      <div v-else class="tile-nav">
        <div
          v-for="item in tileMenuList"
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
  ArrowRight, Close, Grid, Menu
} from '@element-plus/icons-vue'

const userStore = useUserStore()
const router = useRouter()
const route = useRoute()

// 模式切换
const isTileMode = ref(false)
const activeTileMenu = ref(null)

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

// 平铺菜单数据（对应经典菜单的 sub-menu）
const tileMenuList = [
  { index: 'dashboard', label: '驾驶舱', icon: DataAnalysis, path: '/dashboard' },
  { index: 'fsm', label: 'FSM工单', icon: Tools, children: [
    { label: '工单列表', path: '/fsm/work-orders', sub: '查看所有工单' },
    { label: '新建工单', path: '/fsm/work-orders/create', sub: '创建维修/安装工单' },
    { label: '工程师管理', path: '/fsm/engineers', sub: '工程师档案管理' },
  ]},
  { index: 'wms', label: '仓储管理', icon: Box, children: [
    { label: '配件管理', path: '/wms/parts', sub: '配件档案与库存' },
    { label: '仓库管理', path: '/wms/warehouses', sub: '仓库信息维护' },
    { label: '库存台账', path: '/wms/stock', sub: '出入库流水记录' },
  ]},
  { index: 'dispatch', label: '智能派工', icon: Guide, children: [
    { label: '派工看板', path: '/dispatch/board', sub: '实时调度与派工' },
  ]},
  { index: 'finance', label: '财务管理', icon: Money, children: [
    { label: '凭证管理', path: '/finance/vouchers', sub: '会计凭证录入与审核' },
    { label: '财务报表', path: '/finance/reports', sub: '经营报表与分析' },
  ]},
  { index: 'hr', label: '人事管理', icon: User, children: [
    { label: '员工管理', path: '/hr/employees', sub: '员工档案管理' },
    { label: '考勤管理', path: '/hr/attendance', sub: '打卡与考勤记录' },
    { label: '薪资管理', path: '/hr/salary', sub: '薪资发放与管理' },
  ]},
  { index: 'crm', label: '客户管理', icon: UserFilled, children: [
    { label: '客户列表', path: '/crm/customers', sub: '客户信息管理' },
    { label: '联系人', path: '/crm/contacts', sub: '联系人管理' },
  ]},
  { index: 'retail', label: '零售门店', icon: Shop, children: [
    { label: '门店管理', path: '/retail/stores', sub: '门店信息维护' },
    { label: '商品管理', path: '/retail/products', sub: '商品档案与定价' },
    { label: '销售订单', path: '/retail/orders', sub: '零售销售单据' },
  ]},
  { index: 'member', label: '会员管理', icon: Medal, children: [
    { label: '会员列表', path: '/member/members', sub: '会员注册与积分' },
  ]},
  { index: 'logistics', label: '物流配送', icon: Van, children: [
    { label: '司机管理', path: '/logistics/drivers', sub: '司机档案管理' },
    { label: '配送单', path: '/logistics/delivery', sub: '配送调度单' },
  ]},
  { index: 'callcenter', label: '呼叫中心', icon: Phone, children: [
    { label: '来电记录', path: '/callcenter/records', sub: '呼入通话记录' },
  ]},
  { index: 'qa', label: '质量管理', icon: Stamp, children: [
    { label: '质量检查', path: '/qa/inspections', sub: '质检记录管理' },
    { label: '客户反馈', path: '/qa/feedback', sub: '投诉与反馈处理' },
  ]},
  { index: 'approval', label: '审批流', icon: CircleCheck, children: [
    { label: '审批列表', path: '/approval/list', sub: '费用与业务审批' },
  ]},
  { index: 'system', label: '系统设置', icon: Setting, children: [
    { label: '用户管理', path: '/system/users', sub: '系统用户账号' },
    { label: '角色管理', path: '/system/roles', sub: '角色与权限分配' },
    { label: '权限配置', path: '/system/menus', sub: '菜单权限管理' },
    { label: '系统配置', path: '/system/config', sub: '系统参数配置' },
  ]},
]

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

/* 平铺面板覆盖层 — 过渡动画（淡入+左侧滑入） */
.fade-slide-enter-active, .fade-slide-leave-active { transition: all 0.25s ease; }
.fade-slide-enter-from { opacity: 0; }
.fade-slide-enter-from .tile-panel { transform: translateX(-20px); }
.fade-slide-leave-to { opacity: 0; }
.fade-slide-leave-to .tile-panel { transform: translateX(-20px); }
</style>
