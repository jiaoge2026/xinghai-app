<template>
  <div class="print-header">
    <div class="company-name">{{ companyName }}</div>
    <div class="document-title">{{ title }}</div>
    <div class="doc-meta" v-if="showMeta">
      <span v-if="docNo">单据编号：{{ docNo }}</span>
      <span v-if="docDate">日期：{{ docDate }}</span>
      <span v-if="operator">操作人：{{ operator }}</span>
      <span v-if="totalCount > 0">共 {{ totalCount }} 条</span>
    </div>
  </div>
</template>

<script setup>
defineProps({
  companyName: { type: String, default: '山东万欣和经贸有限公司' },
  title: { type: String, required: true },
  docNo: { type: String, default: '' },
  docDate: { type: String, default: '' },
  operator: { type: String, default: '' },
  totalCount: { type: [Number, String], default: 0 },
  showMeta: { type: Boolean, default: true },
})
</script>

<style scoped>
.print-header { text-align: center; margin-bottom: 20px; padding-bottom: 12px; border-bottom: 2px solid #333; }
.company-name { font-size: 18px; font-weight: bold; letter-spacing: 2px; }
.document-title { font-size: 20px; font-weight: bold; letter-spacing: 4px; margin: 8px 0; }
.doc-meta { display: flex; justify-content: center; gap: 24px; font-size: 11px; color: #555; margin-top: 6px; }
</style>
