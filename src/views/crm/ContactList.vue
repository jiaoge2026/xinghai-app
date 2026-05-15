<template>
  <div class="contact-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>联系人管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增联系人</el-button>
        </div>
      </template>

      <SearchForm
        :fields="searchFields"
        v-model="query"
        @search="handleSearch"
        @reset="handleReset"
      />

      <DataTable
        :data="tableData"
        :columns="tableColumns"
        :loading="loading"
        :pagination="pagination"
        row-key="id"
        @page-change="handlePageChange"
        @size-change="handleSizeChange"
        @action="handleTableAction"
      >
        <template #isPrimary="{ row }">
          <el-tag v-if="row.isPrimary === 1" type="warning" size="small">主联系</el-tag>
          <span v-else>-</span>
        </template>
      </DataTable>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="500px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="姓名" prop="name">
          <el-input v-model="form.name" placeholder="联系人姓名" />
        </el-form-item>
        <el-form-item label="所属客户" prop="customerId">
          <el-select v-model="form.customerId" placeholder="选择客户" filterable style="width:100%">
            <el-option v-for="c in customerOptions" :key="c.id" :value="c.id" :label="c.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="职位">
          <el-input v-model="form.position" placeholder="如：采购经理" />
        </el-form-item>
        <el-form-item label="手机" prop="phone">
          <el-input v-model="form.phone" placeholder="手机号" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="form.email" placeholder="邮箱地址" />
        </el-form-item>
        <el-form-item label="主联系人">
          <el-switch v-model="form.isPrimary" :active-value="1" :inactive-value="0" active-text="是" inactive-text="否" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
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
import { SearchForm, DataTable } from '@/components/page-components'

const loading = ref(false)
const tableData = ref([])
const customerOptions = ref([])
const dialogVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()

const query = reactive({ page: 1, pageSize: 20, name: '', customerId: null })
const pagination = computed(() => ({ page: query.page, pageSize: query.pageSize, total: total.value }))
const total = ref(0)

const form = reactive({ id: null, name: '', customerId: null, position: '', phone: '', email: '', isPrimary: 0, remark: '' })
const rules = { name: [{ required: true, message: '请输入姓名', trigger: 'blur' }], customerId: [{ required: true, message: '请选择客户', trigger: 'change' }], phone: [{ required: true, message: '请输入手机', trigger: 'blur' }] }
const dialogTitle = computed(() => isEdit.value ? '编辑联系人' : '新增联系人')

// ============ 搜索 ============
const searchFields = [
  { key: 'name', label: '姓名', type: 'input', placeholder: '联系人姓名' },
  {
    key: 'customerId',
    label: '客户',
    type: 'select',
    placeholder: '全部客户',
    options: [],
  },
]

function handleSearch(params) {
  Object.assign(query, params)
  query.page = 1
  fetchData()
}

function handleReset(params) {
  Object.assign(query, params)
  query.page = 1
  fetchData()
}

// ============ 表格 ============
const tableColumns = [
  { key: 'name', label: '姓名', minWidth: 100 },
  { key: 'customerName', label: '所属客户', minWidth: 180 },
  { key: 'position', label: '职位', minWidth: 120 },
  { key: 'phone', label: '手机', width: 130 },
  { key: 'email', label: '邮箱', minWidth: 180, showOverflowTooltip: true },
  { key: 'isPrimary', label: '主联系人', width: 100, align: 'center', slot: 'isPrimary' },
  {
    key: 'actions',
    label: '操作',
    width: 150,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'edit', label: '编辑', type: 'primary', size: 'small', link: true },
      { key: 'delete', label: '删除', type: 'danger', size: 'small', link: true, danger: true },
    ],
  },
]

function handleTableAction(action, row) {
  if (action === 'edit') handleEdit(row)
  else if (action === 'delete') handleDelete(row)
}

function handlePageChange(page) { query.page = page; fetchData() }
function handleSizeChange(size) { query.pageSize = size; query.page = 1; fetchData() }

// ============ 数据请求 ============
const fetchData = async () => {
  loading.value = true
  try { const res = await request.get('/crm/contacts', { params: query }); tableData.value = res.data?.list || []; total.value = res.data?.total || 0 }
  catch { tableData.value = [] } finally { loading.value = false }
}
const fetchCustomers = async () => {
  try { const res = await request.get('/crm/contacts'); customerOptions.value = res.data?.list || [] } catch { customerOptions.value = [] }
}

const handleAdd = () => { isEdit.value = false; Object.assign(form, { id: null, name: '', customerId: null, position: '', phone: '', email: '', isPrimary: 0, remark: '' }); dialogVisible.value = true }
const handleEdit = (row) => { isEdit.value = true; Object.assign(form, { ...row }); dialogVisible.value = true }
const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) { await request.put(`/crm/contacts/${form.id}`, form) }
    else { await request.post('/crm/contacts', form) }
    ElMessage.success(isEdit.value ? '编辑成功' : '新增成功'); dialogVisible.value = false; fetchData()
  } finally { submitting.value = false }
}
const handleDelete = async (row) => {
  await ElMessageBox.confirm(`确定删除联系人「${row.name}」？`, '提示', { type: 'warning' })
  await request.delete(`/crm/contacts/${row.id}`); ElMessage.success('删除成功'); fetchData()
}

// 加载客户选项到搜索表单
onMounted(() => {
  fetchData()
  fetchCustomers().then(() => {
    searchFields[1].options = customerOptions.value.map(c => ({ label: c.name, value: c.id }))
  })
})
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
</style>
