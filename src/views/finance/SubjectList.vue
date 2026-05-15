<template>
  <div class="page">
    <el-card>

      <SearchForm
        v-model="queryParams"
        :fields="searchFields"
        layout="inline"
        @search="handleSearch"
        @reset="handleReset"
      />

      <DataTable
        v-model:selected-rows="selectedRows"
        :data="tableData"
        :columns="tableColumns"
        :loading="loading"
        :pagination="pagination"
        :show-index="false"
        :index-width="60"
        row-key="id"
        @sort-change="handleSortChange"
        @page-change="handlePageChange"
        @size-change="handleSizeChange"
        @action="handleTableAction">

        <template #header___seq__>
          <span>序号</span>
          <ColumnSettings
            :columns="tableColumns"
            page-path="/finance/subjects"
            @change="onColumnConfigChange"
          >
            <template #trigger>
              <el-icon class="seq-settings-btn"><Setting /></el-icon>
            </template>
          </ColumnSettings>
        </template>
      
      </DataTable>

      <CrudDialog
        v-model="dialogVisible"
        :mode="dialogMode"
        :title="dialogTitle"
        :fields="dialogFields"
        v-model:model-value="dialogForm"
        :saving="submitting"
        width="600px"
        label-width="100px"
        @save="handleSave"
        @cancel="handleDialogCancel"
      />
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Setting } from '@element-plus/icons-vue'
import request from '@/utils/request'
import SearchForm from '@/components/page-components/SearchForm.vue'
import DataTable from '@/components/page-components/DataTable.vue'
import ColumnSettings from '@/views/components/ColumnSettings.vue'
import CrudDialog from '@/components/page-components/CrudDialog.vue'

// ============ 常量 ============
const SUBJECT_TYPE_MAP = {
  ASSET: '资产',
  LIABILITY: '负债',
  EQUITY: '权益',
  REVENUE: '收入',
  EXPENSE: '费用',
}

const BALANCE_DIRECTION_MAP = {
  DEBIT: '借',
  CREDIT: '贷',
}

const STATUS_MAP = {
  1: { label: '启用', type: 'success' },
  0: { label: '停用', type: 'info' },
}

// ============ 表格数据 ============
const loading = ref(false)
const tableData = ref([])
const selectedRows = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })

// ============ 搜索 ============
const queryParams = reactive({
  subjectCode: '',
  subjectName: '',
  subjectType: null,
  status: null,
})

const searchFields = [
  { key: 'subjectCode', label: '科目编码', type: 'input', placeholder: '请输入科目编码' },
  { key: 'subjectName', label: '科目名称', type: 'input', placeholder: '请输入科目名称' },
  {
    key: 'subjectType',
    label: '科目类型',
    type: 'select',
    options: Object.entries(SUBJECT_TYPE_MAP).map(([value, label]) => ({ value, label })),
  },
  {
    key: 'status',
    label: '状态',
    type: 'select',
    options: [
      { value: 1, label: '启用' },
      { value: 0, label: '停用' },
    ],
  },
]

// ============ 表格列定义 ============

// Column settings
// mergedColumns uses tableColumns directly (plain array)
const onColumnConfigChange = (cols) => { Object.assign(tableColumns, cols) }

const tableColumns = [
  { key: '__seq__', label: '', width: 60, show: true, fixed: 'left', columnType: 'seq' },
  
  { key: 'subjectCode', label: '科目编码', width: 120 },
  { key: 'subjectName', label: '科目名称', minWidth: 150 },
  {
    key: 'subjectType',
    label: '科目类型',
    width: 100,
    columnType: 'status',
    statusMap: SUBJECT_TYPE_MAP,
  },
  { key: 'balanceDirection', label: '余额方向', width: 90, columnType: 'status', statusMap: BALANCE_DIRECTION_MAP },
  {
    key: 'status',
    label: '状态',
    width: 80,
    columnType: 'status',
    statusMap: STATUS_MAP,
  },
  { key: 'initialBalance', label: '期初余额', width: 120, columnType: 'currency', precision: 2 },
  { key: 'currentBalance', label: '当前余额', width: 120, columnType: 'currency', precision: 2 },
  { key: 'createTime', label: '创建时间', width: 160, columnType: 'datetime' },
  {
    key: 'actions',
    label: '操作',
    width: 160,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'view', label: '查看', type: 'default' },
      { key: 'edit', label: '编辑', type: 'primary' },
      { key: 'delete', label: '删除', type: 'danger', danger: true },
    ],
  },
]

// ============ 弹窗 ============
const dialogVisible = ref(false)
const dialogMode = ref('create') // create | edit | view
const submitting = ref(false)
const dialogForm = ref({})

const dialogTitle = computed(() => {
  const titles = { create: '新增科目', edit: '编辑科目', view: '查看科目' }
  return titles[dialogMode.value]
})

// 科目类型选项
const subjectTypeOptions = Object.entries(SUBJECT_TYPE_MAP).map(([value, label]) => ({ value, label }))
// 余额方向选项
const balanceDirectionOptions = Object.entries(BALANCE_DIRECTION_MAP).map(([value, label]) => ({ value, label }))
// 状态选项
const statusOptions = [
  { value: 1, label: '启用' },
  { value: 0, label: '停用' },
]

const dialogFields = [
  { key: 'subjectCode', label: '科目编码', type: 'input', required: true, placeholder: '请输入科目编码' },
  { key: 'subjectName', label: '科目名称', type: 'input', required: true, placeholder: '请输入科目名称' },
  {
    key: 'subjectType',
    label: '科目类型',
    type: 'select',
    required: true,
    options: subjectTypeOptions,
  },
  {
    key: 'balanceDirection',
    label: '余额方向',
    type: 'select',
    required: true,
    options: balanceDirectionOptions,
  },
  { key: 'initialBalance', label: '期初余额', type: 'number', defaultValue: 0, precision: 2 },
  {
    key: 'status',
    label: '状态',
    type: 'select',
    defaultValue: 1,
    options: statusOptions,
  },
]

// ============ 数据操作 ============
const fetchData = async () => {
  loading.value = true
  try {
    const params = {
      ...queryParams,
      pageNum: pagination.page,
      pageSize: pagination.pageSize,
    }
    // 删除空值
    Object.keys(params).forEach((k) => {
      if (params[k] === '' || params[k] === null || params[k] === undefined) {
        delete params[k]
      }
    })
    const res = await request.get('/finance/subjects', { params })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch {
    tableData.value = []
    pagination.total = 0
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  pagination.page = 1
  fetchData()
}

const handleReset = () => {
  pagination.page = 1
  fetchData()
}

const handleSortChange = ({ prop, order }) => {
  // 暂不支持后端排序
}

const handlePageChange = (page) => {
  pagination.page = page
  fetchData()
}

const handleSizeChange = (size) => {
  pagination.pageSize = size
  pagination.page = 1
  fetchData()
}

const handleTableAction = (action, row) => {
  if (action === 'view') {
    dialogMode.value = 'view'
    dialogForm.value = { ...row }
    dialogVisible.value = true
  } else if (action === 'edit') {
    dialogMode.value = 'edit'
    dialogForm.value = { ...row }
    dialogVisible.value = true
  } else if (action === 'delete') {
    handleDelete(row)
  }
}

// ============ 弹窗操作 ============
const handleCreate = () => {
  dialogMode.value = 'create'
  dialogForm.value = {
    initialBalance: 0,
    status: 1,
  }
  dialogVisible.value = true
}

const handleSave = async (formData) => {
  submitting.value = true
  try {
    if (dialogMode.value === 'create') {
      await request.post('/finance/subjects', formData)
      ElMessage.success('新增成功')
    } else {
      await request.put(`/finance/subjects/${formData.id}`, formData)
      ElMessage.success('编辑成功')
    }
    dialogVisible.value = false
    fetchData()
  } finally {
    submitting.value = false
  }
}

const handleDelete = async (row) => {
  await ElMessageBox.confirm(`确定删除科目「${row.subjectName}」？`, '提示', { type: 'warning' })
  await request.delete(`/finance/subjects/${row.id}`)
  ElMessage.success('删除成功')
  fetchData()
}

const handleDialogCancel = () => {
  dialogVisible.value = false
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.page {
  padding: 16px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* seq column toolbar */
.table-header-bar {
  display: flex;
  align-items: center;
  justify-content: center;
}
.seq-settings-btn { cursor: pointer; color: #909399; transition: color 0.2s; }
.seq-settings-btn:hover { color: #409eff; }

</style>