<template>
  <div class="voucher-list">
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
            page-path="/finance/vouchers"
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
    <el-dialog v-model="viewVisible" title="凭证详情" width="700px" destroy-on-close>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="凭证号">{{ viewData.voucherNo }}</el-descriptions-item>
        <el-descriptions-item label="制单日期">{{ viewData.voucherDate }}</el-descriptions-item>
        <el-descriptions-item label="会计期间">{{ viewData.period }}</el-descriptions-item>
        <el-descriptions-item label="附件数">{{ viewData.attachCount }}</el-descriptions-item>
        <el-descriptions-item label="制单人ID">{{ viewData.makerId }}</el-descriptions-item>
        <el-descriptions-item label="审核人ID">{{ viewData.approverId }}</el-descriptions-item>
        <el-descriptions-item label="审核时间">{{ viewData.approveTime }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="viewData.status === 'POSTED' ? 'success' : 'info'">
            {{ viewData.status === 'POSTED' ? '已审核' : '草稿' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="来源类型" :span="2">{{ viewData.sourceType || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewData.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
      <el-divider v-if="viewData.details && viewData.details.length" content-position="left">明细</el-divider>
      <el-table v-if="viewData.details && viewData.details.length" :data="viewData.details" stripe size="small">
        <el-table-column prop="subjectName" label="会计科目" min-width="150" />
        <el-table-column prop="summary" label="摘要" min-width="200" show-overflow-tooltip />
        <el-table-column prop="debitAmount" label="借方金额" width="130" align="right">
          <template #default="{ row }">{{ row.debitAmount != null ? fmt(row.debitAmount) : '' }}</template>
        </el-table-column>
        <el-table-column prop="creditAmount" label="贷方金额" width="130" align="right">
          <template #default="{ row }">{{ row.creditAmount != null ? fmt(row.creditAmount) : '' }}</template>
        </el-table-column>
      </el-table>
    </el-dialog>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogMode === 'edit' ? '编辑凭证' : '新增凭证'" width="550px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="凭证号" prop="voucherNo">
          <el-input v-model="formData.voucherNo" placeholder="系统自动生成，可手动填写" />
        </el-form-item>
        <el-form-item label="制单日期" prop="voucherDate">
          <el-date-picker v-model="formData.voucherDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
        <el-form-item label="会计期间" prop="period">
          <el-input v-model="formData.period" placeholder="格式：2026-05" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="formData.status" style="width:100%">
            <el-option label="草稿" value="DRAFT" />
            <el-option label="已审核" value="POSTED" />
          </el-select>
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
let pagination = reactive({ page: 1, pageSize: 20, total: 0 })
let queryParams = reactive({ voucherNo: '', startDate: '', endDate: '' })

const searchFields = [
  { key: 'voucherNo', label: '凭证号', type: 'input', placeholder: '凭证号' },
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
  Object.assign(queryParams, { voucherNo: '', startDate: '', endDate: '' })
  pagination.page = 1
  loadData()
}


// Column settings
// mergedColumns uses tableColumns directly (plain array)
const onColumnConfigChange = (cols) => { Object.assign(tableColumns, cols) }

const tableColumns = [
  { key: '__seq__', label: '', width: 60, show: true, fixed: 'left', columnType: 'seq' },
  
  { key: 'voucherNo', label: '凭证号', width: 160 },
  { key: 'voucherDate', label: '制单日期', width: 120 },
  { key: 'period', label: '会计期间', width: 100 },
  { key: 'attachCount', label: '附件', width: 70, align: 'center' },
  {
    key: 'status',
    label: '状态',
    width: 90,
    align: 'center',
    columnType: 'map',
    maps: { POSTED: { label: '已审核', type: 'success' }, DRAFT: { label: '草稿', type: 'info' } },
  },
  { key: 'makerId', label: '制单人', width: 80 },
  { key: 'approveTime', label: '审核时间', width: 160 },
  {
    key: 'actions',
    label: '操作',
    width: 160,
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
  voucherNo: '',
  voucherDate: '',
  period: '',
  attachCount: 0,
  status: 'DRAFT',
  sourceType: '',
  sourceId: null,
  remark: '',
})

let formData = reactive({ ...defaultForm() })
const formRules = {
  voucherDate: [{ required: true, message: '请选择制单日期', trigger: 'change' }],
}

const fmt = (v) => v != null ? '¥' + Number(v).toFixed(2) : ''

async function openView(row) {
  try {
    const res = await request.get('/finance/vouchers/' + row.id)
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
    voucherNo: row.voucherNo || '',
    voucherDate: row.voucherDate || '',
    period: row.period || '',
    attachCount: row.attachCount || 0,
    status: row.status || 'DRAFT',
    sourceType: row.sourceType || '',
    sourceId: row.sourceId,
    remark: row.remark || '',
  })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm('\u786e\u5b9a\u5220\u9664\u51ed\u8bc1\u300c' + row.voucherNo + '\u300d\uff1f', '\u786e\u8ba4\u5220\u9664', { type: 'warning' })
    await request.delete('/finance/vouchers/' + row.id)
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
      await request.put('/finance/vouchers/' + editingId.value, formData)
      ElMessage.success('\u7f16\u8f91\u6210\u529f')
    } else {
      await request.post('/finance/vouchers', formData)
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
    const params = {
      page: pagination.page,
      pageSize: pagination.pageSize,
      voucherNo: queryParams.voucherNo || undefined,
      startDate: queryParams.startDate || undefined,
      endDate: queryParams.endDate || undefined,
    }
    const res = await request.get('/finance/vouchers', { params })
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
.voucher-list { padding: 12px; display: flex; flex-direction: column; gap: 12px; }
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