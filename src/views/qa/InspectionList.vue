<template>
  <div class="inspection-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>质检管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新建质检</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="质检单号">
          <el-input v-model="query.inspectionNo" placeholder="质检单号" clearable style="width:160px" />
        </el-form-item>
        <el-form-item label="质检类型">
          <el-select v-model="query.type" placeholder="全部" clearable style="width:130px">
            <el-option :value="1" label="巡检" />
            <el-option :value="2" label="抽检" />
            <el-option :value="3" label="全检" />
          </el-select>
        </el-form-item>
        <el-form-item label="结果">
          <el-select v-model="query.result" placeholder="全部" clearable style="width:120px">
            <el-option :value="1" label="合格" />
            <el-option :value="2" label="不合格" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="inspectionNo" label="质检单号" width="170" />
        <el-table-column prop="type" label="类型" width="90" align="center">
          <template #default="{ row }">
            <el-tag size="small">{{ typeLabel[row.type] }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="inspectorName" label="质检员" min-width="100" />
        <el-table-column prop="itemName" label="检品名称" min-width="150" />
        <el-table-column prop="quantity" label="数量" width="80" align="center" />
        <el-table-column prop="result" label="结果" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.result === 1 ? 'success' : 'danger'" size="small">
              {{ row.result === 1 ? '合格' : '不合格' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="defectDesc" label="不合格描述" min-width="200" show-overflow-tooltip />
        <el-table-column prop="inspectionDate" label="质检日期" width="120" />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleView(row)">详情</el-button>
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

    <!-- 详情弹窗 -->
    <el-dialog v-model="viewVisible" title="质检详情" width="600px" destroy-on-close>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="质检单号">{{ viewData.inspectionNo }}</el-descriptions-item>
        <el-descriptions-item label="质检类型">{{ typeLabel[viewData.type] }}</el-descriptions-item>
        <el-descriptions-item label="质检员">{{ viewData.inspectorName }}</el-descriptions-item>
        <el-descriptions-item label="质检日期">{{ viewData.inspectionDate }}</el-descriptions-item>
        <el-descriptions-item label="检品名称">{{ viewData.itemName }}</el-descriptions-item>
        <el-descriptions-item label="数量">{{ viewData.quantity }}</el-descriptions-item>
        <el-descriptions-item label="结果">
          <el-tag :type="viewData.result === 1 ? 'success' : 'danger'">{{ viewData.result === 1 ? '合格' : '不合格' }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="不合格数">{{ viewData.defectCount ?? '-' }}</el-descriptions-item>
        <el-descriptions-item label="不合格描述" :span="2">{{ viewData.defectDesc }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewData.remark }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="550px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="质检类型" prop="type">
          <el-select v-model="form.type" style="width:100%">
            <el-option :value="1" label="巡检" />
            <el-option :value="2" label="抽检" />
            <el-option :value="3" label="全检" />
          </el-select>
        </el-form-item>
        <el-form-item label="检品名称" prop="itemName">
          <el-input v-model="form.itemName" placeholder="被检品名称" />
        </el-form-item>
        <el-form-item label="数量" prop="quantity">
          <el-input-number v-model="form.quantity" :min="1" style="width:100%" />
        </el-form-item>
        <el-form-item label="质检结果" prop="result">
          <el-radio-group v-model="form.result">
            <el-radio :value="1">合格</el-radio>
            <el-radio :value="2">不合格</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="不合格数">
          <el-input-number v-model="form.defectCount" :min="0" style="width:100%" />
        </el-form-item>
        <el-form-item label="不合格描述">
          <el-input v-model="form.defectDesc" type="textarea" :rows="2" placeholder="不合格项目描述" />
        </el-form-item>
        <el-form-item label="质检日期">
          <el-date-picker v-model="form.inspectionDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
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
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'

const typeLabel = { 1: '巡检', 2: '抽检', 3: '全检' }
const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const dialogVisible = ref(false)
const viewVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()
const viewData = ref({})

const query = reactive({ page: 1, pageSize: 20, inspectionNo: '', type: null, result: null })
const form = reactive({ id: null, type: 1, itemName: '', quantity: 1, result: 1, defectCount: 0, defectDesc: '', inspectionDate: '', remark: '' })
const rules = { type: [{ required: true, message: '请选择质检类型', trigger: 'change' }], itemName: [{ required: true, message: '请输入检品名称', trigger: 'blur' }], quantity: [{ required: true, message: '请输入数量', trigger: 'blur' }], result: [{ required: true, message: '请选择结果', trigger: 'change' }] }
const dialogTitle = computed(() => isEdit.value ? '编辑质检' : '新建质检')

const fetchData = async () => {
  loading.value = true
  try { const res = await request.get('/qa/inspections', { params: query }); tableData.value = res.data?.list || []; total.value = res.data?.total || 0 }
  catch { tableData.value = [] } finally { loading.value = false }
}
const resetQuery = () => { Object.assign(query, { inspectionNo: '', type: null, result: null, page: 1 }); fetchData() }
const handleAdd = () => { isEdit.value = false; Object.assign(form, { id: null, type: 1, itemName: '', quantity: 1, result: 1, defectCount: 0, defectDesc: '', inspectionDate: '', remark: '' }); dialogVisible.value = true }
const handleEdit = (row) => { isEdit.value = true; Object.assign(form, { ...row }); dialogVisible.value = true }
const handleView = (row) => { viewData.value = { ...row }; viewVisible.value = true }
const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) { await request.put(`/qa/inspections/${form.id}`, form) }
    else { await request.post('/qa/inspections', form) }
    ElMessage.success(isEdit.value ? '编辑成功' : '新建成功'); dialogVisible.value = false; fetchData()
  } finally { submitting.value = false }
}

onMounted(fetchData)
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
