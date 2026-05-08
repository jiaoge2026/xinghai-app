<template>
  <div class="menu-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>权限配置</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd(null)">新增权限</el-button>
        </div>
      </template>

      <el-table :data="menuTree" row-key="id" default-expand-all :tree-props="{ children: 'children', hasChildren: 'hasChildren' }">
        <el-table-column prop="name" label="权限名称" min-width="150" />
        <el-table-column prop="path" label="路由路径" min-width="150" />
        <el-table-column prop="icon" label="图标" width="120" />
        <el-table-column prop="sort" label="排序" width="80" align="center" />
        <el-table-column prop="type" label="类型" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.type === 1 ? 'primary' : 'success'" size="small">
              {{ row.type === 1 ? '菜单' : '按钮' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-switch v-model="row.status" :active-value="1" :inactive-value="0" @change="handleStatusChange(row)" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link :icon="Plus" @click="handleAdd(row.id)">新增子级</el-button>
            <el-button type="primary" link :icon="Edit" @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" link :icon="Delete" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="500px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="权限类型" prop="type">
          <el-radio-group v-model="form.type">
            <el-radio :value="1">菜单</el-radio>
            <el-radio :value="2">按钮</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="权限名称" prop="name">
          <el-input v-model="form.name" placeholder="如：工单管理" />
        </el-form-item>
        <el-form-item label="路由路径" prop="path">
          <el-input v-model="form.path" placeholder="如：/fsm/work-orders" />
        </el-form-item>
        <el-form-item label="上级权限" prop="parentId">
          <el-tree-select
            v-model="form.parentId"
            :data="menuTreeData"
            check-strictly
            :render-after-expand="false"
            placeholder="顶级权限可不选"
            clearable
            style="width:100%"
          />
        </el-form-item>
        <el-form-item label="图标">
          <el-input v-model="form.icon" placeholder="Element Plus 图标名，如：Document" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sort" :min="0" :max="999" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio :value="1">启用</el-radio>
            <el-radio :value="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete } from '@element-plus/icons-vue'
import request from '@/utils/request'

const menuList = ref([])
const dialogVisible = ref(false)
const submitting = ref(false)
const isEdit = ref(false)
const formRef = ref()

const form = reactive({
  id: null,
  name: '',
  path: '',
  type: 1,
  parentId: null,
  icon: '',
  sort: 0,
  status: 1
})

const rules = {
  name: [{ required: true, message: '请输入权限名称', trigger: 'blur' }],
  type: [{ required: true, message: '请选择权限类型', trigger: 'change' }]
}

const dialogTitle = computed(() => isEdit.value ? '编辑权限' : '新增权限')

// 构建树形结构
const menuTree = computed(() => {
  const map = {}
  const roots = []
  const list = [...menuList.value]
  list.forEach(item => { map[item.id] = { ...item, children: [] } })
  list.forEach(item => {
    if (item.parentId && map[item.parentId]) {
      map[item.parentId].children.push(map[item.id])
    } else {
      roots.push(map[item.id])
    }
  })
  return roots
})

const menuTreeData = computed(() => {
  const transform = (nodes) => nodes.map(n => ({ label: n.name, value: n.id, children: n.children?.length ? transform(n.children) : undefined }))
  return transform(menuTree.value)
})

const loadData = async () => {
  try {
    const res = await request.get('/system/menus')
    menuList.value = res.data || []
  } catch (e) {
    menuList.value = []
  }
}

const handleAdd = (parentId) => {
  isEdit.value = false
  Object.assign(form, { id: null, name: '', path: '', type: 1, parentId, icon: '', sort: 0, status: 1 })
  dialogVisible.value = true
}

const handleEdit = (row) => {
  isEdit.value = true
  Object.assign(form, { ...row, type: row.type || 1 })
  dialogVisible.value = true
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  submitting.value = true
  try {
    if (isEdit.value) {
      await request.put(`/system/menus/${form.id}`, form)
      ElMessage.success('编辑成功')
    } else {
      await request.post('/system/menus', form)
      ElMessage.success('新增成功')
    }
    dialogVisible.value = false
    loadData()
  } finally {
    submitting.value = false
  }
}

const handleStatusChange = async (row) => {
  try {
    await request.put(`/system/menus/${row.id}`, { status: row.status })
    ElMessage.success(row.status === 1 ? '已启用' : '已禁用')
  } catch {
    row.status = row.status === 1 ? 0 : 1
  }
}

const handleDelete = async (row) => {
  await ElMessageBox.confirm(`确定删除权限「${row.name}」？`, '提示', { type: 'warning' })
  await request.delete(`/system/menus/${row.id}`)
  ElMessage.success('删除成功')
  loadData()
}

onMounted(loadData)
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
