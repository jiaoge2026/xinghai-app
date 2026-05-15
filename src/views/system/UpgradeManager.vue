<template>
  <div class="upgrade-manager">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>升级管理</span>
        </div>
      </template>

      <el-row :gutter="20" class="status-row">
        <el-col :span="8">
          <el-card shadow="hover" class="status-card">
            <div class="status-icon" :style="{ background: statusColor }">
              <el-icon :size="28"><component :is="iconMap[statusIcon]" /></el-icon>
            </div>
            <div class="status-info">
              <div class="status-label">升级状态</div>
              <div class="status-value">{{ statusText }}</div>
            </div>
          </el-card>
        </el-col>
        <el-col :span="16">
          <el-card shadow="hover" class="info-card">
            <div class="info-item">
              <span class="info-label">当前系统版本</span>
              <span class="info-value">v1.0</span>
            </div>
            <div class="info-item">
              <span class="info-label">升级包存放目录</span>
              <span class="info-value" style="font-size:12px">/home/admin/xinghai-erp/upgrade-packages/</span>
            </div>
            <div class="info-item">
              <span class="info-label">说明</span>
              <span class="info-value" style="color:#909399">导出：从源码构建增量升级包 &nbsp;|&nbsp; 导入：上传升级包自动执行升级</span>
            </div>
          </el-card>
        </el-col>
      </el-row>

      <el-divider content-position="left">构建升级包（从Git源码打增量包）</el-divider>

      <el-form ref="buildFormRef" :model="buildForm" :rules="buildFormRules" class="build-form" @submit.prevent>
        <el-form-item prop="version">
          <template #label><span class="action-label">版本号</span></template>
          <el-input
            v-model="buildForm.version"
            placeholder="如：v1.1"
            style="width:200px"
            @keyup.enter="handleBuild"
          />
          <span class="action-tip">Git tag 格式，如 v1.1、v2.0</span>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="building" @click="handleBuild">
            <el-icon v-if="!building"><Download /></el-icon>
            导出升级包
          </el-button>
          <span class="action-tip">点击后自动执行 git commit + git tag + 打包脚本</span>
        </el-form-item>
      </el-form>

      <el-divider content-position="left">导入升级包（上传并执行）</el-divider>

      <div class="action-section">
        <el-upload
          ref="uploadRef"
          class="upgrade-uploader"
          drag
          :action="importUrl"
          :headers="uploadHeaders"
          :before-upload="beforeUpload"
          :on-success="handleUploadSuccess"
          :on-error="handleUploadError"
          :on-progress="handleUploadProgress"
          accept=".tar.gz"
          :disabled="uploading"
        >
          <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
          <div class="el-upload__text">拖拽升级包到此处，或 <em>点击上传</em></div>
          <template #tip>
            <div class="el-upload__tip">只支持 .tar.gz 格式，文件大小不超过 100MB</div>
          </template>
        </el-upload>
        <div v-if="uploading" class="upload-progress">
          <el-progress :percentage="uploadPercent" :status="uploadPercent===100?'success':undefined" />
        </div>
      </div>

      <el-alert
        v-if="statusMessage"
        :title="statusMessage"
        :type="statusType"
        show-icon
        :closable="false"
        style="margin-top:20px"
      />
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import type { FormInstance, FormRules } from 'element-plus'
import { ElMessage } from 'element-plus'
import { Download, UploadFilled, CircleCheck, Warning, RefreshRight } from '@element-plus/icons-vue'
import request from '@/utils/request'

interface BuildForm {
  version: string
}

const iconMap: Record<string, unknown> = { CircleCheck, Warning, RefreshRight }

const buildFormRef = ref<FormInstance>()
const buildForm = reactive<BuildForm>({
  version: 'v1.1'
})
const buildFormRules: FormRules<BuildForm> = {
  version: [
    { required: true, message: '请输入版本号', trigger: ['blur', 'change'] },
    { pattern: /^v\d+(\.\d+)*$/, message: '格式错误，例：v1.1、v2.0.1', trigger: ['blur', 'change'] }
  ]
}

const building = ref(false)
const uploading = ref(false)
const uploadPercent = ref(0)
const uploadRef = ref()
const upgradeStatus = ref('IDLE')
const statusMessage = ref('')

const statusMap = {
  IDLE: { color: '#67C23A', icon: 'CircleCheck', text: '空闲' },
  UPGRADING: { color: '#409EFF', icon: 'RefreshRight', text: '升级进行中' },
  SUCCESS: { color: '#67C23A', icon: 'CircleCheck', text: '升级成功' },
  FAILED: { color: '#F56C6C', icon: 'Warning', text: '升级失败' }
}

const statusColor = computed(() => statusMap[upgradeStatus.value]?.color || '#909399')
const statusIcon = computed(() => statusMap[upgradeStatus.value]?.icon || 'RefreshRight')
const statusText = computed(() => statusMap[upgradeStatus.value]?.text || '未知')
const statusType = computed(() => {
  if (upgradeStatus.value === 'SUCCESS') return 'success'
  if (upgradeStatus.value === 'FAILED') return 'error'
  return 'info'
})

const importUrl = computed(() => `${import.meta.env.VITE_API_BASE_URL || "/api"}/system/upgrade/import`)
const uploadHeaders = computed(() => ({ Authorization: `Bearer ${localStorage.getItem('token') || ''}` }))

let pollTimer: ReturnType<typeof setInterval> | null = null

const loadStatus = async () => {
  try {
    const res = await request.get('/system/upgrade/status')
    if (res.code === 0 && res.data) {
      upgradeStatus.value = res.data.status || 'IDLE'
      statusMessage.value = res.data.message || ''
    }
  } catch (e) {
    // silent fail
  }
}

const handleBuild = async () => {
  if (!buildFormRef.value) return
  await buildFormRef.value.validate(async (valid) => {
    if (!valid) return
    building.value = true
    statusMessage.value = ''
    try {
      const res = await request.post('/system/upgrade/build', { version: buildForm.version })
      if (res.code === 0 && res.data?.downloadUrl) {
        const link = document.createElement('a')
        link.href = res.data.downloadUrl
        link.download = res.data.fileName
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        ElMessage.success(`升级包已生成并开始下载：${res.data.fileName}`)
      } else {
        ElMessage.error(res.message || '构建失败')
      }
    } catch (e: unknown) {
      ElMessage.error('构建升级包失败：' + ((e as Error).message || '未知错误'))
    } finally {
      building.value = false
    }
  })
}

const beforeUpload = (file: { name: string; size: number }) => {
  if (!file.name.endsWith('.tar.gz')) { ElMessage.error('只支持 .tar.gz 格式'); return false }
  if (file.size > 100 * 1024 * 1024) { ElMessage.error('文件大小不能超过 100MB'); return false }
  uploading.value = true
  uploadPercent.value = 0
  statusMessage.value = '上传中...'
  return true
}

const handleUploadProgress = (event: { percent?: number }) => {
  uploadPercent.value = Math.round(event.percent || 0)
}

const handleUploadSuccess = (res: { code: number; data?: { message?: string }; message?: string }) => {
  uploading.value = false
  if (res.code === 0) {
    ElMessage.success(res.data?.message || '升级包已接收，升级进行中')
    upgradeStatus.value = 'UPGRADING'
    statusMessage.value = '升级进行中，请稍候...'
    uploadPercent.value = 100
    startPoll()
  } else {
    ElMessage.error(res.message || '上传失败')
    uploadPercent.value = 0
  }
}

const handleUploadError = () => {
  uploading.value = false
  uploadPercent.value = 0
  ElMessage.error('上传失败：网络错误')
}

const startPoll = () => {
  stopPoll()
  pollTimer = setInterval(async () => {
    await loadStatus()
    if (upgradeStatus.value !== 'UPGRADING') stopPoll()
  }, 3000)
}

const stopPoll = () => {
  if (pollTimer) { clearInterval(pollTimer); pollTimer = null }
}

onMounted(() => {
  loadStatus()
  if (upgradeStatus.value === 'UPGRADING') startPoll()
})

onUnmounted(() => { stopPoll() })
</script>

<style scoped>
.upgrade-manager { max-width: 900px; }
.status-row { margin-bottom: 20px; }
.status-card { display:flex; align-items:center; gap:16px; padding:8px; }
.status-icon { width:56px; height:56px; border-radius:12px; display:flex; align-items:center; justify-content:center; color:#fff; flex-shrink:0; }
.status-info { flex:1; }
.status-label { font-size:12px; color:#909399; margin-bottom:4px; }
.status-value { font-size:18px; font-weight:600; color:#303133; }
.info-card .info-item { display:flex; gap:12px; margin-bottom:10px; font-size:14px; }
.info-card .info-item:last-child { margin-bottom:0; }
.info-label { color:#909399; flex-shrink:0; width:120px; }
.info-value { color:#303133; }
.build-form { max-width: 400px; }
.build-form .el-form-item { margin-bottom: 16px; }
.action-label { font-size:14px; color:#606266; }
.action-tip { font-size:12px; color:#909399; margin-left: 8px; }
.upload-progress { margin-top:16px; }
</style>
