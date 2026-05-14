<template>
  <div class="page-container">
    <el-form :inline="true" :model="query" class="search-form">
      <el-form-item><el-input v-model="query.keyword" placeholder="应收单号/客户名称" clearable style="width:200px" @keyup.enter="handleSearch" /></el-form-item>
      <el-form-item>
        <el-select v-model="query.status" placeholder="状态" clearable style="width:140px">
          <el-option label="未到期" value="pending" />
          <el-option label="部分收回" value="partial" />
          <el-option label="已结清" value="settled" />
          <el-option label="逾期" value="overdue" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" value-format="YYYY-MM-DD" style="width:240px" @change="onDateChange" />
      </el-form-item>
      <el-form-item><el-button type="primary" @click="handleSearch">搜索</el-button><el-button @click="handleReset">重置</el-button></el-form-item>
    </el-form>

    <div class="toolbar">
      <el-button type="primary" @click="handleAdd">+ 登记应收款</el-button>
    </div>

    <el-table :data="tableData" stripe v-loading="loading">
      <el-table-column prop="receivableNo" label="应收单号" width="150" />
      <el-table-column prop="orderNo" label="项目单号" width="140" />
      <el-table-column prop="customerName" label="客户名称" min-width="150" />
      <el-table-column prop="totalAmount" label="应收金额" width="120" align="right">
        <template #default="{row}">¥{{ (row.totalAmount || 0).toLocaleString() }}</template>
      </el-table-column>
      <el-table-column prop="receivedAmount" label="已收金额" width="120" align="right">
        <template #default="{row}">¥{{ (row.receivedAmount || 0).toLocaleString() }}</template>
      </el-table-column>
      <el-table-column prop="pendingAmount" label="待收金额" width="120" align="right">
        <template #default="{row}">
          <span :style="{ color: (row.totalAmount - row.receivedAmount) > 0 ? '#E6A23C' : '#67C23A' }">
            ¥{{ ((row.totalAmount || 0) - (row.receivedAmount || 0)).toLocaleString() }}
          </span>
        </template>
      </el-table-column>
      <el-table-column prop="dueDate" label="到期日期" width="120">
        <template #default="{row}">
          <span :class="{ overdue: isOverdue(row) }">{{ row.dueDate ? new Date(row.dueDate).toLocaleDateString() : '-' }}</span>
        </template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="100" align="center">
        <template #default="{row}">
          <el-tag :type="statusType(row.status)">{{ statusLabel(row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="createdAt" label="创建时间" width="160">
        <template #default="{row}">{{ row.createdAt ? new Date(row.createdAt).toLocaleString() : '-' }}</template>
      </el-table-column>
      <el-table-column label="操作" width="160" fixed="right">
        <template #default="{row}">
          <el-button link type="primary" @click="handleEdit(row)">编辑</el-button>
          <el-button link type="success" @click="handleReceive(row)">收款</el-button>
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

    <!-- 新建/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="isEdit ? '编辑应收款' : '登记应收款'" width="550px" destroy-on-close>
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-form-item label="项目单号" prop="orderNo"><el-input v-model="form.orderNo" /></el-form-item>
        <el-form-item label="客户名称" prop="customerName"><el-input v-model="form.customerName" /></el-form-item>
        <el-form-item label="应收金额" prop="totalAmount"><el-input-number v-model="form.totalAmount" :min="0" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="已收金额" prop="receivedAmount"><el-input-number v-model="form.receivedAmount" :min="0" :precision="2" style="width:100%" /></el-form-item>
        <el-form-item label="到期日期" prop="dueDate"><el-date-picker v-model="form.dueDate" type="date" value-format="YYYY-MM-DD" style="width:100%" /></el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="form.status" style="width:100%">
            <el-option label="未到期" value="pending" />
            <el-option label="部分收回" value="partial" />
            <el-option label="已结清" value="settled" />
            <el-option label="逾期" value="overdue" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible=false">取消</el-button>
        <el-button type="primary" @click="handleSave">保存</el-button>
      </template>
    </el-dialog>

    <!-- 收款弹窗 -->
    <el-dialog v-model="receiveVisible" title="登记收款" width="400px" destroy-on-close>
      <el-form :model="receiveForm" ref="receiveRef" label-width="100px">
        <el-form-item label="应收单号">{{ receiveForm.receivableNo }}</el-form-item>
        <el-form-item label="待收金额">¥{{ ((receiveForm.totalAmount || 0) - (receiveForm.receivedAmount || 0)).toLocaleString() }}</el-form-item>
        <el-form-item label="本次收款" prop="amount">
          <el-input-number v-model="receiveForm.amount" :min="0" :precision="2" style="width:100%" />
        </el-form-item>
        <el-form-item label="收款日期" prop="receiveDate">
          <el-date-picker v-model="receiveForm.receiveDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="receiveVisible=false">取消</el-button>
        <el-button type="primary" @click="handleReceiveSave">确认收款</el-button>
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
const receiveVisible = ref(false)
const isEdit = ref(false)
const formRef = ref()
const receiveRef = ref()

const form = reactive({ id: null, orderNo: '', customerName: '', totalAmount: 0, receivedAmount: 0, dueDate: '', status: 'pending', remark: '' })
const receiveForm = reactive({ id: null, receivableNo: '', totalAmount: 0, receivedAmount: 0, amount: 0, receiveDate: '' })

const rules = {
  customerName: [{ required: true, message: '请输入客户名称', trigger: 'blur' }],
  totalAmount: [{ required: true, message: '请输入应收金额', trigger: 'blur' }],
}

const statusLabel = (s) => ({ pending: '未到期', partial: '部分收回', settled: '已结清', overdue: '逾期' }[s] || s)
const statusType = (s) => ({ pending: 'info', partial: 'warning', settled: 'success', overdue: 'danger' }[s] || 'info')

const isOverdue = (row) => row.status === 'overdue' || (row.dueDate && new Date(row.dueDate) < new Date() && row.status !== 'settled')

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
    const res = await request.get('/sales/receivable/page', params)
    tableData.value = res.data?.records || res.data || []
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
  Object.assign(form, { id: null, orderNo: '', customerName: '', totalAmount: 0, receivedAmount: 0, dueDate: '', status: 'pending', remark: '' })
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
    if (isEdit.value) await request.put(`/sales/receivable/page/${form.id}`, form)
    else await request.post('/sales/receivable', form)
    ElMessage.success('保存成功')
    dialogVisible.value = false
    loadData()
  } catch (e) {
    ElMessage.error('保存失败')
  }
}

const handleReceive = (row) => {
  Object.assign(receiveForm, { id: row.id, receivableNo: row.receivableNo, totalAmount: row.totalAmount, receivedAmount: row.receivedAmount, amount: 0, receiveDate: '' })
  receiveVisible.value = true
}

const handleReceiveSave = async () => {
  if (!receiveForm.amount || receiveForm.amount <= 0) { ElMessage.warning('请输入收款金额'); return }
  try {
    await request.post(`/sales/receivable/page/${receiveForm.id}/receive`, { amount: receiveForm.amount, receiveDate: receiveForm.receiveDate })
    ElMessage.success('收款成功')
    receiveVisible.value = false
    loadData()
  } catch (e) {
    ElMessage.error('收款失败')
  }
}

const handleDelete = async (id) => {
  await ElMessageBox.confirm('确认删除此应收款记录？', '警告', { type: 'warning' })
  try {
    await request.delete(`/sales/receivable/${id}`)
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
.overdue { color: #F56C6C; font-weight: 600; }
</style>
