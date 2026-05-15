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
        <el-table
          :data="roleList"
          border
          highlight-current-row
          @row-click="onSelectRole"
          :row-class-name="rowClassName"
          style="width:100%"
        >
          <el-table-column prop="roleName" label="角色名称" />
          <el-table-column prop="roleCode" label="角色编码" width="140" />
          <el-table-column prop="userCount" label="用户数" width="70" align="center" />
          <el-table-column label="操作" width="100" align="center">
            <template #default="{ row }">
              <el-button link type="primary" size="small" @click.stop="onEditRole(row)">编辑</el-button>
              <el-button
                link
                type="danger"
                size="small"
                @click.stop="onDeleteRole(row)"
                :disabled="row.roleCode === 'SUPER_ADMIN'"
              >删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- 右侧：菜单 + 权限配置 -->
      <div class="permission-panel" v-if="selectedRole">
        <div class="panel-header">
          <span>配置角色：<strong>{{ selectedRole.roleName }}</strong></span>
          <el-button type="success" @click="handleSave" :loading="saving">保存配置</el-button>
        </div>

        <!-- 菜单权限 -->
        <div class="section">
          <div class="section-title">菜单权限（勾选该角色可访问的菜单）</div>
          <el-tree
            ref="menuTreeRef"
            :data="menuTree"
            node-key="id"
            :props="treeProps"
            show-checkbox
            check-strictly
            default-expand-all
          >
            <template #default="{ data }">
              <span class="tree-node">
                <span>{{ data.name }}</span>
                <span class="node-path">{{ data.path }}</span>
              </span>
            </template>
          </el-tree>
        </div>

        <!-- 功能权限 -->
        <PermissionModules
          v-model="checkedPermissions"
          :modules="permissionModules"
        />
      </div>

      <!-- 未选中角色时 -->
      <div class="permission-panel empty" v-else>
        <div class="empty-tip">👈 请先选择一个角色进行配置</div>
      </div>
    </div>

    <!-- 新增/编辑角色弹窗 -->
    <RoleDialog
      v-model="dialogVisible"
      :mode="dialogMode"
      :role-data="editingRole"
      :loading="dialogLoading"
      @confirm="handleDialogConfirm"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, nextTick, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import RoleDialog from '@/components/page-components/system/RoleDialog.vue'
import PermissionModules from '@/components/page-components/system/PermissionModules.vue'
import request from '@/utils/request'

// 角色列表
const roleList = ref([])
const selectedRole = ref<any>(null)
const menuTree = ref([])
const permissionModules = ref([])
const menuTreeRef = ref<any>(null)
const checkedPermissions = ref<number[]>([])

// 对话框状态
const dialogVisible = ref(false)
const dialogMode = ref<'create' | 'update'>('create')
const dialogLoading = ref(false)
const editingRole = ref<any>(null)
const currentRoleId = ref<number | null>(null)
const saving = ref(false)

const treeProps = { children: 'children', label: 'name' }

onMounted(async () => {
  await loadRoles()
  const [treeRes, permRes] = await Promise.all([
    request.get('/system/menus/tree'),
    request.get('/system/menus/permissions/grouped'),
  ])
  if (treeRes.code === 0) menuTree.value = treeRes.data
  if (permRes.code === 0) permissionModules.value = permRes.data
})

async function loadRoles() {
  const res = await request.get('/system/roles?page=1&pageSize=100')
  if (res.code === 0) roleList.value = res.data.list
}

function onSelectRole(row: any) {
  selectedRole.value = row
  currentRoleId.value = row.id
  loadRoleConfig(row.id)
}

async function loadRoleConfig(roleId: number) {
  const [menuRes, permRes] = await Promise.all([
    request.get(`/system/menus/tree/${roleId}`),
    request.get(`/system/menus/permissions/${roleId}`),
  ])
  if (menuRes.code === 0) {
    await nextTick()
    const checkedIds = extractCheckedIds(menuRes.data)
    menuTreeRef.value?.setCheckedKeys(checkedIds, false)
  }
  if (permRes.code === 0) {
    checkedPermissions.value = []
    const allPerms = permissionModules.value.flatMap((m: any) => m.permissions)
    for (const code of permRes.data) {
      const found = allPerms.find((p: any) => p.permissionCode === code)
      if (found) checkedPermissions.value.push(found.id)
    }
  }
}

function extractCheckedIds(nodes: any[]): number[] {
  let ids: number[] = []
  for (const n of nodes) {
    if (n.checked) ids.push(n.id)
    if (n.children) ids = ids.concat(extractCheckedIds(n.children))
  }
  return ids
}

async function handleSave() {
  if (!currentRoleId.value) return
  saving.value = true
  try {
    const menuIds = menuTreeRef.value?.getCheckedKeys() || []
    const halfChecked = menuTreeRef.value?.getHalfCheckedKeys() || []
    const allChecked = [...menuIds, ...halfChecked]
    await Promise.all([
      request.post(`/system/menus/assign/${currentRoleId.value}`, { menuIds: allChecked }),
      request.post(`/system/menus/permissions/assign/${currentRoleId.value}`, { permissionIds: checkedPermissions.value }),
    ])
    ElMessage.success('保存成功')
  } finally {
    saving.value = false
  }
}

function handleCreate() {
  dialogMode.value = 'create'
  editingRole.value = null
  dialogVisible.value = true
}

function onEditRole(row: any) {
  dialogMode.value = 'update'
  editingRole.value = { ...row }
  dialogVisible.value = true
}

async function handleDialogConfirm(formData: any) {
  dialogLoading.value = true
  try {
    if (dialogMode.value === 'create') {
      await request.post('/system/roles', formData)
    } else {
      await request.put(`/system/roles/${editingRole.value?.id}`, formData)
    }
    dialogVisible.value = false
    await loadRoles()
    ElMessage.success(dialogMode.value === 'create' ? '创建成功' : '更新成功')
  } finally {
    dialogLoading.value = false
  }
}

async function onDeleteRole(row: any) {
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

function rowClassName({ row }: { row: any }) {
  return selectedRole.value?.id === row.id ? 'selected-row' : ''
}
</script>

<style scoped>
.role-config-container {
  padding: 20px;
}
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}
.header h2 {
  margin: 0;
}
.config-layout {
  display: flex;
  gap: 20px;
  height: calc(100vh - 200px);
}
.role-list-panel {
  width: 380px;
  flex-shrink: 0;
  overflow-y: auto;
}
.permission-panel {
  flex: 1;
  overflow-y: auto;
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  padding: 16px;
}
.permission-panel.empty {
  display: flex;
  align-items: center;
  justify-content: center;
}
.empty-tip {
  color: #999;
  font-size: 16px;
}
.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 1px solid #eee;
}
.section {
  margin-bottom: 24px;
}
.section-title {
  font-weight: 600;
  font-size: 14px;
  margin-bottom: 12px;
  color: #333;
}
.tree-node {
  display: flex;
  justify-content: space-between;
  width: 100%;
}
.node-path {
  color: #999;
  font-size: 12px;
  margin-left: 16px;
}
:deep(.selected-row) {
  background-color: #ecf5ff;
}
</style>
