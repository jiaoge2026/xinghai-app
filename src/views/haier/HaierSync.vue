<template>
  <div class="page-container">
    <el-row :gutter="16" class="stats-row">
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-value">{{ stats.totalAccounts }}</div>
          <div class="stat-label">绑定账号</div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-value">{{ stats.todaySync }}</div>
          <div class="stat-label">今日同步</div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-value">{{ stats.todayNew }}</div>
          <div class="stat-label">今日新增</div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-value">{{ stats.lastSyncTime || '-' }}</div>
          <div class="stat-label">最后同步</div>
        </div>
      </el-col>
    </el-row>

    <div class="toolbar">
      <el-button type="primary" @click="handleSync" :loading="syncing" :disabled="syncing">
        <el-icon v-if="!syncing"><Refresh /></el-icon>
        {{ syncing ? '同步中...' : '全量同步' }}
      </el-button>
      <el-button @click="loadStats">刷新</el-button>
    </div>

    <el-table :data="tableData" stripe v-loading="loading">
      <el-table-column prop="accountNo" label="账号" width="120" />
      <el-table-column prop="accountName" label="账号名称" min-width="150" />
      <el-table-column prop="orgName" label="所属网点" min-width="150" />
      <el-table-column prop="status" label="状态" width="100" align="center">
        <template #default="{row}">
          <el-tag :type="row.status === 'active' ? 'success' : 'info'">{{ row.status === 'active' ? '启用' : '停用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="syncCount" label="同步工单数" width="120" align="right" />
      <el-table-column prop="lastSyncTime" label="最后同步" width="160">
        <template #default="{row}">{{ row.lastSyncTime ? new Date(row.lastSyncTime).toLocaleString() : '-' }}</template>
      </el-table-column>
      <el-table-column label="操作" width="160" fixed="right">
        <template #default="{row}">
          <el-button link type="primary" @click="goToLogs(row)">同步日志</el-button>
        </template>
      </el-table-column>
    </el-table>

    <div class="pagination-wrap">
      <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="20" v-model:current-page="pageNum" @current-change="loadData" />
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import request from '@/utils/request'
import { Refresh } from '@element-plus/icons-vue'

const router = useRouter()
const loading = ref(false)
const syncing = ref(false)
const tableData = ref([])
const total = ref(0)
const pageNum = ref(1)
const stats = reactive({ totalAccounts: 0, todaySync: 0, todayNew: 0, lastSyncTime: '' })

const loadData = async () => {
  loading.value = true
  try {
    const res = await request.get('/v1/haier-sync/accounts', { pageNum: pageNum.value, pageSize: 20 })
    tableData.value = res.data?.list || res.data || []
    total.value = res.data?.total || 0
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

const loadStats = async () => {
  try {
    const res = await request.get('/v1/haier-sync/status')
    Object.assign(stats, res.data || {})
  } catch (e) {
    console.error(e)
  }
}

const handleSync = async () => {
  syncing.value = true
  try {
    await request.post('/v1/haier-sync/sync-all', {})
    ElMessage.success('同步任务已触发，请稍后刷新查看结果')
    setTimeout(loadStats, 3000)
  } catch (e) {
    ElMessage.error('触发同步失败')
  } finally {
    syncing.value = false
  }
}

const goToLogs = (row) => {
  router.push({ path: '/haier/logs', query: { accountId: row.id } })
}

onMounted(() => { loadData(); loadStats() })
</script>

<style scoped>
.page-container { padding: 16px; }
.stats-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; padding: 20px; text-align: center; box-shadow: 0 1px 4px rgba(0,0,0,.08); }
.stat-value { font-size: 28px; font-weight: 700; color: #409EFF; }
.stat-label { font-size: 13px; color: #666; margin-top: 6px; }
.toolbar { margin-bottom: 12px; }
.pagination-wrap { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
