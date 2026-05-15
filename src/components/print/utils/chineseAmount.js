/**
 * 金额转中文大写
 * @param {number|string} num
 * @returns {string} 如：叁仟柒佰肆拾柒元整
 */
export function toChineseAmount(num) {
  if (num === null || num === undefined || num === '') return '-'
  const amount = parseFloat(num)
  if (isNaN(amount)) return '-'
  if (amount === 0) return '零元整'

  const digits = ['零', '壹', '贰', '叁', '肆', '伍', '陆', '柒', '捌', '玖']
  const units = ['分', '角', '元', '拾', '佰', '仟', '万', '拾', '佰', '仟', '亿']

  const intPart = Math.floor(amount)
  const decPart = Math.round((amount - intPart) * 100)

  let intStr = ''
  const reversed = intPart.toString().split('').reverse()
  
  for (let i = 0; i < reversed.length; i++) {
    const digit = parseInt(reversed[i])
    const unit = units[i + 2]
    if (digit === 0) {
      if (!intStr.endsWith('零') && intStr.length > 0) intStr += '零'
    } else {
      intStr += digits[digit] + unit
    }
  }

  intStr = intStr.replace(/零+$/g, '') || '零'
  if (intStr === '零') intStr = ''

  let decStr = ''
  if (decPart > 0) {
    const jiao = Math.floor(decPart / 10)
    const fen = decPart % 10
    if (jiao > 0) decStr += digits[jiao] + '角'
    if (fen > 0) decStr += digits[fen] + '分'
  } else {
    decStr = '整'
  }

  return intStr + decStr
}

/**
 * 金额格式化（千分位）
 */
export function formatMoney(amount, prefix = '¥') {
  if (amount === null || amount === undefined || amount === '') return '-'
  const num = parseFloat(amount)
  if (isNaN(num)) return '-'
  return `${prefix}${num.toLocaleString('zh-CN', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}`
}

/**
 * 中文数字（不含角分）
 */
export function toChineseNumber(num) {
  if (!num && num !== 0) return '-'
  const digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九']
  const units = ['', '十', '百', '千']
  const intPart = Math.floor(num)
  let result = ''
  const str = intPart.toString()
  for (let i = 0; i < str.length; i++) {
    const digit = parseInt(str[i])
    const unit = units[str.length - i - 1]
    if (digit === 0) {
      if (!result.endsWith('零') && result.length > 0) result += '零'
    } else {
      result += digits[digit] + unit
    }
  }
  result = result.replace(/零+$/g, '')
  if (result.startsWith('一十')) result = result.replace('一十', '十')
  return result || '零'
}

export default { toChineseAmount, formatMoney, toChineseNumber }
