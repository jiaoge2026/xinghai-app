<template>
  <div class="xh-empty">
    <!-- 内置 SVG 或自定义图片 -->
    <div class="xh-empty__image">
      <img v-if="resolvedImage" :src="resolvedImage" :alt="title" class="xh-empty__img" />
      <div v-else class="xh-empty__icon-wrap">
        <el-icon :size="iconSize" :color="iconColor">
          <component :is="resolvedIcon" />
        </el-icon>
      </div>
    </div>

    <!-- 标题 -->
    <p class="xh-empty__title">{{ resolvedTitle }}</p>

    <!-- 描述 -->
    <p v-if="description" class="xh-empty__description">{{ description }}</p>

    <!-- 操作按钮 -->
    <el-button
      v-if="showAction && actionText"
      :type="actionType"
      :icon="actionIcon"
      class="xh-empty__action"
      @click="handleAction"
    >
      {{ actionText }}
    </el-button>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
  DocumentDelete,
  Search,
  RefreshLeft,
  Connection,
  WarnTriangleFilled,
} from '@element-plus/icons-vue'

interface Props {
  /** 类型：no-data=无数据/no-result=无结果/loading=加载中/error=错误/network=网络 */
  type?: 'no-data' | 'no-result' | 'loading' | 'error' | 'network'
  /** 自定义标题 */
  title?: string
  /** 自定义描述 */
  description?: string
  /** 自定义图片URL */
  image?: string
  /** el-icon-xxx 图标 */
  icon?: string
  /** 操作按钮文字 */
  actionText?: string
  /** 操作按钮类型 */
  actionType?: string
  /** 操作按钮图标 */
  actionIcon?: string
  /** 是否显示操作按钮 */
  showAction?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  type: 'no-data',
  title: '',
  description: '',
  image: '',
  icon: '',
  showAction: false,
  actionType: 'primary',
})

const emit = defineEmits<{
  action: []
}>()

const ICON_MAP: Record<string, { icon: any; color: string; title: string }> = {
  'no-data': {
    icon: DocumentDelete,
    color: '#c0c4cc',
    title: '暂无数据',
  },
  'no-result': {
    icon: Search,
    color: '#c0c4cc',
    title: '未找到结果',
  },
  'loading': {
    icon: RefreshLeft,
    color: '#409eff',
    title: '加载中...',
  },
  'error': {
    icon: WarnTriangleFilled,
    color: '#f56c6c',
    title: '加载失败',
  },
  'network': {
    icon: Connection,
    color: '#e6a23c',
    title: '网络异常',
  },
}

const TYPE_TITLES: Record<string, string> = {
  'no-data': '暂无数据',
  'no-result': '未找到相关结果',
  'loading': '加载中...',
  'error': '加载失败',
  'network': '网络连接异常',
}

const resolvedIcon = computed(() => {
  if (props.icon) return props.icon
  return ICON_MAP[props.type]?.icon || DocumentDelete
})

const iconColor = computed(() => ICON_MAP[props.type]?.color || '#c0c4cc')

const iconSize = computed(() => {
  if (props.type === 'loading') return 32
  return 48
})

const resolvedTitle = computed(() => {
  if (props.title) return props.title
  return TYPE_TITLES[props.type] || '暂无数据'
})

const resolvedImage = computed(() => props.image || '')

function handleAction() {
  emit('action')
}
</script>

<style scoped>
.xh-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 48px 20px;
  min-height: 240px;
  box-sizing: border-box;
}

.xh-empty__image {
  margin-bottom: 16px;
}

.xh-empty__icon-wrap {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: #f5f7fa;
}

.xh-empty__img {
  width: auto;
  height: auto;
  max-width: 160px;
  max-height: 160px;
}

.xh-empty__title {
  margin: 0 0 8px;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  line-height: 1.4;
}

.xh-empty__description {
  margin: 0 0 20px;
  font-size: 14px;
  color: #909399;
  line-height: 1.5;
  text-align: center;
  max-width: 300px;
}

.xh-empty__action {
  margin-top: 4px;
}
</style>
