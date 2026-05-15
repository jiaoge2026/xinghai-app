<template>
  <el-dialog
    v-model="visible"
    title="🖨 打印设置"
    width="680px"
    :close-on-click-modal="false"
    class="print-dialog"
  >
    <div class="print-dialog-body" v-if="currentTemplate">
      
      <!-- 模板信息 -->
      <div class="template-info">
        <div class="template-icon">{{ currentTemplate.icon }}</div>
        <div class="template-detail">
          <div class="template-name">{{ currentTemplate.label }}</div>
          <div class="template-desc">{{ currentTemplate.description }}</div>
        </div>
      </div>

      <el-divider />

      <!-- 打印范围 -->
      <div class="setting-section" v-if="showRange">
        <div class="section-label">打印范围</div>
        <el-radio-group v-model="printRange" size="default">
          <el-radio value="all">全部 {{ totalCount }} 条</el-radio>
          <el-radio value="current" v-if="showCurrentPage">当前页 {{ currentPageCount }} 条</el-radio>
          <el-radio value="selected" v-if="showSelected && selectedCount > 0">
            选中 {{ selectedCount }} 条
          </el-radio>
        </el-radio-group>
      </div>

      <!-- 纸张选择 -->
      <div class="setting-section">
        <div class="section-label">纸张</div>
        <el-radio-group v-model="paperSize" size="default">
          <el-radio 
            v-for="size in currentTemplate.paperSizes" 
            :key="size"
            :value="size"
          >
            {{ getPaperLabel(size) }}
          </el-radio>
        </el-radio-group>
      </div>

      <!-- 方向 -->
      <div class="setting-section">
        <div class="section-label">方向</div>
        <el-radio-group v-model="orientation" size="default">
          <el-radio value="portrait">纵向</el-radio>
          <el-radio value="landscape">横向</el-radio>
        </el-radio-group>
      </div>

      <!-- 打印份数 -->
      <div class="setting-section" v-if="currentTemplate.copies > 1 || showCopies">
        <div class="section-label">份数</div>
        <el-input-number 
          v-model="copies" 
          :min="1" 
          :max="10" 
          size="default"
        />
        <span class="copies-hint" v-if="currentTemplate.copiesConfig">
          （三联单：{{ currentTemplate.copies }}份）
        </span>
      </div>

      <!-- 选项 -->
      <div class="setting-section">
        <div class="section-label">选项</div>
        <div class="options-grid">
          <el-checkbox v-model="repeatHeader" v-if="currentTemplate.repeatHeader">
            📌 表头每页重复
          </el-checkbox>
          <el-checkbox v-model="includeSignature" v-if="currentTemplate.repeatFooter !== undefined">
            ✍️ 包含签名区
          </el-checkbox>
          <el-checkbox v-model="includeBarcode" v-if="currentTemplate.includeBarcode">
            📊 条码
          </el-checkbox>
          <el-checkbox v-model="includeQRCode" v-if="currentTemplate.includeQRCode">
            📱 二维码
          </el-checkbox>
          <el-checkbox v-model="includeWatermark" v-if="currentTemplate.includeWatermark">
            💧 水印防伪
          </el-checkbox>
          <el-checkbox v-model="mergePdf" v-if="selectedCount > 1">
            📑 合并成一个PDF
          </el-checkbox>
        </div>
      </div>

      <!-- 三联单说明 -->
      <div class="triple-notice" v-if="currentTemplate.copiesConfig" type="info">
        <el-icon><InfoFilled /></el-icon>
        三联单颜色：{{ copiesList.join('、') }}
      </div>

    </div>

    <!-- 无模板时 -->
    <div v-else class="no-template">
      请先选择打印模板
    </div>

    <template #footer>
      <div class="dialog-footer">
        <el-button @click="visible = false">取消</el-button>
        <el-button @click="handlePreview">
          👁 预览
        </el-button>
        <el-button type="primary" @click="handlePrint" :loading="printing">
          🖨 直接打印
        </el-button>
      </div>
    </template>

  </el-dialog>

  <!-- 预览弹窗 -->
  <PrintPreview
    v-model="previewVisible"
    :template-key="templateKey"
    :preview-data="previewContent"
    :paper-size="paperSize"
    :orientation="orientation"
  />
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { InfoFilled } from '@element-plus/icons-vue'
import PrintPreview from './PrintPreview.vue'
import { printTemplates, getPaperSizeConfig } from './registry'
import { usePrint } from './usePrint'

const props = defineProps({
  modelValue: Boolean,
  templateKey: {
    type: String,
    default: 'work-order',
  },
  // 外部传入的打印数据
  defaultData: Object,
  // 列表选中数据
  defaultRecords: {
    type: Array,
    default: () => [],
  },
  // 列表总条数
  totalCount: {
    type: Number,
    default: 0,
  },
  // 当前页条数
  currentPageCount: {
    type: Number,
    default: 0,
  },
  // 选中条数
  selectedCount: {
    type: Number,
    default: 0,
  },
  // 是否显示范围选项
  showRange: {
    type: Boolean,
    default: true,
  },
  // 是否显示当前页选项
  showCurrentPage: {
    type: Boolean,
    default: true,
  },
  // 是否显示选中选项
  showSelected: {
    type: Boolean,
    default: true,
  },
  // 是否显示份数选择
  showCopies: {
    type: Boolean,
    default: true,
  },
})

const emit = defineEmits(['update:modelValue', 'printed'])

const visible = computed({
  get: () => props.modelValue,
  set: (v) => emit('update:modelValue', v),
})

// 状态
const printRange = ref('all')
const paperSize = ref('A4')
const orientation = ref('portrait')
const copies = ref(1)
const repeatHeader = ref(true)
const includeSignature = ref(true)
const includeBarcode = ref(true)
const includeQRCode = ref(true)
const includeWatermark = ref(false)
const mergePdf = ref(false)
const printing = ref(false)
const previewVisible = ref(false)
const previewContent = ref(null)

const { print, exportPdf } = usePrint()

// 当前模板
const currentTemplate = computed(() => printTemplates[props.templateKey] || null)

// 三联单列表
const copiesList = computed(() => {
  if (!currentTemplate.value?.copiesConfig) return []
  return Object.values(currentTemplate.value.copiesConfig).map(c => `${c.label}(${c.color})`)
})

// 监听模板变化，初始化默认值
watch(() => props.templateKey, (key) => {
  const tpl = printTemplates[key]
  if (tpl) {
    paperSize.value = tpl.defaultPaper || 'A4'
    orientation.value = tpl.orientation || 'portrait'
    copies.value = tpl.copies || 1
    repeatHeader.value = tpl.repeatHeader ?? true
    includeBarcode.value = tpl.includeBarcode ?? true
    includeQRCode.value = tpl.includeQRCode ?? true
    includeWatermark.value = tpl.includeWatermark ?? false
  }
}, { immediate: true })

function getPaperLabel(size) {
  const labels = {
    'A4': 'A4 (210×297mm)',
    'A5': 'A5 (148×210mm)',
    'voucher-paper': '凭证纸 (241×140mm)',
    'receipt-paper': '收据纸 (210×297mm)',
    'thermal-40x30': '热敏纸 (40×30mm)',
    'thermal-40x20': '热敏纸 (40×20mm)',
  }
  return labels[size] || size
}

async function handlePrint() {
  if (!currentTemplate.value) {
    ElMessage.warning('请先选择打印模板')
    return
  }

  printing.value = true
  try {
    // TODO: 从后端获取完整打印数据
    // 这里先用前端数据演示
    const printData = props.defaultData || props.defaultRecords || {}

    // 生成打印内容（调用模板组件渲染）
    const content = await renderPrintContent(printData)

    await print(content, {
      title: currentTemplate.value.label,
      paperSize: paperSize.value,
      orientation: orientation.value,
    })

    // 记录日志
    logPrintEvent('print')

    emit('printed', { success: true, type: 'print' })
    ElMessage.success('已发送到打印机')
    visible.value = false

  } catch (error) {
    console.error('打印失败:', error)
    ElMessage.error('打印失败：' + error.message)
  } finally {
    printing.value = false
  }
}

async function handlePreview() {
  if (!currentTemplate.value) {
    ElMessage.warning('请先选择打印模板')
    return
  }

  try {
    const printData = props.defaultData || props.defaultRecords || {}
    previewContent.value = await renderPrintContent(printData)
    previewVisible.value = true
  } catch (error) {
    ElMessage.error('预览生成失败：' + error.message)
  }
}

async function renderPrintContent(data) {
  // 动态加载模板组件并渲染
  // 目前返回占位HTML，后续模板组件就绪后完善
  const tpl = currentTemplate.value
  return `
    <div class="print-document" data-template="${tpl.label}">
      <div class="print-header">
        <div class="company-name">山东万欣和经贸有限公司</div>
        <div class="document-title">${tpl.label}</div>
        <div class="doc-meta">
          <span>打印时间：${new Date().toLocaleString('zh-CN')}</span>
          <span>操作人：${localStorage.getItem('username') || 'admin'}</span>
        </div>
      </div>
      <div class="print-main-info">
        ${renderMainInfo(data)}
      </div>
      ${includeSignature.value ? renderSignature() : ''}
      ${includeBarcode.value ? '<div class="print-barcode">[条码区]</div>' : ''}
      ${includeQRCode.value ? '<div class="print-qrcode">[二维码区]</div>' : ''}
    </div>
  `
}

function renderMainInfo(data) {
  if (!data || Object.keys(data).length === 0) {
    return '<div style="padding:40px;text-align:center;color:#999;">暂无打印数据</div>'
  }
  return Object.entries(data).slice(0, 8).map(([k, v]) => `
    <div class="info-row">
      <span class="label">${k}</span>
      <span class="value">${v ?? '-'}</span>
    </div>
  `).join('')
}

function renderSignature() {
  return `
    <div class="print-signature">
      <div class="signature-grid">
        <div class="signature-item">
          <div class="sign-label">制单人</div>
          <div class="sign-line"></div>
          <div class="sign-date"></div>
        </div>
        <div class="signature-item">
          <div class="sign-label">审核人</div>
          <div class="sign-line"></div>
          <div class="sign-date"></div>
        </div>
        <div class="signature-item">
          <div class="sign-label">客户签字</div>
          <div class="sign-line"></div>
          <div class="sign-date"></div>
        </div>
      </div>
    </div>
  `
}

async function logPrintEvent(type) {
  try {
    const token = localStorage.getItem('token')
    await fetch('/api/v1/print/logs', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({
        templateType: props.templateKey,
        printType: type,
        paperSize: paperSize.value,
        orientation: orientation.value,
        copies: copies.value,
        printedAt: new Date().toISOString(),
      }),
    })
  } catch (e) {
    console.warn('记录打印日志失败:', e)
  }
}
</script>

<style scoped>
.print-dialog-body {
  padding: 0 8px;
}

.template-info {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 8px 0;
}

.template-icon {
  font-size: 40px;
  line-height: 1;
}

.template-detail {
  flex: 1;
}

.template-name {
  font-size: 16px;
  font-weight: bold;
  color: #333;
}

.template-desc {
  font-size: 12px;
  color: #999;
  margin-top: 4px;
}

.setting-section {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 10px 0;
  border-bottom: 1px solid #f0f0f0;
}

.setting-section:last-of-type {
  border-bottom: none;
}

.section-label {
  font-size: 13px;
  font-weight: bold;
  color: #333;
  min-width: 60px;
  padding-top: 4px;
  flex-shrink: 0;
}

.options-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 12px 24px;
}

.options-grid .el-checkbox {
  margin-right: 0;
}

.copies-hint {
  font-size: 12px;
  color: #999;
  margin-left: 8px;
  align-self: center;
}

.triple-notice {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background: #f0f7ff;
  border-radius: 4px;
  font-size: 12px;
  color: #409eff;
  margin-top: 8px;
}

.no-template {
  text-align: center;
  padding: 40px;
  color: #999;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}
</style>
