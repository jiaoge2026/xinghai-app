<template>
  <div class="xh-file-upload">
    <!-- 拖拽上传模式 -->
    <el-upload
      v-if="drag"
      ref="uploadRef"
      :action="uploadUrl"
      :accept="accept"
      :headers="headers"
      :data="extraData"
      :multiple="multiple"
      :disabled="disabled"
      :limit="maxCount"
      :file-list="fileList"
      :before-upload="handleBeforeUpload"
      :on-success="handleSuccess"
      :on-error="handleError"
      :on-remove="handleRemove"
      :on-exceed="handleExceed"
      drag
      class="xh-file-upload__drag"
    >
      <div class="xh-file-upload__drag-inner">
        <el-icon :size="32" color="#909399"><UploadFilled /></el-icon>
        <p class="xh-file-upload__drag-text">
          将文件拖到此处，或<em>点击上传</em>
        </p>
        <p v-if="tip" class="xh-file-upload__tip">{{ tip }}</p>
      </div>
    </el-upload>

    <!-- 按钮上传模式 -->
    <div v-else class="xh-file-upload__button">
      <el-upload
        ref="uploadRef"
        :action="uploadUrl"
        :accept="accept"
        :headers="headers"
        :data="extraData"
        :multiple="multiple"
        :disabled="disabled"
        :limit="maxCount"
        :file-list="fileList"
        :before-upload="handleBeforeUpload"
        :on-success="handleSuccess"
        :on-error="handleError"
        :on-remove="handleRemove"
        :on-exceed="handleExceed"
        :show-file-list="showFileList"
      >
        <el-button :type="buttonType" :icon="UploadFilled" :disabled="disabled">
          {{ buttonText }}
        </el-button>
      </el-upload>
      <p v-if="tip" class="xh-file-upload__tip">{{ tip }}</p>
    </div>

    <!-- 文件列表（自定义） -->
    <div v-if="showFileListCustom && fileList.length > 0" class="xh-file-upload__custom-list">
      <div
        v-for="(file, idx) in fileList"
        :key="file.uid || idx"
        class="xh-file-upload__file-item"
      >
        <el-icon class="xh-file-upload__file-icon"><Document /></el-icon>
        <el-tooltip :content="file.name" placement="top">
          <span class="xh-file-upload__file-name">{{ file.name }}</span>
        </el-tooltip>
        <span v-if="file.size" class="xh-file-upload__file-size">
          ({{ formatFileSize(file.size) }})
        </span>
        <el-button
          v-if="!disabled"
          link
          type="danger"
          :icon="Delete"
          class="xh-file-upload__remove"
          @click="handleRemove(file)"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { ElMessage, genFileId } from 'element-plus'
import { UploadFilled, Document, Delete } from '@element-plus/icons-vue'
import type { UploadRawFile, UploadFile, UploadFiles } from 'element-plus'

interface Props {
  /** v-model: 文件URL列表（多个）或单个URL */
  modelValue: string[] | string | null
  /** 接受的文件类型，如 '.pdf,.doc,.jpg' */
  accept?: string
  /** 单文件最大MB，默认 10 */
  maxSize?: number
  /** 最多上传数量，默认 10 */
  maxCount?: number
  /** 多选模式 */
  multiple?: boolean
  /** 禁用状态 */
  disabled?: boolean
  /** 提示文字 */
  tip?: string
  /** 上传地址 */
  uploadUrl?: string
  /** 额外上传参数 */
  extraData?: Record<string, any>
  /** 显示自带的文件列表 */
  showFileList?: boolean
  /** 显示自定义文件列表 */
  showFileListCustom?: boolean
  /** 拖拽上传模式 */
  drag?: boolean
  /** 按钮文字 */
  buttonText?: string
  /** 按钮类型 */
  buttonType?: string
}

const props = withDefaults(defineProps<Props>(), {
  accept: '',
  maxSize: 10,
  maxCount: 10,
  multiple: true,
  disabled: false,
  showFileList: true,
  showFileListCustom: true,
  drag: false,
  buttonText: '上传文件',
  buttonType: 'primary',
  uploadUrl: '/api/v1/common/upload',
})

const emit = defineEmits<{
  'update:modelValue': [val: string[] | string | null]
}>()

const uploadRef = ref()

/** 文件列表（用于 el-upload） */
const fileList = ref<UploadFiles>([])

/** 请求头（自动带上 token） */
const headers = computed(() => ({
  Authorization: `Bearer ${localStorage.getItem('token') || ''}`,
}))

/** 同步外部 v-model 到内部 fileList */
watch(
  () => props.modelValue,
  (val) => {
    if (!val) {
      fileList.value = []
      return
    }
    const urls = Array.isArray(val) ? val : [val]
    fileList.value = urls
      .filter(Boolean)
      .map((url, idx) => ({
        uid: -idx - 1,
        name: decodeURIComponent(url.split('/').pop() || `file-${idx}`),
        url: url as string,
        status: 'success',
      }))
  },
  { immediate: true }
)

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / 1048576).toFixed(1)} MB`
}

function handleBeforeUpload(file: UploadRawFile): boolean | Promise<void> {
  // 大小校验
  const maxBytes = props.maxSize * 1024 * 1024
  if (file.size > maxBytes) {
    ElMessage.error(`文件「${file.name}」超过${props.maxSize}MB限制`)
    return false
  }
  // 类型校验
  if (props.accept) {
    const acceptTypes = props.accept.split(',').map((t) => t.trim())
    const ext = '.' + file.name.split('.').pop()?.toLowerCase()
    const mimeType = file.type
    const accepted = acceptTypes.some((t) => {
      if (t.startsWith('.')) return ext === t.toLowerCase()
      if (t.includes('*')) return mimeType.startsWith(t.split('/')[0])
      return mimeType === t
    })
    if (!accepted) {
      ElMessage.error(`不支持「${file.name}」的文件类型，仅支持${props.accept}`)
      return false
    }
  }
  return true
}

function handleSuccess(response: any, file: UploadFile, files: UploadFiles) {
  if (response.code === 0 || response.code === 200) {
    const url = response.data?.url || response.data
    const urls = getCurrentUrls()
    urls.push(url)
    emit('update:modelValue', props.multiple ? urls : url)
    ElMessage.success('上传成功')
  } else {
    ElMessage.error(response.message || '上传失败')
  }
}

function handleError(err: any, file: UploadFile) {
  ElMessage.error(`「${file.name}」上传失败`)
}

function handleRemove(file: UploadFile) {
  const urls = getCurrentUrls()
  const idx = urls.indexOf(file.url as string)
  if (idx > -1) urls.splice(idx, 1)
  const newList = fileList.value.filter((f) => f.uid !== file.uid)
  fileList.value = newList
  emit('update:modelValue', urls.length > 0 ? urls : null)
}

function handleExceed(files: File[], uploadFiles: UploadFiles) {
  const count = props.maxCount - uploadFiles.length
  if (count <= 0) {
    ElMessage.warning(`最多只能上传 ${props.maxCount} 个文件`)
    return
  }
  ElMessage.warning(`还能再上传 ${count} 个文件`)
}

function getCurrentUrls(): string[] {
  const val = props.modelValue
  if (!val) return []
  return Array.isArray(val) ? val.filter(Boolean) : [val]
}
</script>

<style scoped>
.xh-file-upload__drag {
  width: 100%;
}

.xh-file-upload__drag-inner {
  padding: 32px 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.xh-file-upload__drag-text {
  margin: 0;
  font-size: 14px;
  color: #606266;
}

.xh-file-upload__drag-text em {
  color: #409eff;
  font-style: normal;
}

.xh-file-upload__tip {
  margin: 4px 0 0;
  font-size: 12px;
  color: #909399;
}

.xh-file-upload__button {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.xh-file-upload__custom-list {
  margin-top: 12px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.xh-file-upload__file-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 10px;
  background: #f5f7fa;
  border-radius: 4px;
}

.xh-file-upload__file-icon {
  color: #909399;
  flex-shrink: 0;
}

.xh-file-upload__file-name {
  font-size: 13px;
  color: #606266;
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.xh-file-upload__file-size {
  font-size: 12px;
  color: #909399;
  flex-shrink: 0;
}

.xh-file-upload__remove {
  padding: 2px;
  flex-shrink: 0;
}
</style>
