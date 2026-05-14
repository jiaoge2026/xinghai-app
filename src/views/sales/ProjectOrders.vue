<template>
  <div class="project-orders">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>项目订单</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增订单</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="关键词">
          <el-input v-model="query.keyword" placeholder="项目单号/客户名称" clearable style="width:160px" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="全部" clearable style="width:130px">
            <el-option value="executing" label="执行中" />
            <el-option value="completed" label="已完成" />
            <el-option value="cancelled" label="已取消" />
          </el-select>
        </el-form-item>
        <el-form-item label="签订日期">
          <el-date-picker
            v-model="dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            value-format="YYYY-MM-DD"
            style="width:240px"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="orderNo" label="项目单号" min-width="150" />
        <el-table-column prop="customerName" label="客户名称" min-width="140" />
        <el-table-column prop="projectName" label="项目名称" min-width="160" />
        <el-table-column prop="contact" label="联系人" width="100" />
        <el-table-column prop="totalAmount" label="合同总额" width="120" align="right">
          <template #default="{ row }">{{ formatCurrency(row.totalAmount) }}</template>
        </el-table-column>
        <el-table-column prop="paidAmount" label="已收款" width="110" align="right">
          <template #default="{ row }">{{ formatCurrency(row.paidAmount) }}</template>
        </el-table-column>
        <el-table-column label="待收款" width="110" align="right">
          <template #default="{ row }">{{ formatCurrency((row.totalAmount || 0) - (row.paidAmount || 0)) }}</template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="statusType[row.status]" size="small">{{ statusLabel[row.status] }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="signDate" label="签订日期" width="110">
          <template #default="{ row }">{{ row.signDate ? new Date(row.signDate).toLocaleDateString() : '-' }}</template>
        </el-table-column>
        <el-table-column prop="createdAt" label="创建时间" width="160">
          <template #default="{ row }">{{ row.createdAt ? new Date(row.createdAt).toLocaleString() : '-' }}</template>
        </el-table-column>
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleView(row)">详情</el-button>
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination">
        <el-pagination
          v-model:current-page="query.pageNum"
          v-model:page-size="query.pageSize"
          :total="total"
          :page-sizes="[10,20,50]"
          layout="total,sizes,prev,pager,next"
          @change="fetchData"
        />
      </div>
    </el-card>

    <!-- 详情弹窗 -->
    <el-dialog v-model="viewVisible" title="订单详情" width="600px" destroy-on-close>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="项目单号">{{ viewData.orderNo }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="statusType[viewData.status]">{{ statusLabel[viewData.status] }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="客户名称" :span="2">{{ viewData.customerName }}</el-descriptions-item>
        <el-descriptions-item label="项目名称" :span="2">{{ viewData.projectName }}</el-descriptions-item>
        <el-descriptions-item label="联系人">{{ viewData.contact }}</el-descriptions-item>
        <el-descriptions-item label="联系电话">{{ viewData.phone }}</el-descriptions-item>
        <el-descriptions-item label="合同总额">{{ formatCurrency(viewData.totalAmount) }}</el-descriptions-item>
        <el-descriptions-item label="已收款">{{ formatCurrency(viewData.paidAmount) }}</el-descriptions-item>
        <el-descriptions-item label="待收款">{{ formatCurrency((viewData.totalAmount || 0) - (viewData.paidAmount || 0)) }}</el-descriptions-item>
        <el-descriptions-item label="签订日期">{{ viewData.signDate ? new Date(viewData.signDate).toLocaleDateString() : '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ viewData.createdAt ? new Date(viewData.createdAt).toLocaleString() : '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewData.remark }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="550px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="客户名称" prop="customerName">
          <el-input v-model="form.customerName" placeholder="客户名称" />
        </el-form-item>
        <el-form-item label="项目名称" prop="projectName">
          <el-input v-model="form.projectName" placeholder="项目名称" />
        </el-form-item>
        <el-form-item label="联系人" prop="contact">
          <el-input v-model="form.contact" placeholder="联系人" />
        </el-form-item>
        <el-form-item label="联系电话" prop="phone">
          <el-input v-model="form.phone" placeholder="手机或座机" />
        </el-form-item>
        <el-form-item label="合同总额" prop="totalAmount">
          <el-input-number v-model="form.totalAmount" :min="0" :precision="2" placeholder="合同总额" style="width:100%" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="form.status" style="width:100%">
            <el-option value="executing" label="执行中" />
            <el-option value="completed" label="已完成" />
            <el-option value="cancelled" label="已取消" />
          </el-select>
        </el-form-item>
        <el-form-item label="签订日期" prop="signDate">
          <el-date-picker
            v-model="form.signDate"
            type="date"
            value-format="YYYY-MM-DD"
            placeholder="选择日期"
            style="width:100%"
          />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="3" placeholder="备注信息" />
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

const statusType = { executing: 'primary', completed: 'success', cancelled: 'info' }
const statusLabel = { executing: '执行中', completed: '已完成', cancelled: '已取消' }

const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const dialogVisible = ref(false)
const viewVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()
const viewData = ref({})
const dateRange = ref([])

const query = reactive({ pageNum: 1, pageSize: 20, keyword: '', status: '', startDate: '', endDate: '' })
const form = reactive({ id: null, customerName: '', projectName: '', contact: '', phone: '', totalAmount: 0, status: 'executing', signDate: '', paidAmount: 0, remark: '' })
const rules = {
  customerName: [{ required: true, message: '请输入客户名称', trigger: 'blur' }],
  projectName: [{ required: true, message: '请输入项目名称', trigger: 'blur' }],
  contact: [{ required: true, message: '请输入联系人', trigger: 'blur' }],
  phone: [{ required: true, message: '请输入联系电话', trigger: 'blur' }],
  totalAmount: [{ required: true, message: '请输入合同总额', trigger: 'blur' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }]
}
const dialogTitle = computed(() => isEdit.value ? '编辑订单' : '新增订单')

const formatCurrency = (val) => {
  if (val == null) return '-'
  return '¥' + Number(val).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

const fetchData = async () => {
  loading.value = true
  try {
    const params = { ...query }
    if (dateRange.value && dateRange.value.length === 2) {
      params.startDate = dateRange.value[0]
      params.endDate = dateRange.value[1]
    } else {
      params.startDate = ''
      params.endDate = ''
    }
    const res = await request.get('/sales/project-order/page', { params })
    tableData.value = res.data?.list || []
    total.value = res.data?.total || 0
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

const resetQuery = () => {
  Object.assign(query, { pageNum: 1, keyword: '', status: '', startDate: '', endDate: '' })
  dateRange.value = []
  fetchData()
}

const handleAdd = () => {
  isEdit.value = false
  Object.assign(form, { id: null, customerName: '', projectName: '', contact: '', phone: '', totalAmount: 0, status: 'executing', signDate: '', paidAmount: 0, remark: '' })
  dialogVisible.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  Object.assign(form, { ...row })
  dialogVisible.value = true
}

const handleView = (row) => {
  viewData.value = { ...row }
  viewVisible.value = true
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) {
      await request.put(`/sales/project-order/page/${form.id}`, form)
    } else {
      await request.post('/sales/project-order', form)
    }
    ElMessage.success(isEdit.value ? '编辑成功' : '新增成功')
    dialogVisible.value = false
    fetchData()
  } finally {
    submitting.value = false
  }
}

const handleDelete = async (row) => {
  await ElMessageBox.confirm(`确定删除订单「${row.orderNo}」？`, '提示', { type: 'warning' })
  await request.delete(`/sales/project-order/${row.id}`)
  ElMessage.success('删除成功')
  fetchData()
}

onMounted(fetchData)
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
