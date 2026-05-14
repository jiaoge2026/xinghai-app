<template>
  <div class="sales-order-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>销售订单</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新建订单</el-button>
        </div>
      </template>

      <el-form :inline="true" class="search-form">
        <el-form-item label="订单号">
          <el-input v-model="query.orderNo" placeholder="订单号" clearable style="width:160px" />
        </el-form-item>
        <el-form-item label="门店">
          <el-select v-model="query.storeId" placeholder="全部门店" clearable style="width:160px">
            <el-option v-for="s in storeOptions" :key="s.id" :value="s.id" :label="s.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="全部" clearable style="width:130px">
            <el-option :value="1" label="待支付" />
            <el-option :value="2" label="已支付" />
            <el-option :value="3" label="已完成" />
            <el-option :value="4" label="已退款" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="fetchData">搜索</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="orderNo" label="订单号" width="180" />
        <el-table-column prop="storeName" label="门店" min-width="150" />
        <el-table-column prop="customerName" label="客户" min-width="100" />
        <el-table-column prop="totalAmount" label="订单金额" width="120" align="right">
          <template #default="{ row }">{{ fmt(row.totalAmount) }}</template>
        </el-table-column>
        <el-table-column prop="discountAmount" label="优惠" width="90" align="right">
          <template #default="{ row }">-{{ fmt(row.discountAmount) }}</template>
        </el-table-column>
        <el-table-column prop="actualAmount" label="实收" width="120" align="right">
          <template #default="{ row }"><b>{{ fmt(row.actualAmount) }}</b></template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="statusType[row.status]" size="small">{{ statusLabel[row.status] }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="下单时间" width="170" />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleView(row)">详情</el-button>
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

    <!-- 详情弹窗 -->
    <el-dialog v-model="viewVisible" title="订单详情" width="650px" destroy-on-close>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="订单号" :span="2">{{ viewData.orderNo }}</el-descriptions-item>
        <el-descriptions-item label="门店">{{ viewData.storeName }}</el-descriptions-item>
        <el-descriptions-item label="客户">{{ viewData.customerName }}</el-descriptions-item>
        <el-descriptions-item label="订单金额">{{ fmt(viewData.totalAmount) }}</el-descriptions-item>
        <el-descriptions-item label="优惠">{{ fmt(viewData.discountAmount) }}</el-descriptions-item>
        <el-descriptions-item label="实收金额"><b>{{ fmt(viewData.actualAmount) }}</b></el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="statusType[viewData.status]">{{ statusLabel[viewData.status] }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="下单时间">{{ viewData.createTime }}</el-descriptions-item>
      </el-descriptions>
      <el-divider>订单明细</el-divider>
      <el-table :data="viewData.items || []" stripe size="small">
        <el-table-column prop="productName" label="商品" min-width="150" />
        <el-table-column prop="spec" label="规格" min-width="100" />
        <el-table-column prop="price" label="单价" width="90" align="right">{{ fmt(viewData.price) }}</el-table-column>
        <el-table-column prop="quantity" label="数量" width="80" align="center" />
        <el-table-column prop="subtotal" label="小计" width="100" align="right"><template #default="{ row }">{{ fmt(row.subtotal) }}</template></el-table-column>
      </el-table>
    </el-dialog>

    <!-- 新建订单弹窗 -->
    <el-dialog v-model="dialogVisible" title="新建订单" width="600px" destroy-on-close>
      <el-form :model="orderForm" label-width="90px">
        <el-form-item label="门店" required>
          <el-select v-model="orderForm.storeId" placeholder="选择门店" style="width:100%">
            <el-option v-for="s in storeOptions" :key="s.id" :value="s.id" :label="s.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="客户">
          <el-input v-model="orderForm.customerName" placeholder="客户姓名（可选）" />
        </el-form-item>
        <el-form-item label="支付方式">
          <el-select v-model="orderForm.payMethod" style="width:100%">
            <el-option value="CASH" label="现金" />
            <el-option value="WECHAT" label="微信支付" />
            <el-option value="ALIPAY" label="支付宝" />
            <el-option value="CARD" label="银行卡" />
            <el-option value="MEMBER" label="会员卡" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="orderForm.remark" type="textarea" :rows="2" placeholder="备注信息" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible=false">取消</el-button>
        <el-button type="primary" @click="dialogVisible=false; ElMessage.success('订单创建功能开发中')">确认创建</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'

const statusLabel = { 1: '待支付', 2: '已支付', 3: '已完成', 4: '已退款' }
const statusType = { 1: 'warning', 2: 'primary', 3: 'success', 4: 'info' }
const loading = ref(false)
const tableData = ref([])
const total = ref(0)
const storeOptions = ref([])
const dialogVisible = ref(false)
const viewVisible = ref(false)
const viewData = ref({})
const orderForm = reactive({ storeId: null, customerName: '', payMethod: 'WECHAT', remark: '' })

const query = reactive({ page: 1, pageSize: 20, orderNo: '', storeId: null, status: null })
const fmt = (v) => v != null ? `¥${Number(v).toFixed(2)}` : '¥0.00'

const fetchData = async () => {
  loading.value = true
  try { const res = await request.get('/retail/orders/page', { params: query }); tableData.value = res.data?.list || []; total.value = res.data?.total || 0 }
  catch { tableData.value = [] } finally { loading.value = false }
}
const fetchStores = async () => {
  try { const res = await request.get('/retail/stores'); storeOptions.value = res.data?.list || [] } catch { storeOptions.value = [] }
}
const resetQuery = () => { Object.assign(query, { orderNo: '', storeId: null, status: null, page: 1 }); fetchData() }
const handleView = (row) => { viewData.value = { ...row }; viewVisible.value = true }
const handleAdd = () => { dialogVisible.value = true }

onMounted(() => { fetchData(); fetchStores() })
</script>

<style scoped>
.card-header { display:flex; justify-content:space-between; align-items:center; }
.search-form { margin-bottom: 12px; }
.pagination { margin-top: 16px; display:flex; justify-content:flex-end; }
</style>
