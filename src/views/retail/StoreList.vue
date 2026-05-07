<template>
  <div class="store-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>门店管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增门店</el-button>
        </div>
      </template>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="name" label="门店名称" min-width="180" />
        <el-table-column prop="code" label="门店编号" width="120" />
        <el-table-column prop="address" label="门店地址" min-width="250" show-overflow-tooltip />
        <el-table-column prop="managerName" label="店长" min-width="100" />
        <el-table-column prop="phone" label="联系电话" width="130" />
        <el-table-column prop="status" label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">{{ row.status === 1 ? '营业中' : '休息中' }}</el-tag>
          </template>
        </el-table-column>
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

    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="550px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="门店名称" prop="name">
          <el-input v-model="form.name" placeholder="门店名称" />
        </el-form-item>
        <el-form-item label="门店编号" prop="code">
          <el-input v-model="form.code" placeholder="如：STORE001" :disabled="isEdit" />
        </el-form-item>
        <el-form-item label="门店地址" prop="address">
          <el-input v-model="form.address" type="textarea" :rows="2" placeholder="详细地址" />
        </el-form-item>
        <el-form-item label="联系电话" prop="phone">
          <el-input v-model="form.phone" placeholder="门店电话" />
        </el-form-item>
        <el-form-item label="店长">
          <el-input v-model="form.managerName" placeholder="店长姓名" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio :value="1">营业中</el-radio>
            <el-radio :value="0">休息中</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="营业时间">
          <el-input v-model="form.businessHours" placeholder="如：09:00-21:00" />
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
const dialogVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()

const query = reactive({ page: 1, pageSize: 20 })
const form = reactive({ id: null, name: '', code: '', address: '', phone: '', managerName: '', businessHours: '', status: 1 })
const rules = { name: [{ required: true, message: '请输入门店名称', trigger: 'blur' }], code: [{ required: true, message: '请输入门店编号', trigger: 'blur' }] }
const dialogTitle = computed(() => isEdit.value ? '编辑门店' : '新增门店')

const fetchData = async () => {
  loading.value = true
  try { const res = await request.get('/retail/stores', { params: query }); tableData.value = res.data?.list || []; total.value = res.data?.total || 0 }
  catch { tableData.value = [] } finally { loading.value = false }
}
const handleAdd = () => { isEdit.value = false; Object.assign(form, { id: null, name: '', code: '', address: '', phone: '', managerName: '', businessHours: '', status: 1 }); dialogVisible.value = true }
const handleEdit = (row) => { isEdit.value = true; Object.assign(form, { ...row }); dialogVisible.value = true }
const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) { await request.put(`/retail/stores/${form.id}`, form) }
    else { await request.post('/retail/stores', form) }
    ElMessage.success(isEdit.value ? '编辑成功' : '新增成功'); dialogVisible.value = false; fetchData()
  } finally { submitting.value = false }
}
const handleDelete = async (row) => {
  await ElMessageBox.confirm(`确定删除门店「${row.name}」？`, '提示', { type: 'warning' })
  await request.delete(`/retail/stores/${row.id}`); ElMessage.success('删除成功'); fetchData()
}

onMounted(fetchData)
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
