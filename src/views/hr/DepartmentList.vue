<template>
  <div class="page"><el-card><template #header><span>部门管理</span></template>
  <el-table :data="[]" stripe><el-table-column prop="name" label="部门名称"/>
  <el-table-column prop="parentName" label="上级部门"/><el-table-column prop="managerName" label="负责人"/></el-table></el-card></div>
</template>
<script setup>
import {ref} from 'vue'
import request from '@/utils/request'
const depts = ref([])
</script>
<style scoped>.page{padding:16px}</style>
