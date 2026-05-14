<template>
  <el-popover
    placement="bottom-end"
    :width="380"
    trigger="click"
    v-model:visible="visible"
    @show="onShow"
  >
    <template #reference>
      <slot name="trigger">
        <el-button size="small" :icon="Setting">列设置</el-button>
      </slot>
    </template>

    <div class="cs-root">
      <!-- 顶部：预设选择 + 快速操作 -->
      <div class="cs-topbar">
        <el-select v-model="activePreset" size="small" placeholder="选择视图" style="width:130px" @change="onPresetChange">
          <el-option label="默认视图" value="__default__" />
          <el-option v-for="p in presets" :key="p.presetName" :label="p.presetName" :value="p.presetName" />
        </el-select>
        <div class="cs-topbar-actions">
          <el-button size="small" link type="primary" @click="openSaveDialog">保存当前</el-button>
          <el-button size="small" link type="danger" :disabled="activePreset === '__default__'" @click="deleteCurrentPreset">删除</el-button>
          <el-button size="small" link @click="showImportDialog = true">导入</el-button>
          <el-button size="small" link @click="exportConfig">导出</el-button>
        </div>
      </div>

      <el-divider style="margin: 8px 0" />

      <!-- 拖拽列列表 -->
      <div class="cs-list-header">
        <span class="cs-list-tip">拖拽排序 · 点击眼睛显隐 · 输入宽度(px)</span>
        <el-button link type="primary" size="small" @click="checkAll">全选</el-button>
        <el-button link size="small" @click="uncheckAll">取消全选</el-button>
      </div>

      <el-scrollbar height="320px" class="cs-scrollbar">
        <div
          v-for="(col, idx) in localColumns"
          :key="col.prop"
          :class="['cs-item', { 'cs-item-dragging': draggingIdx === idx, 'cs-item-hidden': !col.visible }]"
          draggable="true"
          @dragstart="onDragStart(idx, $event)"
          @dragover.prevent="onDragOver(idx)"
          @drop="onDrop(idx)"
          @dragend="onDragEnd"
        >
          <!-- 拖拽手柄 -->
          <el-icon class="cs-drag-handle" @click.stop><Rank /></el-icon>
          <!-- 固定列标识 -->
          <el-tag v-if="col.fixed" size="small" type="warning" style="margin-right:4px;cursor:default;flex-shrink:0">固</el-tag>
          <!-- 列名 -->
          <span class="cs-item-label" @click="toggleCol(idx)">{{ col.label }}</span>
          <!-- 宽度输入 -->
          <div class="cs-item-width" @click.stop>
            <span class="cs-item-width-label">W:</span>
            <el-input-number
              v-model="col._width"
              :min="0"
              :max="600"
              :step="10"
              controls-position="right"
              size="small"
              style="width:70px"
              placeholder="auto"
              @change="onWidthChange(idx)"
            />
          </div>
          <!-- 显隐按钮 -->
          <el-icon
            class="cs-eye"
            :class="{ 'cs-eye-off': !col.visible }"
            @click="toggleCol(idx)"
          >
            <View v-if="col.visible" />
            <Hide v-else />
          </el-icon>
        </div>
      </el-scrollbar>

      <el-divider style="margin: 8px 0" />

      <!-- 底部操作 -->
      <div class="cs-footer">
        <el-button size="small" @click="resetToDefault">重置默认</el-button>
        <el-button size="small" type="primary" @click="applyAndClose">应用</el-button>
      </div>
    </div>

    <!-- 保存预设弹窗 -->
    <el-dialog v-model="showSaveDialog" title="保存为视图" width="340px" :close-on-click-modal="false">
      <el-form-item label="视图名称">
        <el-input v-model="newPresetName" placeholder="如：维修视图" maxlength="20" />
      </el-form-item>
      <template #footer>
        <el-button size="small" @click="showSaveDialog = false">取消</el-button>
        <el-button size="small" type="primary" @click="savePreset" :disabled="!newPresetName.trim()">保存</el-button>
      </template>
    </el-dialog>

    <!-- 导入弹窗 -->
    <el-dialog v-model="showImportDialog" title="导入列配置" width="380px" :close-on-click-modal="false">
      <p style="font-size:12px;color:#999;margin-bottom:8px">粘贴从「导出」功能获取的配置 JSON</p>
      <el-input v-model="importJson" type="textarea" :rows="6" placeholder='[{"prop":"xxx","label":"xxx","visible":true}]' />
      <template #footer>
        <el-button size="small" @click="showImportDialog = false">取消</el-button>
        <el-button size="small" type="primary" @click="importConfig">导入</el-button>
      </template>
    </el-dialog>
  </el-popover>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Rank, View, Hide, Setting } from '@element-plus/icons-vue'

const props = defineProps({
  // 列定义 [{prop, label, visible, fixed, width}]
  columns: { type: Array, default: () => [] },
  // 当前页路径
  pagePath: { type: String, default: '' },
  // 保存接口
  saveUrl: { type: String, default: '/api/v1/system/column-configs' },
  // 预设接口
  presetUrl: { type: String, default: '/api/v1/system/column-presets' },
  // 默认显示的列 key 数组
  defaultVisible: { type: Array, default: () => [] }
})

const emit = defineEmits(['update:columns', 'change'])

// --- 状态 ---
const visible = ref(false)
const localColumns = ref([])
const presets = ref([])
const activePreset = ref('__default__')
const showSaveDialog = ref(false)
const showImportDialog = ref(false)
const newPresetName = ref('')
const importJson = ref('')

// --- 拖拽状态 ---
let draggingIdx = -1

// --- 初始化 ---
const onShow = () => {
  loadFromServer()
  loadPresets()
}

// --- 从服务器加载列配置 ---
const loadFromServer = async () => {
  const key = `cs_cols_${props.pagePath}`
  try {
    const res = await fetch(`${props.saveUrl}?pagePath=${encodeURIComponent(props.pagePath)}`)
    const json = await res.json()
    if (json.code === 0 && json.data && json.data.length > 0) {
      const saved = json.data
      const map = {}
      saved.forEach(s => { map[s.columnKey] = s })
      localColumns.value = props.columns.map(c => ({
        ...c,
        visible: map[c.prop] ? map[c.prop].visible === 1 : c.visible !== false,
        fixed: c.fixed || (map[c.prop] ? map[c.prop].fixed === 1 : false)
      }))
      return
    }
  } catch (e) { /* ignore */ }
  // 回退到 props 或 localStorage
  const saved = localStorage.getItem(key)
  if (saved) {
    try {
      const arr = JSON.parse(saved)
      if (Array.isArray(arr) && arr.length > 0) {
        const map = {}
        arr.forEach(a => { map[a.prop] = a })
        localColumns.value = props.columns.map(c => ({
          ...c,
          _width: map[c.prop] && map[c.prop].width ? map[c.prop].width : c.width || undefined,
          visible: map[c.prop] ? map[c.prop].visible : true
        }))
        return
      }
    } catch (e) { /* ignore */ }
  }
  localColumns.value = props.columns.map(c => ({ ...c, _width: c.width || undefined }))
}

// --- 加载预设列表 ---
const loadPresets = async () => {
  try {
    const res = await fetch(`${props.presetUrl}?pagePath=${encodeURIComponent(props.pagePath)}`)
    const json = await res.json()
    presets.value = json.code === 0 ? json.data || [] : []
  } catch (e) {
    presets.value = []
  }
}

// --- 预设切换 ---
const onPresetChange = async (name) => {
  if (name === '__default__') {
    localColumns.value = props.columns.map(c => ({ ...c, _width: c.width || undefined }))
    return
  }
  const p = presets.value.find(x => x.presetName === name)
  if (!p) return
  try {
    const res = await fetch(`${props.presetUrl}/${encodeURIComponent(name)}?pagePath=${encodeURIComponent(props.pagePath)}`)
    const json = await res.json()
    if (json.code === 0 && json.data) {
      // 预设只存可见列 key 列表
      const keys = JSON.parse(json.data)
      localColumns.value = props.columns.map(c => ({
        ...c,
        _width: c.width || undefined,
        visible: keys.includes(c.prop)
      }))
    }
  } catch (e) {
    ElMessage.error('加载视图失败')
  }
}

// --- 保存预设 ---
const savePreset = async () => {
  const name = newPresetName.value.trim()
  if (!name) return
  const keys = localColumns.value.map(c => c.prop)
  try {
    const res = await fetch(props.presetUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pagePath: props.pagePath, presetName: name, columnKeys: keys, isDefault: false })
    })
    const json = await res.json()
    if (json.code === 0) {
      ElMessage.success('视图已保存')
      showSaveDialog.value = false
      newPresetName.value = ''
      loadPresets()
      activePreset.value = name
    } else {
      ElMessage.error(json.message || '保存失败')
    }
  } catch (e) {
    ElMessage.error('保存失败')
  }
}

// --- 删除预设 ---
const deleteCurrentPreset = async () => {
  if (activePreset.value === '__default__') return
  try {
    const res = await fetch(`${props.presetUrl}?pagePath=${encodeURIComponent(props.pagePath)}&presetName=${encodeURIComponent(activePreset.value)}`, { method: 'DELETE' })
    const json = await res.json()
    if (json.code === 0) {
      ElMessage.success('已删除')
      presets.value = presets.value.filter(p => p.presetName !== activePreset.value)
      activePreset.value = '__default__'
    }
  } catch (e) {
    ElMessage.error('删除失败')
  }
}

// --- 拖拽排序 ---
const onDragStart = (idx, e) => {
  draggingIdx = idx
  e.dataTransfer.effectAllowed = 'move'
  e.dataTransfer.setData('text/plain', idx)
}
const onDragOver = (idx) => {
  if (draggingIdx === idx || draggingIdx < 0) return
}
const onDrop = (idx) => {
  if (draggingIdx === idx || draggingIdx < 0) return
  const arr = [...localColumns.value]
  const [moved] = arr.splice(draggingIdx, 1)
  arr.splice(idx, 0, moved)
  localColumns.value = arr
  draggingIdx = -1
}
const onDragEnd = () => { draggingIdx = -1 }

// --- 显隐切换 ---
const toggleCol = (idx) => {
  if (localColumns.value[idx].fixed) return
  localColumns.value[idx] = { ...localColumns.value[idx], visible: !localColumns.value[idx].visible }
}
const checkAll = () => {
  localColumns.value = localColumns.value.map(c => ({ ...c, visible: true }))
}
const uncheckAll = () => {
  localColumns.value = localColumns.value.map(c => c.fixed ? c : { ...c, visible: false })
}

// --- 重置 ---
const resetToDefault = () => {
  localColumns.value = props.columns.map(c => ({ ...c }))
  activePreset.value = '__default__'
}

// --- 导出 ---
const exportConfig = () => {
  const data = localColumns.value.map(c => ({
    prop: c.prop,
    label: c.label,
    visible: c.visible,
    width: c._width || null
  }))
  const json = JSON.stringify(data, null, 2)
  const blob = new Blob([json], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `columns_${props.pagePath.replace(/\//g, '_')}.json`
  a.click()
  URL.revokeObjectURL(url)
  ElMessage.success('已导出配置文件')
}

// --- 导入 ---
const importConfig = () => {
  try {
    const data = JSON.parse(importJson.value)
    if (!Array.isArray(data)) throw new Error('格式错误')
    const map = {}
    data.forEach(d => { if (d.prop && d.label) map[d.prop] = d })
    localColumns.value = props.columns.map(c => ({
      ...c,
      _width: (map[c.prop] && map[c.prop].width != null) ? map[c.prop].width : c.width,
      visible: map[c.prop] ? (map[c.prop].visible !== false) : true
    }))
    showImportDialog.value = false
    importJson.value = ''
    activePreset.value = '__default__'
    ElMessage.success('导入成功')
  } catch (e) {
    ElMessage.error('JSON 格式错误，请检查')
  }
}

// --- 应用并关闭 ---
const applyAndClose = async () => {
  // 收集当前列状态（含宽度）
  const colData = localColumns.value.map((c, i) => ({
    prop: c.prop,
    visible: c.visible,
    width: c._width || null
  }))
  // 保存到服务器（不含宽度，暂用 localStorage 存宽度）
  const data = localColumns.value.map((c, i) => ({
    columnKey: c.prop,
    visible: c.visible ? 1 : 0,
    sortOrder: i,
    fixed: c.fixed ? 1 : 0
  }))
  try {
    await fetch(props.saveUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pagePath: props.pagePath, configs: data }),
    })
  } catch (e) { /* 忽略 */ }
  // 同时存 localStorage（含宽度）
  const key = `cs_cols_${props.pagePath}`
  localStorage.setItem(key, JSON.stringify(colData))
  emit('update:columns', localColumns.value)
  emit('change', localColumns.value)
  visible.value = false
}
</script>

<style scoped>
.cs-root { user-select: none; }
.cs-topbar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 4px; }
.cs-topbar-actions { display: flex; gap: 2px; flex-wrap: wrap; justify-content: flex-end; }
.cs-list-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 6px; }
.cs-list-tip { font-size: 11px; color: #aaa; }
.cs-scrollbar { border: 1px solid #f0f0f0; border-radius: 4px; }
.cs-item {
  display: flex;
  align-items: center;
  padding: 6px 8px;
  cursor: grab;
  border-bottom: 1px solid #f5f5f5;
  transition: background 0.15s;
  min-height: 32px;
}
.cs-item:hover { background: #f5f7fa; }
.cs-item:last-child { border-bottom: none; }
.cs-item-dragging { opacity: 0.4; background: #e8f4ff; }
.cs-item-hidden .cs-item-label { color: #c0c0c0; text-decoration: line-through; }
.cs-drag-handle { color: #bbb; cursor: grab; margin-right: 6px; flex-shrink: 0; }
.cs-item-label { flex: 1; font-size: 13px; cursor: pointer; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.cs-item-width { display: flex; align-items: center; gap: 2px; flex-shrink: 0; margin: 0 6px; }
.cs-item-width-label { font-size: 11px; color: #bbb; flex-shrink: 0; }
.cs-eye { color: #409eff; flex-shrink: 0; margin-left: 6px; cursor: pointer; }
.cs-eye-off { color: #d0d0d0; }
.cs-footer { display: flex; justify-content: space-between; align-items: center; }
</style>
