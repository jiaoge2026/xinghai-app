<template>
  <div class="page-container">
    <el-form :inline="true" :model="query" class="search-form">
      <el-form-item><el-input v-model="query.keyword" placeholder="报价单号/客户名称" clearable style="width:200px" @keyup.enter="handleSearch" /></el-form-item>
      <el-form-item>
        <el-select v-model="query.status" placeholder="状态" clearable style="width:130px">
          <el-option label="草稿" value="draft" />
          <el-option label="已发送" value="sent" />
          <el-option label="已确认" value="confirmed" />
          <el-option label="已作废" value="cancelled" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" value-format="YYYY-MM-DD" style="width:240px" @change="onDateChange" />
      </el-form-item>
      <el-form-item><el-button type="primary" @click="handleSearch">搜索</el-button><el-button @click="handleReset">重置</el-button></el-form-item>
    </el-form>

    <div class="toolbar">
      <el-button type="primary" @click="handleAdd">+ 新建报价单</el-button>
    </div>

    <el-table :data="tableData" stripe v-loading="loading">
      <el-table-column prop="quoteNo" label="报价单号" width="150" />
      <el-table-column prop="customerName" label="客户名称" min-width="150" />
      <el-table-column prop="contact" label="联系人" width="100" />
      <el-table-column prop="phone" label="电话" width="120" />
      <el-table-column prop="totalAmount" label="报价总额" width="120" align="right">
        <template #default="{row}">¥{{ (row.totalAmount || 0).toLocaleString() }}</template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="100" align="center">
        <template #default="{row}">
          <el-tag :type="statusType(row.status)">{{ statusLabel(row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="validDate" label="有效期至" width="120">
        <template #default="{row}">{{ row.validDate ? new Date(row.validDate).toLocaleDateString() : '-' }}</template>
      </el-table-column>
      <el-table-column prop="createdAt" label="创建时间" width="160">
        <template #default="{row}">{{ row.createdAt ? new Date(row.createdAt).toLocaleString() : '-' }}</template>
      </el-table-column>
      <el-table-column label="操作" width="140" fixed="right">
        <template #default="{row}">
          <el-button link type="primary" @click="handleEdit(row)">编辑</el-button>
          <el-button link type="danger" @click="handleDelete(row.id)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <div class="pagination-wrap">
      <el-pagination
        background
        layout="total, sizes, prev, pager, next"
        :total="total"
        :page-size="query.pageSize"
        :current-page="query.pageNum"
        @size-change="handleSizeChange"
        @current-change="handlePageChange"
      />
    </div>

    <el-dialog v-model="dialogVisible" :title="isEdit ? '编辑报价单' : '新建报价单'" width="600px" destroy-on-close>
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-form-item label="客户名称" prop="customerName"><el-input v-model="form.customerName" /></el-form-item>
        <el-form-item label="联系人" prop="contact"><el-input v-model="form.contact" /></el-form-item>
        <el-form-item label="联系电话" prop="phone"><el-input v-model="form.phone" /></el-form-item>
        <el-form-item label="报价总额" prop="totalAmount"><el-input-number v-model="form.totalAmount" :min="0" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="form.status" style="width:100%">
            <el-option label="草稿" value="draft" />
            <el-option label="已发送" value="sent" />
            <el-option label="已确认" value="confirmed" />
            <el-option label="已作废" value="cancelled" />
          </el-select>
        </el-form-item>
        <el-form-item label="有效期至" prop="validDate"><el-date-picker v-model="form.validDate" type="date" value-format="YYYY-MM-DD" style="width:100%" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="3" /></el-form-item>
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
const query = reactive({ pageNum: 1, pageSize: 20, keyword: '', status: '' })
const dateRange = ref([])
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref()

const form = reactive({
  id: null, customerName: '', contact: '', phone: '',
  totalAmount: 0, status: 'draft', validDate: '', remark: '',
})

const rules = {
  customerName: [{ required: true, message: '请输入客户名称', trigger: 'blur' }],
  totalAmount: [{ required: true, message: '请输入报价总额', trigger: 'blur' }],
}

const statusLabel = (s) => ({ draft: '草稿', sent: '已发送', confirmed: '已确认', cancelled: '已作废' }[s] || s)
const statusType = (s) => ({ draft: 'info', sent: 'warning', confirmed: 'success', cancelled: 'danger' }[s] || 'info')

const onDateChange = () => {
  query.startDate = dateRange.value?.[0] || ''
  query.endDate = dateRange.value?.[1] || ''
}

const loadData = async () => {
  loading.value = true
  try {
    const params = { pageNum: query.pageNum, pageSize: query.pageSize }
    if (query.keyword) params.keyword = query.keyword
    if (query.status) params.status = query.status
    if (query.startDate) params.startDate = query.startDate
    if (query.endDate) params.endDate = query.endDate
    const res = await request.get('/sales/quote/page', params)
    tableData.value = res.data?.list || res.data || []
    total.value = res.data?.total || 0
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

const handleSearch = () => { query.pageNum = 1; loadData() }
const handleReset = () => { query.keyword = ''; query.status = ''; dateRange.value = []; query.startDate = ''; query.endDate = ''; handleSearch() }
const handleSizeChange = (s) => { query.pageSize = s; loadData() }
const handlePageChange = (p) => { query.pageNum = p; loadData() }

const handleAdd = () => {
  isEdit.value = false
  Object.assign(form, { id: null, customerName: '', contact: '', phone: '', totalAmount: 0, status: 'draft', validDate: '', remark: '' })
  dialogVisible.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  Object.assign(form, { ...row })
  dialogVisible.value = true
}

const handleSave = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  try {
    if (isEdit.value) {
      await request.put(`/sales/quote/${form.id}`, form)
    } else {
      await request.post('/sales/quote', form)
    }
    ElMessage.success('保存成功')
    dialogVisible.value = false
    loadData()
  } catch (e) {
    ElMessage.error('保存失败')
  }
}

const handleDelete = async (id) => {
  await ElMessageBox.confirm('确认删除此报价单？', '警告', { type: 'warning' })
  try {
    await request.delete(`/sales/quote/${id}`)
    ElMessage.success('删除成功')
    loadData()
  } catch (e) {
    ElMessage.error('删除失败')
  }
}

onMounted(loadData)
</script>

<style scoped>
.page-container { padding: 16px; }
.search-form { margin-bottom: 12px; }
.toolbar { margin-bottom: 12px; }
.pagination-wrap { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
