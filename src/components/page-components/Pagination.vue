<template>
  <div class="xh-pagination">
    <el-pagination
      v-model:current-page="internalPage"
      v-model:page-size="internalPageSize"
      :total="total"
      :page-sizes="pageSizes"
      :background="background"
      :small="size === 'small'"
      :layout="layout"
      :pager-count="pagerCount"
      @current-change="handleCurrentChange"
      @size-change="handleSizeChange"
    />
    <span v-if="showTotal" class="xh-pagination__total">
      共 {{ total }} 条
    </span>
  </div>
</template>

<script setup lang="ts">
import { computed, watch } from 'vue'

interface Props {
  /** v-model: { page, pageSize } */
  modelValue: { page: number; pageSize: number }
  /** 总数 */
  total: number
  /** 可选每页条数 */
  pageSizes?: number[]
  /** 背景色 */
  background?: boolean
  /** 尺寸 */
  size?: 'default' | 'small'
  /** layout */
  layout?: string
  /** 显示总数 */
  showTotal?: boolean
  /** 最大页码数 */
  pagerCount?: number
}

const props = withDefaults(defineProps<Props>(), {
  pageSizes: () => [10, 20, 50, 100],
  background: true,
  size: 'default',
  layout: 'total, sizes, prev, pager, next, jumper',
  showTotal: true,
  pagerCount: 7,
})

const emit = defineEmits<{
  'update:modelValue': [val: { page: number; pageSize: number }]
  change: [val: { page: number; pageSize: number }]
}>()

const internalPage = computed({
  get: () => props.modelValue.page,
  set: (val) => {
    emit('update:modelValue', { ...props.modelValue, page: val })
  },
})

const internalPageSize = computed({
  get: () => props.modelValue.pageSize,
  set: (val) => {
    emit('update:modelValue', { ...props.modelValue, pageSize: val, page: 1 })
  },
})

function handleCurrentChange(page: number) {
  emit('change', { page, pageSize: props.modelValue.pageSize })
}

function handleSizeChange(size: number) {
  emit('change', { page: 1, pageSize: size })
}
</script>

<style scoped>
.xh-pagination {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 12px;
  padding: 12px 0;
}

.xh-pagination__total {
  font-size: 13px;
  color: #909399;
  white-space: nowrap;
}
</style>
