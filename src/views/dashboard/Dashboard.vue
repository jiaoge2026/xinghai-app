<template>
  <div class="dashboard">
    <el-row :gutter="16">
      <el-col :span="6" v-for="item in stats" :key="item.title">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <div class="stat-value">{{ item.value }}</div>
            <div class="stat-title">{{ item.title }}</div>
          </div>
          <div class="stat-icon" :style="{ color: item.color }">
            <el-icon :size="32"><component :is="item.icon" /></el-icon>
          </div>
        </el-card>
      </el-col>
    </el-row>
    <el-row :gutter="16" style="margin-top:16px">
      <el-col :span="16">
        <el-card>
          <template #header><span>工单趋势</span></template>
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
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import request from '@/utils/request'

const stats = ref([
  { title: '今日新增工单', value: '12', icon: 'Document', color: '#409EFF' },
  { title: '进行中工单', value: '38', icon: 'Loading', color: '#E6A23C' },
  { title: '本月完成', value: '286', icon: 'CircleCheck', color: '#67C23A' },
  { title: '本月营收', value: '¥12.8万', icon: 'Money', color: '#F56C6C' }
])

let orderChart = null
let pieChart = null
const orderChartRef = ref()
const pieChartRef = ref()

onMounted(async () => {
  orderChart = echarts.init(orderChartRef.value)
  pieChart = echarts.init(pieChartRef.value)
  
  orderChart.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['新增', '完成'] },
    xAxis: { type: 'category', data: ['周一','周二','周三','周四','周五','周六','周日'] },
    yAxis: { type: 'value' },
    series: [
      { name: '新增', type: 'bar', data: [12, 8, 15, 10, 18, 6, 3] },
      { name: '完成', type: 'bar', data: [10, 12, 9, 14, 16, 8, 5] }
    ]
  })

  pieChart.setOption({
    tooltip: { trigger: 'item' },
    legend: { bottom: 0 },
    series: [{
      type: 'pie',
      radius: ['40%','70%'],
      data: [
        { value: 38, name: '进行中' },
        { value: 12, name: '待派单' },
        { value: 8, name: '待完工' },
        { value: 286, name: '已完成' }
      ]
    }]
  })
})

onUnmounted(() => {
  orderChart?.dispose()
  pieChart?.dispose()
})
</script>

<style scoped>
.stat-card { display: flex; align-items: center; justify-content: space-between; }
.stat-value { font-size: 28px; font-weight: bold; color: #333; }
.stat-title { font-size: 13px; color: #999; margin-top: 4px; }
.stat-icon { opacity: 0.8; }
</style>