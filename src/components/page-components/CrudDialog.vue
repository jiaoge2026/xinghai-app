<template>
  <el-dialog
    v-model="visible"
    :title="resolvedTitle"
    :width="dialogWidth"
    :close-on-click-modal="mode === 'view' || !hasChanges"
    :show-close="true"
    :destroy-on-close="true"
    class="xh-crud-dialog"
    @close="handleClose"
  >
    <div v-loading="dialogLoading" class="xh-crud-dialog__body">
      <el-form
        ref="formRef"
        :model="formData"
        :rules="formRules"
        :label-width="labelWidth"
        :label-position="labelPosition"
        :disabled="mode === 'view'"
        class="xh-crud-dialog__form"
      >
        <!-- 双列布局 -->
        <div class="xh-crud-dialog__form-grid" :style="{ gridTemplateColumns: `1fr `.repeat(gridColumns).trim() }">
          <el-form-item
            v-for="field in visibleFields"
            :key="field.key"
            :label="field.label"
            :prop="field.key"
            :class="{ 'xh-crud-dialog__form-item--full': (field.cols || 1) >= 2 }"
          >
            <!-- Input -->
            <el-input
              v-if="field.type === 'input'"
              v-model="formData[field.key]"
              :placeholder="field.placeholder || `请输入${field.label}`"
              :clearable="true"
              :disabled="field.disabled || isFieldDisabled(field)"
              :maxlength="field.maxlength"
              :show-word-limit="!!field.maxlength"
              :type="field.inputType || 'text'"
              :rows="field.rows || 3"
              :autosize="field.autosize"
            />

            <!-- Number -->
            <el-input-number
              v-else-if="field.type === 'number'"
              v-model="formData[field.key]"
              :min="field.min"
              :max="field.max"
              :precision="field.precision"
              :disabled="field.disabled || isFieldDisabled(field)"
              :controls="field.controls !== false"
              :step="field.step || 1"
              placeholder=""
              style="width: 100%"
            />

            <!-- Textarea -->
            <el-input
              v-else-if="field.type === 'textarea'"
              v-model="formData[field.key]"
              type="textarea"
              :placeholder="field.placeholder || `请输入${field.label}`"
              :rows="field.rows || 3"
              :maxlength="field.maxlength"
              :show-word-limit="!!field.maxlength"
              :autosize="field.autosize || { minRows: 2, maxRows: 6 }"
              :disabled="field.disabled || isFieldDisabled(field)"
            />

            <!-- Select -->
            <el-select
              v-else-if="field.type === 'select'"
              v-model="formData[field.key]"
              :placeholder="field.placeholder || `请选择${field.label}`"
              :clearable="!field.required"
              :disabled="field.disabled || isFieldDisabled(field)"
              :multiple="field.multiple"
              :filterable="field.filterable"
              style="width: 100%"
            >
              <el-option
                v-for="opt in field.options"
                :key="opt.value"
                :label="opt.label"
                :value="opt.value"
                :disabled="opt.disabled"
              />
            </el-select>

            <!-- Radio -->
            <el-radio-group
              v-else-if="field.type === 'radio'"
              v-model="formData[field.key]"
              :disabled="field.disabled || isFieldDisabled(field)"
            >
              <el-radio
                v-for="opt in field.options"
                :key="opt.value"
                :value="opt.value"
              >
                {{ opt.label }}
              </el-radio>
            </el-radio-group>

            <!-- Switch -->
            <el-switch
              v-else-if="field.type === 'switch'"
              v-model="formData[field.key]"
              :disabled="field.disabled || isFieldDisabled(field)"
              :active-value="field.activeValue ?? 1"
              :inactive-value="field.inactiveValue ?? 0"
            />

            <!-- Date -->
            <el-date-picker
              v-else-if="field.type === 'date'"
              v-model="formData[field.key]"
              :type="field.dateType || 'date'"
              :placeholder="field.placeholder || `选择${field.label}`"
              :format="field.format"
              :value-format="field.valueFormat || 'YYYY-MM-DD'"
              :disabled="field.disabled || isFieldDisabled(field)"
              :shortcuts="field.shortcuts"
              style="width: 100%"
            />

            <!-- DateRange -->
            <el-date-picker
              v-else-if="field.type === 'date-range'"
              v-model="formData[field.key]"
              type="datetimerange"
              :placeholder="field.placeholder || `选择${field.label}`"
              :format="field.format || 'YYYY-MM-DD HH:mm'"
              :value-format="field.valueFormat || 'YYYY-MM-DD HH:mm:ss'"
              range-separator="至"
              start-placeholder="开始时间"
              end-placeholder="结束时间"
              :disabled="field.disabled || isFieldDisabled(field)"
              style="width: 100%"
            />

            <!-- ImageUpload -->
            <div v-else-if="field.type === 'image-upload'" class="xh-crud-dialog__image-upload">
              <el-upload
                :action="field.uploadUrl || '/api/v1/common/upload'"
                :headers="{ Authorization: `Bearer ${localStorage.getItem('token') || ''}` }"
                :data="field.extraData"
                :limit="field.limit || 1"
                :file-list="getFileList(field.key)"
                list-type="picture-card"
                :on-success="(res) => handleUploadSuccess(res, field.key)"
                :on-remove="(file) => handleUploadRemove(file, field.key)"
                :disabled="field.disabled || isFieldDisabled(field)"
              >
                <el-icon><Plus /></el-icon>
              </el-upload>
            </div>

            <!-- FileUpload -->
            <FileUpload
              v-else-if="field.type === 'file-upload'"
              v-model="formData[field.key]"
              :accept="field.accept"
              :max-size="field.maxSize"
              :multiple="field.multiple !== false"
              :disabled="field.disabled || isFieldDisabled(field)"
              :tip="field.tip"
            />

            <!-- AddressPicker -->
            <AddressPicker
              v-else-if="field.type === 'address-picker'"
              v-model="formData[field.key]"
              :disabled="field.disabled || isFieldDisabled(field)"
              :show-detail="field.showDetail !== false"
            />

            <!-- Editor（富文本，简单实现） -->
            <el-input
              v-else-if="field.type === 'editor'"
              v-model="formData[field.key]"
              type="textarea"
              :placeholder="field.placeholder || `请输入${field.label}`"
              :rows="field.rows || 8"
              :disabled="field.disabled || isFieldDisabled(field)"
            />

            <!-- Cascader -->
            <el-cascader
              v-else-if="field.type === 'cascader'"
              v-model="formData[field.key]"
              :options="field.options"
              :props="field.cascaderProps"
              :placeholder="field.placeholder || `选择${field.label}`"
              :disabled="field.disabled || isFieldDisabled(field)"
              :clearable="true"
              :filterable="field.filterable"
              style="width: 100%"
            />

            <!-- 静态文本（查看模式专用） -->
            <span
              v-else-if="field.type === 'static'"
              class="xh-crud-dialog__static"
            >
              {{ formData[field.key] || '-' }}
            </span>
          </el-form-item>
        </div>
      </el-form>
    </div>

    <!-- 底部按钮（view模式隐藏） -->
    <template #footer v-if="mode !== 'view'">
      <div class="xh-crud-dialog__footer">
        <span v-if="mode === 'edit' && hasChanges" class="xh-crud-dialog__changed-hint">
          <el-icon><CircleCheckFilled /></el-icon>
          有未保存的修改
        </span>
        <div class="xh-crud-dialog__footer-buttons">
          <el-button :size="size" @click="handleClose">
            {{ mode === 'edit' ? '取消' : '关闭' }}
          </el-button>
          <el-button
            v-if="mode === 'edit'"
            type="primary"
            :size="size"
            :loading="saving"
            @click="handleSave"
          >
            {{ confirmText || '保存' }}
          </el-button>
        </div>
      </div>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, CircleCheckFilled } from '@element-plus/icons-vue'
import FileUpload from '@/components/framework/Ui/FileUpload.vue'
import AddressPicker from '@/components/framework/Ui/AddressPicker.vue'
import type { FormInstance, FormRules } from 'element-plus'

export interface DialogField {
  key: string
  label: string
  type: 'input' | 'number' | 'textarea' | 'select' | 'radio' | 'switch'
              | 'date' | 'date-range' | 'image-upload' | 'file-upload'
              | 'address-picker' | 'editor' | 'cascader' | 'static'
  placeholder?: string
  required?: boolean
  rules?: any[]
  defaultValue?: any
  /** 占用列数（默认1，最大2） */
  cols?: number
  // select
  options?: Array<{ label: string; value: any; disabled?: boolean }>
  // number
  min?: number
  max?: number
  precision?: number
  step?: number
  controls?: boolean
  // input
  inputType?: string
  maxlength?: number
  rows?: number
  autosize?: { minRows?: number; maxRows?: number }
  // date
  dateType?: 'date' | 'datetime' | 'week' | 'month' | 'year'
  format?: string
  valueFormat?: string
  shortcuts?: any[]
  // cascader
  cascaderProps?: any
  options?: any[]
  // image/file upload
  uploadUrl?: string
  extraData?: Record<string, any>
  limit?: number
  accept?: string
  maxSize?: number
  multiple?: boolean
  tip?: string
  showDetail?: boolean
  // 通用
  disabled?: boolean
  filterable?: boolean
  show?: boolean
  /** 条件禁用 */
  if?: boolean | ((formData: any) => boolean)
}

interface Props {
  /** v-model: 控制显隐 */
  visible: boolean
  /** 模式：create=新建/edit=编辑/view=查看 */
  mode: 'create' | 'edit' | 'view'
  /** 弹窗标题 */
  title?: string
  /** 弹窗宽度 */
  width?: string | number
  /** 表单标签宽度 */
  labelWidth?: string
  /** 表单标签位置 */
  labelPosition?: 'left' | 'right' | 'top'
  /** 字段定义 */
  fields: DialogField[]
  /** 表单数据（v-model） */
  modelValue: Record<string, any>
  /** 保存中状态 */
  saving?: boolean
  /** 确认按钮文字 */
  confirmText?: string
  /** 尺寸 */
  size?: 'large' | 'default' | 'small'
  /** 双列布局列数，默认2 */
  gridColumns?: number
  /** 是否监听变化（编辑模式用于检测未保存修改） */
  watchChanges?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  title: '',
  width: '600px',
  labelWidth: '120px',
  labelPosition: 'right',
  saving: false,
  size: 'default',
  gridColumns: 2,
  watchChanges: true,
})

const emit = defineEmits<{
  'update:visible': [val: boolean]
  'update:modelValue': [val: Record<string, any>]
  save: [data: Record<string, any>]
  cancel: []
  loaded: [data: Record<string, any>]
}>()

const formRef = ref<FormInstance>()
const dialogLoading = ref(false)
const originalData = ref<Record<string, any>>({})

/** 内部表单数据 */
const formData = ref<Record<string, any>>({})

/** 是否显示 */
const visible = computed({
  get: () => props.visible,
  set: (val) => emit('update:visible', val),
})

/** 解析标题 */
const resolvedTitle = computed(() => {
  if (props.title) return props.title
  if (props.mode === 'create') return '新建'
  if (props.mode === 'edit') return '编辑'
  return '查看详情'
})

/** 弹窗宽度 */
const dialogWidth = computed(() => {
  if (props.mode === 'view') return '800px'
  return typeof props.width === 'number' ? `${props.width}px` : props.width
})

/** 可见字段 */
const visibleFields = computed(() =>
  props.fields.filter((f) => {
    if (f.show === false) return false
    if (typeof f.if === 'function') return f.if(formData.value)
    if (typeof f.if === 'boolean') return f.if
    return true
  })
)

/** 是否有未保存修改（编辑模式） */
const hasChanges = computed(() => {
  if (!props.watchChanges || props.mode !== 'edit') return false
  return JSON.stringify(formData.value) !== JSON.stringify(originalData.value)
})

/** 表单验证规则 */
const formRules = computed<FormRules>(() => {
  const rules: FormRules = {}
  props.fields.forEach((field) => {
    if (!field.rules && field.required) {
      rules[field.key] = [
        { required: true, message: `请${field.type === 'select' ? '选择' : '输入'}${field.label}`, trigger: ['blur', 'change'] },
      ]
    } else if (field.rules) {
      rules[field.key] = field.rules
    }
  })
  return rules
})

/** 初始化表单数据 */
function initFormData() {
  const data: Record<string, any> = {}
  props.fields.forEach((f) => {
    if (f.key in (props.modelValue || {})) {
      data[f.key] = props.modelValue[f.key]
    } else {
      data[f.key] = f.defaultValue ?? null
    }
  })
  formData.value = { ...data }
  originalData.value = { ...data }
}

/** 监听 visible 变化，打开时初始化数据 */
watch(
  () => props.visible,
  (val) => {
    if (val) {
      initFormData()
    }
  },
  { immediate: true }
)

/** 同步外部 modelValue 变化 */
watch(
  () => props.modelValue,
  (val) => {
    if (val && props.visible) {
      const data: Record<string, any> = {}
      props.fields.forEach((f) => {
        data[f.key] = f.key in val ? val[f.key] : f.defaultValue ?? null
      })
      formData.value = { ...data }
    }
  }
)

function isFieldDisabled(field: DialogField): boolean {
  if (typeof field.disabled === 'function') return field.disabled(formData.value)
  return false
}

function getFileList(key: string): any[] {
  const url = formData.value[key]
  if (!url) return []
  const urls = Array.isArray(url) ? url : [url]
  return urls
    .filter(Boolean)
    .map((u, idx) => ({
      uid: -idx - 1,
      name: decodeURIComponent(String(u).split('/').pop() || `image-${idx}`),
      url: u,
      status: 'success',
    }))
}

function handleUploadSuccess(response: any, key: string) {
  if (response.code === 0 || response.code === 200) {
    const url = response.data?.url || response.data
    formData.value[key] = url
    ElMessage.success('上传成功')
  }
}

function handleUploadRemove(_file: any, key: string) {
  formData.value[key] = null
}

async function handleSave() {
  if (!formRef.value) return
  try {
    await formRef.value.validate()
    emit('save', { ...formData.value })
  } catch (err) {
    // 验证失败，滚动到第一个错误字段
    ElMessage.error('请检查表单填写')
  }
}

function handleClose() {
  // 有未保存修改时弹出确认
  if (props.mode === 'edit' && hasChanges.value) {
    ElMessageBox.confirm('有未保存的修改，确定要关闭吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })
      .then(() => {
        visible.value = false
        emit('cancel')
      })
      .catch(() => {})
  } else {
    visible.value = false
    emit('cancel')
  }
}
</script>

<style scoped>
.xh-crud-dialog__body {
  padding: 8px 16px;
  max-height: calc(80vh - 120px);
  overflow-y: auto;
}

.xh-crud-dialog__form {
  /*  */
}

.xh-crud-dialog__form-grid {
  display: grid;
  gap: 0 16px;
}

.xh-crud-dialog__form-item--full {
  grid-column: 1 / -1;
}

.xh-crud-dialog__static {
  font-size: 14px;
  color: #303133;
  line-height: 32px;
}

.xh-crud-dialog__image-upload :deep(.el-upload-list__item) {
  width: 80px;
  height: 80px;
}

.xh-crud-dialog__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.xh-crud-dialog__changed-hint {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 13px;
  color: #e6a23c;
}

.xh-crud-dialog__footer-buttons {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}
</style>
