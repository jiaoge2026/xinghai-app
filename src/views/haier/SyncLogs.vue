<template>
  <div class="page-container">
    <el-form :inline="true" :model="query" class="search-form">
      <el-form-item><el-select v-model="query.accountId" placeholder="账号" clearable style="width:160px"><el-option v-for="a in accounts" :key="a.id" :label="a.accountNo" :value="a.id" /></el-select></el-form-item>
      <el-form-item>
        <el-select v-model="query.status" placeholder="结果" clearable style="width:120px">
          <el-option label="成功" value="success" />
          <el-option label="失败" value="failed" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" value-format="YYYY-MM-DD" style="width:240px" @change="onDateChange" />
      </el-form-item>
      <el-form-item><el-button type="primary" @click="handleSearch">搜索</el-button><el-button @click="handleReset">重置</el-button></el-form-item>
    </el-form>

    <el-table :data="tableData" stripe v-loading="loading">
      <el-table-column prop="accountNo" label="账号" width="120" />
      <el-table-column prop="syncType" label="同步类型" width="100">
        <template #default="{row}">{{ syncTypeLabel(row.syncType) }}</template>
      </el-table-column>
      <el-table-column prop="syncCount" label="同步数量" width="100" align="right" />
      <el-table-column prop="status" label="结果" width="80" align="center">
        <template #default="{row}">
          <el-tag :type="row.status === 'success' ? 'success' : 'danger'">{{ row.status === 'success' ? '成功' : '失败' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="message" label="详情" min-width="200" show-overflow-tooltip />
      <el-table-column prop="startTime" label="开始时间" width="160">
        <template #default="{row}">{{ row.startTime ? new Date(row.startTime).toLocaleString() : '-' }}</template>
      </el-table-column>
      <el-table-column prop="endTime" label="结束时间" width="160">
        <template #default="{row}">{{ row.endTime ? new Date(row.endTime).toLocaleString() : '-' }}</template>
      </el-table-column>
      <el-table-column prop="duration" label="耗时" width="80" align="right">
        <template #default="{row}">{{ row.duration ? row.duration + 's' : '-' }}</template>
      </el-table-column>
    </el-table>

    <div class="pagination-wrap">
      <el-pagination background layout="total, sizes, prev, pager, next" :total="total" :page-size="query.pageSize" :current-page="query.pageNum" @size-change="handleSizeChange" @current-change="handlePageChange" />
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import request from '@/utils/request'

const route = useRoute()
const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const accounts = ref([])
const query = reactive({ pageNum: 1, pageSize: 20, accountId: '', status: '', startDate: '', endDate: '' })
const dateRange = ref([])

const syncTypeLabel = (t) => ({ full: '全量', incremental: '增量', manual: '手动' }[t] || t)

const onDateChange = () => {
  query.startDate = dateRange.value?.[0] || ''
  query.endDate = dateRange.value?.[1] || ''
}

const loadAccounts = async () => {
  try {
    const res = await request.get('/v1/haier-sync/accounts', { pageSize: 100 })
    accounts.value = res.data?.list || res.data || []
  } catch (e) { console.error(e) }
}

const loadData = async () => {
  loading.value = true
  try {
    const params = { pageNum: query.pageNum, pageSize: query.pageSize }
    if (query.accountId) params.accountId = query.accountId
    if (query.status) params.status = query.status
    if (query.startDate) params.startDate = query.startDate
    if (query.endDate) params.endDate = query.endDate
    const res = await request.get('/v1/haier-sync/logs', params)
    tableData.value = res.data?.list || res.data || []
    total.value = res.data?.total || 0
  } catch (e) { console.error(e) }
  finally { loading.value = false }
}

const handleSearch = () => { query.pageNum = 1; loadData() }
const handleReset = () => { query.accountId = ''; query.status = ''; dateRange.value = []; query.startDate = ''; query.endDate = ''; handleSearch() }
const handleSizeChange = (s) => { query.pageSize = s; loadData() }
const handlePageChange = (p) => { query.pageNum = p; loadData() }

onMounted(() => {
  if (route.query.accountId) query.accountId = route.query.accountId
  loadAccounts()
  loadData()
})
</script>

<style scoped>
.page-container { padding: 16px; }
.search-form { margin-bottom: 12px; }
.pagination-wrap { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
