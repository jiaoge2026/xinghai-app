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
          <el-input v-model="query.phone" placeholder="手机号" clearable style="width:140px" />
        </el-form-item>
        <el-form-item label="会员等级">
          <el-select v-model="query.level" placeholder="全部" clearable style="width:130px">
            <el-option value="钻石" label="钻石会员" />
            <el-option value="金牌" label="金牌会员" />
            <el-option value="银牌" label="银牌会员" />
            <el-option value="普通" label="普通会员" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="memberNo" label="会员编号" width="150" />
        <el-table-column prop="name" label="姓名" min-width="100" />
        <el-table-column prop="phone" label="手机号" width="130" />
        <el-table-column prop="level" label="等级" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="levelType[row.level]" size="small">{{ row.level }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="points" label="积分" width="100" align="right" />
        <el-table-column prop="balance" label="储值余额" width="110" align="right">
          <template #default="{ row }">{{ row.balance != null ? `¥${Number(row.balance).toFixed(2)}` : '¥0.00' }}</template>
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
          v-model:current-page="query.page"
          v-model:page-size="query.pageSize"
          :total="total"
          :page-sizes="[10,20,50]"
          layout="total,sizes,prev,pager,next"
          @change="fetchData"
        />
      </div>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="500px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="姓名" prop="name">
          <el-input v-model="form.name" placeholder="会员姓名" />
        </el-form-item>
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="form.phone" placeholder="11位手机号" />
        </el-form-item>
        <el-form-item label="会员等级">
          <el-select v-model="form.level" style="width:100%">
            <el-option value="钻石" label="钻石会员" />
            <el-option value="金牌" label="金牌会员" />
            <el-option value="银牌" label="银牌会员" />
            <el-option value="普通" label="普通会员" />
          </el-select>
        </el-form-item>
        <el-form-item label="生日">
          <el-date-picker v-model="form.birthday" type="date" value-format="YYYY-MM-DD" style="width:100%" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible=false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>

    <!-- 积分弹窗 -->
    <el-dialog v-model="pointsVisible" title="积分管理" width="400px" destroy-on-close>
      <el-descriptions :column="1" border size="small">
        <el-descriptions-item label="会员">{{ pointsData.name }}</el-descriptions-item>
        <el-descriptions-item label="当前积分"><b style="color:#E6A23C">{{ pointsData.points }}</b></el-descriptions-item>
        <el-descriptions-item label="储值余额"><b>¥{{ Number(pointsData.balance || 0).toFixed(2) }}</b></el-descriptions-item>
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
        <el-button @click="pointsVisible=false">取消</el-button>
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

const levelType = { '钻石': 'danger', '金牌': 'warning', '银牌': 'info', '普通': '' }
const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const dialogVisible = ref(false)
const pointsVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()
const pointsData = ref({})
const pointsForm = reactive({ type: 'ADD', points: 0, reason: '' })

const query = reactive({ page: 1, pageSize: 20, phone: '', level: '' })
const form = reactive({ id: null, name: '', phone: '', level: '普通', birthday: '', remark: '' })
const rules = { name: [{ required: true, message: '请输入姓名', trigger: 'blur' }], phone: [{ required: true, message: '请输入手机号', trigger: 'blur' }] }
const dialogTitle = computed(() => isEdit.value ? '编辑会员' : '注册会员')

const fetchData = async () => {
  loading.value = true
  try { const res = await request.get('/member/members', { params: query }); tableData.value = res.data?.list || []; total.value = res.data?.total || 0 }
  catch { tableData.value = [] } finally { loading.value = false }
}
const resetQuery = () => { Object.assign(query, { phone: '', level: '', page: 1 }); fetchData() }
const handleAdd = () => { isEdit.value = false; Object.assign(form, { id: null, name: '', phone: '', level: '普通', birthday: '', remark: '' }); dialogVisible.value = true }
const handleEdit = (row) => { isEdit.value = true; Object.assign(form, { ...row }); dialogVisible.value = true }
const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) { await request.put(`/member/members/${form.id}`, form) }
    else { await request.post('/member/members', form) }
    ElMessage.success(isEdit.value ? '编辑成功' : '注册成功'); dialogVisible.value = false; fetchData()
  } finally { submitting.value = false }
}
const handlePoints = (row) => { pointsData.value = { ...row }; pointsForm.type = 'ADD'; pointsForm.points = 0; pointsForm.reason = ''; pointsVisible.value = true }
const handlePointsSubmit = async () => {
  await request.post(`/member/members/${pointsData.value.id}/points`, pointsForm)
  ElMessage.success('积分变动已记录'); pointsVisible.value = false; fetchData()
}

onMounted(fetchData)
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
