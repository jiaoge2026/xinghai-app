/**
 * 数据格式化工具集
 * 所有页面统一使用这里的方法，不在各页面重复定义
 */

import { GENDER_MAP } from '@/constants/maps'

/**
 * 格式化金额
 * @param amount 金额
 * @param precision 小数位数，默认2
 * @param prefix 前缀，默认 '¥'
 */
export function formatCurrency(amount: number | string | null | undefined, precision = 2, prefix = '¥'): string {
  if (amount == null || amount === '') return '-'
  const num = typeof amount === 'string' ? parseFloat(amount) : amount
  if (isNaN(num)) return '-'
  return `${prefix}${num.toFixed(precision).replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`
}

/**
 * 格式化数字（千分位）
 * @param num 数字
 * @param precision 小数位数，默认0
 */
export function formatNumber(num: number | string | null | undefined, precision = 0): string {
  if (num == null || num === '') return '-'
  const n = typeof num === 'string' ? parseFloat(num) : num
  if (isNaN(n)) return '-'
  return n.toFixed(precision).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

/**
 * 格式化百分比
 * @param value 0-1之间的小数或0-100的整数
 * @param precision 小数位数，默认1
 * @param asPercent 是否乘以100，默认true
 */
export function formatPercent(value: number | string | null | undefined, precision = 1, asPercent = true): string {
  if (value == null || value === '') return '-'
  const v = typeof value === 'string' ? parseFloat(value) : value
  if (isNaN(v)) return '-'
  const pct = asPercent && v <= 1 ? v * 100 : v
  return `${pct.toFixed(precision)}%`
}

/**
 * 格式化日期（不含时间）
 */
export function formatDate(date: string | Date | number | null | undefined): string {
  if (!date) return '-'
  const d = parseDate(date)
  if (!d) return '-'
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

/**
 * 格式化日期时间
 * @param date 日期
 * @param format 输出格式，默认 'YYYY-MM-DD HH:mm:ss'
 */
export function formatDateTime(
  date: string | Date | number | null | undefined,
  format: string = 'YYYY-MM-DD HH:mm:ss'
): string {
  if (!date) return '-'
  const d = parseDate(date)
  if (!d) return '-'

  const year = d.getFullYear()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  const hour = String(d.getHours()).padStart(2, '0')
  const minute = String(d.getMinutes()).padStart(2, '0')
  const second = String(d.getSeconds()).padStart(2, '0')

  return format
    .replace('YYYY', String(year))
    .replace('MM', month)
    .replace('DD', day)
    .replace('HH', hour)
    .replace('mm', minute)
    .replace('ss', second)
}

/**
 * 格式化日期（中文友好）
 * 例如：今天 14:30、昨天 14:30、05-15 14:30、2025-05-15
 */
export function formatDateSmart(date: string | Date | number | null | undefined): string {
  if (!date) return '-'
  const d = parseDate(date)
  if (!d) return '-'

  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const yesterday = new Date(today.getTime() - 86400000)
  const targetDay = new Date(d.getFullYear(), d.getMonth(), d.getDate())

  const timeStr = `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`

  if (targetDay.getTime() === today.getTime()) {
    return `今天 ${timeStr}`
  }
  if (targetDay.getTime() === yesterday.getTime()) {
    return `昨天 ${timeStr}`
  }
  if (d.getFullYear() === now.getFullYear()) {
    return `${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')} ${timeStr}`
  }
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

/**
 * 相对时间
 * 例如：3分钟前、2小时前、3天前
 */
export function formatRelativeTime(date: string | Date | number | null | undefined): string {
  if (!date) return '-'
  const d = parseDate(date)
  if (!d) return '-'

  const now = Date.now()
  const diff = now - d.getTime()

  if (diff < 0) return '刚刚'
  if (diff < 60000) return '刚刚'
  if (diff < 3600000) return `${Math.floor(diff / 60000)}分钟前`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}小时前`
  if (diff < 604800000) return `${Math.floor(diff / 86400000)}天前`
  return formatDate(d)
}

/**
 * 格式化文件大小
 */
export function formatFileSize(bytes: number | string | null | undefined): string {
  if (bytes == null || bytes === '') return '-'
  const b = typeof bytes === 'string' ? parseFloat(bytes) : bytes
  if (isNaN(b)) return '-'
  if (b < 1024) return `${b} B`
  if (b < 1048576) return `${(b / 1024).toFixed(1)} KB`
  if (b < 1073741824) return `${(b / 1048576).toFixed(1)} MB`
  return `${(b / 1073741824).toFixed(1)} GB`
}

/**
 * 手机号脱敏
 */
export function formatPhone(phone: string | number | null | undefined): string {
  if (!phone) return '-'
  const p = String(phone)
  if (p.length === 11) {
    return p.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2')
  }
  return p
}

/**
 * 身份证号脱敏
 */
export function formatIdCard(idCard: string | number | null | undefined): string {
  if (!idCard) return '-'
  const id = String(idCard)
  if (id.length === 18) {
    return id.replace(/(\d{4})\d{10}(\d{4})/, '$1**********$2')
  }
  if (id.length === 15) {
    return id.replace(/(\d{4})\d{7}(\d{4})/, '$1*******$2')
  }
  return id
}

/**
 * 银行卡号脱敏
 */
export function formatBankCard(cardNo: string | number | null | undefined): string {
  if (!cardNo) return '-'
  const no = String(cardNo)
  if (no.length >= 8) {
    return no.replace(/(\d{4})\d+(\d{4})/, '$1 **** **** $2')
  }
  return no
}

/**
 * 性别格式化
 */
export function formatGender(gender: string | number | null | undefined): string {
  if (gender == null) return '-'
  return GENDER_MAP[gender] || GENDER_MAP[String(gender)] || String(gender)
}

/**
 * 解析任意格式日期为 Date 对象
 */
export function parseDate(date: string | Date | number): Date | null {
  if (!date) return null
  if (date instanceof Date) return isNaN(date.getTime()) ? null : date
  if (typeof date === 'number') {
    // 毫秒时间戳
    if (date > 1e12) return new Date(date)
    // 秒时间戳
    return new Date(date * 1000)
  }
  // ISO 字符串
  const d = new Date(date)
  return isNaN(d.getTime()) ? null : d
}

/**
 * 截断字符串，超长省略号
 */
export function truncate(str: string | null | undefined, maxLen = 20): string {
  if (!str) return '-'
  return str.length > maxLen ? str.slice(0, maxLen) + '…' : str
}

/**
 * 格式化金额大写（中文）
 */
export function formatAmountInWords(amount: number): string {
  if (amount === 0) return '零元整'
  const units = ['仟', '佰', '拾', '亿', '仟', '佰', '拾', '万', '仟', '佰', '拾', '元', '角', '分']
  const digits = ['零', '壹', '贰', '叁', '肆', '伍', '陆', '柒', '捌', '玖']

  if (amount < 0) return '负' + formatAmountInWords(-amount)

  const parts = amount.toFixed(2).split('.')
  const intPart = parseInt(parts[0])
  const decPart = parts[1]

  let result = ''
  const intStr = String(intPart)

  // 从低位到高位处理
  for (let i = 0; i < intStr.length; i++) {
    const digit = parseInt(intStr[intStr.length - 1 - i])
    const unit = units[units.length - intStr.length + i]
    if (digit !== 0) {
      result = digits[digit] + unit + result
    } else {
      result = (result.startsWith('零') ? '' : '零') + result
    }
  }

  // 去掉连续的零
  result = result.replace(/零+/g, '零').replace(/零元/g, '元')

  if (decPart) {
    const jiao = parseInt(decPart[0])
    const fen = parseInt(decPart[1])
    if (jiao > 0) result += digits[jiao] + '角'
    if (fen > 0) result += digits[fen] + '分'
  } else {
    result += '整'
  }

  return result.replace(/零+/g, '零').replace(/零整/g, '整')
}
