<template>
  <el-dialog
    v-model="dialogVisible"
    :title="dialogMode === 'create' ? '新增角色' : '编辑角色'"
    width="400"
    @close="handleClose"
  >
    <el-form ref="formRef" :model="roleForm" :rules="formRules" label-width="80">
      <el-form-item label="角色编码" prop="roleCode">
        <el-input
          v-model="roleForm.roleCode"
          placeholder="如：finance_manager"
          :disabled="dialogMode === 'update'"
        />
      </el-form-item>
      <el-form-item label="角色名称" prop="roleName">
        <el-input v-model="roleForm.roleName" placeholder="如：财务经理" />
      </el-form-item>
      <el-form-item label="角色类型" prop="roleType">
        <el-radio-group v-model="roleForm.roleType">
          <el-radio :value="1">系统角色</el-radio>
          <el-radio :value="2">业务角色</el-radio>
        </el-radio-group>
      </el-form-item>
      <el-form-item label="描述">
        <el-input v-model="roleForm.description" type="textarea" :rows="2" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="dialogVisible = false">取消</el-button>
      <el-button type="primary" @click="handleConfirm" :loading="dialogLoading">确定</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, watch, computed } from 'vue'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'

const props = defineProps<{
  modelValue: boolean
  mode: 'create' | 'update'
  roleData?: {
    id?: number
    roleCode: string
    roleName: string
    roleType?: number
    description?: string
  }
  loading?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [val: boolean]
  confirm: [data: { roleCode: string; roleName: string; roleType: number; description: string }]
}>()

const formRef = ref<FormInstance>()
const dialogVisible = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})

const dialogMode = computed(() => props.mode)
const dialogLoading = computed(() => props.loading || false)

const defaultForm = { roleCode: '', roleName: '', roleType: 2, description: '' }
const roleForm = reactive({ ...defaultForm })

const formRules: FormRules = {
  roleCode: [{ required: true, message: '请输入角色编码', trigger: 'blur' }],
  roleName: [{ required: true, message: '请输入角色名称', trigger: 'blur' }],
  roleType: [{ required: true, message: '请选择角色类型', trigger: 'change' }],
}

watch(
  () => props.modelValue,
  (visible) => {
    if (visible) {
      if (props.mode === 'update' && props.roleData) {
        Object.assign(roleForm, {
          roleCode: props.roleData.roleCode,
          roleName: props.roleData.roleName,
          roleType: props.roleData.roleType || 2,
          description: props.roleData.description || '',
        })
      } else {
        Object.assign(roleForm, defaultForm)
      }
    }
  }
)

function handleClose() {
  formRef.value?.resetFields()
}

async function handleConfirm() {
  if (!formRef.value) return
  try {
    await formRef.value.validate()
    emit('confirm', { ...roleForm })
  } catch {
    ElMessage.warning('请填写必填项')
  }
}
</script>
