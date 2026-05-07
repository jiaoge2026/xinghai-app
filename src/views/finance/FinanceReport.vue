<template>
  <div class="finance-report">
    <el-card>
      <template #header><span>财务报表</span></template>
      <el-row :gutter="16">
        <el-col :span="6" v-for="item in stats" :key="item.title">
          <el-card shadow="hover" class="stat-card">
            <div class="stat-value" :style="{ color: item.color }">{{ item.value }}</div>
            <div class="stat-title">{{ item.title }}</div>
          </el-card>
        </el-col>
      </el-row>
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
      <el-row style="margin-top: 16px">
        <el-col :span="24">
          <el-card>
            <template #header><span>收支明细</span></template>
            <el-table :data="tableData" stripe>
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
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'

const stats = ref([
  { title: '本月收入', value: '¥128,000', color: '#67C23A' },
  { title: '本月支出', value: '¥86,000', color: '#F56C6C' },
  { title: '本月利润', value: '¥42,000', color: '#409EFF' },
  { title: '同比增长', value: '+15.8%', color: '#E6A23C' }
])

const tableData = ref([
  { date: '2026-01-08', type: 'income', typeText: '收入', item: '维修服务费', amount: '5,000.00', remark: '工单WO20260108001' },
  { date: '2026-01-08', type: 'expense', typeText: '支出', item: '配件采购', amount: '2,000.00', remark: '压缩机采购' },
  { date: '2026-01-07', type: 'income', typeText: '收入', item: '安装服务费', amount: '3,500.00', remark: '工单WO20260107001' },
  { date: '2026-01-07', type: 'expense', typeText: '支出', item: '员工工资', amount: '15,000.00', remark: '12月工资' }
])

let revenueChart = null
let costChart = null
const revenueChartRef = ref()
const costChartRef = ref()

onMounted(() => {
  revenueChart = echarts.init(revenueChartRef.value)
  costChart = echarts.init(costChartRef.value)

  revenueChart.setOption({
    tooltip: { trigger: 'axis' },
    xAxis: { type: 'category', data: ['1月', '2月', '3月', '4月', '5月', '6月'] },
    yAxis: { type: 'value' },
    series: [{ name: '营收', type: 'line', data: [105000, 98000, 115000, 128000, 135000, 128000], smooth: true }]
  })

  costChart.setOption({
    tooltip: { trigger: 'item' },
    series: [{
      type: 'pie',
      radius: ['40%', '70%'],
      data: [
        { value: 35000, name: '人工成本' },
        { value: 20000, name: '配件成本' },
        { value: 15000, name: '运营成本' },
        { value: 16000, name: '其他成本' }
      ]
    }]
  })
})

onUnmounted(() => {
  revenueChart?.dispose()
  costChart?.dispose()
})
</script>

<style scoped>
.stat-card { text-align: center; }
.stat-value { font-size: 24px; font-weight: bold; }
.stat-title { font-size: 13px; color: #999; margin-top: 8px; }
</style>