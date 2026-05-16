<template>
  <div class="bank-account-list">
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
            page-path="/finance/bank-accounts"
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
    <el-dialog v-model="dialogVisible" :title="dialogMode === 'edit' ? '编辑账户' : '新增账户'" width="500px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="账户名称" prop="accountName">
          <el-input v-model="formData.accountName" placeholder="如：公司基本户" />
        </el-form-item>
        <el-form-item label="账号" prop="accountNo">
          <el-input v-model="formData.accountNo" placeholder="银行卡号" />
        </el-form-item>
        <el-form-item label="开户行" prop="bankName">
          <el-input v-model="formData.bankName" placeholder="如：工商银行济南分行" />
        </el-form-item>
        <el-form-item label="账户类型" prop="accountType">
          <el-select v-model="formData.accountType" style="width:100%">
            <el-option label="对公账户" value="COMPANY" />
            <el-option label="个人账户" value="PERSONAL" />
          </el-select>
        </el-form-item>
        <el-form-item label="期初余额" prop="balance">
          <el-input-number v-model="formData.balance" :precision="2" :controls="false" style="width:100%" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="formData.status" style="width:100%">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
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
let queryParams = reactive({ accountName: '', bankName: '' })

const searchFields = [
  { key: 'accountName', label: '账户名称', type: 'input', placeholder: '账户名称' },
  { key: 'bankName', label: '开户行', type: 'input', placeholder: '开户行' },
]

function handleSearch(params) {
  Object.assign(queryParams, params)
  pagination.page = 1
  loadData()
}

function handleReset(params) {
  Object.assign(queryParams, { accountName: '', bankName: '' })
  pagination.page = 1
  loadData()
}


// Column settings
// mergedColumns uses tableColumns directly (plain array)
const onColumnConfigChange = (cols) => { Object.assign(tableColumns, cols) }

const tableColumns = [
  { key: '__seq__', label: '', width: 60, show: true, fixed: 'left', columnType: 'seq' },
  
  { key: 'accountName', label: '账户名称', minWidth: 150 },
  { key: 'accountNo', label: '账号', minWidth: 200 },
  { key: 'bankName', label: '开户行', minWidth: 180 },
  {
    key: 'accountType',
    label: '类型',
    width: 100,
    align: 'center',
    columnType: 'map',
    maps: { COMPANY: { label: '对公', type: '' }, PERSONAL: { label: '个人', type: 'info' } },
  },
  {
    key: 'balance',
    label: '余额',
    width: 130,
    align: 'right',
    formatter: (v) => v != null ? '\u00a5' + Number(v).toFixed(2) : '',
  },
  {
    key: 'status',
    label: '状态',
    width: 80,
    align: 'center',
    columnType: 'map',
    maps: { 1: { label: '\u542f\u7528', type: 'success' }, 0: { label: '\u505c\u7528', type: 'danger' } },
  },
  { key: 'createTime', label: '创建时间', width: 160 },
  {
    key: 'actions',
    label: '操作',
    width: 150,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'edit', label: '\u7f16\u8f91', type: 'primary', size: 'small', link: true },
      { key: 'delete', label: '\u5220\u9664', type: 'danger', size: 'small', link: true, danger: true },
    ],
  },
]

function handleTableAction(action, row) {
  if (action === 'edit') openEdit(row)
  else if (action === 'delete') openDelete(row)
}

function handlePageChange(page) { pagination.page = page; loadData() }
function handleSizeChange(size) { pagination.pageSize = size; pagination.page = 1; loadData() }

const dialogVisible = ref(false)
const dialogMode = ref('create')
const submitting = ref(false)
const editingId = ref(null)

const defaultForm = () => ({
  accountName: '',
  accountNo: '',
  bankName: '',
  accountType: 'COMPANY',
  balance: 0,
  status: 1,
})

let formData = reactive({ ...defaultForm() })
const formRules = {
  accountName: [{ required: true, message: '\u8bf7\u8f93\u5165\u8d26\u6237\u540d\u79f0', trigger: 'blur' }],
  accountNo: [{ required: true, message: '\u8bf7\u8f93\u5165\u8d26\u53f7', trigger: 'blur' }],
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
    accountName: row.accountName || '',
    accountNo: row.accountNo || '',
    bankName: row.bankName || '',
    accountType: row.accountType || 'COMPANY',
    balance: row.balance || 0,
    status: row.status != null ? row.status : 1,
  })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm('\u786e\u5b9a\u5220\u9664\u8d26\u6237\u300c' + row.accountName + '\u300d\uff1f', '\u786e\u8ba4\u5220\u9664', { type: 'warning' })
    await request.delete('/finance/accounts/' + row.id)
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
      await request.put('/finance/accounts/' + editingId.value, formData)
      ElMessage.success('\u7f16\u8f91\u6210\u529f')
    } else {
      await request.post('/finance/accounts', formData)
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
    const res = await request.get('/finance/accounts', {
      params: {
        pageNum: pagination.page,
        pageSize: pagination.pageSize,
        accountName: queryParams.accountName || undefined,
        bankName: queryParams.bankName || undefined,
      },
    })
    const list = Array.isArray(res.data) ? res.data : (res.data?.list || [])
    tableData.value = list
    pagination.total = res.data?.total || list.length
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>

<style scoped>
.bank-account-list { padding: 12px; display: flex; flex-direction: column; gap: 12px; }
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