<template>
  <div class="approval-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>审批流程</span>
          <el-select v-model="queryStatus" placeholder="选择状态" style="width: 150px">
            <el-option label="全部" value="" />
            <el-option label="待审批" value="pending" />
            <el-option label="已通过" value="approved" />
            <el-option label="已驳回" value="rejected" />
          </el-select>
        </div>
      </template>
      <el-table :data="tableData" stripe style="width: 100%">
        <el-table-column prop="approvalNo" label="审批单号" width="140" />
        <el-table-column prop="title" label="审批标题" min-width="180" />
        <el-table-column prop="applicant" label="申请人" width="100" />
        <el-table-column prop="department" label="部门" width="120" />
        <el-table-column prop="approvalType" label="审批类型" width="120">
          <template #default="{ row }">
            <el-tag size="small">{{ row.approvalType }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="amount" label="金额" width="120" align="right" v-if="false" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">{{ row.statusText }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="currentApprover" label="当前审批人" width="100" />
        <el-table-column prop="createTime" label="申请时间" width="180" />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="handleApprove(row)" v-if="row.status === 'pending'">审批</el-button>
            <el-button link type="primary">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'

const queryStatus = ref('')

const tableData = ref([
  { approvalNo: 'AP20260108001', title: '采购申请-压缩机10台', applicant: '张三', department: '技术部', approvalType: '采购', status: 'pending', statusText: '待审批', currentApprover: '李经理', createTime: '2026-01-08 10:00:00' },
  { approvalNo: 'AP20260108002', title: '费用报销-招待费', applicant: '李四', department: '财务部', approvalType: '报销', status: 'approved', statusText: '已通过', currentApprover: '-', createTime: '2026-01-08 09:00:00' },
  { approvalNo: 'AP20260107003', title: '请假申请-年假3天', applicant: '王五', department: '市场部', approvalType: '请假', status: 'rejected', statusText: '已驳回', currentApprover: '-', createTime: '2026-01-07 14:00:00' },
  { approvalNo: 'AP20260107004', title: '设备采购-办公电脑5台', applicant: '赵六', department: '技术部', approvalType: '采购', status: 'pending', statusText: '待审批', currentApprover: '张总', createTime: '2026-01-07 11:00:00' }
])

const getStatusType = (status) => {
  const types = { pending: 'warning', approved: 'success', rejected: 'danger' }
  return types[status] || 'info'
}

const handleApprove = (row) => {
  ElMessageBox.confirm('确认通过该审批?', '提示', {
    confirmButtonText: '通过',
    cancelButtonText: '驳回',
    type: 'warning'
  }).then(() => {
    ElMessage.success('已通过')
  }).catch(() => {
    ElMessage.info('已驳回')
  })
}
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>