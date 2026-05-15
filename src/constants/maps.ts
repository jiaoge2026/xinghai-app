/**
 * 业务状态映射表 - 统一管理所有状态类型和颜色
 * 使用方式：import { WORK_ORDER_STATUS, FINANCE_STATUS } from '@/constants/maps'
 */

// ============================================================
// 工单状态
// ============================================================
export const WORK_ORDER_STATUS: Record<string, { label: string; type: 'success' | 'warning' | 'danger' | 'info' | 'primary' }> = {
  // 海尔工单状态（从爱服务同步过来的原始码）
  '100000010': { label: '已到岗', type: 'info' },
  '100000015': { label: '已到兵', type: 'primary' },
  '100000055': { label: '服务商已结单', type: 'success' },
  '100000060': { label: '海尔已结单', type: 'success' },
  '100000065': { label: '已作废', type: 'danger' },
  '100000090': { label: '已取消', type: 'info' },

  // 本地工单状态（tb_work_order.hsicrm_workorderstatusname）
  '待派单': { label: '待派单', type: 'warning' },
  '已派单': { label: '已派单', type: 'primary' },
  '进行中': { label: '进行中', type: 'primary' },
  '待结算': { label: '待结算', type: 'warning' },
  '已完成': { label: '已完成', type: 'success' },
  '已取消': { label: '已取消', type: 'info' },
}

export const WORK_ORDER_TYPE: Record<string, { label: string; type: string }> = {
  '安装': { label: '安装', type: 'primary' },
  '维修': { label: '维修', type: 'warning' },
  '清洗': { label: '清洗', type: 'info' },
  '保养': { label: '保养', type: 'success' },
  '带货安装': { label: '带货安装', type: 'danger' },
  '移机': { label: '移机', type: 'info' },
}

// ============================================================
// 审批状态
// ============================================================
export const APPROVAL_STATUS: Record<string, { label: string; type: 'success' | 'warning' | 'danger' | 'info' | 'primary' }> = {
  DRAFT: { label: '草稿', type: 'info' },
  PENDING: { label: '审批中', type: 'warning' },
  APPROVED: { label: '已通过', type: 'success' },
  REJECTED: { label: '已拒绝', type: 'danger' },
  CANCELLED: { label: '已撤回', type: 'info' },
  TRANSFERRED: { label: '已转交', type: 'primary' },
}

// ============================================================
// 财务状态
// ============================================================
export const FINANCE_STATUS: Record<string, { label: string; type: 'success' | 'warning' | 'danger' | 'info' | 'primary' }> = {
  UNPAID: { label: '未付款', type: 'warning' },
  PAID: { label: '已付款', type: 'success' },
  PARTIAL: { label: '部分付款', type: 'primary' },
  OVERDUE: { label: '已逾期', type: 'danger' },
  CANCELLED: { label: '已取消', type: 'info' },
}

export const VOUCHER_STATUS: Record<string, { label: string; type: 'success' | 'warning' | 'danger' | 'info' | 'primary' }> = {
  DRAFT: { label: '未审核', type: 'info' },
  AUDITED: { label: '已审核', type: 'success' },
  POSTED: { label: '已过账', type: 'primary' },
  REVERSED: { label: '已冲销', type: 'danger' },
}

// ============================================================
// 库存状态
// ============================================================
export const STOCK_IN_STATUS: Record<string, { label: string; type: 'success' | 'warning' | 'danger' | 'info' | 'primary' }> = {
  PENDING: { label: '待入库', type: 'warning' },
  IN_STOCK: { label: '已入库', type: 'success' },
  RETURNED: { label: '已退货', type: 'info' },
}

export const STOCK_OUT_STATUS: Record<string, { label: string; type: 'success' | 'warning' | 'danger' | 'info' | 'primary' }> = {
  PENDING: { label: '待出库', type: 'warning' },
  OUT: { label: '已出库', type: 'success' },
  RETURNED: { label: '已退货', type: 'info' },
}

// ============================================================
// 工程师状态
// ============================================================
export const ENGINEER_STATUS: Record<string, { label: string; type: 'success' | 'warning' | 'danger' | 'info' | 'primary' }> = {
  ONLINE: { label: '空闲', type: 'success' },
  SERVING: { label: '服务中', type: 'warning' },
  OFFLINE: { label: '离线', type: 'info' },
  BREAK: { label: '休息中', type: 'primary' },
}

// ============================================================
// 客户类型
// ============================================================
export const CUSTOMER_TYPE: Record<string, { label: string; type: 'success' | 'warning' | 'danger' | 'info' | 'primary' }> = {
  HOME: { label: '个人', type: 'primary' },
  BUSINESS: { label: '企业', type: 'success' },
  GOVERNMENT: { label: '政府', type: 'warning' },
}

// ============================================================
// 性别
// ============================================================
export const GENDER_MAP: Record<string | number, string> = {
  1: '男',
  2: '女',
  0: '未知',
  'male': '男',
  'female': '女',
  'unknown': '未知',
}

// ============================================================
// 工单来源
// ============================================================
export const ORDER_SOURCE: Record<string, string> = {
  'APP': 'APP报修',
  'PHONE': '电话报修',
  'ONLINE': '在线下单',
  'WECHAT': '微信报修',
  'REFERRAL': '转介绍',
  'OTHER': '其他',
}

// ============================================================
// 产品类别
// ============================================================
export const PRODUCT_CATEGORY: Record<string, string> = {
  '空调': '空调',
  '冰箱': '冰箱',
  '洗衣机': '洗衣机',
  '热水器': '热水器',
  '油烟机': '油烟机',
  '燃气灶': '燃气灶',
  '净水器': '净水器',
  '洗碗机': '洗碗机',
  '干衣机': '干衣机',
  '消毒柜': '消毒柜',
}

// ============================================================
// 通用获取类型函数
// ============================================================
export function getStatusType(
  status: string | number | undefined,
  map: Record<string, any>
): 'success' | 'warning' | 'danger' | 'info' | 'primary' {
  if (!status) return 'info'
  const found = map[String(status)] || map[status]
  return found?.type || 'info'
}

export function getStatusLabel(
  status: string | number | undefined,
  map: Record<string, any>
): string {
  if (!status) return String(status ?? '-')
  const found = map[String(status)] || map[status]
  return found?.label || String(status)
}

// ============================================================
// QA 反馈状态
// ============================================================
export const QA_FEEDBACK_STATUS: Record<string | number, { label: string; type: 'success' | 'warning' | 'danger' | 'info' | 'primary' }> = {
  1: { label: '待处理', type: 'warning' },
  2: { label: '处理中', type: 'primary' },
  3: { label: '已解决', type: 'success' },
}

export const QA_FEEDBACK_TYPE: Record<string | number, { label: string; type: 'success' | 'warning' | 'danger' | 'info' | 'primary' }> = {
  1: { label: '投诉', type: 'danger' },
  2: { label: '表扬', type: 'success' },
  3: { label: '建议', type: 'info' },
}
