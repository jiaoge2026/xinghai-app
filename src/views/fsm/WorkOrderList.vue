<template>
  <div class="work-order-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>工单管理</span>
          <div class="header-actions">
            <el-button type="primary" size="small" @click="openAdd">新建工单</el-button>
          </div>
        </div>
      </template>
      <!-- 搜索筛选区 -->
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="工单编号">
          <el-input v-model="searchForm.woNo" placeholder="海尔工单号" clearable style="width: 160px" />
        </el-form-item>
        <el-form-item label="客户名称">
          <el-input v-model="searchForm.customerName" placeholder="客户姓名" clearable style="width: 140px" />
        </el-form-item>
        <el-form-item label="电话号码">
          <el-input v-model="searchForm.phone" placeholder="电话" clearable style="width: 130px" />
        </el-form-item>
        <el-form-item label="工程师">
          <el-input v-model="searchForm.engineerName" placeholder="师傅姓名" clearable style="width: 120px" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="searchForm.status" placeholder="全部" clearable style="width: 140px">
            <el-option label="已到商" value="100000010" />
            <el-option label="已到兵" value="100000015" />
            <el-option label="服务商已结单" value="100000055" />
            <el-option label="海尔已结单" value="100000060" />
            <el-option label="已取消" value="100000090" />
          </el-select>
        </el-form-item>
        <el-form-item label="服务类型">
          <el-select v-model="searchForm.serviceType" placeholder="全部" clearable style="width: 120px">
            <el-option label="安装" value="安装" />
            <el-option label="维修" value="维修" />
            <el-option label="清洗" value="清洗" />
            <el-option label="移机" value="移机" />
          </el-select>
        </el-form-item>
        <el-form-item label="日期范围">
          <el-date-picker
            v-model="searchForm.dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始"
            end-placeholder="结束"
            value-format="YYYY-MM-DD"
            style="width: 240px"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 表格区 -->
      <div class="table-wrapper">
        <el-table v-loading="loading" :data="tableData" stripe height="calc(100vh - 300px)">
          <!-- 序号（列设置也在这里） -->
          <el-table-column label="序号" width="80" fixed>
            <template #header>
              <span class="seq-col-header">
                序号
                <ColumnSettings
                  :columns="localColumns"
                  page-path="/fsm/work-orders"
                  @update:columns="localColumns = $event"
                  @change="localColumns = $event"
                >
                  <template #trigger>
                    <el-icon class="seq-settings-btn"><Setting /></el-icon>
                  </template>
                </ColumnSettings>
              </span>
            </template>
            <template #default="{ row, $index }">
              {{ (pagination.page - 1) * pagination.pageSize + $index + 1 }}
            </template>
          </el-table-column>
          <!-- 工单编号 -->
          <el-table-column v-if="isColVisible('hsicrmWorkorderid')" prop="hsicrmWorkorderid" label="工单编号" width="150" fixed />
          <!-- 状态 -->
          <el-table-column v-if="isColVisible('hsicrmWorkorderstatusname')" prop="hsicrmWorkorderstatusname" label="状态" width="110" fixed>
            <template #default="{ row }">
              <el-tag :type="getHaierStatusType(row.hsicrmWorkorderstatuscode)" size="small">
                {{ row.hsicrmWorkorderstatusname || '-' }}
              </el-tag>
            </template>
          </el-table-column>
          <!-- 客户姓名 -->
          <el-table-column v-if="isColVisible('hsicrmConsumername')" prop="hsicrmConsumername" label="客户姓名" width="100" show-overflow-tooltip />
          <!-- 联系电话 -->
          <el-table-column v-if="isColVisible('hsicrmOtherphone')" prop="hsicrmOtherphone" label="电话" width="130">
            <template #default="{row}">{{ row.hsicrmOtherphone ? row.hsicrmOtherphone.split(',')[0] : '-' }}</template>
          </el-table-column>
          <!-- 真实电话 -->
          <el-table-column v-if="isColVisible('hsicrmRealphone')" prop="hsicrmRealphone" label="真实电话" width="120" />
          <!-- 客户地址 -->
          <el-table-column v-if="isColVisible('hsicrmConsumeraddr')" prop="hsicrmConsumeraddr" label="地址" min-width="200" show-overflow-tooltip />
          <!-- 区县 -->
          <el-table-column v-if="isColVisible('hsicrmDistrictname')" prop="hsicrmDistrictname" label="区县" width="90" show-overflow-tooltip />
          <!-- 服务类型 -->
          <el-table-column v-if="isColVisible('hsicrmRequireservicetypename')" prop="hsicrmRequireservicetypename" label="服务类型" width="80" />
          <!-- 品牌 -->
          <el-table-column v-if="isColVisible('hsicrmBrandname')" prop="hsicrmBrandname" label="品牌" width="80" show-overflow-tooltip />
          <!-- 产品型号 -->
          <el-table-column v-if="isColVisible('hsicrmProductmodel')" prop="hsicrmProductmodel" label="产品型号" width="130" show-overflow-tooltip />
          <!-- 工程师 -->
          <el-table-column v-if="isColVisible('hsicrmEmployeename')" prop="hsicrmEmployeename" label="工程师" width="90" />
          <!-- 服务站 -->
          <el-table-column v-if="isColVisible('hsicrmServicestationname')" prop="hsicrmServicestationname" label="服务站" min-width="150" show-overflow-tooltip />
          <!-- 收费金额 -->
          <el-table-column v-if="isColVisible('hsicrmReceivedfee')" prop="hsicrmReceivedfee" label="收费(元)" width="90" align="right">
            <template #default="{ row }">
              {{ row.hsicrmReceivedfee != null ? Number(row.hsicrmReceivedfee).toFixed(2) : '-' }}
            </template>
          </el-table-column>
          <!-- 支付方式 -->
          <el-table-column v-if="isColVisible('hsicrmPaytypename')" prop="hsicrmPaytypename" label="支付方式" width="90" />
          <!-- 创建时间 -->
          <el-table-column v-if="isColVisible('hsicrmRegistrationtime')" prop="hsicrmRegistrationtime" label="创建时间" width="160">
            <template #default="{ row }">
              {{ formatTime(row.hsicrmRegistrationtime) }}
            </template>
          </el-table-column>
          <!-- 派工时间 -->
          <el-table-column v-if="isColVisible('hsicrmDispatchtime')" prop="hsicrmDispatchtime" label="派工时间" width="160">
            <template #default="{ row }">
              {{ formatTime(row.hsicrmDispatchtime) }}
            </template>
          </el-table-column>
          <!-- 完工时间 -->
          <el-table-column v-if="isColVisible('hsicrmServicestationcompletetime')" prop="hsicrmServicestationcompletetime" label="完工时间" width="160">
            <template #default="{ row }">
              {{ formatCompleteTime(row.hsicrmServicestationcompletetime) }}
            </template>
          </el-table-column>
          <!-- 来源 -->
          <el-table-column v-if="isColVisible('hsicrmSourcename')" prop="hsicrmSourcename" label="来源" width="80" />
          <!-- 网单 -->
          <el-table-column v-if="isColVisible('hsicrmIsfromnetwork')" prop="hsicrmIsfromnetwork" label="网单" width="60">
            <template #default="{ row }">
              {{ row.hsicrmIsfromnetwork === 'Y' ? '是' : '-' }}
            </template>
          </el-table-column>
          <!-- 派工方式 -->
          <el-table-column v-if="isColVisible('hsicrmDispatchmode')" prop="hsicrmDispatchmode" label="派工方式" width="80" />
          <!-- 预约服务模式 -->
          <el-table-column v-if="isColVisible('hsicrmRequireservicemodename')" prop="hsicrmRequireservicemodename" label="预约服务模式" width="110" show-overflow-tooltip />
          <!-- 性别 -->
          <el-table-column v-if="isColVisible('hsicrmConsumersex')" prop="hsicrmConsumersex" label="性别" width="60">
            <template #default="{ row }">
              {{ row.hsicrmConsumersex === '1' ? '男' : row.hsicrmConsumersex === '2' ? '女' : '-' }}
            </template>
          </el-table-column>
          <!-- 行业 -->
          <el-table-column v-if="isColVisible('hsicrmIndustryname')" prop="hsicrmIndustryname" label="行业" width="80" show-overflow-tooltip />
          <!-- 序列号 -->
          <el-table-column v-if="isColVisible('hsicrmSerialnumber')" prop="hsicrmSerialnumber" label="序列号" width="140" show-overflow-tooltip />
          <!-- 保修类型 -->
          <el-table-column v-if="isColVisible('hsicrmWarrantytype')" prop="hsicrmWarrantytype" label="保修类型" width="90" />
          <!-- 工时 -->
          <el-table-column v-if="isColVisible('hsicrmTimeduration')" prop="hsicrmTimeduration" label="工时(分钟)" width="90" align="right" />
          <!-- 大区 -->
          <el-table-column v-if="isColVisible('hsicrmTopregionname')" prop="hsicrmTopregionname" label="大区" width="80" show-overflow-tooltip />
          <!-- 省份 -->
          <el-table-column v-if="isColVisible('hsicrmRegionname')" prop="hsicrmRegionname" label="省份" width="80" show-overflow-tooltip />
          <!-- 投诉编号 -->
          <el-table-column v-if="isColVisible('hsicrmComplaintsnumber')" prop="hsicrmComplaintsnumber" label="投诉" width="70" />
          <!-- 工单ID -->
          <el-table-column v-if="isColVisible('hsicrmWorkorderid')" prop="hsicrmWorkorderid" label="工单ID" width="180" show-overflow-tooltip />
          <!-- 操作列 -->
          <el-table-column label="操作" width="100" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" size="small" @click="openDetail(row)">详情</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- 分页 -->
      <el-pagination
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.pageSize"
        :total="pagination.total"
        :page-sizes="[20, 50, 100, 200]"
        layout="total, sizes, prev, pager, next, jumper"
        style="margin-top: 12px; justify-content: flex-end;"
        @size-change="fetchData"
        @current-change="fetchData"
      />

      <!-- 详情弹窗 -->
      <el-dialog v-model="detailDialogVisible" title="工单详情" width="900px" :close-on-click-modal="false">
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
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import request from '@/utils/request'
import { ElMessage } from 'element-plus'
import ColumnSettings from '@/views/components/ColumnSettings.vue'
import { Setting } from '@element-plus/icons-vue'

// ---------- 列定义 ----------
const TABLE_COLUMNS = [
  { prop: 'hsicrmWorkorderid', label: '工单编号', visible: true, fixed: true },
  { prop: 'hsicrmWorkorderstatusname', label: '状态', visible: true, fixed: true },
  { prop: 'hsicrmConsumername', label: '客户姓名', visible: true, fixed: false },
  { prop: 'hsicrmOtherphone', label: '电话', visible: true, fixed: false },
  { prop: 'hsicrmRealphone', label: '真实电话', visible: false, fixed: false },
  { prop: 'hsicrmConsumeraddr', label: '地址', visible: true, fixed: false },
  { prop: 'hsicrmDistrictname', label: '区县', visible: false, fixed: false },
  { prop: 'hsicrmRequireservicetypename', label: '服务类型', visible: true, fixed: false },
  { prop: 'hsicrmBrandname', label: '品牌', visible: false, fixed: false },
  { prop: 'hsicrmProductmodel', label: '产品型号', visible: false, fixed: false },
  { prop: 'hsicrmEmployeename', label: '工程师', visible: true, fixed: false },
  { prop: 'hsicrmServicestationname', label: '服务站', visible: false, fixed: false },
  { prop: 'hsicrmReceivedfee', label: '收费(元)', visible: true, fixed: false },
  { prop: 'hsicrmPaytypename', label: '支付方式', visible: false, fixed: false },
  { prop: 'hsicrmRegistrationtime', label: '创建时间', visible: true, fixed: false },
  { prop: 'hsicrmDispatchtime', label: '派工时间', visible: false, fixed: false },
  { prop: 'hsicrmServicestationcompletetime', label: '完工时间', visible: false, fixed: false },
  { prop: 'hsicrmSourcename', label: '来源', visible: false, fixed: false },
  { prop: 'hsicrmIsfromnetwork', label: '网单', visible: false, fixed: false },
  { prop: 'hsicrmDispatchmode', label: '派工方式', visible: false, fixed: false },
  { prop: 'hsicrmRequireservicemodename', label: '预约服务模式', visible: false, fixed: false },
  { prop: 'hsicrmConsumersex', label: '性别', visible: false, fixed: false },
  { prop: 'hsicrmIndustryname', label: '行业', visible: false, fixed: false },
  { prop: 'hsicrmSerialnumber', label: '序列号', visible: false, fixed: false },
  { prop: 'hsicrmWarrantytype', label: '保修类型', visible: false, fixed: false },
  { prop: 'hsicrmTimeduration', label: '工时(分钟)', visible: false, fixed: false },
  { prop: 'hsicrmTopregionname', label: '大区', visible: false, fixed: false },
  { prop: 'hsicrmRegionname', label: '省份', visible: false, fixed: false },
  { prop: 'hsicrmComplaintsnumber', label: '投诉编号', visible: false, fixed: false },
]

const localColumns = ref([...TABLE_COLUMNS])
const isColVisible = (prop) => {
  const col = localColumns.value.find(c => c.prop === prop)
  return col ? col.visible : false
}

// ---------- 海尔状态映射 ----------
const HAIER_STATUS_MAP = {
  '100000010': { text: '已到商', type: 'info' },
  '100000015': { text: '已到兵', type: 'primary' },
  '100000055': { text: '服务商已结单', type: 'success' },
  '100000060': { text: '海尔已结单', type: 'success' },
  '100000065': { text: '已作废', type: 'danger' },
  '100000090': { text: '已取消', type: 'info' },
}
const getHaierStatusType = (code) => HAIER_STATUS_MAP[code]?.type || 'info'

// ---------- 时间格式化 ----------
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

// ---------- 表格数据 ----------
const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 50, total: 0 })

const searchForm = reactive({
  woNo: '',
  customerName: '',
  phone: '',
  engineerName: '',
  status: '',
  serviceType: '',
  dateRange: null
})

const handleSearch = () => {
  pagination.page = 1
  fetchData()
}
const handleReset = () => {
  searchForm.woNo = ''
  searchForm.customerName = ''
  searchForm.phone = ''
  searchForm.engineerName = ''
  searchForm.status = ''
  searchForm.serviceType = ''
  searchForm.dateRange = null
  handleSearch()
}

// ---------- 获取工单列表 ----------
const fetchData = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      pageSize: pagination.pageSize,
      woNo: searchForm.woNo || undefined,
      customerName: searchForm.customerName || undefined,
      status: searchForm.status || undefined,
      keyword: searchForm.phone || undefined,
      engineerName: searchForm.engineerName || undefined,
      serviceType: searchForm.serviceType || undefined,
      startDate: searchForm.dateRange?.[0] || undefined,
      endDate: searchForm.dateRange?.[1] || undefined
    }
    Object.keys(params).forEach(k => params[k] === undefined && delete params[k])
    const res = await request.get('/fsm/work-orders', { params })
    tableData.value = res.data?.list || res.data?.records || []
    pagination.total = res.data?.total || 0
  } catch (e) {
    console.error('fetchData error', e)
  } finally {
    loading.value = false
  }
}

// ---------- 详情 ----------
const detailDialogVisible = ref(false)
const detailLoading = ref(false)
const detailData = ref({})
const rawJson = computed(() => JSON.stringify(detailData.value, null, 2))

const openDetail = async (row) => {
  detailData.value = { ...row }
  detailDialogVisible.value = true
}

const openAdd = () => {
  ElMessage.info('新建工单功能开发中')
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

// ---------- 初始化 ----------
onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.work-order-list {
  padding: 12px;
}
.search-form {
  margin-bottom: 12px;
}
.table-wrapper {
  overflow-x: auto;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.header-actions {
  display: flex;
  gap: 8px;
  align-items: center;
}
.seq-col-header {
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
