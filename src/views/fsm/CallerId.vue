<template>
  <div class="caller-id-page">
    <el-card>
      <template #header>
        <div style="display:flex;justify-content:space-between;align-items:center">
          <span>来电弹屏管理</span>
          <el-button type="primary" @click="showRegisterDialog=true">注册号码</el-button>
        </div>
      </template>

      <!-- 搜索 -->
      <el-form inline @submit.prevent="loadData">
        <el-form-item label="手机号">
          <el-input v-model="searchPhone" placeholder="输入手机号搜索" clearable style="width:180px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadData">查询</el-button>
        </el-form-item>
      </el-form>

      <!-- 弹屏演示 -->
      <el-divider content-position="left">来电模拟演示</el-divider>
      <el-card shadow="never" style="background:#f5f7fa;margin-bottom:16px">
        <el-form inline>
          <el-form-item label="模拟来电号码">
            <el-input v-model="simPhone" placeholder="13800138000" style="width:180px" />
          </el-form-item>
          <el-form-item>
            <el-button type="success" @click="simulateCall">模拟来电</el-button>
          </el-form-item>
        </el-form>
      </el-card>

      <!-- 弹屏弹窗 -->
      <el-dialog v-model="popupVisible" title="来电弹屏" width="500px" :close-on-click-modal="false">
        <div v-if="popupData" class="popup-box">
          <div class="popup-header">
            <el-icon size="32" color="#67C23A"><Phone /></el-icon>
            <span class="popup-phone">{{ popupData.phone }}</span>
            <el-tag :type="popupData.matched ? 'success' : 'info'" size="large">
              {{ popupData.matched ? '已匹配客户' : '陌生来电' }}
            </el-tag>
          </div>

          <div v-if="popupData.matched && popupData.customer" class="popup-section">
            <div class="popup-section-title">客户信息</div>
            <el-descriptions :column="1" border size="small">
              <el-descriptions-item label="姓名">{{ popupData.customer.name }}</el-descriptions-item>
              <el-descriptions-item label="电话">{{ popupData.customer.phone }}</el-descriptions-item>
              <el-descriptions-item label="地址">{{ popupData.customer.address || '无' }}</el-descriptions-item>
              <el-descriptions-item label="来源">{{ popupData.customer.source || '无' }}</el-descriptions-item>
            </el-descriptions>
          </div>

          <div v-if="popupData.matched && popupData.recentWorkOrders && popupData.recentWorkOrders.length > 0" class="popup-section">
            <div class="popup-section-title">最近工单</div>
            <el-table :data="popupData.recentWorkOrders" size="small" stripe>
              <el-table-column prop="wo_no" label="工单号" width="140" />
              <el-table-column prop="appliance_type" label="家电" width="80" />
              <el-table-column prop="service_type" label="服务类型" width="80" />
              <el-table-column prop="status" label="状态" width="60">
                <template #default="{row}">
                  <el-tag size="small" :type="statusTagType(row.status)">{{ statusName(row.status) }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="total_fee" label="费用" />
            </el-table>
          </div>

          <div v-if="popupData.matched && popupData.engineer" class="popup-section">
            <div class="popup-section-title">服务工程师</div>
            <el-descriptions :column="1" border size="small">
              <el-descriptions-item label="工程师">{{ popupData.engineer.name }}</el-descriptions-item>
              <el-descriptions-item label="电话">{{ popupData.engineer.phone }}</el-descriptions-item>
              <el-descriptions-item label="技能">{{ popupData.engineer.skill_tags }}</el-descriptions-item>
            </el-descriptions>
          </div>

          <div v-if="!popupData.matched" class="popup-section">
            <el-empty description="该号码未在系统中注册，无法提供弹屏信息" />
          </div>
        </div>
      </el-dialog>

      <!-- 注册弹窗 -->
      <el-dialog v-model="showRegisterDialog" title="注册来电号码" width="480px">
        <el-form :model="registerForm" label-width="100px">
          <el-form-item label="手机号" required>
            <el-input v-model="registerForm.phone" placeholder="工程师/客户手机号" />
          </el-form-item>
          <el-form-item label="绑定客户ID" required>
            <el-input-number v-model="registerForm.customerId" :min="1" style="width:100%" />
          </el-form-item>
          <el-form-item label="绑定工程师ID">
            <el-input-number v-model="registerForm.engineerId" :min="1" style="width:100%" />
          </el-form-item>
          <el-form-item label="启用弹屏">
            <el-switch v-model="registerForm.enablePopup" />
          </el-form-item>
        </el-form>
        <template #footer>
          <el-button @click="showRegisterDialog=false">取消</el-button>
          <el-button type="primary" @click="doRegister">确认注册</el-button>
        </template>
      </el-dialog>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive } from "vue";
import { ElMessage } from "element-plus";
import { Phone } from "@element-plus/icons-vue";

const API = "/api/fsm/caller-id";

// 状态
const searchPhone = ref("");
const simPhone = ref("13800138000");
const popupVisible = ref(false);
const popupData = ref(null);
const showRegisterDialog = ref(false);

let registerForm = reactive({
  phone: "",
  customerId: null,
  engineerId: null,
  enablePopup: true,
});

// 加载数据
async function loadData() {
  if (!searchPhone.value) return;
  const res = await fetch(`${API}/lookup?phone=${searchPhone.value}`);
  const json = await res.json();
  popupData.value = json.data;
  popupVisible.value = true;
}

// 模拟来电
async function simulateCall() {
  if (!simPhone.value) return;
  const res = await fetch(`${API}/lookup?phone=${simPhone.value}`);
  const json = await res.json();
  popupData.value = json.data;
  popupVisible.value = true;
}

// 注册
async function doRegister() {
  if (!registerForm.phone || !registerForm.customerId) {
    ElMessage.warning("手机号和客户ID不能为空");
    return;
  }
  const res = await fetch(`${API}/register`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(registerForm),
  });
  const json = await res.json();
  if (json.code === 0) {
    ElMessage.success("注册成功");
    showRegisterDialog.value = false;
  } else {
    ElMessage.error(json.message);
  }
}

// 状态名称
function statusName(status) {
  const map = { 1: "待派单", 2: "已派单", 3: "进行中", 4: "已完成", 5: "待结算", 6: "已取消" };
  return map[status] || status;
}

function statusTagType(status) {
  const map = { 1: "info", 2: "primary", 3: "warning", 4: "success", 5: "warning", 6: "danger" };
  return map[status] || "info";
}
</script>

<style scoped>
.caller-id-page { padding: 0; }
.popup-box { padding: 8px; }
.popup-header {
  display: flex; align-items: center; gap: 12px;
  padding: 16px; background: #f0f9eb; border-radius: 8px; margin-bottom: 16px;
}
.popup-phone { font-size: 24px; font-weight: bold; flex: 1; }
.popup-section { margin-bottom: 16px; }
.popup-section-title { font-weight: bold; margin-bottom: 8px; color: #409EFF; }
</style>
