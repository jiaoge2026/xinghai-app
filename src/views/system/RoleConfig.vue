<template>
  <div class="role-config-container">
    <div class="header">
      <h2>角色权限配置</h2>
      <el-button type="primary" @click="handleCreate">新增角色</el-button>
    </div>

    <!-- 角色列表 + 权限配置 -->
    <div class="config-layout">
      <!-- 左侧：角色列表 -->
      <div class="role-list-panel">
        <el-table :data="roleList" border highlight-current-row @row-click="onSelectRole"
          :row-class-name="rowClassName" style="width:100%">
          <el-table-column prop="roleName" label="角色名称" />
          <el-table-column prop="roleCode" label="角色编码" width="140" />
          <el-table-column prop="userCount" label="用户数" width="70" align="center" />
          <el-table-column label="操作" width="100" align="center">
            <template #default="{ row }">
              <el-button link type="primary" size="small" @click.stop="onEditRole(row)">编辑</el-button>
              <el-button link type="danger" size="small" @click.stop="onDeleteRole(row)" 
                :disabled="row.roleCode === 'SUPER_ADMIN'">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- 右侧：菜单 + 权限配置 -->
      <div class="permission-panel" v-if="selectedRole">
        <div class="panel-header">
          <span>配置角色：<strong>{{ selectedRole.roleName }}</strong></span>
          <el-button type="success" @click="handleSave">保存配置</el-button>
        </div>

        <!-- 菜单权限 -->
        <div class="section">
          <div class="section-title">菜单权限（勾选该角色可访问的菜单）</div>
          <el-tree ref="menuTreeRef" :data="menuTree" node-key="id" :props="treeProps"
            show-checkbox check-strictly default-expand-all>
            <template #default="{ data }">
              <span class="tree-node">
                <span>{{ data.name }}</span>
                <span class="node-path">{{ data.path }}</span>
              </span>
            </template>
          </el-tree>
        </div>

        <!-- 功能权限 -->
        <div class="section">
          <div class="section-title">功能权限（勾选该角色可执行的操作）</div>
          <div class="perm-modules">
            <div v-for="mod in permissionModules" :key="mod.module" class="perm-module">
              <div class="perm-module-title">{{ getModuleName(mod.module) }}</div>
              <el-checkbox-group v-model="checkedPermissions">
                <el-checkbox v-for="p in mod.permissions" :key="p.id" :value="p.id"
                  :label="p.id" @change="onPermChange">
                  {{ p.permissionName }}
                  <span class="perm-code">{{ p.permissionCode }}</span>
                </el-checkbox>
              </el-checkbox-group>
            </div>
          </div>
        </div>
      </div>

      <!-- 未选中角色时 -->
      <div class="permission-panel empty" v-else>
        <div class="empty-tip">👈 请先选择一个角色进行配置</div>
      </div>
    </div>

    <!-- 新增/编辑角色弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogMode === 'create' ? '新增角色' : '编辑角色'" width="400">
      <el-form :model="roleForm" label-width="80">
        <el-form-item label="角色编码">
          <el-input v-model="roleForm.roleCode" placeholder="如：finance_manager" 
            :disabled="dialogMode === 'update'" />
        </el-form-item>
        <el-form-item label="角色名称">
          <el-input v-model="roleForm.roleName" placeholder="如：财务经理" />
        </el-form-item>
        <el-form-item label="角色类型">
          <el-radio-group v-model="roleForm.roleType">
            <el-radio :value="1">系统角色</el-radio>
            <el-radio :value="2">业务角色</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="roleForm.description" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleDialogConfirm" :loading="dialogLoading">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '../../utils/request'

const roleList = ref([])
const selectedRole = ref(null)
const menuTree = ref([])
const permissionModules = ref([])
const menuTreeRef = ref(null)
const checkedPermissions = ref([])
const dialogVisible = ref(false)
const dialogMode = ref('create')
const dialogLoading = ref(false)
const currentRoleId = ref(null)

const roleForm = reactive({ roleCode: '', roleName: '', roleType: 2, description: '' })
const treeProps = { children: 'children', label: 'name' }

// 模块中文名
const moduleNames = {
  fsm: 'FSM工单', wms: '库存备件', logistics: '物流配送', retail: '零售门店',
  crm: 'CRM客户', member: '会员管理', finance: '财务管理', hr: '人事管理',
  qa: '质量管理', report: '报表驾驶舱', system: '系统管理'
}

const getModuleName = (m) => moduleNames[m] || m

onMounted(async () => {
  await loadRoles()
  const [treeRes, permRes] = await Promise.all([
    request.get('/system/menus/tree'),
    request.get('/system/menus/permissions/grouped')
  ])
  if (treeRes.code === 0) menuTree.value = treeRes.data
  if (permRes.code === 0) permissionModules.value = permRes.data
})

async function loadRoles() {
  const res = await request.get('/system/roles?page=1&pageSize=100')
  if (res.code === 0) roleList.value = res.data.list
}

function onSelectRole(row) {
  selectedRole.value = row
  currentRoleId.value = row.id
  loadRoleConfig(row.id)
}

async function loadRoleConfig(roleId) {
  const [menuRes, permRes] = await Promise.all([
    request.get(`/system/menus/tree/${roleId}`),
    request.get(`/system/menus/permissions/${roleId}`)
  ])
  if (menuRes.code === 0) {
    await nextTick()
    const checkedIds = extractCheckedIds(menuRes.data)
    menuTreeRef.value?.setCheckedKeys(checkedIds, false)
  }
  if (permRes.code === 0) {
    checkedPermissions.value = []
    // Convert permission codes to IDs
    const allPerms = permissionModules.value.flatMap(m => m.permissions)
    for (const code of permRes.data) {
      const found = allPerms.find(p => p.permissionCode === code)
      if (found) checkedPermissions.value.push(found.id)
    }
  }
}

function extractCheckedIds(nodes) {
  let ids = []
  for (const n of nodes) {
    if (n.checked) ids.push(n.id)
    if (n.children) ids = ids.concat(extractCheckedIds(n.children))
  }
  return ids
}

async function handleSave() {
  const menuIds = menuTreeRef.value?.getCheckedKeys() || []
  const halfChecked = menuTreeRef.value?.getHalfCheckedKeys() || []
  const allChecked = [...menuIds, ...halfChecked]
  await Promise.all([
    request.post(`/system/menus/assign/${currentRoleId.value}`, { menuIds: allChecked }),
    request.post(`/system/menus/permissions/assign/${currentRoleId.value}`, { permissionIds: checkedPermissions.value })
  ])
  ElMessage.success('保存成功')
}

function onEditRole(row) {
  dialogMode.value = 'update'
  roleForm.roleCode = row.roleCode
  roleForm.roleName = row.roleName
  roleForm.roleType = row.roleType || 2
  roleForm.description = row.description || ''
  currentRoleId.value = row.id
  dialogVisible.value = true
}

function handleCreate() {
  dialogMode.value = 'create'
  Object.assign(roleForm, { roleCode: '', roleName: '', roleType: 2, description: '' })
  dialogVisible.value = true
}

async function handleDialogConfirm() {
  if (!roleForm.roleCode || !roleForm.roleName) {
    ElMessage.warning('请填写角色编码和名称')
    return
  }
  dialogLoading.value = true
  try {
    if (dialogMode.value === 'create') {
      await request.post('/system/roles', roleForm)
    } else {
      await request.put(`/system/roles/${currentRoleId.value}`, roleForm)
    }
    dialogVisible.value = false
    await loadRoles()
    ElMessage.success(dialogMode.value === 'create' ? '创建成功' : '更新成功')
  } finally {
    dialogLoading.value = false
  }
}

async function onDeleteRole(row) {
  if (row.userCount > 0) {
    ElMessage.warning(`该角色下有 ${row.userCount} 个用户，请先移除`)
    return
  }
  await ElMessageBox.confirm(`确认删除角色「${row.roleName}」？`, '确认')
  await request.delete(`/system/roles/${row.id}`)
  ElMessage.success('删除成功')
  if (selectedRole.value?.id === row.id) selectedRole.value = null
  await loadRoles()
}

function rowClassName({ row }) {
  return selectedRole.value?.id === row.id ? 'selected-row' : ''
}

function onPermChange() {}
</script>

<style scoped>
.role-config-container { padding: 20px; }
.header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
.header h2 { margin: 0; }
.config-layout { display: flex; gap: 20px; height: calc(100vh - 200px); }
.role-list-panel { width: 380px; flex-shrink: 0; overflow-y: auto; }
.permission-panel { flex: 1; overflow-y: auto; border: 1px solid #dcdfe6; border-radius: 4px; padding: 16px; }
.permission-panel.empty { display: flex; align-items: center; justify-content: center; }
.empty-tip { color: #999; font-size: 16px; }
.panel-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; padding-bottom: 12px; border-bottom: 1px solid #eee; }
.section { margin-bottom: 24px; }
.section-title { font-weight: 600; font-size: 14px; margin-bottom: 12px; color: #333; }
.tree-node { display: flex; justify-content: space-between; width: 100%; }
.node-path { color: #999; font-size: 12px; margin-left: 16px; }
.perm-modules { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.perm-module { border: 1px solid #eee; border-radius: 4px; padding: 12px; }
.perm-module-title { font-weight: 600; font-size: 13px; margin-bottom: 8px; color: #409eff; }
.perm-code { color: #999; font-size: 11px; margin-left: 4px; }
:deep(.selected-row) { background-color: #ecf5ff; }
:deep(.el-checkbox) { margin-bottom: 8px; }
</style>
