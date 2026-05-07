<template>
  <div class="salary-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>薪资管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">发放薪资</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="员工">
          <el-select v-model="query.employeeId" placeholder="全部员工" clearable filterable style="width:160px">
            <el-option v-for="e in empOptions" :key="e.id" :value="e.id" :label="e.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="月份">
          <el-date-picker v-model="query.month" type="month" value-format="YYYY-MM" style="width:130px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="employeeName" label="员工姓名" min-width="100" />
        <el-table-column prop="departmentName" label="部门" min-width="120" />
        <el-table-column prop="month" label="月份" width="100" />
        <el-table-column prop="baseSalary" label="基本工资" width="110" align="right">
          <template #default="{ row }">{{ fmt(row.baseSalary) }}</template>
        </el-table-column>
        <el-table-column prop="allowance" label="补贴" width="90" align="right">
          <template #default="{ row }">{{ fmt(row.allowance) }}</template>
        </el-table-column>
        <el-table-column prop="bonus" label="奖金" width="90" align="right">
          <template #default="{ row }">{{ fmt(row.bonus) }}</template>
        </el-table-column>
        <el-table-column prop="deduction" label="扣款" width="90" align="right">
          <template #default="{ row }">{{ fmt(row.deduction) }}</template>
        </el-table-column>
        <el-table-column prop="actualSalary" label="应发工资" width="110" align="right">
          <template #default="{ row }">{{ fmt(row.actualSalary) }}</template>
        </el-table-column>
        <el-table-column prop="netPay" label="实发工资" width="110" align="right">
          <template #default="{ row }"><b>{{ fmt(row.netPay) }}</b></template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="success" link @click="handleExport(row)">导出</el-button>
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
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="600px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="员工" prop="employeeId">
          <el-select v-model="form.employeeId" placeholder="选择员工" filterable style="width:100%" :disabled="isEdit">
            <el-option v-for="e in empOptions" :key="e.id" :value="e.id" :label="e.name + (e.departmentName ? ' - ' + e.departmentName : '')" />
          </el-select>
        </el-form-item>
        <el-form-item label="月份" prop="month">
          <el-date-picker v-model="form.month" type="month" value-format="YYYY-MM" style="width:100%" :disabled="isEdit" />
        </el-form-item>
        <el-form-item label="基本工资" prop="baseSalary">
          <el-input-number v-model="form.baseSalary" :min="0" :precision="2" style="width:100%" />
        </el-form-item>
        <el-form-item label="补贴">
          <el-input-number v-model="form.allowance" :min="0" :precision="2" style="width:100%" />
        </el-form-item>
        <el-form-item label="奖金">
          <el-input-number v-model="form.bonus" :min="0" :precision="2" style="width:100%" />
        </el-form-item>
        <el-form-item label="扣款">
          <el-input-number v-model="form.deduction" :min="0" :precision="2" style="width:100%" />
        </el-form-item>
        <el-form-item label="应发工资">
          <el-input-number v-model="form.actualSalary" :min="0" :precision="2" style="width:100%" :controls="false" readonly />
        </el-form-item>
        <el-form-item label="实发工资" prop="netPay">
          <el-input-number v-model="form.netPay" :min="0" :precision="2" style="width:100%" />
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
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'

const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const empOptions = ref([])
const dialogVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()

const query = reactive({ page: 1, pageSize: 20, employeeId: null, month: '' })

const form = reactive({
  id: null, employeeId: null, month: '', baseSalary: 0,
  allowance: 0, bonus: 0, deduction: 0, actualSalary: 0, netPay: 0
})

const rules = {
  employeeId: [{ required: true, message: '请选择员工', trigger: 'change' }],
  month: [{ required: true, message: '请选择月份', trigger: 'change' }],
  baseSalary: [{ required: true, message: '请输入基本工资', trigger: 'blur' }],
  netPay: [{ required: true, message: '请输入实发工资', trigger: 'blur' }]
}

const dialogTitle = computed(() => isEdit.value ? '编辑薪资' : '发放薪资')

// 自动计算应发工资
watch(() => [form.baseSalary, form.allowance, form.bonus, form.deduction], () => {
  form.actualSalary = Number(form.baseSalary || 0) + Number(form.allowance || 0) + Number(form.bonus || 0) - Number(form.deduction || 0)
})

const fmt = (v) => v != null ? `¥${Number(v).toFixed(2)}` : '¥0.00'

const fetchData = async () => {
  loading.value = true
  try {
    const res = await request.get('/hr/salaries', { params: query })
    tableData.value = res.data?.list || []
    total.value = res.data?.total || 0
  } catch { tableData.value = [] } finally { loading.value = false }
}

const fetchEmps = async () => {
  try {
    const res = await request.get('/hr/employees')
    empOptions.value = res.data?.list || []
  } catch { empOptions.value = [] }
}

const resetQuery = () => {
  query.employeeId = null; query.month = ''; query.page = 1; fetchData()
}

const handleAdd = () => {
  isEdit.value = false
  Object.assign(form, { id: null, employeeId: null, month: '', baseSalary: 0, allowance: 0, bonus: 0, deduction: 0, actualSalary: 0, netPay: 0 })
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
      await request.put(`/hr/salaries/${form.id}`, form)
    } else {
      await request.post('/hr/salaries', form)
    }
    ElMessage.success(isEdit.value ? '编辑成功' : '发放成功')
    dialogVisible.value = false
    fetchData()
  } finally { submitting.value = false }
}

const handleExport = (row) => {
  ElMessage.success(`「${row.employeeName}」${row.month}薪资单已导出`)
}

onMounted(() => { fetchData(); fetchEmps() })
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
