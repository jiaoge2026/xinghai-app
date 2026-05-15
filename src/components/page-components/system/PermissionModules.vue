<template>
  <div class="section">
    <div class="section-title">功能权限（勾选该角色可执行的操作）</div>
    <div class="perm-modules">
      <div v-for="mod in modules" :key="mod.module" class="perm-module">
        <div class="perm-module-title">{{ getModuleName(mod.module) }}</div>
        <el-checkbox-group v-model="checked">
          <el-checkbox
            v-for="p in mod.permissions"
            :key="p.id"
            :value="p.id"
            :label="p.id"
          >
            {{ p.permissionName }}
            <span class="perm-code">{{ p.permissionCode }}</span>
          </el-checkbox>
        </el-checkbox-group>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Permission {
  id: number
  permissionName: string
  permissionCode: string
}

interface PermissionModule {
  module: string
  permissions: Permission[]
}

const props = defineProps<{
  modules: PermissionModule[]
  modelValue: number[]
}>()

const emit = defineEmits<{
  'update:modelValue': [val: number[]]
}>()

const checked = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})

// 模块中文名
const moduleNames: Record<string, string> = {
  fsm: 'FSM工单',
  wms: '库存备件',
  logistics: '物流配送',
  retail: '零售门店',
  crm: 'CRM客户',
  member: '会员管理',
  finance: '财务管理',
  hr: '人事管理',
  qa: '质量管理',
  report: '报表驾驶舱',
  system: '系统管理',
}

function getModuleName(m: string): string {
  return moduleNames[m] || m
}
</script>

<style scoped>
.section {
  margin-bottom: 24px;
}
.section-title {
  font-weight: 600;
  font-size: 14px;
  margin-bottom: 12px;
  color: #333;
}
.perm-modules {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}
.perm-module {
  border: 1px solid #eee;
  border-radius: 4px;
  padding: 12px;
}
.perm-module-title {
  font-weight: 600;
  font-size: 13px;
  margin-bottom: 8px;
  color: #409eff;
}
.perm-code {
  color: #999;
  font-size: 11px;
  margin-left: 4px;
}
:deep(.el-checkbox) {
  margin-bottom: 8px;
}
</style>
