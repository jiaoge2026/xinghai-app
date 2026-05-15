<template>
  <el-image-viewer
    v-if="visible"
    :url-list="imageUrls"
    :initial-index="currentIndex"
    :hide-on-click-modal="hideOnClickModal"
    @close="handleClose"
    @switch="currentIndex = $event"
  />
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface ImageItem {
  url: string
  label?: string
  thumbUrl?: string
}

interface Props {
  /** v-model: 控制显示 */
  visible: boolean
  /** 图片列表 */
  images: ImageItem[] | string[]
  /** 当前显示的索引 */
  index?: number
  /** 点击遮罩关闭，默认 true */
  hideOnClickModal?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  index: 0,
  hideOnClickModal: true,
})

const emit = defineEmits<{
  'update:visible': [val: boolean]
  change: [index: number]
}>()

const currentIndex = computed({
  get: () => props.index,
  set: (val) => emit('change', val),
})

/** 统一转换为 URL 数组 */
const imageUrls = computed(() => {
  if (!props.images || props.images.length === 0) return []
  return props.images.map((img) => {
    if (typeof img === 'string') return img
    return img.url || img.thumbUrl || ''
  })
})

function handleClose() {
  emit('update:visible', false)
}
</script>
