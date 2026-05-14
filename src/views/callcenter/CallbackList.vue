<template>
  <div class="page"><el-card><template #header><span>呼入呼出</span></template>
  <el-table :data="[]" stripe><el-table-column prop="caller" label="主叫"/>
  <el-table-column prop="callee" label="被叫"/><el-table-column prop="direction" label="方向"/>
  <el-table-column prop="duration" label="时长"/><el-table-column prop="status" label="状态"/></el-table></el-card></div>
</template>
<script setup></script>
<style scoped>.page{padding:16px}</style>
