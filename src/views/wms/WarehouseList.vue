<template>
  <div class="warehouse-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>仓库管理</span>
          <el-button type="primary">新增仓库</el-button>
        </div>
      </template>
      <el-table :data="tableData" stripe style="width: 100%">
        <el-table-column prop="code" label="仓库编码" width="120" />
        <el-table-column prop="name" label="仓库名称" min-width="150" />
        <el-table-column prop="address" label="仓库地址" min-width="200" />
        <el-table-column prop="manager" label="负责人" width="100" />
        <el-table-column prop="phone" label="联系电话" width="130" />
        <el-table-column prop="capacity" label="容量" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary">编辑</el-button>
            <el-button link type="danger">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const tableData = ref([
  { code: 'WH001', name: '总部仓库', address: '上海市浦东新区张江高科技园区', manager: '张经理', phone: '021-88880001', capacity: 5000, status: 1 },
  { code: 'WH002', name: '分部仓库', address: '北京市朝阳区科技园区', manager: '李经理', phone: '010-88880002', capacity: 3000, status: 1 },
  { code: 'WH003', name: '华南仓库', address: '广州市天河区软件园', manager: '王经理', phone: '020-88880003', capacity: 4000, status: 1 }
])

onMounted(() => {})
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>