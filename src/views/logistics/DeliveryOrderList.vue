<template>
  <div class="delivery-order-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>配送单管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新建配送单</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="配送单号">
          <el-input v-model="query.deliveryNo" placeholder="配送单号" clearable style="width:160px" />
        </el-form-item>
        <el-form-item label="司机">
          <el-select v-model="query.driverId" placeholder="全部" clearable filterable style="width:150px">
            <el-option v-for="d in driverOptions" :key="d.id" :value="d.id" :label="d.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="全部" clearable style="width:130px">
            <el-option :value="1" label="待配送" />
            <el-option :value="2" label="配送中" />
            <el-option :value="3" label="已完成" />
            <el-option :value="4" label="已取消" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="deliveryNo" label="配送单号" width="170" />
        <el-table-column prop="driverName" label="司机" min-width="100" />
        <el-table-column prop="plateNo" label="车牌号" width="120" />
        <el-table-column prop="totalQuantity" label="配送数量" width="100" align="center" />
        <el-table-column prop="status" label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="statusType[row.status]" size="small">{{ statusLabel[row.status] }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="planDate" label="计划日期" width="120" />
        <el-table-column prop="actualDate" label="完成时间" width="120" />
        <el-table-column prop="remark" label="备注" min-width="150" show-overflow-tooltip />
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
    <el-dialog v-model="viewVisible" title="配送单详情" width="700px" destroy-on-close>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="配送单号">{{ viewData.deliveryNo }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="statusType[viewData.status]">{{ statusLabel[viewData.status] }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="司机">{{ viewData.driverName }}</el-descriptions-item>
        <el-descriptions-item label="车牌号">{{ viewData.plateNo }}</el-descriptions-item>
        <el-descriptions-item label="计划日期">{{ viewData.planDate }}</el-descriptions-item>
        <el-descriptions-item label="完成时间">{{ viewData.actualDate }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewData.remark }}</el-descriptions-item>
      </el-descriptions>
      <el-divider>配送明细</el-divider>
      <el-table :data="viewData.items || []" stripe size="small">
        <el-table-column prop="productName" label="商品名称" min-width="150" />
        <el-table-column prop="quantity" label="数量" width="100" align="center" />
        <el-table-column prop="deliveredQty" label="已配送" width="100" align="center" />
        <el-table-column prop="status" label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'warning'" size="small">
              {{ row.status === 1 ? '已送达' : '待配送' }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>
    </el-dialog>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="550px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="司机" prop="driverId">
          <el-select v-model="form.driverId" placeholder="选择司机" filterable style="width:100%">
            <el-option v-for="d in driverOptions" :key="d.id" :value="d.id" :label="d.name + ' - ' + d.plateNo" />
          </el-select>
        </el-form-item>
        <el-form-item label="计划日期" prop="planDate">
          <el-date-picker v-model="form.planDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
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
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'

const statusLabel = { 1: '待配送', 2: '配送中', 3: '已完成', 4: '已取消' }
const statusType = { 1: 'warning', 2: 'primary', 3: 'success', 4: 'info' }
const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const driverOptions = ref([])
const dialogVisible = ref(false)
const viewVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()
const viewData = ref({})

const query = reactive({ page: 1, pageSize: 20, deliveryNo: '', driverId: null, status: null })
const form = reactive({ id: null, driverId: null, planDate: '', remark: '' })
const rules = { driverId: [{ required: true, message: '请选择司机', trigger: 'change' }], planDate: [{ required: true, message: '请选择计划日期', trigger: 'change' }] }
const dialogTitle = computed(() => isEdit.value ? '编辑配送单' : '新建配送单')

const fetchData = async () => {
  loading.value = true
  try { const res = await request.get('/logistics/delivery-orders', { params: query }); tableData.value = res.data?.list || []; total.value = res.data?.total || 0 }
  catch { tableData.value = [] } finally { loading.value = false }
}
const fetchDrivers = async () => {
  try { const res = await request.get('/logistics/drivers'); driverOptions.value = res.data?.list || [] } catch { driverOptions.value = [] }
}
const resetQuery = () => { Object.assign(query, { deliveryNo: '', driverId: null, status: null, page: 1 }); fetchData() }
const handleAdd = () => { isEdit.value = false; Object.assign(form, { id: null, driverId: null, planDate: '', remark: '' }); dialogVisible.value = true }
const handleEdit = (row) => { isEdit.value = true; Object.assign(form, { id: row.id, driverId: row.driverId, planDate: row.planDate, remark: row.remark }); dialogVisible.value = true }
const handleView = async (row) => { viewData.value = { ...row }; viewVisible.value = true }
const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) { await request.put(`/logistics/delivery-orders/${form.id}`, form) }
    else { await request.post('/logistics/delivery-orders', form) }
    ElMessage.success(isEdit.value ? '编辑成功' : '新建成功'); dialogVisible.value = false; fetchData()
  } finally { submitting.value = false }
}

onMounted(() => { fetchData(); fetchDrivers() })
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
