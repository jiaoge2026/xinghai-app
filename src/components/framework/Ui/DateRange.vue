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

<script setup lang="ts">
import { computed } from 'vue'

interface Shortcut {
  label: string
  value: [string, string] | (() => [string, string])
}

interface Props {
  /** v-model: [startDate, endDate] */
  modelValue: [string, string] | null
  /** 显示格式，默认 'YYYY-MM-DD' */
  format?: string
  /** 值格式，默认 'YYYY-MM-DD' */
  valueFormat?: string
  /** 是否有时间选择（精确到秒） */
  showTime?: boolean
  placeholder?: string
  startPlaceholder?: string
  endPlaceholder?: string
  rangeSeparator?: string
  disabled?: boolean
  size?: 'large' | 'default' | 'small'
  /** 快捷选项，默认内置6个；传空数组[]禁用快捷选项 */
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

function today(): string {
  const d = new Date()
  return fmtDate(d)
}

function daysAgo(n: number): string {
  const d = new Date()
  d.setDate(d.getDate() - n)
  return fmtDate(d)
}

function monthStart(): string {
  const d = new Date()
  d.setDate(1)
  return fmtDate(d)
}

function lastMonthStart(): string {
  const d = new Date()
  d.setMonth(d.getMonth() - 1)
  d.setDate(1)
  return fmtDate(d)
}

function lastMonthEnd(): string {
  const d = new Date()
  d.setMonth(d.getMonth() - 1)
  const lastDay = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
  d.setDate(lastDay)
  return fmtDate(d)
}

function yearStart(): string {
  const d = new Date()
  d.setMonth(0)
  d.setDate(1)
  return fmtDate(d)
}

function fmtDate(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}
</script>

<style scoped>
.xh-date-range {
  width: 100%;
}
</style>
