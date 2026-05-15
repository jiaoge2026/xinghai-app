<template>
  <div class="config-list">
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
            page-path="/system/configs"
            @change="onColumnConfigChange"
          >
            <template #trigger>
              <el-icon class="seq-settings-btn"><Setting /></el-icon>
            </template>
          </ColumnSettings>
        </template>
      
      </DataTable>
    </div>

    <CrudDialog
      v-model="dialogVisible"
      :mode="dialogMode"
      :title="dialogTitle"
      :fields="dialogFields"
      :model-value="formData"
      :saving="submitting"
      width="500px"
      @save="handleSave"
      @cancel="dialogVisible = false"
    />
  </div>
</template>

<script setup>
import { SearchForm, DataTable} from '@/components/page-components'
import ColumnSettings from '@/views/components/ColumnSettings.vue'
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Setting } from '@element-plus/icons-vue'
import request from '@/utils/request'

// ============ 数据 ============
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })
const queryParams = reactive({ configKey: '' })

// ============ 搜索 ============
const searchFields = [
  { key: 'configKey', label: '配置项', type: 'input', placeholder: '配置项名称' },
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
const typeMap = { STRING: '', NUMBER: 'success', BOOLEAN: 'warning' }
const typeLabelMap = { STRING: '字符串', NUMBER: '数字', BOOLEAN: '布尔' }


// Column settings
// mergedColumns uses tableColumns directly (plain array)
const onColumnConfigChange = (cols) => { Object.assign(tableColumns, cols) }

const tableColumns = [
  { key: '__seq__', label: '', width: 60, show: true, fixed: 'left', columnType: 'seq' },
  
  { key: 'configKey', label: '配置项', minWidth: 200 },
  { key: 'configValue', label: '配置值', minWidth: 250, showOverflowTooltip: true },
  {
    key: 'configType',
    label: '类型',
    width: 100,
    align: 'center',
    columnType: 'map',
    maps: { STRING: { label: '字符串', type: '' }, NUMBER: { label: '数字', type: 'success' }, BOOLEAN: { label: '布尔', type: 'warning' } },
  },
  { key: 'remark', label: '备注', minWidth: 150, showOverflowTooltip: true },
  { key: 'updatedAt', label: '更新时间', width: 170 },
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
  if (action === 'edit') openEdit(row)
  else if (action === 'delete') openDelete(row)
}

function handlePageChange(page) { pagination.page = page; loadData() }
function handleSizeChange(size) { pagination.pageSize = size; pagination.page = 1; loadData() }

// ============ 弹窗表单 ============
const dialogVisible = ref(false)
const dialogMode = ref('create')
const submitting = ref(false)
const editingId = ref(null)

const dialogTitle = computed(() => dialogMode.value === 'edit' ? '编辑配置' : '新增配置')

const defaultForm = () => ({
  configKey: '',
  configValue: '',
  configType: 'STRING',
  remark: '',
})

const formData = reactive(defaultForm())

const dialogFields = [
  {
    key: 'configKey',
    label: '配置项名',
    type: 'input',
    required: true,
    placeholder: '如：sys.default.password',
    disabled: () => dialogMode.value === 'edit',
  },
  {
    key: 'configValue',
    label: '配置值',
    type: 'textarea',
    required: true,
    placeholder: '配置值',
    rows: 3,
    cols: 2,
  },
  {
    key: 'configType',
    label: '类型',
    type: 'select',
    required: true,
    placeholder: '请选择类型',
    options: [
      { label: '字符串', value: 'STRING' },
      { label: '数字', value: 'NUMBER' },
      { label: '布尔', value: 'BOOLEAN' },
    ],
  },
  {
    key: 'remark',
    label: '备注',
    type: 'input',
    placeholder: '配置说明或用途',
    cols: 2,
  },
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
    configKey: row.configKey,
    configValue: row.configValue,
    configType: row.configType,
    remark: row.remark || '',
  })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除配置「${row.configKey}」？`, '提示', { type: 'warning' })
    await request.delete(`/system/configs/${row.id}`)
    ElMessage.success('删除成功')
    loadData()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('删除失败')
  }
}

async function handleSave(data) {
  submitting.value = true
  try {
    if (dialogMode.value === 'edit') {
      await request.put(`/system/configs/${editingId.value}`, data)
      ElMessage.success('更新成功')
    } else {
      await request.post('/system/configs', data)
      ElMessage.success('新增成功')
    }
    dialogVisible.value = false
    loadData()
  } catch {
    ElMessage.error(dialogMode.value === 'edit' ? '更新失败' : '新增失败')
  } finally {
    submitting.value = false
  }
}

// ============ 加载 ============
async function loadData() {
  loading.value = true
  try {
    const params = { pageNum: pagination.page, pageSize: pagination.pageSize, ...queryParams }
    // 去掉空值
    Object.keys(params).forEach(k => { if (params[k] === null || params[k] === '') delete params[k] })
    const res = await request.get('/system/configs', { params })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>

<style scoped>
.config-list {
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

/* seq column toolbar */
.table-header-bar {
  display: flex;
  align-items: center;
  justify-content: center;
}
.seq-settings-btn { cursor: pointer; color: #909399; transition: color 0.2s; }
.seq-settings-btn:hover { color: #409eff; }

</style>