<template>
  <div class="page-container">
    <!-- 日期选择工具栏 -->
    <div class="report-toolbar">
      <span class="toolbar-label">工单日期范围：</span>
      <el-date-picker
        v-model="dateRange"
        type="daterange"
        range-separator="至"
        start-placeholder="开始日期"
        end-placeholder="结束日期"
        value-format="YYYY-MM-DD"
        style="width:260px"
        @change="handleDateChange"
      />
      <el-button type="primary" @click="loadData" style="margin-left:8px">查询</el-button>
      <el-button @click="handleExport">导出</el-button>
      <el-button @click="handlePrint">打印</el-button>
    </div>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stats-row">
      <el-col :span="6"><div class="stat-card"><div class="stat-value">{{ stats.total }}</div><div class="stat-label">工单总数</div></div></el-col>
      <el-col :span="6"><div class="stat-card"><div class="stat-value">{{ stats.completed }}</div><div class="stat-label">已完成</div></div></el-col>
      <el-col :span="6"><div class="stat-card"><div class="stat-value">{{ stats.inProgress }}</div><div class="stat-label">进行中</div></div></el-col>
      <el-col :span="6"><div class="stat-card"><div class="stat-value">¥{{ stats.totalRevenue?.toLocaleString() || 0 }}</div><div class="stat-label">营收合计</div></div></el-col>
    </el-row>

    <!-- 筛选条件 -->
    <el-form :inline="true" class="filter-form">
      <el-form-item label="状态">
        <el-select v-model="query.status" placeholder="全部" clearable style="width:140px" @change="handleSearch">
          <el-option label="全部" value="" />
          <el-option label="待派单" value="pending" />
          <el-option label="已派单" value="dispatched" />
          <el-option label="进行中" value="in_progress" />
          <el-option label="已完成" value="completed" />
          <el-option label="已取消" value="cancelled" />
        </el-select>
      </el-form-item>
      <el-form-item label="工单类型">
        <el-select v-model="query.workType" placeholder="全部" clearable style="width:120px" @change="handleSearch">
          <el-option label="全部" value="" />
          <el-option label="安装" value="install" />
          <el-option label="维修" value="repair" />
          <el-option label="清洗" value="clean" />
          <el-option label="保养" value="maintain" />
        </el-select>
      </el-form-item>
      <el-form-item label="工程师">
        <el-input v-model="query.engineerName" placeholder="工程师姓名" clearable style="width:130px" @change="handleSearch" />
      </el-form-item>
      <el-form-item><el-button @click="handleFilterReset">重置</el-button></el-form-item>
    </el-form>

    <!-- 表格 -->
    <el-table :data="tableData" stripe v-loading="loading" show-summary :summary-method="getSummaries">
      <el-table-column prop="woNo" label="工单编号" width="160" />
      <el-table-column prop="customerName" label="客户名称" min-width="150" />
      <el-table-column prop="contact" label="联系人" width="100" />
      <el-table-column prop="phone" label="联系电话" width="120" />
      <el-table-column prop="address" label="地址" min-width="150" show-overflow-tooltip />
      <el-table-column prop="workType" label="类型" width="80" align="center">
        <template #default="{row}">{{ workTypeLabel(row.workType) }}</template>
      </el-table-column>
      <el-table-column prop="engineerName" label="工程师" width="100" />
      <el-table-column prop="status" label="状态" width="100" align="center">
        <template #default="{row}"><el-tag :type="statusType(row.status)">{{ statusLabel(row.status) }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="receivedFee" label="收款" width="100" align="right">
        <template #default="{row}">¥{{ (row.receivedFee || 0).toLocaleString() }}</template>
      </el-table-column>
      <el-table-column prop="completeTime" label="完成时间" width="160">
        <template #default="{row}">{{ row.completeTime ? new Date(row.completeTime).toLocaleString() : '-' }}</template>
      </el-table-column>
    </el-table>

    <div class="pagination-wrap">
      <el-pagination
        background
        layout="total, sizes, prev, pager, next"
        :total="total"
        :page-size="query.pageSize"
        :current-page="query.pageNum"
        @size-change="handleSizeChange"
        @current-change="handlePageChange"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import request from '@/utils/request'

const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const dateRange = ref([])
const stats = reactive({ total: 0, completed: 0, inProgress: 0, totalRevenue: 0 })
const query = reactive({ pageNum: 1, pageSize: 20, status: '', workType: '', engineerName: '', startDate: '', endDate: '' })

const workTypeLabel = (t) => ({ install: '安装', repair: '维修', clean: '清洗', maintain: '保养' }[t] || t)
const statusLabel = (s) => ({ pending: '待派单', dispatched: '已派单', in_progress: '进行中', completed: '已完成', cancelled: '已取消' }[s] || s)
const statusType = (s) => ({ pending: 'info', dispatched: 'warning', in_progress: '', completed: 'success', cancelled: 'danger' }[s] || 'info')

const getSummaries = (param) => {
  const { columns, data } = param
  const sums = []
  columns.forEach((column, index) => {
    if (index === 0) { sums[index] = '合计'; return }
    if (column.property === 'receivedFee') {
      const sum = data.reduce((acc, row) => acc + (row.receivedFee || 0), 0)
      sums[index] = `¥${sum.toLocaleString()}`
    } else {
      sums[index] = ''
    }
  })
  return sums
}

const handleDateChange = () => {
  query.startDate = dateRange.value?.[0] || ''
  query.endDate = dateRange.value?.[1] || ''
}

const loadStats = async () => {
  try {
    const params = {}
    if (query.startDate) params.startDate = query.startDate
    if (query.endDate) params.endDate = query.endDate
    const res = await request.get('/v1/fsm/work-orders/stats', params)
    Object.assign(stats, res.data || {})
  } catch (e) { console.error(e) }
}

const loadData = async () => {
  loading.value = true
  try {
    const params = { pageNum: query.pageNum, pageSize: query.pageSize }
    if (query.status) params.status = query.status
    if (query.workType) params.workType = query.workType
    if (query.engineerName) params.engineerName = query.engineerName
    if (query.startDate) params.startDate = query.startDate
    if (query.endDate) params.endDate = query.endDate
    const res = await request.get('/v1/fsm/work-orders', params)
    tableData.value = res.data?.list || res.data || []
    total.value = res.data?.total || 0
    loadStats()
  } catch (e) { console.error(e) }
  finally { loading.value = false }
}

const handleSearch = () => { query.pageNum = 1; loadData() }
const handleFilterReset = () => { query.status = ''; query.workType = ''; query.engineerName = ''; handleSearch() }
const handleSizeChange = (s) => { query.pageSize = s; loadData() }
const handlePageChange = (p) => { query.pageNum = p; loadData() }

const handleExport = () => { ElMessage.info('导出功能开发中') }
const handlePrint = () => { window.print() }

onMounted(loadData)
</script>

<style scoped>
.page-container { padding: 16px; }
.report-toolbar { display: flex; align-items: center; margin-bottom: 16px; background: #fff; padding: 12px 16px; border-radius: 8px; box-shadow: 0 1px 4px rgba(0,0,0,.06); }
.toolbar-label { font-size: 14px; font-weight: 600; color: #333; margin-right: 8px; white-space: nowrap; }
.stats-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; padding: 20px; text-align: center; box-shadow: 0 1px 4px rgba(0,0,0,.08); }
.stat-value { font-size: 24px; font-weight: 700; color: #409EFF; }
.stat-label { font-size: 13px; color: #666; margin-top: 6px; }
.filter-form { margin-bottom: 12px; }
.pagination-wrap { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
