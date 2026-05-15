/**
 * 金额大写转换工具
 * 将数字金额转换为中文大写格式
 */

/**
 * 金额大写（精确到分）
 * @param {number|string} num - 金额数字
 * @returns {string} 中文大写金额
 */
export function toChineseAmount(num) {
  if (!num && num !== 0) return ''
  num = parseFloat(num)
  if (isNaN(num)) return ''
  if (num === 0) return '零元整'

  const units = ['分', '角', '元', '拾', '佰', '仟', '万', '拾', '佰', '仟', '亿', '拾', '佰', '仟']
  const digits = ['零', '壹', '贰', '叁', '肆', '伍', '陆', '柒', '捌', '玖']

  // 处理负数
  let negative = false
  if (num < 0) {
    negative = true
    num = Math.abs(num)
  }

  // 转换为字符串，保留两位小数
  num = num.toFixed(2)
  const parts = num.split('.')
  const intPart = parts[0]
  const decPart = parts[1]

  let result = ''

  // 处理整数部分（从右到左，每4位一组）
  const intLen = intPart.length
  for (let i = 0; i < intLen; i++) {
    const digit = parseInt(intPart[intLen - 1 - i])
    const unitIdx = intLen - i + 1 // +1 因为分角在前面

    if (digit !== 0) {
      result = digits[digit] + units[unitIdx] + result
    } else {
      // 零的处理：连续的零只保留一个
      const nextDigit = intLen - 1 - i >= 0 ? parseInt(intPart[intLen - 2 - i]) : -1
      const nextUnit = intLen - i
      // 如果是万、亿位，且下一位是0，不加"零"
      if (nextUnit === 7 || nextUnit === 11) {
        // 万、亿位
      } else if (i < intLen - 1 && nextDigit !== 0) {
        result = '零' + result
      }
    }
  }

  // 去除末尾的"元"
  result = result.replace(/元$/, '')

  // 处理角分
  const jiao = parseInt(decPart[0])
  const fen = parseInt(decPart[1])

  if (jiao === 0 && fen === 0) {
    result += '整'
  } else {
    if (jiao !== 0) {
      result += digits[jiao] + '角'
    } else {
      result += '零'
    }
    if (fen !== 0) {
      result += digits[fen] + '分'
    }
  }

  // 处理特殊：壹拾几
  result = result.replace(/零+/g, '零')
  result = result.replace(/零整$/, '整')
  result = result.replace(/^零+/, '')

  // 处理"亿萬"这种错误
  result = result.replace(/億萬/g, '亿')

  return negative ? '负' + result : result
}

/**
 * 数字转中文（不带金额单位）
 * @param {number} num - 数字 0-9
 * @returns {string} 中文数字
 */
export function toChineseNumber(num) {
  const digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九']
  if (num < 0 || num > 9) return num.toString()
  return digits[num]
}

/**
 * 数字转中文（带十百千万亿）
 * @param {number} num - 数字
 * @returns {string} 中文数字
 */
export function toChineseInteger(num) {
  if (num === 0) return '零'
  if (num < 0) return '负' + toChineseInteger(-num)

  const units = ['', '十', '百', '千', '万', '十', '百', '千', '亿']
  const digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九']

  let result = ''
  let unitIndex = 0

  while (num > 0) {
    const digit = num % 10
    if (digit !== 0) {
      if (unitIndex === 0) {
        result = digits[digit] + result
      } else {
        result = digits[digit] + units[unitIndex] + result
      }
    } else {
      // 连续的零只保留一个
      if (result && !result.startsWith('零') && !result.startsWith('十') && !result.startsWith('百') && !result.startsWith('千')) {
        result = '零' + result
      }
    }
    num = Math.floor(num / 10)
    unitIndex++
  }

  // 去除末尾的零
  result = result.replace(/零+$/, '')

  // 一十 -> 十（一十这种形式一般说"十"）
  result = result.replace(/^一十/, '十')

  return result
}

/**
 * 格式化金额（千分位分隔）
 * @param {number|string} amount - 金额
 * @param {number} decimals - 小数位数
 * @returns {string} 格式化后的金额
 */
export function formatMoney(amount, decimals = 2) {
  if (!amount && amount !== 0) return ''
  amount = parseFloat(amount)
  if (isNaN(amount)) return ''

  return amount.toFixed(decimals).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

/**
 * 格式化百分比
 * @param {number} value - 数值 0-1
 * @returns {string} 百分比字符串
 */
export function formatPercent(value) {
  if (value === null || value === undefined) return ''
  return (value * 100).toFixed(2) + '%'
}
