<template>
  <div class="receipt-list">
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
        :show-index="false"
        :data="tableData"
        :columns="tableColumns"
        :loading="loading"
        :pagination="pagination"
        row-key="id"
        @page-change="handlePageChange"
        @size-change="handleSizeChange"
        @action="handleTableAction">

        <template #header___seq__>
          <span>序号</span>
          <ColumnSettings
            :columns="tableColumns"
            page-path="/finance/receipts"
            @change="onColumnConfigChange"
          >
            <template #trigger>
              <el-icon class="seq-settings-btn"><Setting /></el-icon>
            </template>
          </ColumnSettings>
        </template>
      
      </DataTable>
    </div>

    <!-- 查看详情 -->
    <el-dialog v-model="viewVisible" title="收款单详情" width="650px" destroy-on-close>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="收款单号">{{ viewData.receiptNo }}</el-descriptions-item>
        <el-descriptions-item label="收款日期">{{ viewData.receiptDate }}</el-descriptions-item>
        <el-descriptions-item label="客户ID">{{ viewData.customerId }}</el-descriptions-item>
        <el-descriptions-item label="收款金额">¥{{ viewData.amount }}</el-descriptions-item>
        <el-descriptions-item label="收款方式">{{ viewData.paymentMethod }}</el-descriptions-item>
        <el-descriptions-item label="银行账户">{{ viewData.bankAccount }}</el-descriptions-item>
        <el-descriptions-item label="关联订单">{{ viewData.orderNo || '-' }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="statusTagType(viewData.status)" size="small">{{ statusLabel(viewData.status) }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewData.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>

    <!-- 新增/编辑 -->
    <el-dialog v-model="dialogVisible" :title="dialogMode === 'edit' ? '编辑收款单' : '新增收款单'" width="550px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="客户ID" prop="customerId">
          <el-input-number v-model="formData.customerId" :min="1" style="width:100%" />
        </el-form-item>
        <el-form-item label="收款日期" prop="receiptDate">
          <el-date-picker v-model="formData.receiptDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
        <el-form-item label="收款金额" prop="amount">
          <el-input-number v-model="formData.amount" :min="0" :precision="2" :controls="false" style="width:100%" />
        </el-form-item>
        <el-form-item label="收款方式" prop="paymentMethod">
          <el-select v-model="formData.paymentMethod" style="width:100%">
            <el-option label="银行转账" value="BANK_TRANSFER" />
            <el-option label="现金" value="CASH" />
            <el-option label="票据" value="BILL" />
            <el-option label="其他" value="OTHER" />
          </el-select>
        </el-form-item>
        <el-form-item label="银行账户" prop="bankAccount">
          <el-input v-model="formData.bankAccount" placeholder="银行账户" />
        </el-form-item>
        <el-form-item label="关联订单" prop="orderNo">
          <el-input v-model="formData.orderNo" placeholder="关联订单号（可选）" />
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="formData.remark" type="textarea" :rows="2" />
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
import { SearchForm, DataTable} from '@/components/page-components'
import ColumnSettings from '@/views/components/ColumnSettings.vue'
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Setting } from '@element-plus/icons-vue'
import request from '@/utils/request'

const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })
const queryParams = reactive({ receiptNo: '', customerId: null, status: '', startDate: '', endDate: '' })

const searchFields = [
  { key: 'receiptNo', label: '收款单号', type: 'input', placeholder: '收款单号' },
  {
    key: 'dateRange',
    label: '日期范围',
    type: 'date-range',
    valueFormat: 'YYYY-MM-DD',
    startPlaceholder: '开始日期',
    endPlaceholder: '结束日期',
  },
]

function handleSearch(params) {
  Object.assign(queryParams, params)
  if (params.dateRange) {
    queryParams.startDate = params.dateRange[0] || ''
    queryParams.endDate = params.dateRange[1] || ''
  }
  pagination.page = 1
  loadData()
}

function handleReset(params) {
  Object.assign(queryParams, { receiptNo: '', customerId: null, status: '', startDate: '', endDate: '' })
  pagination.page = 1
  loadData()
}

const statusMap = { RECEIVED: { label: '\u5df2\u6536\u6b3e', type: 'success' }, PENDING: { label: '\u5f85\u6536\u6b3e', type: 'warning' }, CANCELLED: { label: '\u5df2\u53d6\u6d88', type: 'info' } }
function statusLabel(s) { return statusMap[s]?.label || s || '-' }
function statusTagType(s) { return statusMap[s]?.type || 'info' }


// Column settings
// mergedColumns uses tableColumns directly (plain array)
const onColumnConfigChange = (cols) => { Object.assign(tableColumns, cols) }

const tableColumns = [
  { key: '__seq__', label: '', width: 60, show: true, fixed: 'left', columnType: 'seq' },
  
  { key: 'receiptNo', label: '收款单号', width: 170 },
  { key: 'receiptDate', label: '收款日期', width: 110 },
  { key: 'customerId', label: '客户ID', width: 80 },
  {
    key: 'amount',
    label: '收款金额',
    width: 120,
    align: 'right',
    formatter: (v) => v != null ? '\u00a5' + Number(v).toFixed(2) : '',
  },
  { key: 'paymentMethod', label: '收款方式', width: 110 },
  { key: 'bankAccount', label: '银行账户', minWidth: 150, showOverflowTooltip: true },
  { key: 'orderNo', label: '关联订单', width: 160 },
  {
    key: 'status',
    label: '状态',
    width: 90,
    align: 'center',
    columnType: 'map',
    maps: statusMap,
  },
  { key: 'createTime', label: '创建时间', width: 160 },
  {
    key: 'actions',
    label: '操作',
    width: 150,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'view', label: '\u67e5\u770b', type: 'primary', size: 'small', link: true },
      { key: 'edit', label: '\u7f16\u8f91', type: 'primary', size: 'small', link: true },
      { key: 'delete', label: '\u5220\u9664', type: 'danger', size: 'small', link: true, danger: true },
    ],
  },
]

function handleTableAction(action, row) {
  if (action === 'view') openView(row)
  else if (action === 'edit') openEdit(row)
  else if (action === 'delete') openDelete(row)
}

function handlePageChange(page) { pagination.page = page; loadData() }
function handleSizeChange(size) { pagination.pageSize = size; pagination.page = 1; loadData() }

const viewVisible = ref(false)
const viewData = ref({})
const dialogVisible = ref(false)
const dialogMode = ref('create')
const submitting = ref(false)
const editingId = ref(null)

const defaultForm = () => ({
  customerId: null,
  receiptDate: '',
  amount: null,
  paymentMethod: 'BANK_TRANSFER',
  bankAccount: '',
  orderNo: '',
  remark: '',
})

const formData = reactive({ ...defaultForm() })
const formRules = {
  customerId: [{ required: true, message: '\u8bf7\u8f93\u5165\u5ba2\u6237ID', trigger: 'blur' }],
  receiptDate: [{ required: true, message: '\u8bf7\u9009\u62e9\u6536\u6b3e\u65e5\u671f', trigger: 'change' }],
  amount: [{ required: true, message: '\u8bf7\u8f93\u5165\u6536\u6b3e\u91d1\u989d', trigger: 'blur' }],
}

async function openView(row) {
  viewData.value = { ...row }
  viewVisible.value = true
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
    customerId: row.customerId,
    receiptDate: row.receiptDate || '',
    amount: row.amount,
    paymentMethod: row.paymentMethod || 'BANK_TRANSFER',
    bankAccount: row.bankAccount || '',
    orderNo: row.orderNo || '',
    remark: row.remark || '',
  })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm('\u786e\u5b9a\u5220\u9664\u6536\u6b3e\u5355\u300c' + row.receiptNo + '\u300d\uff1f', '\u786e\u8ba4\u5220\u9664', { type: 'warning' })
    await request.delete('/finance/receipts/' + row.id)
    ElMessage.success('\u5df2\u5220\u9664')
    loadData()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('\u5220\u9664\u5931\u8d25')
  }
}

async function handleSave() {
  submitting.value = true
  try {
    if (dialogMode.value === 'edit') {
      await request.put('/finance/receipts/' + editingId.value, formData)
      ElMessage.success('\u7f16\u8f91\u6210\u529f')
    } else {
      await request.post('/finance/receipts', formData)
      ElMessage.success('\u65b0\u589e\u6210\u529f')
    }
    dialogVisible.value = false
    loadData()
  } catch {
    ElMessage.error(dialogMode.value === 'edit' ? '\u7f16\u8f91\u5931\u8d25' : '\u65b0\u589e\u5931\u8d25')
  } finally {
    submitting.value = false
  }
}

async function loadData() {
  loading.value = true
  try {
    const res = await request.get('/finance/receipts', {
      params: {
        pageNum: pagination.page,
        pageSize: pagination.pageSize,
        receiptNo: queryParams.receiptNo || undefined,
        customerId: queryParams.customerId || undefined,
        startDate: queryParams.startDate || undefined,
        endDate: queryParams.endDate || undefined,
      },
    })
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
.receipt-list { padding: 12px; display: flex; flex-direction: column; gap: 12px; }
.panel { background: #fff; border-radius: 4px; padding: 12px 16px; }

/* seq column toolbar */
.table-header-bar {
  display: flex;
  align-items: center;
  justify-content: center;
}
.seq-settings-btn { cursor: pointer; color: #909399; transition: color 0.2s; }
.seq-settings-btn:hover { color: #409eff; }

</style>