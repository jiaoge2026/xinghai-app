<template>
  <div class="alert-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>库存预警</span>
          <el-button type="primary" @click="handleCheck">手动检查预警</el-button>
        </div>
      </template>

      <el-table :data="tableData" stripe style="width: 100%">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="partName" label="配件名称" min-width="150" />
        <el-table-column prop="warehouseName" label="仓库" width="120" />
        <el-table-column prop="currentStock" label="当前库存" width="100" align="right">
          <template #default="{ row }">
            <span :class="row.currentStock <= row.minStock ? 'text-danger' : ''">{{ row.currentStock }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="minStock" label="最低库存" width="100" align="right" />
        <el-table-column prop="alertLevel" label="预警级别" width="100">
          <template #default="{ row }">
            <el-tag :type="row.alertLevel === 'HIGH' ? 'danger' : 'warning'">
              {{ row.alertLevel === 'HIGH' ? '紧急' : '提醒' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 'PROCESSED' ? 'success' : 'info'">
              {{ row.status === 'PROCESSED' ? '已处理' : '未处理' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button
              v-if="row.status !== 'PROCESSED'"
              type="primary"
              size="small"
              link
              @click="handleProcess(row)"
            >处理</el-button>
            <el-button type="danger" size="small" link @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrap">
        <el-pagination
          v-model:current-page="page"
          v-model:page-size="pageSize"
          :total="total"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next"
          @size-change="loadData"
          @current-change="loadData"
        />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '@/utils/request'

const tableData = ref([])
const page = ref(1)
const pageSize = ref(10)
const total = ref(0)

const loadData = () => {
  request.get('/wms/alerts', { params: { page: page.value, pageSize: pageSize.value } })
    .then(res => {
      if (res.code === 0) {
        tableData.value = res.data.list || []
        total.value = res.data.total || 0
      }
    })
}

const handleProcess = (row) => {
  ElMessageBox.confirm('确认处理该预警？', '处理预警', { type: 'warning' })
    .then(() => {
      request.put(`/wms/alerts/${row.id}/process`).then(res => {
        if (res.code === 0) {
          ElMessage.success('处理成功')
          loadData()
        } else {
          ElMessage.error(res.message || '处理失败')
        }
      })
    }).catch(() => {})
}

const handleDelete = (row) => {
  ElMessageBox.confirm('确认删除该预警？', '删除预警', { type: 'warning' })
    .then(() => {
      request.delete(`/wms/alerts/${row.id}`).then(res => {
        if (res.code === 0) {
          ElMessage.success('删除成功')
          loadData()
        } else {
          ElMessage.error(res.message || '删除失败')
        }
      })
    }).catch(() => {})
}

const handleCheck = () => {
  request.post('/wms/alerts/check').then(res => {
    if (res.code === 0) {
      ElMessage.success('检查完成')
      loadData()
    } else {
      ElMessage.error(res.message || '检查失败')
    }
  })
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.alert-list { padding: 16px; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
.pagination-wrap { margin-top: 16px; display: flex; justify-content: flex-end; }
.text-danger { color: #f56c6c; font-weight: bold; }
</style>
