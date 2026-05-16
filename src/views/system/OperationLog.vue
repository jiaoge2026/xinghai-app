<template>
  <div class="operation-log">
    <!-- 搜索栏 -->
    <div class="search-bar">
      <el-form :inline="true" :model="queryParams" size="small">
        <el-form-item label="用户名">
          <el-input v-model="queryParams.username" placeholder="用户名" clearable style="width:140px" />
        </el-form-item>
        <el-form-item label="模块">
          <el-input v-model="queryParams.module" placeholder="模块" clearable style="width:140px" />
        </el-form-item>
        <el-form-item label="开始日期">
          <el-date-picker v-model="queryParams.startDate" type="date" placeholder="选择日期"
            value-format="YYYY-MM-DD" style="width:150px" />
        </el-form-item>
        <el-form-item label="结束日期">
          <el-date-picker v-model="queryParams.endDate" type="date" placeholder="选择日期"
            value-format="YYYY-MM-DD" style="width:150px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
          <el-button type="success" @click="handleExport" :loading="exporting">导出CSV</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 表格 -->
    <el-table :data="tableData" border stripe size="small" v-loading="loading" max-height="520">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="username" label="用户名" width="100" />
      <el-table-column prop="module" label="模块" width="120" />
      <el-table-column prop="operation" label="操作" width="150" />
      <el-table-column prop="method" label="方法" width="150" show-overflow-tooltip />
      <el-table-column prop="requestUrl" label="请求URL" min-width="200" show-overflow-tooltip />
      <el-table-column prop="requestMethod" label="方式" width="80" align="center">
        <template #default="{row}">
          <el-tag :type="methodTag(row.requestMethod)" size="small">{{ row.requestMethod }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="ipAddress" label="IP地址" width="140" />
      <el-table-column prop="executionTimeMs" label="耗时ms" width="90" align="center" />
      <el-table-column prop="responseCode" label="状态" width="70" align="center">
        <template #default="{row}">
          <span :class="(row.responseCode === 0 || row.responseCode === 200) ? 'text-success' : 'text-danger'">
            {{ row.responseCode }}
          </span>
        </template>
      </el-table-column>
      <el-table-column prop="createdAt" label="时间" width="165" />
      <el-table-column label="操作" width="80" align="center">
        <template #default="{row}">
          <el-button link type="primary" size="small" @click="showDetail(row)">详情</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div class="pagination">
      <el-pagination
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.pageSize"
        :page-sizes="[10, 20, 50, 100]"
        :total="pagination.total"
        layout="total, sizes, prev, pager, next"
        @size-change="loadData"
        @current-change="loadData"
      />
    </div>

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailVisible" title="日志详情" width="700px" destroy-on-close>
      <el-descriptions :column="2" border size="small" v-if="currentLog">
        <el-descriptions-item label="ID">{{ currentLog.id }}</el-descriptions-item>
        <el-descriptions-item label="用户名">{{ currentLog.username }}</el-descriptions-item>
        <el-descriptions-item label="模块" :span="2">{{ currentLog.module }}</el-descriptions-item>
        <el-descriptions-item label="操作" :span="2">{{ currentLog.operation }}</el-descriptions-item>
        <el-descriptions-item label="方法" :span="2">{{ currentLog.method }}</el-descriptions-item>
        <el-descriptions-item label="URL" :span="2">{{ currentLog.requestUrl }}</el-descriptions-item>
        <el-descriptions-item label="请求方式">{{ currentLog.requestMethod }}</el-descriptions-item>
        <el-descriptions-item label="IP地址">{{ currentLog.ipAddress }}</el-descriptions-item>
        <el-descriptions-item label="耗时">{{ currentLog.executionTimeMs }} ms</el-descriptions-item>
        <el-descriptions-item label="状态码">{{ currentLog.responseCode }}</el-descriptions-item>
        <el-descriptions-item label="时间" :span="2">{{ currentLog.createdAt }}</el-descriptions-item>
        <el-descriptions-item label="请求参数" :span="2">
          <pre class="param-pre">{{ formatJson(currentLog.requestParams) }}</pre>
        </el-descriptions-item>
        <el-descriptions-item label="响应数据" :span="2">
          <pre class="param-pre">{{ currentLog.responseData }}</pre>
        </el-descriptions-item>
        <el-descriptions-item label="异常信息" :span="2">
          <span class="text-danger">{{ currentLog.errorMessage || '-' }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="User-Agent" :span="2">
          <span class="text-muted" style="font-size:11px">{{ currentLog.userAgent }}</span>
        </el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import request from '@/utils/request'

const loading = ref(false)
const tableData = ref([])
let pagination = reactive({ page: 1, pageSize: 20, total: 0 })
let queryParams = reactive({ username: '', module: '', startDate: '', endDate: '' })
const exporting = ref(false)
const detailVisible = ref(false)
const currentLog = ref(null)

async function loadData() {
  loading.value = true
  try {
    const params = { page: pagination.page, pageSize: pagination.pageSize, ...queryParams }
    Object.keys(params).forEach(k => { if (params[k] === null || params[k] === '') delete params[k] })
    const res = await request.get('/system/operation-logs/page', { params })
    tableData.value = res.data?.records || []
    pagination.total = res.data?.total || 0
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

function handleQuery() {
  pagination.page = 1
  loadData()
}

function handleReset() {
  queryParams.username = ''
  queryParams.module = ''
  queryParams.startDate = ''
  queryParams.endDate = ''
  handleQuery()
}

async function handleExport() {
  exporting.value = true
  try {
    const params = { ...queryParams }
    const res = await request.get('/system/operation-logs/export', { params, responseType: 'blob' })
    const blob = new Blob([res], { type: 'text/csv;charset=GBK' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = '操作日志.csv'
    a.click()
    URL.revokeObjectURL(url)
    ElMessage.success('导出成功')
  } catch (e) {
    ElMessage.error('导出失败')
  } finally {
    exporting.value = false
  }
}

function methodTag(method) {
  const map = { GET: '', POST: 'success', PUT: 'warning', DELETE: 'danger', PATCH: 'info' }
  return map[method] || ''
}

function formatJson(str) {
  if (!str) return '-'
  try { return JSON.stringify(JSON.parse(str), null, 2) } catch { return str }
}

function showDetail(row) {
  currentLog.value = row
  detailVisible.value = true
}

onMounted(() => loadData())
</script>

<style scoped>
.operation-log { padding: 16px; }
.search-bar { margin-bottom: 12px; }
.pagination { margin-top: 12px; display: flex; justify-content: flex-end; }
.text-success { color: #67c23a; }
.text-danger { color: #f56c6c; }
.text-muted { color: #999; }
.param-pre {
  max-height: 150px; overflow: auto; font-size: 11px;
  background: #f5f5f5; padding: 6px; border-radius: 4px; margin: 0;
  white-space: pre-wrap; word-break: break-all;
}
</style>
