<template>
  <div class="xh-search-form">
    <!-- 主搜索区 -->
    <el-form
      ref="formRef"
      :model="internalValue"
      :inline="layout === 'inline'"
      :class="{ 'xh-search-form--grid': layout === 'grid' }"
      @submit.prevent="handleSearch"
    >
      <el-form-item
        v-for="field in visibleFields"
        :key="field.key"
        :label="field.label"
        :prop="field.key"
        :class="layout === 'grid' ? `xh-search-form__item--col-${field.cols || 1}` : ''"
      >
        <!-- Input -->
        <el-input
          v-if="field.type === 'input'"
          v-model="internalValue[field.key]"
          :placeholder="field.placeholder || `请输入${field.label}`"
          :clearable="true"
          :size="size"
          :disabled="field.disabled"
          @keyup.enter="handleSearch"
        />

        <!-- Select -->
        <el-select
          v-else-if="field.type === 'select'"
          v-model="internalValue[field.key]"
          :placeholder="field.placeholder || `请选择${field.label}`"
          :clearable="true"
          :size="size"
          :disabled="field.disabled"
          :options="field.options"
          style="width: 100%"
        >
          <el-option
            v-for="opt in field.options"
            :key="opt.value"
            :label="opt.label"
            :value="opt.value"
          />
        </el-select>

        <!-- Date Range（使用已有的DateRange组件） -->
        <DateRange
          v-else-if="field.type === 'date-range'"
          v-model="internalValue[field.key]"
          :size="size"
          :show-time="field.showTime"
          :shortcuts="field.shortcuts"
        />

        <!-- Date（单日期） -->
        <el-date-picker
          v-else-if="field.type === 'date'"
          v-model="internalValue[field.key]"
          :type="field.dateType || 'date'"
          :placeholder="field.placeholder || `选择${field.label}`"
          :format="field.format"
          :value-format="field.valueFormat || 'YYYY-MM-DD'"
          :size="size"
          :disabled="field.disabled"
          clearable
          style="width: 100%"
        />

        <!-- Cascader -->
        <el-cascader
          v-else-if="field.type === 'cascader'"
          v-model="internalValue[field.key]"
          :options="field.options"
          :props="field.cascaderProps || { checkStrictly: true, emitPath: false }"
          :placeholder="field.placeholder || `选择${field.label}`"
          :size="size"
          :disabled="field.disabled"
          clearable
          filterable
          style="width: 100%"
        />

        <!-- Number -->
        <el-input-number
          v-else-if="field.type === 'number'"
          v-model="internalValue[field.key]"
          :min="field.min"
          :max="field.max"
          :precision="field.precision"
          :size="size"
          :disabled="field.disabled"
          controls-position="right"
          style="width: 100%"
        />

        <!-- Status Select（专用状态选择） -->
        <el-select
          v-else-if="field.type === 'status-select'"
          v-model="internalValue[field.key]"
          :placeholder="field.placeholder || `选择${field.label}`"
          :clearable="true"
          :size="size"
          style="width: 100%"
        >
          <el-option
            v-for="(label, val) in field.map"
            :key="val"
            :label="typeof label === 'string' ? label : label.label"
            :value="val"
          />
        </el-select>
      </el-form-item>

      <!-- 操作按钮 -->
      <el-form-item class="xh-search-form__actions">
        <el-button type="primary" :size="size" @click="handleSearch">
          <el-icon><Search /></el-icon>
          查询
        </el-button>
        <el-button :size="size" @click="handleReset">
          <el-icon><RefreshLeft /></el-icon>
          重置
        </el-button>
        <el-button
          v-if="showAdvanced && advancedFields.length > 0"
          type="default"
          :size="size"
          link
          @click="showAdvancedPanel = !showAdvancedPanel"
        >
          {{ showAdvancedPanel ? '收起' : '高级筛选' }}
          <el-icon>
            <ArrowUp v-if="showAdvancedPanel" />
            <ArrowDown v-else />
          </el-icon>
        </el-button>
      </el-form-item>
    </el-form>

    <!-- 高级筛选折叠区 -->
    <div v-if="showAdvanced && showAdvancedPanel" class="xh-search-form__advanced">
      <el-form
        ref="advancedFormRef"
        :model="internalValue"
        :inline="layout === 'inline'"
        class="xh-search-form__advanced-form"
      >
        <el-form-item
          v-for="field in advancedVisibleFields"
          :key="field.key"
          :label="field.label"
        >
          <!-- 同上，字段类型处理 -->
          <el-input
            v-if="field.type === 'input'"
            v-model="internalValue[field.key]"
            :placeholder="field.placeholder"
            :size="size"
            clearable
          />
          <el-select
            v-else-if="field.type === 'select' || field.type === 'status-select'"
            v-model="internalValue[field.key]"
            :placeholder="field.placeholder || `选择${field.label}`"
            clearable
            :size="size"
            style="width: 100%"
          >
            <el-option
              v-for="(opt, val) in field.type === 'status-select' ? field.map : field.options"
              :key="field.type === 'status-select' ? val : opt.value"
              :label="field.type === 'status-select'
                ? (typeof field.map[val] === 'string' ? field.map[val] : field.map[val]?.label)
                : opt.label"
              :value="val"
            />
          </el-select>
        </el-form-item>
      </el-form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { Search, RefreshLeft, ArrowUp, ArrowDown } from '@element-plus/icons-vue'
import DateRange from '@/components/framework/Ui/DateRange.vue'

export interface SearchField {
  key: string
  label: string
  type: 'input' | 'select' | 'date-range' | 'date' | 'cascader' | 'number' | 'status-select'
  placeholder?: string
  /** 字段默认空值 */
  defaultValue?: any
  /** 字段宽度（grid布局下占用列数，默认1，最大4） */
  cols?: number
  /** 是否高级筛选字段 */
  advanced?: boolean
  /** 字段级别（普通/高级） */
  level?: 'basic' | 'advanced'
  // select 专用
  options?: Array<{ label: string; value: any }>
  // status-select 专用
  map?: Record<string, any>
  // date 专用
  dateType?: 'date' | 'datetime' | 'week' | 'month' | 'year'
  format?: string
  valueFormat?: string
  showTime?: boolean
  shortcuts?: Array<{ label: string; value: [string, string] | (() => [string, string]) }>
  // cascader 专用
  cascaderProps?: Record<string, any>
  options?: Array<any>
  // number 专用
  min?: number
  max?: number
  precision?: number
  // 通用
  disabled?: boolean
  // 事件
  events?: Record<string, Function>
}

interface Props {
  /** v-model: 搜索参数对象 */
  modelValue: Record<string, any>
  /** 字段定义 */
  fields: SearchField[]
  /** 布局：inline=单行/grid=多行网格 */
  layout?: 'inline' | 'grid'
  /** grid 布局列数，默认4 */
  columns?: number
  /** 是否显示高级筛选按钮 */
  showAdvanced?: boolean
  /** 高级筛选字段的 key 列表 */
  advancedFields?: string[]
  /** 尺寸 */
  size?: 'large' | 'default' | 'small'
}

const props = withDefaults(defineProps<Props>(), {
  layout: 'inline',
  columns: 4,
  showAdvanced: false,
  advancedFields: () => [],
  size: 'default',
})

const emit = defineEmits<{
  'update:modelValue': [val: Record<string, any>]
  search: [val: Record<string, any>]
  reset: []
}>()

const formRef = ref()
const advancedFormRef = ref()
const showAdvancedPanel = ref(false)

/** 内部值（深度拷贝，避免直接修改 prop） */
const internalValue = ref<Record<string, any>>({})

/** 初始化默认值 */
watch(
  () => props.modelValue,
  (val) => {
    const merged = { ...val }
    props.fields.forEach((f) => {
      if (merged[f.key] === undefined) {
        merged[f.key] = f.defaultValue ?? null
      }
    })
    internalValue.value = merged
  },
  { immediate: true }
)

/** 普通字段 */
const visibleFields = computed(() =>
  props.fields.filter((f) => {
    if (props.showAdvanced && f.level === 'advanced') return false
    if (typeof f.show === 'boolean' && !f.show) return false
    return true
  })
)

/** 高级字段 */
const advancedVisibleFields = computed(() =>
  props.fields.filter((f) => {
    if (!props.showAdvanced) return false
    return props.advancedFields.includes(f.key)
  })
)

/** 防抖搜索 */
let searchTimer: ReturnType<typeof setTimeout> | null = null
function handleSearch() {
  if (searchTimer) clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    const params = { ...internalValue.value }
    // 过滤掉空值
    Object.keys(params).forEach((k) => {
      if (params[k] === '' || params[k] === null || params[k] === undefined) {
        delete params[k]
      }
    })
    emit('update:modelValue', params)
    emit('search', params)
  }, 300)
}

function handleReset() {
  const defaults: Record<string, any> = {}
  props.fields.forEach((f) => {
    defaults[f.key] = f.defaultValue ?? null
  })
  internalValue.value = { ...defaults }
  emit('update:modelValue', defaults)
  emit('reset')
}
</script>

<style scoped>
.xh-search-form {
  padding: 16px;
  background: #fff;
  border-radius: 4px;
}

.xh-search-form--grid {
  display: grid;
  grid-template-columns: repeat(v-bind(columns), 1fr);
  gap: 0 16px;
}

.xh-search-form :deep(.el-form-item) {
  margin-bottom: 12px;
}

.xh-search-form :deep(.el-form-item__label) {
  font-size: 13px;
  color: #606266;
}

.xh-search-form__actions {
  margin-left: auto;
}

.xh-search-form__advanced {
  border-top: 1px dashed #ebeef5;
  padding-top: 12px;
  margin-top: 4px;
}
</style>
