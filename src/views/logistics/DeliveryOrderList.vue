<template>
  <div class="delivery-order-list">
    <PageHeader title="配送单管理">
      <template #actions>
        <el-button type="primary" @click="openAdd">
          <el-icon><Plus /></el-icon> 新建配送单
        </el-button>
      </template>
    </PageHeader>

    <div class="panel">
      <SearchForm
        :fields="searchFields"
        v-model="queryParams"
        @search="handleSearch"
        @reset="handleReset"
      />
    </div>

    <div class="panel">
      <DataTable
        :data="tableData"
        :columns="tableColumns"
        :loading="loading"
        :pagination="pagination"
        row-key="id"
        @page-change="handlePageChange"
        @size-change="handleSizeChange"
        @action="handleTableAction"
      />
    </div>

    <!-- 查看详情弹窗 -->
    <CrudDialog
      v-model="viewDialogVisible"
      mode="view"
      title="配送单详情"
      :fields="viewFields"
      :model-value="viewData"
    />

    <!-- 新增/编辑弹窗 -->
    <CrudDialog
      v-model="dialogVisible"
      :mode="dialogMode"
      :fields="dialogFields"
      :model-value="formData"
      :saving="submitting"
      @save="handleSave"
      @cancel="dialogVisible = false"
    />
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'
import { SearchForm, DataTable, CrudDialog, PageHeader } from '@/components/page-components'

const statusLabel = { 1: '待配送', 2: '配送中', 3: '已完成', 4: '已取消' }
const statusType = { 1: 'warning', 2: 'primary', 3: 'success', 4: 'info' }
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })
const queryParams = reactive({ deliveryNo: '', driverId: null, status: null })
const driverOptions = ref([])

// ============ 搜索 ============
const searchFields = [
  { key: 'deliveryNo', label: '配送单号', type: 'input', placeholder: '配送单号' },
  {
    key: 'driverId',
    label: '司机',
    type: 'select',
    placeholder: '全部',
    clearable: true,
    options: [],
  },
  {
    key: 'status',
    label: '状态',
    type: 'select',
    placeholder: '全部',
    clearable: true,
    options: [
      { label: '待配送', value: 1 },
      { label: '配送中', value: 2 },
      { label: '已完成', value: 3 },
      { label: '已取消', value: 4 },
    ],
  },
]

function handleSearch(params) {
  Object.assign(queryParams, params)
  pagination.page = 1
  loadData()
}

function handleReset(params) {
  Object.assign(queryParams, params)
  pagination.page = 1
  loadData()
}

// ============ 表格 ============
const tableColumns = [
  { key: 'deliveryNo', label: '配送单号', width: 170 },
  { key: 'driverName', label: '司机', minWidth: 100 },
  { key: 'plateNo', label: '车牌号', width: 120 },
  { key: 'totalQuantity', label: '配送数量', width: 100, align: 'center' },
  {
    key: 'status',
    label: '状态',
    width: 100,
    align: 'center',
    columnType: 'status',
    statusMap: { 1: { label: '待配送', type: 'warning' }, 2: { label: '配送中', type: 'primary' }, 3: { label: '已完成', type: 'success' }, 4: { label: '已取消', type: 'info' } },
  },
  { key: 'planDate', label: '计划日期', width: 120 },
  { key: 'actualDate', label: '完成时间', width: 120 },
  { key: 'remark', label: '备注', minWidth: 150, showOverflowTooltip: true },
  {
    key: 'actions',
    label: '操作',
    width: 150,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'view', label: '详情', type: 'primary', size: 'small', link: true },
      { key: 'edit', label: '编辑', type: 'primary', size: 'small', link: true },
    ],
  },
]

function handleTableAction(action, row) {
  if (action === 'view') openView(row)
  else if (action === 'edit') openEdit(row)
}

function handlePageChange(page) { pagination.page = page; loadData() }
function handleSizeChange(size) { pagination.pageSize = size; pagination.page = 1; loadData() }

// ============ 弹窗表单 ============
const dialogVisible = ref(false)
const dialogMode = ref('create')
const submitting = ref(false)
const editingId = ref(null)

const defaultForm = () => ({
  driverId: null,
  planDate: '',
  remark: '',
})

const formData = reactive(defaultForm())

const dialogFields = [
  {
    key: 'driverId',
    label: '司机',
    type: 'select',
    required: true,
    placeholder: '选择司机',
    filterable: true,
    options: [],
  },
  {
    key: 'planDate',
    label: '计划日期',
    type: 'date',
    required: true,
    dateType: 'date',
    valueFormat: 'YYYY-MM-DD',
  },
  { key: 'remark', label: '备注', type: 'textarea', placeholder: '备注信息', rows: 2 },
]

// 详情弹窗
const viewDialogVisible = ref(false)
const viewData = ref({})
const viewFields = [
  { key: 'deliveryNo', label: '配送单号', type: 'static' },
  { key: 'status', label: '状态', type: 'static' },
  { key: 'driverName', label: '司机', type: 'static' },
  { key: 'plateNo', label: '车牌号', type: 'static' },
  { key: 'planDate', label: '计划日期', type: 'static' },
  { key: 'actualDate', label: '完成时间', type: 'static' },
  { key: 'remark', label: '备注', type: 'static', cols: 2 },
]

function openAdd() {
  dialogMode.value = 'create'
  editingId.value = null
  Object.assign(formData, defaultForm())
  dialogVisible.value = true
}

function openEdit(row) {
  dialogMode.value = 'edit'
  editingId.value = row.id
  Object.assign(formData, {
    driverId: row.driverId,
    planDate: row.planDate,
    remark: row.remark || '',
  })
  dialogVisible.value = true
}

function openView(row) {
  viewData.value = {
    ...row,
    status: statusLabel[row.status] || row.status,
  }
  viewDialogVisible.value = true
}

async function handleSave(data) {
  submitting.value = true
  try {
    if (dialogMode.value === 'edit') {
      await request.put(`/logistics/delivery-orders/${editingId.value}`, data)
      ElMessage.success('编辑成功')
    } else {
      await request.post('/logistics/delivery-orders', data)
      ElMessage.success('新建成功')
    }
    dialogVisible.value = false
    loadData()
  } catch {
    ElMessage.error(dialogMode.value === 'edit' ? '编辑失败' : '新增失败')
  } finally {
    submitting.value = false
  }
}

// ============ 加载 ============
async function loadData() {
  loading.value = true
  try {
    const params = { pageNum: pagination.page, pageSize: pagination.pageSize, ...queryParams }
    Object.keys(params).forEach(k => { if (params[k] === null || params[k] === '') delete params[k] })
    const res = await request.get('/logistics/delivery-orders', { params })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

async function fetchDrivers() {
  try {
    const res = await request.get('/logistics/drivers')
    driverOptions.value = res.data?.list || []
    // update driver options in search and dialog fields
    const driverOpts = driverOptions.value.map(d => ({ label: d.name, value: d.id }))
    const searchDriverField = searchFields.find(f => f.key === 'driverId')
    if (searchDriverField) searchDriverField.options = driverOpts
    const dialogDriverField = dialogFields.find(f => f.key === 'driverId')
    if (dialogDriverField) dialogDriverField.options = driverOpts
  } catch {
    driverOptions.value = []
  }
}

onMounted(() => { loadData(); fetchDrivers() })
</script>

<style scoped>
.delivery-order-list {
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.panel {
  background: #fff;
  border-radius: 4px;
  padding: 12px 16px;
}
</style>
