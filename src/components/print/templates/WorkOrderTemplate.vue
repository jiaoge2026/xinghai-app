<template>
  <div class="print-work-order">
    <!-- 公司头部 -->
    <PrintHeader
      title="海尔服务工单"
      :doc-no="data.woNo || data.hsicrmWorkorderid"
      :doc-date="data._printDate"
      :operator="data._printEngineer"
    />
    
    <!-- 主信息区 -->
    <div class="info-grid">
      <div class="info-item"><label>客户姓名：</label><span>{{ data._printCustomer }}</span></div>
      <div class="info-item"><label>联系电话：</label><span>{{ data._printPhone }}</span></div>
      <div class="info-item full"><label>服务地址：</label><span>{{ data._printAddress }}</span></div>
      <div class="info-item"><label>服务类型：</label><span>{{ data._printServiceType }}</span></div>
      <div class="info-item"><label>工单状态：</label><span>{{ data._printStatus }}</span></div>
    </div>

    <!-- 服务明细 -->
    <PrintTable :columns="columns" :data="items" striped>
      <template #tfoot>
        <tr>
          <td colspan="3" style="text-align:right;font-weight:bold;">合计：</td>
          <td style="text-align:right;font-weight:bold;">¥{{ data._printFee }}</td>
        </tr>
      </template>
    </PrintTable>

    <!-- 费用汇总 -->
    <PrintSummary
      :items="[{label:'收款金额', value:'¥' + data._printFee}]"
      :amount="data._printFee"
    />

    <!-- 备注 -->
    <div class="remark" v-if="data._printRemark">
      <strong>备注：</strong>{{ data._printRemark }}
    </div>

    <!-- 签名区 -->
    <PrintSignature :fields="['工程师', '客户签字']" :date-value="data._printDate" />

    <!-- 条码 -->
    <div class="print-footer-bar">
      <PrintBarcode :value="data._printLabel" />
      <PrintQRCode :value="verifyUrl" :show-label="true" />
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import PrintHeader from '../fields/PrintHeader.vue'
import PrintTable from '../fields/PrintTable.vue'
import PrintSummary from '../fields/PrintSummary.vue'
import PrintSignature from '../fields/PrintSignature.vue'
import PrintBarcode from '../fields/PrintBarcode.vue'
import PrintQRCode from '../fields/PrintQRCode.vue'

const props = defineProps({ data: { type: Object, default: () => ({}) } })

const verifyUrl = computed(() => {
  return `https://fuwu.jsh.com/verify/${props.data._printLabel}`
})

const columns = [
  { key: '_seq', label: '序号', className: 'col-seq' },
  { key: '_serviceItem', label: '服务项目', className: 'col-item' },
  { key: '_quantity', label: '数量', className: 'col-qty' },
  { key: '_fee', label: '费用', className: 'col-fee' },
]

const items = computed(() => [{
  _seq: 1,
  _serviceItem: props.data._printServiceType || '综合服务',
  _quantity: 1,
  _fee: props.data._printFee,
}])
</script>

<style scoped>
.print-work-order { padding: 20px; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 24px; margin-bottom: 16px; }
.info-item { display: flex; font-size: 12px; }
.info-item.full { grid-column: 1 / -1; }
.info-item label { font-weight: bold; color: #555; min-width: 70px; }
.remark { font-size: 12px; color: #555; margin: 12px 0; padding: 8px; background: #f9f9f9; border-left: 3px solid #ccc; }
.print-footer-bar { display: flex; justify-content: space-between; align-items: center; margin-top: 16px; padding-top: 12px; border-top: 1px dashed #ccc; }
.col-seq { width: 50px; }
.col-item { }
.col-qty { width: 60px; }
.col-fee { width: 80px; }
</style>
