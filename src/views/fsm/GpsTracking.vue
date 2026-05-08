<template>
  <div class="gps-page">
    <el-row :gutter="16" class="mb-16">
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-value" style="color:#409EFF">{{ stats.online }}</div>
            <div class="stat-label">在线工程师</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-value" style="color:#67C23A">{{ stats.offline }}</div>
            <div class="stat-label">离线工程师</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-value" style="color:#909399">{{ stats.todayReports }}</div>
            <div class="stat-label">今日上报次数</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-value" style="color:#E6A23C">{{ lastUpdate }}</div>
            <div class="stat-label">最后更新</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 地图区域 -->
    <el-card class="mb-16">
      <template #header>
        <div class="card-header">
          <span>工程师实时位置</span>
          <el-button type="primary" size="small" @click="loadLocations" :loading="loading">
            刷新位置
          </el-button>
        </div>
      </template>
      <!-- 简单地图容器 -->
      <div id="map-container" class="map-container">
        <div v-if="engineerLocations.length === 0 && !loading" class="map-empty">
          <el-icon size="48" color="#909399"><Location /></el-icon>
          <p>暂无在线工程师位置数据</p>
          <p style="font-size:12px;color:#909399">等待工程师移动端上报GPS坐标</p>
        </div>
        <div v-else class="location-grid">
          <div
            v-for="loc in engineerLocations"
            :key="loc.engineerId"
            class="location-card"
            @click="showEngineerDetail(loc)"
          >
            <div class="loc-header">
              <span class="engineer-name">{{ loc.engineerName || '工程师#' + loc.engineerId }}</span>
              <el-tag size="small" type="success" effect="dark">在线</el-tag>
            </div>
            <div class="loc-coords">
              <span>📍 {{ Number(loc.latitude).toFixed(4) }}, {{ Number(loc.longitude).toFixed(4) }}</span>
            </div>
            <div class="loc-address" v-if="loc.address">{{ loc.address }}</div>
            <div class="loc-footer">
              <span>精度: {{ loc.accuracy }}m</span>
              <span>{{ formatTime(loc.serverTime) }}</span>
            </div>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 历史轨迹（简化版：只显示最近上报记录） -->
    <el-card>
      <template #header>
        <span>GPS上报记录</span>
      </template>
      <el-table :data="historyRecords" size="small" max-height="300" v-loading="loading">
        <el-table-column prop="engineerName" label="工程师" width="100" />
        <el-table-column prop="latitude" label="纬度" width="130">
          <template #default="{ row }">{{ Number(row.latitude).toFixed(6) }}</template>
        </el-table-column>
        <el-table-column prop="longitude" label="经度" width="130">
          <template #default="{ row }">{{ Number(row.longitude).toFixed(6) }}</template>
        </el-table-column>
        <el-table-column prop="accuracy" label="精度(m)" width="90" align="center" />
        <el-table-column prop="address" label="地址" min-width="150" show-overflow-tooltip />
        <el-table-column prop="serverTime" label="上报时间" width="160">
          <template #default="{ row }">{{ formatTime(row.serverTime) }}</template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 工程师详情弹窗 -->
    <el-dialog v-model="detailVisible" :title="detailEngineer?.engineerName + ' 位置详情'" width="500px">
      <div v-if="detailEngineer" class="detail-content">
        <el-descriptions :column="1" border size="small">
          <el-descriptions-item label="工程师">
            {{ detailEngineer.engineerName || 'ID: ' + detailEngineer.engineerId }}
          </el-descriptions-item>
          <el-descriptions-item label="纬度">
            {{ Number(detailEngineer.latitude).toFixed(6) }}
          </el-descriptions-item>
          <el-descriptions-item label="经度">
            {{ Number(detailEngineer.longitude).toFixed(6) }}
          </el-descriptions-item>
          <el-descriptions-item label="定位精度">
            {{ detailEngineer.accuracy }} 米
          </el-descriptions-item>
          <el-descriptions-item label="地址">
            {{ detailEngineer.address || '未知' }}
          </el-descriptions-item>
          <el-descriptions-item label="手机时间">
            {{ formatTime(detailEngineer.clientTime) }}
          </el-descriptions-item>
          <el-descriptions-item label="服务器时间">
            {{ formatTime(detailEngineer.serverTime) }}
          </el-descriptions-item>
        </el-descriptions>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { ElMessage } from 'element-plus'
import request from '@/utils/request'

const engineerLocations = ref([])
const historyRecords = ref([])
const loading = ref(false)
const detailVisible = ref(false)
const detailEngineer = ref(null)
const stats = ref({ online: 0, offline: 0, todayReports: 0 })
const lastUpdate = ref('--')

let autoRefreshTimer = null

function formatTime(time) {
  if (!time) return '--'
  const d = new Date(time)
  const pad = n => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
}

async function loadLocations() {
  loading.value = true
  try {
    const res = await request.get('/fsm/gps/online')
    engineerLocations.value = res.data || []
    historyRecords.value = [...engineerLocations.value]
    stats.value.online = engineerLocations.value.length
    if (engineerLocations.value.length > 0) {
      const latest = engineerLocations.value[0]
      lastUpdate.value = formatTime(latest.serverTime)
    }
  } catch (e) {
    ElMessage.error('加载位置失败')
  } finally {
    loading.value = false
  }
}

function showEngineerDetail(loc) {
  detailEngineer.value = loc
  detailVisible.value = true
}

onMounted(() => {
  loadLocations()
  // 每30秒自动刷新
  autoRefreshTimer = setInterval(loadLocations, 30000)
})

onUnmounted(() => {
  if (autoRefreshTimer) clearInterval(autoRefreshTimer)
})
</script>

<style scoped>
.gps-page { padding: 16px; }
.mb-16 { margin-bottom: 16px; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
.stat-card { text-align: center; padding: 8px 0; }
.stat-value { font-size: 28px; font-weight: bold; }
.stat-label { font-size: 13px; color: #909399; margin-top: 4px; }
.map-container { min-height: 200px; }
.map-empty {
  display: flex; flex-direction: column; align-items: center;
  justify-content: center; min-height: 200px; color: #909399;
}
.location-grid {
  display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 12px;
}
.location-card {
  background: #f5f7fa; border-radius: 8px; padding: 12px;
  cursor: pointer; transition: all 0.2s;
}
.location-card:hover { background: #ecf5ff; transform: translateY(-2px); box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
.loc-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.engineer-name { font-weight: 600; font-size: 14px; }
.loc-coords { font-size: 12px; color: #409EFF; margin-bottom: 4px; }
.loc-address { font-size: 12px; color: #606266; margin-bottom: 4px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.loc-footer { display: flex; justify-content: space-between; font-size: 11px; color: #909399; }
.detail-content { padding: 8px 0; }
</style>
