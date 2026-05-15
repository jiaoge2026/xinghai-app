/**
 * 数据验证工具集
 */

/**
 * 验证手机号（中国大陆）
 */
export function isPhone(value: string | number): boolean {
  if (!value) return false
  return /^1[3-9]\d{9}$/.test(String(value))
}

/**
 * 验证固定电话
 */
export function isTel(value: string | number): boolean {
  if (!value) return false
  return /^0\d{2,3}-?\d{7,8}$/.test(String(value))
}

/**
 * 验证手机或电话
 */
export function isPhoneOrTel(value: string | number): boolean {
  return isPhone(value) || isTel(value)
}

/**
 * 验证身份证号（中国大陆）
 */
export function isIdCard(value: string | number): boolean {
  if (!value) return false
  const id = String(value)
  // 15位
  if (/^\d{15}$/.test(id)) return true
  // 18位
  if (!/^\d{17}[\dXx]$/.test(id)) return false
  const weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
  const checkCodes = ['1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2']
  let sum = 0
  for (let i = 0; i < 17; i++) {
    sum += parseInt(id[i]) * weights[i]
  }
  const checkCode = checkCodes[sum % 11]
  return checkCode === id[17].toUpperCase()
}

/**
 * 验证邮箱
 */
export function isEmail(value: string): boolean {
  if (!value) return false
  return /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(value)
}

/**
 * 验证银行卡号（luhn算法）
 */
export function isBankCard(value: string | number): boolean {
  if (!value) return false
  const no = String(value).replace(/\s/g, '')
  if (!/^\d{16,19}$/.test(no)) return false

  let sum = 0
  let isEven = false
  for (let i = no.length - 1; i >= 0; i--) {
    let digit = parseInt(no[i])
    if (isEven) {
      digit *= 2
      if (digit > 9) digit -= 9
    }
    sum += digit
    isEven = !isEven
  }
  return sum % 10 === 0
}

/**
 * 验证URL
 */
export function isURL(value: string): boolean {
  if (!value) return false
  try {
    new URL(value)
    return true
  } catch {
    return false
  }
}

/**
 * 验证金额
 */
export function validateAmount(
  value: number | string,
  min = 0,
  max?: number
): { valid: boolean; message: string } {
  const num = typeof value === 'string' ? parseFloat(value) : value
  if (isNaN(num)) return { valid: false, message: '请输入有效金额' }
  if (num < min) return { valid: false, message: `金额不能小于${min}` }
  if (max !== undefined && num > max) return { valid: false, message: `金额不能超过${max}` }
  return { valid: true, message: '' }
}

/**
 * 验证必填
 */
export function isRequired(value: any): boolean {
  if (value == null || value === '') return false
  if (typeof value === 'string') return value.trim().length > 0
  return true
}

/**
 * 验证车牌号
 */
export function isCarPlate(value: string): boolean {
  if (!value) return false
  return /^[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领][A-Z][A-HJ-NP-Z0-9]{4,5}[A-HJ-NP-Z0-9挂学警港澳]$/.test(value)
}

/**
 * 验证统一社会信用代码
 */
export function isCreditCode(value: string): boolean {
  if (!value) return false
  return /^[0-9A-HJ-NPQRTUWXY]{2}\d{6}[0-9A-HJ-NPQRTUWXY]{10}$/.test(value)
}

/**
 * 生成 Element Plus 表单验证规则（常用验证）
 */
export const formRules = {
  required: (message = '此项为必填项') => ({ required: true, message, trigger: ['blur', 'change'] }),
  phone: (message = '手机号格式错误') => ({
    pattern: /^1[3-9]\d{9}$/,
    message,
    trigger: ['blur', 'change'],
  }),
  email: (message = '邮箱格式错误') => ({
    type: 'email',
    message,
    trigger: ['blur', 'change'],
  }),
  idCard: (message = '身份证号格式错误') => ({
    pattern: /(^\d{15}$)|(^\d{17}[\dXx]$)/,
    message,
    trigger: ['blur', 'change'],
  }),
  amount: (min = 0, max?: number, message?: string) => ({
    validator: (_rule: any, _val: any, callback: (err?: Error) => void) => {
      const result = validateAmount(_val, min, max)
      callback(result.valid ? undefined : new Error(result.message || message))
    },
    trigger: ['blur', 'change'],
  }),
  url: (message = 'URL格式错误') => ({
    pattern: /^https?:\/\/.+/,
    message,
    trigger: ['blur', 'change'],
  }),
  range: (min: number, max: number, label = '值') => ({
    validator: (_rule: any, _val: any, callback: (err?: Error) => void) => {
      const num = Number(_val)
      if (isNaN(num) || num < min || num > max) {
        callback(new Error(`${label}必须在${min}到${max}之间`))
      } else {
        callback()
      }
    },
    trigger: ['blur', 'change'],
  }),
}
