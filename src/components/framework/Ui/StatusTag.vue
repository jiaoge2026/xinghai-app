<template>
  <el-tag
    :type="tagType"
    :size="size"
    :effect="effect"
    :class="['xh-status-tag', { 'xh-status-tag--bold': bold, 'xh-status-tag--clickable': clickable }]"
    :disable-transitions="true"
    @click="handleClick"
  >
    <slot>{{ displayLabel }}</slot>
  </el-tag>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface StatusMapItem {
  label: string
  type?: 'success' | 'warning' | 'danger' | 'info' | 'primary'
}

interface Props {
  /** 状态值 */
  status: string | number | null | undefined
  /** 状态映射表，key为状态值 */
  map?: Record<string, StatusMapItem>
  /** 标签尺寸 */
  size?: 'large' | 'default' | 'small'
  /** 主题色：light=浅色背景/dark=深色背景/plain=朴素 */
  effect?: 'light' | 'dark' | 'plain'
  /** 文字加粗 */
  bold?: boolean
  /** 可点击 */
  clickable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  status: undefined,
  size: 'default',
  effect: 'light',
  bold: false,
  clickable: false,
  map: () => ({}),
})

const emit = defineEmits<{
  click: [status: string | number]
}>()

/** 从映射表查找类型，找不到返回 info */
const tagType = computed((): 'success' | 'warning' | 'danger' | 'info' | 'primary' => {
  if (!props.status) return 'info'
  const item = props.map[String(props.status)] || props.map[props.status as any]
  return item?.type || 'info'
})

/** 从映射表查找显示文本，找不到返回原始值 */
const displayLabel = computed(() => {
  if (!props.status && props.status !== 0) return String(props.status ?? '-')
  const item = props.map[String(props.status)] || props.map[props.status as any]
  return item?.label || String(props.status)
})

function handleClick() {
  if (props.clickable) {
    emit('click', props.status as string | number)
  }
}
</script>

<style scoped>
.xh-status-tag--bold :deep(.el-tag__content) {
  font-weight: 600;
}

.xh-status-tag--clickable {
  cursor: pointer;
}

.xh-status-tag--clickable:hover {
  opacity: 0.8;
}
</style>
