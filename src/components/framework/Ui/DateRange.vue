<template>
  <el-date-picker
    v-model="internalValue"
    :type="showTime ? 'datetimerange' : 'daterange'"
    :placeholder="placeholder || (showTime ? '选择日期时间范围' : '选择日期范围')"
    :format="showTime ? 'YYYY-MM-DD HH:mm' : format"
    :value-format="showTime ? 'YYYY-MM-DD HH:mm:ss' : valueFormat"
    :start-placeholder="startPlaceholder || '开始日期'"
    :end-placeholder="endPlaceholder || '结束日期'"
    :range-separator="rangeSeparator || '至'"
    :disabled="disabled"
    :size="size"
    :shortcuts="shortcuts.length > 0 ? shortcuts : undefined"
    :clearable="true"
    class="xh-date-range"
    style="width: 100%"
  />
</template>

<script lang="ts">
// ============ 工具函数（普通 script 块，模块级作用域，不受 defineProps 提升影响）============
function fmtDate(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

function today(): string { return fmtDate(new Date()) }

function daysAgo(n: number): string {
  const d = new Date(); d.setDate(d.getDate() - n); return fmtDate(d)
}

function monthStart(): string {
  const d = new Date(); d.setDate(1); return fmtDate(d)
}

function lastMonthStart(): string {
  const d = new Date(); d.setMonth(d.getMonth() - 1); d.setDate(1); return fmtDate(d)
}

function lastMonthEnd(): string {
  const d = new Date(); d.setMonth(d.getMonth() - 1)
  d.setDate(new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()); return fmtDate(d)
}

function yearStart(): string {
  const d = new Date(); d.setMonth(0); d.setDate(1); return fmtDate(d)
}

// 导出给 <script setup> 使用
export { today, daysAgo, monthStart, lastMonthStart, lastMonthEnd, yearStart, fmtDate }
</script>

<script setup lang="ts">
import { computed } from 'vue'

interface Shortcut {
  label: string
  value: [string, string] | (() => [string, string])
}

interface Props {
  modelValue: [string, string] | null
  format?: string
  valueFormat?: string
  showTime?: boolean
  placeholder?: string
  startPlaceholder?: string
  endPlaceholder?: string
  rangeSeparator?: string
  disabled?: boolean
  size?: 'large' | 'default' | 'small'
  shortcuts?: Shortcut[]
}

const props = withDefaults(defineProps<Props>(), {
  format: 'YYYY-MM-DD',
  valueFormat: 'YYYY-MM-DD',
  showTime: false,
  shortcuts: () => [
    { label: '今天', value: () => [today(), today()] },
    { label: '近7天', value: () => [daysAgo(7), today()] },
    { label: '近30天', value: () => [daysAgo(30), today()] },
    { label: '本月', value: () => [monthStart(), today()] },
    { label: '上月', value: () => [lastMonthStart(), lastMonthEnd()] },
    { label: '本年', value: () => [yearStart(), today()] },
  ],
  size: 'default',
})

const emit = defineEmits<{
  'update:modelValue': [val: [string, string] | null]
  change: [val: [string, string] | null]
}>()

const internalValue = computed({
  get: () => props.modelValue,
  set: (val) => {
    emit('update:modelValue', val)
    emit('change', val)
  },
})
</script>

<style scoped>
.xh-date-range {
  width: 100%;
}
</style>
