<template>
  <div class="workflow-definition">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>审批流程模板</span>
          <el-button type="primary" @click="showCreateDialog = true">
            <el-icon><Plus /></el-icon> 新建流程
          </el-button>
        </div>
      </template>

      <el-table :data="definitions" v-loading="loading" stripe>
        <el-table-column prop="workflowCode" label="流程代码" width="140" />
        <el-table-column prop="workflowName" label="流程名称" min-width="160" />
        <el-table-column prop="businessType" label="适用业务" width="120">
          <template #default="{ row }">
            <el-tag size="small">{{ row.businessType || '通用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="描述" min-width="200" show-overflow-tooltip />
        <el-table-column label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">
              {{ row.status === 1 ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="viewDetail(row)">查看</el-button>
            <el-button link type="danger" @click="deleteDef(row)" :loading="row.deleting">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新建/查看 弹窗 -->
    <el-dialog v-model="showCreateDialog" :title="viewDetailData ? '流程详情' : '新建审批流程'" width="700px" destroy-on-close>
      <el-form :model="form" label-width="100px" :disabled="!!viewDetailData">
        <el-form-item label="流程代码" required>
          <el-input v-model="form.workflowCode" placeholder="如: LEAVE_APPROVAL" :disabled="!!viewDetailData" />
        </el-form-item>
        <el-form-item label="流程名称" required>
          <el-input v-model="form.workflowName" placeholder="如: 请假审批流程" />
        </el-form-item>
        <el-form-item label="适用业务">
          <el-select v-model="form.businessType" placeholder="选择业务类型" style="width:100%">
            <el-option label="请假申请" value="LEAVE" />
            <el-option label="采购申请" value="PURCHASE" />
            <el-option label="费用报销" value="EXPENSE" />
            <el-option label="付款申请" value="PAYMENT" />
            <el-option label="通用审批" value="GENERAL" />
          </el-select>
        </el-form-item>
        <el-form-item label="流程描述">
          <el-input v-model="form.description" type="textarea" :rows="3" placeholder="描述此流程的用途和审批规则" />
        </el-form-item>

        <!-- 审批节点配置 -->
        <el-divider content-position="left">审批节点</el-divider>
        <div v-for="(node, idx) in form.nodes" :key="idx" class="node-item">
          <el-tag size="small" type="info">节点 {{ idx + 1 }}</el-tag>
          <el-form-item label="节点名称">
            <el-input v-model="node.nodeName" placeholder="如: 部门经理审批" />
          </el-form-item>
          <el-form-item label="审批人类型">
            <el-select v-model="node.approverType" placeholder="选择审批人类型" style="width:100%">
              <el-option label="指定人员" value="USER" />
              <el-option label="部门主管" value="MANAGER" />
              <el-option label="角色" value="ROLE" />
              <el-option label="上级" value="SUPERIOR" />
            </el-select>
          </el-form-item>
          <el-form-item label="审批人" v-if="node.approverType === 'USER'">
            <el-input v-model="node.approverId" placeholder="审批人用户ID" />
          </el-form-item>
          <el-form-item label="角色" v-if="node.approverType === 'ROLE'">
            <el-input v-model="node.approverRole" placeholder="角色代码" />
          </el-form-item>
          <el-form-item label="节点类型">
            <el-select v-model="node.nodeType" style="width:100%">
              <el-option label="或签(任一通过即可)" value="OR" />
              <el-option label="会签(全部通过)" value="AND" />
              <el-option label="顺序审批" value="SEQ" />
            </el-select>
          </el-form-item>
          <el-button link type="danger" @click="removeNode(idx)" v-if="form.nodes.length > 1">删除节点</el-button>
        </div>
        <el-button link type="primary" @click="addNode" :disabled="!!viewDetailData">+ 添加审批节点</el-button>
      </el-form>

      <template #footer>
        <el-button @click="showCreateDialog = false">取消</el-button>
        <el-button type="primary" @click="submitDefinition" v-if="!viewDetailData" :loading="submitting">
          确认创建
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'

const loading = ref(false)
const submitting = ref(false)
const showCreateDialog = ref(false)
const viewDetailData = ref(null)
const definitions = ref([])

const form = ref({
  workflowCode: '',
  workflowName: '',
  businessType: 'GENERAL',
  description: '',
  nodes: [
    { nodeName: '', approverType: 'MANAGER', approverId: '', approverRole: '', nodeType: 'OR' }
  ]
})

const loadDefinitions = async () => {
  loading.value = true
  try {
    const res = await request.get('/workflow/definitions')
    definitions.value = res.data || []
  } catch (e) {
    console.error('loadDefinitions error:', e)
    definitions.value = []
  } finally {
    loading.value = false
  }
}

const viewDetail = (row) => {
  viewDetailData.value = row
  form.value = {
    workflowCode: row.workflowCode,
    workflowName: row.workflowName,
    businessType: row.businessType || 'GENERAL',
    description: row.description || '',
    nodes: row.nodes || []
  }
  showCreateDialog.value = true
}

const addNode = () => {
  form.value.nodes.push({
    nodeName: '', approverType: 'MANAGER', approverId: '', approverRole: '', nodeType: 'OR'
  })
}

const removeNode = (idx) => {
  form.value.nodes.splice(idx, 1)
}

const submitDefinition = async () => {
  if (!form.value.workflowCode || !form.value.workflowName) {
    ElMessage.warning('流程代码和名称不能为空')
    return
  }
  submitting.value = true
  try {
    // 实际创建流程定义（后端B3任务完成后可用）
    ElMessage.success('流程模板创建成功（后端对接中）')
    showCreateDialog.value = false
    loadDefinitions()
  } catch (e) {
    ElMessage.error('创建失败: ' + (e.message || e))
  } finally {
    submitting.value = false
  }
}

const deleteDef = async (row) => {
  try {
    await ElMessageBox.confirm('确认删除流程 ' + row.workflowName + '？此操作不可恢复。', '删除确认', {
      type: 'warning'
    })
    ElMessage.info('删除功能后端对接中')
  } catch {
    // 用户取消
  }
}

onMounted(() => {
  loadDefinitions()
})
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.node-item {
  border: 1px solid #eee;
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 12px;
  background: #fafafa;
}
</style>
