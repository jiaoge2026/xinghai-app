<template>
  <div class="log-container">
    <!-- 统计卡片 -->
    <el-row :gutter="12" class="stats-row">
      <el-col :span="6">
        <div class="stat-card stat-total">
          <div class="stat-value">{{ stats.total }}</div>
          <div class="stat-label">总日志</div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-error">
          <div class="stat-value">{{ stats.error }}</div>
          <div class="stat-label">错误</div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-warning">
          <div class="stat-value">{{ stats.warning }}</div>
          <div class="stat-label">警告</div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-today">
          <div class="stat-value">{{ stats.today }}</div>
          <div class="stat-label">今日新增</div>
        </div>
      </el-col>
    </el-row>

    <!-- 搜索栏 -->
    <el-form :inline="true" class="search-form">
      <el-form-item label="级别">
        <el-select v-model="searchForm.level" placeholder="全部" clearable style="width:100px">
          <el-option label="全部" value="all" />
          <el-option label="error" value="error" />
          <el-option label="warning" value="warning" />
          <el-option label="info" value="info" />
        </el-select>
      </el-form-item>
      <el-form-item label="关键词">
        <el-input v-model="searchForm.keyword" placeholder="消息/URL/堆栈" clearable style="width:160px" />
      </el-form-item>
      <el-form-item label="日期">
        <el-date-picker v-model="searchForm.dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="YYYY-MM-DD" style="width:240px" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="loadData">查询</el-button>
        <el-button @click="resetSearch">重置</el-button>
      </el-form-item>
      <el-form-item style="margin-left:auto">
        <el-button type="danger" @click="clearLogs">清空日志</el-button>
      </el-form-item>
    </el-form>

    <!-- 表格 -->
    <el-table :data="tableData" stripe v-loading="loading" class="log-table">
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="level" label="级别" width="90">
        <template #default="{ row }">
          <el-tag :type="row.level === 'error' ? 'danger' : row.level === 'warning' ? 'warning' : 'info'" size="small">
            {{ row.level }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="message" label="消息" min-width="300" show-overflow-tooltip />
      <el-table-column prop="url" label="URL" min-width="180" show-overflow-tooltip />
      <el-table-column prop="user_id" label="用户ID" width="100" />
      <el-table-column prop="created_at" label="时间" width="170" />
      <el-table-column label="操作" width="80" fixed="right">
        <template #default="{ row }">
          <el-button link type="primary" @click="showDetail(row)">详情</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div class="pagination-wrap">
      <el-pagination
        v-model:current-page="pagination.current"
        v-model:page-size="pagination.size"
        :page-sizes="[20, 50, 100, 200]"
        :total="pagination.total"
        layout="total, sizes, prev, pager, next"
        @size-change="loadData"
        @current-change="loadData"
      />
    </div>

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailVisible" title="日志详情" width="700px" destroy-on-close>
      <div v-if="detail" class="detail-content">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="ID">{{ detail.id }}</el-descriptions-item>
          <el-descriptions-item label="级别">
            <el-tag :type="detail.level === 'error' ? 'danger' : detail.level === 'warning' ? 'warning' : 'info'" size="small">{{ detail.level }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="用户ID">{{ detail.user_id || '-' }}</el-descriptions-item>
          <el-descriptions-item label="时间">{{ detail.created_at }}</el-descriptions-item>
          <el-descriptions-item label="URL" :span="2">{{ detail.url }}</el-descriptions-item>
          <el-descriptions-item label="消息" :span="2">{{ detail.message }}</el-descriptions-item>
        </el-descriptions>
        <div v-if="detail.stack" class="stack-section">
          <div class="stack-title">堆栈信息</div>
          <pre class="stack-content">{{ detail.stack }}</pre>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '@/utils/request'

const loading = ref(false)
const tableData = ref([])
const stats = ref({ total: 0, error: 0, warning: 0, today: 0 })
const detailVisible = ref(false)
const detail = ref(null)

let searchForm = reactive({
  level: 'all',
  keyword: '',
  dateRange: null
})

let pagination = reactive({
  current: 1,
  size: 20,
  total: 0
})

const loadStats = async () => {
  try {
    const res = await request.get('/v1/frontend-logs/stats')
    if (res.data) stats.value = res.data
  } catch (e) {
    console.error('loadStats error:', e)
  }
}

const loadData = async () => {
  loading.value = true
  try {
    const params = {
      current: pagination.current,
      size: pagination.size,
      level: searchForm.level === 'all' ? undefined : searchForm.level,
      keyword: searchForm.keyword || undefined,
      startDate: searchForm.dateRange?.[0] || undefined,
      endDate: searchForm.dateRange?.[1] || undefined
    }
    const res = await request.get('/v1/frontend-logs/page', { params })
    tableData.value = res.data || []
    pagination.total = res.total || 0
  } catch (e) {
    ElMessage.error('加载失败')
  } finally {
    loading.value = false
  }
}

const resetSearch = () => {
  searchForm.level = 'all'
  searchForm.keyword = ''
  searchForm.dateRange = null
  pagination.current = 1
  loadData()
}

const showDetail = (row) => {
  detail.value = row
  detailVisible.value = true
}

const clearLogs = async () => {
  try {
    await ElMessageBox.confirm('确定清空全部前端日志？此操作不可恢复。', '清空确认', { type: 'warning' })
    await request.delete('/v1/frontend-logs')
    ElMessage.success('已清空')
    loadStats()
    loadData()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('清空失败')
  }
}

onMounted(() => {
  loadStats()
  loadData()
})
</script>

<style scoped>
.log-container { padding: 16px; }
.stats-row { margin-bottom: 16px; }
.stat-card {
  background: #fff;
  border-radius: 6px;
  padding: 16px;
  text-align: center;
  border: 1px solid #e8e8e8;
}
.stat-value { font-size: 24px; font-weight: bold; color: #333; }
.stat-label { font-size: 12px; color: #999; margin-top: 4px; }
.stat-error .stat-value { color: #f56c6c; }
.stat-warning .stat-value { color: #e6a23c; }
.stat-total .stat-value { color: #409eff; }
.stat-today .stat-value { color: #67c23a; }
.search-form { margin-bottom: 12px; }
.log-table { border-radius: 6px; overflow: hidden; }
.pagination-wrap { margin-top: 12px; display: flex; justify-content: flex-end; }
.detail-content { max-height: 60vh; overflow-y: auto; }
.stack-section { margin-top: 12px; }
.stack-title { font-size: 13px; font-weight: bold; color: #333; margin-bottom: 6px; }
.stack-content {
  background: #1e1e1e;
  color: #d4d4d4;
  padding: 12px;
  border-radius: 4px;
  font-size: 12px;
  line-height: 1.5;
  overflow-x: auto;
  max-height: 300px;
  overflow-y: auto;
  white-space: pre-wrap;
  word-break: break-all;
}
</style>
