<template>
  <div class="engineer-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>工程师管理</span>
          <el-button type="primary">新增工程师</el-button>
        </div>
      </template>
      <el-table :data="tableData" stripe style="width: 100%">
        <el-table-column prop="id" label="工号" width="100" />
        <el-table-column prop="name" label="姓名" width="100" />
        <el-table-column prop="phone" label="联系电话" width="130" />
        <el-table-column prop="skill" label="技能专长" min-width="150" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '在职' : '离职' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="workOrders" label="当前工单" width="100" />
        <el-table-column prop="score" label="评分" width="100" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary">编辑</el-button>
            <el-button link type="primary">排班</el-button>
            <el-button link type="danger">禁用</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const tableData = ref([
  { id: 'E001', name: '李工', phone: '13800138001', skill: '空调维修、冰箱维修', status: 1, workOrders: 3, score: 4.8 },
  { id: 'E002', name: '王工', phone: '13800138002', skill: '洗衣机维修、烘干机维修', status: 1, workOrders: 2, score: 4.6 },
  { id: 'E003', name: '赵工', phone: '13800138003', skill: '厨电维修、热水器维修', status: 1, workOrders: 4, score: 4.9 },
  { id: 'E004', name: '钱工', phone: '13800138004', skill: '中央空调安装', status: 0, workOrders: 0, score: 4.7 }
])

onMounted(() => {})
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>