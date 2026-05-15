<template>
  <div class="project-orders">
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
            page-path="/sales/project-orders"
            @change="onColumnConfigChange"
          >
            <template #trigger>
              <el-icon class="seq-settings-btn"><Setting /></el-icon>
            </template>
          </ColumnSettings>
        </template>
      
      </DataTable>
    </div>

    <!-- 查看详情弹窗 -->
    <el-dialog v-model="viewVisible" title="订单详情" width="700px" destroy-on-close>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="订单号">{{ viewData.orderNo }}</el-descriptions-item>
        <el-descriptions-item label="订单日期">{{ viewData.orderDate }}</el-descriptions-item>
        <el-descriptions-item label="客户ID">{{ viewData.customerId }}</el-descriptions-item>
        <el-descriptions-item label="是否需要FSM">
          <el-tag :type="viewData.requireFsm === 1 ? 'success' : 'info'" size="small">
            {{ viewData.requireFsm === 1 ? '是' : '否' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="订单金额">¥{{ viewData.totalAmount }}</el-descriptions-item>
        <el-descriptions-item label="已收金额">¥{{ viewData.receivedAmount }}</el-descriptions-item>
        <el-descriptions-item label="订单状态">{{ viewData.status }}</el-descriptions-item>
        <el-descriptions-item label="FSM工单状态">{{ viewData.fsmOrderStatus }}</el-descriptions-item>
        <el-descriptions-item label="确认日期">{{ viewData.confirmDate }}</el-descriptions-item>
        <el-descriptions-item label="发货日期">{{ viewData.shippedDate }}</el-descriptions-item>
        <el-descriptions-item label="安装日期">{{ viewData.installedDate }}</el-descriptions-item>
        <el-descriptions-item label="配送地址" :span="2">{{ viewData.deliveryAddress || '-' }}</el-descriptions-item>
        <el-descriptions-item label="配送联系人">{{ viewData.deliveryContact }}</el-descriptions-item>
        <el-descriptions-item label="配送电话">{{ viewData.deliveryPhone }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewData.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogMode === 'edit' ? '编辑订单' : '新增订单'" width="600px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="110px">
        <el-form-item label="客户ID" prop="customerId">
          <el-input-number v-model="formData.customerId" :min="1" style="width:100%" />
        </el-form-item>
        <el-form-item label="订单日期" prop="orderDate">
          <el-date-picker v-model="formData.orderDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
        <el-form-item label="是否需要FSM" prop="requireFsm">
          <el-select v-model="formData.requireFsm" style="width:100%">
            <el-option :value="1" label="是" />
            <el-option :value="0" label="否" />
          </el-select>
        </el-form-item>
        <el-form-item label="配送地址" prop="deliveryAddress">
          <el-input v-model="formData.deliveryAddress" type="textarea" :rows="2" />
        </el-form-item>
        <el-form-item label="配送联系人" prop="deliveryContact">
          <el-input v-model="formData.deliveryContact" />
        </el-form-item>
        <el-form-item label="配送电话" prop="deliveryPhone">
          <el-input v-model="formData.deliveryPhone" />
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
const queryParams = reactive({ keyword: '', startDate: '', endDate: '', status: '' })

const searchFields = [
  { key: 'keyword', label: '关键词', type: 'input', placeholder: '订单号/客户ID' },
  { key: 'status', label: '状态', type: 'select', placeholder: '全部', clearable: true, options: [] },
  {
    key: 'dateRange',
    label: '签订日期',
    type: 'date-range',
    valueFormat: 'YYYY-MM-DD',
    startPlaceholder: '开始',
    endPlaceholder: '结束',
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
  Object.assign(queryParams, { keyword: '', startDate: '', endDate: '', status: '' })
  pagination.page = 1
  loadData()
}


// Column settings
// mergedColumns uses tableColumns directly (plain array)
const onColumnConfigChange = (cols) => { Object.assign(tableColumns, cols) }

const tableColumns = [
  { key: '__seq__', label: '', width: 60, show: true, fixed: 'left', columnType: 'seq' },
  
  { key: 'orderNo', label: '订单号', width: 170 },
  { key: 'orderDate', label: '订单日期', width: 110 },
  { key: 'customerId', label: '客户ID', width: 80 },
  {
    key: 'requireFsm',
    label: 'FSM',
    width: 60,
    align: 'center',
    columnType: 'map',
    maps: { 1: { label: '是', type: 'success' }, 0: { label: '否', type: 'info' } },
  },
  { key: 'totalAmount', label: '订单金额', width: 110, align: 'right', formatter: (v) => v != null ? '¥' + Number(v).toFixed(2) : '' },
  { key: 'receivedAmount', label: '已收金额', width: 110, align: 'right', formatter: (v) => v != null ? '¥' + Number(v).toFixed(2) : '' },
  { key: 'status', label: '订单状态', width: 100 },
  { key: 'fsmOrderStatus', label: 'FSM状态', width: 100 },
  { key: 'deliveryContact', label: '联系人', width: 100 },
  { key: 'deliveryPhone', label: '电话', width: 130 },
  { key: 'createTime', label: '创建时间', width: 160 },
  {
    key: 'actions',
    label: '操作',
    width: 150,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'view', label: '查看', type: 'primary', size: 'small', link: true },
      { key: 'edit', label: '编辑', type: 'primary', size: 'small', link: true },
      { key: 'delete', label: '删除', type: 'danger', size: 'small', link: true, danger: true },
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
  orderDate: '',
  requireFsm: 1,
  deliveryAddress: '',
  deliveryContact: '',
  deliveryPhone: '',
  remark: '',
})

const formData = reactive({ ...defaultForm() })
const formRules = {
  customerId: [{ required: true, message: '请输入客户ID', trigger: 'blur' }],
  orderDate: [{ required: true, message: '请选择订单日期', trigger: 'change' }],
}

async function openView(row) {
  try {
    const res = await request.get('/sales/project-order/' + row.id)
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
    customerId: row.customerId,
    orderDate: row.orderDate || '',
    requireFsm: row.requireFsm,
    deliveryAddress: row.deliveryAddress || '',
    deliveryContact: row.deliveryContact || '',
    deliveryPhone: row.deliveryPhone || '',
    remark: row.remark || '',
  })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm('\u786e\u5b9a\u5220\u9664\u8ba2\u5355\u300c' + row.orderNo + '\u300d\uff1f', '\u786e\u8ba4\u5220\u9664', { type: 'warning' })
    await request.delete('/sales/project-order/' + row.id)
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
      await request.put('/sales/project-order/' + editingId.value, formData)
      ElMessage.success('\u7f16\u8f91\u6210\u529f')
    } else {
      await request.post('/sales/project-order', formData)
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
    const res = await request.get('/sales/project-order/page', {
      params: {
        pageNum: pagination.page,
        pageSize: pagination.pageSize,
        keyword: queryParams.keyword || undefined,
        startDate: queryParams.startDate || undefined,
        endDate: queryParams.endDate || undefined,
        status: queryParams.status || undefined,
      },
    })
    tableData.value = res.data?.records || []
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
.project-orders { padding: 12px; display: flex; flex-direction: column; gap: 12px; }
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