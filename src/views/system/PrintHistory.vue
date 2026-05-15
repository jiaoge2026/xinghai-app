<!--
  PrintHistory.vue - 打印历史记录页面
  独立页面：/system/print-history
-->
<template>
  <div class="print-history-page">
    <!-- 搜索栏 -->
    <div class="search-panel">
      <el-form :inline="true" :model="searchForm" size="default">
        <el-form-item label="模板类型">
          <el-select v-model="searchForm.templateType" placeholder="全部" clearable>
            <el-option
              v-for="(tpl, key) in printTemplates"
              :key="key"
              :label="tpl.label"
              :value="key"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="打印时间">
          <el-date-picker
            v-model="searchForm.dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            value-format="YYYY-MM-DD"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadData" :icon="Search">查询</el-button>
          <el-button @click="resetForm">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 数据表格 -->
    <div class="table-panel">
      <el-table
        :data="tableData"
        border
        stripe
        v-loading="loading"
        :height="tableHeight"
      >
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="taskNo" label="任务编号" width="160" />
        <el-table-column prop="templateLabel" label="模板" width="120">
          <template #default="{ row }">
            <el-tag size="small">{{ row.templateLabel || row.templateType }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="recordNo" label="单据编号" width="150" />
        <el-table-column prop="printedBy" label="打印人" width="100" />
        <el-table-column prop="printedAt" label="打印时间" width="160">
          <template #default="{ row }">
            {{ formatDate(row.printedAt) }}
          </template>
        </el-table-column>
        <el-table-column prop="paperSize" label="纸张" width="80" align="center" />
        <el-table-column prop="copies" label="份数" width="60" align="center" />
        <el-table-column prop="pageCount" label="页数" width="60" align="center" />
        <el-table-column prop="status" label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 'success' ? 'success' : 'danger'" size="small">
              {{ row.status === 'success' ? '成功' : '失败' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="ipAddress" label="IP" width="120" />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button type="text" size="small" @click="reprint(row)">🔄 重打</el-button>
            <el-button type="text" size="small" @click="viewDetail(row)">📋 详情</el-button>
            <el-button type="text" size="small" @click="deleteRow(row)" style="color: #F56C6C;">
              🗑 删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="pagination-wrapper">
      <el-pagination
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.pageSize"
        :total="pagination.total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next"
        @size-change="loadData"
        @current-change="loadData"
      />
    </div>

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailVisible" title="打印详情" width="650px">
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="任务编号" :span="2">
          {{ detailData.taskNo }}
        </el-descriptions-item>
        <el-descriptions-item label="模板类型">
          {{ detailData.templateLabel }} ({{ detailData.templateType }})
        </el-descriptions-item>
        <el-descriptions-item label="单据编号">
          {{ detailData.recordNo || '-' }}
        </el-descriptions-item>
        <el-descriptions-item label="打印人">{{ detailData.printedBy }}</el-descriptions-item>
        <el-descriptions-item label="打印时间">
          {{ formatDate(detailData.printedAt) }}
        </el-descriptions-item>
        <el-descriptions-item label="IP地址">{{ detailData.ipAddress }}</el-descriptions-item>
        <el-descriptions-item label="打印机">{{ detailData.printerName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="纸张">{{ detailData.paperSize }}</el-descriptions-item>
        <el-descriptions-item label="方向">{{ detailData.orientation }}</el-descriptions-item>
        <el-descriptions-item label="份数">{{ detailData.copies }}</el-descriptions-item>
        <el-descriptions-item label="页数">{{ detailData.pageCount }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="detailData.status === 'success' ? 'success' : 'danger'" size="small">
            {{ detailData.status === 'success' ? '成功' : '失败' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="错误信息" :span="2" v-if="detailData.errorMsg">
          <span style="color: #F56C6C;">{{ detailData.errorMsg }}</span>
        </el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="detailVisible = false">关闭</el-button>
        <el-button type="primary" @click="reprint(detailData)">🔄 重新打印</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import request from '@/utils/request'
import { printTemplates } from '@/components/print/registry.js'

const tableHeight = ref(500)
const loading = ref(false)
const tableData = ref([])
const detailVisible = ref(false)
const detailData = ref({})

const searchForm = reactive({
  templateType: '',
  dateRange: [],
})

const pagination = reactive({
  page: 1,
  pageSize: 20,
  total: 0,
})

// 加载数据
async function loadData() {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      pageSize: pagination.pageSize,
      templateType: searchForm.templateType || undefined,
      startDate: searchForm.dateRange?.[0] || undefined,
      endDate: searchForm.dateRange?.[1] || undefined,
    }

    const res = await request.get('/api/v1/print/history', { params })
    const page = res.data

    tableData.value = page.records || []
    pagination.total = page.total || 0
  } catch (e) {
    console.error('Load print history failed:', e)
    tableData.value = []
    ElMessage.error('加载失败')
  } finally {
    loading.value = false
  }
}

// 重置表单
function resetForm() {
  searchForm.templateType = ''
  searchForm.dateRange = []
  pagination.page = 1
  loadData()
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
  detailData.value = { ...row }
  detailVisible.value = true
}

// 重新打印
function reprint(row) {
  ElMessage.info(`重新打印功能开发中，模板类型：${row.templateType}`)
  detailVisible.value = false
}

// 删除
async function deleteRow(row) {
  try {
    await ElMessageBox.confirm('确定删除这条打印记录吗？', '提示', {
      type: 'warning',
    })

    await request.delete(`/api/v1/print/history/${row.id}`)
    ElMessage.success('删除成功')
    loadData()
  } catch (e) {
    if (e !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 自适应表格高度
function calcTableHeight() {
  const h = window.innerHeight - 280
  tableHeight.value = h > 300 ? h : 300
}

onMounted(() => {
  calcTableHeight()
  window.addEventListener('resize', calcTableHeight)
  loadData()
})
</script>

<style scoped>
.print-history-page {
  padding: 20px;
}

.search-panel {
  margin-bottom: 15px;
}

.table-panel {
  margin-bottom: 15px;
}

.pagination-wrapper {
  display: flex;
  justify-content: flex-end;
}
</style>
