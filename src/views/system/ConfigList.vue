<template>
  <div class="config-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>系统配置</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增配置</el-button>
        </div>
      </template>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="configKey" label="配置项" min-width="200" />
        <el-table-column prop="configValue" label="配置值" min-width="250" show-overflow-tooltip />
        <el-table-column prop="configType" label="类型" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="typeMap[row.configType] || 'info'" size="small">
              {{ row.configType === 'STRING' ? '字符串' : row.configType === 'NUMBER' ? '数字' : '布尔' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" min-width="150" show-overflow-tooltip />
        <el-table-column prop="updatedAt" label="更新时间" width="170" />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link :icon="Edit" @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" link :icon="Delete" @click="handleDelete(row)">删除</el-button>
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
          @change="loadData"
        />
      </div>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="500px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="配置项名" prop="configKey">
          <el-input v-model="form.configKey" placeholder="如：sys.default.password" :disabled="isEdit" />
        </el-form-item>
        <el-form-item label="配置值" prop="configValue">
          <el-input v-model="form.configValue" type="textarea" :rows="3" placeholder="配置值" />
        </el-form-item>
        <el-form-item label="类型" prop="configType">
          <el-select v-model="form.configType" style="width:100%">
            <el-option value="STRING" label="字符串" />
            <el-option value="NUMBER" label="数字" />
            <el-option value="BOOLEAN" label="布尔" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" placeholder="配置说明或用途" />
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
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete } from '@element-plus/icons-vue'
import request from '@/utils/request'

const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const dialogVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()

const typeMap = { STRING: '', NUMBER: 'success', BOOLEAN: 'warning' }

const query = reactive({ page: 1, pageSize: 20 })

const form = reactive({
  id: null,
  configKey: '',
  configValue: '',
  configType: 'STRING',
  remark: ''
})

const rules = {
  configKey: [{ required: true, message: '请输入配置项名', trigger: 'blur' }],
  configValue: [{ required: true, message: '请输入配置值', trigger: 'blur' }],
  configType: [{ required: true, message: '请选择类型', trigger: 'change' }]
}

const dialogTitle = computed(() => isEdit.value ? '编辑配置' : '新增配置')

const loadData = async () => {
  loading.value = true
  try {
    const res = await request.get('/system/configs', { params: query })
    tableData.value = res.data?.list || []
    total.value = res.data?.total || 0
  } catch {
    tableData.value = []
  } finally {
    loading.value = false
  }
}

const handleAdd = () => {
  isEdit.value = false
  Object.assign(form, { id: null, configKey: '', configValue: '', configType: 'STRING', remark: '' })
  dialogVisible.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  Object.assign(form, { ...row })
  dialogVisible.value = true
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) {
      await request.put(`/system/configs/${form.id}`, form)
      ElMessage.success('更新成功')
    } else {
      await request.post('/system/configs', form)
      ElMessage.success('新增成功')
    }
    dialogVisible.value = false
    loadData()
  } finally {
    submitting.value = false
  }
}

const handleDelete = async (row) => {
  await ElMessageBox.confirm(`确定删除配置「${row.configKey}」？`, '提示', { type: 'warning' })
  await request.delete(`/system/configs/${row.id}`)
  ElMessage.success('删除成功')
  loadData()
}

onMounted(loadData)
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.pagination { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
