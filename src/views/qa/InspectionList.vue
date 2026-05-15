<template>
  <div class="inspection-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>质检管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新建质检</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="质检单号">
          <el-input v-model="query.inspectionNo" placeholder="质检单号" clearable style="width:160px" />
        </el-form-item>
        <el-form-item label="质检类型">
          <el-select v-model="query.type" placeholder="全部" clearable style="width:130px">
            <el-option :value="INSPECTION_TYPE.PATROL" label="巡检" />
            <el-option :value="INSPECTION_TYPE.SAMPLE" label="抽检" />
            <el-option :value="INSPECTION_TYPE.FULL" label="全检" />
          </el-select>
        </el-form-item>
        <el-form-item label="结果">
          <el-select v-model="query.result" placeholder="全部" clearable style="width:120px">
            <el-option :value="RESULT_PASS" label="合格" />
            <el-option :value="RESULT_FAIL" label="不合格" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="inspectionNo" label="质检单号" width="170" />
        <el-table-column prop="type" label="类型" width="90" align="center">
          <template #default="{ row }">
            <el-tag size="small">{{ INSPECTION_TYPE_LABEL[row.type] }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="inspectorName" label="质检员" min-width="100" />
        <el-table-column prop="itemName" label="检品名称" min-width="150" show-overflow-tooltip />
        <el-table-column prop="quantity" label="数量" width="80" align="center" />
        <el-table-column prop="result" label="结果" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.result === RESULT_PASS ? 'success' : 'danger'" size="small">
              {{ RESULT_LABEL[row.result] }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="defectDesc" label="不合格描述" min-width="200" show-overflow-tooltip />
        <el-table-column prop="inspectionDate" label="质检日期" width="120" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleView(row)">详情</el-button>
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination">
        <el-pagination
          v-model:current-page="query.page"
          v-model:page-size="query.pageSize"
          :total="total"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 详情弹窗 -->
    <el-dialog v-model="viewVisible" title="质检详情" width="600px" destroy-on-close>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="质检单号">{{ viewData.inspectionNo }}</el-descriptions-item>
        <el-descriptions-item label="质检类型">{{ INSPECTION_TYPE_LABEL[viewData.type] }}</el-descriptions-item>
        <el-descriptions-item label="质检员">{{ viewData.inspectorName }}</el-descriptions-item>
        <el-descriptions-item label="质检日期">{{ viewData.inspectionDate }}</el-descriptions-item>
        <el-descriptions-item label="检品名称">{{ viewData.itemName }}</el-descriptions-item>
        <el-descriptions-item label="数量">{{ viewData.quantity }}</el-descriptions-item>
        <el-descriptions-item label="结果">
          <el-tag :type="viewData.result === RESULT_PASS ? 'success' : 'danger'">{{ RESULT_LABEL[viewData.result] }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="不合格数">{{ viewData.defectCount ?? '-' }}</el-descriptions-item>
        <el-descriptions-item label="不合格描述" :span="2">{{ viewData.defectDesc || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewData.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="550px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="质检类型" prop="type">
          <el-select v-model="form.type" style="width:100%">
            <el-option :value="INSPECTION_TYPE.PATROL" label="巡检" />
            <el-option :value="INSPECTION_TYPE.SAMPLE" label="抽检" />
            <el-option :value="INSPECTION_TYPE.FULL" label="全检" />
          </el-select>
        </el-form-item>
        <el-form-item label="检品名称" prop="itemName">
          <el-input v-model="form.itemName" placeholder="被检品名称" />
        </el-form-item>
        <el-form-item label="数量" prop="quantity">
          <el-input-number v-model="form.quantity" :min="1" style="width:100%" />
        </el-form-item>
        <el-form-item label="质检结果" prop="result">
          <el-radio-group v-model="form.result">
            <el-radio :value="RESULT_PASS">合格</el-radio>
            <el-radio :value="RESULT_FAIL">不合格</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="不合格数">
          <el-input-number v-model="form.defectCount" :min="0" style="width:100%" />
        </el-form-item>
        <el-form-item label="不合格描述">
          <el-input v-model="form.defectDesc" type="textarea" :rows="2" placeholder="不合格项目描述" />
        </el-form-item>
        <el-form-item label="质检日期">
          <el-date-picker v-model="form.inspectionDate" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { Plus } from '@element-plus/icons-vue'
import {
  useInspectionList,
  INSPECTION_TYPE,
  INSPECTION_TYPE_LABEL,
  RESULT_PASS,
  RESULT_FAIL,
  RESULT_LABEL
} from '@/composables/useInspectionList'

const {
  loading, submitting, tableData, total, query,
  formRef, form, rules, dialogVisible, viewVisible, viewData, dialogTitle,
  fetchData, resetQuery, handleAdd, handleEdit, handleView, handleDelete, handleSubmit,
  handleSizeChange, handleCurrentChange
} = useInspectionList()
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
