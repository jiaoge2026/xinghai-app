<template>
  <div class="page"><el-card><template #header><span>客户跟进</span></template>
  <el-table :data="[]" stripe><el-table-column prop="customerName" label="客户"/>
  <el-table-column prop="followUpTime" label="跟进时间"/><el-table-column prop="content" label="跟进内容"/>
  <el-table-column prop="nextTime" label="下次跟进"/></el-table></el-card></div>
</template>
<script setup></script>
<style scoped>.page{padding:16px}</style>
