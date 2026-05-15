<template>
  <div class="print-signature">
    <div class="signature-grid" :class="'cols-' + fields.length">
      <div class="signature-item" v-for="field in fields" :key="field">
        <div class="sign-label">{{ field }}</div>
        <div class="sign-line"></div>
        <div class="sign-date">日期：{{ formattedDate }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  fields: { type: Array, default: () => ['制单人', '审核人', '客户签字'] },
  dateValue: { type: String, default: '' },
})

const formattedDate = computed(() => props.dateValue || new Date().toLocaleDateString('zh-CN'))
</script>

<style scoped>
.print-signature { margin: 24px 0 16px; }
.signature-grid { display: flex; justify-content: space-around; gap: 16px; }
.signature-grid.cols-2 { justify-content: space-between; }
.signature-grid.cols-4 { justify-content: space-between; }
.signature-item { text-align: center; min-width: 100px; flex: 1; }
.sign-label { font-size: 11px; color: #555; margin-bottom: 4px; font-weight: normal; }
.sign-line { display: block; height: 28px; border-bottom: 1px solid #333; margin-bottom: 4px; }
.sign-date { font-size: 10px; color: #555; }
</style>
