<template>
  <div class="department-list">
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
            page-path="/hr/departments"
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
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Setting } from '@element-plus/icons-vue'
import request from '@/utils/request'

// ============ 数据 ============
const loading = ref(false)
const tableData = ref([])
let pagination = reactive({ page: 1, pageSize: 20, total: 0 })
let queryParams = reactive({ name: '', status: null })
const statusOptions = [
  { label: '启用', value: 1 },
  { label: '禁用', value: 0 },
]

// ============ 搜索 ============
const searchFields = [
  { key: 'name', label: '部门名称', type: 'input', placeholder: '输入部门名称' },
  {
    key: 'status',
    label: '状态',
    type: 'select',
    placeholder: '全部',
    clearable: true,
    options: statusOptions,
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
  
  { key: 'name', label: '部门名称', minWidth: 150 },
  { key: 'parentName', label: '上级部门', minWidth: 120 },
  { key: 'managerName', label: '负责人', minWidth: 100 },
  {
    key: 'status',
    label: '状态',
    width: 80,
    align: 'center',
    columnType: 'map',
    maps: { 1: { label: '启用', type: 'success' }, 0: { label: '禁用', type: 'info' } },
  },
  { key: 'sort', label: '排序', width: 80, align: 'center' },
  { key: 'createTime', label: '创建时间', width: 170 },
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
  name: '',
  parentId: null,
  managerId: null,
  status: 1,
  sort: 0,
})

let formData = reactive(defaultForm())

const dialogFields = [
  { key: 'name', label: '部门名称', type: 'input', required: true, placeholder: '如：销售部' },
  { key: 'parentId', label: '上级部门', type: 'select', placeholder: '顶级部门可不选', options: [] },
  { key: 'managerId', label: '负责人', type: 'select', placeholder: '选择负责人', options: [] },
  { key: 'sort', label: '排序', type: 'number', min: 0, max: 999, defaultValue: 0 },
  {
    key: 'status',
    label: '状态',
    type: 'radio',
    options: [{ label: '启用', value: 1 }, { label: '禁用', value: 0 }],
    defaultValue: 1,
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
    parentId: row.parentId,
    managerId: row.managerId,
    status: row.status ?? 1,
    sort: row.sort ?? 0,
  })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除部门「${row.name}」？`, '提示', { type: 'warning' })
    await request.delete(`/hr/departments/${row.id}`)
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
      await request.put(`/hr/departments/${editingId.value}`, data)
      ElMessage.success('编辑成功')
    } else {
      await request.post('/hr/departments', data)
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
    const params = { page: pagination.page, pageSize: pagination.pageSize, ...queryParams }
    // 去掉null值
    Object.keys(params).forEach(k => { if (params[k] === null || params[k] === '') delete params[k] })
    const res = await request.get('/hr/departments', { params })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

async function loadDeptOptions() {
  try {
    const res = await request.get('/hr/departments')
    const list = Array.isArray(res.data) ? res.data : (res.data?.list || [])
    const deptMap = list.map(d => ({ label: d.name, value: d.id }))
    // 上级部门选项
    const parentField = dialogFields.find(f => f.key === 'parentId')
    if (parentField) parentField.options = deptMap
  } catch {
    // ignore
  }
}

async function loadManagerOptions() {
  try {
    const res = await request.get('/hr/employees', { params: { page: 1, pageSize: 1000 } })
    const list = res.data?.list || []
    const empMap = list.map(e => ({ label: e.name, value: e.id }))
    const managerField = dialogFields.find(f => f.key === 'managerId')
    if (managerField) managerField.options = empMap
  } catch {
    // ignore
  }
}

onMounted(() => {
  loadDeptOptions()
  loadManagerOptions()
  loadData()
})
</script>

<style scoped>
.department-list {
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