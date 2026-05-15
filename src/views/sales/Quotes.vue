<template>
  <div class="quotes-page">
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
            page-path="/sales/quotes"
            @change="onColumnConfigChange"
          >
            <template #trigger>
              <el-icon class="seq-settings-btn"><Setting /></el-icon>
            </template>
          </ColumnSettings>
        </template>
      
      </DataTable>
    </div>

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
import { SearchForm, DataTable} from '@/components/page-components'
import ColumnSettings from '@/views/components/ColumnSettings.vue'
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Setting } from '@element-plus/icons-vue'
import request from '@/utils/request'

// ============ 数据 ============
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })
const queryParams = reactive({ keyword: '', status: null })

// ============ 搜索 ============
// Backend status values unknown - using placeholder, verify from actual data
const searchFields = [
  { key: 'keyword', label: '关键词', type: 'input', placeholder: '报价单号' },
  {
    key: 'status',
    label: '状态',
    type: 'select',
    placeholder: '全部',
    clearable: true,
    options: [
      { label: '草稿', value: 'draft' },
      { label: '已发送', value: 'sent' },
      { label: '已确认', value: 'confirmed' },
      { label: '已作废', value: 'cancelled' },
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

// Column settings
// mergedColumns uses tableColumns directly (plain array)
const onColumnConfigChange = (cols) => { Object.assign(tableColumns, cols) }

const tableColumns = [
  { key: '__seq__', label: '', width: 60, show: true, fixed: 'left', columnType: 'seq' },
  
  { key: 'quoteNo', label: '报价单号', width: 150 },
  { key: 'customerId', label: '客户ID', width: 100 },
  {
    key: 'totalAmount',
    label: '报价总额',
    width: 120,
    align: 'right',
    columnType: 'currency',
    prefix: '¥',
    precision: 2,
  },
  {
    key: 'status',
    label: '状态',
    width: 100,
    align: 'center',
    columnType: 'map',
    maps: {
      draft: { label: '草稿', type: 'info' },
      sent: { label: '已发送', type: 'warning' },
      confirmed: { label: '已确认', type: 'success' },
      cancelled: { label: '已作废', type: 'danger' },
    },
  },
  { key: 'validUntil', label: '有效期至', width: 120, columnType: 'date' },
  { key: 'createTime', label: '创建时间', width: 160, columnType: 'datetime' },
  {
    key: 'actions',
    label: '操作',
    width: 140,
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
// Backend entity: SalesQuote { id, quoteNo, customerId, opportunityId, accountId,
//   requireFsm, subtotal, discountAmount, taxAmount, totalAmount, status,
//   validUntil, sentDate, confirmedDate, remark, createTime }
const dialogVisible = ref(false)
const dialogMode = ref('create')
const submitting = ref(false)
const editingId = ref(null)

const defaultForm = () => ({
  customerId: null,
  opportunityId: null,
  requireFsm: 0,
  subtotal: 0,
  discountAmount: 0,
  taxAmount: 0,
  totalAmount: 0,
  status: 'draft',
  validUntil: '',
  remark: '',
})

const formData = reactive(defaultForm())

const dialogFields = [
  { key: 'customerId', label: '客户', type: 'input', required: true, placeholder: '客户ID' },
  { key: 'totalAmount', label: '报价总额', type: 'number', required: true, min: 0, precision: 2 },
  {
    key: 'status',
    label: '状态',
    type: 'select',
    options: [
      { label: '草稿', value: 'draft' },
      { label: '已发送', value: 'sent' },
      { label: '已确认', value: 'confirmed' },
      { label: '已作废', value: 'cancelled' },
    ],
  },
  { key: 'validUntil', label: '有效期至', type: 'date', valueFormat: 'YYYY-MM-DD' },
  { key: 'remark', label: '备注', type: 'textarea', placeholder: '备注信息' },
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
    customerId: row.customerId,
    opportunityId: row.opportunityId,
    requireFsm: row.requireFsm || 0,
    subtotal: row.subtotal || 0,
    discountAmount: row.discountAmount || 0,
    taxAmount: row.taxAmount || 0,
    totalAmount: row.totalAmount || 0,
    status: row.status || 'draft',
    validUntil: row.validUntil || '',
    remark: row.remark || '',
  })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除报价单「${row.quoteNo}」？`, '确认删除', { type: 'warning' })
    await request.delete(`/sales/quote/${row.id}`)
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
      await request.put(`/sales/quote/${editingId.value}`, data)
      ElMessage.success('编辑成功')
    } else {
      await request.post('/sales/quote', data)
      ElMessage.success('新建成功')
    }
    dialogVisible.value = false
    loadData()
  } catch {
    ElMessage.error(dialogMode.value === 'edit' ? '编辑失败' : '新建失败')
  } finally {
    submitting.value = false
  }
}

// ============ 加载 ============
async function loadData() {
  loading.value = true
  try {
    const params = {
      pageNum: pagination.page,
      pageSize: pagination.pageSize,
      ...queryParams,
    }
    Object.keys(params).forEach(k => { if (params[k] === null || params[k] === '') delete params[k] })
    const res = await request.get('/sales/quote/page', { params })
    tableData.value = res.data?.records || res.data?.list || []
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
.quotes-page {
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

/* seq column toolbar */
.table-header-bar {
  display: flex;
  align-items: center;
  justify-content: center;
}
.seq-settings-btn { cursor: pointer; color: #909399; transition: color 0.2s; }
.seq-settings-btn:hover { color: #409eff; }

</style>