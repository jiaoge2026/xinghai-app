<template>
  <div class="commission-page">
    <el-card>
      <el-tabs v-model="activeTab">

        <!-- ==================== 提成规则 ==================== -->
        <el-tab-pane label="提成规则" name="rules">
          <div class="toolbar">
            <el-button type="primary" :icon="Plus" @click="showRuleDialog(null)">新增规则</el-button>
          </div>

          <el-table :data="rules" v-loading="rulesLoading" stripe size="small">
            <el-table-column prop="ruleName" label="规则名称" min-width="140" />
            <el-table-column prop="applianceType" label="家电类型" width="120">
              <template #default="{ row }">{{ applianceLabel(row.applianceType) }}</template>
            </el-table-column>
            <el-table-column prop="serviceType" label="服务类型" width="100">
              <template #default="{ row }">{{ serviceLabel(row.serviceType) }}</template>
            </el-table-column>
            <el-table-column prop="calcType" label="计算方式" width="110">
              <template #default="{ row }">{{ calcTypeLabel(row.calcType) }}</template>
            </el-table-column>
            <el-table-column label="提成参数" width="150">
              <template #default="{ row }">
                <span v-if="row.calcType === 1">¥{{ row.perOrderAmt }}/次</span>
                <span v-else-if="row.calcType === 2">{{ (row.commissionRate * 100).toFixed(0) }}%收入</span>
                <span v-else-if="row.calcType === 3">¥{{ row.baseSalary }}+{{ (row.commissionRate * 100).toFixed(0) }}%</span>
                <span v-else>¥{{ row.perOrderAmt }}</span>
              </template>
            </el-table-column>
            <el-table-column label="评分奖金" width="110">
              <template #default="{ row }">
                <span v-if="row.bonusPerStar > 0">¥{{ row.bonusPerStar }}/星</span>
                <span v-else>-</span>
              </template>
            </el-table-column>
            <el-table-column prop="isDefault" label="默认" width="60" align="center">
              <template #default="{ row }">
                <el-tag v-if="row.isDefault === 1" type="warning" size="small">默认</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="70" align="center">
              <template #default="{ row }">
                <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">
                  {{ row.status === 1 ? '启用' : '停用' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="120" fixed="right">
              <template #default="{ row }">
                <el-button type="primary" link @click="showRuleDialog(row)">编辑</el-button>
                <el-button type="danger" link :disabled="row.isDefault === 1" @click="deleteRule(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- ==================== 月度结算 ==================== -->
        <el-tab-pane label="月度结算" name="settlements">
          <div class="toolbar">
            <el-form :inline="true">
              <el-form-item label="月份">
                <el-date-picker v-model="calcMonth" type="month" value-format="YYYY-MM"
                  placeholder="选择月份" style="width:130px" />
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="runCalculation" :loading="calcLoading">
                  结算该月
                </el-button>
              </el-form-item>
              <el-form-item label="结算月份">
                <el-date-picker v-model="settlementQuery.month" type="month" value-format="YYYY-MM"
                  placeholder="筛选月份" style="width:130px" clearable @change="fetchSettlements" />
              </el-form-item>
            </el-form>
          </div>

          <el-alert v-if="calcResult" :title="calcResult.message" type="success"
            style="margin-bottom:12px" show-icon :closable="false" />

          <el-table :data="settlements" v-loading="settlementLoading" stripe>
            <el-table-column prop="engineerName" label="工程师" min-width="100" />
            <el-table-column prop="settlementMonth" label="结算月" width="100" />
            <el-table-column prop="totalOrders" label="工单数" width="80" align="center" />
            <el-table-column prop="totalRevenue" label="总收入" width="110" align="right">
              <template #default="{ row }">{{ fmt(row.totalRevenue) }}</template>
            </el-table-column>
            <el-table-column label="提成组成" min-width="180">
              <template #default="{ row }">
                <span v-if="row.baseSalary > 0">固定¥{{ row.baseSalary }}</span>
                <span v-if="row.commissionAmt > 0"> + 收入¥{{ row.commissionAmt }}</span>
                <span v-if="row.goodRatingBonus > 0"> + 好评¥{{ row.goodRatingBonus }}</span>
                <span v-if="row.ratingPenalty > 0"> - 差评¥{{ row.ratingPenalty }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="finalAmount" label="应发提成" width="110" align="right">
              <template #default="{ row }"><b style="color:#67C23A">¥{{ row.finalAmount }}</b></template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="90" align="center">
              <template #default="{ row }">
                <el-tag :type="statusType(row.status)" size="small">{{ statusLabel(row.status) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="160" fixed="right">
              <template #default="{ row }">
                <el-button type="primary" link size="small" @click="showDetail(row)">明细</el-button>
                <el-button v-if="row.status === 1" type="success" link size="small" @click="confirmSettlement(row)">确认</el-button>
                <el-button v-if="row.status === 2" type="warning" link size="small" @click="markPaid(row)">发放</el-button>
              </template>
            </el-table-column>
          </el-table>

          <div class="pagination">
            <el-pagination
              v-model:current-page="settlementQuery.page"
              v-model:page-size="settlementQuery.pageSize"
              :total="settlementTotal"
              :page-sizes="[10,20,50]"
              layout="total,sizes,prev,pager,next"
              @change="fetchSettlements"
            />
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- ==================== 规则弹窗 ==================== -->
    <el-dialog v-model="ruleDialogVisible" :title="isEditRule ? '编辑规则' : '新增规则'" width="520px">
      <el-form :model="ruleForm" :rules="ruleFormRules" ref="ruleFormRef" label-width="110px">
        <el-form-item prop="ruleName" label="规则名称">
          <el-input v-model="ruleForm.ruleName" placeholder="如：空调维修-按收入比例" />
        </el-form-item>
        <el-form-item label="家电类型">
          <el-select v-model="ruleForm.applianceType" placeholder="不限制" clearable style="width:100%">
            <el-option v-for="a in APPLIANCE_OPTIONS" :key="a.value" :label="a.label" :value="a.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="服务类型">
          <el-select v-model="ruleForm.serviceType" placeholder="不限制" clearable style="width:100%">
            <el-option v-for="s in SERVICE_OPTIONS" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item prop="calcType" label="计算方式">
          <el-radio-group v-model="ruleForm.calcType">
            <el-radio :value="1">按次固定</el-radio>
            <el-radio :value="2">按收入比例</el-radio>
            <el-radio :value="3">基础+比例</el-radio>
            <el-radio :value="4">固定金额</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="ruleForm.calcType === 1" label="每单金额(元)">
          <el-input-number v-model="ruleForm.perOrderAmt" :min="0" :precision="2" />
        </el-form-item>
        <el-form-item v-if="ruleForm.calcType === 2" label="收入比例(%)">
          <el-input-number v-model="ruleForm.commissionRate" :min="0" :max="1" :step="0.01" />
        </el-form-item>
        <el-form-item v-if="ruleForm.calcType === 3" label="基础金额(元)">
          <el-input-number v-model="ruleForm.baseSalary" :min="0" :precision="2" />
        </el-form-item>
        <el-form-item v-if="ruleForm.calcType === 3" label="收入比例(%)">
          <el-input-number v-model="ruleForm.commissionRate" :min="0" :max="1" :step="0.01" />
        </el-form-item>
        <el-form-item v-if="ruleForm.calcType === 4" label="固定金额(元)">
          <el-input-number v-model="ruleForm.perOrderAmt" :min="0" :precision="2" />
        </el-form-item>
        <el-form-item label="好评奖金">
          <el-input-number v-model="ruleForm.bonusPerStar" :min="0" :precision="2" placeholder="每星多少钱" />
        </el-form-item>
        <el-form-item label="最低评分">
          <el-input-number v-model="ruleForm.minRating" :min="0" :max="5" :step="0.5" />
        </el-form-item>
        <el-form-item label="设为默认">
          <el-switch v-model="isDefaultRule" />
        </el-form-item>
        <el-form-item label="生效日期">
          <el-date-picker v-model="ruleForm.effectiveDate" type="date" value-format="YYYY-MM-DD" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="ruleForm.status">
            <el-radio :value="1">启用</el-radio>
            <el-radio :value="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="ruleDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="ruleSubmitting" @click="submitRule">保存</el-button>
      </template>
    </el-dialog>

    <!-- ==================== 明细弹窗 ==================== -->
    <el-dialog v-model="detailDialogVisible" title="提成明细" width="900px">
      <div v-if="detailSettlement" class="detail-summary">
        <span>{{ detailSettlement.engineerName }}</span>
        <span>{{ detailSettlement.settlementMonth }}</span>
        <span>共{{ detailSettlement.totalOrders }}单</span>
        <span>应发：<b style="color:#67C23A">¥{{ detailSettlement.finalAmount }}</b></span>
      </div>
      <el-table :data="detailList" stripe size="small">
        <el-table-column prop="workOrderNo" label="工单号" width="130" />
        <el-table-column prop="applianceType" label="家电" width="100">
          <template #default="{ row }">{{ applianceLabel(row.applianceType) }}</template>
        </el-table-column>
        <el-table-column prop="serviceType" label="服务" width="80">
          <template #default="{ row }">{{ serviceLabel(row.serviceType) }}</template>
        </el-table-column>
        <el-table-column prop="revenue" label="收入" width="100" align="right">
          <template #default="{ row }">{{ fmt(row.revenue) }}</template>
        </el-table-column>
        <el-table-column label="计算方式" width="100">
          <template #default="{ row }">{{ calcTypeLabel(row.calcTypeUsed) }}</template>
        </el-table-column>
        <el-table-column prop="commissionAmt" label="提成" width="100" align="right">
          <template #default="{ row }"><b>¥{{ row.commissionAmt }}</b></template>
        </el-table-column>
        <el-table-column prop="rating" label="评分" width="70" align="center">
          <template #default="{ row }">{{ row.rating ? row.rating + '★' : '-' }}</template>
        </el-table-column>
        <el-table-column prop="ratingBonus" label="评分奖/扣" width="100" align="right">
          <template #default="{ row }">
            <span :style="{color: row.ratingBonus > 0 ? '#67C23A' : row.ratingBonus < 0 ? '#F56C6C' : ''}">
              {{ row.ratingBonus ? (row.ratingBonus > 0 ? '+' : '') + '¥' + row.ratingBonus : '-' }}
            </span>
          </template>
        </el-table-column>
      </el-table>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import request from '@/utils/request'

const activeTab = ref('rules')

// ========== 常量 ==========
const APPLIANCE_OPTIONS = [
  { value: 'air_conditioner', label: '空调' },
  { value: 'refrigerator', label: '冰箱' },
  { value: 'washer', label: '洗衣机' },
  { value: 'water_heater', label: '热水器' },
  { value: 'television', label: '电视' },
  { value: 'kitchen_appliance', label: '厨房电器' },
  { value: 'other', label: '其他' },
]
const SERVICE_OPTIONS = [
  { value: 'repair', label: '维修' },
  { value: 'install', label: '安装' },
  { value: 'maintenance', label: '保养' },
  { value: 'inspection', label: '检修' },
]
const APPLIANCE_MAP = Object.fromEntries(APPLIANCE_OPTIONS.map(a => [a.value, a.label]))
const SERVICE_MAP = Object.fromEntries(SERVICE_OPTIONS.map(s => [s.value, s.label]))
const applianceLabel = (v) => APPLIANCE_MAP[v] || v || '-'
const serviceLabel = (v) => SERVICE_MAP[v] || v || '-'
const calcTypeLabel = (t) => ['', '按次固定', '按收入比例', '基础+比例', '固定金额'][t] || t
const statusLabel = (s) => ['', '待确认', '已确认', '已发放'][s] || s
const statusType = (s) => ['', 'warning', 'success', 'primary'][s] || 'info'
const fmt = (v) => v != null ? `¥${Number(v).toFixed(2)}` : '¥0.00'

// ========== 规则 ==========
const rules = ref([])
const rulesLoading = ref(false)
const ruleDialogVisible = ref(false)
const isEditRule = ref(false)
const ruleSubmitting = ref(false)
const ruleFormRef = ref()
const isDefaultRule = ref(false)
let ruleForm = reactive({
  id: null, ruleName: '', applianceType: null, serviceType: null,
  calcType: 1, perOrderAmt: 80, commissionRate: 0.1, baseSalary: 0,
  bonusPerStar: 20, minRating: 4, effectiveDate: '', status: 1
})
const ruleFormRules = {
  ruleName: [{ required: true, message: '请输入规则名称', trigger: 'blur' }],
  calcType: [{ required: true, message: '请选择计算方式', trigger: 'change' }],
}

const fetchRules = async () => {
  rulesLoading.value = true
  try {
    const res = await request.get('/hr/commission/rules')
    rules.value = res.data || []
  } catch { rules.value = [] } finally { rulesLoading.value = false }
}

const showRuleDialog = (row) => {
  if (row) {
    isEditRule.value = true
    Object.assign(ruleForm, {
      id: row.id, ruleName: row.ruleName, applianceType: row.applianceType,
      serviceType: row.serviceType, calcType: row.calcType,
      perOrderAmt: row.perOrderAmt || 0, commissionRate: row.commissionRate || 0,
      baseSalary: row.baseSalary || 0, bonusPerStar: row.bonusPerStar || 0,
      minRating: row.minRating || 0, effectiveDate: row.effectiveDate || '',
      status: row.status
    })
    isDefaultRule.value = row.isDefault === 1
  } else {
    isEditRule.value = false
    Object.assign(ruleForm, {
      id: null, ruleName: '', applianceType: null, serviceType: null,
      calcType: 1, perOrderAmt: 80, commissionRate: 0.1, baseSalary: 0,
      bonusPerStar: 20, minRating: 4, effectiveDate: '', status: 1
    })
    isDefaultRule.value = false
  }
  ruleDialogVisible.value = true
}

const submitRule = async () => {
  const valid = await ruleFormRef.value.validate().catch(() => false)
  if (!valid) return
  ruleSubmitting.value = true
  try {
    const payload = { ...ruleForm, isDefault: isDefaultRule.value ? 1 : 0 }
    if (isEditRule.value) {
      await request.post('/hr/commission/rules', payload)
    } else {
      await request.post('/hr/commission/rules', payload)
    }
    ElMessage.success('保存成功')
    ruleDialogVisible.value = false
    fetchRules()
  } finally { ruleSubmitting.value = false }
}

const deleteRule = async (row) => {
  await ElMessageBox.confirm(`确定删除规则「${row.ruleName}」？`, '确认删除')
  await request.delete(`/hr/commission/rules/${row.id}`)
  ElMessage.success('删除成功')
  fetchRules()
}

// ========== 结算 ==========
const calcMonth = ref('')
const calcLoading = ref(false)
const calcResult = ref(null)
const settlements = ref([])
const settlementLoading = ref(false)
const settlementTotal = ref(0)
let settlementQuery = reactive({ page: 1, pageSize: 20, month: '' })
const detailDialogVisible = ref(false)
const detailSettlement = ref(null)
const detailList = ref([])

const runCalculation = async () => {
  if (!calcMonth.value) { ElMessage.warning('请选择月份'); return }
  calcLoading.value = true
  calcResult.value = null
  try {
    const res = await request.post(`/hr/commission/calculate/${calcMonth.value}`)
    calcResult.value = res.data
    const engineers = res.data?.settlements?.length || 0
    const orders = res.data?.totalWorkOrders || 0
    ElMessage.success(`结算完成：${engineers}名工程师，${orders}个工单`)
    fetchSettlements()
  } catch (e) {
    ElMessage.error(e.message || '结算失败')
  } finally { calcLoading.value = false }
}

const fetchSettlements = async () => {
  settlementLoading.value = true
  try {
    const res = await request.get('/hr/commission/settlements', {
      params: { page: settlementQuery.page, size: settlementQuery.pageSize, month: settlementQuery.month }
    })
    settlements.value = res.data?.records || []
    settlementTotal.value = res.data?.total || 0
  } catch { settlements.value = [] } finally { settlementLoading.value = false }
}

const showDetail = async (row) => {
  try {
    const res = await request.get(`/hr/commission/settlements/${row.id}`)
    detailSettlement.value = res.data?.settlement
    detailList.value = res.data?.details || []
    detailDialogVisible.value = true
  } catch { ElMessage.error('加载明细失败') }
}

const confirmSettlement = async (row) => {
  await ElMessageBox.confirm(`确认「${row.engineerName}」${row.settlementMonth}的提成¥${row.finalAmount}？`, '确认结算')
  await request.post(`/hr/commission/settlements/${row.id}/confirm`)
  ElMessage.success('已确认')
  fetchSettlements()
}

const markPaid = async (row) => {
  await ElMessageBox.confirm(`确认「${row.engineerName}」的提成已发放？`, '确认发放')
  await request.post(`/hr/commission/settlements/${row.id}/pay`)
  ElMessage.success('已标记发放')
  fetchSettlements()
}

onMounted(() => { fetchRules(); fetchSettlements() })
</script>

<style scoped>
.commission-page { padding: 16px; }
.toolbar { margin-bottom: 12px; }
.detail-summary {
  display: flex; gap: 24px; margin-bottom: 12px; padding: 8px 12px;
  background: #f5f7fa; border-radius: 4px; font-size: 14px;
}
.pagination { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
