<template>
  <div class="print-summary">
    <div class="summary-row" v-for="item in items" :key="item.label">
      <span class="label">{{ item.label }}</span>
      <span class="value" :class="item.className">{{ item.value }}</span>
    </div>
    <div class="amount-cn" v-if="showChinese && amount !== undefined">
      大写：{{ chineseAmount }}
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { toChineseAmount } from '../utils/chineseAmount.js'

const props = defineProps({
  items: { type: Array, default: () => [] }, // [{label, value, className}]
  amount: { type: [Number, String], default: undefined },
  showChinese: { type: Boolean, default: true },
})

const chineseAmount = computed(() => toChineseAmount(props.amount))
</script>

<style scoped>
.print-summary { margin: 16px 0; padding: 12px 0; border-top: 2px solid #333; border-bottom: 1px solid #333; }
.summary-row { display: flex; justify-content: flex-end; gap: 24px; font-size: 12px; margin-bottom: 6px; }
.summary-row:last-of-type { margin-bottom: 0; }
.summary-row .label { font-weight: bold; color: #333; }
.summary-row .value { min-width: 100px; text-align: right; }
.summary-row .value.total { color: #c00; font-size: 14px; font-weight: bold; }
.amount-cn { text-align: right; font-size: 13px; font-weight: bold; padding: 6px 0; border-top: 1px solid #eee; margin-top: 8px; }
</style>
