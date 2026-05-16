<template>
  <div class="receivables-page">
    <!-- 搜索区 -->
    <div class="panel">
      <SearchForm
        :fields="searchFields"
        v-model="queryParams"
        @search="handleSearch"
        @reset="handleReset"
      />
    </div>

    <!-- 工具栏 -->
    <div class="panel toolbar">
      <el-button type="primary" @click="openAdd">
        <el-icon><Plus /></el-icon> 登记应收款
      </el-button>
    </div>

    <!-- 表格 -->
    <div class="panel">
      <DataTable
        ref="tableRef"
        :data="tableData"
        :columns="tableColumns"
        :loading="loading"
        :pagination="pagination"
        row-key="id"
        :show-pagination="true"
        @page-change="handlePageChange"
        @size-change="handleSizeChange"
        @action="handleTableAction"
      />
    </div>

    <!-- 新建/编辑弹窗 -->
    <CrudDialog
      v-model="dialogVisible"
      :mode="dialogMode"
      :fields="dialogFields"
      :model-value="formData"
      :saving="submitting"
      title=""
      width="550"
      @save="handleSave"
      @cancel="dialogVisible = false"
    />

    <!-- 收款弹窗 (separate, not using CrudDialog) -->
    <el-dialog v-model="receiveVisible" title="登记收款" width="400px" destroy-on-close>
      <el-form :model="receiveForm" ref="receiveRef" label-width="100px">
        <el-form-item label="应收单号">{{ receiveForm.receivableNo }}</el-form-item>
        <el-form-item label="待收金额">¥{{ pendingAmount.toLocaleString() }}</el-form-item>
        <el-form-item label="本次收款" prop="amount">
          <el-input-number v-model="receiveForm.amount" :min="0" :precision="2" style="width:100%" />
        </el-form-item>
        <el-form-item label="收款日期" prop="receiveDate">
          <el-date-picker v-model="receiveForm.receiveDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="receiveVisible = false">取消</el-button>
        <el-button type="primary" @click="handleReceiveSave">确认收款</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'
import { SearchForm, DataTable, CrudDialog } from '@/components/page-components'

// ============ 数据 ============
const loading = ref(false)
const tableData = ref([])
let pagination = reactive({ page: 1, pageSize: 20, total: 0 })
let queryParams = reactive({ keyword: '', status: '' })

// ============ 搜索 ============
const searchFields = [
  {
    key: 'keyword',
    label: '关键词',
    type: 'input',
    placeholder: '应收单号/客户名称',
    defaultValue: '',
  },
  {
    key: 'status',
    label: '状态',
    type: 'select',
    placeholder: '请选择状态',
    defaultValue: '',
    options: [
      { label: '未到期', value: 'PENDING' },
      { label: '已结清', value: 'RECEIVED' },
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
const tableRef = ref()

// Backend status: RECEIVED / PENDING
const statusMap = {
  RECEIVED: { label: '已结清', type: 'success' },
  PENDING: { label: '未到期', type: 'info' },
}

const tableColumns = [
  { key: 'receivableNo', label: '应收单号', width: 150 },
  { key: 'orderNo', label: '项目单号', width: 140 },
  { key: 'customerName', label: '客户名称', minWidth: 150 },
  {
    key: 'amount',
    label: '应收金额',
    width: 120,
    align: 'right',
    columnType: 'currency',
    prefix: '¥',
  },
  {
    key: 'receivedAmount',
    label: '已收金额',
    width: 120,
    align: 'right',
    columnType: 'currency',
    prefix: '¥',
  },
  {
    key: 'pendingAmount',
    label: '待收金额',
    width: 120,
    align: 'right',
    columnType: 'currency',
    prefix: '¥',
  },
  {
    key: 'dueDate',
    label: '到期日期',
    width: 120,
    columnType: 'date',
    format: 'YYYY-MM-DD',
  },
  {
    key: 'status',
    label: '状态',
    width: 100,
    align: 'center',
    columnType: 'status',
    statusMap,
  },
  {
    key: 'createTime',
    label: '创建时间',
    width: 160,
    columnType: 'datetime',
    format: 'YYYY-MM-DD HH:mm',
  },
  {
    key: 'actions',
    label: '操作',
    width: 160,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'edit', label: '编辑', type: 'primary', size: 'small', link: true },
      { key: 'receive', label: '收款', type: 'success', size: 'small', link: true },
      { key: 'delete', label: '删除', type: 'danger', size: 'small', link: true, danger: true },
    ],
  },
]

function handleTableAction(action, row) {
  if (action === 'edit') handleEdit(row)
  else if (action === 'delete') handleDelete(row)
  else if (action === 'receive') handleReceive(row)
}

function handlePageChange(page) {
  pagination.page = page
  loadData()
}

function handleSizeChange(size) {
  pagination.pageSize = size
  pagination.page = 1
  loadData()
}

// ============ 弹窗表单 ============
const dialogVisible = ref(false)
const dialogMode = ref('create') // 'create' | 'edit' | 'view'
const submitting = ref(false)
const editingId = ref(null)

const defaultForm = () => ({
  orderNo: '',
  customerName: '',
  amount: 0,
  receivedAmount: 0,
  dueDate: '',
  status: 'PENDING',
  remark: '',
})

let formData = reactive(defaultForm())

const dialogFields = [
  { key: 'orderNo', label: '项目单号', type: 'input', placeholder: '请输入项目单号', cols: 2 },
  { key: 'customerName', label: '客户名称', type: 'input', required: true, placeholder: '请输入客户名称', cols: 2 },
  { key: 'amount', label: '应收金额', type: 'number', required: true, min: 0, precision: 2, cols: 2 },
  { key: 'receivedAmount', label: '已收金额', type: 'number', min: 0, precision: 2, cols: 2 },
  { key: 'dueDate', label: '到期日期', type: 'date', valueFormat: 'YYYY-MM-DD', cols: 2 },
  {
    key: 'status',
    label: '状态',
    type: 'select',
    required: true,
    defaultValue: 'PENDING',
    options: [
      { label: '未到期', value: 'PENDING' },
      { label: '已结清', value: 'RECEIVED' },
    ],
    cols: 2,
  },
  { key: 'remark', label: '备注', type: 'textarea', placeholder: '请输入备注', cols: 2 },
]

function openAdd() {
  dialogMode.value = 'create'
  editingId.value = null
  Object.keys(defaultForm()).forEach(k => { formData[k] = defaultForm()[k] })
  dialogVisible.value = true
}

function handleEdit(row) {
  dialogMode.value = 'edit'
  editingId.value = row.id
  Object.keys(defaultForm()).forEach(k => {
    formData[k] = row[k] !== undefined ? row[k] : defaultForm()[k]
  })
  dialogVisible.value = true
}

async function handleSave(data) {
  submitting.value = true
  try {
    if (dialogMode.value === 'edit') {
      await request.put(`/sales/receivable/${editingId.value}`, data)
      ElMessage.success('编辑成功')
    } else {
      await request.post('/sales/receivable', data)
      ElMessage.success('新建成功')
    }
    dialogVisible.value = false
    loadData()
  } catch (e) {
    ElMessage.error(dialogMode.value === 'edit' ? '编辑失败' : '新建失败')
  } finally {
    submitting.value = false
  }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除应收款「${row.receivableNo}」？`, '确认删除', { type: 'warning' })
    await request.delete(`/sales/receivable/${row.id}`)
    ElMessage.success('已删除')
    loadData()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('删除失败')
  }
}

// ============ 收款弹窗 ============
const receiveVisible = ref(false)
const receiveRef = ref()
let receiveForm = reactive({
  id: null,
  receivableNo: '',
  amount: 0,
  totalAmount: 0,
  receivedAmount: 0,
  receiveDate: '',
})

const pendingAmount = computed(() =>
  (receiveForm.totalAmount || 0) - (receiveForm.receivedAmount || 0)
)

function handleReceive(row) {
  Object.assign(receiveForm, {
    id: row.id,
    receivableNo: row.receivableNo,
    totalAmount: row.amount || 0,
    receivedAmount: row.receivedAmount || 0,
    amount: 0,
    receiveDate: '',
  })
  receiveVisible.value = true
}

async function handleReceiveSave() {
  if (!receiveForm.amount || receiveForm.amount <= 0) {
    ElMessage.warning('请输入收款金额')
    return
  }
  try {
    // Note: Backend receive endpoint not implemented yet
    await request.post(`/sales/receivable/${receiveForm.id}/receive`, {
      amount: receiveForm.amount,
      receiveDate: receiveForm.receiveDate,
    })
    ElMessage.success('收款成功')
    receiveVisible.value = false
    loadData()
  } catch (e) {
    ElMessage.error('收款失败')
  }
}

// ============ 加载数据 ============
async function loadData() {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      pageSize: pagination.pageSize,
    }
    if (queryParams.keyword) params.keyword = queryParams.keyword
    if (queryParams.status) params.status = queryParams.status

    const res = await request.get('/sales/receivable/page', { params })
    const records = res.data?.records || res.data || []
    // Compute pendingAmount (amount - receivedAmount) for each row
    tableData.value = records.map(row => ({
      ...row,
      pendingAmount: (row.amount || 0) - (row.receivedAmount || 0),
    }))
    pagination.total = res.data?.total || 0
  } catch (e) {
    console.error(e)
    tableData.value = []
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>

<style scoped>
.receivables-page {
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

.toolbar {
  padding: 12px 16px;
}
</style>
