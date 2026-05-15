<template>
  <div class="xh-data-table">
    <!-- 批量操作工具栏 -->
    <BatchToolbar
      v-if="showBatchToolbar && selectedRows.length > 0"
      :selected-count="selectedRows.length"
      :actions="batchActions"
      @action="handleBatchAction"
    />

    <!-- 表格 -->
    <el-table
      ref="tableRef"
      v-loading="loading"
      :data="data"
      :stripe="stripe"
      :border="border"
      :size="size"
      :height="height"
      :max-height="maxHeight"
      :row-class-name="rowClassName"
      :expand-row-keys="expandRowKeys"
      :default-sort="defaultSort"
      :row-key="rowKey"
      :span-method="spanMethod"
      :show-header="showHeader"
      @selection-change="handleSelectionChange"
      @sort-change="handleSortChange"
      @row-click="handleRowClick"
      @row-dblclick="handleRowDblClick"
      @expand-change="handleExpandChange"
    >
      <!-- 选择列 -->
      <el-table-column
        v-if="selectable"
        type="selection"
        :width="selectionWidth"
        :fixed="selectionFixed"
        :selectable="selectable"
      />

      <!-- 序号列 -->
      <el-table-column
        v-if="showIndex"
        type="index"
        :label="indexLabel"
        :width="indexWidth"
        :fixed="indexFixed"
        :align="indexAlign || 'center'"
      />

      <!-- 展开列 -->
      <el-table-column v-if="expandable" type="expand" :width="40">
        <template #default="{ row }">
          <slot :name="expandSlot || 'expand'" :row="row" />
        </template>
      </el-table-column>

      <!-- 动态列 -->
      <el-table-column
        v-for="col in visibleColumns"
        :key="col.key"
        :prop="col.key"
        :label="col.label"
        :width="col.width"
        :min-width="col.minWidth"
        :fixed="col.fixed"
        :align="col.align || 'left'"
        :sortable="col.sortable"
        :column-key="col.key"
        :show-overflow-tooltip="col.showOverflowTooltip !== false"
        :class-name="col.className"
      >
        <!-- 列头插槽 -->
        <template #header>
          <slot :name="`header_${col.key}`">{{ col.label }}</slot>
        </template>

        <!-- 内容插槽 -->
        <template #default="{ row }">
          <!-- 自定义插槽 -->
          <slot v-if="col.slot" :name="col.slot" :row="row" :column="col" :value="row[col.key]" />

          <!-- 状态列 -->
          <StatusTag
            v-else-if="col.columnType === 'status'"
            :status="row[col.key]"
            :map="col.statusMap || {}"
            :size="col.tagSize || 'small'"
          />

          <!-- 日期列 -->
          <span
            v-else-if="col.columnType === 'date'"
            class="xh-data-table__cell"
          >
            {{ formatDateValue(row[col.key], col.format) }}
          </span>

          <!-- 日期时间列 -->
          <span
            v-else-if="col.columnType === 'datetime'"
            class="xh-data-table__cell"
          >
            {{ formatDateValue(row[col.key], col.format || 'YYYY-MM-DD HH:mm') }}
          </span>

          <!-- 金额列 -->
          <span
            v-else-if="col.columnType === 'currency'"
            class="xh-data-table__cell xh-data-table__cell--currency"
          >
            {{ formatCurrencyValue(row[col.key], col.prefix, col.precision) }}
          </span>

          <!-- 图片列 -->
          <div
            v-else-if="col.columnType === 'image'"
            class="xh-data-table__image-cell"
          >
            <el-image
              v-if="row[col.key]"
              :src="row[col.key]"
              :fit="'cover'"
              :preview-src-list="col.previewList ? col.previewList(row) : [row[col.key]]"
              :style="{
                width: col.imageWidth || '40px',
                height: col.imageHeight || '40px',
              }"
              class="xh-data-table__image"
            />
            <span v-else class="xh-data-table__cell">-</span>
          </div>

          <!-- 多图片列 -->
          <div
            v-else-if="col.columnType === 'images'"
            class="xh-data-table__images-cell"
          >
            <template v-if="row[col.key] && row[col.key].length > 0">
              <el-image
                v-for="(img, idx) in row[col.key].slice(0, 3)"
                :key="idx"
                :src="img"
                :fit="'cover'"
                :style="{
                  width: col.imageWidth || '32px',
                  height: col.imageHeight || '32px',
                }"
                class="xh-data-table__image"
              />
              <span v-if="row[col.key].length > 3" class="xh-data-table__images-more">
                +{{ row[col.key].length - 3 }}
              </span>
            </template>
            <span v-else class="xh-data-table__cell">-</span>
          </div>

          <!-- 标签列 -->
          <div
            v-else-if="col.columnType === 'tags'"
            class="xh-data-table__tags-cell"
          >
            <el-tag
              v-for="(tag, idx) in (row[col.key] || []).slice(0, 3)"
              :key="idx"
              :type="col.tagTypes?.[idx % col.tagTypes.length] || 'info'"
              size="small"
            >
              {{ tag }}
            </el-tag>
            <span v-if="(row[col.key] || []).length > 3" class="xh-data-table__cell">
              +{{ row[col.key].length - 3 }}
            </span>
          </div>

          <!-- 操作列 -->
          <div
            v-else-if="col.columnType === 'actions'"
            class="xh-data-table__actions-cell"
          >
            <template v-for="(action, idx) in col.actions" :key="action.key || idx">
              <el-divider v-if="action.dividerBefore" direction="vertical" />
              <el-button
                :type="action.type || 'default'"
                :size="action.size || 'small'"
                :icon="action.icon ? h('i', { class: `el-icon-${action.icon}` }) : undefined"
                :disabled="isActionDisabled(action, row)"
                :link="action.link"
                :type="action.type || 'primary'"
                :class="{ 'xh-data-table__action--danger': action.danger }"
                @click.stop="handleAction(action, row)"
              >
                {{ action.label }}
              </el-button>
            </template>
          </div>

          <!-- 默认文本 -->
          <span v-else class="xh-data-table__cell">
            {{ formatCellValue(row[col.key], col) }}
          </span>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div v-if="showPagination" class="xh-data-table__pagination">
      <el-pagination
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.pageSize"
        :total="pagination.total"
        :page-sizes="pageSizes"
        :background="true"
        :small="paginationSize === 'small'"
        :layout="paginationLayout"
        @current-change="handlePageChange"
        @size-change="handleSizeChange"
      />
      <span v-if="showTotal" class="xh-data-table__total">
        共 {{ pagination.total }} 条
      </span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, h } from 'vue'
import { ElMessage } from 'element-plus'
import StatusTag from '@/components/framework/Ui/StatusTag.vue'
import BatchToolbar from '@/components/framework/Layout/BatchToolbar.vue'
import { formatCurrency } from '@/utils/format'

export interface TableColumn {
  /** 列标识（对应字段名） */
  key: string
  /** 列标题 */
  label: string
  /** 列宽 */
  width?: string | number
  /** 最小宽度 */
  minWidth?: string | number
  /** 固定列 */
  fixed?: 'left' | 'right' | boolean
  /** 对齐 */
  align?: 'left' | 'center' | 'right'
  /** 是否可排序 */
  sortable?: boolean | 'custom'
  /** 列类型 */
  columnType?: 'status' | 'date' | 'datetime' | 'currency' | 'image' | 'images' | 'tags' | 'actions' | 'slot'
  /** 自定义插槽名 */
  slot?: string
  /** 状态映射（columnType=status时） */
  statusMap?: Record<string, any>
  /** 日期格式 */
  format?: string
  /** 金额前缀 */
  prefix?: string
  /** 金额精度 */
  precision?: number
  /** 图片尺寸 */
  imageWidth?: string
  imageHeight?: string
  /** 多图预览列表函数 */
  previewList?: (row: any) => string[]
  /** 标签类型数组 */
  tagTypes?: string[]
  /** 操作按钮列表 */
  actions?: Array<{
    key?: string
    label: string
    type?: string
    icon?: string
    size?: string
    disabled?: boolean | string | ((row: any) => boolean)
    danger?: boolean
    link?: boolean
    dividerBefore?: boolean
    confirm?: { title: string; message: string; type?: string }
  }>
  /** 显示配置 */
  show?: boolean
  showOverflowTooltip?: boolean
  className?: string
  tagSize?: 'large' | 'default' | 'small'
}

interface Pagination {
  page: number
  pageSize: number
  total: number
}

interface BatchAction {
  key: string
  label: string
  type?: string
  icon?: string
  danger?: boolean
}

interface Props {
  /** 表格数据 */
  data: Array<Record<string, any>>
  /** 列定义 */
  columns: TableColumn[]
  /** 加载状态 */
  loading?: boolean
  /** 是否可选择 */
  selectable?: boolean
  /** 选中行（v-model） */
  selectedRows?: Array<Record<string, any>>
  /** 是否斑马纹 */
  stripe?: boolean
  /** 是否边框 */
  border?: boolean
  /** 表格尺寸 */
  size?: 'large' | 'default' | 'small'
  /** 固定高度（px），设置后表格可滚动 */
  height?: string | number
  /** 最大高度 */
  maxHeight?: string | number
  /** 行class */
  rowClassName?: string | ((row: any, rowIndex: number) => string)
  /** 行唯一键 */
  rowKey?: string | ((row: any) => string)
  /** 展开行keys */
  expandRowKeys?: string[]
  /** 展开插槽名 */
  expandSlot?: string
  /** 默认排序 */
  defaultSort?: { prop: string; order: 'ascending' | 'descending' }
  /** 是否显示表头 */
  showHeader?: boolean
  /** 是否显示序号 */
  showIndex?: boolean
  /** 序号列宽度 */
  indexWidth?: number | string
  /** 序号列固定 */
  indexFixed?: 'left' | 'right' | boolean
  /** 序号列对齐 */
  indexAlign?: 'left' | 'center' | 'right'
  /** 序号列标签 */
  indexLabel?: string
  /** 选择列宽度 */
  selectionWidth?: number | string
  /** 选择列固定 */
  selectionFixed?: 'left' | 'right' | boolean
  /** 分页配置 */
  pagination?: Pagination
  /** 是否显示分页 */
  showPagination?: boolean
  /** 分页尺寸 */
  paginationSize?: 'default' | 'small'
  /** 每页条数选项 */
  pageSizes?: number[]
  /** 分页 layout */
  paginationLayout?: string
  /** 是否显示合计 */
  showSummary?: boolean
  /** 合计计算函数 */
  summaryMethod?: (params: { columns: any[]; data: any[] }) => any[]
  /** 合并单元格 */
  spanMethod?: (params: { row: any; column: any; rowIndex: number; columnIndex: number }) => [number, number] | undefined
  /** 是否显示批量工具栏 */
  showBatchToolbar?: boolean
  /** 批量操作按钮 */
  batchActions?: BatchAction[]
  /** 是否显示总数 */
  showTotal?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  selectable: false,
  selectedRows: () => [],
  stripe: true,
  border: false,
  size: 'default',
  showIndex: true,
  indexWidth: 60,
  indexLabel: '序号',
  showPagination: true,
  paginationSize: 'default',
  pageSizes: () => [10, 20, 50, 100],
  paginationLayout: 'total, sizes, prev, pager, next, jumper',
  showBatchToolbar: true,
  showTotal: true,
  showHeader: true,
})

const emit = defineEmits<{
  'update:selectedRows': [val: any[]]
  'sort-change': [params: { prop: string; order: string }]
  'row-click': [row: any]
  'row-dblclick': [row: any]
  'expand-change': [row: any, expanded: boolean]
  'batch-action': [key: string, rows: any[]]
  'page-change': [page: number]
  'size-change': [size: number]
}>()

const tableRef = ref()

const pagination = computed(() =>
  props.pagination || { page: 1, pageSize: 20, total: 0 }
)

/** 可见列 */
const visibleColumns = computed(() =>
  props.columns.filter((col) => col.show !== false)
)

function handleSelectionChange(selection: any[]) {
  emit('update:selectedRows', selection)
}

function handleSortChange({ prop, order }: { prop: string; order: string }) {
  emit('sort-change', { prop, order })
}

function handleRowClick(row: any) {
  emit('row-click', row)
}

function handleRowDblClick(row: any) {
  emit('row-dblclick', row)
}

function handleExpandChange(row: any, expanded: boolean) {
  emit('expand-change', row, expanded)
}

function handlePageChange(page: number) {
  emit('page-change', page)
}

function handleSizeChange(size: number) {
  emit('size-change', size)
}

function handleBatchAction(key: string) {
  emit('batch-action', key, props.selectedRows)
}

function isActionDisabled(action: any, row: any): boolean {
  if (typeof action.disabled === 'function') return action.disabled(row)
  if (typeof action.disabled === 'boolean') return action.disabled
  return false
}

function handleAction(action: any, row: any) {
  if (action.confirm) {
    ElMessageBox.confirm(action.confirm.message, action.confirm.title, {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: action.confirm.type || 'warning',
    })
      .then(() => {
        emit('action' as any, action.key || action.label, row)
      })
      .catch(() => {})
  } else {
    emit('action' as any, action.key || action.label, row)
  }
}

function formatDateValue(val: any, fmt?: string): string {
  if (!val) return '-'
  const d = new Date(val)
  if (isNaN(d.getTime())) return String(val)
  const format = fmt || 'YYYY-MM-DD'
  return format
    .replace('YYYY', String(d.getFullYear()))
    .replace('MM', String(d.getMonth() + 1).padStart(2, '0'))
    .replace('DD', String(d.getDate()).padStart(2, '0'))
    .replace('HH', String(d.getHours()).padStart(2, '0'))
    .replace('mm', String(d.getMinutes()).padStart(2, '0'))
    .replace('ss', String(d.getSeconds()).padStart(2, '0'))
}

function formatCurrencyValue(val: any, prefix = '¥', precision = 2): string {
  if (val == null || val === '') return '-'
  return formatCurrency(val, precision, prefix)
}

function formatCellValue(val: any, col: TableColumn): string {
  if (val == null || val === '') return '-'
  if (typeof val === 'boolean') return val ? '是' : '否'
  if (typeof val === 'number') return String(val)
  return String(val)
}

/** 暴露方法供外部调用 */
defineExpose({
  table: tableRef,
  toggleRowSelection: (row: any, selected?: boolean) => tableRef.value?.toggleRowSelection(row, selected),
  toggleAllSelection: () => tableRef.value?.toggleAllSelection(),
  clearSelection: () => tableRef.value?.clearSelection(),
  setCurrentRow: (row: any) => tableRef.value?.setCurrentRow(row),
})
</script>

<style scoped>
.xh-data-table__cell {
  font-size: 13px;
  color: #303133;
}

.xh-data-table__cell--currency {
  font-variant-numeric: tabular-nums;
  color: #e6a23c;
}

.xh-data-table__image-cell {
  display: flex;
  align-items: center;
}

.xh-data-table__images-cell {
  display: flex;
  align-items: center;
  gap: 4px;
}

.xh-data-table__images-more {
  font-size: 12px;
  color: #909399;
}

.xh-data-table__tags-cell {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.xh-data-table__actions-cell {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
}

.xh-data-table__action--danger {
  color: #f56c6c !important;
}

.xh-data-table__image {
  border-radius: 4px;
  cursor: pointer;
}

.xh-data-table__pagination {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 12px 0;
  gap: 12px;
}

.xh-data-table__total {
  font-size: 13px;
  color: #909399;
  white-space: nowrap;
}
</style>
