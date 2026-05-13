<script setup>
import { ref, watch } from 'vue'
import { Close, ArrowDown } from '@element-plus/icons-vue'
import { useTabStore } from '@/stores/tab'

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
            @click="tabStore.switchTab(tab.id)"
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
  height: 40px;
  background: #1a1a2e;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  padding: 0 8px;
  gap: 4px;
  overflow: hidden;
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
  gap: 2px;
  white-space: nowrap;
}

.tab-item {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 13px;
  color: rgba(255, 255, 255, 0.55);
  background: transparent;
  transition: all 0.2s;
  border: 1px solid transparent;
  flex-shrink: 0;
  max-width: 180px;
}

.tab-item:hover {
  color: rgba(255, 255, 255, 0.85);
  background: rgba(255, 255, 255, 0.06);
}

.tab-item.active {
  color: #fff;
  background: rgba(64, 158, 255, 0.15);
  border-color: rgba(64, 158, 255, 0.3);
}

.tab-title {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.tab-close {
  font-size: 12px;
  opacity: 0.6;
  transition: opacity 0.2s;
  flex-shrink: 0;
}

.tab-close:hover {
  opacity: 1;
  color: #f56c6c;
}

.tabs-actions {
  display: flex;
  align-items: center;
  flex-shrink: 0;
}

.action-icon {
  color: rgba(255, 255, 255, 0.55);
  cursor: pointer;
  padding: 4px;
  border-radius: 4px;
  transition: all 0.2s;
}

.action-icon:hover {
  color: rgba(255, 255, 255, 0.85);
  background: rgba(255, 255, 255, 0.08);
}

.tab-enter-active,
.tab-leave-active {
  transition: all 0.2s ease;
}

.tab-enter-from {
  opacity: 0;
  transform: translateY(-4px);
}

.tab-leave-to {
  opacity: 0;
  transform: translateY(4px);
}
</style>
