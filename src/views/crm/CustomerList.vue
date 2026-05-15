<template>
  <div class="customer-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>客户管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增客户</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="客户名称">
          <el-input v-model="queryParams.name" placeholder="客户名称" clearable style="width:150px" />
        </el-form-item>
        <el-form-item label="客户类型">
          <el-select v-model="queryParams.type" placeholder="全部" clearable style="width:130px">
            <el-option :value="CUSTOMER_TYPE.PERSONAL" label="个人" />
            <el-option :value="CUSTOMER_TYPE.ENTERPRISE" label="企业" />
          </el-select>
        </el-form-item>
        <el-form-item label="客户等级">
          <el-select v-model="queryParams.level" placeholder="全部" clearable style="width:120px">
            <el-option :value="CUSTOMER_LEVEL.A" label="A类" />
            <el-option :value="CUSTOMER_LEVEL.B" label="B类" />
            <el-option :value="CUSTOMER_LEVEL.C" label="C类" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">搜索</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="name" label="客户名称" min-width="180" />
        <el-table-column prop="type" label="类型" width="90" align="center">
          <template #default="{ row }">{{ formatType(row.type) }}</template>
        </el-table-column>
        <el-table-column prop="level" label="等级" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="getLevelTagType(row.level)" size="small">{{ row.level }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="contactName" label="联系人" min-width="100" />
        <el-table-column prop="contactPhone" label="联系电话" width="130" />
        <el-table-column prop="address" label="地址" min-width="200" show-overflow-tooltip />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleView(row)">详情</el-button>
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination">
        <el-pagination
          v-model:current-page="queryParams.page"
          v-model:page-size="queryParams.pageSize"
          :total="total"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next"
          @change="fetchCustomerList"
        />
      </div>
    </el-card>

    <!-- 详情弹窗 -->
    <el-dialog v-model="viewDialogVisible" title="客户详情" width="600px" destroy-on-close>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="客户名称" :span="2">{{ viewData.name }}</el-descriptions-item>
        <el-descriptions-item label="类型">{{ formatType(viewData.type) }}</el-descriptions-item>
        <el-descriptions-item label="等级">
          <el-tag :type="getLevelTagType(viewData.level)">{{ viewData.level }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="联系人">{{ viewData.contactName }}</el-descriptions-item>
        <el-descriptions-item label="联系电话">{{ viewData.contactPhone }}</el-descriptions-item>
        <el-descriptions-item label="地址" :span="2">{{ viewData.address }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewData.remark }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="formDialogVisible" :title="dialogTitle" width="550px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="客户名称" prop="name">
          <el-input v-model="formData.name" placeholder="客户名称" />
        </el-form-item>
        <el-form-item label="客户类型" prop="type">
          <el-radio-group v-model="formData.type">
            <el-radio :value="CUSTOMER_TYPE.PERSONAL">个人</el-radio>
            <el-radio :value="CUSTOMER_TYPE.ENTERPRISE">企业</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="客户等级">
          <el-select v-model="formData.level" style="width:100%">
            <el-option :value="CUSTOMER_LEVEL.A" label="A类（重要客户）" />
            <el-option :value="CUSTOMER_LEVEL.B" label="B类（普通客户）" />
            <el-option :value="CUSTOMER_LEVEL.C" label="C类（潜在客户）" />
          </el-select>
        </el-form-item>
        <el-form-item label="联系人" prop="contactName">
          <el-input v-model="formData.contactName" placeholder="联系人姓名" />
        </el-form-item>
        <el-form-item label="联系电话" prop="contactPhone">
          <el-input v-model="formData.contactPhone" placeholder="手机或座机" />
        </el-form-item>
        <el-form-item label="地址">
          <el-input v-model="formData.address" type="textarea" :rows="2" placeholder="详细地址" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="formData.remark" type="textarea" :rows="2" placeholder="备注信息" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="formDialogVisible = false">取消</el-button>
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

// ============ 常量定义 ============
const CUSTOMER_API = '/crm/customers'

const CUSTOMER_TYPE = {
  PERSONAL: 1,
  ENTERPRISE: 2
}

const CUSTOMER_LEVEL = {
  A: 'A',
  B: 'B',
  C: 'C'
}

const LEVEL_TAG_MAP = {
  A: 'danger',
  B: 'warning',
  C: 'info'
}

// ============ 状态定义 ============
const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const formDialogVisible = ref(false)
const viewDialogVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()
const viewData = ref({})

// 查询参数
const queryParams = reactive({
  page: 1,
  pageSize: 20,
  name: '',
  type: null,
  level: ''
})

// 表单数据
const formData = reactive({
  id: null,
  name: '',
  type: CUSTOMER_TYPE.PERSONAL,
  level: CUSTOMER_LEVEL.B,
  contactName: '',
  contactPhone: '',
  address: '',
  remark: ''
})

// 表单验证规则
const formRules = {
  name: [{ required: true, message: '请输入客户名称', trigger: 'blur' }],
  contactName: [{ required: true, message: '请输入联系人', trigger: 'blur' }],
  contactPhone: [{ required: true, message: '请输入联系电话', trigger: 'blur' }]
}

// ============ 计算属性 ============
const dialogTitle = computed(() => isEdit.value ? '编辑客户' : '新增客户')

// ============ 方法 ============

/**
 * 格式化客户类型显示
 */
function formatType(type) {
  return type === CUSTOMER_TYPE.PERSONAL ? '个人' : '企业'
}

/**
 * 获取等级标签类型
 */
function getLevelTagType(level) {
  return LEVEL_TAG_MAP[level] || 'info'
}

/**
 * 获取空白表单数据
 */
function getEmptyForm() {
  return {
    id: null,
    name: '',
    type: CUSTOMER_TYPE.PERSONAL,
    level: CUSTOMER_LEVEL.B,
    contactName: '',
    contactPhone: '',
    address: '',
    remark: ''
  }
}

/**
 * 获取查询参数（过滤空值）
 */
function getQueryParams() {
  const params = { ...queryParams }
  if (params.type === null) delete params.type
  if (!params.level) delete params.level
  return params
}

/**
 * 获取客户列表
 */
async function fetchCustomerList() {
  loading.value = true
  try {
    const params = getQueryParams()
    const res = await request.get(CUSTOMER_API, { params })
    tableData.value = res.data?.list || []
    total.value = res.data?.total || 0
  } catch {
    tableData.value = []
    ElMessage.error('获取客户列表失败')
  } finally {
    loading.value = false
  }
}

/**
 * 重置查询条件
 */
function handleReset() {
  Object.assign(queryParams, {
    name: '',
    type: null,
    level: '',
    page: 1
  })
  fetchCustomerList()
}

/**
 * 搜索（重置到第一页后查询）
 */
function handleSearch() {
  queryParams.page = 1
  fetchCustomerList()
}

/**
 * 打开新增弹窗
 */
function handleAdd() {
  isEdit.value = false
  Object.assign(formData, getEmptyForm())
  formDialogVisible.value = true
}

/**
 * 打开编辑弹窗
 */
function handleEdit(row) {
  isEdit.value = true
  Object.assign(formData, { ...row })
  formDialogVisible.value = true
}

/**
 * 打开详情弹窗
 */
function handleView(row) {
  viewData.value = { ...row }
  viewDialogVisible.value = true
}

/**
 * 提交表单
 */
async function handleSubmit() {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  submitting.value = true
  try {
    if (isEdit.value) {
      await request.put(`${CUSTOMER_API}/${formData.id}`, formData)
      ElMessage.success('编辑成功')
    } else {
      await request.post(CUSTOMER_API, formData)
      ElMessage.success('新增成功')
    }
    formDialogVisible.value = false
    fetchCustomerList()
  } catch (err) {
    ElMessage.error(isEdit.value ? '编辑失败' : '新增失败')
  } finally {
    submitting.value = false
  }
}

/**
 * 删除客户
 */
async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除客户「${row.name}」？`, '提示', { type: 'warning' })
    await request.delete(`${CUSTOMER_API}/${row.id}`)
    ElMessage.success('删除成功')
    fetchCustomerList()
  } catch (err) {
    if (err !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// ============ 生命周期 ============
onMounted(fetchCustomerList)
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.search-form {
  margin-bottom: 12px;
}
.pagination {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}
</style>
