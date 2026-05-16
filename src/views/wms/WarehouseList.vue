<template>
  <div class="warehouse-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>仓库管理</span>
          <el-button type="primary" @click="openAdd">新增仓库</el-button>
        </div>
      </template>

      <!-- 搜索区域 -->
      <div class="search-bar">
        <el-form inline :model="searchForm" class="search-form">
          <el-form-item label="仓库编码">
            <el-input v-model="searchForm.code" placeholder="请输入仓库编码" clearable style="width: 150px" />
          </el-form-item>
          <el-form-item label="仓库名称">
            <el-input v-model="searchForm.name" placeholder="请输入仓库名称" clearable style="width: 150px" />
          </el-form-item>
          <el-form-item label="状态">
            <el-select v-model="searchForm.status" placeholder="全部" clearable style="width: 120px">
              <el-option :value="1" label="启用" />
              <el-option :value="0" label="停用" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleSearch">查询</el-button>
            <el-button @click="handleReset">重置</el-button>
          </el-form-item>
        </el-form>
      </div>

      <el-table v-loading="loading" :data="tableData" stripe style="width: 100%">
        <el-table-column prop="code" label="仓库编码" width="120" />
        <el-table-column prop="name" label="仓库名称" min-width="150" />
        <el-table-column prop="address" label="仓库地址" min-width="200" show-overflow-tooltip />
        <el-table-column prop="manager" label="负责人" width="100" />
        <el-table-column prop="phone" label="联系电话" width="130" />
        <el-table-column prop="capacity" label="容量" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'">
              {{ row.status === 1 ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="pagination.pageNum"
          v-model:page-size="pagination.pageSize"
          :total="pagination.total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handlePageChange"
        />
      </div>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog
      v-model="dialogVisible"
      :title="formMode === 'add' ? '新增仓库' : '编辑仓库'"
      width="500px"
      @close="handleDialogClose"
    >
      <el-form ref="formRef" :model="form" :rules="formRules" label-width="100px">
        <el-form-item label="仓库编码" prop="code">
          <el-input v-model="form.code" maxlength="20" :disabled="formMode === 'edit'" placeholder="请输入仓库编码" />
        </el-form-item>
        <el-form-item label="仓库名称" prop="name">
          <el-input v-model="form.name" maxlength="100" placeholder="请输入仓库名称" />
        </el-form-item>
        <el-form-item label="仓库地址" prop="address">
          <el-input v-model="form.address" maxlength="200" placeholder="请输入仓库地址" />
        </el-form-item>
        <el-form-item label="负责人" prop="manager">
          <el-input v-model="form.manager" maxlength="50" placeholder="请输入负责人" />
        </el-form-item>
        <el-form-item label="联系电话" prop="phone">
          <el-input v-model="form.phone" maxlength="20" placeholder="请输入联系电话" />
        </el-form-item>
        <el-form-item label="容量" prop="capacity">
          <el-input-number v-model="form.capacity" :min="0" :controls="false" style="width: 150px" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio :value="1">启用</el-radio>
            <el-radio :value="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitLoading" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '@/utils/request'

// API 路径常量
const API_WAREHOUSES = '/wms/warehouses'

// 状态常量
const STATUS = {
  ENABLED: 1,
  DISABLED: 0
}

// 表格数据
const tableData = ref([])
const loading = ref(false)

// 搜索表单
let searchForm = reactive({
  code: '',
  name: '',
  status: null
})

// 分页
let pagination = reactive({
  page: 1,
  pageSize: 10,
  total: 0
})

// 弹窗
const dialogVisible = ref(false)
const formRef = ref()
const formMode = ref('add')
const submitLoading = ref(false)

// 表单
const form = ref({
  id: null,
  code: '',
  name: '',
  address: '',
  manager: '',
  phone: '',
  capacity: null,
  status: STATUS.ENABLED
})

// 表单校验规则
const formRules = {
  code: [
    { required: true, message: '请输入仓库编码', trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9_]+$/, message: '仓库编码只能包含字母、数字和下划线', trigger: 'blur' }
  ],
  name: [
    { required: true, message: '请输入仓库名称', trigger: 'blur' },
    { min: 2, max: 100, message: '仓库名称长度为 2-100 个字符', trigger: 'blur' }
  ]
}

// 获取默认表单数据
const getDefaultForm = () => ({
  id: null,
  code: '',
  name: '',
  address: '',
  manager: '',
  phone: '',
  capacity: null,
  status: STATUS.ENABLED
})

// 获取数据
const fetchData = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.pageNum,
      pageSize: pagination.pageSize,
      ...searchForm
    }
    const res = await request.get(API_WAREHOUSES, { params })
    tableData.value = res.data?.list || res.data || []
    pagination.total = res.data?.total || 0
  } catch (error) {
    ElMessage.error('获取仓库列表失败')
    console.error('fetchData error:', error)
  } finally {
    loading.value = false
  }
}

// 搜索
const handleSearch = () => {
  pagination.pageNum = 1
  fetchData()
}

// 重置搜索
const handleReset = () => {
  searchForm.code = ''
  searchForm.name = ''
  searchForm.status = null
  pagination.pageNum = 1
  fetchData()
}

// 分页
const handleSizeChange = () => {
  pagination.pageNum = 1
  fetchData()
}

const handlePageChange = () => {
  fetchData()
}

// 打开新增弹窗
const openAdd = () => {
  formMode.value = 'add'
  form.value = getDefaultForm()
  dialogVisible.value = true
}

// 打开编辑弹窗
const openEdit = (row) => {
  formMode.value = 'edit'
  form.value = { ...row }
  dialogVisible.value = true
}

// 弹窗关闭
const handleDialogClose = () => {
  formRef.value?.resetFields()
}

// 提交表单
const handleSubmit = async () => {
  try {
    await formRef.value.validate()
    submitLoading.value = true

    if (formMode.value === 'add') {
      await request.post(API_WAREHOUSES, form.value)
      ElMessage.success('新增成功')
    } else {
      await request.put(`${API_WAREHOUSES}/${form.value.id}`, form.value)
      ElMessage.success('编辑成功')
    }

    dialogVisible.value = false
    fetchData()
  } catch (error) {
    if (error !== false) {
      ElMessage.error(formMode.value === 'add' ? '新增失败' : '编辑失败')
      console.error('handleSubmit error:', error)
    }
  } finally {
    submitLoading.value = false
  }
}

// 删除
const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除仓库「${row.name}」吗？删除后不可恢复。`,
      '删除确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    await request.delete(`${API_WAREHOUSES}/${row.id}`)
    ElMessage.success('删除成功')
    fetchData()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
      console.error('handleDelete error:', error)
    }
  }
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.search-bar {
  margin-bottom: 16px;
}

.search-form {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.pagination-wrapper {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}
</style>
