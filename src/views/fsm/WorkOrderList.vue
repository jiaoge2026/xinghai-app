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
          <el-table-column v-if="isColVisible('hsicrmWorkorderid')" prop="hsicrmWorkorderid" label="工单编号" :width="getColWidth('hsicrmWorkorderid') || 150" fixed show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmWorkorderstatusname')" prop="hsicrmWorkorderstatusname" label="状态" :width="getColWidth('hsicrmWorkorderstatusname') || 110" fixed show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmConsumername')" prop="hsicrmConsumername" label="客户姓名" :width="getColWidth('hsicrmConsumername') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmOtherphone')" prop="hsicrmOtherphone" label="电话" :width="getColWidth('hsicrmOtherphone') || 130" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmRealphone')" prop="hsicrmRealphone" label="真实电话" :width="getColWidth('hsicrmRealphone') || 120" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmConsumeraddr')" prop="hsicrmConsumeraddr" label="地址" :min-width="getColWidth('hsicrmConsumeraddr') || 200" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmDistrictname')" prop="hsicrmDistrictname" label="区县" :width="getColWidth('hsicrmDistrictname') || 90" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmTownname')" prop="hsicrmTownname" label="乡镇" :width="getColWidth('hsicrmTownname') || 90" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmRegionname')" prop="hsicrmRegionname" label="省份" :width="getColWidth('hsicrmRegionname') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmTopregionname')" prop="hsicrmTopregionname" label="大区" :width="getColWidth('hsicrmTopregionname') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmRequireservicetypename')" prop="hsicrmRequireservicetypename" label="服务类型" :width="getColWidth('hsicrmRequireservicetypename') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmActualservicetypename')" prop="hsicrmActualservicetypename" label="实际服务类型" :width="getColWidth('hsicrmActualservicetypename') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmBrandname')" prop="hsicrmBrandname" label="品牌" :width="getColWidth('hsicrmBrandname') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmProductmodel')" prop="hsicrmProductmodel" label="产品型号" :width="getColWidth('hsicrmProductmodel') || 130" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmProductmodelname')" prop="hsicrmProductmodelname" label="产品型号名" :width="getColWidth('hsicrmProductmodelname') || 130" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmSerialnumber')" prop="hsicrmSerialnumber" label="序列号" :width="getColWidth('hsicrmSerialnumber') || 140" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmEmployeename')" prop="hsicrmEmployeename" label="工程师" :width="getColWidth('hsicrmEmployeename') || 90" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmEmployeenumber')" prop="hsicrmEmployeenumber" label="工程师工号" :width="getColWidth('hsicrmEmployeenumber') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmServicestationname')" prop="hsicrmServicestationname" label="服务站" :min-width="getColWidth('hsicrmServicestationname') || 150" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmServicestationcode')" prop="hsicrmServicestationcode" label="服务站编码" :width="getColWidth('hsicrmServicestationcode') || 120" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmReceivedfee')" prop="hsicrmReceivedfee" label="收费(元)" :width="getColWidth('hsicrmReceivedfee') || 90" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmPaytypename')" prop="hsicrmPaytypename" label="支付方式" :width="getColWidth('hsicrmPaytypename') || 90" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmPaystatus')" prop="hsicrmPaystatus" label="支付状态" :width="getColWidth('hsicrmPaystatus') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmRegistrationtime')" prop="hsicrmRegistrationtime" label="创建时间" :width="getColWidth('hsicrmRegistrationtime') || 160" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmDispatchtime')" prop="hsicrmDispatchtime" label="派工时间" :width="getColWidth('hsicrmDispatchtime') || 160" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmServicestationcompletetime')" prop="hsicrmServicestationcompletetime" label="完工时间" :width="getColWidth('hsicrmServicestationcompletetime') || 160" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmHaiercompletetime')" prop="hsicrmHaiercompletetime" label="海尔完工时间" :width="getColWidth('hsicrmHaiercompletetime') || 160" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmSignintime')" prop="hsicrmSignintime" label="签到时间" :width="getColWidth('hsicrmSignintime') || 160" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmSourcename')" prop="hsicrmSourcename" label="来源" :width="getColWidth('hsicrmSourcename') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmSourcecode')" prop="hsicrmSourcecode" label="来源编码" :width="getColWidth('hsicrmSourcecode') || 90" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmIsfromnetwork')" prop="hsicrmIsfromnetwork" label="网单" :width="getColWidth('hsicrmIsfromnetwork') || 60" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmDispatchmode')" prop="hsicrmDispatchmode" label="派工方式" :width="getColWidth('hsicrmDispatchmode') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmRequireservicemodename')" prop="hsicrmRequireservicemodename" label="预约服务模式" :width="getColWidth('hsicrmRequireservicemodename') || 110" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmRequireservicetime')" prop="hsicrmRequireservicetime" label="预约服务时间" :width="getColWidth('hsicrmRequireservicetime') || 160" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmConsumersex')" prop="hsicrmConsumersex" label="性别" :width="getColWidth('hsicrmConsumersex') || 60" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmConsumerno')" prop="hsicrmConsumerno" label="客户编号" :width="getColWidth('hsicrmConsumerno') || 120" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmIndustryname')" prop="hsicrmIndustryname" label="行业" :width="getColWidth('hsicrmIndustryname') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmWarrantytype')" prop="hsicrmWarrantytype" label="保修类型" :width="getColWidth('hsicrmWarrantytype') || 90" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmTimeduration')" prop="hsicrmTimeduration" label="工时(分钟)" :width="getColWidth('hsicrmTimeduration') || 90" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmSalesdate')" prop="hsicrmSalesdate" label="销售日期" :width="getColWidth('hsicrmSalesdate') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmInvoiceno')" prop="hsicrmInvoiceno" label="发票号" :width="getColWidth('hsicrmInvoiceno') || 140" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmComplaintsnumber')" prop="hsicrmComplaintsnumber" label="投诉编号" :width="getColWidth('hsicrmComplaintsnumber') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmWorkorderstatuscode')" prop="hsicrmWorkorderstatuscode" label="状态编码" :width="getColWidth('hsicrmWorkorderstatuscode') || 90" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmPoiregion')" prop="hsicrmPoiregion" label="POI区域" :width="getColWidth('hsicrmPoiregion') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmLatitude')" prop="hsicrmLatitude" label="纬度" :width="getColWidth('hsicrmLatitude') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmLongitude')" prop="hsicrmLongitude" label="经度" :width="getColWidth('hsicrmLongitude') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmBequeathreason')" prop="hsicrmBequeathreason" label="转交原因" :min-width="getColWidth('hsicrmBequeathreason') || 150" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmConsumerdesc')" prop="hsicrmConsumerdesc" label="客户描述" :min-width="getColWidth('hsicrmConsumerdesc') || 150" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmGenerationphone')" prop="hsicrmGenerationphone" label="生成电话" :width="getColWidth('hsicrmGenerationphone') || 120" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmContactnumber')" prop="hsicrmContactnumber" label="联系电话" :width="getColWidth('hsicrmContactnumber') || 120" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmTaxbmobilephone')" prop="hsicrmTaxbmobilephone" label="师傅回电电话" :width="getColWidth('hsicrmTaxbmobilephone') || 120" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmMobilenumber')" prop="hsicrmMobilenumber" label="手机号" :width="getColWidth('hsicrmMobilenumber') || 120" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmMobilephoneservicestationname')" prop="hsicrmMobilephoneservicestationname" label="手机服务站名" :width="getColWidth('hsicrmMobilephoneservicestationname') || 150" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmCustomerphone')" prop="hsicrmCustomerphone" label="客户电话" :width="getColWidth('hsicrmCustomerphone') || 120" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmBrandcode')" prop="hsicrmBrandcode" label="品牌编码" :width="getColWidth('hsicrmBrandcode') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmProductcategoryname')" prop="hsicrmProductcategoryname" label="产品类别" :width="getColWidth('hsicrmProductcategoryname') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmProductcategorycode')" prop="hsicrmProductcategorycode" label="产品类别编码" :width="getColWidth('hsicrmProductcategorycode') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmIndustrycode')" prop="hsicrmIndustrycode" label="行业编码" :width="getColWidth('hsicrmIndustrycode') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmRegioncode')" prop="hsicrmRegioncode" label="省份编码" :width="getColWidth('hsicrmRegioncode') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmTopregioncode')" prop="hsicrmTopregioncode" label="大区编码" :width="getColWidth('hsicrmTopregioncode') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmPaytypecode')" prop="hsicrmPaytypecode" label="支付类型编码" :width="getColWidth('hsicrmPaytypecode') || 90" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmRequireservicetypecode')" prop="hsicrmRequireservicetypecode" label="服务类型编码" :width="getColWidth('hsicrmRequireservicetypecode') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmActualservicetypecode')" prop="hsicrmActualservicetypecode" label="实际服务类型编码" :width="getColWidth('hsicrmActualservicetypecode') || 110" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmActualservicemodename')" prop="hsicrmActualservicemodename" label="实际服务模式" :width="getColWidth('hsicrmActualservicemodename') || 110" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmActualservicemodecode')" prop="hsicrmActualservicemodecode" label="实际服务模式编码" :width="getColWidth('hsicrmActualservicemodecode') || 110" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmDispatchresultsdesc')" prop="hsicrmDispatchresultsdesc" label="派工结果描述" :min-width="getColWidth('hsicrmDispatchresultsdesc') || 150" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmReturnnetid')" prop="hsicrmReturnnetid" label="退回网点ID" :width="getColWidth('hsicrmReturnnetid') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmReturnnetname')" prop="hsicrmReturnnetname" label="退回网点名称" :width="getColWidth('hsicrmReturnnetname') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmActualwarrantytypoename')" prop="hsicrmActualwarrantytypoename" label="实际保修类型" :width="getColWidth('hsicrmActualwarrantytypoename') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmTrippingtypename')" prop="hsicrmTrippingtypename" label="差旅类型" :width="getColWidth('hsicrmTrippingtypename') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmTrippingtypecode')" prop="hsicrmTrippingtypecode" label="差旅类型编码" :width="getColWidth('hsicrmTrippingtypecode') || 90" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmSecondleveltrippingtypename')" prop="hsicrmSecondleveltrippingtypename" label="二级差旅类型" :width="getColWidth('hsicrmSecondleveltrippingtypename') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmSecondleveltrippingtypecode')" prop="hsicrmSecondleveltrippingtypecode" label="二级差旅类型编码" :width="getColWidth('hsicrmSecondleveltrippingtypecode') || 110" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmUrgencydegreename')" prop="hsicrmUrgencydegreename" label="紧急程度" :width="getColWidth('hsicrmUrgencydegreename') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmImportancename')" prop="hsicrmImportancename" label="重要程度" :width="getColWidth('hsicrmImportancename') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmImportancecode')" prop="hsicrmImportancecode" label="重要程度编码" :width="getColWidth('hsicrmImportancecode') || 90" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmEvaluationresult')" prop="hsicrmEvaluationresult" label="评价结果" :width="getColWidth('hsicrmEvaluationresult') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmEvaluatechannel')" prop="hsicrmEvaluatechannel" label="评价渠道" :width="getColWidth('hsicrmEvaluatechannel') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmEvaluationcompletiontime')" prop="hsicrmEvaluationcompletiontime" label="评价完成时间" :width="getColWidth('hsicrmEvaluationcompletiontime') || 160" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmShortmessagesendedtime')" prop="hsicrmShortmessagesendedtime" label="短信发送时间" :width="getColWidth('hsicrmShortmessagesendedtime') || 160" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmServicetime')" prop="hsicrmServicetime" label="服务时间" :width="getColWidth('hsicrmServicetime') || 160" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmServiceprocess')" prop="hsicrmServiceprocess" label="服务流程" :width="getColWidth('hsicrmServiceprocess') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmDocumentarytype')" prop="hsicrmDocumentarytype" label="跟单类型" :width="getColWidth('hsicrmDocumentarytype') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmDeadlinedate')" prop="hsicrmDeadlinedate" label="截止日期" :width="getColWidth('hsicrmDeadlinedate') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmEntercallcenter')" prop="hsicrmEntercallcenter" label="进入呼叫中心" :width="getColWidth('hsicrmEntercallcenter') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmBelongtocallcenter')" prop="hsicrmBelongtocallcenter" label="所属呼叫中心" :width="getColWidth('hsicrmBelongtocallcenter') || 120" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmLinkedworkorderid')" prop="hsicrmLinkedworkorderid" label="关联工单ID" :width="getColWidth('hsicrmLinkedworkorderid') || 150" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmLastcomplainttime')" prop="hsicrmLastcomplainttime" label="最后投诉时间" :width="getColWidth('hsicrmLastcomplainttime') || 160" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmInformationsource')" prop="hsicrmInformationsource" label="信息来源" :width="getColWidth('hsicrmInformationsource') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmReflectproblemclassification')" prop="hsicrmReflectproblemclassification" label="问题分类" :width="getColWidth('hsicrmReflectproblemclassification') || 120" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmRawwatertds')" prop="hsicrmRawwatertds" label="原水TDS" :width="getColWidth('hsicrmRawwatertds') || 90" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmProductprice')" prop="hsicrmProductprice" label="产品价格" :width="getColWidth('hsicrmProductprice') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmImeicode')" prop="hsicrmImeicode" label="IMEI码" :width="getColWidth('hsicrmImeicode') || 140" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmWorkordersuitno')" prop="hsicrmWorkordersuitno" label="工单套装号" :width="getColWidth('hsicrmWorkordersuitno') || 120" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmWoWorkorderid')" prop="hsicrmWoWorkorderid" label="工单外部ID" :width="getColWidth('hsicrmWoWorkorderid') || 150" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmStoragelocation')" prop="hsicrmStoragelocation" label="存储位置" :width="getColWidth('hsicrmStoragelocation') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmBizorgcode')" prop="hsicrmBizorgcode" label="业务组织编码" :width="getColWidth('hsicrmBizorgcode') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmSalesmarketcode')" prop="hsicrmSalesmarketcode" label="销售渠道编码" :width="getColWidth('hsicrmSalesmarketcode') || 100" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmOfficialwebsiteid')" prop="hsicrmOfficialwebsiteid" label="官网ID" :width="getColWidth('hsicrmOfficialwebsiteid') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmOnestopcheck')" prop="hsicrmOnestopcheck" label="一键检测" :width="getColWidth('hsicrmOnestopcheck') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmIsbound')" prop="hsicrmIsbound" label="是否绑定" :width="getColWidth('hsicrmIsbound') || 70" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmIsprint')" prop="hsicrmIsprint" label="是否打印" :width="getColWidth('hsicrmIsprint') || 70" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmIfepass')" prop="hsicrmIfepass" label="是否放行" :width="getColWidth('hsicrmIfepass') || 70" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmMembershipcategorycode')" prop="hsicrmMembershipcategorycode" label="会员类别编码" :width="getColWidth('hsicrmMembershipcategorycode') || 110" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmDeletedby')" prop="hsicrmDeletedby" label="删除人" :width="getColWidth('hsicrmDeletedby') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmBequeathreasonupdatetime')" prop="hsicrmBequeathreasonupdatetime" label="转交原因更新时间" :width="getColWidth('hsicrmBequeathreasonupdatetime') || 160" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmAttribute2')" prop="hsicrmAttribute2" label="扩展字段2" :width="getColWidth('hsicrmAttribute2') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmAttribute4')" prop="hsicrmAttribute4" label="扩展字段4" :width="getColWidth('hsicrmAttribute4') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmAttribute5')" prop="hsicrmAttribute5" label="扩展字段5" :width="getColWidth('hsicrmAttribute5') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmAttribute6')" prop="hsicrmAttribute6" label="扩展字段6" :width="getColWidth('hsicrmAttribute6') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmAttribute7')" prop="hsicrmAttribute7" label="扩展字段7" :width="getColWidth('hsicrmAttribute7') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmAttribute9')" prop="hsicrmAttribute9" label="扩展字段9" :width="getColWidth('hsicrmAttribute9') || 80" show-overflow-tooltip />
          <el-table-column v-if="isColVisible('hsicrmContactconsumertime')" prop="hsicrmContactconsumertime" label="联系客户时间" :width="getColWidth('hsicrmContactconsumertime') || 160" show-overflow-tooltip />
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
  { prop: 'hsicrmConsumername', label: '客户姓名', visible: true },
  { prop: 'hsicrmOtherphone', label: '电话', visible: true },
  { prop: 'hsicrmRealphone', label: '真实电话', visible: false },
  { prop: 'hsicrmConsumeraddr', label: '地址', visible: true },
  { prop: 'hsicrmDistrictname', label: '区县', visible: false },
  { prop: 'hsicrmTownname', label: '乡镇', visible: false },
  { prop: 'hsicrmRegionname', label: '省份', visible: false },
  { prop: 'hsicrmTopregionname', label: '大区', visible: false },
  { prop: 'hsicrmRequireservicetypename', label: '服务类型', visible: true },
  { prop: 'hsicrmActualservicetypename', label: '实际服务类型', visible: false },
  { prop: 'hsicrmBrandname', label: '品牌', visible: false },
  { prop: 'hsicrmProductmodel', label: '产品型号', visible: false },
  { prop: 'hsicrmProductmodelname', label: '产品型号名', visible: false },
  { prop: 'hsicrmSerialnumber', label: '序列号', visible: false },
  { prop: 'hsicrmEmployeename', label: '工程师', visible: true },
  { prop: 'hsicrmEmployeenumber', label: '工程师工号', visible: false },
  { prop: 'hsicrmServicestationname', label: '服务站', visible: false },
  { prop: 'hsicrmServicestationcode', label: '服务站编码', visible: false },
  { prop: 'hsicrmReceivedfee', label: '收费(元)', visible: true },
  { prop: 'hsicrmPaytypename', label: '支付方式', visible: false },
  { prop: 'hsicrmPaystatus', label: '支付状态', visible: false },
  { prop: 'hsicrmRegistrationtime', label: '创建时间', visible: true },
  { prop: 'hsicrmDispatchtime', label: '派工时间', visible: false },
  { prop: 'hsicrmServicestationcompletetime', label: '完工时间', visible: false },
  { prop: 'hsicrmHaiercompletetime', label: '海尔完工时间', visible: false },
  { prop: 'hsicrmSignintime', label: '签到时间', visible: false },
  { prop: 'hsicrmSourcename', label: '来源', visible: false },
  { prop: 'hsicrmSourcecode', label: '来源编码', visible: false },
  { prop: 'hsicrmIsfromnetwork', label: '网单', visible: false },
  { prop: 'hsicrmDispatchmode', label: '派工方式', visible: false },
  { prop: 'hsicrmRequireservicemodename', label: '预约服务模式', visible: false },
  { prop: 'hsicrmRequireservicetime', label: '预约服务时间', visible: false },
  { prop: 'hsicrmConsumersex', label: '性别', visible: false },
  { prop: 'hsicrmConsumerno', label: '客户编号', visible: false },
  { prop: 'hsicrmIndustryname', label: '行业', visible: false },
  { prop: 'hsicrmWarrantytype', label: '保修类型', visible: false },
  { prop: 'hsicrmTimeduration', label: '工时(分钟)', visible: false },
  { prop: 'hsicrmSalesdate', label: '销售日期', visible: false },
  { prop: 'hsicrmInvoiceno', label: '发票号', visible: false },
  { prop: 'hsicrmComplaintsnumber', label: '投诉编号', visible: false },
  { prop: 'hsicrmWorkorderstatuscode', label: '状态编码', visible: false },
  { prop: 'hsicrmPoiregion', label: 'POI区域', visible: false },
  { prop: 'hsicrmLatitude', label: '纬度', visible: false },
  { prop: 'hsicrmLongitude', label: '经度', visible: false },
  { prop: 'hsicrmBequeathreason', label: '转交原因', visible: false },
  { prop: 'hsicrmConsumerdesc', label: '客户描述', visible: false },
  { prop: 'hsicrmGenerationphone', label: '生成电话', visible: false },
  { prop: 'hsicrmContactnumber', label: '联系电话', visible: false },
  { prop: 'hsicrmTaxbmobilephone', label: '师傅回电电话', visible: false },
  { prop: 'hsicrmMobilenumber', label: '手机号', visible: false },
  { prop: 'hsicrmMobilephoneservicestationname', label: '手机服务站名', visible: false },
  { prop: 'hsicrmCustomerphone', label: '客户电话', visible: false },
  { prop: 'hsicrmBrandcode', label: '品牌编码', visible: false },
  { prop: 'hsicrmProductcategoryname', label: '产品类别', visible: false },
  { prop: 'hsicrmProductcategorycode', label: '产品类别编码', visible: false },
  { prop: 'hsicrmIndustrycode', label: '行业编码', visible: false },
  { prop: 'hsicrmRegioncode', label: '省份编码', visible: false },
  { prop: 'hsicrmTopregioncode', label: '大区编码', visible: false },
  { prop: 'hsicrmPaytypecode', label: '支付类型编码', visible: false },
  { prop: 'hsicrmRequireservicetypecode', label: '服务类型编码', visible: false },
  { prop: 'hsicrmActualservicetypecode', label: '实际服务类型编码', visible: false },
  { prop: 'hsicrmActualservicemodename', label: '实际服务模式', visible: false },
  { prop: 'hsicrmActualservicemodecode', label: '实际服务模式编码', visible: false },
  { prop: 'hsicrmDispatchresultsdesc', label: '派工结果描述', visible: false },
  { prop: 'hsicrmReturnnetid', label: '退回网点ID', visible: false },
  { prop: 'hsicrmReturnnetname', label: '退回网点名称', visible: false },
  { prop: 'hsicrmActualwarrantytypoename', label: '实际保修类型', visible: false },
  { prop: 'hsicrmTrippingtypename', label: '差旅类型', visible: false },
  { prop: 'hsicrmTrippingtypecode', label: '差旅类型编码', visible: false },
  { prop: 'hsicrmSecondleveltrippingtypename', label: '二级差旅类型', visible: false },
  { prop: 'hsicrmSecondleveltrippingtypecode', label: '二级差旅类型编码', visible: false },
  { prop: 'hsicrmUrgencydegreename', label: '紧急程度', visible: false },
  { prop: 'hsicrmImportancename', label: '重要程度', visible: false },
  { prop: 'hsicrmImportancecode', label: '重要程度编码', visible: false },
  { prop: 'hsicrmEvaluationresult', label: '评价结果', visible: false },
  { prop: 'hsicrmEvaluatechannel', label: '评价渠道', visible: false },
  { prop: 'hsicrmEvaluationcompletiontime', label: '评价完成时间', visible: false },
  { prop: 'hsicrmShortmessagesendedtime', label: '短信发送时间', visible: false },
  { prop: 'hsicrmServicetime', label: '服务时间', visible: false },
  { prop: 'hsicrmServiceprocess', label: '服务流程', visible: false },
  { prop: 'hsicrmDocumentarytype', label: '跟单类型', visible: false },
  { prop: 'hsicrmDeadlinedate', label: '截止日期', visible: false },
  { prop: 'hsicrmEntercallcenter', label: '进入呼叫中心', visible: false },
  { prop: 'hsicrmBelongtocallcenter', label: '所属呼叫中心', visible: false },
  { prop: 'hsicrmLinkedworkorderid', label: '关联工单ID', visible: false },
  { prop: 'hsicrmLastcomplainttime', label: '最后投诉时间', visible: false },
  { prop: 'hsicrmInformationsource', label: '信息来源', visible: false },
  { prop: 'hsicrmReflectproblemclassification', label: '问题分类', visible: false },
  { prop: 'hsicrmRawwatertds', label: '原水TDS', visible: false },
  { prop: 'hsicrmProductprice', label: '产品价格', visible: false },
  { prop: 'hsicrmImeicode', label: 'IMEI码', visible: false },
  { prop: 'hsicrmWorkordersuitno', label: '工单套装号', visible: false },
  { prop: 'hsicrmWoWorkorderid', label: '工单外部ID', visible: false },
  { prop: 'hsicrmStoragelocation', label: '存储位置', visible: false },
  { prop: 'hsicrmBizorgcode', label: '业务组织编码', visible: false },
  { prop: 'hsicrmSalesmarketcode', label: '销售渠道编码', visible: false },
  { prop: 'hsicrmOfficialwebsiteid', label: '官网ID', visible: false },
  { prop: 'hsicrmOnestopcheck', label: '一键检测', visible: false },
  { prop: 'hsicrmIsbound', label: '是否绑定', visible: false },
  { prop: 'hsicrmIsprint', label: '是否打印', visible: false },
  { prop: 'hsicrmIfepass', label: '是否放行', visible: false },
  { prop: 'hsicrmMembershipcategorycode', label: '会员类别编码', visible: false },
  { prop: 'hsicrmDeletedby', label: '删除人', visible: false },
  { prop: 'hsicrmBequeathreasonupdatetime', label: '转交原因更新时间', visible: false },
  { prop: 'hsicrmAttribute2', label: '扩展字段2', visible: false },
  { prop: 'hsicrmAttribute4', label: '扩展字段4', visible: false },
  { prop: 'hsicrmAttribute5', label: '扩展字段5', visible: false },
  { prop: 'hsicrmAttribute6', label: '扩展字段6', visible: false },
  { prop: 'hsicrmAttribute7', label: '扩展字段7', visible: false },
  { prop: 'hsicrmAttribute9', label: '扩展字段9', visible: false },
  { prop: 'hsicrmContactconsumertime', label: '联系客户时间', visible: false },
]

const localColumns = ref([...TABLE_COLUMNS])
const isColVisible = (prop) => {
  const col = localColumns.value.find(c => c.prop === prop)
  return col ? col.visible : false
}
const getColWidth = (prop) => {
  const col = localColumns.value.find(c => c.prop === prop)
  return col?._width || col?.width || undefined
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
