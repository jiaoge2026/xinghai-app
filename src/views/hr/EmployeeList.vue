<template>
  <div class="employee-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>员工管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增员工</el-button>
        </div>
      </template>

      <!-- 搜索区 -->
      <el-form :inline="true" class="search-form">
        <el-form-item label="姓名">
          <el-input v-model="query.name" placeholder="姓名" clearable style="width:140px" />
        </el-form-item>
        <el-form-item label="部门">
          <el-select v-model="query.departmentId" placeholder="全部" clearable style="width:150px">
            <el-option v-for="d in deptOptions" :key="d.id" :value="d.id" :label="d.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="全部" clearable style="width:120px">
            <el-option :value="1" label="在职" />
            <el-option :value="2" label="离职" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 表格 -->
      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="employeeNo" label="工号" width="100" />
        <el-table-column prop="name" label="姓名" min-width="100" />
        <el-table-column prop="gender" label="性别" width="70" align="center">
          <template #default="{ row }">{{ row.gender === 1 ? '男' : '女' }}</template>
        </el-table-column>
        <el-table-column prop="phone" label="手机号" width="130" />
        <el-table-column prop="departmentName" label="部门" min-width="120" />
        <el-table-column prop="position" label="岗位" min-width="120" />
        <el-table-column prop="status" label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">
              {{ row.status === 1 ? '在职' : '离职' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="hireDate" label="入职日期" width="120" />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
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
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="550px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="工号" prop="employeeNo">
          <el-input v-model="form.employeeNo" placeholder="如：EMP001" :disabled="isEdit" />
        </el-form-item>
        <el-form-item label="姓名" prop="name">
          <el-input v-model="form.name" placeholder="员工姓名" />
        </el-form-item>
        <el-form-item label="性别" prop="gender">
          <el-radio-group v-model="form.gender">
            <el-radio :value="1">男</el-radio>
            <el-radio :value="2">女</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="form.phone" placeholder="11位手机号" />
        </el-form-item>
        <el-form-item label="部门" prop="departmentId">
          <el-select v-model="form.departmentId" placeholder="选择部门" style="width:100%">
            <el-option v-for="d in deptOptions" :key="d.id" :value="d.id" :label="d.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="岗位">
          <el-input v-model="form.position" placeholder="职位/岗位" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="form.email" placeholder="可选" />
        </el-form-item>
        <el-form-item label="入职日期">
          <el-date-picker v-model="form.hireDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio :value="1">在职</el-radio>
            <el-radio :value="2">离职</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible=false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">确定</el-button>
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
const deptOptions = ref([])
const dialogVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()

const query = reactive({ page: 1, pageSize: 20, name: '', departmentId: null, status: null })

const form = reactive({
  id: null, employeeNo: '', name: '', gender: 1, phone: '',
  departmentId: null, departmentName: '', position: '', email: '',
  hireDate: '', status: 1
})

const rules = {
  employeeNo: [{ required: true, message: '请输入工号', trigger: 'blur' }],
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  phone: [
    { required: true, message: '请输入手机号', trigger: 'blur' },
    { pattern: /^1[3-9]\d{9}$/, message: '手机号格式不正确', trigger: 'blur' }
  ],
  departmentId: [{ required: true, message: '请选择部门', trigger: 'change' }]
}

const dialogTitle = computed(() => isEdit.value ? '编辑员工' : '新增员工')

const fetchData = async () => {
  loading.value = true
  try {
    const res = await request.get('/hr/employees', { params: query })
    tableData.value = res.data?.list || []
    total.value = res.data?.total || 0
  } catch { tableData.value = [] } finally { loading.value = false }
}

const fetchDepts = async () => {
  try {
    const res = await request.get('/hr/departments')
    deptOptions.value = Array.isArray(res.data) ? res.data : (res.data?.list || [])
  } catch { deptOptions.value = [] }
}

const resetQuery = () => {
  query.name = ''; query.departmentId = null; query.status = null; query.page = 1
  fetchData()
}

const handleAdd = () => {
  isEdit.value = false
  Object.assign(form, { id: null, employeeNo: '', name: '', gender: 1, phone: '',
    departmentId: null, departmentName: '', position: '', email: '',
    hireDate: '', status: 1 })
  dialogVisible.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  Object.assign(form, { ...row })
  dialogVisible.value = true
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) {
      await request.put(`/hr/employees/${form.id}`, form)
    } else {
      await request.post('/hr/employees', form)
    }
    ElMessage.success(isEdit.value ? '编辑成功' : '新增成功')
    dialogVisible.value = false
    fetchData()
  } finally { submitting.value = false }
}

const handleDelete = async (row) => {
  await ElMessageBox.confirm(`确定删除员工「${row.name}」？`, '提示', { type: 'warning' })
  await request.delete(`/hr/employees/${row.id}`)
  ElMessage.success('删除成功')
  fetchData()
}

onMounted(() => { fetchData(); fetchDepts() })
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
