<template>
  <div class="page"><el-card><template #header><span>请假申请</span></template>
  <el-table :data="[]" stripe><el-table-column prop="employeeName" label="员工"/>
  <el-table-column prop="leaveType" label="请假类型"/><el-table-column prop="days" label="天数"/>
  <el-table-column prop="status" label="状态"/></el-table></el-card></div>
</template>
<script setup></script>
<style scoped>.page{padding:16px}</style>
