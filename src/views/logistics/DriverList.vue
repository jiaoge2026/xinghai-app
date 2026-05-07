<template>
  <div class="driver-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>司机管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增司机</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="姓名">
          <el-input v-model="query.name" placeholder="司机姓名" clearable style="width:140px" />
        </el-form-item>
        <el-form-item label="车牌号">
          <el-input v-model="query.plateNo" placeholder="车牌号" clearable style="width:140px" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="全部" clearable style="width:120px">
            <el-option :value="1" label="空闲" />
            <el-option :value="2" label="配送中" />
            <el-option :value="3" label="离线" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="name" label="姓名" min-width="100" />
        <el-table-column prop="phone" label="手机号" width="130" />
        <el-table-column prop="plateNo" label="车牌号" width="120" />
        <el-table-column prop="vehicleType" label="车型" min-width="100" />
        <el-table-column prop="licenseNo" label="驾照号" min-width="180" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="statusType[row.status]" size="small">{{ statusLabel[row.status] }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="deliveryCount" label="配送次数" width="100" align="center" />
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

    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="500px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="姓名" prop="name">
          <el-input v-model="form.name" placeholder="司机姓名" />
        </el-form-item>
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="form.phone" placeholder="11位手机号" />
        </el-form-item>
        <el-form-item label="车牌号" prop="plateNo">
          <el-input v-model="form.plateNo" placeholder="如：京A12345" />
        </el-form-item>
        <el-form-item label="车型">
          <el-input v-model="form.vehicleType" placeholder="如：厢式货车" />
        </el-form-item>
        <el-form-item label="驾照号">
          <el-input v-model="form.licenseNo" placeholder="驾驶证号码" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="form.status" style="width:100%">
            <el-option :value="1" label="空闲" />
            <el-option :value="2" label="配送中" />
            <el-option :value="3" label="离线" />
          </el-select>
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

const statusLabel = { 1: '空闲', 2: '配送中', 3: '离线' }
const statusType = { 1: 'success', 2: 'primary', 3: 'info' }
const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const dialogVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()

const query = reactive({ page: 1, pageSize: 20, name: '', plateNo: '', status: null })
const form = reactive({ id: null, name: '', phone: '', plateNo: '', vehicleType: '', licenseNo: '', status: 1 })
const rules = {
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  phone: [{ required: true, message: '请输入手机号', trigger: 'blur' }],
  plateNo: [{ required: true, message: '请输入车牌号', trigger: 'blur' }]
}
const dialogTitle = computed(() => isEdit.value ? '编辑司机' : '新增司机')

const fetchData = async () => {
  loading.value = true
  try { const res = await request.get('/logistics/drivers', { params: query }); tableData.value = res.data?.list || []; total.value = res.data?.total || 0 }
  catch { tableData.value = [] } finally { loading.value = false }
}
const resetQuery = () => { Object.assign(query, { name: '', plateNo: '', status: null, page: 1 }); fetchData() }
const handleAdd = () => { isEdit.value = false; Object.assign(form, { id: null, name: '', phone: '', plateNo: '', vehicleType: '', licenseNo: '', status: 1 }); dialogVisible.value = true }
const handleEdit = (row) => { isEdit.value = true; Object.assign(form, { ...row }); dialogVisible.value = true }
const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) { await request.put(`/logistics/drivers/${form.id}`, form) }
    else { await request.post('/logistics/drivers', form) }
    ElMessage.success(isEdit.value ? '编辑成功' : '新增成功'); dialogVisible.value = false; fetchData()
  } finally { submitting.value = false }
}
const handleDelete = async (row) => {
  await ElMessageBox.confirm(`确定删除司机「${row.name}」？`, '提示', { type: 'warning' })
  await request.delete(`/logistics/drivers/${row.id}`); ElMessage.success('删除成功'); fetchData()
}

onMounted(fetchData)
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
