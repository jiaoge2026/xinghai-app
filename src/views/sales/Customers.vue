<template>
  <div class="customer-list">
    <PageHeader title="工程客户" subtitle="客户档案管理">
      <template #actions>
        <el-button type="primary" @click="openAdd">
          <el-icon><Plus /></el-icon> 新建客户
        </el-button>
      </template>
    </PageHeader>

    <!-- 搜索区 -->
    <div class="panel">
      <SearchForm
        :fields="searchFields"
        v-model="queryParams"
        @search="handleSearch"
        @reset="handleReset"
      />
    </div>

    <!-- 表格 -->
    <div class="panel">
      <DataTable
        :show-index="false"
        ref="tableRef"
        :data="tableData"
        :columns="tableColumns"
        :loading="loading"
        :pagination="pagination"
        row-key="id"
        :show-pagination="true"
        @page-change="handlePageChange"
        @size-change="handleSizeChange"
        @action="handleTableAction">

        <template #header___seq__>
          <span>序号</span>
          <ColumnSettings
            :columns="tableColumns"
            page-path="/sales/customers"
            @change="onColumnConfigChange"
          >
            <template #trigger>
              <el-icon class="seq-settings-btn"><Setting /></el-icon>
            </template>
          </ColumnSettings>
        </template>
      
      </DataTable>
    </div>

    <!-- 新建/编辑弹窗 -->
    <CrudDialog
      v-model="dialogVisible"
      :mode="dialogMode"
      :fields="dialogFields"
      :model-value="formData"
      :saving="submitting"
      title=""
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
const queryParams = reactive({ keyword: '' })

// ============ 搜索 ============
const searchFields = [
  {
    key: 'keyword',
    label: '关键词',
    type: 'input',
    placeholder: '客户名称/联系人/电话',
    defaultValue: '',
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
  
  { key: 'customerName', label: '客户名称', minWidth: 150, sortable: true },
  { key: 'industry', label: '行业', width: 100 },
  { key: 'contactName', label: '联系人', width: 100 },
  { key: 'contactPhone', label: '电话', width: 130 },
  {
    key: 'status',
    label: '状态',
    width: 90,
    align: 'center',
    columnType: 'status',
    statusMap: { 1: { label: '正常', type: 'success' }, 0: { label: '禁用', type: 'danger' } },
  },
  { key: 'createTime', label: '创建时间', width: 170, columnType: 'datetime' },
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

function handleTableAction(action, row) {
  if (action === 'edit') handleEdit(row)
  else if (action === 'delete') handleDelete(row)
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
const dialogMode = ref('create') // 'create' | 'edit' | 'view'
const submitting = ref(false)
const editingId = ref(null)

const defaultForm = () => ({
  customerName: '',
  industry: '',
  contactName: '',
  contactPhone: '',
  contactEmail: '',
  address: '',
  status: 1,
})

const formData = reactive(defaultForm())

const dialogFields = [
  { key: 'customerName', label: '客户名称', type: 'input', required: true, placeholder: '请输入客户名称', cols: 2 },
  { key: 'industry', label: '行业', type: 'select', placeholder: '请选择行业', options: [
    { label: '酒店', value: '酒店' },
    { label: '学校', value: '学校' },
    { label: '医院', value: '医院' },
    { label: '工厂', value: '工厂' },
    { label: '楼宇', value: '楼宇' },
    { label: '政府', value: '政府' },
    { label: '其他', value: '其他' },
  ], cols: 2 },
  { key: 'contactName', label: '联系人', type: 'input', required: true, placeholder: '请输入联系人', cols: 2 },
  { key: 'contactPhone', label: '电话', type: 'input', required: true, placeholder: '请输入电话', cols: 2 },
  { key: 'contactEmail', label: '邮箱', type: 'input', placeholder: '请输入邮箱', cols: 2 },
  { key: 'address', label: '地址', type: 'textarea', placeholder: '请输入详细地址', cols: 2 },
  {
    key: 'status',
    label: '状态',
    type: 'select',
    required: true,
    defaultValue: 1,
    options: [
      { label: '正常', value: 1 },
      { label: '禁用', value: 0 },
    ],
    cols: 2,
  },
]

function openAdd() {
  dialogMode.value = 'create'
  editingId.value = null
  Object.keys(defaultForm()).forEach(k => { formData[k] = defaultForm()[k] })
  dialogVisible.value = true
}

function handleEdit(row) {
  dialogMode.value = 'edit'
  editingId.value = row.id
  Object.assign(formData, { ...row })
  dialogVisible.value = true
}

async function handleSave(data) {
  submitting.value = true
  try {
    if (dialogMode.value === 'edit') {
      await request.put(`/sales/customer/${editingId.value}`, data)
      ElMessage.success('编辑成功')
    } else {
      await request.post('/sales/customer', data)
      ElMessage.success('新建成功')
    }
    dialogVisible.value = false
    loadData()
  } catch (e) {
    ElMessage.error(dialogMode.value === 'edit' ? '编辑失败' : '新建失败')
  } finally {
    submitting.value = false
  }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除客户「${row.customerName}」？`, '确认删除', { type: 'warning' })
    await request.delete(`/sales/customer/${row.id}`)
    ElMessage.success('已删除')
    loadData()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('删除失败')
  }
}

// ============ 加载数据 ============
async function loadData() {
  loading.value = true
  try {
    const params = {
      pageNum: pagination.page,
      pageSize: pagination.pageSize,
      ...queryParams,
    }
    const res = await request.get('/sales/customer/page', { params })
    tableData.value = res.data?.records || []
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
.customer-list {
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