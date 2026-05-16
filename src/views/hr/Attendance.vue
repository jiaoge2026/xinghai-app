<template>
  <div class="attendance-page">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>考勤记录</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">打卡记录</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="员工">
          <el-select v-model="query.employeeId" placeholder="全部" clearable filterable style="width:160px">
            <el-option v-for="e in empOptions" :key="e.id" :value="e.id" :label="e.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="日期">
          <el-date-picker v-model="query.date" type="date" value-format="YYYY-MM-DD" style="width:130px" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="全部" clearable style="width:120px">
            <el-option v-for="item in STATUS_OPTIONS" :key="item.value" :value="item.value" :label="item.label" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="employeeName" label="员工姓名" min-width="100" />
        <el-table-column prop="departmentName" label="部门" min-width="120" />
        <el-table-column prop="date" label="日期" width="120" />
        <el-table-column prop="checkInTime" label="上班打卡" width="100" />
        <el-table-column prop="checkOutTime" label="下班打卡" width="100" />
        <el-table-column prop="workHours" label="工时" width="80" align="center">
          <template #default="{ row }">{{ row.workHours ? row.workHours + 'h' : '-' }}</template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="statusConfig[row.status]?.type" size="small">{{ statusConfig[row.status]?.label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" min-width="150" show-overflow-tooltip />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
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
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="480px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="员工" prop="employeeId">
          <el-select v-model="form.employeeId" placeholder="选择员工" filterable style="width:100%">
            <el-option v-for="e in empOptions" :key="e.id" :value="e.id" :label="e.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="日期" prop="date">
          <el-date-picker v-model="form.date" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
        <el-form-item label="上班打卡">
          <el-time-picker v-model="form.checkInTime" value-format="HH:mm:ss" style="width:100%" placeholder="上班时间" />
        </el-form-item>
        <el-form-item label="下班打卡">
          <el-time-picker v-model="form.checkOutTime" value-format="HH:mm:ss" style="width:100%" placeholder="下班时间" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="form.status" placeholder="选择状态" style="width:100%">
            <el-option v-for="item in STATUS_OPTIONS" :key="item.value" :value="item.value" :label="item.label" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" placeholder="可选备注" />
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
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'

// ============ 常量定义 ============
const API_PATH = '/hr/attendance'

const STATUS_OPTIONS = [
  { value: 1, label: '正常' },
  { value: 2, label: '迟到' },
  { value: 3, label: '早退' },
  { value: 4, label: '缺勤' }
]

const STATUS_TYPE_MAP = {
  1: 'success',
  2: 'warning',
  3: 'warning',
  4: 'danger'
}

// ============ 状态配置计算属性 ============
const statusConfig = computed(() => {
  const config = {}
  STATUS_OPTIONS.forEach(opt => {
    config[opt.value] = { label: opt.label, type: STATUS_TYPE_MAP[opt.value] }
  })
  return config
})

// ============ 默认表单数据 ============
const createEmptyForm = () => ({
  id: null,
  employeeId: null,
  date: '',
  checkInTime: '',
  checkOutTime: '',
  status: 1,
  remark: ''
})

// ============ 响应式状态 ============
const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const empOptions = ref([])
const dialogVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()

let query = reactive({
  page: 1,
  pageSize: 20,
  employeeId: null,
  date: '',
  status: null
})

let form = reactive(createEmptyForm())

const rules = {
  employeeId: [{ required: true, message: '请选择员工', trigger: 'change' }],
  date: [{ required: true, message: '请选择日期', trigger: 'change' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }]
}

// ============ 计算属性 ============
const dialogTitle = computed(() => isEdit.value ? '编辑考勤' : '新增打卡')

// ============ API 请求 ============
const fetchAttendanceList = async () => {
  loading.value = true
  try {
    const res = await request.get(API_PATH, { params: query })
    tableData.value = res.data?.list ?? []
    total.value = res.data?.total ?? 0
  } catch (err) {
    console.error('[Attendance] 获取考勤列表失败:', err)
    tableData.value = []
    ElMessage.error('获取考勤列表失败')
  } finally {
    loading.value = false
  }
}

const fetchEmployeeOptions = async () => {
  try {
    const res = await request.get('/hr/employees')
    empOptions.value = res.data?.list ?? []
  } catch (err) {
    console.error('[Attendance] 获取员工列表失败:', err)
    empOptions.value = []
  }
}

const submitAttendance = async (payload) => {
  if (isEdit.value) {
    await request.put(`${API_PATH}/${payload.id}`, payload)
  } else {
    await request.post(API_PATH, payload)
  }
}

// ============ 事件处理 ============
const fetchData = fetchAttendanceList

const resetQuery = () => {
  Object.assign(query, {
    employeeId: null,
    date: '',
    status: null,
    page: 1
  })
  fetchData()
}

const openAddDialog = () => {
  isEdit.value = false
  Object.assign(form, createEmptyForm())
  dialogVisible.value = true
}

const openEditDialog = (row) => {
  isEdit.value = true
  Object.assign(form, { ...row })
  dialogVisible.value = true
}

const handleAdd = openAddDialog
const handleEdit = openEditDialog

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  submitting.value = true
  try {
    await submitAttendance({ ...form })
    ElMessage.success(isEdit.value ? '编辑成功' : '新增成功')
    dialogVisible.value = false
    fetchData()
  } catch (err) {
    console.error('[Attendance] 提交失败:', err)
    ElMessage.error('提交失败')
  } finally {
    submitting.value = false
  }
}

// ============ 生命周期 ============
onMounted(() => {
  fetchData()
  fetchEmployeeOptions()
})
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
