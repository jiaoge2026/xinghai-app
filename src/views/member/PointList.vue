<template>
  <div class="page"><el-card><template #header><span>会员积分</span></template>
  <el-table :data="[]" stripe><el-table-column prop="memberName" label="会员"/>
  <el-table-column prop="points" label="积分"/><el-table-column prop="balance" label="余额"/>
  <el-table-column prop="expireDate" label="过期日期"/></el-table></el-card></div>
</template>
<script setup></script>
<style scoped>.page{padding:16px}</style>
