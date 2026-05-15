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
          <!-- 序号列（含列设置按钮） -->
          <el-table-column label="序号" width="80" fixed>
            <template #header>
              <div class="table-header-bar">
                <span>序号</span>
                <ColumnSettings
                  :columns="mergedColumns"
                  page-path="/fsm/work-orders"
                  @change="onColumnConfigChange"
                >
                  <template #trigger>
                    <el-icon class="seq-settings-btn"><Setting /></el-icon>
                  </template>
                </ColumnSettings>
              </div>
            </template>
            <template #default="{ $index }">
              {{ (pagination.page - 1) * pagination.pageSize + $index + 1 }}
            </template>
          </el-table-column>
          <!-- 动态列：v-for 可见列，Vue 只渲染当前需要显示的列 -->
          <el-table-column
            v-for="col in visibleColumns"
            :key="col.prop"
            :prop="col.prop"
            :label="col.label"
            :width="col.width || undefined"
            :fixed="col.prop === 'hsicrmWorkorderid' || col.prop === 'hsicrmWorkorderstatusname' ? 'left' : undefined"
            show-overflow-tooltip
          />
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
// visible: true = 默认显示，false = 默认隐藏，用户可通过列设置调整
const TABLE_COLUMNS = [
  { prop: 'hsicrmWorkorderid', label: '工单编号', visible: true, fixed: true, width: 150},
  { prop: 'hsicrmWorkorderstatusname', label: '状态', visible: true, fixed: true, width: 110},
  { prop: 'hsicrmConsumername', label: '客户姓名', visible: true, width: 100},
  { prop: 'hsicrmOtherphone', label: '电话', visible: true, width: 130},
  { prop: 'hsicrmRealphone', label: '真实电话', visible: true, width: 120},
  { prop: 'hsicrmConsumeraddr', label: '地址', visible: true, width: 200},
  { prop: 'hsicrmDistrictname', label: '区县', visible: false, width: 90},
  { prop: 'hsicrmTownname', label: '乡镇', visible: false, width: 90},
  { prop: 'hsicrmRegionname', label: '省份', visible: false, width: 80},
  { prop: 'hsicrmTopregionname', label: '大区', visible: false, width: 80},
  { prop: 'hsicrmRequireservicetypename', label: '服务类型', visible: true, width: 80},
  { prop: 'hsicrmActualservicetypename', label: '实际服务类型', visible: true, width: 100},
  { prop: 'hsicrmBrandname', label: '品牌', visible: true, width: 80},
  { prop: 'hsicrmProductmodel', label: '产品型号', visible: false, width: 130},
  { prop: 'hsicrmProductmodelname', label: '产品型号名', visible: false, width: 130},
  { prop: 'hsicrmSerialnumber', label: '序列号', visible: false, width: 140},
  { prop: 'hsicrmEmployeename', label: '工程师', visible: true, width: 90},
  { prop: 'hsicrmEmployeenumber', label: '工程师工号', visible: false, width: 100},
  { prop: 'hsicrmServicestationname', label: '服务站', visible: false, width: 150},
  { prop: 'hsicrmServicestationcode', label: '服务站编码', visible: false, width: 120},
  { prop: 'hsicrmReceivedfee', label: '收费(元)', visible: true, width: 90},
  { prop: 'hsicrmPaytypename', label: '支付方式', visible: true, width: 90},
  { prop: 'hsicrmPaystatus', label: '支付状态', visible: false, width: 80},
  { prop: 'hsicrmRegistrationtime', label: '创建时间', visible: true, width: 160},
  { prop: 'hsicrmDispatchtime', label: '派工时间', visible: true, width: 160},
  { prop: 'hsicrmServicestationcompletetime', label: '完工时间', visible: false, width: 160},
  { prop: 'hsicrmHaiercompletetime', label: '海尔完工时间', visible: true, width: 160},
  { prop: 'hsicrmSignintime', label: '签到时间', visible: true, width: 160},
  { prop: 'hsicrmSourcename', label: '来源', visible: true, width: 80},
  { prop: 'hsicrmSourcecode', label: '来源编码', visible: false, width: 90},
  { prop: 'hsicrmIsfromnetwork', label: '网单', visible: false, width: 60},
  { prop: 'hsicrmDispatchmode', label: '派工方式', visible: false, width: 80},
  { prop: 'hsicrmRequireservicemodename', label: '预约服务模式', visible: false, width: 110},
  { prop: 'hsicrmRequireservicetime', label: '预约服务时间', visible: false, width: 160},
  { prop: 'hsicrmConsumersex', label: '性别', visible: false, width: 60},
  { prop: 'hsicrmConsumerno', label: '客户编号', visible: false, width: 120},
  { prop: 'hsicrmIndustryname', label: '行业', visible: false, width: 80},
  { prop: 'hsicrmWarrantytype', label: '保修类型', visible: false, width: 90},
  { prop: 'hsicrmTimeduration', label: '工时(分钟)', visible: false, width: 90},
  { prop: 'hsicrmSalesdate', label: '销售日期', visible: false, width: 100},
  { prop: 'hsicrmInvoiceno', label: '发票号', visible: false, width: 140},
  { prop: 'hsicrmComplaintsnumber', label: '投诉编号', visible: false, width: 80},
  { prop: 'hsicrmWorkorderstatuscode', label: '状态编码', visible: false, width: 90},
  { prop: 'hsicrmPoiregion', label: 'POI区域', visible: false, width: 100},
  { prop: 'hsicrmLatitude', label: '纬度', visible: false, width: 100},
  { prop: 'hsicrmLongitude', label: '经度', visible: false, width: 100},
  { prop: 'hsicrmBequeathreason', label: '转交原因', visible: false, width: 150},
  { prop: 'hsicrmConsumerdesc', label: '客户描述', visible: false, width: 150},
  { prop: 'hsicrmGenerationphone', label: '生成电话', visible: false, width: 120},
  { prop: 'hsicrmContactnumber', label: '联系电话', visible: false, width: 120},
  { prop: 'hsicrmTaxbmobilephone', label: '师傅回电电话', visible: false, width: 120},
  { prop: 'hsicrmMobilenumber', label: '手机号', visible: false, width: 120},
  { prop: 'hsicrmMobilephoneservicestationname', label: '手机服务站名', visible: false, width: 150},
  { prop: 'hsicrmCustomerphone', label: '客户电话', visible: false, width: 120},
  { prop: 'hsicrmBrandcode', label: '品牌编码', visible: false, width: 80},
  { prop: 'hsicrmProductcategoryname', label: '产品类别', visible: false, width: 100},
  { prop: 'hsicrmProductcategorycode', label: '产品类别编码', visible: false, width: 100},
  { prop: 'hsicrmIndustrycode', label: '行业编码', visible: false, width: 80},
  { prop: 'hsicrmRegioncode', label: '省份编码', visible: false, width: 80},
  { prop: 'hsicrmTopregioncode', label: '大区编码', visible: false, width: 80},
  { prop: 'hsicrmPaytypecode', label: '支付类型编码', visible: false, width: 90},
  { prop: 'hsicrmRequireservicetypecode', label: '服务类型编码', visible: false, width: 100},
  { prop: 'hsicrmActualservicetypecode', label: '实际服务类型编码', visible: false, width: 110},
  { prop: 'hsicrmActualservicemodename', label: '实际服务模式', visible: false, width: 110},
  { prop: 'hsicrmActualservicemodecode', label: '实际服务模式编码', visible: false, width: 110},
  { prop: 'hsicrmDispatchresultsdesc', label: '派工结果描述', visible: false, width: 150},
  { prop: 'hsicrmReturnnetid', label: '退回网点ID', visible: false, width: 100},
  { prop: 'hsicrmReturnnetname', label: '退回网点名称', visible: false, width: 100},
  { prop: 'hsicrmActualwarrantytypoename', label: '实际保修类型', visible: false, width: 100},
  { prop: 'hsicrmTrippingtypename', label: '差旅类型', visible: false, width: 80},
  { prop: 'hsicrmTrippingtypecode', label: '差旅类型编码', visible: false, width: 90},
  { prop: 'hsicrmSecondleveltrippingtypename', label: '二级差旅类型', visible: false, width: 100},
  { prop: 'hsicrmSecondleveltrippingtypecode', label: '二级差旅类型编码', visible: false, width: 110},
  { prop: 'hsicrmUrgencydegreename', label: '紧急程度', visible: false, width: 80},
  { prop: 'hsicrmImportancename', label: '重要程度', visible: false, width: 80},
  { prop: 'hsicrmImportancecode', label: '重要程度编码', visible: false, width: 90},
  { prop: 'hsicrmEvaluationresult', label: '评价结果', visible: false, width: 80},
  { prop: 'hsicrmEvaluatechannel', label: '评价渠道', visible: false, width: 80},
  { prop: 'hsicrmEvaluationcompletiontime', label: '评价完成时间', visible: false, width: 160},
  { prop: 'hsicrmShortmessagesendedtime', label: '短信发送时间', visible: false, width: 160},
  { prop: 'hsicrmServicetime', label: '服务时间', visible: false, width: 160},
  { prop: 'hsicrmServiceprocess', label: '服务流程', visible: false, width: 100},
  { prop: 'hsicrmDocumentarytype', label: '跟单类型', visible: false, width: 80},
  { prop: 'hsicrmDeadlinedate', label: '截止日期', visible: false, width: 100},
  { prop: 'hsicrmEntercallcenter', label: '进入呼叫中心', visible: false, width: 80},
  { prop: 'hsicrmBelongtocallcenter', label: '所属呼叫中心', visible: false, width: 120},
  { prop: 'hsicrmLinkedworkorderid', label: '关联工单ID', visible: false, width: 150},
  { prop: 'hsicrmLastcomplainttime', label: '最后投诉时间', visible: false, width: 160},
  { prop: 'hsicrmInformationsource', label: '信息来源', visible: false, width: 100},
  { prop: 'hsicrmReflectproblemclassification', label: '问题分类', visible: false, width: 120},
  { prop: 'hsicrmRawwatertds', label: '原水TDS', visible: false, width: 90},
  { prop: 'hsicrmProductprice', label: '产品价格', visible: false, width: 100},
  { prop: 'hsicrmImeicode', label: 'IMEI码', visible: false, width: 140},
  { prop: 'hsicrmWorkordersuitno', label: '工单套装号', visible: false, width: 120},
  { prop: 'hsicrmWoWorkorderid', label: '工单外部ID', visible: false, width: 150},
  { prop: 'hsicrmStoragelocation', label: '存储位置', visible: false, width: 100},
  { prop: 'hsicrmBizorgcode', label: '业务组织编码', visible: false, width: 100},
  { prop: 'hsicrmSalesmarketcode', label: '销售渠道编码', visible: false, width: 100},
  { prop: 'hsicrmOfficialwebsiteid', label: '官网ID', visible: false, width: 80},
  { prop: 'hsicrmOnestopcheck', label: '一键检测', visible: false, width: 80},
  { prop: 'hsicrmIsbound', label: '是否绑定', visible: false, width: 70},
  { prop: 'hsicrmIsprint', label: '是否打印', visible: false, width: 70},
  { prop: 'hsicrmIfepass', label: '是否放行', visible: false, width: 70},
  { prop: 'hsicrmMembershipcategorycode', label: '会员类别编码', visible: false, width: 110},
  { prop: 'hsicrmDeletedby', label: '删除人', visible: false, width: 80},
  { prop: 'hsicrmBequeathreasonupdatetime', label: '转交原因更新时间', visible: false, width: 160},
  { prop: 'hsicrmAttribute2', label: '扩展字段2', visible: false, width: 80},
  { prop: 'hsicrmAttribute4', label: '扩展字段4', visible: false, width: 80},
  { prop: 'hsicrmAttribute5', label: '扩展字段5', visible: false, width: 80},
  { prop: 'hsicrmAttribute6', label: '扩展字段6', visible: false, width: 80},
  { prop: 'hsicrmAttribute7', label: '扩展字段7', visible: false, width: 80},
  { prop: 'hsicrmAttribute9', label: '扩展字段9', visible: false, width: 80},
  { prop: 'hsicrmContactconsumertime', label: '联系客户时间', visible: false, width: 160},
]

// ---------- 列配置框架（与表格渲染完全解耦） ----------
// colConfig: { [prop]: { visible, width, fixed, sortOrder } }
// TABLE_COLUMNS 是静态 const，Vue 不追踪其内部变化，只有 colConfig 是响应式
const colConfig = ref({})
const PAGE_PATH = '/fsm/work-orders'

// 可见列：computed，基于 TABLE_COLUMNS 静态定义 + colConfig 动态配置
const visibleColumns = computed(() => {
  const cfg = colConfig.value
  const widthKey = `cs_width_${PAGE_PATH}`
  const savedWidth = JSON.parse(localStorage.getItem(widthKey) || '{}')
  return TABLE_COLUMNS
    .map(col => {
      const c = cfg[col.prop] || {}
      return {
        ...col,
        visible: c.visible !== undefined ? c.visible : col.visible,
        width: savedWidth[col.prop] || c.width || col.width,
        fixed: c.fixed !== undefined ? c.fixed : col.fixed,
        sortOrder: c.sortOrder !== undefined ? c.sortOrder : -1
      }
    })
    .filter(col => col.visible)
    .sort((a, b) => a.sortOrder - b.sortOrder)
})

// 表格上方工具栏里 ColumnSettings 需要的完整列数据（含隐藏列）
const mergedColumns = computed(() => {
  const cfg = colConfig.value
  const widthKey = `cs_width_${PAGE_PATH}`
  const savedWidth = JSON.parse(localStorage.getItem(widthKey) || '{}')
  return TABLE_COLUMNS.map(col => {
    const c = cfg[col.prop] || {}
    return {
      ...col,
      visible: c.visible !== undefined ? c.visible : col.visible,
      width: savedWidth[col.prop] || c.width || col.width,
      fixed: c.fixed !== undefined ? c.fixed : col.fixed
    }
  })
})

// 从服务器加载列配置
const loadColConfig = async () => {
  try {
    const res = await fetch(`/api/v1/system/column-configs?pagePath=${encodeURIComponent(PAGE_PATH)}`)
    const json = await res.json()
    if (json.code === 0 && json.data && json.data.length > 0) {
      const map = {}
      json.data.forEach(s => {
        map[s.columnKey] = {
          visible: s.visible === 1,
          fixed: s.fixed === 1,
          width: s.width || undefined,
          sortOrder: s.sortOrder || -1
        }
      })
      colConfig.value = map
    }
  } catch (e) { /* ignore */ }
}

// 列设置保存后：从 ColumnSettings 返回的完整列数组中提取配置，更新 colConfig
// 宽度已由 ColumnSettings 存入 localStorage，此处只需更新 colConfig（触发 visibleColumns 重算）
const onColumnConfigChange = (columns) => {
  const map = {}
  columns.forEach((col, idx) => {
    map[col.prop] = {
      visible: col.visible,
      fixed: col.fixed || false,
      width: col.width || col._width || undefined,
      sortOrder: idx
    }
  })
  colConfig.value = map
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
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })

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
  loadColConfig()  // 加载用户列配置（不阻塞表格渲染）
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
.seq-col-header,
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
