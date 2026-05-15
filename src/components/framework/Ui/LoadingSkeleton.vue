<template>
  <div class="xh-skeleton" :class="{ 'xh-skeleton--animate': active }">
    <!-- 头像 -->
    <div v-if="avatar" class="xh-skeleton__avatar" :class="`xh-skeleton__avatar--${avatarShape}`" />

    <!-- 标题 -->
    <div v-if="title" class="xh-skeleton__title" :style="{ width: titleWidth }" />

    <!-- 段落行 -->
    <div v-if="rows > 0" class="xh-skeleton__rows">
      <div
        v-for="i in rows"
        :key="i"
        class="xh-skeleton__row"
        :style="{ width: i === rows ? '60%' : '100%' }"
      />
    </div>

    <!-- 表格列骨架 -->
    <div v-if="columns > 0" class="xh-skeleton__columns">
      <div v-for="i in columns" :key="i" class="xh-skeleton__column" />
    </div>
  </div>
</template>

<script setup lang="ts">
interface Props {
  /** 是否开启动画，默认 true */
  active?: boolean
  /** 是否显示头像占位 */
  avatar?: boolean
  /** 头像形状：circle=圆形.round=圆角 */
  avatarShape?: 'circle' | 'round'
  /** 是否显示标题占位 */
  title?: boolean
  /** 标题宽度，默认 '40%' */
  titleWidth?: string
  /** 段落行数，默认 3 */
  rows?: number
  /** 表格列数（与rows互斥） */
  columns?: number
}

withDefaults(defineProps<Props>(), {
  active: true,
  avatar: false,
  avatarShape: 'round',
  title: true,
  titleWidth: '40%',
  rows: 3,
  columns: 0,
})
</script>

<style scoped>
.xh-skeleton {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.xh-skeleton__avatar {
  width: 48px;
  height: 48px;
  border-radius: 4px;
  background: #e6e8eb;
}

.xh-skeleton__avatar--circle {
  border-radius: 50%;
}

.xh-skeleton__title {
  height: 20px;
  background: #e6e8eb;
  border-radius: 4px;
}

.xh-skeleton__rows {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.xh-skeleton__row {
  height: 16px;
  background: #e6e8eb;
  border-radius: 4px;
}

.xh-skeleton__columns {
  display: flex;
  gap: 8px;
}

.xh-skeleton__column {
  flex: 1;
  height: 32px;
  background: #e6e8eb;
  border-radius: 4px;
}

/* 动画 */
.xh-skeleton--animate .xh-skeleton__avatar,
.xh-skeleton--animate .xh-skeleton__title,
.xh-skeleton--animate .xh-skeleton__row,
.xh-skeleton--animate .xh-skeleton__column {
  background: linear-gradient(90deg, #e6e8eb 25%, #f0f0f0 50%, #e6e8eb 75%);
  background-size: 200% 100%;
  animation: skeleton-loading 1.5s infinite;
}

@keyframes skeleton-loading {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
</style>
