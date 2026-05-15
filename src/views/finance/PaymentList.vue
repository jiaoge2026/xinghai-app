<template>
  <div class="payment-list">
    <PageHeader title="付款单管理">
      <template #actions>
        <el-button type="primary" @click="openAdd">
          <el-icon><Plus /></el-icon> 新增付款单
        </el-button>
      </template>
    </PageHeader>

    <div class="panel">
      <SearchForm
        v-model="queryParams"
        :fields="searchFields"
        layout="inline"
        @search="handleSearch"
        @reset="handleReset"
      />
    </div>

    <div class="panel">
      <DataTable
        v-model:selected-rows="selectedRows"
        :data="tableData"
        :columns="tableColumns"
        :loading="loading"
        :pagination="pagination"
        :show-index="true"
        :index-width="60"
        row-key="id"
        @page-change="handlePageChange"
        @size-change="handleSizeChange"
        @action="handleTableAction"
      />
    </div>

    <!-- 查看详情弹窗 -->
    <el-dialog v-model="viewVisible" title="付款单详情" width="800px" destroy-on-close>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="付款单号">{{ viewData.paymentNo }}</el-descriptions-item>
        <el-descriptions-item label="付款日期">{{ viewData.paymentDate }}</el-descriptions-item>
        <el-descriptions-item label="供应商">{{ viewData.supplierName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="付款方式">
          <el-tag v-if="viewData.paymentMethod" :type="getPaymentMethodTag(viewData.paymentMethod)">
            {{ getPaymentMethodLabel(viewData.paymentMethod) }}
          </el-tag>
          <span v-else>-</span>
        </el-descriptions-item>
        <el-descriptions-item label="付款金额">
          <span class="amount">{{ viewData.amount != null ? '¥' + Number(viewData.amount).toFixed(2) : '-' }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="已核销金额">
          <span class="amount">{{ viewData.writtenOffAmount != null ? '¥' + Number(viewData.writtenOffAmount).toFixed(2) : '-' }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="未核销金额">
          <span class="amount">{{ viewData.unwrittenOffAmount != null ? '¥' + Number(viewData.unwrittenOffAmount).toFixed(2) : '-' }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="结算账户">{{ viewData.bankAccountName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="付款状态">
          <el-tag :type="getStatusTag(viewData.status)">
            {{ getStatusLabel(viewData.status) }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="关联单据" :span="2">{{ viewData.sourceType ? viewData.sourceType + ' - ' + viewData.sourceNo : '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewData.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
      <el-divider v-if="viewData.items && viewData.items.length" content-position="left">付款明细</el-divider>
      <el-table v-if="viewData.items && viewData.items.length" :data="viewData.items" stripe size="small">
        <el-table-column prop="invoiceNo" label="发票号" min-width="140" />
        <el-table-column prop="invoiceDate" label="发票日期" width="120" />
        <el-table-column prop="description" label="付款说明" min-width="160" show-overflow-tooltip />
        <el-table-column prop="amount" label="付款金额" width="120" align="right">
          <template #default="{ row }">{{ row.amount != null ? '¥' + Number(row.amount).toFixed(2) : '' }}</template>
        </el-table-column>
        <el-table-column prop="writtenOffAmount" label="已核销" width="100" align="right">
          <template #default="{ row }">{{ row.writtenOffAmount != null ? '¥' + Number(row.writtenOffAmount).toFixed(2) : '' }}</template>
        </el-table-column>
      </el-table>
    </el-dialog>

    <!-- 新增/编辑弹窗 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogMode === 'edit' ? '编辑付款单' : '新增付款单'"
      width="600px"
      destroy-on-close
    >
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="付款日期" prop="paymentDate">
          <el-date-picker
            v-model="formData.paymentDate"
            type="date"
            value-format="YYYY-MM-DD"
            placeholder="选择付款日期"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="供应商" prop="supplierId">
          <el-select v-model="formData.supplierId" placeholder="请选择供应商" style="width: 100%" filterable>
            <el-option
              v-for="supplier in supplierOptions"
              :key="supplier.value"
              :label="supplier.label"
              :value="supplier.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="付款方式" prop="paymentMethod">
          <el-select v-model="formData.paymentMethod" placeholder="请选择付款方式" style="width: 100%">
            <el-option label="银行转账" value="BANK_TRANSFER" />
            <el-option label="现金" value="CASH" />
            <el-option label="商业汇票" value="BILL" />
            <el-option label="其他" value="OTHER" />
          </el-select>
        </el-form-item>
        <el-form-item label="付款金额" prop="amount">
          <el-input-number
            v-model="formData.amount"
            :min="0"
            :precision="2"
            :controls="false"
            placeholder="请输入付款金额"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="结算账户" prop="bankAccountId">
          <el-select v-model="formData.bankAccountId" placeholder="请选择结算账户" style="width: 100%">
            <el-option
              v-for="account in bankAccountOptions"
              :key="account.value"
              :label="account.label"
              :value="account.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="关联单据" prop="sourceType">
          <el-input v-model="formData.sourceType" placeholder="如：采购订单" />
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="formData.remark" type="textarea" :rows="2" placeholder="请输入备注" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSave">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'
import { SearchForm, DataTable, PageHeader } from '@/components/page-components'

// ============ 常量 ============
const PAYMENT_METHOD_MAP = {
  BANK_TRANSFER: '银行转账',
  CASH: '现金',
  BILL: '商业汇票',
  OTHER: '其他',
}

const PAYMENT_STATUS_MAP = {
  PENDING: { label: '待审核', type: 'warning' },
  APPROVED: { label: '已审核', type: 'success' },
  PAID: { label: '已付款', type: 'success' },
  CANCELLED: { label: '已取消', type: 'info' },
}

const fmt = (v) => (v != null ? '¥' + Number(v).toFixed(2) : '-')

function getPaymentMethodLabel(method) {
  return PAYMENT_METHOD_MAP[method] || method || '-'
}

function getPaymentMethodTag(method) {
  const tags = { BANK_TRANSFER: '', CASH: 'success', BILL: 'warning', OTHER: 'info' }
  return tags[method] || 'info'
}

function getStatusLabel(status) {
  return PAYMENT_STATUS_MAP[status]?.label || status || '-'
}

function getStatusTag(status) {
  return PAYMENT_STATUS_MAP[status]?.type || 'info'
}

// ============ 表格数据 ============
const loading = ref(false)
const tableData = ref([])
const selectedRows = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })

// ============ 搜索 ============
const queryParams = reactive({
  paymentNo: '',
  supplierName: '',
  paymentMethod: null,
  status: null,
  startDate: '',
  endDate: '',
})

const searchFields = [
  { key: 'paymentNo', label: '付款单号', type: 'input', placeholder: '请输入付款单号' },
  { key: 'supplierName', label: '供应商', type: 'input', placeholder: '请输入供应商名称' },
  {
    key: 'paymentMethod',
    label: '付款方式',
    type: 'select',
    options: [
      { value: 'BANK_TRANSFER', label: '银行转账' },
      { value: 'CASH', label: '现金' },
      { value: 'BILL', label: '商业汇票' },
      { value: 'OTHER', label: '其他' },
    ],
  },
  {
    key: 'status',
    label: '状态',
    type: 'select',
    options: [
      { value: 'PENDING', label: '待审核' },
      { value: 'APPROVED', label: '已审核' },
      { value: 'PAID', label: '已付款' },
      { value: 'CANCELLED', label: '已取消' },
    ],
  },
  {
    key: 'dateRange',
    label: '日期范围',
    type: 'date-range',
    valueFormat: 'YYYY-MM-DD',
    startPlaceholder: '开始日期',
    endPlaceholder: '结束日期',
  },
]

// ============ 表格列定义 ============
const tableColumns = [
  { key: 'paymentNo', label: '付款单号', width: 160 },
  { key: 'paymentDate', label: '付款日期', width: 120 },
  { key: 'supplierName', label: '供应商', minWidth: 150 },
  {
    key: 'paymentMethod',
    label: '付款方式',
    width: 100,
    columnType: 'status',
    statusMap: PAYMENT_METHOD_MAP,
  },
  {
    key: 'amount',
    label: '付款金额',
    width: 130,
    columnType: 'currency',
    precision: 2,
  },
  {
    key: 'status',
    label: '状态',
    width: 90,
    align: 'center',
    columnType: 'status',
    statusMap: PAYMENT_STATUS_MAP.reduce((acc, { label }, key) => ({ ...acc, [key]: label }), {}),
  },
  { key: 'bankAccountName', label: '结算账户', width: 140 },
  { key: 'createTime', label: '创建时间', width: 160, columnType: 'datetime' },
  {
    key: 'actions',
    label: '操作',
    width: 160,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'view', label: '查看', type: 'primary', link: true },
      { key: 'edit', label: '编辑', type: 'primary', link: true },
      { key: 'delete', label: '删除', type: 'danger', link: true, danger: true },
    ],
  },
]

// ============ 弹窗 ============
const viewVisible = ref(false)
const viewData = ref({})
const dialogVisible = ref(false)
const dialogMode = ref('create')
const submitting = ref(false)
const editingId = ref(null)

const defaultForm = () => ({
  paymentDate: '',
  supplierId: null,
  paymentMethod: '',
  amount: null,
  bankAccountId: null,
  sourceType: '',
  sourceNo: '',
  remark: '',
})

const formData = reactive({ ...defaultForm() })

const formRules = {
  paymentDate: [{ required: true, message: '请选择付款日期', trigger: 'change' }],
  supplierId: [{ required: true, message: '请选择供应商', trigger: 'change' }],
  paymentMethod: [{ required: true, message: '请选择付款方式', trigger: 'change' }],
  amount: [{ required: true, message: '请输入付款金额', trigger: 'blur' }],
}

// 供应商选项（实际应从接口获取）
const supplierOptions = ref([])
const bankAccountOptions = ref([])

// ============ 数据操作 ============
const fetchData = async () => {
  loading.value = true
  try {
    const params = {
      pageNum: pagination.page,
      pageSize: pagination.pageSize,
      paymentNo: queryParams.paymentNo || undefined,
      supplierName: queryParams.supplierName || undefined,
      paymentMethod: queryParams.paymentMethod || undefined,
      status: queryParams.status || undefined,
      startDate: queryParams.startDate || undefined,
      endDate: queryParams.endDate || undefined,
    }
    // 删除空值
    Object.keys(params).forEach((k) => {
      if (params[k] === '' || params[k] === null || params[k] === undefined) {
        delete params[k]
      }
    })
    const res = await request.get('/finance/payments', { params })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch {
    tableData.value = []
    pagination.total = 0
  } finally {
    loading.value = false
  }
}

// 加载供应商列表
async function loadSuppliers() {
  try {
    const res = await request.get('/finance/suppliers', { params: { pageNum: 1, pageSize: 1000 } })
    supplierOptions.value = (res.data?.list || []).map((s) => ({
      value: s.id,
      label: s.supplierName || s.name,
    }))
  } catch {
    supplierOptions.value = []
  }
}

// 加载银行账户列表
async function loadBankAccounts() {
  try {
    const res = await request.get('/finance/bank-accounts', { params: { pageNum: 1, pageSize: 1000 } })
    bankAccountOptions.value = (res.data?.list || []).map((a) => ({
      value: a.id,
      label: a.accountName || a.bankAccountName,
    }))
  } catch {
    bankAccountOptions.value = []
  }
}

const handleSearch = (params) => {
  Object.assign(queryParams, params)
  if (params.dateRange) {
    queryParams.startDate = params.dateRange[0] || ''
    queryParams.endDate = params.dateRange[1] || ''
  }
  pagination.page = 1
  fetchData()
}

const handleReset = () => {
  Object.assign(queryParams, {
    paymentNo: '',
    supplierName: '',
    paymentMethod: null,
    status: null,
    startDate: '',
    endDate: '',
  })
  pagination.page = 1
  fetchData()
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
  if (action === 'view') openView(row)
  else if (action === 'edit') openEdit(row)
  else if (action === 'delete') openDelete(row)
}

// ============ 弹窗操作 ============
async function openView(row) {
  try {
    const res = await request.get('/finance/payments/' + row.id)
    viewData.value = res.data || row
    viewVisible.value = true
  } catch {
    viewData.value = { ...row }
    viewVisible.value = true
  }
}

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
    paymentDate: row.paymentDate || '',
    supplierId: row.supplierId,
    paymentMethod: row.paymentMethod || '',
    amount: row.amount,
    bankAccountId: row.bankAccountId,
    sourceType: row.sourceType || '',
    sourceNo: row.sourceNo || '',
    remark: row.remark || '',
  })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm(
      `确定删除付款单「${row.paymentNo}」？`,
      '确认删除',
      { type: 'warning' }
    )
    await request.delete('/finance/payments/' + row.id)
    ElMessage.success('删除成功')
    fetchData()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('删除失败')
  }
}

async function handleSave() {
  submitting.value = true
  try {
    if (dialogMode.value === 'edit') {
      await request.put('/finance/payments/' + editingId.value, formData)
      ElMessage.success('编辑成功')
    } else {
      await request.post('/finance/payments', formData)
      ElMessage.success('新增成功')
    }
    dialogVisible.value = false
    fetchData()
  } catch (e) {
    ElMessage.error(dialogMode.value === 'edit' ? '编辑失败' : '新增失败')
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  fetchData()
  loadSuppliers()
  loadBankAccounts()
})
</script>

<style scoped>
.payment-list {
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

.amount {
  color: #e6a23c;
  font-weight: 500;
}
</style>
