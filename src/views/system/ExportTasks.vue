<template>
  <div class="export-tasks-page">
    <div class="page-header">
      <h2>导出任务</h2>
      <div class="header-actions">
        <el-radio-group v-model="viewMode" size="default">
          <el-radio-button value="mine">我的导出</el-radio-button>
          <el-radio-button value="all" v-if="isAdmin">全部导出</el-radio-button>
        </el-radio-group>
      </div>
    </div>

    <el-table :data="tasks" v-loading="loading" stripe>
      <el-table-column prop="taskNo" label="任务编号" width="160" />
      <el-table-column prop="taskType" label="类型" width="100">
        <template #default="{ row }">
          <el-tag type="info" size="small">{{ typeLabel(row.taskType) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="username" label="导出人" width="100" />
      <el-table-column prop="status" label="状态" width="100">
        <template #default="{ row }">
          <el-tag v-if="row.status === 'done'" type="success" size="small">已完成</el-tag>
          <el-tag v-else-if="row.status === 'fail'" type="danger" size="small">失败</el-tag>
          <el-tag v-else-if="row.status === 'processing'" type="warning" size="small">
            <el-icon class="is-loading"><Loading /></el-icon> 处理中
          </el-tag>
          <el-tag v-else type="info" size="small">等待中</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="progress" label="进度" width="140">
        <template #default="{ row }">
          <el-progress
            v-if="row.status === 'processing' || row.status === 'done'"
            :percentage="row.progress || 0"
            :stroke-width="6"
            style="width:100px;display:inline-block;vertical-align:middle"
          />
          <span v-else style="color:#999">—</span>
        </template>
      </el-table-column>
      <el-table-column prop="totalRows" label="导出行数" width="90">
        <template #default="{ row }">{{ row.totalRows || 0 }}</template>
      </el-table-column>
      <el-table-column prop="fileSize" label="文件大小" width="100">
        <template #default="{ row }">{{ formatSize(row.fileSize) }}</template>
      </el-table-column>
      <el-table-column prop="ipAddress" label="IP" width="130" />
      <el-table-column prop="createdAt" label="创建时间" width="160">
        <template #default="{ row }">{{ fmt(row.createdAt) }}</template>
      </el-table-column>
      <el-table-column label="操作" width="100" fixed="right">
        <template #default="{ row }">
          <el-button
            v-if="row.status === 'done' && row.filePath"
            type="primary"
            size="small"
            link
            @click="download(row)"
          >下载</el-button>
          <el-button
            type="danger"
            size="small"
            link
            @click="remove(row)"
          >删除</el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Loading } from '@element-plus/icons-vue'

const API_BASE = '/api'
const tasks = ref([])
const loading = ref(false)
const viewMode = ref('mine')
const isAdmin = ref(false)
let pollTimer = null

const typeLabel = (t) => ({ WORK_ORDER: '工单', EMPLOYEE: '员工' }[t] || t)

const fmt = (v) => {
  if (!v) return '—'
  const d = new Date(v)
  if (isNaN(d)) return v
  const pad = n => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
}

const formatSize = (bytes) => {
  if (!bytes) return '—'
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  return (bytes / 1024 / 1024).toFixed(1) + ' MB'
}

const fetchTasks = async () => {
  try {
    const token = localStorage.getItem('token')
    const res = await fetch(`${API_BASE}/v1/system/export-tasks?all=${viewMode.value === 'all'}`, {
      headers: { 'Authorization': 'Bearer ' + token }
    })
    if (res.ok) {
      const json = await res.json()
      tasks.value = json.data || []
    }
  } catch (e) { console.error(e) }
}

const download = (row) => {
  const token = localStorage.getItem('token')
  window.open(`${API_BASE}/v1/system/export-tasks/${row.id}/download?token=${encodeURIComponent(token)}`, '_blank')
}

const remove = async (row) => {
  await ElMessageBox.confirm(`删除任务 ${row.taskNo}？`, '确认', { type: 'warning' })
  const token = localStorage.getItem('token')
  const res = await fetch(`${API_BASE}/v1/system/export-tasks/${row.id}`, {
    method: 'DELETE',
    headers: { 'Authorization': 'Bearer ' + token }
  })
  if (res.ok) {
    ElMessage.success('已删除')
    fetchTasks()
  } else {
    ElMessage.error('删除失败')
  }
}

// 轮询处理中任务
const startPoll = () => {
  pollTimer = setInterval(() => {
    const hasProcessing = tasks.value.some(t => t.status === 'pending' || t.status === 'processing')
    if (hasProcessing) fetchTasks()
  }, 3000)
}

onMounted(async () => {
  // 简单权限判断：localStorage里的role
  const role = localStorage.getItem('role') || ''
  isAdmin.value = role.includes('ADMIN') || role.includes('admin')
  await fetchTasks()
  startPoll()
})

onUnmounted(() => { if (pollTimer) clearInterval(pollTimer) })
</script>

<style scoped>
.export-tasks-page { padding: 16px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; }
.page-header h2 { margin: 0; font-size: 16px; font-weight: 600; }
</style>
