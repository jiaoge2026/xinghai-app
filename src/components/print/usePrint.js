/**
 * 星海ERP 打印核心 Hook
 * 
 * 提供：
 *   print()        — 调用浏览器原生打印
 *   exportPdf()    — 生成PDF下载
 *   preview()      — 预览打印内容
 *   getPrintHtml() — 生成打印专用HTML
 * 
 * 使用方式：
 *   import { usePrint } from '@/components/print/usePrint'
 *   const { print, exportPdf } = usePrint()
 */
import { ElMessage } from 'element-plus'
import { getPaperSizeConfig } from './registry'

// 动态导入（减少首屏体积）
let html2canvas, jsPDF
async function loadDeps() {
  if (!html2canvas) {
    html2canvas = (await import('html2canvas')).default
  }
  if (!jsPDF) {
    const mod = await import('jspdf')
    jsPDF = mod.jsPDF
  }
}

/**
 * 格式化金额为千分位
 * @param {number} amount
 * @returns {string} 如：¥3,747.00
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

  // 整数部分
  const intPart = Math.floor(amount)
  // 小数部分（保留2位）
  const decPart = Math.round((amount - intPart) * 100)

  let intStr = ''
  let intStrReversed = intPart.toString().split('').reverse()
  
  for (let i = 0; i < intStrReversed.length; i++) {
    const digit = parseInt(intStrReversed[i])
    const unit = units[i + 2] // 从"元"开始（index 2）
    
    if (digit === 0) {
      // 连续的0只保留一个
      if (!intStr.endsWith('零') && intStr.length > 0) {
        intStr += '零'
      }
    } else {
      intStr += digits[digit] + unit
    }
  }

  // 去除末尾的零并补"整"
  intStr = intStr.replace(/零+$/g, '') || '零'
  if (intStr === '零') intStr = ''

  // 处理角分
  let decStr = ''
  if (decPart > 0) {
    const jiao = Math.floor(decPart / 10)
    const fen = decPart % 10
    if (jiao > 0) {
      decStr += digits[jiao] + '角'
    }
    if (fen > 0) {
      decStr += digits[fen] + '分'
    }
  } else {
    decStr = '整'
  }

  return intStr + decStr
}

/**
 * 金额转中文数字（不含角分）
 * @param {number} num
 * @returns {string}
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
      if (!result.endsWith('零') && result.length > 0) {
        result += '零'
      }
    } else {
      result += digits[digit] + unit
    }
  }
  
  result = result.replace(/零+$/g, '')
  // 十十几的处理
  if (result.startsWith('一十')) {
    result = result.replace('一十', '十')
  }
  
  return result || '零'
}

export function usePrint() {
  /**
   * 生成打印专用HTML
   * @param {string} content HTML内容
   * @param {object} options 配置
   * @returns {string} 完整的HTML字符串
   */
  function getPrintHtml(content, options = {}) {
    const {
      title = '星海ERP',
      paperSize = 'A4',
      orientation = 'portrait',
      style = '',
    } = options

    const paper = getPaperSizeConfig(paperSize)

    return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <style>
    /* 打印CSS */
    ${getGlobalPrintStyle(paper, orientation)}
    ${style}
  </style>
</head>
<body>
  ${content}
</body>
</html>`
  }

  /**
   * 调用浏览器打印
   * @param {string|HTMLElement} content HTML字符串或DOM元素
   * @param {object} options 配置
   */
  async function print(content, options = {}) {
    const {
      title = '星海ERP',
      paperSize = 'A4',
      orientation = 'portrait',
    } = options

    try {
      let html
      if (typeof content === 'string') {
        html = getPrintHtml(content, { title, paperSize, orientation })
      } else {
        // DOM元素：克隆并注入样式
        html = getPrintHtml(content.innerHTML, { title, paperSize, orientation })
      }

      const printWindow = window.open('', '_blank', 'width=900,height=700,scrollbars=yes')
      if (!printWindow) {
        ElMessage.error('弹出窗口被拦截，请允许弹窗后重试')
        return
      }

      printWindow.document.write(html)
      printWindow.document.close()
      printWindow.focus()

      // 等待资源加载完成后打印
      printWindow.onload = () => {
        setTimeout(() => {
          printWindow.print()
          printWindow.close()
        }, 300)
      }

      // 如果 onload 没触发（本地文件），直接打印
      setTimeout(() => {
        if (!printWindow.closed && printWindow.document.readyState === 'complete') {
          printWindow.print()
          printWindow.close()
        }
      }, 1000)

    } catch (error) {
      console.error('打印失败:', error)
      ElMessage.error('打印失败：' + error.message)
    }
  }

  /**
   * 导出PDF
   * @param {HTMLElement} element DOM元素
   * @param {string} filename 文件名（不含扩展名）
   * @param {object} options 配置
   */
  async function exportPdf(element, filename = 'export', options = {}) {
    const {
      paperSize = 'A4',
      orientation = 'portrait',
      scale = 2, // 清晰度，2=200%
      format = 'png', // png 或 jpeg
    } = options

    try {
      ElMessage.info('正在生成PDF，请稍候...')
      await loadDeps()

      const canvas = await html2canvas(element, {
        scale,
        useCORS: true,
        allowTaint: true,
        logging: false,
        backgroundColor: '#ffffff',
        // A4 尺寸（像素，假设96dpi）
        width: element.offsetWidth,
        height: element.offsetHeight,
      })

      const imgData = canvas.toDataURL(`image/${format}`, 1.0)

      const paper = getPaperSizeConfig(paperSize)
      // 转换为 mm 单位的尺寸
      const pdfWidth = orientation === 'landscape' ? paper.height : paper.width
      const pdfHeight = orientation === 'landscape' ? paper.width : paper.height

      const pdf = new jsPDF({
        orientation: orientation,
        unit: 'mm',
        format: [pdfWidth, pdfHeight],
      })

      const imgWidth = canvas.width
      const imgHeight = canvas.height

      // 按宽度等比缩放
      const ratio = pdfWidth / (imgWidth /96 * 25.4) // 96dpi转mm
      const scaledHeight = (imgHeight /96 * 25.4) * ratio

      pdf.addImage(imgData, format.toUpperCase(), 0, 0, pdfWidth, Math.max(pdfHeight, scaledHeight))
      pdf.save(`${filename}.pdf`)

      ElMessage.success('PDF导出成功')

      // 记录打印日志
      await logPrint({ filename, type: 'pdf', element: element.tagName })

    } catch (error) {
      console.error('PDF导出失败:', error)
      ElMessage.error('PDF导出失败：' + error.message)
    }
  }

  /**
   * 预览打印内容（在新窗口中显示）
   */
  async function previewInWindow(element, options = {}) {
    const {
      title = '打印预览',
      paperSize = 'A4',
      orientation = 'portrait',
    } = options

    const html = getPrintHtml(element.innerHTML, {
      title,
      paperSize,
      orientation,
    })

    const previewWindow = window.open('', '_blank', 'width=900,height=700,scrollbars=yes')
    if (!previewWindow) {
      ElMessage.error('弹出窗口被拦截，请允许弹窗后重试')
      return
    }

    previewWindow.document.write(html)
    previewWindow.document.close()
    previewWindow.focus()
    previewWindow.document.title = title
  }

  /**
   * 记录打印日志到后端
   */
  async function logPrint(params) {
    try {
      const token = localStorage.getItem('token')
      await fetch('/api/v1/print/logs', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          ...params,
          printedAt: new Date().toISOString(),
        }),
      })
    } catch (e) {
      // 打印日志失败不影响主流程
      console.warn('记录打印日志失败:', e)
    }
  }

  /**
   * 获取全局打印样式（注入到iframe）
   */
  function getGlobalPrintStyle(paper, orientation) {
    return `
      * { box-sizing: border-box; margin: 0; padding: 0; }
      body {
        font-family: 'Microsoft YaHei', '宋体', 'SimSun', serif;
        font-size: 12px;
        color: #000;
        background: #fff;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
      }
      @page {
        size: ${paper.width}mm ${paper.height}mm;
        margin: 12mm;
      }
      .no-print, .screen-only, .el-button, .toolbar, .pagination {
        display: none !important;
      }
      .print-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 11px;
      }
      .print-table th, .print-table td {
        border: 1px solid #333;
        padding: 5px 8px;
        text-align: center;
      }
      .print-table th {
        background: #f0f0f0 !important;
        font-weight: bold;
      }
      .print-table thead { display: table-header-group; }
      .print-table tr { page-break-inside: avoid; }
    `
  }

  return {
    print,
    exportPdf,
    previewInWindow,
    formatMoney,
    toChineseAmount,
    toChineseNumber,
    logPrint,
  }
}

export default usePrint
