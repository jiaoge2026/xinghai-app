<template>
  <div class="stock-list">
    <PageHeader title="库存台账">
      <template #actions>
        <el-button type="success" @click="openInDialog()">
          <el-icon><Top /></el-icon> 入库
        </el-button>
        <el-button type="warning" @click="openOutDialog()">
          <el-icon><Bottom /></el-icon> 出库
        </el-button>
        <el-button type="primary" @click="openCheckDialog">
          <el-icon><Refresh /></el-icon> 库存盘点
        </el-button>
      </template>
    </PageHeader>

    <div class="panel">
      <SearchForm
        :fields="searchFields"
        v-model="queryParams"
        @search="handleSearch"
        @reset="handleReset"
      />
    </div>

    <div class="panel">
      <DataTable
        ref="tableRef"
        :data="tableData"
        :columns="tableColumns"
        :loading="loading"
        :pagination="pagination"
        row-key="id"
        @page-change="handlePageChange"
        @size-change="handleSizeChange"
        @action="handleTableAction"
      />
    </div>

    <!-- 入库弹窗 -->
    <el-dialog v-model="inDialogVisible" title="配件入库" width="500px" :close-on-click-modal="false">
      <el-form ref="inFormRef" :model="stockForm" :rules="stockFormRules" label-width="100px">
        <el-form-item label="配件" prop="partId">
          <el-select
            v-model="stockForm.partId"
            placeholder="请选择配件"
            filterable
            style="width: 100%"
            :disabled="!!stockForm.partId && !!stockForm.partCode"
            @change="handlePartChange"
          >
            <el-option
              v-for="p in partList"
              :key="p.id"
              :label="`${p.code} - ${p.name}`"
              :value="p.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="配件编码">
          <el-input v-model="stockForm.partCode" disabled />
        </el-form-item>
        <el-form-item label="配件名称">
          <el-input v-model="stockForm.partName" disabled />
        </el-form-item>
        <el-form-item label="当前库存">
          <el-input v-model="stockForm.currentStock" disabled />
        </el-form-item>
        <el-form-item label="入库仓库" prop="warehouseId">
          <el-select v-model="stockForm.warehouseId" placeholder="请选择仓库" style="width: 100%">
            <el-option
              v-for="wh in warehouseList"
              :key="wh.id"
              :label="wh.name"
              :value="wh.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="入库数量" prop="quantity">
          <el-input-number v-model="stockForm.quantity" :min="1" :precision="0" :controls="true" style="width: 150px" />
        </el-form-item>
        <el-form-item label="操作人" prop="operator">
          <el-input v-model="stockForm.operator" placeholder="请输入操作人" maxlength="50" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="stockForm.remark" placeholder="请输入备注" type="textarea" :rows="2" maxlength="200" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="inDialogVisible = false">取消</el-button>
        <el-button type="success" :loading="inSubmitLoading" @click="handleInSubmit">确认入库</el-button>
      </template>
    </el-dialog>

    <!-- 出库弹窗 -->
    <el-dialog v-model="outDialogVisible" title="配件出库" width="500px" :close-on-click-modal="false">
      <el-form ref="outFormRef" :model="stockForm" :rules="stockFormRules" label-width="100px">
        <el-form-item label="配件" prop="partId">
          <el-select
            v-model="stockForm.partId"
            placeholder="请选择配件"
            filterable
            style="width: 100%"
            :disabled="!!stockForm.partId && !!stockForm.partCode"
            @change="handlePartChange"
          >
            <el-option
              v-for="p in partList"
              :key="p.id"
              :label="`${p.code} - ${p.name}`"
              :value="p.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="配件编码">
          <el-input v-model="stockForm.partCode" disabled />
        </el-form-item>
        <el-form-item label="配件名称">
          <el-input v-model="stockForm.partName" disabled />
        </el-form-item>
        <el-form-item label="当前库存">
          <el-input v-model="stockForm.currentStock" disabled />
        </el-form-item>
        <el-form-item label="出库仓库" prop="warehouseId">
          <el-select v-model="stockForm.warehouseId" placeholder="请选择仓库" style="width: 100%">
            <el-option
              v-for="wh in warehouseList"
              :key="wh.id"
              :label="wh.name"
              :value="wh.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="出库数量" prop="quantity">
          <el-input-number
            v-model="stockForm.quantity"
            :min="1"
            :max="stockForm.currentStock || 999999"
            :precision="0"
            :controls="true"
            style="width: 150px"
          />
        </el-form-item>
        <el-form-item label="操作人" prop="operator">
          <el-input v-model="stockForm.operator" placeholder="请输入操作人" maxlength="50" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="stockForm.remark" placeholder="请输入备注" type="textarea" :rows="2" maxlength="200" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="outDialogVisible = false">取消</el-button>
        <el-button type="warning" :loading="outSubmitLoading" @click="handleOutSubmit">确认出库</el-button>
      </template>
    </el-dialog>

    <!-- 库存盘点弹窗 -->
    <el-dialog v-model="checkDialogVisible" title="库存盘点" width="600px">
      <el-table :data="checkData" border stripe style="width: 100%">
        <el-table-column prop="partCode" label="配件编码" width="100" />
        <el-table-column prop="partName" label="配件名称" min-width="120" show-overflow-tooltip />
        <el-table-column prop="warehouseName" label="仓库" width="100" show-overflow-tooltip />
        <el-table-column prop="currentStock" label="系统库存" width="90" align="center" />
        <el-table-column prop="checkStock" label="盘点库存" width="100" align="center">
          <template #default="{ row }">
            <el-input-number
              v-model="row.checkStock"
              :min="0"
              :precision="0"
              :controls="false"
              size="small"
              style="width: 70px"
            />
          </template>
        </el-table-column>
        <el-table-column label="差异" width="80" align="center">
          <template #default="{ row }">
            <span :class="{ 'text-success': row.checkStock === row.currentStock, 'text-danger': row.checkStock !== row.currentStock }">
              {{ row.checkStock - row.currentStock }}
            </span>
          </template>
        </el-table-column>
      </el-table>
      <template #footer>
        <el-button @click="checkDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="checkSubmitLoading" @click="handleCheckSubmit">确认盘点</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Top, Bottom, Refresh } from '@element-plus/icons-vue'
import request from '@/utils/request'
import { SearchForm, DataTable, PageHeader } from '@/components/page-components'

// ============ 数据 ============
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })
const queryParams = reactive({ partCode: '', partName: '', warehouseId: null })

// ============ 仓库列表 ============
const warehouseList = ref([])

// ============ 配件列表 ============
const partList = ref([])

// ============ 搜索 ============
const searchFields = [
  { key: 'partCode', label: '配件编码', type: 'input', placeholder: '请输入配件编码' },
  { key: 'partName', label: '配件名称', type: 'input', placeholder: '请输入配件名称' },
  {
    key: 'warehouseId',
    label: '仓库',
    type: 'select',
    placeholder: '请选择仓库',
    options: [],
  },
]

function handleSearch(params) {
  Object.assign(queryParams, params)
  pagination.page = 1
  loadData()
}

function handleReset(params) {
  Object.assign(queryParams, params)
  pagination.page = 1
  loadData()
}

// ============ 表格 ============
const tableRef = ref()

const tableColumns = [
  { key: 'partCode', label: '配件编码', width: 120 },
  { key: 'partName', label: '配件名称', minWidth: 150, showOverflowTooltip: true },
  { key: 'warehouseName', label: '仓库', width: 120, showOverflowTooltip: true },
  {
    key: 'inQuantity',
    label: '入库数量',
    width: 100,
    align: 'right',
    slot: 'inQuantity',
  },
  {
    key: 'outQuantity',
    label: '出库数量',
    width: 100,
    align: 'right',
    slot: 'outQuantity',
  },
  {
    key: 'stockQuantity',
    label: '当前库存',
    width: 100,
    align: 'center',
    slot: 'stockQuantity',
  },
  { key: 'minStock', label: '最低库存', width: 100, align: 'center' },
  {
    key: 'lastInTime',
    label: '最后入库时间',
    width: 170,
    columnType: 'datetime',
  },
  {
    key: 'lastOutTime',
    label: '最后出库时间',
    width: 170,
    columnType: 'datetime',
  },
  {
    key: 'actions',
    label: '操作',
    width: 120,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'in', label: '入库', type: 'success', size: 'small', link: true },
      { key: 'out', label: '出库', type: 'warning', size: 'small', link: true },
    ],
  },
]

function handleTableAction(action, row) {
  if (action === 'in') openInDialog(row)
  else if (action === 'out') openOutDialog(row)
}

function handlePageChange(page) {
  pagination.page = page
  loadData()
}

function handleSizeChange(size) {
  pagination.pageSize = size
  pagination.page = 1
  loadData()
}

// ============ 入库/出库表单 ============
const inDialogVisible = ref(false)
const inSubmitLoading = ref(false)
const inFormRef = ref(null)

const outDialogVisible = ref(false)
const outSubmitLoading = ref(false)
const outFormRef = ref(null)

const defaultStockForm = () => ({
  partId: null,
  partCode: '',
  partName: '',
  currentStock: 0,
  warehouseId: null,
  quantity: 1,
  operator: '',
  remark: '',
})

const stockForm = reactive(defaultStockForm())

const stockFormRules = {
  partId: [{ required: true, message: '请选择配件', trigger: 'change' }],
  warehouseId: [{ required: true, message: '请选择仓库', trigger: 'change' }],
  quantity: [{ required: true, message: '请输入数量', trigger: 'blur' }],
  operator: [{ required: true, message: '请输入操作人', trigger: 'blur' }],
}

const handlePartChange = (partId) => {
  const part = partList.value.find(p => p.id === partId)
  if (part) {
    stockForm.partCode = part.code
    stockForm.partName = part.name
    stockForm.currentStock = part.stock || 0
    stockForm.warehouseId = part.warehouseId
  }
}

// ---------- 入库 ----------
const openInDialog = (row) => {
  Object.assign(stockForm, defaultStockForm())
  if (row) {
    stockForm.partId = row.partId
    handlePartChange(row.partId)
  }
  inDialogVisible.value = true
}

const handleInSubmit = async () => {
  try {
    await inFormRef.value.validate()
    inSubmitLoading.value = true
    await request.post('/wms/stock-records/in', {
      partId: stockForm.partId,
      warehouseId: stockForm.warehouseId,
      quantity: stockForm.quantity,
      operator: stockForm.operator,
      remark: stockForm.remark,
    })
    ElMessage.success('入库成功')
    inDialogVisible.value = false
    loadData()
  } catch (e) {
    console.error('入库失败', e)
  } finally {
    inSubmitLoading.value = false
  }
}

// ---------- 出库 ----------
const openOutDialog = (row) => {
  Object.assign(stockForm, defaultStockForm())
  if (row) {
    stockForm.partId = row.partId
    handlePartChange(row.partId)
  }
  outDialogVisible.value = true
}

const handleOutSubmit = async () => {
  try {
    await outFormRef.value.validate()
    outSubmitLoading.value = true
    await request.post('/wms/stock-records/out', {
      partId: stockForm.partId,
      warehouseId: stockForm.warehouseId,
      quantity: stockForm.quantity,
      operator: stockForm.operator,
      remark: stockForm.remark,
    })
    ElMessage.success('出库成功')
    outDialogVisible.value = false
    loadData()
  } catch (e) {
    console.error('出库失败', e)
  } finally {
    outSubmitLoading.value = false
  }
}

// ============ 库存盘点 ============
const checkDialogVisible = ref(false)
const checkSubmitLoading = ref(false)
const checkData = ref([])

const openCheckDialog = async () => {
  checkDialogVisible.value = true
  try {
    const res = await request.get('/wms/stock-records', { params: { page: 1, pageSize: 500 } })
    checkData.value = (res.data?.list || []).map(item => ({
      ...item,
      checkStock: item.stockQuantity,
    }))
  } catch (e) {
    console.error('获取盘点数据失败', e)
    checkData.value = []
  }
}

const handleCheckSubmit = async () => {
  try {
    checkSubmitLoading.value = true
    const checkList = checkData.value
      .filter(item => item.checkStock !== item.stockQuantity)
      .map(item => ({
        partId: item.partId,
        warehouseId: item.warehouseId,
        actualStock: item.checkStock,
      }))
    if (checkList.length === 0) {
      ElMessage.warning('没有需要调整的库存')
      return
    }
    await request.post('/wms/stock-records/check', { list: checkList })
    ElMessage.success('盘点完成')
    checkDialogVisible.value = false
    loadData()
  } catch (e) {
    console.error('盘点失败', e)
  } finally {
    checkSubmitLoading.value = false
  }
}

// ============ 加载数据 ============
async function loadData() {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      pageSize: pagination.pageSize,
      ...queryParams,
    }
    const res = await request.get('/wms/stock-records', { params })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch (e) {
    console.error('获取库存列表失败', e)
  } finally {
    loading.value = false
  }
}

async function loadWarehouses() {
  try {
    const res = await request.get('/wms/warehouses', { params: { page: 1, pageSize: 100 } })
    warehouseList.value = res.data?.list || []
    const whOptions = warehouseList.value.map(w => ({ label: w.name, value: w.id }))
    searchFields[2].options = whOptions
  } catch {
    warehouseList.value = []
  }
}

async function loadParts() {
  try {
    const res = await request.get('/wms/parts', { params: { page: 1, pageSize: 500 } })
    partList.value = res.data?.list || []
  } catch {
    partList.value = []
  }
}

onMounted(() => {
  loadWarehouses()
  loadParts()
  loadData()
})
</script>

<style scoped>
.stock-list {
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.panel {
  background: #fff;
  border-radius: 4px;
  padding: 12px 16px;
}

.text-success {
  color: #67c23a;
  font-weight: 500;
}

.text-danger {
  color: #f56c6c;
  font-weight: bold;
}

:deep(.stock-low) {
  color: #f56c6c;
  font-weight: bold;
}
</style>
