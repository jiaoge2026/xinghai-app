<template>
  <div class="warehouse-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>仓库管理</span>
          <el-button type="primary" @click="openAdd">新增仓库</el-button>
        </div>
      </template>
      <el-table v-loading="loading" :data="tableData" stripe style="width: 100%">
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
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>

      <!-- 新增/编辑弹窗 -->
      <el-dialog v-model="dialogVisible" :title="formMode === 'add' ? '新增仓库' : '编辑仓库'" width="500px">
        <el-form ref="formRef" :model="form" :rules="formRules" label-width="100px">
          <el-form-item label="仓库编码" prop="code">
            <el-input v-model="form.code" maxlength="20" :disabled="formMode === 'edit'" />
          </el-form-item>
          <el-form-item label="仓库名称" prop="name">
            <el-input v-model="form.name" maxlength="100" />
          </el-form-item>
          <el-form-item label="仓库地址" prop="address">
            <el-input v-model="form.address" maxlength="200" />
          </el-form-item>
          <el-form-item label="负责人" prop="manager">
            <el-input v-model="form.manager" maxlength="50" />
          </el-form-item>
          <el-form-item label="联系电话" prop="phone">
            <el-input v-model="form.phone" maxlength="20" />
          </el-form-item>
          <el-form-item label="容量" prop="capacity">
            <el-input-number v-model="form.capacity" :min="0" :controls="false" style="width:150px" />
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
          <el-button type="primary" @click="handleSubmit">确定</el-button>
        </template>
      </el-dialog>

</template>

<script setup>
import { ref, onMounted } from 'vue'
import request from '@/utils/request'

const tableData = ref([])
const loading = ref(false)
const dialogVisible = ref(false)
const formRef = ref()
const formMode = ref('add')
const form = ref({ id: null, code: '', name: '', address: '', manager: '', phone: '', capacity: null, status: 1 })
const formRules = {
  code: [{ required: true, message: '请输入仓库编码', trigger: 'blur' }],
  name: [{ required: true, message: '请输入仓库名称', trigger: 'blur' }]
}

const fetchData = async () => {
  loading.value = true
  try {
    const res = await request.get('/wms/warehouses')
    tableData.value = res.data?.list || res.data || []
  } finally {
    loading.value = false
  }
}

const openAdd = () => {
  formMode.value = 'add'
  form.value = { id: null, code: '', name: '', address: '', manager: '', phone: '', capacity: null, status: 1 }
  dialogVisible.value = true
}

const openEdit = (row) => {
  formMode.value = 'edit'
  form.value = { ...row }
  dialogVisible.value = true
}

const handleSubmit = async () => {
  await formRef.value.validate()
  if (formMode.value === 'add') {
    await request.post('/wms/warehouses', form.value)
  } else {
    await request.put('/wms/warehouses/' + form.value.id, form.value)
  }
  dialogVisible.value = false
  fetchData()
}

const handleDelete = async (row) => {
  await request.delete('/wms/warehouses/' + row.id)
  fetchData()
}

onMounted(() => { fetchData() })
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>