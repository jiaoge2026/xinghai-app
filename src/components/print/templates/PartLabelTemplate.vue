<template>
  <div class="print-template">
    <slot />
  </div>
</template>
<script setup>
defineProps({ data: { type: Object, default: () => ({}) } })
</script>
