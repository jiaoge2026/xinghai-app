import { createRouter, createWebHistory } from 'vue-router'
import { setAuthConfirmed } from '@/utils/request'

const routes = [
  { path: '/login', name: 'Login', component: () => import('@/views/login/Login.vue'), meta: { public: true } },
  { 
    path: '/', 
    component: () => import('@/views/layout/MainLayout.vue'),
    redirect: '/dashboard',
    children: [
      { path: 'dashboard', name: 'Dashboard', component: () => import('@/views/dashboard/Dashboard.vue'), meta: { title: '驾驶舱' } },
      { path: 'fsm/work-orders', name: 'WorkOrders', component: () => import('@/views/fsm/WorkOrderList.vue'), meta: { title: '工单管理' } },
      { path: 'fsm/work-orders/create', name: 'WorkOrderCreate', component: () => import('@/views/fsm/WorkOrderCreate.vue'), meta: { title: '新建工单' } },
      { path: 'fsm/engineers', name: 'Engineers', component: () => import('@/views/fsm/EngineerList.vue'), meta: { title: '工程师管理' } },
      { path: 'wms/parts', name: 'Parts', component: () => import('@/views/wms/PartList.vue'), meta: { title: '配件管理' } },
      { path: 'wms/warehouses', name: 'Warehouses', component: () => import('@/views/wms/WarehouseList.vue'), meta: { title: '仓库管理' } },
      { path: 'wms/stock', name: 'Stock', component: () => import('@/views/wms/StockList.vue'), meta: { title: '库��管理' } },
      { path: 'dispatch/board', name: 'DispatchBoard', component: () => import('@/views/dispatch/DispatchBoard.vue'), meta: { title: '智能派工' } },
      { path: 'finance/vouchers', name: 'Vouchers', component: () => import('@/views/finance/VoucherList.vue'), meta: { title: '凭证管理' } },
      { path: 'finance/reports', name: 'FinanceReports', component: () => import('@/views/finance/FinanceReport.vue'), meta: { title: '财务报表' } },
      { path: 'hr/employees', name: 'Employees', component: () => import('@/views/hr/EmployeeList.vue'), meta: { title: '员工管理' } },
      { path: 'hr/attendance', name: 'Attendance', component: () => import('@/views/hr/Attendance.vue'), meta: { title: '考勤管理' } },
      { path: 'hr/salary', name: 'Salary', component: () => import('@/views/hr/SalaryList.vue'), meta: { title: '薪资管理' } },
      { path: 'crm/customers', name: 'Customers', component: () => import('@/views/crm/CustomerList.vue'), meta: { title: '客户管理' } },
      { path: 'crm/contacts', name: 'Contacts', component: () => import('@/views/crm/ContactList.vue'), meta: { title: '联系人管理' } },
      { path: 'retail/orders', name: 'SalesOrders', component: () => import('@/views/retail/SalesOrderList.vue'), meta: { title: '销售订单' } },
      { path: 'retail/products', name: 'Products', component: () => import('@/views/retail/ProductList.vue'), meta: { title: '商品管理' } },
      { path: 'retail/stores', name: 'Stores', component: () => import('@/views/retail/StoreList.vue'), meta: { title: '门店管理' } },
      { path: 'member/members', name: 'Members', component: () => import('@/views/member/MemberList.vue'), meta: { title: '会员管理' } },
      { path: 'logistics/drivers', name: 'Drivers', component: () => import('@/views/logistics/DriverList.vue'), meta: { title: '司机管理' } },
      { path: 'logistics/delivery', name: 'DeliveryOrders', component: () => import('@/views/logistics/DeliveryOrderList.vue'), meta: { title: '配送单' } },
      { path: 'callcenter/records', name: 'CallRecords', component: () => import('@/views/callcenter/CallRecordList.vue'), meta: { title: '来电记录' } },
      { path: 'qa/inspections', name: 'Inspections', component: () => import('@/views/qa/InspectionList.vue'), meta: { title: '质量检查' } },
      { path: 'qa/feedback', name: 'Feedback', component: () => import('@/views/qa/FeedbackList.vue'), meta: { title: '客户反馈' } },
      { path: 'approval/list', name: 'ApprovalList', component: () => import('@/views/approval/ApprovalList.vue'), meta: { title: '审批流程' } },
      { path: 'system/users', name: 'SystemUsers', component: () => import('@/views/system/UserList.vue'), meta: { title: '用户管理' } },
      { path: 'system/roles', name: 'SystemRoles', component: () => import('@/views/system/RoleList.vue'), meta: { title: '角色管理' } },
      { path: 'system/menus', name: 'SystemMenus', component: () => import('@/views/system/MenuList.vue'), meta: { title: '权限管理' } },
      { path: 'system/config', name: 'SystemConfig', component: () => import('@/views/system/ConfigList.vue'), meta: { title: '系统配置' } },
      { path: 'system/upgrade', name: 'SystemUpgrade', component: () => import('@/views/system/UpgradeManager.vue'), meta: { title: '升级管理' } },
      { path: 'system/upgrade', name: 'SystemUpgrade', component: () => import('@/views/system/UpgradeManager.vue'), meta: { title: '升级管理' } },
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  if (!to.meta.public && !token) {
    next('/login')
  } else {
    // Auth confirmed: mark it before allowing navigation
    if (token) setAuthConfirmed(true)
    next()
  }
})

export default router