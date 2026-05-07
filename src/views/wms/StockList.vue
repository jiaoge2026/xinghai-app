<template>
  <div class="stock-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>库存台账</span>
          <div class="header-actions">
            <el-button type="success" @click="openInDialog">入库</el-button>
            <el-button type="warning" @click="openOutDialog">出库</el-button>
            <el-button type="primary" @click="openCheckDialog">库存盘点</el-button>
          </div>
        </div>
      </template>

      <!-- 搜索筛选区 -->
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="配件编码">
          <el-input v-model="searchForm.partCode" placeholder="请输入配件编码" clearable style="width: 140px" />
        </el-form-item>
        <el-form-item label="配件名称">
          <el-input v-model="searchForm.partName" placeholder="请输入配件名称" clearable style="width: 140px" />
        </el-form-item>
        <el-form-item label="仓库">
          <el-select v-model="searchForm.warehouseId" placeholder="请选择仓库" clearable style="width: 150px">
            <el-option
              v-for="wh in warehouseList"
              :key="wh.id"
              :label="wh.name"
              :value="wh.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 表格区 -->
      <el-table v-loading="loading" :data="tableData" stripe style="width: 100%">
        <el-table-column prop="partCode" label="配件编码" width="120" />
        <el-table-column prop="partName" label="配件名称" min-width="150" show-overflow-tooltip />
        <el-table-column prop="warehouseName" label="仓库" width="120" show-overflow-tooltip />
        <el-table-column prop="inQuantity" label="入库数量" width="100" align="right">
          <template #default="{ row }">
            <span class="text-success">+{{ row.inQuantity }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="outQuantity" label="出库数量" width="100" align="right">
          <template #default="{ row }">
            <span class="text-warning">-{{ row.outQuantity }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="stockQuantity" label="当前库存" width="100" align="center">
          <template #default="{ row }">
            <span :class="{ 'stock-low': row.stockQuantity < row.minStock }">{{ row.stockQuantity }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="minStock" label="最低库存" width="100" align="center" />
        <el-table-column prop="lastInTime" label="最后入库时间" width="170">
          <template #default="{ row }">
            {{ row.lastInTime || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="lastOutTime" label="最后出库时间" width="170">
          <template #default="{ row }">
            {{ row.lastOutTime || '-' }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openInDialog(row)">入库</el-button>
            <el-button link type="warning" @click="openOutDialog(row)">出库</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <el-pagination
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.pageSize"
        :total="pagination.total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        style="margin-top: 16px; justify-content: flex-end;"
        @size-change="fetchData"
        @current-change="fetchData"
      />

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
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import request from '@/utils/request'
import { ElMessage } from 'element-plus'

// ---------- 仓库列表 ----------
const warehouseList = ref([])

// ---------- 配件列表 ----------
const partList = ref([])

// ---------- 表格数据 ----------
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 10, total: 0 })

// ---------- 搜索表单 ----------
const searchForm = reactive({
  partCode: '',
  partName: '',
  warehouseId: null
})

// ---------- 入库 ----------
const inDialogVisible = ref(false)
const inSubmitLoading = ref(false)
const inFormRef = ref(null)

// ---------- 出库 ----------
const outDialogVisible = ref(false)
const outSubmitLoading = ref(false)
const outFormRef = ref(null)

// ---------- 库存盘点 ----------
const checkDialogVisible = ref(false)
const checkSubmitLoading = ref(false)
const checkData = ref([])

// ---------- 库存表单 ----------
const defaultStockForm = () => ({
  partId: null,
  partCode: '',
  partName: '',
  currentStock: 0,
  warehouseId: null,
  quantity: 1,
  operator: '',
  remark: ''
})

const stockForm = reactive(defaultStockForm())

const stockFormRules = {
  partId: [{ required: true, message: '请选择配件', trigger: 'change' }],
  warehouseId: [{ required: true, message: '请选择仓库', trigger: 'change' }],
  quantity: [{ required: true, message: '请输入数量', trigger: 'blur' }],
  operator: [{ required: true, message: '请输入操作人', trigger: 'blur' }]
}

// ---------- 生命周期 ----------
onMounted(() => {
  fetchWarehouseList()
  fetchPartList()
  fetchData()
})

// ---------- 方法 ----------
const fetchWarehouseList = async () => {
  try {
    const res = await request.get('/wms/warehouse/list', { params: { page: 1, pageSize: 100 } })
    warehouseList.value = res.data?.list || []
  } catch (e) {
    console.error('获取仓库列表失败', e)
    warehouseList.value = []
  }
}

const fetchPartList = async () => {
  try {
    const res = await request.get('/wms/part/list', { params: { page: 1, pageSize: 500 } })
    partList.value = res.data?.list || []
  } catch (e) {
    console.error('获取配件列表失败', e)
    partList.value = []
  }
}

const fetchData = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      pageSize: pagination.pageSize,
      ...searchForm
    }
    const res = await request.get('/wms/stock/page', { params })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch (e) {
    console.error('获取库存列表失败', e)
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  pagination.page = 1
  fetchData()
}

const handleReset = () => {
  searchForm.partCode = ''
  searchForm.partName = ''
  searchForm.warehouseId = null
  pagination.page = 1
  fetchData()
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
    await request.post('/wms/stock/in', {
      partId: stockForm.partId,
      warehouseId: stockForm.warehouseId,
      quantity: stockForm.quantity,
      operator: stockForm.operator,
      remark: stockForm.remark
    })
    ElMessage.success('入库成功')
    inDialogVisible.value = false
    fetchData()
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
    await request.post('/wms/stock/out', {
      partId: stockForm.partId,
      warehouseId: stockForm.warehouseId,
      quantity: stockForm.quantity,
      operator: stockForm.operator,
      remark: stockForm.remark
    })
    ElMessage.success('出库成功')
    outDialogVisible.value = false
    fetchData()
  } catch (e) {
    console.error('出库失败', e)
  } finally {
    outSubmitLoading.value = false
  }
}

// ---------- 库存盘点 ----------
const openCheckDialog = async () => {
  checkDialogVisible.value = true
  try {
    const res = await request.get('/wms/stock/page', { params: { page: 1, pageSize: 500 } })
    checkData.value = (res.data?.list || []).map(item => ({
      ...item,
      checkStock: item.stockQuantity
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
        actualStock: item.checkStock
      }))
    if (checkList.length === 0) {
      ElMessage.warning('没有需要调整的库存')
      return
    }
    await request.post('/wms/stock/check', { list: checkList })
    ElMessage.success('盘点完成')
    checkDialogVisible.value = false
    fetchData()
  } catch (e) {
    console.error('盘点失败', e)
  } finally {
    checkSubmitLoading.value = false
  }
}
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.header-actions { display: flex; gap: 8px; }
.search-form { margin-bottom: 16px; }
.stock-low { color: #f56c6c; font-weight: bold; }
.text-success { color: #67c23a; font-weight: 500; }
.text-warning { color: #e6a23c; font-weight: 500; }
.text-danger { color: #f56c6c; font-weight: bold; }
</style>
