<script setup>
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { Close, ArrowDown } from '@element-plus/icons-vue'
import { useTabStore } from '@/stores/tab'

const router = useRouter()
const tabStore = useTabStore()
const scrollRef = ref(null)

// 菜单命令处理
const onCommand = (command) => {
  if (command === 'closeCurrent') {
    tabStore.closeActiveTab()
  } else if (command === 'closeOthers') {
    if (tabStore.activeTabId !== null) {
      tabStore.closeOtherTabs(tabStore.activeTabId)
    }
  } else if (command === 'closeAll') {
    tabStore.tabs.splice(0, tabStore.tabs.length)
    tabStore.activeTabId = null
  } else if (command === 'refresh') {
    const currentTab = tabStore.getActiveTab()
    if (currentTab) {
      const idx = tabStore.tabs.findIndex(t => t.id === currentTab.id)
      if (idx !== -1) {
        const [removed] = tabStore.tabs.splice(idx, 1)
        tabStore.tabs.push({ ...removed, id: tabStore.newTabId() })
        tabStore.activeTabId = tabStore.tabs[tabStore.tabs.length - 1].id
      }
    }
  }
}

// 滚动激活tab到可见区域
watch(() => tabStore.activeTabId, () => {
  if (!scrollRef.value) return
  const el = scrollRef.value.querySelector('.tab-item.active')
  el && el.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' })
})
</script>

<template>
  <div class="tabs-container">
    <div class="tabs-scroll" ref="scrollRef">
      <div class="tabs-inner">
        <TransitionGroup name="tab">
          <div
            v-for="tab in tabStore.tabs"
            :key="tab.id"
            :class="['tab-item', { active: tab.id === tabStore.activeTabId }]"
            @click="router.push(tab.path)"
          >
            <span class="tab-title">{{ tab.title }}</span>
            <el-icon
              v-if="tab.name !== 'Dashboard'"
              class="tab-close"
              @click.stop="tabStore.closeTab(tab.id)"
            >
              <Close />
            </el-icon>
          </div>
        </TransitionGroup>
      </div>
    </div>
    <div class="tabs-actions">
      <el-dropdown trigger="click" @command="onCommand">
        <template #dropdown>
          <el-dropdown-menu>
            <el-dropdown-item command="closeCurrent">关闭当前</el-dropdown-item>
            <el-dropdown-item command="closeOthers">关闭其他</el-dropdown-item>
            <el-dropdown-item command="closeAll">关闭全部</el-dropdown-item>
            <el-dropdown-item command="refresh" divided>刷新当前</el-dropdown-item>
          </el-dropdown-menu>
        </template>
        <el-icon :size="16" class="action-icon">
          <ArrowDown />
        </el-icon>
      </el-dropdown>
    </div>
  </div>
</template>

<style scoped>
.tabs-container {
  display: flex;
  align-items: center;
  height: 38px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-bottom: 1px solid #e4e7ed;
  padding: 0 12px 0 0;
  gap: 0;
  overflow: hidden;
  flex-shrink: 0;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
}

.tabs-scroll {
  flex: 1;
  overflow-x: auto;
  overflow-y: hidden;
  scrollbar-width: none;
}

.tabs-scroll::-webkit-scrollbar {
  display: none;
}

.tabs-inner {
  display: flex;
  align-items: center;
  height: 100%;
  min-width: max-content;
  padding-left: 4px;
}

.tab-item {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 30px;
  padding: 0 12px;
  margin: 0 2px;
  border-radius: 6px 6px 0 0;
  cursor: pointer;
  font-size: 12px;
  color: #909399;
  background: transparent;
  transition: all 0.15s;
  border: 1px solid transparent;
  border-bottom: none;
  white-space: nowrap;
  flex-shrink: 0;
  position: relative;
}

.tab-item:hover {
  color: #409EFF;
  background: #ecf5ff;
}

.tab-item.active {
  color: #409EFF;
  background: #fff;
  border-color: #e4e7ed;
  font-weight: 600;
  box-shadow: 0 -1px 0 0 #fff inset;
}

.tab-title {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 120px;
}

.tab-close {
  font-size: 11px;
  opacity: 0.5;
  transition: opacity 0.15s;
  flex-shrink: 0;
  padding: 1px;
  border-radius: 3px;
}

.tab-close:hover {
  opacity: 1;
  color: #f56c6c;
  background: rgba(245, 108, 108, 0.1);
}

.tabs-actions {
  display: flex;
  align-items: center;
  flex-shrink: 0;
  padding-left: 8px;
  border-left: 1px solid #e4e7ed;
  margin-left: 4px;
}

.action-icon {
  color: #c0c4cc;
  cursor: pointer;
  padding: 4px;
  border-radius: 4px;
  transition: all 0.15s;
  font-size: 12px;
}

.action-icon:hover {
  color: #409EFF;
  background: #ecf5ff;
}

.tab-enter-active,
.tab-leave-active {
  transition: all 0.15s ease;
}

.tab-enter-from {
  opacity: 0;
  transform: translateY(-3px);
}

.tab-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>
