<template>
  <div class="dispatch-board">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>智能派工</span>
          <el-button type="primary">自动派单</el-button>
        </div>
      </template>
      <el-row :gutter="16">
        <el-col :span="12">
          <div class="board-section">
            <h4>待派单工单</h4>
            <el-table :data="pendingOrders" size="small" max-height="400">
              <el-table-column prop="id" label="工单号" width="120" />
              <el-table-column prop="title" label="工单标题" min-width="150" />
              <el-table-column prop="skill" label="所需技能" width="100" />
              <el-table-column prop="distance" label="距离" width="80" />
              <el-table-column label="操作" width="80">
                <template #default="{ row }">
                  <el-button size="small" type="primary" @click="handleDispatch(row)">派单</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-col>
        <el-col :span="12">
          <div class="board-section">
            <h4>工程师状态</h4>
            <el-table :data="engineers" size="small" max-height="400">
              <el-table-column prop="name" label="工程师" width="80" />
              <el-table-column prop="status" label="状态" width="80">
                <template #default="{ row }">
                  <el-tag :type="row.status === 'idle' ? 'success' : row.status === 'working' ? 'warning' : 'info'" size="small">
                    {{ row.statusText }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="currentOrder" label="当前工单" min-width="120" />
              <el-table-column prop="todayOrders" label="今日工单" width="80" />
              <el-table-column prop="location" label="位置" width="100" />
            </el-table>
          </div>
        </el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { ElMessage } from 'element-plus'

const pendingOrders = ref([
  { id: 'WO20260108002', title: '冰箱结冰问题', skill: '冰箱维修', distance: '3.2km' },
  { id: 'WO20260108004', title: '空调不制热', skill: '空调维修', distance: '5.1km' },
  { id: 'WO20260108005', title: '洗衣机不脱水', skill: '洗衣机维修', distance: '2.8km' }
])

const engineers = ref([
  { name: '李工', status: 'working', statusText: '工作中', currentOrder: 'WO20260108001', todayOrders: 4, location: '张江区域' },
  { name: '王工', status: 'idle', statusText: '空闲', currentOrder: '-', todayOrders: 3, location: '陆家嘴区域' },
  { name: '赵工', status: 'busy', statusText: '忙碌', currentOrder: 'WO20260107003', todayOrders: 5, location: '静安区域' }
])

const handleDispatch = (order) => {
  ElMessage.success(`已派单给李工: ${order.id}`)
}
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.board-section h4 { margin-bottom: 12px; color: #333; font-size: 14px; }
</style>