<template>
  <div class="dispatch-board">
    <el-row :gutter="16" class="mb-16">
      <!-- 统计卡片 -->
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-value" style="color:#409EFF">{{ stats.pending }}</div>
            <div class="stat-label">待派单</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-value" style="color:#67C23A">{{ stats.dispatched }}</div>
            <div class="stat-label">今日已派</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-value" style="color:#E6A23C">{{ stats.engineers }}</div>
            <div class="stat-label">在线工程师</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-value" style="color:#909399">{{ stats.completed }}</div>
            <div class="stat-label">今日完成</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16">
      <!-- 左侧：待派单工单 -->
      <el-col :span="14">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>待派单工单</span>
              <el-button type="primary" size="small" @click="loadPendingOrders" :loading="loadingOrders">
                刷新
              </el-button>
            </div>
          </template>
          <el-table :data="pendingOrders" v-loading="loadingOrders" size="small" max-height="420" stripe>
            <el-table-column prop="woNo" label="工单号" width="130" />
            <el-table-column prop="customerName" label="客户" width="100" show-overflow-tooltip />
            <el-table-column prop="applianceType" label="家电类型" width="100">
              <template #default="{ row }">
                <el-tag size="small" type="info">{{ applianceTypeName(row.applianceType) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="serviceType" label="服务类型" width="80">
              <template #default="{ row }">
                <el-tag size="small">{{ serviceTypeName(row.serviceType) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="faultDesc" label="故障描述" min-width="120" show-overflow-tooltip />
            <el-table-column label="操作" width="120" fixed="right">
              <template #default="{ row }">
                <el-button size="small" type="primary" @click="openDispatch(row)">派单</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>

      <!-- 右侧：工程师状态 -->
      <el-col :span="10">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>在线工程师</span>
              <el-button size="small" @click="loadEngineers">刷新</el-button>
            </div>
          </template>
          <el-table :data="engineers" size="small" max-height="420" v-loading="loadingEngineers" stripe>
            <el-table-column prop="name" label="姓名" width="80" />
            <el-table-column prop="skillTags" label="技能" min-width="120" show-overflow-tooltip />
            <el-table-column prop="serviceArea" label="服务区域" width="100" show-overflow-tooltip />
            <el-table-column prop="todayWoCount" label="今日工单" width="80" align="center">
              <template #default="{ row }">
                <el-tag size="small" :type="row.todayWoCount >= 6 ? 'danger' : 'success'">
                  {{ row.todayWoCount }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="avgRating" label="评分" width="70" align="center">
              <template #default="{ row }">
                <span v-if="row.avgRating">{{ Number(row.avgRating).toFixed(1) }} ⭐</span>
                <span v-else>-</span>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>

    <!-- 派单对话框 -->
    <el-dialog v-model="dispatchDialogVisible" title="智能派单" width="680px" destroy-on-close>
      <div v-if="selectedOrder">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="工单编号">{{ selectedOrder.woNo }}</el-descriptions-item>
          <el-descriptions-item label="客户">{{ selectedOrder.customerName }}</el-descriptions-item>
          <el-descriptions-item label="地址">{{ selectedOrder.customerAddress }}</el-descriptions-item>
          <el-descriptions-item label="故障">{{ selectedOrder.faultDesc }}</el-descriptions-item>
        </el-descriptions>

        <el-divider>推荐工程师（按匹配度排序）</el-divider>

        <el-table :data="recommendations" size="small" v-loading="loadingRecommend">
          <el-table-column prop="engineer.name" label="姓名" width="80" />
          <el-table-column prop="engineer.skillTags" label="技能" width="120" show-overflow-tooltip />
          <el-table-column prop="engineer.serviceArea" label="服务区域" width="100" />
          <el-table-column prop="engineer.todayWoCount" label="今日工单" width="80" align="center" />
          <el-table-column prop="score" label="匹配分" width="80" align="center">
            <template #default="{ row }">
              <el-tag :type="scoreTagType(row.score)">{{ Number(row.score).toFixed(0) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="80">
            <template #default="{ row }">
              <el-button size="small" type="primary" @click="doAssign(row.engineer.id)">派给</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
      <template #footer>
        <el-button @click="dispatchDialogVisible = false">取消</el-button>
        <el-button type="warning" @click="doAutoDispatch" :loading="dispatching" :disabled="!selectedOrder">
          AI自动派单
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '@/utils/request'

const pendingOrders = ref([])
const engineers = ref([])
const recommendations = ref([])
const selectedOrder = ref(null)
const dispatchDialogVisible = ref(false)
const loadingOrders = ref(false)
const loadingEngineers = ref(false)
const loadingRecommend = ref(false)
const dispatching = ref(false)
const stats = ref({ pending: 0, dispatched: 0, engineers: 0, completed: 0 })

const APPLIANCE_TYPES = {
  air_conditioner: '空调', refrigerator: '冰箱', washing_machine: '洗衣机',
  water_heater: '热水器', range_hood: '油烟机', gas_stove: '燃气灶',
  television: '电视', air_purifier: '空气净化器', other: '其他'
}
const SERVICE_TYPES = { repair: '维修', installation: '安装', maintenance: '保养' }

const applianceTypeName = (t) => APPLIANCE_TYPES[t] || t
const serviceTypeName = (t) => SERVICE_TYPES[t] || t
const scoreTagType = (s) => s >= 70 ? 'success' : s >= 50 ? 'warning' : 'info'

async function loadStats() {
  try {
    // 查今日派工统计
    const res = await request.get('/dispatch/logs', { params: { page: 1, pageSize: 1 } })
    const total = res.data?.total || 0
    stats.value.dispatched = total

    // 查待派单工单数
    const woRes = await request.get('/fsm/work-orders', { params: { status: 1, page: 1, pageSize: 1 } })
    stats.value.pending = woRes.data?.total || 0

    stats.value.engineers = engineers.value.length
    stats.value.completed = 0
  } catch (e) {
    console.error('loadStats error', e)
  }
}

async function loadPendingOrders() {
  loadingOrders.value = true
  try {
    const res = await request.get('/fsm/work-orders', { params: { status: 1, page: 1, pageSize: 50 } })
    pendingOrders.value = res.data?.list || res.data || []
    stats.value.pending = pendingOrders.value.length
  } catch (e) {
    ElMessage.error('加载待派单工单失败')
  } finally {
    loadingOrders.value = false
  }
}

async function loadEngineers() {
  loadingEngineers.value = true
  try {
    const res = await request.get('/dispatch/engineers/available')
    engineers.value = res.data || []
    stats.value.engineers = engineers.value.length
  } catch (e) {
    ElMessage.error('加载工程师列表失败')
  } finally {
    loadingEngineers.value = false
  }
}

async function openDispatch(order) {
  selectedOrder.value = order
  dispatchDialogVisible.value = true
  loadingRecommend.value = true
  try {
    const res = await request.get(`/dispatch/recommend/${order.id}`)
    recommendations.value = res.data || []
  } catch (e) {
    ElMessage.error('获取推荐失败')
    recommendations.value = []
  } finally {
    loadingRecommend.value = false
  }
}

async function doAssign(engineerId) {
  if (!selectedOrder.value) return
  try {
    await ElMessageBox.confirm(`确认派单给工程师 #${engineerId}？`, '确认派工')
    await request.post('/dispatch/assign', {
      workOrderId: selectedOrder.value.id,
      engineerId: engineerId,
      reason: '人工派单'
    })
    ElMessage.success('派单成功')
    dispatchDialogVisible.value = false
    loadPendingOrders()
    loadStats()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('派单失败')
  }
}

async function doAutoDispatch() {
  if (!selectedOrder.value) return
  dispatching.value = true
  try {
    const res = await request.post('/dispatch/auto', null, { params: { workOrderId: selectedOrder.value.id } })
    const result = res.data || {}
    const engineerName = result.dispatchedEngineer?.name || '工程师'
    ElMessage.success(`自动派单成功：${engineerName}（评分 ${result.score}）`)
    dispatchDialogVisible.value = false
    loadPendingOrders()
    loadStats()
  } catch (e) {
    ElMessage.error('自动派单失败：' + (e.message || '未知错误'))
  } finally {
    dispatching.value = false
  }
}

onMounted(() => {
  loadPendingOrders()
  loadEngineers()
  loadStats()
})
</script>

<style scoped>
.dispatch-board { padding: 16px; }
.mb-16 { margin-bottom: 16px; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
.stat-card { text-align: center; padding: 8px 0; }
.stat-value { font-size: 28px; font-weight: bold; }
.stat-label { font-size: 13px; color: #909399; margin-top: 4px; }
</style>
