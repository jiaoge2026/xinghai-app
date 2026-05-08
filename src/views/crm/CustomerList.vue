<template>
  <div class="customer-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>客户管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增客户</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="客户名称">
          <el-input v-model="query.name" placeholder="客户名称" clearable style="width:150px" />
        </el-form-item>
        <el-form-item label="客户类型">
          <el-select v-model="query.type" placeholder="全部" clearable style="width:130px">
            <el-option :value="1" label="个人" />
            <el-option :value="2" label="企业" />
          </el-select>
        </el-form-item>
        <el-form-item label="客户等级">
          <el-select v-model="query.level" placeholder="全部" clearable style="width:120px">
            <el-option value="A" label="A类" />
            <el-option value="B" label="B类" />
            <el-option value="C" label="C类" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="name" label="客户名称" min-width="180" />
        <el-table-column prop="type" label="类型" width="90" align="center">
          <template #default="{ row }">{{ row.type === 1 ? '个人' : '企业' }}</template>
        </el-table-column>
        <el-table-column prop="level" label="等级" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="levelType[row.level]" size="small">{{ row.level }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="contactName" label="联系人" min-width="100" />
        <el-table-column prop="contactPhone" label="联系电话" width="130" />
        <el-table-column prop="address" label="地址" min-width="200" show-overflow-tooltip />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleView(row)">详情</el-button>
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

    <!-- 详情弹窗 -->
    <el-dialog v-model="viewVisible" title="客户详情" width="600px" destroy-on-close>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="客户名称" :span="2">{{ viewData.name }}</el-descriptions-item>
        <el-descriptions-item label="类型">{{ viewData.type === 1 ? '个人' : '企业' }}</el-descriptions-item>
        <el-descriptions-item label="等级">
          <el-tag :type="levelType[viewData.level]">{{ viewData.level }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="联系人">{{ viewData.contactName }}</el-descriptions-item>
        <el-descriptions-item label="联系电话">{{ viewData.contactPhone }}</el-descriptions-item>
        <el-descriptions-item label="地址" :span="2">{{ viewData.address }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewData.remark }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="550px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="客户名称" prop="name">
          <el-input v-model="form.name" placeholder="客户名称" />
        </el-form-item>
        <el-form-item label="客户类型" prop="type">
          <el-radio-group v-model="form.type">
            <el-radio :value="1">个人</el-radio>
            <el-radio :value="2">企业</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="客户等级">
          <el-select v-model="form.level" style="width:100%">
            <el-option value="A" label="A类（重要客户）" />
            <el-option value="B" label="B类（普通客户）" />
            <el-option value="C" label="C类（潜在客户）" />
          </el-select>
        </el-form-item>
        <el-form-item label="联系人" prop="contactName">
          <el-input v-model="form.contactName" placeholder="联系人姓名" />
        </el-form-item>
        <el-form-item label="联系电话" prop="contactPhone">
          <el-input v-model="form.contactPhone" placeholder="手机或座机" />
        </el-form-item>
        <el-form-item label="地址">
          <el-input v-model="form.address" type="textarea" :rows="2" placeholder="详细地址" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" placeholder="备注信息" />
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

const levelType = { A: 'danger', B: 'warning', C: 'info' }
const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const dialogVisible = ref(false)
const viewVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()
const viewData = ref({})

const query = reactive({ page: 1, pageSize: 20, name: '', type: null, level: '' })
const form = reactive({ id: null, name: '', type: 1, level: 'B', contactName: '', contactPhone: '', address: '', remark: '' })
const rules = { name: [{ required: true, message: '请输入客户名称', trigger: 'blur' }], contactName: [{ required: true, message: '请输入联系人', trigger: 'blur' }], contactPhone: [{ required: true, message: '请输入联系电话', trigger: 'blur' }] }
const dialogTitle = computed(() => isEdit.value ? '编辑客户' : '新增客户')

const fetchData = async () => {
  loading.value = true
  try { const res = await request.get('/crm/contacts', { params: query }); tableData.value = res.data?.list || []; total.value = res.data?.total || 0 }
  catch { tableData.value = [] } finally { loading.value = false }
}
const resetQuery = () => { Object.assign(query, { name: '', type: null, level: '', page: 1 }); fetchData() }
const handleAdd = () => { isEdit.value = false; Object.assign(form, { id: null, name: '', type: 1, level: 'B', contactName: '', contactPhone: '', address: '', remark: '' }); dialogVisible.value = true }
const handleEdit = (row) => { isEdit.value = true; Object.assign(form, { ...row }); dialogVisible.value = true }
const handleView = (row) => { viewData.value = { ...row }; viewVisible.value = true }
const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) { await request.put(`/crm/customers/${form.id}`, form) }
    else { await request.post('/crm/contacts', form) }
    ElMessage.success(isEdit.value ? '编辑成功' : '新增成功'); dialogVisible.value = false; fetchData()
  } finally { submitting.value = false }
}
const handleDelete = async (row) => {
  await ElMessageBox.confirm(`确定删除客户「${row.name}」？`, '提示', { type: 'warning' })
  await request.delete(`/crm/customers/${row.id}`); ElMessage.success('删除成功'); fetchData()
}

onMounted(fetchData)
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
