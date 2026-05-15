<template>
  <div
    class="xh-stat-card"
    :class="[
      `xh-stat-card--${color}`,
      { 'xh-stat-card--gradient': gradient }
    ]"
  >
    <!-- 顶部：图标 + 标题 -->
    <div class="xh-stat-card__header">
      <span class="xh-stat-card__title">{{ title }}</span>
      <div v-if="icon" class="xh-stat-card__icon">
        <el-icon :size="20">
          <component :is="icon" />
        </el-icon>
      </div>
    </div>

    <!-- 中部：数值 -->
    <div class="xh-stat-card__body">
      <span v-if="loading" class="xh-stat-card__skeleton" />
      <span v-else class="xh-stat-card__value">
        <span v-if="prefix" class="xh-stat-card__prefix">{{ prefix }}</span>
        <span class="xh-stat-card__number">{{ displayValue }}</span>
        <span v-if="suffix" class="xh-stat-card__suffix">{{ suffix }}</span>
      </span>
    </div>

    <!-- 底部：趋势 -->
    <div v-if="trend && !loading" class="xh-stat-card__trend">
      <span
        class="xh-stat-card__trend-value"
        :class="`xh-stat-card__trend-value--${trend.type}`"
      >
        <el-icon v-if="trend.type === 'up'" :size="14"><ArrowUp /></el-icon>
        <el-icon v-else-if="trend.type === 'down'" :size="14"><ArrowDown /></el-icon>
        {{ Math.abs(trend.value) }}%
      </span>
      <span v-if="trendLabel" class="xh-stat-card__trend-label">{{ trendLabel }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, h } from 'vue'
import { ArrowUp, ArrowDown } from '@element-plus/icons-vue'

interface Trend {
  value: number
  type: 'up' | 'down' | 'neutral'
}

interface Props {
  title: string
  value: number | string
  prefix?: string
  suffix?: string
  /** 数值精度（用于格式化） */
  precision?: number
  trend?: Trend
  trendLabel?: string
  color?: 'primary' | 'success' | 'warning' | 'danger' | 'info'
  icon?: string
  loading?: boolean
  gradient?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  precision: 0,
  color: 'primary',
  loading: false,
  gradient: false,
})

const displayValue = computed(() => {
  if (typeof props.value === 'string') return props.value
  return props.value.toLocaleString('zh-CN', {
    minimumFractionDigits: props.precision,
    maximumFractionDigits: props.precision,
  })
})
</script>

<style scoped>
.xh-stat-card {
  background: #fff;
  border-radius: 8px;
  padding: 20px;
  box-sizing: border-box;
  position: relative;
  overflow: hidden;
  transition: box-shadow 0.2s;
}

.xh-stat-card:hover {
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
}

/* 背景色 */
.xh-stat-card--primary { background: linear-gradient(135deg, #ecf5ff, #ffffff); }
.xh-stat-card--success { background: linear-gradient(135deg, #f0f9eb, #ffffff); }
.xh-stat-card--warning { background: linear-gradient(135deg, #fdf6ec, #ffffff); }
.xh-stat-card--danger  { background: linear-gradient(135deg, #fef0f0, #ffffff); }
.xh-stat-card--info    { background: linear-gradient(135deg, #f4f4f5, #ffffff); }

/* 渐变背景 */
.xh-stat-card--gradient.xh-stat-card--primary { background: linear-gradient(135deg, #409eff, #66b1ff); }
.xh-stat-card--gradient.xh-stat-card--success  { background: linear-gradient(135deg, #67c23a, #85ce61); }
.xh-stat-card--gradient.xh-stat-card--warning  { background: linear-gradient(135deg, #e6a23c, #ebb563); }
.xh-stat-card--gradient.xh-stat-card--danger   { background: linear-gradient(135deg, #f56c6c, #f78989); }
.xh-stat-card--gradient.xh-stat-card--info     { background: linear-gradient(135deg, #909399, #a6a9ad); }

.xh-stat-card__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.xh-stat-card__title {
  font-size: 14px;
  color: #606266;
  font-weight: 500;
}

.xh-stat-card__icon {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
}

.xh-stat-card__body {
  margin-bottom: 8px;
}

.xh-stat-card__value {
  display: flex;
  align-items: baseline;
  gap: 2px;
}

.xh-stat-card__prefix {
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.xh-stat-card__number {
  font-size: 28px;
  font-weight: 700;
  color: #303133;
  line-height: 1.2;
  font-variant-numeric: tabular-nums;
}

.xh-stat-card__suffix {
  font-size: 14px;
  color: #909399;
  margin-left: 2px;
}

.xh-stat-card__skeleton {
  display: block;
  height: 34px;
  width: 80px;
  background: linear-gradient(90deg, #f2f2f2 25%, #e6e6e6 50%, #f2f2f2 75%);
  background-size: 200% 100%;
  animation: skeleton-loading 1.5s infinite;
  border-radius: 4px;
}

@keyframes skeleton-loading {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

.xh-stat-card__trend {
  display: flex;
  align-items: center;
  gap: 6px;
}

.xh-stat-card__trend-value {
  display: flex;
  align-items: center;
  gap: 2px;
  font-size: 13px;
  font-weight: 500;
}

.xh-stat-card__trend-value--up   { color: #67c23a; }
.xh-stat-card__trend-value--down { color: #f56c6c; }
.xh-stat-card__trend-value--neutral { color: #909399; }

.xh-stat-card__trend-label {
  font-size: 12px;
  color: #909399;
}

/* 渐变模式下文字变白 */
.xh-stat-card--gradient .xh-stat-card__title,
.xh-stat-card--gradient .xh-stat-card__number,
.xh-stat-card--gradient .xh-stat-card__prefix,
.xh-stat-card--gradient .xh-stat-card__trend-label {
  color: #fff;
}

.xh-stat-card--gradient .xh-stat-card__icon {
  background: rgba(255, 255, 255, 0.3);
  color: #fff;
}
</style>
