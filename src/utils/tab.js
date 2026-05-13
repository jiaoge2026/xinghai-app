// tab.js - 组件名称 → Vue 组件映射表
// 所有在 Tab 系统中注册的组件必须在这里登记

const COMPONENT_MAP = {
  // ===== 驾驶舱 =====
  Dashboard: () => import('@/views/dashboard/Dashboard.vue'),

  // ===== FSM 工单 =====
  WorkOrders: () => import('@/views/fsm/WorkOrderList.vue'),
  WorkOrderCreate: () => import('@/views/fsm/WorkOrderCreate.vue'),
  Engineers: () => import('@/views/fsm/EngineerList.vue'),
  GpsTracking: () => import('@/views/fsm/GpsTracking.vue'),
  CallerId: () => import('@/views/fsm/CallerId.vue'),

  // ===== 仓储管理 =====
  Parts: () => import('@/views/wms/PartList.vue'),
  Warehouses: () => import('@/views/wms/WarehouseList.vue'),
  Stock: () => import('@/views/wms/StockList.vue'),

  // ===== 智能派工 =====
  DispatchBoard: () => import('@/views/dispatch/DispatchBoard.vue'),

  // ===== 财务管理 =====
  Vouchers: () => import('@/views/finance/VoucherList.vue'),
  FinanceReports: () => import('@/views/finance/FinanceReport.vue'),

  // ===== 人事管理 =====
  Employees: () => import('@/views/hr/EmployeeList.vue'),
  Attendance: () => import('@/views/hr/Attendance.vue'),
  Salary: () => import('@/views/hr/SalaryList.vue'),
  Commission: () => import('@/views/hr/CommissionList.vue'),

  // ===== 客户管理 =====
  Customers: () => import('@/views/crm/CustomerList.vue'),
  Contacts: () => import('@/views/crm/ContactList.vue'),

  // ===== 零售门店 =====
  SalesOrders: () => import('@/views/retail/SalesOrderList.vue'),
  Products: () => import('@/views/retail/ProductList.vue'),
  Stores: () => import('@/views/retail/StoreList.vue'),

  // ===== 会员管理 =====
  Members: () => import('@/views/member/MemberList.vue'),

  // ===== 物流配送 =====
  Drivers: () => import('@/views/logistics/DriverList.vue'),
  DeliveryOrders: () => import('@/views/logistics/DeliveryOrderList.vue'),

  // ===== 呼叫中心 =====
  CallRecords: () => import('@/views/callcenter/CallRecordList.vue'),

  // ===== 质量管理 =====
  Inspections: () => import('@/views/qa/InspectionList.vue'),
  Feedback: () => import('@/views/qa/FeedbackList.vue'),

  // ===== 审批流 =====
  ApprovalList: () => import('@/views/approval/ApprovalList.vue'),
  WorkflowDefinition: () => import('@/views/approval/WorkflowDefinition.vue'),

  // ===== 系统管理 =====
  SystemUsers: () => import('@/views/system/UserList.vue'),
  SystemRoles: () => import('@/views/system/RoleList.vue'),
  SystemMenus: () => import('@/views/system/MenuList.vue'),
  SystemRoleConfig: () => import('@/views/system/RoleConfig.vue'),
  SystemConfig: () => import('@/views/system/ConfigList.vue'),
  SystemUpgrade: () => import('@/views/system/UpgradeManager.vue'),

  // ===== AI助手 =====
  AIChat: () => import('@/views/ai/AIChat.vue'),

  // ===== 工程销售 =====
  SalesCustomers: () => import('@/views/sales/Customers.vue'),
  SalesQuotes: () => import('@/views/sales/Quotes.vue'),
  ProjectOrders: () => import('@/views/sales/ProjectOrders.vue'),
  SalesReceivables: () => import('@/views/sales/Receivables.vue'),

  // ===== 海尔同步 =====
  HaierSync: () => import('@/views/haier/HaierSync.vue'),
  HaierAccounts: () => import('@/views/haier/HaierAccounts.vue'),
  SyncLogs: () => import('@/views/haier/SyncLogs.vue'),

  // ===== 报表 =====
  ReportWorkOrders: () => import('@/views/report/ReportWorkOrder.vue'),
}

export default COMPONENT_MAP

// 路由路径 → 组件名称映射（用于 router.beforeEach 自动打开 Tab）
export const PATH_TO_NAME = {
  '/dashboard': 'Dashboard',
  '/fsm/work-orders': 'WorkOrders',
  '/fsm/work-orders/create': 'WorkOrderCreate',
  '/fsm/engineers': 'Engineers',
  '/fsm/gps': 'GpsTracking',
  '/fsm/caller-id': 'CallerId',
  '/wms/parts': 'Parts',
  '/wms/warehouses': 'Warehouses',
  '/wms/stock': 'Stock',
  '/dispatch/board': 'DispatchBoard',
  '/finance/vouchers': 'Vouchers',
  '/finance/reports': 'FinanceReports',
  '/hr/employees': 'Employees',
  '/hr/attendance': 'Attendance',
  '/hr/salary': 'Salary',
  '/hr/commission': 'Commission',
  '/crm/customers': 'Customers',
  '/crm/contacts': 'Contacts',
  '/retail/orders': 'SalesOrders',
  '/retail/products': 'Products',
  '/retail/stores': 'Stores',
  '/member/members': 'Members',
  '/logistics/drivers': 'Drivers',
  '/logistics/delivery': 'DeliveryOrders',
  '/callcenter/records': 'CallRecords',
  '/qa/inspections': 'Inspections',
  '/qa/feedback': 'Feedback',
  '/approval/list': 'ApprovalList',
  '/approval/definition': 'WorkflowDefinition',
  '/system/users': 'SystemUsers',
  '/system/roles': 'SystemRoles',
  '/system/menus': 'SystemMenus',
  '/system/role-config': 'SystemRoleConfig',
  '/system/config': 'SystemConfig',
  '/system/upgrade': 'SystemUpgrade',
  '/ai/chat': 'AIChat',
  // 工程销售
  '/sales/customers': 'SalesCustomers',
  '/sales/quotes': 'SalesQuotes',
  '/sales/project-orders': 'ProjectOrders',
  '/sales/receivables': 'SalesReceivables',
  // 海尔同步
  '/haier/sync': 'HaierSync',
  '/haier/accounts': 'HaierAccounts',
  '/haier/logs': 'SyncLogs',
  // 报表
  '/report/work-orders': 'ReportWorkOrders',
}
