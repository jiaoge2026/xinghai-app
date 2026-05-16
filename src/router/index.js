import { createRouter, createWebHistory } from 'vue-router'
import { setAuthConfirmed } from '@/utils/request'
import { addTab } from '@/stores/tab'
import COMPONENT_MAP, { PATH_TO_NAME } from '@/utils/tab'

const routes = [
  { path: '/login', name: 'Login', component: () => import('@/views/login/Login.vue'), meta: { public: true } },
  {
    path: '/',
    component: () => import('@/views/layout/MainLayout.vue'),
    redirect: '/dashboard',
    children: [
      { path: 'dashboard', name: 'Dashboard', component: () => import('@/views/dashboard/Dashboard.vue'), meta: { title: '驾驶舱' } },
      // FSM工单
      { path: 'fsm/work-orders', name: 'WorkOrders', component: () => import('@/views/fsm/WorkOrderList.vue'), meta: { title: '工单管理' } },
      { path: 'fsm/work-orders/create', name: 'WorkOrderCreate', component: () => import('@/views/fsm/WorkOrderCreate.vue'), meta: { title: '新建工单' } },
      { path: 'fsm/engineers', name: 'Engineers', component: () => import('@/views/fsm/EngineerList.vue'), meta: { title: '工程师管理' } },
      { path: 'fsm/gps', name: 'GpsTracking', component: () => import('@/views/fsm/GpsTracking.vue'), meta: { title: 'GPS追踪' } },
      { path: 'fsm/caller-id', name: 'CallerId', component: () => import('@/views/fsm/CallerId.vue'), meta: { title: '来电弹屏' } },
      // 仓储管理
      { path: 'wms/parts', name: 'Parts', component: () => import('@/views/wms/PartList.vue'), meta: { title: '配件管理' } },
      { path: 'wms/warehouses', name: 'Warehouses', component: () => import('@/views/wms/WarehouseList.vue'), meta: { title: '仓库管理' } },
      { path: 'wms/stock', name: 'Stock', component: () => import('@/views/wms/StockList.vue'), meta: { title: '库存台账' } },
      { path: 'wms/alerts', name: 'InventoryAlerts', component: () => import('@/views/wms/InventoryAlert.vue'), meta: { title: '库存预警' } },
      // 智能派工
      { path: 'dispatch/board', name: 'DispatchBoard', component: () => import('@/views/dispatch/DispatchBoard.vue'), meta: { title: '智能派工' } },
      // 财务管理
      { path: 'finance/vouchers', name: 'Vouchers', component: () => import('@/views/finance/VoucherList.vue'), meta: { title: '凭证管理' } },
      { path: 'finance/reports', name: 'FinanceReports', component: () => import('@/views/finance/FinanceReport.vue'), meta: { title: '财务报表' } },
      // 人事管理
      { path: 'hr/employees', name: 'Employees', component: () => import('@/views/hr/EmployeeList.vue'), meta: { title: '员工管理' } },
      { path: 'hr/attendance', name: 'Attendance', component: () => import('@/views/hr/Attendance.vue'), meta: { title: '考勤管理' } },
      { path: 'hr/salary', name: 'Salary', component: () => import('@/views/hr/SalaryList.vue'), meta: { title: '薪资管理' } },
      { path: 'hr/commission', name: 'Commission', component: () => import('@/views/hr/CommissionList.vue'), meta: { title: '提成管理' } },
      // 客户管理
      { path: 'crm/customers', name: 'Customers', component: () => import('@/views/crm/CustomerList.vue'), meta: { title: '客户管理' } },
      { path: 'crm/contacts', name: 'Contacts', component: () => import('@/views/crm/ContactList.vue'), meta: { title: '联系人管理' } },
      // 零售门店
      { path: 'retail/orders', name: 'SalesOrders', component: () => import('@/views/retail/SalesOrderList.vue'), meta: { title: '销售订单' } },
      { path: 'retail/products', name: 'Products', component: () => import('@/views/retail/ProductList.vue'), meta: { title: '商品管理' } },
      { path: 'retail/stores', name: 'Stores', component: () => import('@/views/retail/StoreList.vue'), meta: { title: '门店管理' } },
      // 会员管理
      { path: 'member/members', name: 'Members', component: () => import('@/views/member/MemberList.vue'), meta: { title: '会员管理' } },
      // 物流配送
      { path: 'logistics/drivers', name: 'Drivers', component: () => import('@/views/logistics/DriverList.vue'), meta: { title: '司机管理' } },
      { path: 'logistics/delivery', name: 'DeliveryOrders', component: () => import('@/views/logistics/DeliveryOrderList.vue'), meta: { title: '配送单' } },
      // 呼叫中心
      { path: 'callcenter/records', name: 'CallRecords', component: () => import('@/views/callcenter/CallRecordList.vue'), meta: { title: '来电记录' } },
      // 质量管理
      { path: 'qa/inspections', name: 'Inspections', component: () => import('@/views/qa/InspectionList.vue'), meta: { title: '质量检查' } },
      { path: 'qa/feedback', name: 'Feedback', component: () => import('@/views/qa/FeedbackList.vue'), meta: { title: '客户反馈' } },
      // 审批流
      { path: 'approval/list', name: 'ApprovalList', component: () => import('@/views/approval/ApprovalList.vue'), meta: { title: '审批流程' } },
      { path: 'approval/definition', name: 'WorkflowDefinition', component: () => import('@/views/approval/WorkflowDefinition.vue'), meta: { title: '流程模板' } },
      // 系统管理
      { path: 'system/users', name: 'SystemUsers', component: () => import('@/views/system/UserList.vue'), meta: { title: '用户管理' } },
      { path: 'system/roles', name: 'SystemRoles', component: () => import('@/views/system/RoleList.vue'), meta: { title: '角色管理' } },
      { path: 'system/menus', name: 'SystemMenus', component: () => import('@/views/system/MenuList.vue'), meta: { title: '权限管理' } },
      { path: 'system/role-config', name: 'SystemRoleConfig', component: () => import('@/views/system/RoleConfig.vue'), meta: { title: '角色配置' } },
      { path: 'system/config', name: 'SystemConfig', component: () => import('@/views/system/ConfigList.vue'), meta: { title: '系统配置' } },
      { path: 'system/upgrade', name: 'SystemUpgrade', component: () => import('@/views/system/UpgradeManager.vue'), meta: { title: '升级管理' } },
      { path: 'system/export-tasks', name: 'ExportTasks', component: () => import('@/views/system/ExportTasks.vue'), meta: { title: '导出任务' } },
      // AI助手
      { path: 'ai/chat', name: 'AIChat', component: () => import('@/views/ai/AIChat.vue'), meta: { title: 'AI助手' } },

      // ===== 新增：工程销售 =====
      { path: 'sales/customers', name: 'SalesCustomers', component: () => import('@/views/sales/Customers.vue'), meta: { title: '工程客户' } },
      { path: 'sales/quotes', name: 'SalesQuotes', component: () => import('@/views/sales/Quotes.vue'), meta: { title: '报价单' } },
      { path: 'sales/project-orders', name: 'ProjectOrders', component: () => import('@/views/sales/ProjectOrders.vue'), meta: { title: '项目订单' } },
      { path: 'sales/receivables', name: 'SalesReceivables', component: () => import('@/views/sales/Receivables.vue'), meta: { title: '应收款' } },

      // ===== 新增：海尔同步 =====
      { path: 'haier/sync', name: 'HaierSync', component: () => import('@/views/haier/HaierSync.vue'), meta: { title: '海尔同步' } },
      { path: 'haier/accounts', name: 'HaierAccounts', component: () => import('@/views/haier/HaierAccounts.vue'), meta: { title: '海尔账号' } },
      { path: 'haier/logs', name: 'SyncLogs', component: () => import('@/views/haier/SyncLogs.vue'), meta: { title: '同步日志' } },

      // ===== 新增：报表 =====
      { path: 'report/work-orders', name: 'ReportWorkOrders', component: () => import('@/views/report/ReportWorkOrder.vue'), meta: { title: '工单报表' } },

      // ===== 补全：tb_menu有但router缺失的路径 =====
      // FSM
      { path: 'fsm/customers', name: 'FSMCustomers', component: () => import('@/views/crm/CustomerList.vue'), meta: { title: '客户列表' } },
      { path: 'fsm/projects', name: 'FSMProjects', component: () => import('@/views/sales/ProjectOrders.vue'), meta: { title: '项目管理' } },
      // CRM
      { path: 'crm/opportunities', name: 'Opportunities', component: () => import('@/views/crm/ContactList.vue'), meta: { title: '商机管理' } },
      { path: 'crm/follow-ups', name: 'FollowUps', component: () => import('@/views/crm/FollowUpList.vue'), meta: { title: '客户跟进' } },
      { path: 'crm/tags', name: 'Tags', component: () => import('@/views/crm/TagList.vue'), meta: { title: '客户标签' } },
      // HR
      { path: 'hr/employees/import', name: 'EmployeeImport', component: () => import('@/views/hr/EmployeeList.vue'), meta: { title: '员工导入' } },
      { path: 'hr/departments', name: 'Departments', component: () => import('@/views/hr/DepartmentList.vue'), meta: { title: '部门管理' } },
      { path: 'hr/leaves', name: 'Leaves', component: () => import('@/views/hr/LeaveList.vue'), meta: { title: '请假申请' } },
      { path: 'hr/attendances', name: 'AttendanceRecord', component: () => import('@/views/hr/AttendanceRecord.vue'), meta: { title: '考勤记录' } },
      // QA
      { path: 'qa/templates', name: 'QATemplates', component: () => import('@/views/qa/InspectionList.vue'), meta: { title: '质检模板' } },
      // Finance
      { path: 'finance/subjects', name: 'Subjects', component: () => import('@/views/finance/SubjectList.vue'), meta: { title: '会计科目' } },
      { path: 'finance/receipts', name: 'Receipts', component: () => import('@/views/finance/ReceiptList.vue'), meta: { title: '收款单' } },
      { path: 'finance/payments', name: 'Payments', component: () => import('@/views/finance/PaymentList.vue'), meta: { title: '付款单' } },
      { path: 'finance/bank-accounts', name: 'BankAccounts', component: () => import('@/views/finance/BankAccountList.vue'), meta: { title: '银行账户' } },
      // Member
      { path: 'member/points', name: 'MemberPoints', component: () => import('@/views/member/PointList.vue'), meta: { title: '会员积分' } },
      { path: 'member/coupons', name: 'Coupons', component: () => import('@/views/member/CouponList.vue'), meta: { title: '优惠券' } },
      // Retail
      { path: 'retail/inventory', name: 'RetailInventory', component: () => import('@/views/wms/StockList.vue'), meta: { title: '门店库存' } },
      { path: 'retail/categories', name: 'Categories', component: () => import('@/views/retail/CategoryList.vue'), meta: { title: '零售分类' } },
      // CallCenter
      { path: 'callcenter/ivr', name: 'IVRMenu', component: () => import('@/views/callcenter/IVRMenu.vue'), meta: { title: 'IVR菜单' } },
      { path: 'callcenter/callback', name: 'CallbackList', component: () => import('@/views/callcenter/CallbackList.vue'), meta: { title: '呼入呼出' } },
      // Report
      { path: 'report/fsm', name: 'ReportFSM', component: () => import('@/views/report/ReportWorkOrder.vue'), meta: { title: 'FSM报表' } },
      { path: 'report/finance', name: 'ReportFinance', component: () => import('@/views/finance/FinanceReport.vue'), meta: { title: '财务报表' } },
      // System
      { path: 'system/organization', name: 'Organization', component: () => import('@/views/system/RoleList.vue'), meta: { title: '组织架构' } },
      { path: 'system/dicts', name: 'Dicts', component: () => import('@/views/system/Dictionary.vue'), meta: { title: '数据字典' } },
      { path: 'system/operation-logs', name: 'OperationLogs', component: () => import('@/views/system/OperationLog.vue'), meta: { title: '操作日志' } },
      // WeCom（后端未实现，先占位）
      { path: 'wecom/messages', name: 'WecomMessages', component: () => import('@/views/system/ConfigList.vue'), meta: { title: '消息推送' } },
      { path: 'wecom/callback', name: 'WeComCallback', component: () => import('@/views/system/ConfigList.vue'), meta: { title: '回调配置' } },
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  if (!to.meta?.public && !token) {
    next('/login')
    return
  }
  if (token) setAuthConfirmed(true)
  next()
})

// TabBar：路由变化时自动添加标签页
router.afterEach((to) => {
  if (to.meta?.public || !to.name) return
  addTab({
    name: to.name,
    path: to.path,
    title: to.meta.title || to.name,
    closable: true
  })
})

export default router
