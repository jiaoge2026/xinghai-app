<template>
  <div class="employee-list">
    <PageHeader title="员工管理">
      <template #actions>
        <el-button type="primary" @click="openAdd">
          <el-icon><Plus /></el-icon> 新增员工
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

// ============ 数据 ============
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })
const queryParams = reactive({ name: '', departmentId: null, status: null })
const deptOptions = ref([])

// ============ 搜索 ============
const searchFields = [
  { key: 'name', label: '姓名', type: 'input', placeholder: '员工姓名' },
  {
    key: 'departmentId',
    label: '部门',
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
      { label: '在职', value: 'ON_JOB' },
      { label: '离职', value: 'OFF_JOB' },
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
  { key: 'employeeNo', label: '工号', width: 110 },
  { key: 'name', label: '姓名', minWidth: 100 },
  {
    key: 'gender',
    label: '性别',
    width: 70,
    align: 'center',
    columnType: 'map',
    maps: { 1: '男', 2: '女' },
  },
  { key: 'phone', label: '手机号', width: 130 },
  { key: 'deptName', label: '部门', minWidth: 120 },
  { key: 'positionName', label: '岗位', minWidth: 120 },
  {
    key: 'status',
    label: '状态',
    width: 90,
    align: 'center',
    columnType: 'map',
    maps: { ON_JOB: { label: '在职', type: 'success' }, OFF_JOB: { label: '离职', type: 'info' } },
  },
  { key: 'entryDate', label: '入职日期', width: 120 },
  {
    key: 'actions',
    label: '操作',
    width: 120,
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
  employeeNo: '',
  name: '',
  gender: 1,
  phone: '',
  departmentId: null,
  position: '',
  email: '',
  entryDate: '',
  status: 'ON_JOB',
})

const formData = reactive(defaultForm())

const dialogFields = [
  { key: 'employeeNo', label: '工号', type: 'input', required: true, placeholder: '如：EMP001', disabled: () => dialogMode.value === 'edit' },
  { key: 'name', label: '姓名', type: 'input', required: true, placeholder: '员工姓名' },
  {
    key: 'gender',
    label: '性别',
    type: 'radio',
    options: [{ label: '男', value: 1 }, { label: '女', value: 2 }],
  },
  { key: 'phone', label: '手机号', type: 'input', required: true, placeholder: '11位手机号' },
  { key: 'departmentId', label: '部门', type: 'select', required: true, placeholder: '选择部门', options: [] },
  { key: 'position', label: '岗位', type: 'input', placeholder: '职位/岗位' },
  { key: 'email', label: '邮箱', type: 'input', placeholder: '可选' },
  { key: 'entryDate', label: '入职日期', type: 'date', valueFormat: 'YYYY-MM-DD' },
  {
    key: 'status',
    label: '状态',
    type: 'radio',
    options: [{ label: '在职', value: 'ON_JOB' }, { label: '离职', value: 'OFF_JOB' }],
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
    employeeNo: row.employeeNo,
    name: row.name,
    gender: row.gender || 1,
    phone: row.phone,
    departmentId: row.departmentId,
    position: row.position || '',
    email: row.email || '',
    entryDate: row.entryDate || '',
    status: row.status || 'ON_JOB',
  })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除员工「${row.name}」？`, '提示', { type: 'warning' })
    await request.delete(`/hr/employees/${row.id}`)
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
      await request.put(`/hr/employees/${editingId.value}`, data)
      ElMessage.success('编辑成功')
    } else {
      await request.post('/hr/employees', data)
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
    // 去掉null值
    Object.keys(params).forEach(k => { if (params[k] === null || params[k] === '') delete params[k] })
    const res = await request.get('/hr/employees', { params })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

async function loadDepts() {
  try {
    const res = await request.get('/hr/departments')
    deptOptions.value = Array.isArray(res.data) ? res.data : (res.data?.list || [])
    const deptMap = deptOptions.value.map(d => ({ label: d.name, value: d.id }))
    searchFields[1].options = deptMap
    dialogFields.find(f => f.key === 'departmentId').options = deptMap
  } catch {
    deptOptions.value = []
  }
}

onMounted(() => { loadDepts(); loadData() })
</script>

<style scoped>
.employee-list {
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
