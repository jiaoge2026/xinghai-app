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

    <!-- 简单表格，绕过 el-table 崩溃问题 -->
    <div v-loading="loading" style="padding: 16px;">
      <table style="width:100%;border-collapse:collapse;font-size:14px;">
        <thead>
          <tr style="background:#f5f7fa;">
            <th style="padding:8px 12px;text-align:left;border-bottom:1px solid #ebeef5;">任务编号</th>
            <th style="padding:8px 12px;text-align:left;border-bottom:1px solid #ebeef5;">类型</th>
            <th style="padding:8px 12px;text-align:left;border-bottom:1px solid #ebeef5;">导出人</th>
            <th style="padding:8px 12px;text-align:left;border-bottom:1px solid #ebeef5;">状态</th>
            <th style="padding:8px 12px;text-align:right;border-bottom:1px solid #ebeef5;">导出行数</th>
            <th style="padding:8px 12px;text-align:left;border-bottom:1px solid #ebeef5;">创建时间</th>
            <th style="padding:8px 12px;text-align:left;border-bottom:1px solid #ebeef5;">操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="safeTasks.length === 0 && !loading">
            <td colspan="7" style="padding:40px;text-align:center;color:#909399;">暂无导出任务</td>
          </tr>
          <tr v-for="row in safeTasks" :key="row.id" style="border-bottom:1px solid #ebeef5;">
            <td style="padding:8px 12px;">{{ row.taskNo }}</td>
            <td style="padding:8px 12px;">{{ typeLabel(row.taskType) }}</td>
            <td style="padding:8px 12px;">{{ row.username }}</td>
            <td style="padding:8px 12px;">
              <span v-if="row.status === 'done'" style="color:#67c23a;">已完成</span>
              <span v-else-if="row.status === 'fail'" style="color:#f56c6c;">失败</span>
              <span v-else-if="row.status === 'processing' || row.status === 'pending'" style="color:#e6a23c;">处理中</span>
              <span v-else style="color:#909399;">等待中</span>
            </td>
            <td style="padding:8px 12px;text-align:right;">{{ row.totalRows.toLocaleString() }}</td>
            <td style="padding:8px 12px;">{{ fmt(row.createdAt) }}</td>
            <td style="padding:8px 12px;">
              <button v-if="row.status === 'done' && row.filePath" @click="downloadFile(row)" style="color:#409eff;background:none;border:none;cursor:pointer;padding:0;font-size:14px;">下载</button>
              <button @click="removeTask(row)" style="color:#f56c6c;background:none;border:none;cursor:pointer;padding:0;font-size:14px;margin-left:8px;">删除</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Loading, Document } from '@element-plus/icons-vue'
import request from '@/utils/request'

const tasks = ref([])
const loading = ref(false)
const viewMode = ref('mine')
const isAdmin = ref(false)
let pollTimer = null

// 防御性编程：保证 el-table 的 data 永远是合法数组，防止 JS 错误导致整个 Vue 应用崩溃
const safeTasks = computed(() => {
  if (!Array.isArray(tasks.value)) return []
  return tasks.value.map(t => ({
    id: t.id ?? '',
    taskNo: t.taskNo ?? '',
    taskType: t.taskType ?? '',
    username: t.username ?? '',
    status: t.status ?? '',
    progress: Number(t.progress) || 0,
    totalRows: Number(t.totalRows) || 0,
    fileSize: Number(t.fileSize) || 0,
    ipAddress: t.ipAddress ?? '',
    createdAt: t.createdAt ?? '',
    filePath: t.filePath ?? '',
  }))
})

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

async function fetchTasks() {
  loading.value = true
  try {
    const isAll = viewMode.value === 'all'
    const res = await request.get('/system/export-tasks', { params: { all: isAll } })
    tasks.value = Array.isArray(res.data) ? res.data : []
  } catch (e) {
    console.error('获取导出任务失败', e.message, e.response?.data)
    tasks.value = []
  } finally {
    loading.value = false
  }
}

async function downloadFile(row) {
  try {
    const token = localStorage.getItem('token')
    const url = `/api/v1/system/export-tasks/${row.id}/download?token=${encodeURIComponent(token || '')}`
    window.open(url, '_blank')
  } catch (e) {
    ElMessage.error('下载失败')
  }
}

async function removeTask(row) {
  try {
    await ElMessageBox.confirm(`删除任务 ${row.taskNo}？`, '确认', { type: 'warning' })
    await request.delete(`/system/export-tasks/${row.id}`)
    ElMessage.success('已删除')
    await fetchTasks()
  } catch (e) {
    if (e !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 切换视图时重新加载
watch(viewMode, () => { fetchTasks() })

// 轮询处理中任务
const startPoll = () => {
  pollTimer = setInterval(() => {
    const hasProcessing = tasks.value.some(t => t.status === 'pending' || t.status === 'processing')
    if (hasProcessing) fetchTasks()
  }, 5000)
}

onMounted(async () => {
  // 从 userInfo.roles 判断是否管理员
  const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
  const roles = userInfo.roles || []
  isAdmin.value = roles.includes('ADMIN') || roles.includes('ROLE_ADMIN')
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
