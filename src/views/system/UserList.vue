<template>
  <div class="user-list">
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
        @action="handleTableAction"
      >
        <template #roles="{ row }">
          <el-tag v-for="r in (row.roles || [])" :key="r.id" size="small" style="margin-right:4px">{{ r.roleName }}</el-tag>
        </template>
      
        <template #header___seq__>
          <span>序号</span>
          <ColumnSettings
            :columns="mergedColumns"
            page-path="/system/users"
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

    <!-- 分配角色弹窗 -->
    <el-dialog v-model="roleVisible" title="分配角色" width="400px" destroy-on-close>
      <el-checkbox-group v-model="selectedRoles">
        <el-checkbox v-for="r in roleOptions" :key="r.id" :value="r.id" style="display:block;margin-bottom:8px">
          {{ r.roleName }} <span style="color:#999;font-size:12px">{{ r.roleCode }}</span>
        </el-checkbox>
      </el-checkbox-group>
      <template #footer>
        <el-button @click="roleVisible=false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleRoleSubmit">确定分配</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { SearchForm, DataTable} from '@/components/page-components'
import ColumnSettings from '@/views/components/ColumnSettings.vue'
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {Plus, Setting} from '@element-plus/icons-vue'
import request from '@/utils/request'


// ============ 数据 ============
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })
const queryParams = reactive({ username: '', name: '', roleId: null })
const roleOptions = ref([])

// ============ 搜索 ============
const searchFields = [
  { key: 'username', label: '用户名', type: 'input', placeholder: '用户名' },
  { key: 'name', label: '姓名', type: 'input', placeholder: '姓名' },
  {
    key: 'roleId',
    label: '角色',
    type: 'select',
    placeholder: '全部角色',
    clearable: true,
    options: [],
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
  
  { key: 'username', label: '用户名', width: 150 },
  { key: 'name', label: '姓名', minWidth: 120 },
  { key: 'phone', label: '手机号', width: 130 },
  { key: 'email', label: '邮箱', minWidth: 180, showOverflowTooltip: true },
  { key: 'roles', label: '角色', minWidth: 200 },
  {
    key: 'status',
    label: '状态',
    width: 90,
    align: 'center',
    columnType: 'status',
    statusMap: { 1: { label: '启用', type: 'success' }, 0: { label: '禁用', type: 'info' } },
  },
  {
    key: 'actions',
    label: '操作',
    width: 200,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'assignRole', label: '分配角色', type: 'primary', size: 'small', link: true },
      { key: 'edit', label: '编辑', type: 'primary', size: 'small', link: true },
      { key: 'delete', label: '删除', type: 'danger', size: 'small', link: true, danger: true },
    ],
  },
]

function handleTableAction(action, row) {
  if (action === 'edit') openEdit(row)
  else if (action === 'delete') openDelete(row)
  else if (action === 'assignRole') openAssignRole(row)
}

function handlePageChange(page) { pagination.page = page; loadData() }
function handleSizeChange(size) { pagination.pageSize = size; pagination.page = 1; loadData() }

// ============ 弹窗表单 ============
const dialogVisible = ref(false)
const dialogMode = ref('create')
const submitting = ref(false)
const editingId = ref(null)

const defaultForm = () => ({
  id: null,
  username: '',
  name: '',
  phone: '',
  email: '',
  password: '',
  status: 1,
})

const formData = reactive(defaultForm())

const dialogFields = computed(() => [
  { key: 'username', label: '用户名', type: 'input', required: true, placeholder: '登录用户名', disabled: dialogMode.value === 'edit' },
  { key: 'name', label: '姓名', type: 'input', required: true, placeholder: '真实姓名' },
  { key: 'phone', label: '手机号', type: 'input', placeholder: '11位手机号' },
  { key: 'email', label: '邮箱', type: 'input', placeholder: '邮箱地址' },
  { key: 'password', label: '初始密码', type: 'input', required: dialogMode.value === 'create', placeholder: '设置初始密码', if: dialogMode.value === 'create' },
  {
    key: 'status',
    label: '状态',
    type: 'radio',
    options: [{ label: '启用', value: 1 }, { label: '禁用', value: 0 }],
  },
])

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
    id: row.id,
    username: row.username,
    name: row.name,
    phone: row.phone || '',
    email: row.email || '',
    password: '',
    status: row.status ?? 1,
  })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除用户「${row.username}」？`, '提示', { type: 'warning' })
    await request.delete(`/system/users/${row.id}`)
    ElMessage.success('删除成功')
    loadData()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('删除失败')
  }
}

async function handleSave(data) {
  submitting.value = true
  try {
    if (dialogMode.value === 'edit') {
      await request.put(`/system/users/${editingId.value}`, data)
      ElMessage.success('编辑成功')
    } else {
      await request.post('/system/users', data)
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

// ============ 分配角色 ============
const roleVisible = ref(false)
const currentUserId = ref(null)
const selectedRoles = ref([])

function openAssignRole(row) {
  currentUserId.value = row.id
  selectedRoles.value = (row.roles || []).map(r => r.id)
  roleVisible.value = true
}

async function handleRoleSubmit() {
  await request.post(`/system/users/${currentUserId.value}/roles`, { roleIds: selectedRoles.value })
  ElMessage.success('角色分配成功')
  roleVisible.value = false
  loadData()
}

// ============ 加载 ============
async function loadData() {
  loading.value = true
  try {
    const params = { pageNum: pagination.page, pageSize: pagination.pageSize, ...queryParams }
    Object.keys(params).forEach(k => { if (params[k] === null || params[k] === '') delete params[k] })
    const res = await request.get('/system/users', { params })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

async function loadRoles() {
  try {
    const res = await request.get('/system/roles')
    roleOptions.value = res.data?.list || []
    const roleMap = roleOptions.value.map(r => ({ label: r.roleName, value: r.id }))
    const roleField = searchFields.find(f => f.key === 'roleId')
    if (roleField) roleField.options = roleMap
  } catch {
    roleOptions.value = []
  }
}

onMounted(() => { loadRoles(); loadData() })
</script>

<script>
export default { name: 'UserList' }
</script>

<style scoped>
.user-list {
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