<template>
  <div class="print-toolbar">
    <!-- 打印按钮组 -->
    <el-button-group>
      <el-button 
        type="primary" 
        size="small"
        @click="handlePrint"
        :icon="Printer"
      >
        🖨 打印
      </el-button>
      
      <el-button 
        size="small"
        @click="handleExportPdf"
        :icon="Document"
      >
        📄 PDF
      </el-button>

      <el-button 
        size="small"
        @click="handlePreview"
        :icon="View"
        v-if="showPreview"
      >
        👁 预览
      </el-button>

      <el-dropdown 
        trigger="click" 
        @command="handleTemplateSelect"
        v-if="showTemplateSelect"
      >
        <el-button size="small">
          📋 {{ selectedTemplateLabel }} ▼
        </el-button>
        <template #dropdown>
          <el-dropdown-menu class="print-template-dropdown">
            <div class="dropdown-category" 
              v-for="cat in categories" 
              :key="cat">
              <div class="category-title">{{ cat }}</div>
              <el-dropdown-item 
                v-for="tpl in getTemplatesByCat(cat)" 
                :key="tpl.key"
                :command="tpl.key"
                :class="{ 'is-selected': selectedTemplate === tpl.key }"
              >
                <span class="tpl-icon">{{ tpl.icon }}</span>
                <span class="tpl-label">{{ tpl.label }}</span>
                <el-icon class="check-icon" v-if="selectedTemplate === tpl.key">
                  <Check />
                </el-icon>
              </el-dropdown-item>
            </div>
          </el-dropdown-menu>
        </template>
      </el-dropdown>
    </el-button-group>

    <!-- 打印对话框 -->
    <PrintDialog
      v-model="dialogVisible"
      :template-key="selectedTemplate"
      :default-data="defaultData"
      :default-records="defaultRecords"
      :mode="dialogMode"
      @printed="onPrinted"
    />

    <!-- 预览弹窗 -->
    <PrintPreview
      v-model="previewVisible"
      :template-key="selectedTemplate"
      :preview-data="previewData"
      :paper-size="currentPaperSize"
      :orientation="currentOrientation"
    />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { Printer, Document, View, Check } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import PrintDialog from './PrintDialog.vue'
import PrintPreview from './PrintPreview.vue'
import { printTemplates, getTemplateList, getTemplatesByCategory } from './registry'
import { usePrint } from './usePrint'

const props = defineProps({
  // 当前模板key
  templateKey: {
    type: String,
    default: 'work-order',
  },
  // 是否显示模板选择器
  showTemplateSelect: {
    type: Boolean,
    default: false,
  },
  // 是否显示预览按钮
  showPreview: {
    type: Boolean,
    default: true,
  },
  // 弹窗模式
  dialogMode: {
    type: String,
    default: 'dialog', // 'dialog' | 'preview' | 'direct'
  },
  // 默认打印数据（单条）
  defaultData: {
    type: Object,
    default: null,
  },
  // 默认打印数据（多条，用于批量）
  defaultRecords: {
    type: Array,
    default: () => [],
  },
  // 预传递给打印的数据（从列表页选择的多条）
  printData: {
    type: Array,
    default: () => [],
  },
})

const emit = defineEmits(['printed', 'template-change'])

// 状态
const dialogVisible = ref(false)
const previewVisible = ref(false)
const selectedTemplate = ref(props.templateKey)
const previewData = ref(null)
const { print } = usePrint()

// 模板列表
const templateList = getTemplateList()
const categories = [...new Set(templateList.map(t => t.category))]

function getTemplatesByCat(cat) {
  return templateList.filter(t => t.category === cat)
}

const selectedTemplateLabel = computed(() => {
  const tpl = printTemplates[selectedTemplate.value]
  return tpl ? tpl.label : '选择模板'
})

const currentPaperSize = computed(() => {
  const tpl = printTemplates[selectedTemplate.value]
  return tpl ? tpl.defaultPaper : 'A4'
})

const currentOrientation = computed(() => {
  const tpl = printTemplates[selectedTemplate.value]
  return tpl ? tpl.orientation : 'portrait'
})

// 事件处理
function handlePrint() {
  // 将 props.printData 传给 PrintDialog
  if (props.printData && props.printData.length > 0) {
    defaultData.value = props.printData[0]
    defaultRecords.value = props.printData
  }
  dialogVisible.value = true
}

function handleExportPdf() {
  // PDF导出模式
  if (props.printData && props.printData.length > 0) {
    defaultData.value = props.printData[0]
    defaultRecords.value = props.printData
  }
  dialogVisible.value = true
}

function handlePreview() {
  if (props.printData && props.printData.length > 0) {
    previewData.value = props.printData[0]
  }
  previewVisible.value = true
}

function handleTemplateSelect(key) {
  selectedTemplate.value = key
  emit('template-change', key)
}

function onPrinted(result) {
  emit('printed', result)
}

// 暴露方法给父组件
defineExpose({
  openPrint: (data) => {
    if (data) {
      defaultData.value = data
      defaultRecords.value = Array.isArray(data) ? data : [data]
    }
    dialogVisible.value = true
  },
  openPreview: (data) => {
    previewData.value = data
    previewVisible.value = true
  },
})

// DEBUG: expose to window for testing
window.__printToolbar = { openPrint, dialogVisible, handlePrint }
</script>

<style scoped>
.print-toolbar {
  display: inline-flex;
  align-items: center;
}

.print-template-dropdown {
  max-height: 400px;
  overflow-y: auto;
}

.dropdown-category {
  padding: 4px 0;
}

.category-title {
  padding: 4px 12px;
  font-size: 11px;
  color: #999;
  font-weight: bold;
  text-transform: uppercase;
}

.dropdown-category .el-dropdown-item {
  padding: 6px 12px;
  font-size: 13px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.dropdown-category .el-dropdown-item .tpl-icon {
  font-size: 14px;
}

.dropdown-category .el-dropdown-item .tpl-label {
  flex: 1;
}

.dropdown-category .el-dropdown-item.is-selected {
  background: #ecf5ff;
  color: #409eff;
}

.dropdown-category .check-icon {
  color: #409eff;
  margin-left: auto;
}
</style>
