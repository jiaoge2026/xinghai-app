<template>
  <el-card class="filter-card">
    <el-form :model="localFilters" inline @submit.prevent="handleSearch">
      <el-form-item label="日期范围">
        <el-date-picker
          v-model="localFilters.dateRange"
          type="daterange"
          range-separator="至"
          start-placeholder="开始日期"
          end-placeholder="结束日期"
          value-format="YYYY-MM-DD"
          style="width: 240px"
        />
      </el-form-item>
      <el-form-item label="类型">
        <el-select v-model="localFilters.type" placeholder="请选择" style="width: 120px">
          <el-option label="全部" value="all" />
          <el-option label="收入" value="income" />
          <el-option label="支出" value="expense" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleSearch" :loading="loading">查询</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>
  </el-card>
</template>

<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  modelValue: {
    type: Object,
    default: () => ({
      dateRange: [],
      type: 'all'
    })
  },
  loading: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue', 'search', 'reset'])

const localFilters = ref({ ...props.modelValue })

watch(
  () => props.modelValue,
  (val) => {
    localFilters.value = { ...val }
  },
  { deep: true }
)

function handleSearch() {
  emit('update:modelValue', { ...localFilters.value })
  emit('search', { ...localFilters.value })
}

function handleReset() {
  localFilters.value = {
    dateRange: [],
    type: 'all'
  }
  emit('update:modelValue', { ...localFilters.value })
  emit('reset')
}
</script>

<style scoped>
.filter-card {
  margin-bottom: 16px;
}
</style>
