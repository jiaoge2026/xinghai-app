<template>
  <div class="finance-report">
    <el-card>
      <template #header><span>财务报表</span></template>
      
      <!-- Filter Controls -->
      <FinanceReportFilters
        v-model="filters"
        :loading="loading"
        @search="handleSearch"
        @reset="handleReset"
      />

      <!-- Stats Summary -->
      <el-row :gutter="16">
        <el-col :span="6" v-for="item in stats" :key="item.title">
          <el-card shadow="hover" class="stat-card">
            <div class="stat-value" :style="{ color: item.color }">{{ item.value }}</div>
            <div class="stat-title">{{ item.title }}</div>
          </el-card>
        </el-col>
      </el-row>

      <!-- Charts Row -->
      <el-row :gutter="16" style="margin-top: 16px">
        <el-col :span="12">
          <el-card>
            <template #header><span>月度营收趋势</span></template>
            <div ref="revenueChartRef" style="height: 300px"></div>
          </el-card>
        </el-col>
        <el-col :span="12">
          <el-card>
            <template #header><span>成本构成</span></template>
            <div ref="costChartRef" style="height: 300px"></div>
          </el-card>
        </el-col>
      </el-row>

      <!-- Data Table -->
      <el-row style="margin-top: 16px">
        <el-col :span="24">
          <el-card>
            <template #header><span>收支明细</span></template>
            <el-table :data="tableData" stripe v-loading="loading">
              <el-table-column prop="date" label="日期" width="120" />
              <el-table-column prop="type" label="类型" width="100">
                <template #default="{ row }">
                  <el-tag :type="row.type === 'income' ? 'success' : 'warning'">{{ row.typeText }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="item" label="项目" min-width="150" />
              <el-table-column prop="amount" label="金额" width="120" align="right" />
              <el-table-column prop="remark" label="备注" min-width="150" />
            </el-table>
          </el-card>
        </el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import * as echarts from 'echarts'
import FinanceReportFilters from '@/components/finance-components/FinanceReportFilters.vue'
import { useFinanceReportData } from '@/composables/useFinanceReportData'

// Filter state
const filters = ref({
  dateRange: [],
  type: 'all'
})

// Data loading via composable
const { loading, stats, tableData, revenueChartData, costChartData, loadMockData } = useFinanceReportData(filters)

// Chart refs and instances
let revenueChart = null
let costChart = null
const revenueChartRef = ref()
const costChartRef = ref()

// Chart rendering functions (kept intact)
function initCharts() {
  revenueChart = echarts.init(revenueChartRef.value)
  costChart = echarts.init(costChartRef.value)
  updateChartOptions()
}

function updateChartOptions() {
  if (revenueChart) {
    revenueChart.setOption({
      tooltip: { trigger: 'axis' },
      xAxis: { type: 'category', data: revenueChartData.value.xAxis || [] },
      yAxis: { type: 'value' },
      series: [{ name: '营收', type: 'line', data: revenueChartData.value.series || [], smooth: true }]
    })
  }

  if (costChart) {
    costChart.setOption({
      tooltip: { trigger: 'item' },
      series: [{
        type: 'pie',
        radius: ['40%', '70%'],
        data: costChartData.value || []
      }]
    })
  }
}

function disposeCharts() {
  revenueChart?.dispose()
  costChart?.dispose()
  revenueChart = null
  costChart = null
}

// Event handlers for filters
function handleSearch() {
  loadMockData()
  // Re-init charts after data loads
  setTimeout(() => {
    updateChartOptions()
  }, 50)
}

function handleReset() {
  loadMockData()
  setTimeout(() => {
    updateChartOptions()
  }, 50)
}

// Watch for data changes to update charts
watch([revenueChartData, costChartData], () => {
  updateChartOptions()
}, { deep: true })

onMounted(() => {
  initCharts()
  loadMockData()
})

onUnmounted(() => {
  disposeCharts()
})
</script>

<style scoped>
.stat-card { text-align: center; }
.stat-value { font-size: 24px; font-weight: bold; }
.stat-title { font-size: 13px; color: #999; margin-top: 8px; }
</style>
