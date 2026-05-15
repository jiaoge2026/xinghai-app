<template>
  <el-dialog v-model="visible" title="订单详情" width="650px" destroy-on-close>
    <el-descriptions :column="2" border>
      <el-descriptions-item label="订单号" :span="2">{{ order.orderNo }}</el-descriptions-item>
      <el-descriptions-item label="门店">{{ order.storeName }}</el-descriptions-item>
      <el-descriptions-item label="客户">{{ order.customerName || '-' }}</el-descriptions-item>
      <el-descriptions-item label="订单金额">{{ fmtCurrency(order.totalAmount) }}</el-descriptions-item>
      <el-descriptions-item label="优惠">{{ fmtCurrency(order.discountAmount) }}</el-descriptions-item>
      <el-descriptions-item label="实收金额"><b>{{ fmtCurrency(order.actualAmount) }}</b></el-descriptions-item>
      <el-descriptions-item label="状态">
        <el-tag :type="statusType[order.status]" size="small">{{ statusLabel[order.status] }}</el-tag>
      </el-descriptions-item>
      <el-descriptions-item label="下单时间">{{ order.createTime || '-' }}</el-descriptions-item>
    </el-descriptions>
    <el-divider>订单明细</el-divider>
    <el-table :data="order.items || []" stripe size="small">
      <el-table-column prop="productName" label="商品" min-width="150" />
      <el-table-column prop="spec" label="规格" min-width="100" />
      <el-table-column prop="price" label="单价" width="90" align="right">
        <template #default="{ row }">{{ fmtCurrency(row.price) }}</template>
      </el-table-column>
      <el-table-column prop="quantity" label="数量" width="80" align="center" />
      <el-table-column prop="subtotal" label="小计" width="100" align="right">
        <template #default="{ row }">{{ fmtCurrency(row.subtotal) }}</template>
      </el-table-column>
    </el-table>
  </el-dialog>
</template>

<script setup>
import { computed } from 'vue'
import { formatCurrency } from '@/utils/format'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false,
  },
  order: {
    type: Object,
    default: () => ({}),
  },
})

const emit = defineEmits(['update:modelValue'])

const visible = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})

const statusLabel = { 1: '待支付', 2: '已支付', 3: '已完成', 4: '已退款' }
const statusType = { 1: 'warning', 2: 'primary', 3: 'success', 4: 'info' }

const fmtCurrency = (v) => formatCurrency(v ?? 0)
</script>
