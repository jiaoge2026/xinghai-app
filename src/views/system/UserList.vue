<template>
  <div class="user-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>用户管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增用户</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="用户名">
          <el-input v-model="query.username" placeholder="用户名" clearable style="width:140px" />
        </el-form-item>
        <el-form-item label="姓名">
          <el-input v-model="query.name" placeholder="姓名" clearable style="width:140px" />
        </el-form-item>
        <el-form-item label="角色">
          <el-select v-model="query.roleId" placeholder="全部角色" clearable style="width:160px">
            <el-option v-for="r in roleOptions" :key="r.id" :value="r.id" :label="r.roleName" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="username" label="用户名" width="150" />
        <el-table-column prop="name" label="姓名" min-width="120" />
        <el-table-column prop="phone" label="手机号" width="130" />
        <el-table-column prop="email" label="邮箱" min-width="180" show-overflow-tooltip />
        <el-table-column prop="roles" label="角色" min-width="200">
          <template #default="{ row }">
            <el-tag v-for="r in (row.roles || [])" :key="r.id" size="small" style="margin-right:4px">{{ r.roleName }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">{{ row.status === 1 ? '启用' : '禁用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleAssignRole(row)">分配角色</el-button>
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
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="form.username" placeholder="登录用户名" :disabled="isEdit" />
        </el-form-item>
        <el-form-item label="姓名" prop="name">
          <el-input v-model="form.name" placeholder="真实姓名" />
        </el-form-item>
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="form.phone" placeholder="11位手机号" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="form.email" placeholder="邮箱地址" />
        </el-form-item>
        <el-form-item v-if="!isEdit" label="初始密码" prop="password">
          <el-input v-model="form.password" type="password" show-password placeholder="设置初始密码" />
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
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'

const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const roleOptions = ref([])
const dialogVisible = ref(false)
const roleVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()
const currentUserId = ref(null)
const selectedRoles = ref([])

const query = reactive({ page: 1, pageSize: 20, username: '', name: '', roleId: null })
const form = reactive({ id: null, username: '', name: '', phone: '', email: '', password: '', status: 1 })
const rules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  phone: [{ pattern: /^1[3-9]\d{9}$/, message: '手机号格式不正确', trigger: 'blur' }],
  password: [{ required: true, min: 6, message: '密码至少6位', trigger: 'blur' }]
}
const dialogTitle = computed(() => isEdit.value ? '编辑用户' : '新增用户')

const fetchData = async () => {
  loading.value = true
  try { const res = await request.get('/system/users', { params: query }); tableData.value = res.data?.list || []; total.value = res.data?.total || 0 }
  catch { tableData.value = [] } finally { loading.value = false }
}
const fetchRoles = async () => {
  try { const res = await request.get('/system/roles'); roleOptions.value = res.data?.list || [] } catch { roleOptions.value = [] }
}
const resetQuery = () => { Object.assign(query, { username: '', name: '', roleId: null, page: 1 }); fetchData() }
const handleAdd = () => { isEdit.value = false; Object.assign(form, { id: null, username: '', name: '', phone: '', email: '', password: '', status: 1 }); dialogVisible.value = true }
const handleEdit = (row) => { isEdit.value = true; Object.assign(form, { ...row }); dialogVisible.value = true }
const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) { await request.put(`/system/users/${form.id}`, form) }
    else { await request.post('/system/users', form) }
    ElMessage.success(isEdit.value ? '编辑成功' : '新增成功'); dialogVisible.value = false; fetchData()
  } finally { submitting.value = false }
}
const handleDelete = async (row) => {
  await ElMessageBox.confirm(`确定删除用户「${row.username}」？`, '提示', { type: 'warning' })
  await request.delete(`/system/users/${row.id}`); ElMessage.success('删除成功'); fetchData()
}
const handleAssignRole = async (row) => {
  currentUserId.value = row.id
  selectedRoles.value = (row.roles || []).map(r => r.id)
  roleVisible.value = true
}
const handleRoleSubmit = async () => {
  await request.post(`/system/users/${currentUserId.value}/roles`, { roleIds: selectedRoles.value })
  ElMessage.success('角色分配成功'); roleVisible.value = false; fetchData()
}

onMounted(() => { fetchData(); fetchRoles() })
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
