<template>
  <div class="product-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>商品管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增商品</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="商品名称">
          <el-input v-model="query.name" placeholder="商品名称" clearable style="width:150px" />
        </el-form-item>
        <el-form-item label="商品分类">
          <el-select v-model="query.categoryId" placeholder="全部" clearable style="width:140px">
            <el-option v-for="c in catOptions" :key="c.id" :value="c.id" :label="c.name" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="productCode" label="商品编码" width="130" />
        <el-table-column prop="name" label="商品名称" min-width="180" />
        <el-table-column prop="categoryName" label="分类" min-width="120" />
        <el-table-column prop="spec" label="规格" min-width="120" />
        <el-table-column prop="unit" label="单位" width="70" align="center" />
        <el-table-column prop="price" label="零售价" width="100" align="right">
          <template #default="{ row }">{{ fmt(row.price) }}</template>
        </el-table-column>
        <el-table-column prop="stock" label="库存" width="90" align="center">
          <template #default="{ row }">
            <span :style="{ color: row.stock <= 10 ? '#F56C6C' : '' }">{{ row.stock ?? '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">{{ row.status === 1 ? '上架' : '下架' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
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
          :page-sizes="[10,20,50]"
          layout="total,sizes,prev,pager,next"
          @change="fetchData"
        />
      </div>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="550px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="商品编码" prop="productCode">
          <el-input v-model="form.productCode" placeholder="商品编码" :disabled="isEdit" />
        </el-form-item>
        <el-form-item label="商品名称" prop="name">
          <el-input v-model="form.name" placeholder="商品名称" />
        </el-form-item>
        <el-form-item label="商品分类" prop="categoryId">
          <el-select v-model="form.categoryId" placeholder="选择分类" style="width:100%">
            <el-option v-for="c in catOptions" :key="c.id" :value="c.id" :label="c.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="规格">
          <el-input v-model="form.spec" placeholder="如：500g/瓶" />
        </el-form-item>
        <el-form-item label="单位">
          <el-input v-model="form.unit" placeholder="如：台/个/瓶" style="width:120px" />
        </el-form-item>
        <el-form-item label="零售价" prop="price">
          <el-input-number v-model="form.price" :min="0" :precision="2" style="width:100%" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio :value="1">上架</el-radio>
            <el-radio :value="0">下架</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible=false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'

const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const catOptions = ref([])
const dialogVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()

const query = reactive({ page: 1, pageSize: 20, name: '', categoryId: null })
const form = reactive({ id: null, productCode: '', name: '', categoryId: null, spec: '', unit: '', price: 0, status: 1 })
const rules = { productCode: [{ required: true, message: '请输入商品编码', trigger: 'blur' }], name: [{ required: true, message: '请输入商品名称', trigger: 'blur' }], price: [{ required: true, message: '请输入价格', trigger: 'blur' }] }
const dialogTitle = computed(() => isEdit.value ? '编辑商品' : '新增商品')
const fmt = (v) => v != null ? `¥${Number(v).toFixed(2)}` : ''

const fetchData = async () => {
  loading.value = true
  try { const res = await request.get('/retail/products', { params: query }); tableData.value = res.data?.list || []; total.value = res.data?.total || 0 }
  catch { tableData.value = [] } finally { loading.value = false }
}
const fetchCats = async () => {
  try { const res = await request.get('/retail/categories'); catOptions.value = res.data?.list || [] } catch { catOptions.value = [] }
}
const resetQuery = () => { Object.assign(query, { name: '', categoryId: null, page: 1 }); fetchData() }
const handleAdd = () => { isEdit.value = false; Object.assign(form, { id: null, productCode: '', name: '', categoryId: null, spec: '', unit: '', price: 0, status: 1 }); dialogVisible.value = true }
const handleEdit = (row) => { isEdit.value = true; Object.assign(form, { ...row }); dialogVisible.value = true }
const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) { await request.put(`/retail/products/${form.id}`, form) }
    else { await request.post('/retail/products', form) }
    ElMessage.success(isEdit.value ? '编辑成功' : '新增成功'); dialogVisible.value = false; fetchData()
  } finally { submitting.value = false }
}
const handleDelete = async (row) => {
  await ElMessageBox.confirm(`确定删除商品「${row.name}」？`, '提示', { type: 'warning' })
  await request.delete(`/retail/products/${row.id}`); ElMessage.success('删除成功'); fetchData()
}

onMounted(() => { fetchData(); fetchCats() })
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
