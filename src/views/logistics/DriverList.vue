<template>
  <div class="driver-list">
    <PageHeader title="司机管理">
      <template #actions>
        <el-button type="primary" @click="openAdd">
          <el-icon><Plus /></el-icon> 新增司机
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

const statusLabel = { 1: '空闲', 2: '配送中', 3: '离线' }
const statusType = { 1: 'success', 2: 'primary', 3: 'info' }

// ============ 数据 ============
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })
const queryParams = reactive({ name: '', plateNo: '', status: null })

// ============ 搜索 ============
const searchFields = [
  { key: 'name', label: '姓名', type: 'input', placeholder: '司机姓名' },
  { key: 'plateNo', label: '车牌号', type: 'input', placeholder: '车牌号' },
  {
    key: 'status',
    label: '状态',
    type: 'select',
    placeholder: '全部',
    clearable: true,
    options: [
      { label: '空闲', value: 1 },
      { label: '配送中', value: 2 },
      { label: '离线', value: 3 },
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
  { key: 'name', label: '姓名', minWidth: 100 },
  { key: 'phone', label: '手机号', width: 130 },
  { key: 'plateNo', label: '车牌号', width: 120 },
  { key: 'vehicleType', label: '车型', minWidth: 100 },
  { key: 'licenseNo', label: '驾照号', minWidth: 180, showOverflowTooltip: true },
  {
    key: 'status',
    label: '状态',
    width: 100,
    align: 'center',
    columnType: 'status',
    statusMap: { 1: { label: '空闲', type: 'success' }, 2: { label: '配送中', type: 'primary' }, 3: { label: '离线', type: 'info' } },
  },
  { key: 'deliveryCount', label: '配送次数', width: 100, align: 'center' },
  {
    key: 'actions',
    label: '操作',
    width: 150,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'edit', label: '编辑', type: 'primary', size: 'small', link: true },
      { key: 'delete', label: '删除', type: 'danger', size: 'small', link: true, danger: true },
    ],
  },
]

function handleTableAction(action, row) {
  if (action === 'edit') openEdit(row)
  else if (action === 'delete') openDelete(row)
}

function handlePageChange(page) { pagination.page = page; loadData() }
function handleSizeChange(size) { pagination.pageSize = size; pagination.page = 1; loadData() }

// ============ 弹窗表单 ============
const dialogVisible = ref(false)
const dialogMode = ref('create')
const submitting = ref(false)
const editingId = ref(null)

const defaultForm = () => ({
  name: '',
  phone: '',
  plateNo: '',
  vehicleType: '',
  licenseNo: '',
  status: 1,
})

const formData = reactive(defaultForm())

const dialogFields = [
  { key: 'name', label: '姓名', type: 'input', required: true, placeholder: '司机姓名' },
  { key: 'phone', label: '手机号', type: 'input', required: true, placeholder: '11位手机号' },
  { key: 'plateNo', label: '车牌号', type: 'input', required: true, placeholder: '如：京A12345' },
  { key: 'vehicleType', label: '车型', type: 'input', placeholder: '如：厢式货车' },
  { key: 'licenseNo', label: '驾照号', type: 'input', placeholder: '驾驶证号码' },
  {
    key: 'status',
    label: '状态',
    type: 'select',
    options: [
      { label: '空闲', value: 1 },
      { label: '配送中', value: 2 },
      { label: '离线', value: 3 },
    ],
  },
]

function openAdd() {
  dialogMode.value = 'create'
  editingId.value = null
  Object.keys(defaultForm()).forEach(k => { formData[k] = defaultForm()[k] })
  dialogVisible.value = true
}

function openEdit(row) {
  dialogMode.value = 'edit'
  editingId.value = row.id
  Object.assign(formData, {
    name: row.name,
    phone: row.phone,
    plateNo: row.plateNo,
    vehicleType: row.vehicleType || '',
    licenseNo: row.licenseNo || '',
    status: row.status || 1,
  })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除司机「${row.name}」？`, '提示', { type: 'warning' })
    await request.delete(`/logistics/drivers/${row.id}`)
    ElMessage.success('已删除')
    loadData()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('删除失败')
  }
}

async function handleSave(data) {
  submitting.value = true
  try {
    if (dialogMode.value === 'edit') {
      await request.put(`/logistics/drivers/${editingId.value}`, data)
      ElMessage.success('编辑成功')
    } else {
      await request.post('/logistics/drivers', data)
      ElMessage.success('新增成功')
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
    const res = await request.get('/logistics/drivers', { params })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>

<style scoped>
.driver-list {
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
