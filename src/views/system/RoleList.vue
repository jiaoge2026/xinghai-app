<template>
  <div class="role-list">
    <PageHeader title="角色管理">
      <template #actions>
        <el-button type="primary" @click="openAdd">
          <el-icon><Plus /></el-icon> 新增角色
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

    <!-- 分配权限 -->
    <el-dialog v-model="permVisible" title="分配权限" width="500px" destroy-on-close>
      <el-form label-width="100px">
        <el-form-item label="角色">{{ permData.roleName }} ({{ permData.roleCode }})</el-form-item>
        <el-form-item label="权限配置">
          <el-tree
            ref="treeRef"
            :data="menuTree"
            :props="{ label: 'menuName', children: 'children' }"
            node-key="id"
            :default-checked-keys="permData.checkedKeys || []"
            show-checkbox
            check-strictly
            style="max-height:400px;overflow-y:auto"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="permVisible = false">取消</el-button>
        <el-button type="primary" :loading="permLoading" @click="handleSavePerm">保存权限</el-button>
      </template>
    </el-dialog>

    <!-- 新增/编辑 -->
    <el-dialog v-model="dialogVisible" :title="dialogMode === '\u7f16\u8f91' ? '\u7f16\u8f91\u89d2\u8272' : '\u65b0\u589e\u89d2\u8272'" width="500px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="角色名称" prop="roleName">
          <el-input v-model="formData.roleName" placeholder="如\uff1a\u8d22\u52a1\u7ecf\u7406" />
        </el-form-item>
        <el-form-item label="角色代码" prop="roleCode">
          <el-input v-model="formData.roleCode" placeholder="如\uff1afinance_manager" :disabled="dialogMode === '\u7f16\u8f91'" />
        </el-form-item>
        <el-form-item label="角色类型" prop="roleType">
          <el-select v-model="formData.roleType" style="width:100%">
            <el-option :label="'\u7cfb\u7edf\u7ba1\u7406'" :value="1" />
            <el-option :label="'\u4e1a\u52a1\u7ba1\u7406'" :value="2" />
            <el-option :label="'\u666e\u901a\u7528\u6237'" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="formData.description" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">\u53d6\u6d88</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSave">\u786e\u5b9a</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'
import { SearchForm, DataTable, PageHeader } from '@/components/page-components'

const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })
const queryParams = reactive({ roleName: '', roleCode: '', status: '' })

const searchFields = [
  { key: 'roleName', label: '\u89d2\u8272\u540d\u79f0', type: 'input', placeholder: '\u89d2\u8272\u540d\u79f0' },
  { key: 'roleCode', label: '\u89d2\u8272\u4ee3\u7801', type: 'input', placeholder: '\u89d2\u8272\u4ee3\u7801' },
]

function handleSearch(params) {
  Object.assign(queryParams, params)
  pagination.page = 1
  loadData()
}

function handleReset() {
  Object.assign(queryParams, { roleName: '', roleCode: '', status: '' })
  pagination.page = 1
  loadData()
}

const statusMap = { 1: { label: '\u6d3b\u8dc3', type: 'success' }, 0: { label: '\u7981\u7528', type: 'danger' } }

const tableColumns = [
  { key: 'roleName', label: '\u89d2\u8272\u540d\u79f0', width: 150 },
  { key: 'roleCode', label: '\u89d2\u8272\u4ee3\u7801', width: 160 },
  { key: 'description', label: '\u63cf\u8ff0', minWidth: 200, showOverflowTooltip: true },
  { key: 'userCount', label: '\u4eba\u6570', width: 80, align: 'center' },
  {
    key: 'status',
    label: '\u72b6\u6001',
    width: 90,
    align: 'center',
    columnType: 'switch',
    activeValue: 1,
    inactiveValue: 0,
    switchChange: (val, row) => handleStatusChange(row, val),
  },
  { key: 'createdAt', label: '\u521b\u5efa\u65f6\u95f4', width: 170 },
  {
    key: 'actions',
    label: '\u64cd\u4f5c',
    width: 180,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'perm', label: '\u5206\u914d\u6743\u9650', type: 'primary', size: 'small', link: true },
      { key: 'edit', label: '\u7f16\u8f91', type: 'primary', size: 'small', link: true },
      { key: 'delete', label: '\u5220\u9664', type: 'danger', size: 'small', link: true, danger: true },
    ],
  },
]

function handleTableAction(action, row) {
  if (action === 'perm') openPerm(row)
  else if (action === 'edit') openEdit(row)
  else if (action === 'delete') openDelete(row)
}

function handlePageChange(page) { pagination.page = page; loadData() }
function handleSizeChange(size) { pagination.pageSize = size; pagination.page = 1; loadData() }

async function handleStatusChange(row, val) {
  try {
    await request.put('/system/roles/' + row.id, { status: val })
    ElMessage.success(val === 1 ? '\u5df2\u542f\u7528' : '\u5df2\u7981\u7528')
  } catch { loadData() }
}

const dialogVisible = ref(false)
const dialogMode = ref('create')
const submitting = ref(false)
const editingId = ref(null)
const defaultForm = () => ({ roleName: '', roleCode: '', roleType: 3, description: '' })
const formData = reactive({ ...defaultForm() })
const formRules = {
  roleName: [{ required: true, message: '\u8bf7\u8f93\u5165\u89d2\u8272\u540d\u79f0', trigger: 'blur' }],
  roleCode: [
    { required: true, message: '\u8bf7\u8f93\u5165\u89d2\u8272\u4ee3\u7801', trigger: 'blur' },
    { pattern: /^[a-z_]+$/, message: '\u4ee3\u7801\u53ea\u80fd\u662f\u5c0f\u5199\u5b57\u6bcd+\u4e0b\u5212\u7ebf', trigger: 'blur' },
  ],
}
const formRef = ref(null)

function openAdd() {
  dialogMode.value = 'create'
  editingId.value = null
  Object.assign(formData, defaultForm())
  dialogVisible.value = true
}

function openEdit(row) {
  dialogMode.value = '\u7f16\u8f91'
  editingId.value = row.id
  Object.assign(formData, { roleName: row.roleName, roleCode: row.roleCode, roleType: row.roleType || 3, description: row.description || '' })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm('\u786e\u5b9a\u5220\u9664\u89d2\u8272\u300c' + row.roleName + '\u300d\uff1f', '\u786e\u8ba4\u5220\u9664', { type: 'warning' })
    await request.delete('/system/roles/' + row.id)
    ElMessage.success('\u5df2\u5220\u9664')
    loadData()
  } catch (e) { if (e !== 'cancel') ElMessage.error('\u5220\u9664\u5931\u8d25') }
}

async function handleSave() {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (dialogMode.value === '\u7f16\u8f91') {
      await request.put('/system/roles/' + editingId.value, formData)
      ElMessage.success('\u7f16\u8f91\u6210\u529f')
    } else {
      await request.post('/system/roles', formData)
      ElMessage.success('\u65b0\u589e\u6210\u529f')
    }
    dialogVisible.value = false
    loadData()
  } catch { ElMessage.error(dialogMode.value === '\u7f16\u8f91' ? '\u7f16\u8f91\u5931\u8d25' : '\u65b0\u589e\u5931\u8d25') }
  finally { submitting.value = false }
}

const permVisible = ref(false)
const permLoading = ref(false)
const permData = ref({})
const menuTree = ref([])
const treeRef = ref(null)

async function openPerm(row) {
  permData.value = { id: row.id, roleName: row.roleName, roleCode: row.roleCode, checkedKeys: [] }
  permVisible.value = true
  try {
    const [menuRes, permRes] = await Promise.all([
      request.get('/system/menus'),
      request.get('/system/roles/' + row.id + '/menus'),
    ])
    menuTree.value = menuRes.data || []
    permData.value.checkedKeys = (permRes.data || []).map(m => m.menuId || m.id)
  } catch { menuTree.value = [] }
}

async function handleSavePerm() {
  permLoading.value = true
  try {
    const checked = treeRef.value?.getCheckedKeys() || []
    await request.post('/system/roles/' + permData.value.id + '/menus', { menuIds: checked })
    ElMessage.success('\u6743\u9650\u5206\u914d\u5df2\u4fdd\u5b58')
    permVisible.value = false
  } catch { ElMessage.error('\u4fdd\u5b58\u5931\u8d25') }
  finally { permLoading.value = false }
}

async function loadData() {
  loading.value = true
  try {
    const res = await request.get('/system/roles', {
      params: {
        pageNum: pagination.page,
        pageSize: pagination.pageSize,
        roleName: queryParams.roleName || undefined,
        roleCode: queryParams.roleCode || undefined,
      },
    })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch { tableData.value = [] }
  finally { loading.value = false }
}

onMounted(loadData)
</script>

<style scoped>
.role-list { padding: 12px; display: flex; flex-direction: column; gap: 12px; }
.panel { background: #fff; border-radius: 4px; padding: 12px 16px; }
</style>
