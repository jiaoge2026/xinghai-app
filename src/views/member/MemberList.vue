<template>
  <div class="member-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>会员管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">注册会员</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="手机号">
          <el-input v-model="queryParams.phone" placeholder="手机号" clearable style="width:140px" />
        </el-form-item>
        <el-form-item label="会员等级">
          <el-select v-model="queryParams.level" placeholder="全部" clearable style="width:130px">
            <el-option v-for="item in LEVEL_OPTIONS" :key="item.value" :value="item.value" :label="item.label" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">搜索</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="memberNo" label="会员编号" width="150" />
        <el-table-column prop="name" label="姓名" min-width="100" />
        <el-table-column prop="phone" label="手机号" width="130" />
        <el-table-column prop="level" label="等级" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="getLevelTagType(row.level)" size="small">{{ row.level }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="points" label="积分" width="100" align="right" />
        <el-table-column prop="balance" label="储值余额" width="110" align="right">
          <template #default="{ row }">{{ formatBalance(row.balance) }}</template>
        </el-table-column>
        <el-table-column prop="totalAmount" label="累计消费" width="110" align="right" />
        <el-table-column prop="createTime" label="注册时间" width="170" />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="primary" link @click="handlePoints(row)">积分</el-button>
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
          @change="fetchMemberList"
        />
      </div>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="500px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="90px">
        <el-form-item label="姓名" prop="name">
          <el-input v-model="formData.name" placeholder="会员姓名" />
        </el-form-item>
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="formData.phone" placeholder="11位手机号" />
        </el-form-item>
        <el-form-item label="会员等级">
          <el-select v-model="formData.level" style="width:100%">
            <el-option v-for="item in LEVEL_OPTIONS" :key="item.value" :value="item.value" :label="item.label" />
          </el-select>
        </el-form-item>
        <el-form-item label="生日">
          <el-date-picker v-model="formData.birthday" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="formData.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>

    <!-- 积分弹窗 -->
    <el-dialog v-model="pointsVisible" title="积分管理" width="400px" destroy-on-close>
      <el-descriptions :column="1" border size="small">
        <el-descriptions-item label="会员">{{ currentMember.name }}</el-descriptions-item>
        <el-descriptions-item label="当前积分"><b style="color:#E6A23C">{{ currentMember.points }}</b></el-descriptions-item>
        <el-descriptions-item label="储值余额"><b>¥{{ formatBalance(currentMember.balance) }}</b></el-descriptions-item>
      </el-descriptions>
      <el-divider>积分变动</el-divider>
      <el-form :model="pointsForm" label-width="80px">
        <el-form-item label="变动类型">
          <el-radio-group v-model="pointsForm.type">
            <el-radio value="ADD">增加</el-radio>
            <el-radio value="SUB">扣除</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="积分数量">
          <el-input-number v-model="pointsForm.points" :min="1" style="width:100%" />
        </el-form-item>
        <el-form-item label="原因">
          <el-input v-model="pointsForm.reason" placeholder="积分变动原因" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="pointsVisible = false">取消</el-button>
        <el-button type="primary" @click="handlePointsSubmit">确认变动</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'

// ============ Constants ============
const LEVEL_OPTIONS = [
  { value: '钻石', label: '钻石会员' },
  { value: '金牌', label: '金牌会员' },
  { value: '银牌', label: '银牌会员' },
  { value: '普通', label: '普通会员' }
]

const LEVEL_TAG_TYPES = {
  '钻石': 'danger',
  '金牌': 'warning',
  '银牌': 'info',
  '普通': ''
}

const DEFAULT_FORM = {
  id: null,
  name: '',
  phone: '',
  level: '普通',
  birthday: '',
  remark: ''
}

// ============ API ============
const API = {
  list: (params) => request.get('/member/members', { params }),
  create: (data) => request.post('/member/members', data),
  update: (id, data) => request.put(`/member/members/${id}`, data),
  updatePoints: (id, data) => request.post(`/member/members/${id}/points`, data)
}

// ============ State ============
const loading = ref(false)
const submitting = ref(false)
const tableData = ref([])
const total = ref(0)
const dialogVisible = ref(false)
const pointsVisible = ref(false)
const isEdit = ref(false)
const formRef = ref()

let queryParams = reactive({
  page: 1,
  pageSize: 20,
  phone: '',
  level: ''
})

let formData = reactive({ ...DEFAULT_FORM })

const formRules = {
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  phone: [{ required: true, message: '请输入手机号', trigger: 'blur' }]
}

const currentMember = ref({})
let pointsForm = reactive({
  type: 'ADD',
  points: 0,
  reason: ''
})

// ============ Computed ============
const dialogTitle = computed(() => isEdit.value ? '编辑会员' : '注册会员')

// ============ Helpers ============
const getLevelTagType = (level) => LEVEL_TAG_TYPES[level] || ''

const formatBalance = (balance) => {
  return `¥${Number(balance ?? 0).toFixed(2)}`
}

const resetForm = () => {
  Object.assign(formData, DEFAULT_FORM)
}

const resetPointsForm = () => {
  pointsForm.type = 'ADD'
  pointsForm.points = 0
  pointsForm.reason = ''
}

// ============ Data Fetching ============
const fetchMemberList = async () => {
  loading.value = true
  try {
    const res = await API.list(queryParams)
    tableData.value = res.data?.list || []
    total.value = res.data?.total || 0
  } catch (e) {
    ElMessage.error('获取会员列表失败')
    tableData.value = []
  } finally {
    loading.value = false
  }
}

// ============ Event Handlers ============
const handleSearch = () => {
  queryParams.page = 1
  fetchMemberList()
}

const handleReset = () => {
  Object.assign(queryParams, { phone: '', level: '', page: 1 })
  fetchMemberList()
}

const handleAdd = () => {
  isEdit.value = false
  resetForm()
  dialogVisible.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  Object.assign(formData, row)
  dialogVisible.value = true
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  submitting.value = true
  try {
    if (isEdit.value) {
      await API.update(formData.id, formData)
      ElMessage.success('编辑成功')
    } else {
      await API.create(formData)
      ElMessage.success('注册成功')
    }
    dialogVisible.value = false
    fetchMemberList()
  } catch (e) {
    ElMessage.error(isEdit.value ? '编辑失败' : '注册失败')
  } finally {
    submitting.value = false
  }
}

const handlePoints = (row) => {
  currentMember.value = { ...row }
  resetPointsForm()
  pointsVisible.value = true
}

const handlePointsSubmit = async () => {
  if (pointsForm.points <= 0) {
    ElMessage.warning('请输入有效的积分数量')
    return
  }
  try {
    await API.updatePoints(currentMember.value.id, pointsForm)
    ElMessage.success('积分变动已记录')
    pointsVisible.value = false
    fetchMemberList()
  } catch (e) {
    ElMessage.error('积分变动失败')
  }
}

// ============ Lifecycle ============
onMounted(fetchMemberList)
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
