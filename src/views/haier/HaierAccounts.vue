<template>
  <div class="page-container">
    <div class="toolbar">
      <el-button type="primary" @click="handleAdd">+ 添加账号</el-button>
    </div>

    <el-table :data="tableData" stripe v-loading="loading">
      <el-table-column prop="accountNo" label="账号" width="140" />
      <el-table-column prop="accountName" label="账号名称" min-width="150" />
      <el-table-column prop="password" label="密码" width="160">
        <template #default="{row}">******</template>
      </el-table-column>
      <el-table-column prop="orgName" label="所属网点" min-width="150" />
      <el-table-column prop="orgCode" label="网点编码" width="140" />
      <el-table-column prop="status" label="状态" width="80" align="center">
        <template #default="{row}">
          <el-switch v-model="row.status" active-value="active" inactive-value="inactive" @change="handleToggleStatus(row)" />
        </template>
      </el-table-column>
      <el-table-column prop="createdAt" label="添加时间" width="160">
        <template #default="{row}">{{ row.createdAt ? new Date(row.createdAt).toLocaleString() : '-' }}</template>
      </el-table-column>
      <el-table-column label="操作" width="120" fixed="right">
        <template #default="{row}">
          <el-button link type="primary" @click="handleEdit(row)">编辑</el-button>
          <el-button link type="danger" @click="handleDelete(row.id)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <div class="pagination-wrap">
      <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="20" v-model:current-page="pageNum" @current-change="loadData" />
    </div>

    <el-dialog v-model="dialogVisible" :title="isEdit ? '编辑账号' : '添加账号'" width="550px" destroy-on-close>
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-form-item label="账号" prop="accountNo"><el-input v-model="form.accountNo" :disabled="isEdit" /></el-form-item>
        <el-form-item label="账号名称" prop="accountName"><el-input v-model="form.accountName" /></el-form-item>
        <el-form-item label="密码" prop="password"><el-input v-model="form.password" type="password" show-password /></el-form-item>
        <el-form-item label="网点编码" prop="orgCode"><el-input v-model="form.orgCode" /></el-form-item>
        <el-form-item label="所属网点" prop="orgName"><el-input v-model="form.orgName" /></el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="form.status" style="width:100%">
            <el-option label="启用" value="active" />
            <el-option label="停用" value="inactive" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible=false">取消</el-button>
        <el-button type="primary" @click="handleSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '@/utils/request'

const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const pageNum = ref(1)
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref()

let form = reactive({ id: null, accountNo: '', accountName: '', password: '', orgCode: '', orgName: '', status: 'active' })
const rules = {
  accountNo: [{ required: true, message: '请输入账号', trigger: 'blur' }],
  accountName: [{ required: true, message: '请输入账号名称', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }],
}

const loadData = async () => {
  loading.value = true
  try {
    const res = await request.get('/haier-sync/accounts', { pageNum: pageNum.value, pageSize: 20 })
    tableData.value = res.data?.list || res.data || []
    total.value = res.data?.total || 0
  } catch (e) { console.error(e) }
  finally { loading.value = false }
}

const handleAdd = () => {
  isEdit.value = false
  Object.assign(form, { id: null, accountNo: '', accountName: '', password: '', orgCode: '', orgName: '', status: 'active' })
  dialogVisible.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  Object.assign(form, { ...row, password: '' })
  dialogVisible.value = true
}

const handleSave = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  try {
    if (isEdit.value) await request.put(`/haier-sync/accounts/${form.id}`, form)
    else await request.post('/haier-sync/accounts', form)
    ElMessage.success('保存成功')
    dialogVisible.value = false
    loadData()
  } catch (e) { ElMessage.error('保存失败') }
}

const handleToggleStatus = async (row) => {
  try { await request.put(`/haier-sync/accounts/${row.id}`, { status: row.status }) }
  catch (e) { ElMessage.error('修改状态失败'); loadData() }
}

const handleDelete = async (id) => {
  await ElMessageBox.confirm('确认删除此账号？', '警告', { type: 'warning' })
  try { await request.delete(`/haier-sync/accounts/${id}`); ElMessage.success('删除成功'); loadData() }
  catch (e) { ElMessage.error('删除失败') }
}

onMounted(loadData)
</script>

<style scoped>
.page-container { padding: 16px; }
.toolbar { margin-bottom: 12px; }
.pagination-wrap { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
