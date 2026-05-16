<template>
  <div class="dict-container">
    <!-- 左侧：字典类型列表 -->
    <div class="type-panel">
      <div class="panel-header">
        <span class="panel-title">字典类型</span>
        <el-button type="primary" size="small" @click="openAddType" plain>
          <el-icon><Plus /></el-icon> 新增类型
        </el-button>
      </div>

      <div class="type-search">
        <el-input v-model="typeKeyword" placeholder="搜索类型" clearable size="small" @clear="loadTypes" @keyup.enter="loadTypes">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
      </div>

      <div class="type-list" v-loading="typeLoading">
        <div
          v-for="t in typeList"
          :key="t.dictType"
          class="type-item"
          :class="{ active: selectedType === t.dictType }"
          @click="selectType(t)"
        >
          <span class="type-label">{{ t.dictLabel }}</span>
          <span class="type-code">{{ t.dictType }}</span>
          <el-tag size="small" type="info">{{ t.itemCount }}项</el-tag>
        </div>
        <el-empty v-if="!typeLoading && typeList.length === 0" description="暂无数据" :image-size="60" />
      </div>

      <div class="type-pagination">
        <el-pagination
          small
          layout="prev, pager, next"
          :total="typeTotal"
          :page-size="10"
          :current-page="typePage"
          @current-change="v => { typePage = v; loadTypes() }"
        />
      </div>
    </div>

    <!-- 右侧：字典项管理 -->
    <div class="item-panel">
      <div class="panel-header">
        <span class="panel-title">
          字典项
          <span v-if="selectedType" class="selected-type">（ {{ selectedTypeLabel }} ）</span>
        </span>
        <div class="header-actions">
          <el-button v-if="selectedType" type="primary" size="small" @click="openAddItem">
            <el-icon><Plus /></el-icon> 新增项
          </el-button>
        </div>
      </div>

      <div class="item-table" v-loading="itemLoading">
        <el-table :data="itemList" stripe size="small" v-if="selectedType">
          <el-table-column type="index" width="60" label="序号" align="center" />
          <el-table-column prop="dictLabel" label="名称" min-width="120" show-overflow-tooltip />
          <el-table-column prop="dictValue" label="值" min-width="120" show-overflow-tooltip />
          <el-table-column prop="dictCode" label="编码" min-width="200" show-overflow-tooltip />
          <el-table-column prop="sortOrder" label="排序" width="80" align="center" />
          <el-table-column label="状态" width="80" align="center">
            <template #default="{ row }">
              <el-tag :type="row.isActive === 1 ? 'success' : 'info'" size="small">
                {{ row.isActive === 1 ? '启用' : '禁用' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="120" fixed="right" align="center">
            <template #default="{ row }">
              <el-button type="primary" link size="small" @click="openEditItem(row)">编辑</el-button>
              <el-button type="danger" link size="small" @click="openDeleteItem(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>

        <el-empty v-if="!selectedType" description="请从左侧选择一个字典类型" :image-size="80" />
        <el-empty v-if="selectedType && !itemLoading && itemList.length === 0" description="该类型下暂无字典项" :image-size="60" />
      </div>
    </div>

    <!-- 字典项弹窗 -->
    <el-dialog v-model="itemDialogVisible" :title="itemDialogTitle" width="500px" destroy-on-close>
      <el-form ref="itemFormRef" :model="itemForm" label-width="80px" size="default">
        <el-form-item label="字典类型" prop="dictType" :rules="[{ required: true, message: '请输入字典类型' }]">
          <el-input v-model="itemForm.dictType" placeholder="如：sex" :disabled="isEditItem" />
        </el-form-item>
        <el-form-item label="名称" prop="dictLabel" :rules="[{ required: true, message: '请输入名称' }]">
          <el-input v-model="itemForm.dictLabel" placeholder="如：男" />
        </el-form-item>
        <el-form-item label="值" prop="dictValue" :rules="[{ required: true, message: '请输入值' }]">
          <el-input v-model="itemForm.dictValue" placeholder="如：1" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="itemForm.sortOrder" :min="0" :max="9999" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="itemForm.isActive">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="itemDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="itemSubmitting" @click="submitItem">确定</el-button>
      </template>
    </el-dialog>

    <!-- 新增类型弹窗 -->
    <el-dialog v-model="typeDialogVisible" title="新增字典类型" width="450px" destroy-on-close>
      <el-form ref="typeFormRef" :model="typeForm" label-width="80px" size="default">
        <el-form-item label="类型编码" prop="dictType" :rules="[{ required: true, message: '请输入类型编码' }]">
          <el-input v-model="typeForm.dictType" placeholder="如：sex（英文字母+下划线）" />
        </el-form-item>
        <el-form-item label="类型名称" prop="dictLabel" :rules="[{ required: true, message: '请输入类型名称' }]">
          <el-input v-model="typeForm.dictLabel" placeholder="如：性别" />
        </el-form-item>
        <el-form-item label="首项名称" :rules="[{ required: true, message: '请输入首项名称' }]">
          <el-input v-model="typeForm.firstLabel" placeholder="如：男（将自动创建第一个字典项）" />
        </el-form-item>
        <el-form-item label="首项值">
          <el-input v-model="typeForm.firstValue" placeholder="如：1" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="typeForm.isActive">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="typeDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="typeSubmitting" @click="submitType">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Search } from '@element-plus/icons-vue'
import request from '@/utils/request'

// ============ 字典类型 ============
const typeLoading = ref(false)
const typeList = ref([])
const typeTotal = ref(0)
const typePage = ref(1)
const typeKeyword = ref('')
const selectedType = ref('')
const selectedTypeLabel = ref('')
const typeDialogVisible = ref(false)
const typeSubmitting = ref(false)
const typeFormRef = ref()

const typeForm = reactive({
  dictType: '',
  dictLabel: '',
  firstLabel: '',
  firstValue: '',
  isActive: 1,
})

async function loadTypes() {
  typeLoading.value = true
  try {
    const res = await request.get('/system/dict/types/page', {
      params: { current: typePage.value, size: 10, dictType: typeKeyword.value || null, dictLabel: typeKeyword.value || null }
    })
    typeList.value = res.data?.records || []
    typeTotal.value = res.data?.total || 0
  } catch {
    typeList.value = []
  } finally {
    typeLoading.value = false
  }
}

function selectType(t) {
  selectedType.value = t.dictType
  selectedTypeLabel.value = t.dictLabel
  loadItems()
}

function openAddType() {
  typeForm.dictType = ''
  typeForm.dictLabel = ''
  typeForm.firstLabel = ''
  typeForm.firstValue = ''
  typeForm.isActive = 1
  typeDialogVisible.value = true
}

async function submitType() {
  try {
    await typeFormRef.value.validate()
  } catch {
    return
  }
  typeSubmitting.value = true
  try {
    // 新增字典类型 = 创建第一个字典项（类型本身通过第一个字典项隐式创建）
    await request.post('/system/dict/items', {
      dictType: typeForm.dictType,
      dictLabel: typeForm.firstLabel,
      dictValue: typeForm.firstValue || typeForm.firstLabel,
      isActive: typeForm.isActive,
      sortOrder: 0,
    })
    ElMessage.success('新增成功')
    typeDialogVisible.value = false
    loadTypes()
  } catch {
    ElMessage.error('新增失败')
  } finally {
    typeSubmitting.value = false
  }
}

// ============ 字典项 ============
const itemLoading = ref(false)
const itemList = ref([])
const itemDialogVisible = ref(false)
const itemSubmitting = ref(false)
const isEditItem = ref(false)
const editingItemId = ref(null)
const itemFormRef = ref()

const itemForm = reactive({
  dictType: '',
  dictLabel: '',
  dictValue: '',
  sortOrder: 0,
  isActive: 1,
})

const itemDialogTitle = computed(() => isEditItem.value ? '编辑字典项' : '新增字典项')

async function loadItems() {
  if (!selectedType.value) return
  itemLoading.value = true
  try {
    const res = await request.get('/system/dict/items', {
      params: { dictType: selectedType.value }
    })
    itemList.value = res.data || []
  } catch {
    itemList.value = []
  } finally {
    itemLoading.value = false
  }
}

function openAddItem() {
  isEditItem.value = false
  editingItemId.value = null
  Object.assign(itemForm, { dictType: selectedType.value, dictLabel: '', dictValue: '', sortOrder: itemList.value.length, isActive: 1 })
  itemDialogVisible.value = true
}

function openEditItem(row) {
  isEditItem.value = true
  editingItemId.value = row.id
  Object.assign(itemForm, { dictType: row.dictType, dictLabel: row.dictLabel, dictValue: row.dictValue, sortOrder: row.sortOrder, isActive: row.isActive })
  itemDialogVisible.value = true
}

async function openDeleteItem(row) {
  try {
    await ElMessageBox.confirm(`确定删除字典项「${row.dictLabel}」？`, '提示', { type: 'warning' })
    await request.delete(`/system/dict/items/${row.id}`)
    ElMessage.success('删除成功')
    loadItems()
    loadTypes() // 更新计数
  } catch (e) {
    if (e !== 'cancel') ElMessage.error('删除失败')
  }
}

async function submitItem() {
  try {
    await itemFormRef.value.validate()
  } catch {
    return
  }
  itemSubmitting.value = true
  try {
    if (isEditItem.value) {
      await request.put(`/system/dict/items/${editingItemId.value}`, { ...itemForm })
      ElMessage.success('更新成功')
    } else {
      await request.post('/system/dict/items', { ...itemForm })
      ElMessage.success('新增成功')
    }
    itemDialogVisible.value = false
    loadItems()
    loadTypes()
  } catch {
    ElMessage.error(isEditItem.value ? '更新失败' : '新增失败')
  } finally {
    itemSubmitting.value = false
  }
}

onMounted(loadTypes)
</script>

<style scoped>
.dict-container {
  display: flex;
  height: 100%;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}

.type-panel {
  width: 280px;
  min-width: 280px;
  background: #fff;
  border-radius: 4px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px;
  border-bottom: 1px solid #f0f0f0;
  flex-shrink: 0;
}

.panel-title {
  font-size: 14px;
  font-weight: 600;
  color: #303133;
}

.selected-type {
  font-weight: 400;
  color: #909399;
  font-size: 13px;
}

.header-actions {
  display: flex;
  gap: 8px;
}

.type-search {
  padding: 8px 10px;
  border-bottom: 1px solid #f0f0f0;
  flex-shrink: 0;
}

.type-list {
  flex: 1;
  overflow-y: auto;
  padding: 6px 0;
}

.type-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  cursor: pointer;
  transition: background 0.15s;
  border-left: 3px solid transparent;
}

.type-item:hover {
  background: #f5f7fa;
}

.type-item.active {
  background: #ecf5ff;
  border-left-color: #409eff;
}

.type-label {
  font-size: 13px;
  color: #303133;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.type-code {
  font-size: 11px;
  color: #909399;
  font-family: monospace;
  flex-shrink: 0;
}

.type-pagination {
  padding: 6px;
  border-top: 1px solid #f0f0f0;
  display: flex;
  justify-content: center;
  flex-shrink: 0;
}

.item-panel {
  flex: 1;
  background: #fff;
  border-radius: 4px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.item-table {
  flex: 1;
  overflow-y: auto;
  padding: 0 12px 12px;
}
</style>
