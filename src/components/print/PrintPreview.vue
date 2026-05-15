<template>
  <el-dialog
    v-model="visible"
    title="👁 打印预览"
    width="900px"
    fullscreen
    :close-on-click-modal="false"
    class="print-preview-dialog"
  >
    <div class="preview-container">
      <!-- 预览控制栏 -->
      <div class="preview-toolbar">
        <div class="preview-info">
          <span class="preview-title">{{ templateLabel }}</span>
          <span class="preview-paper">
            {{ getPaperLabel(paperSize) }} · {{ orientation === 'portrait' ? '纵向' : '横向' }}
          </span>
        </div>

        <div class="preview-controls">
          <el-button-group size="small">
            <el-button @click="zoomOut" title="缩小">
              <el-icon><ZoomOut /></el-icon>
            </el-button>
            <el-button disabled class="zoom-label">{{ Math.round(zoom * 100) }}%</el-button>
            <el-button @click="zoomIn" title="放大">
              <el-icon><ZoomIn /></el-icon>
            </el-button>
            <el-button @click="resetZoom" title="重置">重置</el-button>
          </el-button-group>

          <el-button-group size="small" style="margin-left: 12px;">
            <el-button @click="handlePrint">
              <el-icon><Printer /></el-icon> 打印
            </el-button>
            <el-button @click="handleExportPdf" type="primary">
              <el-icon><Download /></el-icon> 导出PDF
            </el-button>
          </el-button-group>
        </div>
      </div>

      <!-- 预览内容区 -->
      <div class="preview-scroll" ref="scrollRef">
        <div class="preview-page-wrapper" :style="wrapperStyle">
          <div 
            class="preview-page"
            :style="pageStyle"
            v-html="previewContent"
          />
        </div>
      </div>
    </div>
  </el-dialog>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { ZoomOut, ZoomIn, Printer, Download } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { printTemplates, getPaperSizeConfig } from './registry'
import { usePrint } from './usePrint'

const props = defineProps({
  modelValue: Boolean,
  templateKey: {
    type: String,
    default: 'work-order',
  },
  previewData: [String, Object, Array],
  paperSize: {
    type: String,
    default: 'A4',
  },
  orientation: {
    type: String,
    default: 'portrait',
  },
})

const emit = defineEmits(['update:modelValue', 'printed'])

const visible = computed({
  get: () => props.modelValue,
  set: (v) => emit('update:modelValue', v),
})

const zoom = ref(0.75) // 默认缩放到75%
const scrollRef = ref(null)
const previewContent = ref('')

const { print, exportPdf } = usePrint()

// 当前模板
const currentTemplate = computed(() => printTemplates[props.templateKey] || null)
const templateLabel = computed(() => currentTemplate.value?.label || '打印预览')

// 纸张尺寸（mm → px，96dpi）
const paperPx = computed(() => {
  const paper = getPaperSizeConfig(props.paperSize)
  const dpi = 96
  const mmPerInch = 25.4
  return {
    width: (paper.width / mmPerInch) * dpi,
    height: (paper.height / mmPerInch) * dpi,
  }
})

// 预览容器样式
const pageStyle = computed(() => {
  const { width, height } = paperPx.value
  return {
    width: `${width}px`,
    height: `${height}px`,
    transform: `scale(${zoom.value})`,
    transformOrigin: 'top center',
    background: '#fff',
    boxShadow: '0 4px 24px rgba(0,0,0,0.15)',
    overflow: 'hidden',
  }
})

// 包裹层样式
const wrapperStyle = computed(() => ({
  width: `${paperPx.value.width}px`,
  height: `${paperPx.value.height}px`,
  margin: '0 auto',
}))

// 监听内容变化
watch(() => props.previewData, (data) => {
  if (typeof data === 'string') {
    previewContent.value = data
  } else if (data) {
    previewContent.value = renderDefaultContent(data)
  }
}, { immediate: true })

function renderDefaultContent(data) {
  const tpl = currentTemplate.value
  return `
    <div class="print-document">
      <div class="print-header">
        <div class="company-name">山东万欣和经贸有限公司</div>
        <div class="document-title">${tpl?.label || '打印预览'}</div>
        <div class="doc-meta">
          <span>打印时间：${new Date().toLocaleString('zh-CN')}</span>
        </div>
      </div>
      <div class="print-main-info">
        ${JSON.stringify(data, null, 2)}
      </div>
    </div>
  `
}

function zoomIn() {
  zoom.value = Math.min(zoom.value + 0.1, 2)
}

function zoomOut() {
  zoom.value = Math.max(zoom.value - 0.1, 0.3)
}

function resetZoom() {
  zoom.value = 0.75
}

function getPaperLabel(size) {
  const labels = {
    'A4': 'A4',
    'A5': 'A5',
    'voucher-paper': '凭证纸',
    'receipt-paper': '收据纸',
    'thermal-40x30': '热敏纸',
    'thermal-40x20': '热敏纸',
  }
  return labels[size] || size
}

async function handlePrint() {
  try {
    // 从预览内容提取HTML
    const content = previewContent.value
    await print(content, {
      title: templateLabel.value,
      paperSize: props.paperSize,
      orientation: props.orientation,
    })
    ElMessage.success('已发送到打印机')
  } catch (error) {
    ElMessage.error('打印失败：' + error.message)
  }
}

async function handleExportPdf() {
  // 创建一个临时容器用于PDF生成
  const container = document.createElement('div')
  container.innerHTML = previewContent.value
  container.style.position = 'absolute'
  container.style.left = '-9999px'
  container.style.top = '0'
  container.style.width = `${paperPx.value.width}px`
  container.style.background = '#fff'
  document.body.appendChild(container)

  try {
    await exportPdf(container, templateLabel.value, {
      paperSize: props.paperSize,
      orientation: props.orientation,
    })
  } finally {
    document.body.removeChild(container)
  }
}
</script>

<style scoped>
.preview-container {
  display: flex;
  flex-direction: column;
  height: calc(100vh - 140px);
}

.preview-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 16px;
  background: #f5f5f5;
  border-bottom: 1px solid #ddd;
  flex-shrink: 0;
}

.preview-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.preview-title {
  font-size: 15px;
  font-weight: bold;
  color: #333;
}

.preview-paper {
  font-size: 12px;
  color: #999;
  padding: 2px 8px;
  background: #eee;
  border-radius: 10px;
}

.preview-controls {
  display: flex;
  align-items: center;
}

.zoom-label {
  min-width: 50px;
  text-align: center;
  cursor: default;
}

.preview-scroll {
  flex: 1;
  overflow: auto;
  padding: 24px;
  background: #e0e0e0;
  display: flex;
  justify-content: center;
}

.preview-page-wrapper {
  position: relative;
}

.preview-page {
  /* 打印内容样式由 global print.css 提供 */
  /* 这里用 scoped 是为了预览缩放 */
  font-family: 'Microsoft YaHei', '宋体', serif;
  font-size: 12px;
  line-height: 1.5;
  color: #000;
  padding: 15mm;
}
</style>

<style>
/* 全局：预览内容中的打印样式 */
.preview-page .print-document {
  width: 100%;
}

.preview-page .print-header {
  text-align: center;
  margin-bottom: 20px;
  padding-bottom: 12px;
  border-bottom: 2px solid #333;
}

.preview-page .print-header .company-name {
  font-size: 18px;
  font-weight: bold;
}

.preview-page .print-header .document-title {
  font-size: 20px;
  font-weight: bold;
  letter-spacing: 4px;
  margin: 8px 0;
}

.preview-page .print-header .doc-meta {
  font-size: 11px;
  color: #555;
}

.preview-page .print-main-info {
  margin: 12px 0;
}

.preview-page .print-main-info .info-row {
  display: flex;
  font-size: 11px;
  line-height: 22px;
  border-bottom: 1px solid #eee;
}

.preview-page .print-main-info .label {
  min-width: 80px;
  font-weight: bold;
  background: #f5f5f5;
  padding: 0 6px;
}

.preview-page .print-main-info .value {
  padding: 0 8px;
  min-width: 120px;
}
</style>
