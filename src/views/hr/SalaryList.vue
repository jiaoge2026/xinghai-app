<template>
  <div class="salary-list">
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
            page-path="/hr/salaries"
            @change="onColumnConfigChange"
          >
            <template #trigger>
              <el-icon class="seq-settings-btn"><Setting /></el-icon>
            </template>
          </ColumnSettings>
        </template>
      
      </DataTable>
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
import { SearchForm, DataTable} from '@/components/page-components'
import ColumnSettings from '@/views/components/ColumnSettings.vue'
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus, Setting } from '@element-plus/icons-vue'
import request from '@/utils/request'
import { formatCurrency } from '@/utils/format'

// ============ 数据 ============
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })
const queryParams = reactive({ employeeId: null, month: '' })
const empOptions = ref([])

// ============ 搜索 ============
const searchFields = [
  {
    key: 'employeeId',
    label: '员工',
    type: 'select',
    placeholder: '全部员工',
    clearable: true,
    options: [],
  },
  {
    key: 'month',
    label: '月份',
    type: 'month',
    valueFormat: 'YYYY-MM',
    placeholder: '选择月份',
    clearable: true,
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
  
  { key: 'employeeName', label: '员工姓名', minWidth: 100 },
  { key: 'departmentName', label: '部门', minWidth: 120 },
  { key: 'month', label: '月份', width: 100 },
  {
    key: 'baseSalary',
    label: '基本工资',
    width: 110,
    align: 'right',
    columnType: 'money',
  },
  {
    key: 'allowance',
    label: '补贴',
    width: 90,
    align: 'right',
    columnType: 'money',
  },
  {
    key: 'bonus',
    label: '奖金',
    width: 90,
    align: 'right',
    columnType: 'money',
  },
  {
    key: 'deduction',
    label: '扣款',
    width: 90,
    align: 'right',
    columnType: 'money',
  },
  {
    key: 'actualSalary',
    label: '应发工资',
    width: 110,
    align: 'right',
    columnType: 'money',
  },
  {
    key: 'netPay',
    label: '实发工资',
    width: 110,
    align: 'right',
    columnType: 'money',
    bold: true,
  },
  {
    key: 'actions',
    label: '操作',
    width: 140,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'edit', label: '编辑', type: 'primary', size: 'small', link: true },
      { key: 'export', label: '导出', type: 'success', size: 'small', link: true },
    ],
  },
]

function handleTableAction(action, row) {
  if (action === 'edit') openEdit(row)
  else if (action === 'export') handleExport(row)
}

function handlePageChange(page) { pagination.page = page; loadData() }
function handleSizeChange(size) { pagination.pageSize = size; pagination.page = 1; loadData() }

// ============ 弹窗表单 ============
const dialogVisible = ref(false)
const dialogMode = ref('create')
const submitting = ref(false)
const editingId = ref(null)

const defaultForm = () => ({
  employeeId: null,
  month: '',
  baseSalary: 0,
  allowance: 0,
  bonus: 0,
  deduction: 0,
  actualSalary: 0,
  netPay: 0,
})

const formData = reactive(defaultForm())

const dialogFields = [
  {
    key: 'employeeId',
    label: '员工',
    type: 'select',
    required: true,
    placeholder: '选择员工',
    options: [],
    disabled: () => dialogMode.value === 'edit',
  },
  {
    key: 'month',
    label: '月份',
    type: 'month',
    valueFormat: 'YYYY-MM',
    required: true,
    disabled: () => dialogMode.value === 'edit',
  },
  {
    key: 'baseSalary',
    label: '基本工资',
    type: 'number',
    required: true,
    min: 0,
    precision: 2,
  },
  { key: 'allowance', label: '补贴', type: 'number', min: 0, precision: 2 },
  { key: 'bonus', label: '奖金', type: 'number', min: 0, precision: 2 },
  { key: 'deduction', label: '扣款', type: 'number', min: 0, precision: 2 },
  {
    key: 'actualSalary',
    label: '应发工资',
    type: 'number',
    min: 0,
    precision: 2,
    readonly: true,
    computed: true,
  },
  {
    key: 'netPay',
    label: '实发工资',
    type: 'number',
    required: true,
    min: 0,
    precision: 2,
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
    employeeId: row.employeeId,
    month: row.month,
    baseSalary: row.baseSalary || 0,
    allowance: row.allowance || 0,
    bonus: row.bonus || 0,
    deduction: row.deduction || 0,
    actualSalary: row.actualSalary || 0,
    netPay: row.netPay || 0,
  })
  dialogVisible.value = true
}

function handleExport(row) {
  ElMessage.success(`「${row.employeeName}」${row.month}薪资单已导出`)
}

// 自动计算应发工资
watch(
  () => [formData.baseSalary, formData.allowance, formData.bonus, formData.deduction],
  () => {
    formData.actualSalary =
      Number(formData.baseSalary || 0) +
      Number(formData.allowance || 0) +
      Number(formData.bonus || 0) -
      Number(formData.deduction || 0)
  }
)

// ============ 数据加载 ============
async function loadData() {
  loading.value = true
  try {
    const res = await request.get('/hr/salaries', {
      params: { ...queryParams, page: pagination.page, pageSize: pagination.pageSize },
    })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch {
    tableData.value = []
    pagination.total = 0
  } finally {
    loading.value = false
  }
}

async function loadEmployees() {
  try {
    const res = await request.get('/hr/employees')
    empOptions.value = res.data?.list || []
    // update select options in search and dialog
    const empSelectField = searchFields.find(f => f.key === 'employeeId')
    if (empSelectField) empSelectField.options = empOptions.value
    const dialogEmpField = dialogFields.find(f => f.key === 'employeeId')
    if (dialogEmpField) dialogEmpField.options = empOptions.value
  } catch {
    empOptions.value = []
  }
}

async function handleSave() {
  submitting.value = true
  try {
    if (dialogMode.value === 'edit') {
      await request.put(`/hr/salaries/${editingId.value}`, formData)
      ElMessage.success('编辑成功')
    } else {
      await request.post('/hr/salaries', formData)
      ElMessage.success('发放成功')
    }
    dialogVisible.value = false
    loadData()
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  loadData()
  loadEmployees()
})
</script>

<style scoped>
.salary-list {
  padding: 0;
}

.panel {
  background: #fff;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 16px;
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