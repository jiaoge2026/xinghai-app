<template>
  <el-dialog
    v-model="visible"
    :title="resolvedTitle"
    :width="width"
    :close-on-click-modal="type === 'danger' ? false : true"
    :show-close="true"
    class="xh-confirm-dialog"
    @close="handleClose"
  >
    <div class="xh-confirm-dialog__body">
      <!-- 图标 -->
      <div v-if="showIcon" class="xh-confirm-dialog__icon" :class="`xh-confirm-dialog__icon--${resolvedType}`">
        <el-icon :size="32">
          <WarningFilled v-if="resolvedType === 'danger' || resolvedType === 'warning'" />
          <InfoFilled v-else />
        </el-icon>
      </div>

      <!-- 消息 -->
      <p class="xh-confirm-dialog__message">{{ resolvedMessage }}</p>
    </div>

    <template #footer>
      <div class="xh-confirm-dialog__footer">
        <el-button
          :size="size"
          @click="handleCancel"
        >
          {{ cancelText }}
        </el-button>
        <el-button
          :type="confirmButtonType"
          :size="size"
          :loading="confirmLoading"
          @click="handleConfirm"
        >
          {{ confirmText }}
        </el-button>
      </div>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { WarningFilled, InfoFilled } from '@element-plus/icons-vue'

interface Props {
  /** v-model */
  visible: boolean
  /** 标题 */
  title?: string
  /** 消息内容，支持函数（延迟解析） */
  message?: string | (() => string)
  /** 类型：warning=警告/danger=危险/info=提示 */
  type?: 'warning' | 'danger' | 'info'
  /** 确认按钮文字 */
  confirmText?: string
  /** 取消按钮文字 */
  cancelText?: string
  /** 确认按钮loading */
  confirmLoading?: boolean
  /** 图标 */
  icon?: string
  /** 是否显示图标 */
  showIcon?: boolean
  /** 宽度 */
  width?: string | number
  /** 尺寸 */
  size?: 'large' | 'default' | 'small'
}

const props = withDefaults(defineProps<Props>(), {
  title: '操作确认',
  message: '确定执行此操作吗？',
  type: 'warning',
  confirmText: '确定',
  cancelText: '取消',
  confirmLoading: false,
  showIcon: true,
  width: '420px',
  size: 'default',
})

const emit = defineEmits<{
  'update:visible': [val: boolean]
  confirm: []
  cancel: []
}>()

/** 支持函数消息（延迟解析，避免对象渲染时立即执行） */
const resolvedMessage = computed(() => {
  if (typeof props.message === 'function') {
    return props.message()
  }
  return props.message
})

/** 类型对应的默认标题 */
const TITLE_MAP: Record<string, string> = {
  danger: '危险操作',
  warning: '操作确认',
  info: '确认提示',
}

const resolvedTitle = computed(() => props.title || TITLE_MAP[props.type] || '操作确认')

const confirmButtonType = computed(() => {
  return props.type === 'danger' ? 'danger' : 'primary'
})

function handleClose() {
  emit('update:visible', false)
  emit('cancel')
}

function handleCancel() {
  emit('update:visible', false)
  emit('cancel')
}

function handleConfirm() {
  emit('confirm')
}
</script>

<style scoped>
.xh-confirm-dialog__body {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px 0 24px;
  gap: 16px;
}

.xh-confirm-dialog__icon {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.xh-confirm-dialog__icon--danger {
  background: #fef0f0;
  color: #f56c6c;
}

.xh-confirm-dialog__icon--warning {
  background: #fdf6ec;
  color: #e6a23c;
}

.xh-confirm-dialog__icon--info {
  background: #f4f4f5;
  color: #909399;
}

.xh-confirm-dialog__message {
  margin: 0;
  font-size: 15px;
  line-height: 1.6;
  color: #303133;
  text-align: center;
  word-break: break-word;
}

.xh-confirm-dialog__footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}
</style>
