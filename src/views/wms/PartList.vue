<template>
  <div class="part-list">
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
        :show-index="false"
        ref="tableRef"
        :data="tableData"
        :columns="tableColumns"
        :loading="loading"
        :pagination="pagination"
        row-key="id"
        @page-change="handlePageChange"
        @size-change="handleSizeChange"
        @action="handleTableAction">

        <template #header___seq__>
          <span>序号</span>
          <ColumnSettings
            :columns="tableColumns"
            page-path="/wms/parts"
            @change="onColumnConfigChange"
          >
            <template #trigger>
              <el-icon class="seq-settings-btn"><Setting /></el-icon>
            </template>
          </ColumnSettings>
        </template>
      
      </DataTable>
    </div>

    <!-- 新增/编辑弹窗 -->
    <CrudDialog
      v-model="dialogVisible"
      :mode="dialogMode"
      :fields="dialogFields"
      :model-value="formData"
      :saving="submitting"
      @save="handleSave"
      @cancel="dialogVisible = false"
    />
  </div>
</template>

<script setup>
import { SearchForm, DataTable} from '@/components/page-components'
import ColumnSettings from '@/views/components/ColumnSettings.vue'
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Setting } from '@element-plus/icons-vue'
import request from '@/utils/request'

// ============ 数据 ============
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })
const queryParams = reactive({ partNo: '', partName: '', warehouseId: null })

// ============ 仓库列表 ============
const warehouseList = ref([])

// ============ 搜索 ============
const searchFields = [
  { key: 'partNo', label: '配件编码', type: 'input', placeholder: '配件编码' },
  { key: 'partName', label: '配件名称', type: 'input', placeholder: '配件名称' },
  {
    key: 'warehouseId',
    label: '所属仓库',
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


// Column settings
// mergedColumns uses tableColumns directly (plain array)
const onColumnConfigChange = (cols) => { Object.assign(tableColumns, cols) }

const tableColumns = [
  { key: '__seq__', label: '', width: 60, show: true, fixed: 'left', columnType: 'seq' },
  
  { key: 'partNo', label: '配件编码', width: 130 },
  { key: 'partName', label: '配件名称', minWidth: 150 },
  { key: 'spec', label: '规格型号', minWidth: 120, showOverflowTooltip: true },
  { key: 'category', label: '分类', width: 100 },
  { key: 'unit', label: '单位', width: 70, align: 'center' },
  {
    key: 'unitPrice',
    label: '单价',
    width: 100,
    align: 'right',
    columnType: 'currency',
    prefix: '¥',
    precision: 2,
  },
  {
    key: 'safetyStock',
    label: '库存',
    width: 90,
    align: 'center',
    slot: 'stock',
  },
  { key: 'warehouseName', label: '所属仓库', width: 120, showOverflowTooltip: true },
  {
    key: 'actions',
    label: '操作',
    width: 120,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'edit', label: '编辑', type: 'primary', size: 'small', link: true },
      { key: 'delete', label: '删除', type: 'danger', size: 'small', link: true, danger: true },
    ],
  },
]

// 库存低于安全库存高亮
function stockCellClass({ row }) {
  return row.safetyStock !== undefined && row.safetyStock > 0 && row.stock < row.safetyStock
    ? 'stock-low'
    : ''
}

function handleTableAction(action, row) {
  if (action === 'edit') openEdit(row)
  else if (action === 'delete') openDelete(row)
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

// ============ 弹窗表单 ============
const dialogVisible = ref(false)
const dialogMode = ref('create')
const submitting = ref(false)
const editingId = ref(null)

const defaultForm = () => ({
  partNo: '',
  partName: '',
  spec: '',
  category: '',
  unit: '',
  unitCost: 0,
  unitPrice: 0,
  safetyStock: 0,
  stock: 0,
  warehouseId: null,
  remark: '',
})

const formData = reactive(defaultForm())

const dialogFields = [
  { key: 'partNo', label: '配件编码', type: 'input', required: true, placeholder: '请输入配件编码', maxlength: 30, disabled: () => dialogMode.value === 'edit' },
  { key: 'partName', label: '配件名称', type: 'input', required: true, placeholder: '请输入配件名称', maxlength: 100 },
  { key: 'spec', label: '规格型号', type: 'input', placeholder: '规格型号', maxlength: 100 },
  { key: 'category', label: '分类', type: 'input', placeholder: '配件分类' },
  { key: 'unit', label: '单位', type: 'input', placeholder: '如：台、个、罐', maxlength: 20 },
  { key: 'unitPrice', label: '单价', type: 'number', min: 0, precision: 2, placeholder: '0.00' },
  { key: 'safetyStock', label: '安全库存', type: 'number', min: 0, precision: 0 },
  {
    key: 'warehouseId',
    label: '所属仓库',
    type: 'select',
    required: true,
    placeholder: '请选择仓库',
    options: [],
  },
  { key: 'remark', label: '备注', type: 'textarea', placeholder: '备注信息', maxlength: 200 },
]

function openAdd() {
  dialogMode.value = 'create'
  editingId.value = null
  Object.keys(defaultForm()).forEach(k => { formData[k] = defaultForm()[k] })
  dialogVisible.value = true
}

function openEdit(row) {
  dialogMode.value = 'edit'
  editingId.value = row.id
  Object.assign(formData, {
    partNo: row.partNo,
    partName: row.partName,
    spec: row.spec || '',
    category: row.category || '',
    unit: row.unit || '',
    unitCost: row.unitCost || 0,
    unitPrice: row.unitPrice || 0,
    safetyStock: row.safetyStock || 0,
    stock: row.stock || 0,
    warehouseId: row.warehouseId,
    remark: row.remark || '',
  })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm(
      `确定删除配件「${row.partName}」(编码: ${row.partNo})？此操作不可恢复。`,
      '确认删除',
      { type: 'warning' }
    )
    await request.delete(`/wms/parts/${row.id}`)
    ElMessage.success('已删除')
    loadData()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('删除失败')
  }
}

async function handleSave(data) {
  submitting.value = true
  try {
    if (dialogMode.value === 'edit') {
      await request.put(`/wms/parts/${editingId.value}`, data)
      ElMessage.success('编辑成功')
    } else {
      await request.post('/wms/parts', data)
      ElMessage.success('新增成功')
    }
    dialogVisible.value = false
    loadData()
  } catch (e) {
    ElMessage.error(dialogMode.value === 'edit' ? '编辑失败' : '新增失败')
  } finally {
    submitting.value = false
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
    const res = await request.get('/wms/parts', { params })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

async function loadWarehouses() {
  try {
    const res = await request.get('/wms/warehouses', { params: { page: 1, pageSize: 100 } })
    warehouseList.value = res.data?.list || []
    // 更新搜索和表单的仓库选项
    const whOptions = warehouseList.value.map(w => ({ label: w.name, value: w.id }))
    searchFields[2].options = whOptions
    dialogFields.find(f => f.key === 'warehouseId').options = whOptions
  } catch {
    warehouseList.value = []
  }
}

onMounted(() => {
  loadWarehouses()
  loadData()
})
</script>

<style scoped>
.part-list {
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

:deep(.stock-low) {
  color: #f56c6c;
  font-weight: bold;
}

/* seq column toolbar */
.table-header-bar {
  display: flex;
  align-items: center;
  justify-content: center;
}
.seq-settings-btn { cursor: pointer; color: #909399; transition: color 0.2s; }
.seq-settings-btn:hover { color: #409eff; }

</style>