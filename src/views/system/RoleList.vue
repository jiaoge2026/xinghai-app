<template>
  <div class="role-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>角色管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增角色</el-button>
        </div>
      </template>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="roleName" label="角色名称" min-width="150" />
        <el-table-column prop="roleCode" label="角色代码" width="150" />
        <el-table-column prop="description" label="描述" min-width="200" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-switch v-model="row.status" :active-value="1" :inactive-value="0" @change="handleStatusChange(row)" />
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="170" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleAssignMenu(row)">分配权限</el-button>
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination">
        <el-pagination
          v-model:current-page="query.page"
          v-model:page-size="query.pageSize"
          :total="total"
          :page-sizes="[10,20,50]"
          layout="total,sizes,prev,pager,next"
          @change="fetchData"
        />
      </div>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="500px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="角色名称" prop="roleName">
          <el-input v-model="form.roleName" placeholder="如：财务经理" />
        </el-form-item>
        <el-form-item label="角色代码" prop="roleCode">
          <el-input v-model="form.roleCode" placeholder="如：finance_manager" :disabled="isEdit" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="form.description" type="textarea" :rows="3" placeholder="角色职责描述" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio :value="1">启用</el-radio>
            <el-radio :value="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible=false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>

    <!-- 分配权限弹窗 -->
    <el-dialog v-model="menuVisible" title="分配权限" width="400px" destroy-on-close>
      <el-tree
        ref="menuTreeRef"
        :data="menuTreeData"
        :props="{ label: 'name', children: 'children' }"
        node-key="id"
        :default-expand-all="true"
        show-checkbox
        check-strictly
      />
      <template #footer>
        <el-button @click="menuVisible=false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleMenuSubmit">确定分配</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'

const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const dialogVisible = ref(false)
const menuVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()
const menuTreeRef = ref()
const currentRoleId = ref(null)
const menuTreeData = ref([])

const query = reactive({ page: 1, pageSize: 20 })
const form = reactive({ id: null, roleName: '', roleCode: '', description: '', status: 1 })
const rules = {
  roleName: [{ required: true, message: '请输入角色名称', trigger: 'blur' }],
  roleCode: [{ required: true, message: '请输入角色代码', trigger: 'blur' }]
}
const dialogTitle = computed(() => isEdit.value ? '编辑角色' : '新增角色')

const fetchData = async () => {
  loading.value = true
  try { const res = await request.get('/system/roles', { params: query }); tableData.value = res.data?.list || []; total.value = res.data?.total || 0 }
  catch { tableData.value = [] } finally { loading.value = false }
}
const fetchMenuTree = async () => {
  try { const res = await request.get('/system/menus'); menuTreeData.value = buildTree(res.data || []) }
  catch { menuTreeData.value = [] }
}
const buildTree = (list) => {
  const map = {}, roots = []
  list.forEach(i => { map[i.id] = { ...i, children: [] } })
  list.forEach(i => { if (i.parentId && map[i.parentId]) map[i.parentId].children.push(map[i.id]); else roots.push(map[i]) })
  return roots
}
const handleAdd = () => { isEdit.value = false; Object.assign(form, { id: null, roleName: '', roleCode: '', description: '', status: 1 }); dialogVisible.value = true }
const handleEdit = (row) => { isEdit.value = true; Object.assign(form, { ...row }); dialogVisible.value = true }
const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) { await request.put(`/system/roles/${form.id}`, form) }
    else { await request.post('/system/roles', form) }
    ElMessage.success(isEdit.value ? '编辑成功' : '新增成功'); dialogVisible.value = false; fetchData()
  } finally { submitting.value = false }
}
const handleDelete = async (row) => {
  await ElMessageBox.confirm(`确定删除角色「${row.roleName}」？`, '提示', { type: 'warning' })
  await request.delete(`/system/roles/${row.id}`); ElMessage.success('删除成功'); fetchData()
}
const handleStatusChange = async (row) => {
  try { await request.put(`/system/roles/${row.id}`, { status: row.status }); ElMessage.success(row.status === 1 ? '已启用' : '已禁用') }
  catch { row.status = row.status === 1 ? 0 : 1 }
}
const handleAssignMenu = async (row) => {
  currentRoleId.value = row.id
  await fetchMenuTree()
  menuVisible.value = true
  try {
    const res = await request.get(`/system/roles/${row.id}/menus`)
    nextTick(() => { menuTreeRef.value?.setCheckedKeys(res.data || [], false) })
  } catch {}
}
const handleMenuSubmit = async () => {
  const checkedKeys = menuTreeRef.value?.getCheckedKeys() || []
  await request.post(`/system/roles/${currentRoleId.value}/menus`, { menuIds: checkedKeys })
  ElMessage.success('权限分配成功'); menuVisible.value = false
}

onMounted(fetchData)
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
