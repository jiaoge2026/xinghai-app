<template>
  <table class="print-table" :class="{ striped }">
    <thead>
      <tr>
        <th v-for="col in columns" :key="col.key" :class="col.className">{{ col.label }}</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="(row, idx) in data" :key="idx" :class="row._class">
        <td v-for="col in columns" :key="col.key">{{ row[col.key] ?? '-' }}</td>
      </tr>
      <tr v-if="!data || data.length === 0">
        <td :colspan="columns.length" style="text-align:center;color:#999;">暂无数据</td>
      </tr>
    </tbody>
    <tfoot v-if="$slots.tfoot">
      <slot name="tfoot" />
    </tfoot>
  </table>
</template>

<script setup>
defineProps({
  columns: { type: Array, required: true }, // [{key, label, className}]
  data: { type: Array, default: () => [] },
  striped: { type: Boolean, default: false },
})
</script>

<style scoped>
.print-table { width: 100%; border-collapse: collapse; font-size: 11px; margin: 12px 0; table-layout: fixed; }
.print-table thead { display: table-header-group; }
.print-table th, .print-table td { border: 1px solid #333; padding: 5px 8px; text-align: center; vertical-align: middle; word-break: break-word; }
.print-table th { background: #f0f0f0 !important; font-weight: bold; white-space: nowrap; }
.print-table tr { page-break-inside: avoid; }
.print-table.striped tbody tr:nth-child(even) td { background: #fafafa; }
</style>
