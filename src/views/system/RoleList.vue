<template>
  <div class="role-list">
<div class="panel">
      <SearchForm
        :fields="searchFields"
        v-model="queryParams"
        @search="handleSearch"
        @reset="handleReset"
      />
    </div>

    <div class="panel">
      <DataTable
        :show-index="false"
        :data="tableData"
        :columns="tableColumns"
        :loading="loading"
        :pagination="pagination"
        row-key="id"
        @page-change="handlePageChange"
        @size-change="handleSizeChange"
        @action="handleTableAction">

        <template #header___seq__>
          <span>序号</span>
          <ColumnSettings
            :columns="tableColumns"
            page-path="/system/roles"
            @change="onColumnConfigChange"
          >
            <template #trigger>
              <el-icon class="seq-settings-btn"><Setting /></el-icon>
            </template>
          </ColumnSettings>
        </template>
      
      </DataTable>
    </div>

    <!-- 分配权限 — 两栏对照式 -->
    <el-dialog
      v-model="permVisible"
      title="分配权限"
      width="960px"
      destroy-on-close
      class="perm-dialog"
    >
      <!-- 弹窗头部：角色信息 -->
      <div class="perm-header">
          <div class="perm-tree-wrap">
            <!-- 调试：显示数据长度 -->
            <div style="padding:4px 8px;background:#fdf6ec;color:#e6a23c;font-size:12px;">
              菜单数据：{{ menuTree.length }} 个节点
            </div>
            <el-input v-model="menuSearch" placeholder="搜索菜单..." prefix-icon="Search" style="margin-bottom:8px;" />
          <span class="role-name">{{ permData.roleName }}</span>
          <span class="role-code">{{ permData.roleCode }}</span>
        </div>
        <div class="perm-summary" v-if="permSummary.total > 0">
          <el-tag type="success" size="small" effect="light">
            {{ permSummary.checked }} / {{ permSummary.total }} 个模块已授权
          </el-tag>
        </div>
      </div>

      <!-- 两栏主体 -->
      <div class="perm-body">
        <!-- 左栏：菜单搜索 + 分组树 -->
        <div class="perm-left">
          <div class="perm-left-header">
            <span class="section-label">模块菜单</span>
            <el-input
              v-model="menuSearch"
              placeholder="搜索模块..."
              prefix-icon="Search"
              size="small"
              clearable
              class="menu-search-input"
            />
          </div>

          <div class="menu-tree-wrap" v-loading="permLoading">
          <el-tree
            ref="treeRef"
            :data="menuTree"
            node-key="id"
            show-checkbox
            check-strictly
            :expand-on-click-node="false"
            default-expand-all
            class="perm-tree"
            :props="{ label: 'name' }"
            @node-click="handleMenuClick"
            @check="handleCheckChange"
          >
            <template #default="{ data }">
              <span class="tree-node-row">
                <span class="node-icon-wrap">
                  <el-icon><Menu /></el-icon>
                </span>
                <span class="node-name">{{ data.name }}</span>
              </span>
            </template>
          </el-tree>

            <div v-if="filteredGroupedTree.length === 0 && menuSearch" class="search-empty">
              <el-icon size="32" color="#c0c4cc"><Search /></el-icon>
              <p>未找到「{{ menuSearch }}」相关模块</p>
            </div>
          </div>
        </div>

        <!-- 右栏：选中菜单详情 -->
        <div class="perm-right">
          <div class="perm-right-header">
            <span class="section-label">权限详情</span>
          </div>

          <!-- 无选中菜单时 -->
          <div v-if="!selectedMenuNode" class="perm-right-empty">
            <el-icon size="48" color="#dcdfe6"><Menu /></el-icon>
            <p class="empty-hint">从左侧选择一个模块<br>查看其操作权限</p>
          </div>

          <!-- 选中菜单详情 -->
          <div v-else class="menu-detail-panel">
            <div class="detail-menu-card">
              <div class="detail-icon-wrap" :style="{ background: selectedMenuNode.iconColor + '22' }">
                <el-icon size="24" :style="{ color: selectedMenuNode.iconColor }">
                  <component :is="getIcon(selectedMenuNode.icon)" />
                </el-icon>
              </div>
              <div class="detail-info">
                <div class="detail-menu-name">{{ selectedMenuNode.name }}</div>
                <div class="detail-menu-path">{{ selectedMenuNode.path }}</div>
              </div>
              <div class="detail-check-status">
                <el-tag v-if="isMenuChecked(selectedMenuNode.id)" type="success" size="small" effect="dark">
                  <el-icon size="10"><CircleCheck /></el-icon> 已授权
                </el-tag>
                <el-tag v-else type="info" size="small" effect="light">未授权</el-tag>
              </div>
            </div>

            <!-- 权限代码标签 -->
            <div class="detail-section">
              <div class="detail-section-title">
                <el-icon size="13"><Key /></el-icon>
                操作权限码
              </div>
              <div v-if="selectedMenuNode.permissionCodes?.length" class="perm-codes-wrap">
                <el-tag
                  v-for="code in selectedMenuNode.permissionCodes"
                  :key="code"
                  size="small"
                  effect="plain"
                  class="perm-code-tag"
                  :type="isMenuChecked(selectedMenuNode.id) ? 'success' : 'info'"
                >
                  {{ code }}
                </el-tag>
              </div>
              <div v-else class="no-perm-codes">
                <el-icon size="14" color="#c0c4cc"><InfoFilled /></el-icon>
                <span>该模块暂未配置操作权限码</span>
              </div>
            </div>

            <!-- 快速操作 -->
            <div class="detail-section" v-if="selectedMenuNode.children?.length">
              <div class="detail-section-title">
                <el-icon size="13"><Operation /></el-icon>
                包含子模块（{{ selectedMenuNode.children.length }}个）
              </div>
              <div class="sub-menus-wrap">
                <div
                  v-for="child in selectedMenuNode.children"
                  :key="child.id"
                  class="sub-menu-item"
                  :class="{ 'is-checked': isMenuChecked(child.id) }"
                >
                  <el-icon size="12" :style="{ color: child.iconColor }">
                    <component :is="getIcon(child.icon)" />
                  </el-icon>
                  <span class="sub-menu-name">{{ child.name }}</span>
                  <el-icon v-if="isMenuChecked(child.id)" size="12" color="#67c23a"><CircleCheck /></el-icon>
                </div>
              </div>
            </div>

            <!-- 快捷全选/取消 -->
            <div class="quick-actions">
              <el-button
                v-if="!isMenuChecked(selectedMenuNode.id)"
                type="primary"
                size="small"
                @click="checkMenu(selectedMenuNode.id)"
              >
                <el-icon size="12"><Select /></el-icon> 授权此模块
              </el-button>
              <el-button
                v-else
                type="danger"
                size="small"
                plain
                @click="uncheckMenu(selectedMenuNode.id)"
              >
                <el-icon size="12"><Close /></el-icon> 取消授权
              </el-button>
              <el-button
                v-if="selectedMenuNode.children?.length"
                size="small"
                @click="checkMenuWithChildren(selectedMenuNode)"
              >
                含子模块全授权
              </el-button>
            </div>
          </div>
        </div>
      </div>

      <!-- 底部工具栏 -->
      <template #footer>
        <div class="perm-footer">
          <span class="perm-tip">
            <el-icon size="12"><InfoFilled /></el-icon>
            勾选父模块会自动包含其子模块
          </span>
          <div class="footer-actions">
            <el-button @click="permVisible = false" size="small">取消</el-button>
            <el-button type="primary" :loading="permLoading" @click="handleSavePerm" size="small">
              保存配置
            </el-button>
          </div>
        </div>
      </template>
    </el-dialog>

    <!-- 新增/编辑 -->
    <el-dialog v-model="dialogVisible" :title="dialogMode === '\u7f16\u8f91' ? '\u7f16\u8f91\u89d2\u8272' : '\u65b0\u589e\u89d2\u8272'" width="500px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="角色名称" prop="roleName">
          <el-input v-model="formData.roleName" placeholder="如\uff1a\u8d22\u52a1\u7ecf\u7406" />
        </el-form-item>
        <el-form-item label="角色代码" prop="roleCode">
          <el-input v-model="formData.roleCode" placeholder="如\uff1afinance_manager" :disabled="dialogMode === '\u7f16\u8f91'" />
        </el-form-item>
        <el-form-item label="角色类型" prop="roleType">
          <el-select v-model="formData.roleType" style="width:100%">
            <el-option :label="'\u7cfb\u7edf\u7ba1\u7406'" :value="1" />
            <el-option :label="'\u4e1a\u52a1\u7ba1\u7406'" :value="2" />
            <el-option :label="'\u666e\u901a\u7528\u6237'" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="formData.description" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">\u53d6\u6d88</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSave">\u786e\u5b9a</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { SearchForm, DataTable} from '@/components/page-components'
import ColumnSettings from '@/views/components/ColumnSettings.vue'
// 用 shallowRef 避免深层响应式开销 + watch 强制触发 el-tree 更新
import { ref, reactive, watch, onMounted, computed, nextTick, triggerRef } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Setting, UserFilled, Key, Operation, CircleCheck, InfoFilled, Search, Menu, Select, Close } from '@element-plus/icons-vue'

// 图标映射（避免 fallback 到 Grid）
const iconMap = {
  DataAnalysis: 'DataAnalysis', Grid: 'Grid', OfficeBuilding: 'OfficeBuilding', Money: 'Money',
  UserFilled: 'UserFilled', Tools: 'Tools', Box: 'Box', Van: 'Van', Shop: 'Shop',
  Postcard: 'Postcard', CreditCard: 'CreditCard', Phone: 'Phone', CircleCheck: 'CircleCheck',
  DataBoard: 'DataBoard', Setting: 'Setting', ChatDotSquare: 'ChatDotSquare',
  MessageBox: 'MessageBox', Upload: 'Upload', Document: 'Document', List: 'List',
  Location: 'Location', Coin: 'Coin', DataLine: 'DataLine', Connection: 'Connection',
}
function getIcon(name) { return iconMap[name] || 'Grid' }
import request from '@/utils/request'

const loading = ref(false)
const tableData = ref([])
let pagination = reactive({ page: 1, pageSize: 20, total: 0 })
let queryParams = reactive({ roleName: '', roleCode: '', status: '' })

const searchFields = [
  { key: 'roleName', label: '\u89d2\u8272\u540d\u79f0', type: 'input', placeholder: '\u89d2\u8272\u540d\u79f0' },
  { key: 'roleCode', label: '\u89d2\u8272\u4ee3\u7801', type: 'input', placeholder: '\u89d2\u8272\u4ee3\u7801' },
]

function handleSearch(params) {
  Object.assign(queryParams, params)
  pagination.page = 1
  loadData()
}

function handleReset() {
  Object.assign(queryParams, { roleName: '', roleCode: '', status: '' })
  pagination.page = 1
  loadData()
}

const statusMap = { 1: { label: '\u6d3b\u8dc3', type: 'success' }, 0: { label: '\u7981\u7528', type: 'danger' } }


// Column settings
// mergedColumns uses tableColumns directly (plain array)
const onColumnConfigChange = (cols) => { Object.assign(tableColumns, cols) }

const tableColumns = [
  { key: '__seq__', label: '', width: 60, show: true, fixed: 'left', columnType: 'seq' },
  
  { key: 'roleName', label: '\u89d2\u8272\u540d\u79f0', width: 150 },
  { key: 'roleCode', label: '\u89d2\u8272\u4ee3\u7801', width: 160 },
  { key: 'description', label: '\u63cf\u8ff0', minWidth: 200, showOverflowTooltip: true },
  { key: 'userCount', label: '\u4eba\u6570', width: 80, align: 'center' },
  {
    key: 'status',
    label: '\u72b6\u6001',
    width: 90,
    align: 'center',
    columnType: 'switch',
    activeValue: 1,
    inactiveValue: 0,
    switchChange: (val, row) => handleStatusChange(row, val),
  },
  { key: 'createdAt', label: '\u521b\u5efa\u65f6\u95f4', width: 170 },
  {
    key: 'actions',
    label: '\u64cd\u4f5c',
    width: 180,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'perm', label: '\u5206\u914d\u6743\u9650', type: 'primary', size: 'small', link: true },
      { key: 'edit', label: '\u7f16\u8f91', type: 'primary', size: 'small', link: true },
      { key: 'delete', label: '\u5220\u9664', type: 'danger', size: 'small', link: true, danger: true },
    ],
  },
]

function handleTableAction(action, row) {
  if (action === 'perm') openPerm(row)
  else if (action === 'edit') openEdit(row)
  else if (action === 'delete') openDelete(row)
}

function handlePageChange(page) { pagination.page = page; loadData() }
function handleSizeChange(size) { pagination.pageSize = size; pagination.page = 1; loadData() }

async function handleStatusChange(row, val) {
  try {
    await request.put('/system/roles/' + row.id, { status: val })
    ElMessage.success(val === 1 ? '\u5df2\u542f\u7528' : '\u5df2\u7981\u7528')
  } catch { loadData() }
}

const dialogVisible = ref(false)
const dialogMode = ref('create')
const submitting = ref(false)
const editingId = ref(null)
const defaultForm = () => ({ roleName: '', roleCode: '', roleType: 3, description: '' })
let formData = reactive({ ...defaultForm() })
const formRules = {
  roleName: [{ required: true, message: '\u8bf7\u8f93\u5165\u89d2\u8272\u540d\u79f0', trigger: 'blur' }],
  roleCode: [
    { required: true, message: '\u8bf7\u8f93\u5165\u89d2\u8272\u4ee3\u7801', trigger: 'blur' },
    { pattern: /^[a-z_]+$/, message: '\u4ee3\u7801\u53ea\u80fd\u662f\u5c0f\u5199\u5b57\u6bcd+\u4e0b\u5212\u7ebf', trigger: 'blur' },
  ],
}
const formRef = ref(null)

function openAdd() {
  dialogMode.value = 'create'
  editingId.value = null
  Object.assign(formData, defaultForm())
  dialogVisible.value = true
}

function openEdit(row) {
  dialogMode.value = '\u7f16\u8f91'
  editingId.value = row.id
  Object.assign(formData, { roleName: row.roleName, roleCode: row.roleCode, roleType: row.roleType || 3, description: row.description || '' })
  dialogVisible.value = true
}

async function openDelete(row) {
  try {
    await ElMessageBox.confirm('\u786e\u5b9a\u5220\u9664\u89d2\u8272\u300c' + row.roleName + '\u300d\uff1f', '\u786e\u8ba4\u5220\u9664', { type: 'warning' })
    await request.delete('/system/roles/' + row.id)
    ElMessage.success('\u5df2\u5220\u9664')
    loadData()
  } catch (e) { if (e !== 'cancel') ElMessage.error('\u5220\u9664\u5931\u8d25') }
}

async function handleSave() {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (dialogMode.value === '\u7f16\u8f91') {
      await request.put('/system/roles/' + editingId.value, formData)
      ElMessage.success('\u7f16\u8f91\u6210\u529f')
    } else {
      await request.post('/system/roles', formData)
      ElMessage.success('\u65b0\u589e\u6210\u529f')
    }
    dialogVisible.value = false
    loadData()
  } catch { ElMessage.error(dialogMode.value === '\u7f16\u8f91' ? '\u7f16\u8f91\u5931\u8d25' : '\u65b0\u589e\u5931\u8d25') }
  finally { submitting.value = false }
}

const permVisible = ref(false)
const permLoading = ref(false)
const permData = ref({})
const menuTree = ref([])
const treeRef = ref(null)
const menuSearch = ref('')
const selectedMenuNode = ref(null)

// 模块颜色配置
const moduleColors = [
  '#409EFF', '#67c23a', '#e6a23c', '#f56c6c', '#909399',
  '#c71585', '#00b4d8', '#2ec4b6', '#e76f51', '#9b59b6',
  '#1abc9c', '#3498db', '#e74c3c', '#f39c12', '#27ae60',
]

function getMenuColor(index) {
  return moduleColors[index % moduleColors.length]
}

// 将扁平菜单树转换为嵌套结构（仅当后端数据是扁平时才需要重组）
function buildMenuTree(flatList) {
  const map = {}
  const roots = []
  flatList.forEach(item => {
    map[item.id] = { ...item, children: [], childCount: 0, iconColor: getMenuColor(flatList.indexOf(item)) }
  })
  flatList.forEach(item => {
    if (item.parentId && map[item.parentId]) {
      map[item.parentId].children.push(map[item.id])
      map[item.parentId].childCount = map[item.parentId].children.length
    } else {
      roots.push(map[item.id])
    }
  })
  return roots
}

// 自动检测并保留后端已有 children 结构，只补充 iconColor / childCount
function normalizeMenuData(list) {
  if (!list || !list.length) return []
  // 后端已带 children 嵌套，直接增强
  let idx = 0
  function enhance(nodes) {
    nodes.forEach(node => {
      node.iconColor = node.iconColor || getMenuColor(idx++)
      node.childCount = node.children?.length || 0
      if (node.children?.length) enhance(node.children)
    })
  }
  enhance(list)
  return list
}

// 按index给所有节点上色
function colorizeTree(nodes, colorFn) {
  nodes.forEach(node => {
    node.iconColor = colorFn()
    if (node.children?.length) colorizeTree(node.children, colorFn)
  })
}

// 监听搜索
watch(menuTree, async (val) => {
  triggerRef(menuTree)
  await nextTick()
}, { deep: true })

watch(menuSearch, val => {
  treeRef.value?.filter(val)
})

function filterMenu(value, data) {
  if (!menuSearch.value) return true
  return data.name.includes(menuSearch.value) || (data.path && data.path.includes(menuSearch.value))
}

// 后端返回数据已带 children，直接使用；只需补充缺失字段
const groupedMenuTree = computed(() => {
  return menuTree.value
})

const filteredGroupedTree = computed(() => {
  if (!menuSearch.value) return groupedMenuTree.value
  const result = []
  const search = menuSearch.value.toLowerCase()
  function searchIn(nodes) {
    nodes.forEach(node => {
      const nameMatch = (node.name || '').toLowerCase().includes(search)
      const pathMatch = (node.path || '').toLowerCase().includes(search)
      if (nameMatch || pathMatch) {
        result.push(node)
        // 匹配时继续搜子节点（但不重复加入父节点）
        if (node.children?.length) searchIn(node.children)
      } else if (node.children?.length) {
        // 父不匹配但有子可能匹配，递归搜
        searchIn(node.children)
      }
    })
  }
  searchIn(groupedMenuTree.value)
  return result
})

const permSummary = computed(() => {
  if (!treeRef.value) return { checked: 0, total: menuTree.value.length }
  const checked = (treeRef.value.getCheckedKeys() || [])
  return { checked: checked.length, total: menuTree.value.length }
})

function isMenuChecked(menuId) {
  if (!treeRef.value) return false
  return (treeRef.value.getCheckedKeys() || []).includes(menuId)
}

function checkMenu(menuId) {
  treeRef.value?.setChecked(menuId, true, false)
}

function uncheckMenu(menuId) {
  treeRef.value?.setChecked(menuId, false, false)
}

function checkMenuWithChildren(node) {
  treeRef.value?.setChecked(node.id, true, false)
  node.children?.forEach(child => {
    treeRef.value?.setChecked(child.id, true, false)
  })
}

// 节点点击选中并显示详情
function onTreeNodeClick(data) {
  selectedMenuNode.value = data
}

// el-tree check 事件：选中变化时也更新选中节点
function onTreeCheck(data, { checkedKeys }) {
  if (checkedKeys.includes(data.id)) {
    selectedMenuNode.value = data
  }
}

async function openPerm(row) {
  permData.value = { id: row.id, roleName: row.roleName, roleCode: row.roleCode, checkedKeys: [] }
  menuTree.value = []
  selectedMenuNode.value = null
  menuSearch.value = ''
  permLoading.value = true
  permVisible.value = true  // 先显示空状态
  try {
    const [menuRes, permRes] = await Promise.all([
      request.get('/system/menus'),
      request.get('/system/roles/' + row.id + '/menus'),
    ])
  const rawMenu = menuRes.data || []
  window.__menuData = rawMenu
  // 去掉嵌套children，只保留根节点，测试el-tree是否能显示简单数组
  const flatData = rawMenu.map(item => ({ id: item.id, name: item.name }))
  menuTree.value = flatData
  console.log('[DEBUG] menuTree.value.length=', menuTree.value.length, JSON.stringify(menuTree.value[0]))
    permData.value.checkedKeys = (permRes.data || []).map(m => m.menuId || m.id)
    await nextTick()
    // 等待 el-tree 渲染完成后再设置选中状态
    setTimeout(() => {
      if (permData.value.checkedKeys.length > 0) {
        permData.value.checkedKeys.forEach(id => treeRef.value?.setChecked(id, true, false))
      }
    }, 150)
  } catch {
    menuTree.value = []
    permData.value.checkedKeys = []
  } finally {
    permLoading.value = false
  }
}

async function handleSavePerm() {
  permLoading.value = true
  try {
    const checked = treeRef.value?.getCheckedKeys() || []
    await request.post('/system/roles/' + permData.value.id + '/menus', { menuIds: checked })
    ElMessage.success('权限配置已保存')
    permVisible.value = false
  } catch { ElMessage.error('保存失败') }
  finally { permLoading.value = false }
}

async function loadData() {
  loading.value = true
  try {
    const res = await request.get('/system/roles', {
      params: {
        pageNum: pagination.page,
        pageSize: pagination.pageSize,
        roleName: queryParams.roleName || undefined,
        roleCode: queryParams.roleCode || undefined,
      },
    })
    tableData.value = res.data?.list || []
    pagination.total = res.data?.total || 0
  } catch { tableData.value = [] }
  finally { loading.value = false }
}

onMounted(loadData)
</script>

<style scoped>
.role-list { padding: 12px; display: flex; flex-direction: column; gap: 12px; }
.panel { background: #fff; border-radius: 4px; padding: 12px 16px; }

/* seq column toolbar */
.table-header-bar {
  display: flex;
  align-items: center;
  justify-content: center;
}
.seq-settings-btn { cursor: pointer; color: #909399; transition: color 0.2s; }
.seq-settings-btn:hover { color: #409eff; }

/* =================== 权限弹窗两栏布局 =================== */
.perm-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: linear-gradient(135deg, #f0f7ff 0%, #e8f4fd 100%);
  border-radius: 8px;
  margin-bottom: 14px;
  border: 1px solid #d9ecff;
}
.perm-role-badge {
  display: flex;
  align-items: center;
  gap: 8px;
}
.role-icon { color: #409eff; }
.role-name { font-size: 15px; font-weight: 600; color: #303133; }
.role-code {
  font-size: 12px;
  color: #909399;
  background: #f4f4f5;
  padding: 2px 8px;
  border-radius: 10px;
  font-family: monospace;
}
.perm-summary { display: flex; align-items: center; gap: 8px; }

/* 两栏主体 */
.perm-body {
  display: flex;
  gap: 0;
  height: 440px;
  border: 1px solid #ebeef5;
  border-radius: 8px;
  overflow: hidden;
}

/* 左栏 */
.perm-left {
  width: 52%;
  border-right: 1px solid #ebeef5;
  display: flex;
  flex-direction: column;
  background: #fafafa;
}
.perm-left-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px 8px;
  border-bottom: 1px solid #f0f0f0;
  flex-shrink: 0;
}
.section-label {
  font-size: 12px;
  font-weight: 600;
  color: #606266;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
.menu-search-input { width: 150px; }
.menu-tree-wrap {
  flex: 1;
  overflow-y: auto;
  padding: 6px 8px;
}
.perm-tree { background: transparent; }

/* 树节点 */
.tree-node-row {
  display: flex;
  align-items: center;
  gap: 6px;
  width: 100%;
  padding: 2px 0;
}
.node-icon-wrap {
  width: 22px;
  height: 22px;
  border-radius: 5px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.node-name {
  flex: 1;
  font-size: 13px;
  color: #303133;
  font-weight: 500;
}
.node-count {
  font-size: 11px;
  color: #909399;
  background: #f0f2f5;
  padding: 1px 5px;
  border-radius: 8px;
  flex-shrink: 0;
}

/* 搜索空状态 */
.search-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 0;
  color: #c0c4cc;
  gap: 8px;
}
.search-empty p { font-size: 13px; margin: 0; }

/* 右栏 */
.perm-right {
  width: 48%;
  display: flex;
  flex-direction: column;
  background: #fff;
}
.perm-right-header {
  padding: 10px 12px 8px;
  border-bottom: 1px solid #f0f0f0;
  flex-shrink: 0;
}

/* 右栏空状态 */
.perm-right-empty {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  color: #dcdfe6;
}
.empty-hint {
  font-size: 13px;
  color: #c0c4cc;
  text-align: center;
  line-height: 1.6;
  margin: 0;
}

/* 选中菜单详情面板 */
.menu-detail-panel {
  flex: 1;
  overflow-y: auto;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

/* 菜单卡片 */
.detail-menu-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: linear-gradient(135deg, #f8fbff 0%, #f0f7ff 100%);
  border-radius: 8px;
  border: 1px solid #d9ecff;
}
.detail-icon-wrap {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.detail-info { flex: 1; min-width: 0; }
.detail-menu-name { font-size: 14px; font-weight: 600; color: #303133; margin-bottom: 3px; }
.detail-menu-path { font-size: 11px; color: #909399; font-family: monospace; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

/* 详情区段 */
.detail-section { }
.detail-section-title {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 11px;
  font-weight: 600;
  color: #909399;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 8px;
}

/* 权限码标签 */
.perm-codes-wrap {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.perm-code-tag {
  font-family: monospace;
  font-size: 11px;
  letter-spacing: 0.3px;
}

/* 无权限码 */
.no-perm-codes {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #c0c4cc;
  padding: 6px 0;
}

/* 子模块列表 */
.sub-menus-wrap {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.sub-menu-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 5px 8px;
  border-radius: 6px;
  font-size: 12px;
  color: #606266;
  background: #fafafa;
  transition: all 0.15s;
}
.sub-menu-item:hover { background: #f0f2f5; }
.sub-menu-item.is-checked { background: #f0f9eb; color: #67c23a; }
.sub-menu-name { flex: 1; }

/* 快捷操作按钮 */
.quick-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-top: 4px;
}

/* 底部工具栏 */
.perm-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}
.perm-tip {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #909399;
}
.footer-actions { display: flex; gap: 8px; }

/* el-dialog 内部样式覆盖 */
:deep(.el-dialog__body) { padding: 16px 20px 8px; }
:deep(.el-dialog__header) { padding: 14px 20px 0; border-bottom: none; }
:deep(.el-dialog__footer) { padding: 10px 20px 14px; border-top: 1px solid #f0f0f0; }

</style>