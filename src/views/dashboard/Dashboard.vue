<template>
  <div class="dashboard">
    <!-- 统计卡片 -->
    <el-row :gutter="16">
      <el-col :span="6" v-for="item in stats" :key="item.title">
        <el-card shadow="hover" class="stat-card" :body-style="{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }">
          <div>
            <div class="stat-value">{{ item.value }}</div>
            <div class="stat-title">{{ item.title }}</div>
            <div class="stat-change" :class="item.change >= 0 ? 'up' : 'down'" v-if="item.change !== undefined">
              {{ item.change >= 0 ? '↑' : '↓' }} {{ Math.abs(item.change) }}%
            </div>
          </div>
          <div class="stat-icon" :style="{ color: item.color }">
            <el-icon :size="36"><component :is="item.icon" /></el-icon>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 图表区 -->
    <el-row :gutter="16" style="margin-top:16px">
      <el-col :span="16">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>工单趋势（近7天）</span>
              <el-radio-group v-model="orderPeriod" size="small" @change="loadOrderTrend">
                <el-radio-button value="7">近7天</el-radio-button>
                <el-radio-button value="30">近30天</el-radio-button>
              </el-radio-group>
            </div>
          </template>
          <div ref="orderChartRef" style="height:300px"></div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card>
          <template #header><span>工单状态分布</span></template>
          <div ref="pieChartRef" style="height:300px"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 预警区 -->
    <el-row :gutter="16" style="margin-top:16px">
      <el-col :span="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>库存预警</span>
              <el-badge :value="lowStockItems.length" type="danger" :hidden="lowStockItems.length === 0">
                <el-button size="small" @click="$router.push('/wms/part-stock')">查看详情</el-button>
              </el-badge>
            </div>
          </template>
          <el-table :data="lowStockItems" stripe size="small" max-height="200" v-loading="stockLoading">
            <el-table-column prop="partNo" label="配件编码" width="120" />
            <el-table-column prop="partName" label="配件名称" min-width="160" />
            <el-table-column prop="warehouseName" label="仓库" width="100" />
            <el-table-column label="当前库存" width="100">
              <template #default="{ row }">
                <span style="color:#F56C6C;font-weight:bold">{{ row.quantity }}</span>
              </template>
            </el-table-column>
            <el-table-column label="安全库存" width="100">
              <template #default="{ row }">
                <span style="color:#999">{{ row.safeStock }}</span>
              </template>
            </el-table-column>
          </el-table>
          <el-empty v-if="!stockLoading && lowStockItems.length === 0" description="暂无预警" :image-size="60" />
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>待审批事项</span>
              <el-badge :value="pendingApprovals" type="warning" :hidden="pendingApprovals === 0">
                <el-button size="small" @click="$router.push('/approval/list')">去审批</el-button>
              </el-badge>
            </div>
          </template>
          <div class="pending-list">
            <div v-for="item in pendingList" :key="item.instanceNo" class="pending-item" @click="$router.push('/approval/list')">
              <div class="pending-info">
                <span class="pending-title">{{ item.workflowName }}</span>
                <span class="pending-applicant">申请人: {{ item.applicantName }}</span>
              </div>
              <el-tag type="warning" size="small">待审批</el-tag>
            </div>
            <el-empty v-if="pendingList.length === 0 && !pendingLoading" description="暂无待审批" :image-size="60" />
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import { Document, Loading, CircleCheck, Money, Warning, Bell } from '@element-plus/icons-vue'
import request from '@/utils/request'

const stats = ref([
  { title: '今日新增工单', value: '--', icon: 'Document', color: '#409EFF' },
  { title: '进行中工单', value: '--', icon: 'Loading', color: '#E6A23C' },
  { title: '本月完成', value: '--', icon: 'CircleCheck', color: '#67C23A' },
  { title: '本月营收', value: '--', icon: 'Money', color: '#F56C6C' }
])

const orderPeriod = ref('7')
const lowStockItems = ref([])
const pendingApprovals = ref(0)
const pendingList = ref([])
const stockLoading = ref(false)
const pendingLoading = ref(false)

let orderChart = null
let pieChart = null
const orderChartRef = ref()
const pieChartRef = ref()

// 加载统计数据
const loadStats = async () => {
  try {
    // 从工单统计接口获取
    const res = await request.get('/report/data/workOrderStats')
    if (res.data) {
      stats.value[0].value = res.data.todayNew || 0
      stats.value[1].value = res.data.inProgress || 0
      stats.value[2].value = res.data.monthCompleted || 0
      stats.value[3].value = res.data.monthRevenue ? '¥' + res.data.monthRevenue + '万' : '--'
    }
  } catch (e) {
    console.error('loadStats error:', e)
    // 使用默认值（--）
  }
}

// 加载工单趋势
const loadOrderTrend = async () => {
  if (!orderChart) return
  try {
    const res = await request.get(`/report/data/orderTrend?period=${orderPeriod.value}`)
    const data = res.data || []
    orderChart.setOption({
      tooltip: { trigger: 'axis' },
      legend: { data: ['新增', '完成'] },
      grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
      xAxis: { type: 'category', data: data.dates || [] },
      yAxis: { type: 'value' },
      series: [
        { name: '新增', type: 'line', smooth: true, data: data.newOrders || [] },
        { name: '完成', type: 'line', smooth: true, data: data.completedOrders || [] }
      ]
    })
  } catch (e) {
    console.error('loadOrderTrend error:', e)
    // 保持默认数据
  }
}

// 加载工单状态分布
const loadOrderStatus = async () => {
  if (!pieChart) return
  try {
    const res = await request.get('/report/data/orderStatus')
    const data = res.data || []
    pieChart.setOption({
      tooltip: { trigger: 'item' },
      legend: { bottom: 0 },
      series: [{
        type: 'pie',
        radius: ['40%', '70%'],
        data: data
      }]
    })
  } catch (e) {
    console.error('loadOrderStatus error:', e)
  }
}

// 加载库存预警
const loadStockAlert = async () => {
  stockLoading.value = true
  try {
    const res = await request.get('/wms/part-stock/low-alert')
    lowStockItems.value = res.data || []
  } catch (e) {
    console.error('loadStockAlert error:', e)
    lowStockItems.value = []
  } finally {
    stockLoading.value = false
  }
}

// 加载待审批
const loadPending = async () => {
  pendingLoading.value = true
  try {
    const res = await request.get('/workflow/pending')
    pendingList.value = (res.data || []).slice(0, 5)
    pendingApprovals.value = pendingList.value.length
  } catch (e) {
    console.error('loadPending error:', e)
    pendingList.value = []
  } finally {
    pendingLoading.value = false
  }
}

const initCharts = () => {
  nextTick(() => {
    orderChart = echarts.init(orderChartRef.value)
    pieChart = echarts.init(pieChartRef.value)

    // 默认数据（等待API）
    orderChart.setOption({
      tooltip: { trigger: 'axis' },
      legend: { data: ['新增', '完成'] },
      grid: { left: '3%', right: '4%', bottom: '3%', containLabel: true },
      xAxis: { type: 'category', data: ['暂无数据'] },
      yAxis: { type: 'value' },
      series: [
        { name: '新增', type: 'line', smooth: true, data: [] },
        { name: '完成', type: 'line', smooth: true, data: [] }
      ]
    })

    pieChart.setOption({
      tooltip: { trigger: 'item' },
      legend: { bottom: 0 },
      series: [{
        type: 'pie',
        radius: ['40%', '70%'],
        data: [
          { value: 0, name: '暂无数据' }
        ]
      }]
    })

    // 加载真实数据
    loadOrderTrend()
    loadOrderStatus()
  })
}

const loadAll = () => {
  loadStats()
  loadStockAlert()
  loadPending()
}

onMounted(() => {
  initCharts()
  loadAll()

  // 监听窗口变化
  window.addEventListener('resize', () => {
    orderChart?.resize()
    pieChart?.resize()
  })
})

onUnmounted(() => {
  orderChart?.dispose()
  pieChart?.dispose()
})
</script>

<style scoped>
.stat-card { cursor: default; }
.stat-value { font-size: 28px; font-weight: bold; color: #333; }
.stat-title { font-size: 13px; color: #999; margin-top: 4px; }
.stat-change { font-size: 12px; margin-top: 4px; }
.stat-change.up { color: #67C23A; }
.stat-change.down { color: #F56C6C; }
.stat-icon { opacity: 0.7; }
.card-header { display: flex; justify-content: space-between; align-items: center; }

.pending-list { display: flex; flex-direction: column; gap: 8px; }
.pending-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  border: 1px solid #eee;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.2s;
}
.pending-item:hover { background: #f5f7fa; }
.pending-title { font-size: 14px; font-weight: 500; color: #333; display: block; }
.pending-applicant { font-size: 12px; color: #999; }
</style>
