<template>
  <div class="part-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>配件管理</span>
          <el-button type="primary" @click="openAdd">新增配件</el-button>
        </div>
      </template>

      <!-- 搜索筛选区 -->
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="配件编码">
          <el-input v-model="searchForm.code" placeholder="请输入配件编码" clearable style="width: 150px" />
        </el-form-item>
        <el-form-item label="配件名称">
          <el-input v-model="searchForm.name" placeholder="请输入配件名称" clearable style="width: 150px" />
        </el-form-item>
        <el-form-item label="仓库分类">
          <el-select v-model="searchForm.warehouseId" placeholder="请选择仓库" clearable style="width: 160px">
            <el-option
              v-for="wh in warehouseList"
              :key="wh.id"
              :label="wh.name"
              :value="wh.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 表格区 -->
      <el-table v-loading="loading" :data="tableData" stripe style="width: 100%">
        <el-table-column prop="code" label="配件编码" width="120" />
        <el-table-column prop="name" label="配件名称" min-width="150" show-overflow-tooltip />
        <el-table-column prop="spec" label="规格型号" width="150" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="80" align="center" />
        <el-table-column prop="price" label="单价" width="100" align="right">
          <template #default="{ row }">
            ¥{{ row.price?.toFixed(2) }}
          </template>
        </el-table-column>
        <el-table-column prop="stock" label="库存" width="100" align="center">
          <template #default="{ row }">
            <span :class="{ 'stock-low': row.stock < row.minStock }">{{ row.stock }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="minStock" label="最低库存" width="100" align="center" />
        <el-table-column prop="warehouseName" label="所属仓库" width="120" show-overflow-tooltip />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link type="danger" @click="openDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <el-pagination
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.pageSize"
        :total="pagination.total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        style="margin-top: 16px; justify-content: flex-end;"
        @size-change="fetchData"
        @current-change="fetchData"
      />

      <!-- 新增/编辑弹窗 -->
      <el-dialog
        v-model="formDialogVisible"
        :title="formMode === 'add' ? '新增配件' : '编辑配件'"
        width="550px"
        :close-on-click-modal="false"
      >
        <el-form ref="formRef" :model="form" :rules="formRules" label-width="100px">
          <el-form-item label="配件编码" prop="code">
            <el-input v-model="form.code" placeholder="请输入配件编码" maxlength="30" :disabled="formMode === 'edit'" />
          </el-form-item>
          <el-form-item label="配件名称" prop="name">
            <el-input v-model="form.name" placeholder="请输入配件名称" maxlength="100" />
          </el-form-item>
          <el-form-item label="规格型号" prop="spec">
            <el-input v-model="form.spec" placeholder="请输入规格型号" maxlength="100" />
          </el-form-item>
          <el-form-item label="单位" prop="unit">
            <el-input v-model="form.unit" placeholder="如：台、个、罐" maxlength="20" style="width: 120px" />
          </el-form-item>
          <el-form-item label="单价" prop="price">
            <el-input-number v-model="form.price" :min="0" :precision="2" :controls="false" placeholder="0.00" style="width: 150px" />
          </el-form-item>
          <el-form-item label="库存" prop="stock">
            <el-input-number v-model="form.stock" :min="0" :precision="0" :controls="false" placeholder="0" style="width: 150px" />
          </el-form-item>
          <el-form-item label="最低库存" prop="minStock">
            <el-input-number v-model="form.minStock" :min="0" :precision="0" :controls="false" placeholder="0" style="width: 150px" />
          </el-form-item>
          <el-form-item label="所属仓库" prop="warehouseId">
            <el-select v-model="form.warehouseId" placeholder="请选择仓库" style="width: 100%">
              <el-option
                v-for="wh in warehouseList"
                :key="wh.id"
                :label="wh.name"
                :value="wh.id"
              />
            </el-select>
          </el-form-item>
          <el-form-item label="备注" prop="remark">
            <el-input v-model="form.remark" placeholder="请输入备注" type="textarea" :rows="2" maxlength="200" show-word-limit />
          </el-form-item>
        </el-form>
        <template #footer>
          <el-button @click="formDialogVisible = false">取消</el-button>
          <el-button type="primary" :loading="submitLoading" @click="handleSubmit">确定</el-button>
        </template>
      </el-dialog>

      <!-- 删除确认弹窗 -->
      <el-dialog v-model="deleteDialogVisible" title="删除确认" width="400px">
        <p style="font-size: 16px">确认删除配件 <strong>{{ deleteData.name }}</strong> (编码: {{ deleteData.code }}) 吗？此操作不可恢复。</p>
        <template #footer>
          <el-button @click="deleteDialogVisible = false">取消</el-button>
          <el-button type="danger" :loading="deleteLoading" @click="handleDelete">删除</el-button>
        </template>
      </el-dialog>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import request from '@/utils/request'
import { ElMessage, ElMessageBox } from 'element-plus'

// ---------- 仓库列表 ----------
const warehouseList = ref([])

// ---------- 表格数据 ----------
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 10, total: 0 })

// ---------- 搜索表单 ----------
const searchForm = reactive({
  code: '',
  name: '',
  warehouseId: null
})

// ---------- 新增/编辑表单 ----------
const formDialogVisible = ref(false)
const formMode = ref('add')
const submitLoading = ref(false)
const formRef = ref(null)

const defaultForm = () => ({
  code: '',
  name: '',
  spec: '',
  unit: '',
  price: 0,
  stock: 0,
  minStock: 0,
  warehouseId: null,
  remark: ''
})

const form = reactive(defaultForm())

const formRules = {
  code: [{ required: true, message: '请输入配件编码', trigger: 'blur' }],
  name: [{ required: true, message: '请输入配件名称', trigger: 'blur' }],
  warehouseId: [{ required: true, message: '请选择所属仓库', trigger: 'change' }]
}

// ---------- 删除 ----------
const deleteDialogVisible = ref(false)
const deleteLoading = ref(false)
const deleteData = ref({})

// ---------- 生命周期 ----------
onMounted(() => {
  fetchWarehouseList()
  fetchData()
})

// ---------- 方法 ----------
const fetchWarehouseList = async () => {
  try {
    const res = await request.get('/wms/warehouse/list', { params: { page: 1, pageSize: 100 } })
    warehouseList.value = res.data?.list || []
  } catch (e) {
    console.error('获取仓库列表失败', e)
    warehouseList.value = []
  }
}

const fetchData = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      pageSize: pagination.pageSize,
      ...searchForm
    }
    const res = await request.get('/wms/part/page', { params })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch (e) {
    console.error('获取配件列表失败', e)
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  pagination.page = 1
  fetchData()
}

const handleReset = () => {
  searchForm.code = ''
  searchForm.name = ''
  searchForm.warehouseId = null
  pagination.page = 1
  fetchData()
}

const openAdd = () => {
  formMode.value = 'add'
  Object.assign(form, defaultForm())
  formDialogVisible.value = true
}

const openEdit = (row) => {
  formMode.value = 'edit'
  Object.assign(form, {
    id: row.id,
    code: row.code,
    name: row.name,
    spec: row.spec || '',
    unit: row.unit || '',
    price: row.price || 0,
    stock: row.stock || 0,
    minStock: row.minStock || 0,
    warehouseId: row.warehouseId,
    remark: row.remark || ''
  })
  formDialogVisible.value = true
}

const handleSubmit = async () => {
  try {
    await formRef.value.validate()
    submitLoading.value = true
    const url = formMode.value === 'add' ? '/wms/part/add' : '/wms/part/update'
    await request.post(url, form)
    ElMessage.success(formMode.value === 'add' ? '新增成功' : '更新成功')
    formDialogVisible.value = false
    fetchData()
  } catch (e) {
    console.error('提交失败', e)
  } finally {
    submitLoading.value = false
  }
}

const openDelete = (row) => {
  deleteData.value = { id: row.id, code: row.code, name: row.name }
  deleteDialogVisible.value = true
}

const handleDelete = async () => {
  try {
    deleteLoading.value = true
    await request.delete(`/wms/part/delete/${deleteData.value.id}`)
    ElMessage.success('删除成功')
    deleteDialogVisible.value = false
    fetchData()
  } catch (e) {
    console.error('删除失败', e)
  } finally {
    deleteLoading.value = false
  }
}
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.search-form { margin-bottom: 16px; }
.stock-low { color: #f56c6c; font-weight: bold; }
</style>
