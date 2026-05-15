<!--
  PrintHistory.vue - 打印历史记录
  记录每次打印操作，支持查看/重新打印/删除
-->
<template>
  <div class="print-history">
    <el-table :data="historyList" border stripe size="small">
      <el-table-column prop="taskNo" label="任务编号" width="150" />
      <el-table-column prop="templateLabel" label="模板" width="120" />
      <el-table-column prop="recordNo" label="单据编号" width="150" />
      <el-table-column prop="printedBy" label="打印人" width="100" />
      <el-table-column prop="printedAt" label="打印时间" width="160">
        <template #default="{ row }">
          {{ formatDate(row.printedAt) }}
        </template>
      </el-table-column>
      <el-table-column prop="printerName" label="打印机" width="120" />
      <el-table-column prop="paperSize" label="纸张" width="80" />
      <el-table-column prop="copies" label="份数" width="60" align="center" />
      <el-table-column prop="pageCount" label="页数" width="60" align="center" />
      <el-table-column prop="fileUrl" label="PDF文件" width="100">
        <template #default="{ row }">
          <el-button
            v-if="row.fileUrl"
            type="text"
            size="small"
            @click="downloadFile(row)"
          >
            📥 下载
          </el-button>
          <span v-else class="text-muted">-</span>
        </template>
      </el-table-column>
      <el-table-column prop="ipAddress" label="IP地址" width="120" />
      <el-table-column label="操作" width="150" fixed="right">
        <template #default="{ row }">
          <el-button type="text" size="small" @click="reprint(row)">
            🔄 重打
          </el-button>
          <el-button type="text" size="small" @click="viewDetail(row)">
            📋 详情
          </el-button>
          <el-button type="text" size="small" @click="deleteRecord(row)">
            🗑 删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div class="pagination-wrapper">
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next"
        @size-change="loadHistory"
        @current-change="loadHistory"
      />
    </div>

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailVisible" title="打印详情" width="600px">
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="任务编号">{{ currentRecord?.taskNo }}</el-descriptions-item>
        <el-descriptions-item label="模板类型">{{ currentRecord?.templateLabel }}</el-descriptions-item>
        <el-descriptions-item label="单据编号">{{ currentRecord?.recordNo }}</el-descriptions-item>
        <el-descriptions-item label="打印人">{{ currentRecord?.printedBy }}</el-descriptions-item>
        <el-descriptions-item label="打印时间">{{ formatDate(currentRecord?.printedAt) }}</el-descriptions-item>
        <el-descriptions-item label="IP地址">{{ currentRecord?.ipAddress }}</el-descriptions-item>
        <el-descriptions-item label="打印机">{{ currentRecord?.printerName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="纸张">{{ currentRecord?.paperSize }}</el-descriptions-item>
        <el-descriptions-item label="份数">{{ currentRecord?.copies }}</el-descriptions-item>
        <el-descriptions-item label="页数">{{ currentRecord?.pageCount }}</el-descriptions-item>
        <el-descriptions-item label="状态" :span="2">
          <el-tag :type="currentRecord?.status === 'success' ? 'success' : 'danger'" size="small">
            {{ currentRecord?.status === 'success' ? '成功' : '失败' }}
          </el-tag>
        </el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="detailVisible = false">关闭</el-button>
        <el-button type="primary" @click="reprint(currentRecord)">重新打印</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '@/utils/request'

const props = defineProps({
  // 筛选：模板类型
  templateType: {
    type: String,
    default: ''
  },
  // 筛选：日期范围
  dateRange: {
    type: Array,
    default: () => []
  },
})

const emit = defineEmits(['reprint'])

const historyList = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const detailVisible = ref(false)
const currentRecord = ref(null)

// 加载历史记录
async function loadHistory() {
  try {
    const params = {
      page: currentPage.value,
      pageSize: pageSize.value,
      templateType: props.templateType || undefined,
      startDate: props.dateRange?.[0] || undefined,
      endDate: props.dateRange?.[1] || undefined,
    }

    const res = await request.get('/api/v1/print/history', { params })
    historyList.value = res.data?.list || []
    total.value = res.data?.total || 0
  } catch (e) {
    console.error('Load print history failed:', e)
    // 降级：显示空数据
    historyList.value = []
    total.value = 0
  }
}

// 格式化日期
function formatDate(value) {
  if (!value) return '-'
  const date = new Date(value)
  if (isNaN(date)) return value
  return date.toLocaleString('zh-CN')
}

// 查看详情
function viewDetail(row) {
  currentRecord.value = row
  detailVisible.value = true
}

// 重新打印
function reprint(row) {
  emit('reprint', row)
  detailVisible.value = false
}

// 下载文件
function downloadFile(row) {
  if (!row.fileUrl) return
  window.open(row.fileUrl, '_blank')
}

// 删除记录
async function deleteRecord(row) {
  try {
    await ElMessageBox.confirm('确定删除这条打印记录吗？', '提示', {
      type: 'warning',
    })

    await request.delete(`/api/v1/print/history/${row.id}`)
    ElMessage.success('删除成功')
    loadHistory()
  } catch (e) {
    if (e !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 刷新
function refresh() {
  loadHistory()
}

onMounted(() => {
  loadHistory()
})

defineExpose({ refresh })
</script>

<style scoped>
.print-history {
  padding: 20px;
}

.pagination-wrapper {
  margin-top: 15px;
  display: flex;
  justify-content: flex-end;
}

.text-muted {
  color: #999;
  font-size: 12px;
}
</style>
