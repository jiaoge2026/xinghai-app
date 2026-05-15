<template>
  <div class="xh-page-header" :class="{ 'xh-page-header--bordered': showBorder }">
    <!-- 面包屑 -->
    <div v-if="showBreadcrumb" class="xh-page-header__breadcrumb">
      <slot name="breadcrumb">
        <el-breadcrumb separator="/">
          <el-breadcrumb-item :to="{ path: '/dashboard' }">首页</el-breadcrumb-item>
          <el-breadcrumb-item>{{ title }}</el-breadcrumb-item>
        </el-breadcrumb>
      </slot>
    </div>

    <!-- 主内容区 -->
    <div class="xh-page-header__main">
      <!-- 左侧：图标 + 标题 -->
      <div class="xh-page-header__left">
        <el-icon v-if="icon" :size="22" class="xh-page-header__icon">
          <component :is="icon" />
        </el-icon>
        <div class="xh-page-header__title-wrap">
          <h1 class="xh-page-header__title">{{ title }}</h1>
          <p v-if="subtitle" class="xh-page-header__subtitle">{{ subtitle }}</p>
        </div>
      </div>

      <!-- 右侧：操作按钮 -->
      <div v-if="actions.length > 0" class="xh-page-header__actions">
        <template v-for="(action, idx) in actions" :key="action.key || idx">
          <!-- 分隔线 -->
          <el-divider v-if="action.dividerBefore" direction="vertical" />
          <el-button
            :type="action.type || 'default'"
            :icon="action.icon ? h('i', { class: `el-icon-${action.icon}` }) : undefined"
            :disabled="action.disabled"
            @click="action.onClick"
          >
            {{ action.label }}
          </el-button>
        </template>
      </div>
    </div>

    <!-- 额外插槽 -->
    <slot />
  </div>
</template>

<script setup lang="ts">
import { h } from 'vue'

interface Action {
  key?: string
  label: string
  type?: '' | 'default' | 'primary' | 'success' | 'warning' | 'danger' | 'info' | 'text'
  icon?: string
  disabled?: boolean
  dividerBefore?: boolean
  onClick: () => void
}

interface Props {
  title: string
  subtitle?: string
  icon?: string
  showBorder?: boolean
  showBreadcrumb?: boolean
  actions?: Action[]
}

withDefaults(defineProps<Props>(), {
  showBorder: true,
  showBreadcrumb: true,
  actions: () => [],
})
</script>

<style scoped>
.xh-page-header {
  padding: 0 0 16px;
  background: #fff;
}

.xh-page-header--bordered {
  padding-bottom: 16px;
  border-bottom: 1px solid #ebeef5;
}

.xh-page-header__breadcrumb {
  margin-bottom: 12px;
}

.xh-page-header__main {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.xh-page-header__left {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.xh-page-header__icon {
  color: #409eff;
  flex-shrink: 0;
}

.xh-page-header__title-wrap {
  min-width: 0;
}

.xh-page-header__title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #303133;
  line-height: 1.3;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.xh-page-header__subtitle {
  margin: 4px 0 0;
  font-size: 13px;
  color: #909399;
  line-height: 1.4;
}

.xh-page-header__actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

.xh-page-header :deep(.el-divider--vertical) {
  margin: 0 4px;
}
</style>
