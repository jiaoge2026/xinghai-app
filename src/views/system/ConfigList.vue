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
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">
        <span style="font-size:13px;color:#606266">共 {{ pagination.total }} 条配置</span>
        <el-button type="primary" size="small" @click="openAdd">
          <el-icon style="margin-right:4px"><Plus /></el-icon>新增配置
        </el-button>
      </div>
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

        <template #configValue="{ row }">
          <div style="display:flex;align-items:center;gap:6px">
            <span style="font-family:monospace;font-size:12px;color:#409eff;max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap" :title="row.configValue">
              {{ row.configValue }}
            </span>
            <el-tag v-if="row.configType === 'BOOLEAN'" :type="row.configValue === 'true' || row.configValue === '1' ? 'success' : 'danger'" size="small">
              {{ row.configValue === 'true' || row.configValue === '1' ? 'true' : 'false' }}
            </el-tag>
            <el-tag v-if="row.configType === 'NUMBER'" type="info" size="small">number</el-tag>
          </div>
        </template>

        <template #configType="{ row }">
          <el-tag :type="typeTagMap[row.configType] || 'info'" size="small">{{ typeLabelMap[row.configType] || row.configType }}</el-tag>
        </template>

        <template #header___seq__>
          <span>序号</span>
          <ColumnSettings :columns="tableColumns" page-path="/system/configs" @change="onColumnConfigChange">
            <template #trigger>
              <el-icon class="seq-settings-btn"><Setting /></el-icon>
            </template>
          </ColumnSettings>
        </template>

      </DataTable>
    </div>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="580px" destroy-on-close>
      <el-form :model="formData" :rules="formRules" ref="formRef" label-width="100px">
        <el-form-item label="配置分组" prop="configGroup">
          <el-select v-model="formData.configGroup" placeholder="选择分组" style="width:100%">
            <el-option v-for="g in groupOptions" :key="g" :label="g" :value="g" />
          </el-select>
        </el-form-item>
        <el-form-item label="配置项名" prop="configKey">
          <el-input v-model="formData.configKey" :disabled="dialogMode === 'edit'" placeholder="如：sys.default.timeout" />
        </el-form-item>
        <el-form-item label="配置类型" prop="configType">
          <el-radio-group v-model="formData.configType">
            <el-radio value="STRING">字符串</el-radio>
            <el-radio value="NUMBER">数字</el-radio>
            <el-radio value="BOOLEAN">布尔</el-radio>
            <el-radio value="JSON">JSON</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="配置值" prop="configValue">
          <el-input v-if="formData.configType === 'BOOLEAN'" v-model="formData.configValue" placeholder="输入 true 或 false">
            <template #append>
              <el-button @click="formData.configValue = formData.configValue === 'true' ? 'false' : 'true'">
                {{ formData.configValue === 'true' ? '设为false' : '设为true' }}
              </el-button>
            </template>
          </el-input>
          <el-input v-else-if="formData.configType === 'JSON'" v-model="formData.configValue" type="textarea" :rows="4" placeholder='{"key": "value"}' style="font-family:monospace" />
          <el-input v-else-if="formData.configType === 'NUMBER'" v-model="formData.configValue" placeholder="数字，如：30000" />
          <el-input v-else v-model="formData.configValue" type="textarea" :rows="2" placeholder="配置值" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="formData.description" type="textarea" :rows="2" placeholder="配置项用途说明" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="formData.remark" placeholder="补充说明" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSave">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { SearchForm, DataTable } from '@/components/page-components'
import ColumnSettings from '@/views/components/ColumnSettings.vue'
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus, Setting, DocumentCopy } from '@element-plus/icons-vue'
import request from '@/utils/request'

const typeTagMap = { STRING: '', NUMBER: 'success', BOOLEAN: 'warning', JSON: 'info' }
const typeLabelMap = { STRING: '字符串', NUMBER: '数字', BOOLEAN: '布尔', JSON: 'JSON' }
const groupOptions = ['系统', '业务', '财务', 'FSM', 'WMS', 'CRM', '安全', '通知', '自定义']

// ============ 数据 ============
const loading = ref(false)
const tableData = ref([])
let pagination = reactive({ page: 1, pageSize: 20, total: 0 })
let queryParams = reactive({ keyword: '' })

// ============ 搜索 ============
const searchFields = [
  { key: 'keyword', label: '配置项', type: 'input', placeholder: '配置项名/配置值/描述' },
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
const onColumnConfigChange = (cols) => { Object.assign(tableColumns, cols) }

const tableColumns = [
  { key: '__seq__', label: '', width: 60, show: true, fixed: 'left', columnType: 'seq' },
  { key: 'configGroup', label: '分组', width: 100, align: 'center' },
  { key: 'configKey', label: '配置项名', minWidth: 200 },
  { key: 'configValue', label: '配置值', minWidth: 240 },
  { key: 'configType', label: '类型', width: 90, align: 'center' },
  { key: 'description', label: '描述', minWidth: 150, showOverflowTooltip: true },
  { key: 'remark', label: '备注', minWidth: 120, showOverflowTooltip: true },
  {
    key: 'actions',
    label: '操作',
    width: 200,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'copy', label: '复制', type: 'primary', size: 'small', link: true },
      { key: 'edit', label: '编辑', type: 'primary', size: 'small', link: true },
      { key: 'delete', label: '删除', type: 'danger', size: 'small', link: true, danger: true },
    ],
  },
]

function handleTableAction(action, row) {
  if (action === 'edit') openEdit(row)
  else if (action === 'delete') openDelete(row)
  else if (action === 'copy') copyValue(row)
}

function handlePageChange(page) { pagination.page = page; loadData() }
function handleSizeChange(size) { pagination.pageSize = size; pagination.page = 1; loadData() }

// ============ 复制配置值 ============
async function copyValue(row) {
  try {
    await navigator.clipboard.writeText(row.configValue)
    ElMessage.success(`「${row.configKey}」的值已复制到剪贴板`)
  } catch {
    ElMessage.error('复制失败，请手动复制')
  }
}

// ============ 弹窗表单 ============
const dialogVisible = ref(false)
const dialogMode = ref('create')
const submitting = ref(false)
const editingId = ref(null)
const formRef = ref(null)

const dialogTitle = computed(() => dialogMode.value === 'edit' ? '编辑配置' : '新增配置')

const defaultForm = () => ({
  configGroup: '系统',
  configKey: '',
  configValue: '',
  configType: 'STRING',
  description: '',
  remark: '',
})

let formData = reactive(defaultForm())

const formRules = {
  configKey: [{ required: true, message: '请输入配置项名', trigger: 'blur' }],
  configValue: [{ required: true, message: '请输入配置值', trigger: 'blur' }],
  configType: [{ required: true, message: '请选择类型', trigger: 'change' }],
}

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
    configGroup: row.configGroup || '系统',
    configKey: row.configKey,
    configValue: row.configValue,
    configType: row.configType || 'STRING',
    description: row.description || '',
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

async function handleSave() {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (dialogMode.value === 'edit') {
      await request.put(`/system/configs/${editingId.value}`, { ...formData })
      ElMessage.success('更新成功')
    } else {
      await request.post('/system/configs', { ...formData })
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
.seq-settings-btn { cursor: pointer; color: #909399; transition: color 0.2s; }
.seq-settings-btn:hover { color: #409eff; }
</style>
