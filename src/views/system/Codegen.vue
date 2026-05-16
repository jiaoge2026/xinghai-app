<template>
  <div class="codegen-container">
    <!-- 左侧：表列表 -->
    <div class="table-panel">
      <div class="panel-header">
        <span class="panel-title">数据库表</span>
        <el-button type="primary" size="small" @click="loadTables" :loading="tableLoading" plain>
          <el-icon><Refresh /></el-icon> 刷新
        </el-button>
      </div>

      <div class="table-search">
        <el-input v-model="tableKeyword" placeholder="搜索表名" clearable size="small" @input="debounceLoad">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
      </div>

      <div class="table-list" v-loading="tableLoading">
        <div
          v-for="t in tableList"
          :key="t.tableName"
          class="table-item"
          :class="{ active: selectedTable === t.tableName }"
          @click="selectTable(t)"
        >
          <span class="table-name">{{ t.tableName }}</span>
          <span class="table-count">{{ t.columnCount }}列</span>
        </div>
        <el-empty v-if="!tableLoading && tableList.length === 0" description="暂无数据" :image-size="60" />
      </div>

      <div class="table-pagination">
        <el-pagination
          small
          layout="prev, pager, next"
          v-model:current-page="tablePage"
          :page-size="tablePageSize"
          :total="tableTotal"
          @current-change="loadTables"
        />
      </div>
    </div>

    <!-- 右侧：列预览 + 生成选项 -->
    <div class="preview-panel" v-if="selectedTable">
      <!-- 表基本信息 -->
      <div class="info-card">
        <div class="info-row">
          <span class="info-label">表名：</span>
          <span class="info-value mono">{{ tableMeta.tableName }}</span>
          <el-tag size="small" type="info">{{ tableMeta.tableComment || '无注释' }}</el-tag>
        </div>
        <div class="info-row">
          <span class="info-label">列数：</span>
          <span class="info-value">{{ tableMeta.columns?.length || 0 }}</span>
        </div>
      </div>

      <!-- 列预览表格 -->
      <div class="column-section">
        <div class="section-header">
          <span class="section-title">列预览</span>
          <el-button size="small" @click="loadMeta" :loading="metaLoading">
            <el-icon><Refresh /></el-icon> 刷新
          </el-button>
        </div>

        <el-table :data="tableMeta.columns" size="small" border max-height="320" v-loading="metaLoading">
          <el-table-column prop="columnName" label="列名" width="180">
            <template #default="{ row }">
              <span class="mono">{{ row.columnName }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="dataType" label="数据类型" width="120" />
          <el-table-column prop="columnKey" label="键" width="60" align="center">
            <template #default="{ row }">
              <el-tag size="small" type="warning" v-if="row.columnKey === 'PRI'">PK</el-tag>
              <el-tag size="small" type="success" v-else-if="row.columnKey === 'UNI'">UNI</el-tag>
              <el-tag size="small" type="info" v-else-if="row.columnKey === 'MUL'">FK</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="nullable" label="可空" width="60" align="center">
            <template #default="{ row }">
              <span :class="row.nullable === 'YES' ? 'text-danger' : 'text-success'">
                {{ row.nullable === 'YES' ? '否' : '是' }}
              </span>
            </template>
          </el-table-column>
          <el-table-column prop="columnComment" label="注释" min-width="120" show-overflow-tooltip />
          <el-table-column prop="javaType" label="Java类型" width="130">
            <template #default="{ row }">
              <span class="mono text-primary">{{ row.javaType }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="javaField" label="Java字段" width="140">
            <template #default="{ row }">
              <span class="mono">{{ row.javaField }}</span>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- 代码生成选项 -->
      <div class="gen-options">
        <div class="section-header">
          <span class="section-title">生成选项</span>
        </div>

        <div class="options-form">
          <div class="form-row">
            <label>模块名：</label>
            <el-input v-model="moduleName" placeholder="如: sales, wms, fsm" size="small" style="width:200px" />
          </div>

          <div class="form-row">
            <label>生成内容：</label>
            <el-checkbox v-model="genOptions.entity">Entity 实体类</el-checkbox>
            <el-checkbox v-model="genOptions.mapper">Mapper 接口</el-checkbox>
            <el-checkbox v-model="genOptions.service">Service 层</el-checkbox>
            <el-checkbox v-model="genOptions.controller">Controller</el-checkbox>
          </div>

          <div class="form-row">
            <label>包路径：</label>
            <el-input v-model="packageName" placeholder="com.xinghai.erp.xxx" size="small" style="width:260px" />
          </div>
        </div>

        <div class="gen-actions">
          <el-button type="primary" @click="generateCode" :loading="genLoading" :disabled="!hasSelection">
            <el-icon><Upload /></el-icon> 生成代码
          </el-button>
          <el-button @click="downloadZip" :disabled="!zipReady">
            <el-icon><Download /></el-icon> 下载ZIP
          </el-button>
        </div>

        <!-- 生成结果 -->
        <div class="gen-result" v-if="genMessage">
          <pre>{{ genMessage }}</pre>
        </div>
      </div>
    </div>

    <!-- 无选中表时的占位 -->
    <div class="preview-panel empty" v-else>
      <div class="empty-tip">
        <el-icon size="48" color="#c0c4cc"><Document /></el-icon>
        <p>请从左侧选择一个数据表</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Search, Refresh, Upload, Download, Document } from '@element-plus/icons-vue'
import request from '@/utils/request'

const API_BASE = '/system/codegen'

// 左侧表列表
const tableLoading = ref(false)
const tableKeyword = ref('')
const allTables = ref([]) // 后端一次性返回全部
const tablePage = ref(1)
const tablePageSize = ref(30)
const selectedTable = ref('')

// 右侧预览
const tableMeta = ref({})
const metaLoading = ref(false)

// 生成选项
const moduleName = ref('')
const packageName = ref('com.xinghai.erp')
const genOptions = ref({ entity: true, mapper: true, service: true, controller: true })
const genLoading = ref(false)
const genMessage = ref('')
const zipReady = ref(false)
const lastGenPath = ref('')

let debounceTimer = null

const hasSelection = computed(() => {
  return selectedTable.value && Object.values(genOptions.value).some(v => v)
})

function debounceLoad() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    tablePage.value = 1
    loadTables()
  }, 300)
}

async function loadTables() {
  tableLoading.value = true
  try {
    const res = await request.get(`${API_BASE}/tables`)
    if (res.data && Array.isArray(res.data)) {
      // 后端一次性返回全部表，前端做过滤+分页
      const keyword = tableKeyword.value.toLowerCase()
      allTables.value = res.data
        .filter(t => !keyword || t.toLowerCase().includes(keyword))
        .map(t => ({ tableName: t, columnCount: '-' }))
    }
  } catch (e) {
    ElMessage.error('加载表列表失败')
  } finally {
    tableLoading.value = false
  }
}

// 过滤后的分页数据
const tableList = computed(() => {
  const start = (tablePage.value - 1) * tablePageSize.value
  return allTables.value.slice(start, start + tablePageSize.value)
})

const tableTotal = computed(() => allTables.value.length)

async function selectTable(t) {
  selectedTable.value = t.tableName
  // 自动从表名推断模块名
  if (!moduleName.value) {
    const parts = t.tableName.replace(/^tb_/, '').split('_')
    if (parts.length >= 2) {
      moduleName.value = parts[0]
    } else {
      moduleName.value = t.tableName.replace(/^tb_/, '').substring(0, 10)
    }
  }
  await loadMeta()
  genMessage.value = ''
  zipReady.value = false
}

async function loadMeta() {
  if (!selectedTable.value) return
  metaLoading.value = true
  try {
    const res = await request.get(`${API_BASE}/meta/${selectedTable.value}`)
    if (res.data.code === 0) {
      tableMeta.value = res.data.data || {}
      // 回填列数到列表
      const item = tableList.value.find(t => t.tableName === selectedTable.value)
      if (item) item.columnCount = tableMeta.value.columns?.length || 0
    }
  } catch (e) {
    ElMessage.error('加载表结构失败')
  } finally {
    metaLoading.value = false
  }
}

async function generateCode() {
  if (!selectedTable.value) {
    ElMessage.warning('请先选择一个表')
    return
  }
  if (!moduleName.value) {
    ElMessage.warning('请输入模块名')
    return
  }
  if (!Object.values(genOptions.value).some(v => v)) {
    ElMessage.warning('请至少选择一种生成内容')
    return
  }

  genLoading.value = true
  genMessage.value = ''
  try {
    const res = await request.post(`${API_BASE}/generate`, {
      tableName: selectedTable.value,
      module: moduleName.value,
      packageName: packageName.value,
      entity: genOptions.value.entity,
      mapper: genOptions.value.mapper,
      service: genOptions.value.service,
      controller: genOptions.value.controller
    })

    if (res.data.code === 0) {
      const data = res.data.data || {}
      const files = data.files || []
      lastGenPath.value = data.outputPath || ''
      genMessage.value = `✅ 生成成功！\n\n输出目录：${lastGenPath.value}\n\n生成文件：\n${files.map(f => '  ✓ ' + f).join('\n')}`
      zipReady.value = true
      ElMessage.success('代码生成成功，共 ' + files.length + ' 个文件')
    } else {
      genMessage.value = '❌ 生成失败：' + (res.data.message || '未知错误')
      ElMessage.error(res.data.message || '生成失败')
    }
  } catch (e) {
    genMessage.value = '❌ 请求失败：' + (e.message || '网络错误')
    ElMessage.error('请求失败')
  } finally {
    genLoading.value = false
  }
}

async function downloadZip() {
  if (!selectedTable.value) return
  try {
    const res = await request.get(`${API_BASE}/download/${selectedTable.value}`, {
      responseType: 'blob'
    })
    const blob = new Blob([res.data])
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${selectedTable.value}_code.zip`
    a.click()
    window.URL.revokeObjectURL(url)
    ElMessage.success('下载完成')
  } catch (e) {
    // 如果是流式响应，尝试从message里获取URL
    if (e.response?.data) {
      try {
        const text = await e.response.data.text()
        const json = JSON.parse(text)
        if (json.data?.zipPath) {
          ElMessage.info('ZIP路径：' + json.data.zipPath + '，请手动下载')
        }
      } catch {}
    }
    ElMessage.error('下载失败，请查看生成路径手动下载')
  }
}

// 初始化
loadTables()
</script>

<style scoped>
.codegen-container {
  display: flex;
  height: calc(100vh - 140px);
  gap: 12px;
  padding: 12px;
  background: #f5f7fa;
}

.table-panel {
  width: 280px;
  flex-shrink: 0;
  background: #fff;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  box-shadow: 0 1px 4px rgba(0,0,0,0.08);
}

.preview-panel {
  flex: 1;
  background: #fff;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 14px;
  overflow-y: auto;
  box-shadow: 0 1px 4px rgba(0,0,0,0.08);
}

.preview-panel.empty {
  justify-content: center;
  align-items: center;
}

.empty-tip {
  text-align: center;
  color: #909399;
}
.empty-tip p {
  margin-top: 12px;
  font-size: 14px;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 14px 8px;
  border-bottom: 1px solid #f0f0f0;
}
.panel-title {
  font-weight: 600;
  font-size: 14px;
  color: #303133;
}

.table-search {
  padding: 8px 12px;
  border-bottom: 1px solid #f0f0f0;
}

.table-list {
  flex: 1;
  overflow-y: auto;
  padding: 6px;
}

.table-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 10px;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.2s;
  font-size: 13px;
  margin-bottom: 2px;
}
.table-item:hover { background: #f5f7fa; }
.table-item.active { background: #ecf5ff; }
.table-item.active .table-name { color: #409eff; font-weight: 600; }

.table-name { color: #303133; font-family: 'Courier New', monospace; font-size: 12px; }
.table-count { color: #909399; font-size: 11px; }

.table-pagination {
  padding: 6px;
  border-top: 1px solid #f0f0f0;
  display: flex;
  justify-content: center;
}

.info-card {
  background: #f5f7fa;
  border-radius: 6px;
  padding: 10px 14px;
  display: flex;
  gap: 24px;
}
.info-row { display: flex; align-items: center; gap: 6px; font-size: 13px; }
.info-label { color: #909399; }
.info-value { color: #303133; font-weight: 600; }
.info-value.mono { font-family: 'Courier New', monospace; font-size: 12px; }

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}
.section-title { font-weight: 600; font-size: 14px; color: #303133; }

.column-section { flex: 1; }

.gen-options {
  background: #f5f7fa;
  border-radius: 6px;
  padding: 14px;
}

.options-form { margin-bottom: 14px; }
.form-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 10px;
  font-size: 13px;
}
.form-row label { color: #606266; min-width: 70px; }

.gen-actions {
  display: flex;
  gap: 10px;
  margin-bottom: 10px;
}

.gen-result {
  background: #1e1e1e;
  border-radius: 6px;
  padding: 12px;
  max-height: 200px;
  overflow-y: auto;
}
.gen-result pre {
  margin: 0;
  color: #d4d4d4;
  font-size: 12px;
  font-family: 'Courier New', monospace;
  white-space: pre-wrap;
  word-break: break-all;
}

.mono { font-family: 'Courier New', monospace; }
.text-primary { color: #409eff; }
.text-success { color: #67c23a; }
.text-danger { color: #f56c6c; }
</style>
