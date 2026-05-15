<template>
  <div class="work-order-list">
    <!-- 搜索表单 -->
    <div class="panel">
      <SearchForm
        :fields="searchFields"
        v-model="queryParams"
        layout="inline"
        @search="handleSearch"
        @reset="handleReset"
      />
    </div>

    <!-- 表格 + 右上角操作按钮 -->
    <div class="panel table-panel">
      <div class="table-toolbar">
        <el-button icon="Download" @click="openExport">导出</el-button>
        <el-button icon="Printer" @click="handlePrint" :disabled="!selectedRows.length">打印</el-button>
        <el-button type="primary" icon="Plus" @click="openAdd">新建工单</el-button>
      </div>
      <DataTable
        ref="dataTableRef"
        :data="tableData"
        :columns="tableColumns"
        :loading="loading"
        :pagination="pagination"
        :height="tableHeight"
        row-key="hsicrmWorkorderid"
        :show-index="false"
        index-label="序号"
        :index-width="80"
        :show-pagination="true"
        :page-sizes="[20, 50, 100, 200]"
        :selectable="true"
        @update:selected-rows="selectedRows = $event"
        @page-change="handlePageChange"
        @size-change="handleSizeChange"
        @action="handleTableAction"
        @row-click="openDetail"
      >
        <template #header___seq__>
          <span>序号</span>
          <ColumnSettings
            :columns="tableColumns"
            page-path="/fsm/work-orders"
            @change="onColumnConfigChange"
          >
            <template #trigger>
              <el-icon class="seq-settings-btn"><Setting /></el-icon>
            </template>
          </ColumnSettings>
        </template>
        <template #header_hsicrmWorkorderid>
          <span>工单编号</span>
        </template>
      </DataTable>
    </div>

    <!-- 导出弹窗 -->
    <el-dialog v-model="exportDialogVisible" title="导出工单" width="480px" destroy-on-close>
      <el-form label-width="90px" size="default">
        <el-form-item label="筛选条件">
          <div style="color:#909399;font-size:12px;">
            <span v-if="queryParams.woNo">工单号: {{ queryParams.woNo }}；</span>
            <span v-if="queryParams.customerName">客户: {{ queryParams.customerName }}；</span>
            <span v-if="queryParams.engineerName">工程师: {{ queryParams.engineerName }}；</span>
            <span v-if="queryParams.status">状态: {{ getStatusLabel(queryParams.status) }}；</span>
            <span v-if="queryParams.serviceType">服务类型: {{ queryParams.serviceType }}；</span>
            <span v-if="queryParams.dateRange && queryParams.dateRange.length === 2">
              日期: {{ queryParams.dateRange[0] }} ~ {{ queryParams.dateRange[1] }}
            </span>
            <span v-if="!queryParams.woNo && !queryParams.customerName && !queryParams.engineerName && !queryParams.status && !queryParams.serviceType && !(queryParams.dateRange && queryParams.dateRange.length === 2)">
              无筛选（导出全部）
            </span>
          </div>
        </el-form-item>
        <el-form-item label="导出说明">
          <div style="color:#909399;font-size:12px;">
            任务提交后可在「导出任务」页面查看进度并下载文件
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="exportDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="exporting" @click="confirmExport">确认导出</el-button>
      </template>
    </el-dialog>

    <!-- 详情弹窗（保留原有的多Tab详情结构，内容太丰富不适合用CrudDialog） -->
    <el-dialog
      v-model="detailDialogVisible"
      title="工单详情"
      width="900px"
      :close-on-click-modal="false"
      destroy-on-close
    >
      <div v-loading="detailLoading">
        <el-tabs v-if="Object.keys(detailData).length > 0">
          <!-- 基本信息 -->
          <el-tab-pane label="基本信息">
            <el-descriptions :column="3" border size="small">
              <el-descriptions-item label="工单编号" :span="2">{{ detailData.hsicrmWorkorderid || '-' }}</el-descriptions-item>
              <el-descriptions-item label="状态">
                <el-tag :type="getHaierStatusType(detailData.hsicrmWorkorderstatuscode)" size="small">
                  {{ detailData.hsicrmWorkorderstatusname || '-' }}
                </el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="创建时间">{{ formatTime(detailData.hsicrmRegistrationtime) }}</el-descriptions-item>
              <el-descriptions-item label="派工时间">{{ formatTime(detailData.hsicrmDispatchtime) }}</el-descriptions-item>
              <el-descriptions-item label="完工时间">{{ formatCompleteTime(detailData.hsicrmServicestationcompletetime) }}</el-descriptions-item>
              <el-descriptions-item label="服务站">{{ detailData.hsicrmServicestationname || '-' }}</el-descriptions-item>
              <el-descriptions-item label="服务类型">{{ detailData.hsicrmRequireservicetypename || '-' }}</el-descriptions-item>
              <el-descriptions-item label="预约服务模式">{{ detailData.hsicrmRequireservicemodename || '-' }}</el-descriptions-item>
              <el-descriptions-item label="来源">{{ detailData.hsicrmSourcename || '-' }}</el-descriptions-item>
              <el-descriptions-item label="派工方式">{{ detailData.hsicrmDispatchmode || '-' }}</el-descriptions-item>
              <el-descriptions-item label="是否网单">{{ detailData.hsicrmIsfromnetwork === 'Y' ? '是' : '否' }}</el-descriptions-item>
              <el-descriptions-item label="工单ID" :span="2">{{ detailData.hsicrmWorkorderid || '-' }}</el-descriptions-item>
            </el-descriptions>
          </el-tab-pane>

          <!-- 客户信息 -->
          <el-tab-pane label="客户信息">
            <el-descriptions :column="3" border size="small">
              <el-descriptions-item label="客户姓名">{{ detailData.hsicrmConsumername || '-' }}</el-descriptions-item>
              <el-descriptions-item label="性别">{{ detailData.hsicrmConsumersex === '1' ? '男' : detailData.hsicrmConsumersex === '2' ? '女' : '-' }}</el-descriptions-item>
              <el-descriptions-item label="客户编号">{{ detailData.hsicrmConsumerno || '-' }}</el-descriptions-item>
              <el-descriptions-item label="联系电话" :span="2">{{ detailData.hsicrmOtherphone ? detailData.hsicrmOtherphone.split(',')[0] : '-' }}</el-descriptions-item>
              <el-descriptions-item label="真实电话">
                <span v-if="detailData.hsicrmRealphone" style="color: #67c23a">{{ detailData.hsicrmRealphone }}</span>
                <el-button v-else-if="!detailData._decrypting" size="small" type="primary" @click="decryptPhone(detailData)">解密</el-button>
                <span v-else style="color: #999">解密中...</span>
              </el-descriptions-item>
              <el-descriptions-item label="其他电话">{{ detailData.hsicrmOtherphone || '-' }}</el-descriptions-item>
              <el-descriptions-item label="客户地址" :span="3">{{ detailData.hsicrmConsumeraddr || '-' }}</el-descriptions-item>
              <el-descriptions-item label="行业">{{ detailData.hsicrmIndustryname || '-' }}</el-descriptions-item>
              <el-descriptions-item label="会员类别">{{ detailData.hsicrmMembershipcategorycode || '-' }}</el-descriptions-item>
              <el-descriptions-item label="销售日期">{{ detailData.hsicrmSalesdate || '-' }}</el-descriptions-item>
            </el-descriptions>
          </el-tab-pane>

          <!-- 产品信息 -->
          <el-tab-pane label="产品信息">
            <el-descriptions :column="3" border size="small">
              <el-descriptions-item label="品牌">{{ detailData.hsicrmBrandname || '-' }}</el-descriptions-item>
              <el-descriptions-item label="品类">{{ detailData.hsicrmProductcategoryname || '-' }}</el-descriptions-item>
              <el-descriptions-item label="产品型号" :span="2">{{ detailData.hsicrmProductmodel || '-' }}</el-descriptions-item>
              <el-descriptions-item label="序列号">{{ detailData.hsicrmSerialnumber || '-' }}</el-descriptions-item>
              <el-descriptions-item label="保修类型">{{ detailData.hsicrmWarrantytype || '-' }}</el-descriptions-item>
              <el-descriptions-item label="产品问题描述" :span="2">{{ detailData.hsicrmConsumerdesc || '-' }}</el-descriptions-item>
              <el-descriptions-item label="发票号">{{ detailData.hsicrmInvoiceno || '-' }}</el-descriptions-item>
              <el-descriptions-item label="是否打印">{{ detailData.hsicrmIsprint === 'Y' ? '是' : '否' }}</el-descriptions-item>
            </el-descriptions>
          </el-tab-pane>

          <!-- 费用信息 -->
          <el-tab-pane label="费用信息">
            <el-descriptions :column="3" border size="small">
              <el-descriptions-item label="收费金额">
                <span style="color: #e6a23c; font-weight: bold">{{ detailData.hsicrmReceivedfee != null ? Number(detailData.hsicrmReceivedfee).toFixed(2) : '-' }}</span>
              </el-descriptions-item>
              <el-descriptions-item label="支付状态">{{ detailData.hsicrmPaystatus || '-' }}</el-descriptions-item>
              <el-descriptions-item label="支付方式">{{ detailData.hsicrmPaytypename || '-' }}</el-descriptions-item>
              <el-descriptions-item label="工时(分钟)">{{ detailData.hsicrmTimeduration || '-' }}</el-descriptions-item>
              <el-descriptions-item label="其他费用描述" :span="2">{{ detailData.hsicrmDispatchresultsdesc || '-' }}</el-descriptions-item>
            </el-descriptions>
          </el-tab-pane>

          <!-- 工程师信息 -->
          <el-tab-pane label="工程师信息">
            <el-descriptions :column="3" border size="small">
              <el-descriptions-item label="工程师姓名">{{ detailData.hsicrmEmployeename || '-' }}</el-descriptions-item>
              <el-descriptions-item label="工程师编号">{{ detailData.hsicrmEmployeenumber || '-' }}</el-descriptions-item>
              <el-descriptions-item label="服务网点">{{ detailData.hsicrmServicestationcode || '-' }}</el-descriptions-item>
              <el-descriptions-item label="网点名称">{{ detailData.hsicrmServicestationname || '-' }}</el-descriptions-item>
            </el-descriptions>
          </el-tab-pane>

          <!-- 区域信息 -->
          <el-tab-pane label="区域信息">
            <el-descriptions :column="3" border size="small">
              <el-descriptions-item label="大区">{{ detailData.hsicrmTopregionname || '-' }}</el-descriptions-item>
              <el-descriptions-item label="省份">{{ detailData.hsicrmRegionname || '-' }}</el-descriptions-item>
              <el-descriptions-item label="城市">{{ detailData.hsicrmDistrictname || '-' }}</el-descriptions-item>
              <el-descriptions-item label="街道">{{ detailData.hsicrmTownname || '-' }}</el-descriptions-item>
              <el-descriptions-item label="商圈">{{ detailData.hsicrmPoiregion || '-' }}</el-descriptions-item>
              <el-descriptions-item label="行业">{{ detailData.hsicrmIndustryname || '-' }}</el-descriptions-item>
            </el-descriptions>
          </el-tab-pane>

          <!-- 扩展字段 -->
          <el-tab-pane label="扩展字段">
            <el-descriptions :column="3" border size="small">
              <el-descriptions-item label="是否结单回单">{{ detailData.hsicrmIfepass || '-' }}</el-descriptions-item>
              <el-descriptions-item label="是否绑定">{{ detailData.hsicrmIsbound === 'Y' ? '是' : '否' }}</el-descriptions-item>
              <el-descriptions-item label="是否有回单">{{ detailData.hsicrmOnestopcheck || '-' }}</el-descriptions-item>
              <el-descriptions-item label="退回网络">{{ detailData.hsicrmReturnnetname || '-' }}</el-descriptions-item>
              <el-descriptions-item label="未执行P2P">{{ detailData.hsicrmUnexecutedp2pcase || '-' }}</el-descriptions-item>
              <el-descriptions-item label="投诉编号">{{ detailData.hsicrmComplaintsnumber || '-' }}</el-descriptions-item>
              <el-descriptions-item label="归属呼叫中心">{{ detailData.hsicrmBelongtocallcenter || '-' }}</el-descriptions-item>
              <el-descriptions-item label="业务组织">{{ detailData.hsicrmBizorgcode || '-' }}</el-descriptions-item>
            </el-descriptions>
          </el-tab-pane>

          <!-- 原始字段 -->
          <el-tab-pane label="原始JSON">
            <el-input type="textarea" :model-value="rawJson" rows="20" readonly style="font-family: monospace; font-size: 12px;" />
          </el-tab-pane>
        </el-tabs>
      </div>
      <template #footer>
        <el-button @click="detailDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus, Setting } from '@element-plus/icons-vue'
import request from '@/utils/request'
import { SearchForm, DataTable } from '@/components/page-components'
import ColumnSettings from '@/views/components/ColumnSettings.vue'
import { printTemplates } from '@/components/print/registry'

// ============ 搜索 ============
const queryParams = reactive({
  woNo: '',
  customerName: '',
  phone: '',
  engineerName: '',
  status: null,
  serviceType: null,
  dateRange: null
})

const searchFields = [
  { key: 'woNo', label: '工单编号', type: 'input', placeholder: '海尔工单号' },
  { key: 'customerName', label: '客户名称', type: 'input', placeholder: '客户姓名' },
  { key: 'phone', label: '电话号码', type: 'input', placeholder: '电话' },
  { key: 'engineerName', label: '工程师', type: 'input', placeholder: '师傅姓名' },
  {
    key: 'status',
    label: '状态',
    type: 'select',
    placeholder: '全部',
    options: [
      { label: '已到商', value: '100000010' },
      { label: '已到兵', value: '100000015' },
      { label: '服务商已结单', value: '100000055' },
      { label: '海尔已结单', value: '100000060' },
      { label: '已取消', value: '100000090' }
    ]
  },
  {
    key: 'serviceType',
    label: '服务类型',
    type: 'select',
    placeholder: '全部',
    options: [
      { label: '安装', value: '安装' },
      { label: '维修', value: '维修' },
      { label: '清洗', value: '清洗' },
      { label: '移机', value: '移机' }
    ]
  },
  { key: 'dateRange', label: '日期范围', type: 'date-range', showTime: false }
]

function handleSearch(params) {
  Object.assign(queryParams, params)
  pagination.page = 1
  loadData()
}

function handleReset(params) {
  Object.assign(queryParams, params)
  pagination.page = 1
  loadData()
}

// ============ 表格数据 ============
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })
const tableHeight = computed(() => 'calc(100vh - 300px)')
const exportDialogVisible = ref(false)
const exporting = ref(false)
const selectedRows = ref([])
const printToolbarRef = ref()

const STATUS_OPTIONS = {
  '100000010': '已到商',
  '100000015': '已到兵',
  '100000055': '服务商已结单',
  '100000060': '海尔已结单',
  '100000090': '已取消'
}
const getStatusLabel = (val) => STATUS_OPTIONS[val] || val || '全部'

const openExport = () => {
  exportDialogVisible.value = true
}

const confirmExport = async () => {
  exporting.value = true
  try {
    const filterParams = {}
    if (queryParams.woNo) filterParams.woNo = queryParams.woNo
    if (queryParams.customerName) filterParams.customerName = queryParams.customerName
    if (queryParams.phone) filterParams.phone = queryParams.phone
    if (queryParams.engineerName) filterParams.engineerName = queryParams.engineerName
    if (queryParams.status) filterParams.status = queryParams.status
    if (queryParams.serviceType) filterParams.serviceType = queryParams.serviceType
    if (queryParams.dateRange && queryParams.dateRange.length === 2) {
      filterParams.startDate = queryParams.dateRange[0]
      filterParams.endDate = queryParams.dateRange[1]
    }
    await request.post('/system/export-tasks', {
      taskType: 'WORK_ORDER',
      filterParams
    })
    ElMessage.success('导出任务已提交，请到「导出任务」页面查看进度')
    exportDialogVisible.value = false
  } catch (e) {
    console.error('提交导出失败', e)
    ElMessage.error('提交失败: ' + (e.message || '未知错误'))
  } finally {
    exporting.value = false
  }
}

// ============ 列定义 ============
const HAIER_STATUS_MAP = {
  '100000010': { label: '已到商', type: 'info' },
  '100000015': { label: '已到兵', type: 'primary' },
  '100000055': { label: '服务商已结单', type: 'success' },
  '100000060': { label: '海尔已结单', type: 'success' },
  '100000065': { label: '已作废', type: 'danger' },
  '100000090': { label: '已取消', type: 'info' }
}

const TABLE_COLUMNS = [
  { key: '__seq__', label: '', width: 60, show: true, fixed: 'left', columnType: 'seq' },
  { key: 'hsicrmWorkorderid', label: '工单编号', width: 150, show: true, fixed: true },
  { key: 'hsicrmWorkorderstatusname', label: '状态', width: 110, show: true, fixed: true, columnType: 'status', statusMap: HAIER_STATUS_MAP },
  { key: 'hsicrmConsumername', label: '客户姓名', width: 100, show: true },
  { key: 'hsicrmOtherphone', label: '电话', width: 130, show: true },
  { key: 'hsicrmRealphone', label: '真实电话', width: 120, show: true },
  { key: 'hsicrmConsumeraddr', label: '地址', width: 200, show: true },
  { key: 'hsicrmDistrictname', label: '区县', width: 90, show: false },
  { key: 'hsicrmTownname', label: '乡镇', width: 90, show: false },
  { key: 'hsicrmRegionname', label: '省份', width: 80, show: false },
  { key: 'hsicrmTopregionname', label: '大区', width: 80, show: false },
  { key: 'hsicrmRequireservicetypename', label: '服务类型', width: 80, show: true },
  { key: 'hsicrmActualservicetypename', label: '实际服务类型', width: 100, show: true },
  { key: 'hsicrmBrandname', label: '品牌', width: 80, show: true },
  { key: 'hsicrmProductmodel', label: '产品型号', width: 130, show: false },
  { key: 'hsicrmProductmodelname', label: '产品型号名', width: 130, show: false },
  { key: 'hsicrmSerialnumber', label: '序列号', width: 140, show: false },
  { key: 'hsicrmEmployeename', label: '工程师', width: 90, show: true },
  { key: 'hsicrmEmployeenumber', label: '工程师工号', width: 100, show: false },
  { key: 'hsicrmServicestationname', label: '服务站', width: 150, show: false },
  { key: 'hsicrmServicestationcode', label: '服务站编码', width: 120, show: false },
  { key: 'hsicrmReceivedfee', label: '收费(元)', width: 90, show: true, columnType: 'currency' },
  { key: 'hsicrmPaytypename', label: '支付方式', width: 90, show: true },
  { key: 'hsicrmPaystatus', label: '支付状态', width: 80, show: false },
  { key: 'hsicrmRegistrationtime', label: '创建时间', width: 160, show: true, columnType: 'datetime' },
  { key: 'hsicrmDispatchtime', label: '派工时间', width: 160, show: true, columnType: 'datetime' },
  { key: 'hsicrmServicestationcompletetime', label: '完工时间', width: 160, show: false, columnType: 'datetime' },
  { key: 'hsicrmHaiercompletetime', label: '海尔完工时间', width: 160, show: true, columnType: 'datetime' },
  { key: 'hsicrmSignintime', label: '签到时间', width: 160, show: true, columnType: 'datetime' },
  { key: 'hsicrmSourcename', label: '来源', width: 80, show: true },
  { key: 'hsicrmSourcecode', label: '来源编码', width: 90, show: false },
  { key: 'hsicrmIsfromnetwork', label: '网单', width: 60, show: false },
  { key: 'hsicrmDispatchmode', label: '派工方式', width: 80, show: false },
  { key: 'hsicrmRequireservicemodename', label: '预约服务模式', width: 110, show: false },
  { key: 'hsicrmRequireservicetime', label: '预约服务时间', width: 160, show: false },
  { key: 'hsicrmConsumersex', label: '性别', width: 60, show: false },
  { key: 'hsicrmConsumerno', label: '客户编号', width: 120, show: false },
  { key: 'hsicrmIndustryname', label: '行业', width: 80, show: false },
  { key: 'hsicrmWarrantytype', label: '保修类型', width: 90, show: false },
  { key: 'hsicrmTimeduration', label: '工时(分钟)', width: 90, show: false },
  { key: 'hsicrmSalesdate', label: '销售日期', width: 100, show: false },
  { key: 'hsicrmInvoiceno', label: '发票号', width: 140, show: false },
  { key: 'hsicrmComplaintsnumber', label: '投诉编号', width: 80, show: false },
  { key: 'hsicrmWorkorderstatuscode', label: '状态编码', width: 90, show: false }
]

// 列配置（用户自定义）
const colConfig = ref({})
const PAGE_PATH = '/fsm/work-orders'

// 可见列：基于 TABLE_COLUMNS + colConfig 动态配置
const visibleColumns = computed(() => {
  const cfg = colConfig.value
  const widthKey = `cs_width_${PAGE_PATH}`
  const savedWidth = JSON.parse(localStorage.getItem(widthKey) || '{}')
  return TABLE_COLUMNS
    .map(col => {
      const c = cfg[col.key] || {}
      return {
        ...col,
        show: c.show !== undefined ? c.show : col.show,
        width: savedWidth[col.key] || c.width || col.width,
        fixed: c.fixed !== undefined ? c.fixed : col.fixed
      }
    })
    .filter(col => col.show)
})

// 表格列配置（带操作列）
const tableColumns = computed(() => [
  ...visibleColumns.value,
  {
    key: 'actions',
    label: '操作',
    width: 80,
    fixed: 'right',
    columnType: 'actions',
    actions: [
      { key: 'detail', label: '详情', type: 'primary', size: 'small', link: true }
    ]
  }
])

// ColumnSettings 需要的完整列数据（含隐藏列）
const mergedColumns = computed(() => {
  const cfg = colConfig.value
  const widthKey = `cs_width_${PAGE_PATH}`
  const savedWidth = JSON.parse(localStorage.getItem(widthKey) || '{}')
  return TABLE_COLUMNS.map(col => {
    const c = cfg[col.key] || {}
    return {
      ...col,
      show: c.show !== undefined ? c.show : col.show,
      width: savedWidth[col.key] || c.width || col.width,
      fixed: c.fixed !== undefined ? c.fixed : col.fixed
    }
  })
})

// 加载列配置
const loadColConfig = async () => {
  try {
    const res = await fetch(`/api/v1/system/column-configs?pagePath=${encodeURIComponent(PAGE_PATH)}`)
    const json = await res.json()
    if (json.code === 0 && json.data && json.data.length > 0) {
      const map = {}
      json.data.forEach(s => {
        map[s.columnKey] = {
          show: s.visible === 1,
          fixed: s.fixed === 1,
          width: s.width || undefined
        }
      })
      colConfig.value = map
    }
  } catch (e) { /* ignore */ }
}

// 打印回调
const onPrinted = (result) => {
  ElMessage.success(`已记录打印日志：${result.templateType}`)
}

// 打印数据获取（供 PrintToolbar 调用）
const printData = () => {
  return tableData.value.map(row => ({
    ...row,
    _printLabel: row.hsicrmWorkorderid || row.woNo || '',
    _printDate: formatCompleteTime(row.hsicrmServicestationcompletetime),
    _printEngineer: row.hsicrmEmployeename || '',
    _printCustomer: row.customerName || row.hsicrmCustomername || '',
    _printPhone: row.hsicrmRealphone || row.hsicrmContactphone || '',
    _printAddress: row.hsicrmServiceaddress || '',
    _printServiceType: row.hsicrmServicetypename || '',
    _printStatus: row.hsicrmWorkorderstatusname || '',
    _printFee: row.hsicrmReceivedfee ?? 0,
    _printRemark: row.hsicrmServicestationremark || '',
  }))
}

// 列设置保存后
const onColumnConfigChange = (columns) => {
  const map = {}
  columns.forEach((col, idx) => {
    map[col.key] = {
      show: col.show,
      fixed: col.fixed || false,
      width: col.width || col._width || undefined,
      sortOrder: idx
    }
  })
  colConfig.value = map
}

// ============ 时间格式化 ============
const formatTime = (val) => {
  if (!val) return '-'
  if (String(val).length === 13) {
    return new Date(Number(val)).toLocaleString('zh-CN', { hour12: false })
  }
  if (String(val).length === 19) return val.replace('T', ' ')
  return val
}

const formatCompleteTime = (val) => {
  if (!val || val === '0') return '-'
  return formatTime(val)
}

// ============ 状态映射 ============
const getHaierStatusType = (code) => HAIER_STATUS_MAP[code]?.type || 'info'

// ============ 详情 ============
const detailDialogVisible = ref(false)
const detailLoading = ref(false)
const detailData = ref({})
const rawJson = computed(() => JSON.stringify(detailData.value, null, 2))

const openDetail = async (row) => {
  detailData.value = { ...row }
  detailDialogVisible.value = true
}

const decryptPhone = async (row) => {
  if (!row.hsicrmWorkorderid) return
  row._decrypting = true
  detailData.value = { ...detailData.value, _decrypting: true }
  try {
    const res = await request.post('/fsm/haier/decrypt-phone', {
      workOrderId: row.hsicrmWorkorderid,
      storageLocation: row.hsicrmStoragelocation || 'WO1'
    })
    if (res.data?.phone) {
      detailData.value.hsicrmRealphone = res.data.phone
      row.hsicrmRealphone = res.data.phone
      ElMessage.success('解密成功')
    } else {
      ElMessage.warning('未返回电话')
    }
  } catch (e) {
    console.error('decrypt error', e)
    ElMessage.error('解密失败')
  } finally {
    row._decrypting = false
  }
}

// ============ 操作处理 ============
const dataTableRef = ref()

function handleTableAction(action, row) {
  if (action === 'detail') openDetail(row)
}

function handlePageChange(page) {
  pagination.page = page
  loadData()
}

function handleSizeChange(size) {
  pagination.pageSize = size
  pagination.page = 1
  loadData()
}

const openAdd = () => {
  ElMessage.info('新建工单功能开发中')
}

// ============ 打印 ============
const handlePrint = async () => {
  if (!selectedRows.value.length) {
    ElMessage.warning('请先选择要打印的工单')
    return
  }
  const row = selectedRows.value[0]
  // 调工单详情接口获取完整数据
  try {
    const res = await request.get(`/fsm/work-orders/${row.id}`)
    const data = res.data || res
    // 打开打印窗口
    const printWindow = window.open('/print.html?id=' + row.id, '_blank', 'width=900,height=700')
    if (!printWindow) {
      ElMessage.error('请允许弹出窗口')
      return
    }
    // 等页面加载完成后写入内容
    printWindow.onload = () => {
      printWindow.document.write(buildPrintHtml(data))
      printWindow.document.close()
    }
  } catch (e) {
    ElMessage.error('获取工单详情失败')
  }
}

// 构建打印HTML内容
function buildPrintHtml(data) {
  const wo = data.workOrder || data
  const parts = data.parts || []
  const items = data.items || []
  return `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>工单打印</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: '思源黑体', 'Microsoft YaHei', sans-serif; font-size: 14px; color: #333; padding: 20px; }
  .header { text-align: center; border-bottom: 2px solid #333; padding-bottom: 12px; margin-bottom: 16px; }
  .header h1 { font-size: 22px; margin-bottom: 4px; }
  .header p { font-size: 12px; color: #666; }
  .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; margin-bottom: 16px; }
  .info-item { display: flex; font-size: 13px; }
  .info-label { color: #666; width: 80px; flex-shrink: 0; }
  .info-value { font-weight: 500; }
  table { width: 100%; border-collapse: collapse; margin-bottom: 12px; font-size: 13px; }
  th, td { border: 1px solid #ddd; padding: 6px 8px; text-align: left; }
  th { background: #f5f5f5; font-weight: 600; }
  .sign-area { display: flex; justify-content: space-between; margin-top: 24px; }
  .sign-box { width: 45%; }
  .sign-box p { margin-top: 40px; font-size: 12px; color: #666; border-top: 1px solid #333; padding-top: 6px; }
  @media print { body { padding: 0; } }
</style>
</head>
<body>
<div class="header">
  <h1>家电服务工单</h1>
  <p>全国服务热线：400-699-9999</p>
</div>
<div class="info-grid">
  <div class="info-item"><span class="info-label">工单编号</span><span class="info-value">${wo.woNo || wo.hsicrmWorkorderno || ''}</span></div>
  <div class="info-item"><span class="info-label">客户姓名</span><span class="info-value">${wo.customerName || wo.hsicrmCustomername || ''}</span></div>
  <div class="info-item"><span class="info-label">联系电话</span><span class="info-value">${wo.customerPhone || wo.hsicrmPhone || ''}</span></div>
  <div class="info-item"><span class="info-label">服务地址</span><span class="info-value">${wo.address || wo.hsicrmServiceaddress || ''}</span></div>
  <div class="info-item"><span class="info-label">服务类型</span><span class="info-value">${wo.serviceTypeName || wo.hsicrmServicetypename || ''}</span></div>
  <div class="info-item"><span class="info-label">预约时间</span><span class="info-value">${wo.requireTime || wo.hsicrmRequireservicetime || ''}</span></div>
  <div class="info-item"><span class="info-label">工程师</span><span class="info-value">${wo.employeeName || wo.hsicrmEmployeename || ''}</span></div>
  <div class="info-item"><span class="info-label">工单状态</span><span class="info-value">${wo.statusName || wo.hsicrmWorkorderstatusname || ''}</span></div>
</div>
${parts.length ? `
<table>
  <tr><th>序号</th><th>配件编码</th><th>配件名称</th><th>规格</th><th>数量</th><th>单位</th><th>费用</th></tr>
  ${parts.map((p, i) => `<tr><td>${i+1}</td><td>${p.partCode || ''}</td><td>${p.partName || ''}</td><td>${p.spec || ''}</td><td>${p.quantity || ''}</td><td>${p.unit || ''}</td><td>${p.fee || '0.00'}</td></tr>`).join('')}
</table>` : ''}
<div class="sign-area">
  <div class="sign-box"><p>客户签字：</p></div>
  <div class="sign-box"><p>工程师签字：</p></div>
</div>
</body>
</html>`
}

// ============ 加载数据 ============
async function loadData() {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      pageSize: pagination.pageSize,
      woNo: queryParams.woNo || undefined,
      customerName: queryParams.customerName || undefined,
      status: queryParams.status || undefined,
      keyword: queryParams.phone || undefined,
      engineerName: queryParams.engineerName || undefined,
      serviceType: queryParams.serviceType || undefined,
      startDate: queryParams.dateRange?.[0] || undefined,
      endDate: queryParams.dateRange?.[1] || undefined
    }
    Object.keys(params).forEach(k => params[k] === undefined && delete params[k])
    const res = await request.get('/fsm/work-orders', { params })
    tableData.value = res.data?.list || res.data?.records || []
    pagination.total = res.data?.total || 0
  } catch (e) {
    console.error('loadData error', e)
    tableData.value = []
  } finally {
    loading.value = false
  }
}

// ============ 初始化 ============
onMounted(() => {
  loadColConfig()
  loadData()
})
</script>

<style scoped>
.work-order-list {
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.panel {
  background: #fff;
  border-radius: 4px;
  padding: 12px 16px;
}

.table-panel {
  position: relative;
  padding-top: 48px;
}

.table-toolbar {
  position: absolute;
  top: 10px;
  right: 16px;
  display: flex;
  gap: 8px;
  z-index: 1;
}

.table-header-bar {
  display: flex;
  align-items: center;
  gap: 6px;
}

.seq-settings-btn {
  cursor: pointer;
  color: #909399;
  font-size: 14px;
  transition: color 0.2s;
}

.seq-settings-btn:hover {
  color: #409eff;
}
</style>
