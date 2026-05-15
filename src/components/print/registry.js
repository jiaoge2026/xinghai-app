/**
 * 星海ERP打印模板注册表
 * 所有打印模板在此注册，业务页面通过 templateKey 引用
 * 
 * 使用方式：
 *   import { printTemplates } from '@/components/print/registry'
 *   const template = printTemplates['work-order']
 */
export const printTemplates = {

  // ═══════════════════════════════════════
  // 工单类（3个）
  // ═══════════════════════════════════════
  'work-order': {
    label: '服务工单',
    labelEn: 'Service Order',
    icon: '📋',
    category: '工单',
    description: '完整服务工单，含客户信息、配件明细、费用汇总、客户签字',
    component: () => import('./templates/WorkOrderTemplate.vue'),
    fields: [
      'woNo', 'customerName', 'customerPhone', 'address',
      'engineerName', 'serviceTypeName', 'appointmentTime',
      'items', 'laborFee', 'partsFee', 'travelFee', 'totalFee',
      'completeTime', 'customerSign', 'engineerSign'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: true,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: true,
    includeQRCode: true,
    copies: 1,
    permissions: ['admin', 'service-manager', 'engineer'],
    apiPath: '/api/v1/fsm/work-orders',
    preview: true,
    pdf: true,
  },

  'dispatch-order': {
    label: '派工单',
    labelEn: 'Dispatch Order',
    icon: '🔧',
    category: '工单',
    description: '工程师携带联，含预约时间、服务地址、联系电话',
    component: () => import('./templates/DispatchTemplate.vue'),
    fields: [
      'woNo', 'customerName', 'customerPhone', 'address',
      'engineerName', 'engineerPhone', 'appointmentTime',
      'serviceTypeName', 'remark'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: false,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: true,
    includeQRCode: false,
    copies: 1,
    permissions: ['admin', 'service-manager', 'engineer'],
    apiPath: '/api/v1/fsm/work-orders',
    preview: true,
    pdf: true,
  },

  'return-order': {
    label: '返修单',
    labelEn: 'Return Order',
    icon: '🔄',
    category: '工单',
    description: '质量问题返修，含原工单信息、返修原因、新配件明细',
    component: () => import('./templates/ReturnTemplate.vue'),
    fields: [
      'woNo', 'originalWoNo', 'customerName', 'customerPhone',
      'engineerName', 'returnReason', 'newParts', 'totalFee'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: true,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: true,
    includeQRCode: false,
    copies: 1,
    permissions: ['admin', 'service-manager'],
    apiPath: '/api/v1/fsm/work-orders',
    preview: true,
    pdf: true,
  },

  // ═══════════════════════════════════════
  // 凭证类（4个）
  // ═══════════════════════════════════════
  'voucher': {
    label: '会计凭证',
    labelEn: 'Accounting Voucher',
    icon: '🧾',
    category: '凭证',
    description: '财务记账凭证，含借贷方科目、金额、附件张数',
    component: () => import('./templates/VoucherTemplate.vue'),
    fields: [
      'voucherNo', 'voucherDate', 'attachCount',
      'debitSubject', 'debitAmount', 'creditSubject', 'creditAmount',
      'maker', 'checker', 'poster'
    ],
    paperSizes: ['voucher-paper'],
    defaultPaper: 'voucher-paper',
    orientation: 'landscape',
    paperSizeCustom: { width: 241, height: 140, unit: 'mm' },
    repeatHeader: false,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: true,
    includeQRCode: false,
    copies: 1,
    permissions: ['admin', 'finance-manager', 'accountant'],
    apiPath: '/api/v1/finance/vouchers',
    preview: true,
    pdf: true,
  },

  'receipt': {
    label: '收款收据',
    labelEn: 'Receipt',
    icon: '💰',
    category: '凭证',
    description: '三联单收款收据，含金额大写、收款人、付款方',
    component: () => import('./templates/ReceiptTemplate.vue'),
    fields: [
      'receiptNo', 'receiptDate', 'payerName', 'amount',
      'amountCn', 'paymentMethod', 'receiptType',
      'collector', 'remark'
    ],
    paperSizes: ['receipt-paper'],
    defaultPaper: 'receipt-paper',
    orientation: 'portrait',
    paperSizeCustom: { width: 210, height: 297, unit: 'mm' },
    copies: 3,
    copiesConfig: {
      1: { label: '留存联', color: '#000' },
      2: { label: '客户联', color: '#c00' },
      3: { label: '财务联', color: '#00a' },
    },
    repeatHeader: false,
    repeatFooter: false,
    includeWatermark: true,
    includeBarcode: true,
    includeQRCode: true,
    permissions: ['admin', 'finance-manager', 'cashier'],
    apiPath: '/api/v1/finance/receipts',
    preview: true,
    pdf: true,
  },

  'payment-request': {
    label: '付款申请单',
    labelEn: 'Payment Request',
    icon: '💳',
    category: '凭证',
    description: '采购/费用付款申请，含金额大写、多级审批签字栏',
    component: () => import('./templates/PaymentRequestTemplate.vue'),
    fields: [
      'requestNo', 'requestDate', 'payee', 'amount',
      'amountCn', 'paymentReason', 'bankAccount',
      'approver1', 'approver2', 'approver3', 'approver4', 'approver5'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: false,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: false,
    includeQRCode: false,
    copies: 2,
    permissions: ['admin', 'finance-manager'],
    apiPath: '/api/v1/finance/payments',
    preview: true,
    pdf: true,
  },

  'deposit-receipt': {
    label: '订金收据',
    labelEn: 'Deposit Receipt',
    icon: '📝',
    category: '凭证',
    description: '工程/报价预付款订金收据，与正式收据区分标注',
    component: () => import('./templates/DepositTemplate.vue'),
    fields: [
      'receiptNo', 'receiptDate', 'payerName', 'projectName',
      'amount', 'amountCn', 'collector', 'remark'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: false,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: true,
    includeQRCode: true,
    copies: 2,
    permissions: ['admin', 'finance-manager'],
    apiPath: '/api/v1/finance/receipts',
    preview: true,
    pdf: true,
  },

  // ═══════════════════════════════════════
  // 销售类（4个）
  // ═══════════════════════════════════════
  'quote': {
    label: '报价单',
    labelEn: 'Quotation',
    icon: '📄',
    category: '销售',
    description: '商品报价单，含客户信息、商品明细、税率、总价、有效期',
    component: () => import('./templates/QuoteTemplate.vue'),
    fields: [
      'quoteNo', 'quoteDate', 'customerName', 'customerPhone',
      'items', 'subtotal', 'taxRate', 'taxAmount', 'total',
      'validUntil', 'salesPerson', 'remark'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: true,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: false,
    includeQRCode: true,
    copies: 2,
    permissions: ['admin', 'sales-manager', 'sales'],
    apiPath: '/api/v1/sales/quotes',
    preview: true,
    pdf: true,
  },

  'order': {
    label: '订货单',
    labelEn: 'Purchase Order',
    icon: '🛒',
    category: '销售',
    description: '客户确认订购，含商品、数量、交货期、客户签字栏',
    component: () => import('./templates/OrderTemplate.vue'),
    fields: [
      'orderNo', 'orderDate', 'customerName', 'customerPhone',
      'items', 'subtotal', 'deliveryDate', 'total',
      'customerSign', 'salesSign'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: true,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: true,
    includeQRCode: false,
    copies: 2,
    permissions: ['admin', 'sales-manager', 'sales'],
    apiPath: '/api/v1/sales/orders',
    preview: true,
    pdf: true,
  },

  'delivery': {
    label: '送货单',
    labelEn: 'Delivery Note',
    icon: '📦',
    category: '销售',
    description: '配送送货单，含客户信息、商品数量规格、三联单',
    component: () => import('./templates/DeliveryTemplate.vue'),
    fields: [
      'deliveryNo', 'deliveryDate', 'customerName', 'customerPhone', 'address',
      'items', 'totalQuantity', 'receiver', 'driverName', 'vehicleNo'
    ],
    paperSizes: ['A5'],
    defaultPaper: 'A5',
    orientation: 'landscape',
    repeatHeader: true,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: true,
    includeQRCode: false,
    copies: 3,
    copiesConfig: {
      1: { label: '发货联', color: '#000' },
      2: { label: '客户联', color: '#c00' },
      3: { label: '财务联', color: '#00a' },
    },
    permissions: ['admin', 'logistics-manager', 'driver'],
    apiPath: '/api/v1/logistics/delivery-orders',
    preview: true,
    pdf: true,
  },

  'delivery-sign': {
    label: '送货验收单',
    labelEn: 'Delivery Acceptance',
    icon: '✅',
    category: '销售',
    description: '客户签收确认，含送货单内容+验货照片栏+异常备注',
    component: () => import('./templates/DeliverySignTemplate.vue'),
    fields: [
      'deliveryNo', 'deliveryDate', 'customerName', 'items',
      'customerSign', 'checkResult', 'exceptionNote', 'photos'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: false,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: true,
    includeQRCode: true,
    copies: 1,
    permissions: ['admin', 'logistics-manager'],
    apiPath: '/api/v1/logistics/delivery-orders',
    preview: true,
    pdf: true,
  },

  // ═══════════════════════════════════════
  // 库存类（2个）
  // ═══════════════════════════════════════
  'stock': {
    label: '出入库单',
    labelEn: 'Stock In/Out',
    icon: '🏭',
    category: '库存',
    description: '仓库出入库单，含仓库、类型、商品、数量、操作人',
    component: () => import('./templates/StockTemplate.vue'),
    fields: [
      'stockNo', 'stockDate', 'warehouse', 'stockType',
      'items', 'totalQuantity', 'operator', 'remark'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: true,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: true,
    includeQRCode: false,
    copies: 2,
    permissions: ['admin', 'warehouse-manager', 'warehouse-staff'],
    apiPath: '/api/v1/wms/stock-records',
    preview: true,
    pdf: true,
  },

  'inventory': {
    label: '盘点表',
    labelEn: 'Inventory Count',
    icon: '📊',
    category: '库存',
    description: '仓库盘点表，含账面数量、实盘数量、差异、异常标红',
    component: () => import('./templates/InventoryTemplate.vue'),
    fields: [
      'inventoryNo', 'inventoryDate', 'warehouse', 'items',
      'totalItems', 'totalDiff', 'counter', 'checker'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: true,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: true,
    includeQRCode: false,
    copies: 2,
    permissions: ['admin', 'warehouse-manager'],
    apiPath: '/api/v1/wms/inventory-counts',
    preview: true,
    pdf: true,
  },

  // ═══════════════════════════════════════
  // 标签类（3个）
  // ═══════════════════════════════════════
  'part-label': {
    label: '配件标签',
    labelEn: 'Part Label',
    icon: '🏷️',
    category: '标签',
    description: '配件热敏标签，含条码、名称、规格、价格',
    component: () => import('./templates/PartLabelTemplate.vue'),
    fields: ['partNo', 'partName', 'spec', 'price', 'warehouse', 'barcode'],
    paperSizes: ['thermal-40x30'],
    defaultPaper: 'thermal-40x30',
    orientation: 'portrait',
    paperSizeCustom: { width: 40, height: 30, unit: 'mm' },
    repeatHeader: false,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: true,
    includeQRCode: false,
    copies: 1,
    batchPrint: true,   // 支持批量打印
    permissions: ['admin', 'warehouse-manager', 'warehouse-staff'],
    apiPath: '/api/v1/wms/parts',
    preview: true,
    pdf: true,
  },

  'asset-label': {
    label: '固定资产标签',
    labelEn: 'Asset Label',
    icon: '💻',
    category: '标签',
    description: '公司固定资产标签，含条码、资产名称、编号、购置日期',
    component: () => import('./templates/AssetLabelTemplate.vue'),
    fields: ['assetNo', 'assetName', 'purchaseDate', 'originalValue', 'barcode'],
    paperSizes: ['thermal-40x20'],
    defaultPaper: 'thermal-40x20',
    orientation: 'portrait',
    paperSizeCustom: { width: 40, height: 20, unit: 'mm' },
    repeatHeader: false,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: true,
    includeQRCode: false,
    copies: 1,
    batchPrint: true,
    permissions: ['admin', 'hr-admin'],
    apiPath: '/api/v1/hr/assets',
    preview: false,
    pdf: true,
  },

  'shelf-label': {
    label: '货架仓位标签',
    labelEn: 'Shelf Label',
    icon: '🗃️',
    category: '标签',
    description: '仓库货架仓位标签，含仓库、区、排、架、位、条码',
    component: () => import('./templates/ShelfLabelTemplate.vue'),
    fields: ['warehouse', 'zone', 'row', 'rack', 'position', 'barcode'],
    paperSizes: ['thermal-40x30'],
    defaultPaper: 'thermal-40x30',
    orientation: 'portrait',
    paperSizeCustom: { width: 40, height: 30, unit: 'mm' },
    repeatHeader: false,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: true,
    includeQRCode: false,
    copies: 1,
    batchPrint: true,
    permissions: ['admin', 'warehouse-manager'],
    apiPath: '/api/v1/wms/warehouses',
    preview: false,
    pdf: true,
  },

  // ═══════════════════════════════════════
  // 财务类（2个）
  // ═══════════════════════════════════════
  'salary': {
    label: '工资条',
    labelEn: 'Payroll Slip',
    icon: '💳',
    category: '财务',
    description: '员工工资条，含基本工资、奖金、扣款、实发金额',
    component: () => import('./templates/SalaryTemplate.vue'),
    fields: [
      'empNo', 'empName', 'department', 'baseSalary',
      'bonus', 'allowance', 'overtimeFee', 'deduction',
      'socialSecurity', 'housingFund', 'tax', 'netPay', 'payDate'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: false,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: false,
    includeQRCode: false,
    copies: 1,
    batchPrint: true,
    // 工资条不预览，直接批量生成PDF发微信
    preview: false,
    pdf: true,
    permissions: ['admin', 'hr-admin', 'finance-manager'],
    apiPath: '/api/v1/hr/salaries',
  },

  'attendance': {
    label: '考勤汇总表',
    labelEn: 'Attendance Summary',
    icon: '📅',
    category: '财务',
    description: '月度考勤汇总，按部门分组，异常行标黄',
    component: () => import('./templates/AttendanceTemplate.vue'),
    fields: [
      'department', 'empName', 'workDays', 'actualDays',
      'lateCount', 'earlyLeaveCount', 'absentDays',
      'overtimeHours', 'leaveDays', 'anomaly'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'landscape',
    repeatHeader: true,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: false,
    includeQRCode: false,
    copies: 1,
    permissions: ['admin', 'hr-admin'],
    apiPath: '/api/v1/hr/attendance',
    preview: true,
    pdf: true,
  },

  // ═══════════════════════════════════════
  // 合同/人事类（2个）
  // ═══════════════════════════════════════
  'project-contract': {
    label: '工程合同',
    labelEn: 'Project Contract',
    icon: '📜',
    category: '合同',
    description: '工程合同，含条款、分期付款、验收条件、双方签章',
    component: () => import('./templates/ProjectContractTemplate.vue'),
    fields: [
      'contractNo', 'contractDate', 'customerName', 'projectName',
      'projectAddress', 'contractAmount', 'paymentTerms',
      'deliveryTerms', 'acceptanceCriteria', 'partyASign', 'partyBSign'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: true,
    repeatFooter: true,
    includeWatermark: true,
    includeBarcode: true,
    includeQRCode: true,
    copies: 4,
    permissions: ['admin', 'sales-manager'],
    apiPath: '/api/v1/sales/project-orders',
    preview: true,
    pdf: true,
  },

  'customer-statement': {
    label: '客户对账单',
    labelEn: 'Customer Statement',
    icon: '📊',
    category: '合同',
    description: '客户对账周期内交易明细及余额',
    component: () => import('./templates/CustomerStatementTemplate.vue'),
    fields: [
      'customerName', 'statementNo', 'periodStart', 'periodEnd',
      'openingBalance', 'transactions', 'closingBalance', 'printDate'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: true,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: false,
    includeQRCode: true,
    copies: 2,
    permissions: ['admin', 'finance-manager', 'sales-manager'],
    apiPath: '/api/v1/crm/customers',
    preview: true,
    pdf: true,
  },

  'employee-reg': {
    label: '员工入职登记表',
    labelEn: 'Employee Registration',
    icon: '👤',
    category: '合同',
    description: '员工入职信息，含个人信息、学历、入职信息、照片栏',
    component: () => import('./templates/EmployeeRegTemplate.vue'),
    fields: [
      'empNo', 'empName', 'gender', 'birthDate', 'idCard',
      'nation', 'politicalStatus', 'education', 'graduationSchool',
      'phone', 'address', 'emergencyContact', 'joinDate',
      'department', 'position', 'contractStart', 'contractEnd', 'photo'
    ],
    paperSizes: ['A4'],
    defaultPaper: 'A4',
    orientation: 'portrait',
    repeatHeader: false,
    repeatFooter: false,
    includeWatermark: false,
    includeBarcode: false,
    includeQRCode: false,
    copies: 2,
    permissions: ['admin', 'hr-admin'],
    apiPath: '/api/v1/hr/employees',
    preview: true,
    pdf: true,
  },
}

// ═══════════════════════════════════════
// 辅助函数
// ═══════════════════════════════════════

/**
 * 获取所有模板列表（用于下拉选择）
 */
export function getTemplateList() {
  return Object.entries(printTemplates).map(([key, template]) => ({
    key,
    label: template.label,
    labelEn: template.labelEn,
    icon: template.icon,
    category: template.category,
    description: template.description,
    preview: template.preview,
    pdf: template.pdf,
    batchPrint: template.batchPrint || false,
  }))
}

/**
 * 获取某个模板配置
 */
export function getTemplate(key) {
  return printTemplates[key] || null
}

/**
 * 按分类获取模板
 */
export function getTemplatesByCategory(category) {
  return Object.entries(printTemplates)
    .filter(([, t]) => t.category === category)
    .map(([key, t]) => ({ key, ...t }))
}

/**
 * 获取所有分类
 */
export function getCategories() {
  const cats = new Set(Object.values(printTemplates).map(t => t.category))
  return Array.from(cats)
}

/**
 * 获取纸张尺寸配置
 */
export function getPaperSizeConfig(size) {
  const sizes = {
    'A4': { width: 210, height: 297, unit: 'mm' },
    'A5': { width: 148, height: 210, unit: 'mm' },
    'voucher-paper': { width: 241, height: 140, unit: 'mm' },
    'receipt-paper': { width: 210, height: 297, unit: 'mm' },
    'thermal-40x30': { width: 40, height: 30, unit: 'mm' },
    'thermal-40x20': { width: 40, height: 20, unit: 'mm' },
  }
  return sizes[size] || sizes['A4']
}

export default printTemplates
