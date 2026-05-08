<template>
  <div class="call-record-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>来电记录</span>
          <el-select v-model="queryType" placeholder="选择查询类型" style="width: 150px">
            <el-option label="全部" value="" />
            <el-option label="今日" value="today" />
            <el-option label="本周" value="week" />
            <el-option label="本月" value="month" />
          </el-select>
        </div>
      </template>
      <el-table :data="tableData" stripe style="width: 100%">
        <el-table-column prop="callId" label="来电编号" width="140" />
        <el-table-column prop="callerPhone" label="来电号码" width="130" />
        <el-table-column prop="customerName" label="客户名称" min-width="120" />
        <el-table-column prop="callTime" label="来电时间" width="180" />
        <el-table-column prop="waitTime" label="等待时长" width="100" />
        <el-table-column prop="talkTime" label="通话时长" width="100" />
        <el-table-column prop="agentName" label="客服" width="100" />
        <el-table-column prop="callType" label="类型" width="100">
          <template #default="{ row }">
            <el-tag size="small">{{ row.callType }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="result" label="处理结果" min-width="150" />
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const queryType = ref('')

const tableData = ref([
  { callId: 'CALL20260108001', callerPhone: '13800138001', customerName: '张三', callTime: '2026-01-08 10:30:00', waitTime: '12秒', talkTime: '5分32秒', agentName: '客服A', callType: '咨询', result: '已解答' },
  { callId: 'CALL20260108002', callerPhone: '13800138002', customerName: '李四', callTime: '2026-01-08 10:45:00', waitTime: '5秒', talkTime: '3分15秒', agentName: '客服B', callType: '投诉', result: '已记录投诉' },
  { callId: 'CALL20260108003', callerPhone: '13800138003', customerName: '王五', callTime: '2026-01-08 11:00:00', waitTime: '8秒', talkTime: '8分20秒', agentName: '客服A', callType: '报修', result: '已生成工单' },
  { callId: 'CALL20260108004', callerPhone: '13800138004', customerName: '-', callTime: '2026-01-08 11:15:00', waitTime: '0秒', talkTime: '1分45秒', agentName: '客服C', callType: '其他', result: '无效来电' }
])
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>