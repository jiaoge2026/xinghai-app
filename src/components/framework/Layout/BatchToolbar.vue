<template>
  <transition name="el-fade-in-linear">
    <div
      v-if="selectedCount > 0"
      class="xh-batch-toolbar"
      :class="[`xh-batch-toolbar--${position}`, `xh-batch-toolbar--${selectedCount > 0 ? 'visible' : 'hidden'}`]"
    >
      <div class="xh-batch-toolbar__content">
        <!-- 已选数量 -->
        <span class="xh-batch-toolbar__count">
          <el-icon><Check /></el-icon>
          已选择 <strong>{{ selectedCount }}</strong> 项
          <span v-if="max" class="xh-batch-toolbar__limit">（最多 {{ max }} 项）</span>
        </span>

        <!-- 分隔线 -->
        <el-divider direction="vertical" />

        <!-- 操作按钮 -->
        <div class="xh-batch-toolbar__actions">
          <template v-for="(action, idx) in actions" :key="action.key || idx">
            <el-divider v-if="action.dividerBefore" direction="vertical" />
            <el-button
              :type="action.type || 'default'"
              :size="size"
              :icon="action.icon ? h('i', { class: `el-icon-${action.icon}` }) : undefined"
              :disabled="action.disabled"
              @click="handleAction(action)"
            >
              {{ action.label }}
            </el-button>
          </template>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup lang="ts">
import { h } from 'vue'
import { Check } from '@element-plus/icons-vue'

interface Action {
  key: string
  label: string
  type?: 'default' | 'primary' | 'success' | 'warning' | 'danger' | 'info' | 'text'
  icon?: string
  disabled?: boolean
  dividerBefore?: boolean
}

interface Props {
  /** 已勾选数量 */
  selectedCount: number
  /** 最大勾选数量，null 表示不限制 */
  max?: number | null
  /** 工具栏位置：top=表格上方/bottom=表格下方 */
  position?: 'top' | 'bottom' | 'both'
  /** 操作按钮列表 */
  actions: Action[]
  size?: 'large' | 'default' | 'small'
}

const props = withDefaults(defineProps<Props>(), {
  position: 'top',
  size: 'default',
  max: null,
})

const emit = defineEmits<{
  action: [key: string]
}>()

function handleAction(action: Action) {
  emit('action', action.key)
}
</script>

<style scoped>
.xh-batch-toolbar {
  background: #ecf5ff;
  border: 1px solid #d9ecff;
  border-radius: 4px;
  padding: 8px 16px;
  margin-bottom: 12px;
}

.xh-batch-toolbar--bottom {
  margin-bottom: 0;
  margin-top: 12px;
}

.xh-batch-toolbar__content {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.xh-batch-toolbar__count {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 14px;
  color: #409eff;
  white-space: nowrap;
}

.xh-batch-toolbar__count strong {
  color: #303133;
  font-weight: 600;
}

.xh-batch-toolbar__limit {
  font-size: 12px;
  color: #909399;
}

.xh-batch-toolbar__actions {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
}

.xh-batch-toolbar :deep(.el-divider--vertical) {
  margin: 0 4px;
  height: 20px;
}
</style>
