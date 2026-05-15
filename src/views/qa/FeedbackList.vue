<template>
  <div class="feedback-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>客户反馈管理</span>
        </div>
      </template>

      <!-- 搜索筛选 -->
      <div class="search-form">
        <el-form :inline="true" :model="queryForm" class="search-form-inline">
          <el-form-item label="客户名称">
            <el-input v-model="queryForm.customerName" placeholder="请输入客户名称" clearable style="width: 160px" />
          </el-form-item>
          <el-form-item label="反馈类型">
            <el-select v-model="queryForm.feedbackType" placeholder="全部" clearable style="width: 140px">
              <el-option label="全部" value="" />
              <el-option label="投诉" value="1" />
              <el-option label="表扬" value="2" />
              <el-option label="建议" value="3" />
            </el-select>
          </el-form-item>
          <el-form-item label="状态">
            <el-select v-model="queryForm.status" placeholder="全部" clearable style="width: 140px">
              <el-option label="全部" value="" />
              <el-option label="待处理" value="1" />
              <el-option label="处理中" value="2" />
              <el-option label="已解决" value="3" />
            </el-select>
          </el-form-item>
          <el-form-item label="日期范围">
            <el-date-picker
              v-model="dateRange"
              type="daterange"
              range-separator="至"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              value-format="YYYY-MM-DD"
              style="width: 260px"
            />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleSearch">查询</el-button>
            <el-button @click="handleReset">重置</el-button>
          </el-form-item>
        </el-form>
      </div>

      <!-- 表格列表 -->
      <el-table :data="tableData" stripe style="width: 100%" v-loading="loading">
        <el-table-column prop="id" label="反馈编号" width="140" />
        <el-table-column prop="customerName" label="客户名称" min-width="120" />
        <el-table-column prop="customerPhone" label="联系电话" width="130" />
        <el-table-column prop="feedbackType" label="反馈类型" width="100">
          <template #default="{ row }">
            <el-tag size="small" :type="getFeedbackTypeTag(row.feedbackType)">
              {{ getFeedbackTypeText(row.feedbackType) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="content" label="反馈内容" min-width="200" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="反馈时间" width="180" />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openDetail(row)">详情</el-button>
            <el-button link type="primary" @click="openHandle(row)">处理</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination-wrap">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.pageSize"
          :total="pagination.total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailVisible" title="反馈详情" width="600px" destroy-on-close>
      <div v-if="currentRow" class="detail-content">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="反馈编号">{{ currentRow.id }}</el-descriptions-item>
          <el-descriptions-item label="客户名称">{{ currentRow.customerName }}</el-descriptions-item>
          <el-descriptions-item label="联系电话">{{ currentRow.customerPhone }}</el-descriptions-item>
          <el-descriptions-item label="反馈类型">
            <el-tag size="small" :type="getFeedbackTypeTag(currentRow.feedbackType)">
              {{ getFeedbackTypeText(currentRow.feedbackType) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="getStatusType(currentRow.status)">
              {{ getStatusText(currentRow.status) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="反馈时间">{{ currentRow.createTime }}</el-descriptions-item>
          <el-descriptions-item label="反馈内容" :span="2">{{ currentRow.content }}</el-descriptions-item>
        </el-descriptions>

        <!-- 处理记录 -->
        <div class="record-section">
          <h4>处理记录</h4>
          <el-timeline v-if="currentRow.records && currentRow.records.length">
            <el-timeline-item
              v-for="(record, index) in currentRow.records"
              :key="index"
              :timestamp="record.createTime"
              placement="top"
            >
              <el-card shadow="never">
                <p><strong>处理人：</strong>{{ record.handlerName }}</p>
                <p><strong>状态：</strong><el-tag size="small" :type="getStatusType(record.status)">{{ getStatusText(record.status) }}</el-tag></p>
                <p><strong>备注：</strong>{{ record.remark || '无' }}</p>
              </el-card>
            </el-timeline-item>
          </el-timeline>
          <el-empty v-else description="暂无处理记录" :image-size="60" />
        </div>
      </div>
      <template #footer>
        <el-button @click="detailVisible = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 处理弹窗 -->
    <el-dialog v-model="handleVisible" title="处理反馈" width="500px" destroy-on-close>
      <el-form :model="handleForm" :rules="handleRules" ref="handleFormRef" label-width="90px">
        <el-form-item label="反馈编号">
          <el-input v-model="currentRow.id" disabled />
        </el-form-item>
        <el-form-item label="处理状态" prop="status">
          <el-select v-model="handleForm.status" placeholder="请选择状态" style="width: 100%">
            <el-option label="待处理" value="1" />
            <el-option label="处理中" value="2" />
            <el-option label="已解决" value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="处理人" prop="handlerId">
          <el-select v-model="handleForm.handlerId" placeholder="请选择处理人" style="width: 100%" filterable>
            <el-option
              v-for="emp in employeeList"
              :key="emp.id"
              :label="emp.name"
              :value="emp.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="处理备注" prop="remark">
          <el-input v-model="handleForm.remark" type="textarea" :rows="3" placeholder="请输入处理备注" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="handleVisible = false">取消</el-button>
        <el-button type="primary" @click="submitHandle" :loading="submitLoading">提交</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useFeedbackList } from '@/composables/useFeedbackList'

const {
  // State
  loading,
  submitLoading,
  tableData,
  pagination,
  queryForm,
  dateRange,
  detailVisible,
  currentRow,
  handleVisible,
  handleFormRef,
  handleForm,
  handleRules,
  employeeList,

  // Methods
  getStatusType,
  getStatusText,
  getFeedbackTypeTag,
  getFeedbackTypeText,
  loadData,
  handleSearch,
  handleReset,
  handleSizeChange,
  handleCurrentChange,
  openDetail,
  openHandle,
  submitHandle
} = useFeedbackList()

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.feedback-list {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.search-form {
  margin-bottom: 20px;
}

.search-form-inline {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.pagination-wrap {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}

.detail-content {
  max-height: 60vh;
  overflow-y: auto;
}

.record-section {
  margin-top: 20px;
}

.record-section h4 {
  margin-bottom: 12px;
  font-size: 14px;
  color: #303133;
}

:deep(.el-descriptions__label) {
  width: 100px;
}
</style>
