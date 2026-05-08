<template>
  <div class="work-order-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>工单管理</span>
          <el-button type="primary" @click="openAdd">新建工单</el-button>
        </div>
      </template>
      <!-- 搜索筛选区 -->
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="工单编号">
          <el-input v-model="searchForm.orderNo" placeholder="请输入工单编号" clearable style="width: 180px" />
        </el-form-item>
        <el-form-item label="客户名称">
          <el-input v-model="searchForm.customerName" placeholder="请输入客户名称" clearable style="width: 160px" />
        </el-form-item>
        <el-form-item label="工单状态">
          <el-select v-model="searchForm.status" placeholder="请选择状态" clearable style="width: 140px">
            <el-option label="待派单" :value="1" />
            <el-option label="已派单" :value="2" />
            <el-option label="进行中" :value="3" />
            <el-option label="待结算" :value="4" />
            <el-option label="已完成" :value="5" />
            <el-option label="已取消" :value="6" />
          </el-select>
        </el-form-item>
        <el-form-item label="日期范围">
          <el-date-picker
            v-model="searchForm.dateRange"
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

      <!-- 表格区 -->
      <el-table v-loading="loading" :data="tableData" stripe style="width: 100%">
        <el-table-column prop="orderNo" label="工单编号" width="150" />
        <el-table-column prop="title" label="工单标题" min-width="180" show-overflow-tooltip />
        <el-table-column prop="customerName" label="客户名称" width="140" show-overflow-tooltip />
        <el-table-column prop="type" label="工单类型" width="100">
          <template #default="{ row }">
            <el-tag>{{ getTypeText(row.type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="engineerName" label="工程师" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">{{ getStatusText(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="170" />
        <el-table-column label="操作" width="220" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openDetail(row)">详情</el-button>
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
        :title="formMode === 'add' ? '新增工单' : '编辑工单'"
        width="600px"
        :close-on-click-modal="false"
      >
        <el-form ref="formRef" :model="form" :rules="formRules" label-width="100px">
          <el-form-item label="工单标题" prop="title">
            <el-input v-model="form.title" placeholder="请输入工单标题" maxlength="100" />
          </el-form-item>
          <el-form-item label="客户名称" prop="customerName">
            <el-input v-model="form.customerName" placeholder="请输入客户名称" maxlength="50" />
          </el-form-item>
          <el-form-item label="客户电话" prop="customerPhone">
            <el-input v-model="form.customerPhone" placeholder="请输入客户电话" maxlength="20" />
          </el-form-item>
          <el-form-item label="客户地址" prop="customerAddress">
            <el-input v-model="form.customerAddress" placeholder="请输入客户地址" maxlength="200" type="textarea" :rows="2" />
          </el-form-item>
          <el-form-item label="工单类型" prop="type">
            <el-select v-model="form.type" placeholder="请选择工单类型" style="width: 100%">
              <el-option label="安装" :value="1" />
              <el-option label="维修" :value="2" />
              <el-option label="保养" :value="3" />
              <el-option label="巡检" :value="4" />
            </el-select>
          </el-form-item>
          <el-form-item label="派单工程师" prop="engineerId">
            <el-select v-model="form.engineerId" placeholder="请选择工程师" clearable style="width: 100%">
              <el-option
                v-for="eng in engineerList"
                :key="eng.id"
                :label="eng.name"
                :value="eng.id"
              />
            </el-select>
          </el-form-item>
          <el-form-item label="工单状态" prop="status">
            <el-select v-model="form.status" placeholder="请选择状态" style="width: 100%">
              <el-option label="待派单" :value="1" />
              <el-option label="已派单" :value="2" />
              <el-option label="进行中" :value="3" />
              <el-option label="待结算" :value="4" />
              <el-option label="已完成" :value="5" />
              <el-option label="已取消" :value="6" />
            </el-select>
          </el-form-item>
          <el-form-item label="工单描述" prop="description">
            <el-input v-model="form.description" placeholder="请输入工单描述" type="textarea" :rows="3" maxlength="500" show-word-limit />
          </el-form-item>
        </el-form>
        <template #footer>
          <el-button @click="formDialogVisible = false">取消</el-button>
          <el-button type="primary" :loading="submitLoading" @click="handleSubmit">确定</el-button>
        </template>
      </el-dialog>

      <!-- 详情弹窗 -->
      <el-dialog v-model="detailDialogVisible" title="工单详情" width="600px">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="工单编号">{{ detailData.orderNo }}</el-descriptions-item>
          <el-descriptions-item label="工单状态">
            <el-tag :type="getStatusType(detailData.status)">{{ getStatusText(detailData.status) }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="工单标题" :span="2">{{ detailData.title }}</el-descriptions-item>
          <el-descriptions-item label="工单类型">{{ getTypeText(detailData.type) }}</el-descriptions-item>
          <el-descriptions-item label="派单工程师">{{ detailData.engineerName || '-' }}</el-descriptions-item>
          <el-descriptions-item label="客户名称">{{ detailData.customerName }}</el-descriptions-item>
          <el-descriptions-item label="客户电话">{{ detailData.customerPhone || '-' }}</el-descriptions-item>
          <el-descriptions-item label="客户地址" :span="2">{{ detailData.customerAddress || '-' }}</el-descriptions-item>
          <el-descriptions-item label="工单描述" :span="2">{{ detailData.description || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ detailData.createTime || '-' }}</el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ detailData.updateTime || '-' }}</el-descriptions-item>
        </el-descriptions>
        <template #footer>
          <el-button @click="detailDialogVisible = false">关闭</el-button>
        </template>
      </el-dialog>

      <!-- 删除确认弹窗 -->
      <el-dialog v-model="deleteDialogVisible" title="删除确认" width="400px">
        <p style="font-size: 16px">确认删除工单 <strong>{{ deleteData.orderNo }}</strong> 吗？此操作不可恢复。</p>
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

// ---------- 状态映射 ----------
const STATUS_MAP = {
  1: { text: '待派单', type: 'warning' },
  2: { text: '已派单', type: 'info' },
  3: { text: '进行中', type: 'primary' },
  4: { text: '待结算', type: 'success' },
  5: { text: '已完成', type: 'success' },
  6: { text: '已取消', type: 'info' }
}
const TYPE_MAP = { 1: '安装', 2: '维修', 3: '保养', 4: '巡检' }

const getStatusText = (status) => STATUS_MAP[status]?.text || '-'
const getStatusType = (status) => STATUS_MAP[status]?.type || 'info'
const getTypeText = (type) => TYPE_MAP[type] || '-'

// ---------- 表格数据 ----------
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 10, total: 0 })

// ---------- 搜索表单 ----------
const searchForm = reactive({
  orderNo: '',
  customerName: '',
  status: null,
  dateRange: null
})

const handleSearch = () => {
  pagination.page = 1
  fetchData()
}

const handleReset = () => {
  searchForm.orderNo = ''
  searchForm.customerName = ''
  searchForm.status = null
  searchForm.dateRange = null
  handleSearch()
}

// ---------- 获取工单列表 ----------
const fetchData = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      pageSize: pagination.pageSize,
      orderNo: searchForm.orderNo || undefined,
      customerName: searchForm.customerName || undefined,
      status: searchForm.status || undefined,
      startDate: searchForm.dateRange?.[0] || undefined,
      endDate: searchForm.dateRange?.[1] || undefined
    }
    const res = await request.get('/fsm/work-orders', { params })
    tableData.value = res.data.list || []
    pagination.total = res.data.total || 0
  } catch (e) {
    console.error('fetchData error', e)
  } finally {
    loading.value = false
  }
}

// ---------- 工程师下拉 ----------
const engineerList = ref([])
const fetchEngineers = async () => {
  try {
    const res = await request.get('/fsm/engineers')
    engineerList.value = res.data || []
  } catch (e) {
    console.error('fetchEngineers error', e)
  }
}

// ---------- 初始化 ----------
onMounted(() => {
  fetchData()
  fetchEngineers()
})

// ---------- 新增/编辑表单 ----------
const formRef = ref(null)
const formDialogVisible = ref(false)
const submitLoading = ref(false)
const formMode = ref('add') // 'add' | 'edit'
const currentId = ref(null)

const defaultForm = () => ({
  title: '',
  customerName: '',
  customerPhone: '',
  customerAddress: '',
  type: null,
  engineerId: null,
  status: 1,
  description: ''
})

const form = reactive(defaultForm())

const formRules = {
  title: [{ required: true, message: '请输入工单标题', trigger: 'blur' }],
  customerName: [{ required: true, message: '请输入客户名称', trigger: 'blur' }],
  type: [{ required: true, message: '请选择工单类型', trigger: 'change' }]
}

const openAdd = () => {
  formMode.value = 'add'
  Object.assign(form, defaultForm())
  formDialogVisible.value = true
}

const openEdit = (row) => {
  formMode.value = 'edit'
  currentId.value = row.id
  request.get(`/fsm/work-orders/${row.id}`).then(res => {
    const data = res.data
    Object.assign(form, {
      title: data.title || '',
      customerName: data.customerName || '',
      customerPhone: data.customerPhone || '',
      customerAddress: data.customerAddress || '',
      type: data.type || null,
      engineerId: data.engineerId || null,
      status: data.status || 1,
      description: data.description || ''
    })
  }).catch(e => console.error(e))
  formDialogVisible.value = true
}

const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate(async (valid) => {
    if (!valid) return
    submitLoading.value = true
    try {
      if (formMode.value === 'add') {
        await request.post('/fsm/work-orders', form)
        ElMessage.success('新增成功')
      } else {
        await request.put(`/fsm/work-orders/${currentId.value}`, form)
        ElMessage.success('更新成功')
      }
      formDialogVisible.value = false
      fetchData()
    } catch (e) {
      console.error('submit error', e)
    } finally {
      submitLoading.value = false
    }
  })
}

// ---------- 详情 ----------
const detailDialogVisible = ref(false)
const detailData = reactive({})

const openDetail = (row) => {
  request.get(`/fsm/work-orders/${row.id}`).then(res => {
    Object.assign(detailData, res.data || {})
  }).catch(e => console.error(e))
  detailDialogVisible.value = true
}

// ---------- 删除 ----------
const deleteDialogVisible = ref(false)
const deleteLoading = ref(false)
const deleteData = reactive({ id: null, orderNo: '' })

const openDelete = (row) => {
  deleteData.id = row.id
  deleteData.orderNo = row.orderNo
  deleteDialogVisible.value = true
}

const handleDelete = async () => {
  deleteLoading.value = true
  try {
    await request.delete(`/fsm/work-orders/${deleteData.id}`)
    ElMessage.success('删除成功')
    deleteDialogVisible.value = false
    fetchData()
  } catch (e) {
    console.error('delete error', e)
  } finally {
    deleteLoading.value = false
  }
}
</script>

<style scoped>
.work-order-list {
  padding: 16px;
}
.search-form {
  margin-bottom: 16px;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
