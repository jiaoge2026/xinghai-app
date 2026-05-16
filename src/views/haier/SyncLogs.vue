<template>
  <div class="page-container">
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
        :data="tableData"
        :columns="tableColumns"
        :loading="loading"
        :pagination="pagination"
        row-key="id"
        @page-change="handlePageChange"
        @size-change="handleSizeChange"
      >
        <template #syncType="{ row }">
          {{ syncTypeLabel(row.syncType) }}
        </template>
        <template #status="{ row }">
          <el-tag :type="row.status === 'success' ? 'success' : 'danger'" size="small">
            {{ row.status === 'success' ? '成功' : '失败' }}
          </el-tag>
        </template>
        <template #startTime="{ row }">
          {{ row.startTime ? formatDateTime(row.startTime) : '-' }}
        </template>
        <template #endTime="{ row }">
          {{ row.endTime ? formatDateTime(row.endTime) : '-' }}
        </template>
        <template #duration="{ row }">
          {{ row.duration ? row.duration + 's' : '-' }}
        </template>
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import request from '@/utils/request'
import { SearchForm, DataTable } from '@/components/page-components'

const route = useRoute()
const loading = ref(false)
const tableData = ref([])
let pagination = reactive({ page: 1, pageSize: 20, total: 0 })
let queryParams = reactive({ accountId: null, status: null, dateRange: null })
const accounts = ref([])

// ============ 搜索 ============
const searchFields = [
  {
    key: 'accountId',
    label: '账号',
    type: 'select',
    placeholder: '请选择账号',
    options: [],
  },
  {
    key: 'status',
    label: '结果',
    type: 'select',
    placeholder: '请选择结果',
    options: [
      { label: '成功', value: 'success' },
      { label: '失败', value: 'failed' },
    ],
  },
  {
    key: 'dateRange',
    label: '日期范围',
    type: 'date-range',
    placeholder: ['开始日期', '结束日期'],
    valueFormat: 'YYYY-MM-DD',
  },
]

const syncTypeLabel = (t) => ({ full: '全量', incremental: '增量', manual: '手动' }[t] || t)

function formatDateTime(val) {
  if (!val) return '-'
  const d = new Date(val)
  if (isNaN(d.getTime())) return String(val)
  return (
    d.getFullYear() +
    '-' +
    String(d.getMonth() + 1).padStart(2, '0') +
    '-' +
    String(d.getDate()).padStart(2, '0') +
    ' ' +
    String(d.getHours()).padStart(2, '0') +
    ':' +
    String(d.getMinutes()).padStart(2, '0') +
    ':' +
    String(d.getSeconds()).padStart(2, '0')
  )
}

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

function handlePageChange(page) {
  pagination.page = page
  loadData()
}

function handleSizeChange(size) {
  pagination.pageSize = size
  pagination.page = 1
  loadData()
}

// ============ 表格 ============
const tableColumns = [
  { key: 'accountNo', label: '账号', width: 120 },
  { key: 'syncType', label: '同步类型', width: 100, slot: 'syncType' },
  { key: 'syncCount', label: '同步数量', width: 100, align: 'right' },
  { key: 'status', label: '结果', width: 80, align: 'center', slot: 'status' },
  { key: 'message', label: '详情', minWidth: 200, showOverflowTooltip: true },
  { key: 'startTime', label: '开始时间', width: 160, slot: 'startTime' },
  { key: 'endTime', label: '结束时间', width: 160, slot: 'endTime' },
  { key: 'duration', label: '耗时', width: 80, align: 'right', slot: 'duration' },
]

// ============ 数据加载 ============
const loadAccounts = async () => {
  try {
    const res = await request.get('/haier-sync/accounts', { pageSize: 100 })
    accounts.value = res.data?.list || res.data || []
    const accountField = searchFields.find((f) => f.key === 'accountId')
    if (accountField) {
      accountField.options = accounts.value.map((a) => ({ label: a.accountNo, value: a.id }))
    }
  } catch (e) {
    console.error(e)
  }
}

const loadData = async () => {
  loading.value = true
  try {
    const params = { pageNum: pagination.page, pageSize: pagination.pageSize }
    if (queryParams.accountId) params.accountId = queryParams.accountId
    if (queryParams.status) params.status = queryParams.status
    if (queryParams.dateRange && queryParams.dateRange[0]) params.startDate = queryParams.dateRange[0]
    if (queryParams.dateRange && queryParams.dateRange[1]) params.endDate = queryParams.dateRange[1]
    const res = await request.get('/haier-sync/logs', params)
    tableData.value = res.data?.list || res.data || []
    pagination.total = res.data?.total || 0
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  if (route.query.accountId) queryParams.accountId = route.query.accountId
  loadAccounts()
  loadData()
})
</script>

<style scoped>
.page-container {
  padding: 16px;
}

.panel {
  margin-bottom: 12px;
  background: #fff;
  border-radius: 4px;
}
</style>
