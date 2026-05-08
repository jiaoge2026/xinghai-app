<template>
  <div class="approval-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <el-radio-group v-model="activeTab" @change="onTabChange">
            <el-radio-button label="pending">待我审批</el-radio-button>
            <el-radio-button label="applications">我的申请</el-radio-button>
          </el-radio-group>
          <div class="header-right">
            <el-button size="small" @click="loadData" :loading="loading">
              <el-icon><Refresh /></el-icon> 刷新
            </el-button>
          </div>
        </div>
      </template>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="instanceNo" label="审批单号" width="160" />
        <el-table-column prop="workflowName" label="流程名称" min-width="160" />
        <el-table-column prop="applicantName" label="申请人" width="100" />
        <el-table-column prop="department" label="部门" width="120" show-overflow-tooltip />
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)" size="small">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="当前节点" width="120">
          <template #default="{ row }">
            <span>{{ row.currentNodeIndex || 1 }} / {{ row.totalNodes || 1 }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="申请时间" width="160" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="viewDetail(row)">详情</el-button>
            <template v-if="activeTab === 'pending' && row.status === 'PENDING'">
              <el-button link type="success" @click="approve(row)">通过</el-button>
              <el-button link type="danger" @click="reject(row)">驳回</el-button>
            </template>
            <el-button link type="warning" v-if="activeTab === 'applications' && row.status === 'PENDING'" @click="cancel(row)">撤回</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination" v-if="total > 0">
        <el-pagination
          v-model:current-page="page"
          :page-size="pageSize"
          :total="total"
          layout="prev, pager, next, total"
          @current-change="loadData"
        />
      </div>
    </el-card>

    <!-- 审批详情 弹窗 -->
    <el-dialog v-model="detailVisible" title="审批详情" width="700px" destroy-on-close>
      <div v-if="detail">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="审批单号">{{ detail.instanceNo }}</el-descriptions-item>
          <el-descriptions-item label="流程名称">{{ detail.workflowName }}</el-descriptions-item>
          <el-descriptions-item label="申请人">{{ detail.applicantName }}</el-descriptions-item>
          <el-descriptions-item label="部门">{{ detail.department }}</el-descriptions-item>
          <el-descriptions-item label="当前状态">
            <el-tag :type="getStatusType(detail.status)" size="small">
              {{ getStatusText(detail.status) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="申请时间">{{ detail.createTime }}</el-descriptions-item>
        </el-descriptions>

        <el-divider content-position="left">审批流程</el-divider>
        <el-steps :active="getStepActive(detail.status)" finish-status="success" align-center>
          <el-step v-for="(node, idx) in detail.nodes" :key="idx"
            :title="node.nodeName"
            :description="node.approverName + ' · ' + (node.finishTime || (node.status === 'PENDING' ? '审批中' : '待处理'))"
          />
        </el-steps>

        <template v-if="activeTab === 'pending' && detail.status === 'PENDING'">
          <el-divider content-position="left">审批操作</el-divider>
          <el-form label-width="80px">
            <el-form-item label="审批意见">
              <el-input v-model="approveComment" type="textarea" :rows="3" placeholder="可选填写审批意见" />
            </el-form-item>
            <el-form-item>
              <el-button type="success" @click="doApprove" :loading="actionLoading">通过</el-button>
              <el-button type="danger" @click="doReject" :loading="actionLoading">驳回</el-button>
            </el-form-item>
          </el-form>
        </template>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Refresh } from '@element-plus/icons-vue'
import request from '@/utils/request'

const activeTab = ref('pending')
const tableData = ref([])
const loading = ref(false)
const actionLoading = ref(false)
const detailVisible = ref(false)
const detail = ref(null)
const approveComment = ref('')
const page = ref(1)
const pageSize = ref(20)
const total = ref(0)

// 当前操作的行
const currentRow = ref(null)

const getStatusText = (status) => {
  const map = { 'PENDING': '审批中', 'APPROVED': '已通过', 'REJECTED': '已驳回', 'CANCELLED': '已撤回' }
  return map[status] || status
}

const getStatusType = (status) => {
  const map = { 'PENDING': 'warning', 'APPROVED': 'success', 'REJECTED': 'danger', 'CANCELLED': 'info' }
  return map[status] || 'info'
}

const getStepActive = (status) => {
  const map = { 'PENDING': 0, 'APPROVED': 99, 'REJECTED': 0, 'CANCELLED': 0 }
  return map[status] || 0
}

const loadData = async () => {
  loading.value = true
  try {
    let res
    if (activeTab.value === 'pending') {
      res = await request.get('/workflow/pending')
      tableData.value = res.data || []
    } else {
      res = await request.get('/workflow/my-applications')
      tableData.value = res.data || []
    }
    total.value = tableData.value.length
  } catch (e) {
    console.error('loadData error:', e)
    tableData.value = []
  } finally {
    loading.value = false
  }
}

const onTabChange = () => {
  page.value = 1
  loadData()
}

const viewDetail = async (row) => {
  try {
    const res = await request.get(`/workflow/instances/${row.instanceNo}`)
    detail.value = res.data
    detailVisible.value = true
  } catch (e) {
    ElMessage.error('加载详情失败: ' + (e.message || ''))
  }
}

const approve = (row) => {
  currentRow.value = row
  approveComment.value = ''
  detail.value = { ...row }
  detailVisible.value = true
}

const reject = (row) => {
  currentRow.value = row
  approveComment.value = ''
  detail.value = { ...row }
  detailVisible.value = true
}

const doApprove = async () => {
  if (!currentRow.value) return
  actionLoading.value = true
  try {
    await request.post('/workflow/approve', {
      instanceId: currentRow.value.id || currentRow.value.instanceId,
      comment: approveComment.value
    })
    ElMessage.success('审批已通过')
    detailVisible.value = false
    loadData()
  } catch (e) {
    ElMessage.error('审批失败: ' + (e.message || ''))
  } finally {
    actionLoading.value = false
  }
}

const doReject = async () => {
  if (!currentRow.value) return
  try {
    await ElMessageBox.confirm('确认驳回此审批申请？', '驳回确认', { type: 'warning' })
    actionLoading.value = true
    await request.post('/workflow/reject', {
      instanceId: currentRow.value.id || currentRow.value.instanceId,
      comment: approveComment.value || '不符合条件，驳回'
    })
    ElMessage.success('已驳回')
    detailVisible.value = false
    loadData()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('驳回失败: ' + (e.message || ''))
  } finally {
    actionLoading.value = false
  }
}

const cancel = async (row) => {
  try {
    await ElMessageBox.confirm('确认撤回此申请？', '撤回确认', { type: 'warning' })
    await request.post('/workflow/cancel', {
      instanceId: row.id || row.instanceId
    })
    ElMessage.success('已撤回')
    loadData()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('撤回失败: ' + (e.message || ''))
  }
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.pagination { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
