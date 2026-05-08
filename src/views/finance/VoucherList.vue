<template>
  <div class="voucher-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>凭证管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增凭证</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="凭证号">
          <el-input v-model="query.voucherNo" placeholder="凭证号" clearable style="width:150px" />
        </el-form-item>
        <el-form-item label="日期">
          <el-date-picker v-model="query.dateRange" type="daterange" value-format="YYYY-MM-DD" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:240px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="voucherNo" label="凭证号" width="160" />
        <el-table-column prop="voucherDate" label="制单日期" width="120" />
        <el-table-column prop="subjectName" label="会计科目" min-width="150" />
        <el-table-column prop="summary" label="摘要" min-width="200" show-overflow-tooltip />
        <el-table-column prop="debitAmount" label="借方金额" width="130" align="right">
          <template #default="{ row }">{{ row.debitAmount != null ? fmt(row.debitAmount) : '' }}</template>
        </el-table-column>
        <el-table-column prop="creditAmount" label="贷方金额" width="130" align="right">
          <template #default="{ row }">{{ row.creditAmount != null ? fmt(row.creditAmount) : '' }}</template>
        </el-table-column>
        <el-table-column prop="creatorName" label="制单人" width="100" />
        <el-table-column prop="status" label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">
              {{ row.status === 1 ? '已审核' : '草稿' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleView(row)">查看</el-button>
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

    <!-- 查看弹窗 -->
    <el-dialog v-model="viewVisible" title="凭证详情" width="700px" destroy-on-close>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="凭证号">{{ viewData.voucherNo }}</el-descriptions-item>
        <el-descriptions-item label="制单日期">{{ viewData.voucherDate }}</el-descriptions-item>
        <el-descriptions-item label="会计科目">{{ viewData.subjectName }}</el-descriptions-item>
        <el-descriptions-item label="摘要" :span="2">{{ viewData.summary }}</el-descriptions-item>
        <el-descriptions-item label="借方金额">{{ fmt(viewData.debitAmount) }}</el-descriptions-item>
        <el-descriptions-item label="贷方金额">{{ fmt(viewData.creditAmount) }}</el-descriptions-item>
        <el-descriptions-item label="制单人">{{ viewData.creatorName }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="viewData.status === 1 ? 'success' : 'info'">{{ viewData.status === 1 ? '已审核' : '草稿' }}</el-tag>
        </el-descriptions-item>
      </el-descriptions>
    </el-dialog>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="550px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="凭证号" prop="voucherNo">
          <el-input v-model="form.voucherNo" placeholder="系统自动生成，可手动填写" />
        </el-form-item>
        <el-form-item label="制单日期" prop="voucherDate">
          <el-date-picker v-model="form.voucherDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
        <el-form-item label="会计科目" prop="subjectId">
          <el-select v-model="form.subjectId" placeholder="选择科目" style="width:100%" filterable>
            <el-option v-for="s in subjectOptions" :key="s.id" :value="s.id" :label="s.subjectCode + ' ' + s.subjectName" />
          </el-select>
        </el-form-item>
        <el-form-item label="摘要" prop="summary">
          <el-input v-model="form.summary" type="textarea" :rows="2" placeholder="业务摘要" />
        </el-form-item>
        <el-form-item label="借方金额" prop="debitAmount">
          <el-input-number v-model="form.debitAmount" :min="0" :precision="2" style="width:100%" :controls="false" />
        </el-form-item>
        <el-form-item label="贷方金额" prop="creditAmount">
          <el-input-number v-model="form.creditAmount" :min="0" :precision="2" style="width:100%" :controls="false" />
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
const subjectOptions = ref([])
const dialogVisible = ref(false)
const viewVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()
const viewData = ref({})

const query = reactive({ page: 1, pageSize: 20, voucherNo: '', dateRange: null })
const form = reactive({ id: null, voucherNo: '', voucherDate: '', subjectId: null, subjectName: '', summary: '', debitAmount: null, creditAmount: null })
const rules = {
  voucherDate: [{ required: true, message: '请选择日期', trigger: 'change' }],
  subjectId: [{ required: true, message: '请选择会计科目', trigger: 'change' }],
  summary: [{ required: true, message: '请输入摘要', trigger: 'blur' }]
}
const dialogTitle = computed(() => isEdit.value ? '编辑凭证' : '新增凭证')
const fmt = (v) => v != null ? `¥${Number(v).toFixed(2)}` : ''

const fetchData = async () => {
  loading.value = true
  try {
    const params = { ...query }
    if (query.dateRange) { params.startDate = query.dateRange[0]; params.endDate = query.dateRange[1]; delete params.dateRange }
    const res = await request.get('/finance/vouchers', { params })
    tableData.value = res.data?.list || []
    total.value = res.data?.total || 0
  } catch { tableData.value = [] } finally { loading.value = false }
}
const fetchSubjects = async () => {
  try { const res = await request.get('/finance/subjects'); subjectOptions.value = res.data?.list || [] } catch { subjectOptions.value = [] }
}
const resetQuery = () => { query.voucherNo = ''; query.dateRange = null; query.page = 1; fetchData() }
const handleAdd = () => { isEdit.value = false; Object.assign(form, { id: null, voucherNo: '', voucherDate: '', subjectId: null, subjectName: '', summary: '', debitAmount: null, creditAmount: null }); dialogVisible.value = true }
const handleEdit = (row) => { isEdit.value = true; Object.assign(form, { ...row }); dialogVisible.value = true }
const handleView = (row) => { viewData.value = { ...row }; viewVisible.value = true }
const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) { await request.put(`/finance/vouchers/${form.id}`, form) }
    else { await request.post('/finance/vouchers', form) }
    ElMessage.success(isEdit.value ? '编辑成功' : '新增成功')
    dialogVisible.value = false; fetchData()
  } finally { submitting.value = false }
}
const handleDelete = async (row) => {
  await ElMessageBox.confirm(`确定删除凭证「${row.voucherNo}」？`, '提示', { type: 'warning' })
  await request.delete(`/finance/vouchers/${row.id}`)
  ElMessage.success('删除成功'); fetchData()
}

onMounted(() => { fetchData(); fetchSubjects() })
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
