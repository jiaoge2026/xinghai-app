<template>
  <div 
    class="print-layout"
    :class="[`paper-${paperSize}`, orientation]"
    :data-template="templateKey"
  >
    <!-- 水印 -->
    <div class="print-watermark" v-if="includeWatermark">
      <div class="watermark-text">{{ companyName }}</div>
    </div>

    <!-- 打印头部 -->
    <slot name="header">
      <div class="print-header">
        <div class="company-name">{{ companyName }}</div>
        <div class="document-title">{{ documentTitle }}</div>
        <div class="doc-meta" v-if="showMeta">
          <span v-if="docNo">单据编号：{{ docNo }}</span>
          <span v-if="docDate">日期：{{ docDate }}</span>
          <span v-if="operator">操作人：{{ operator }}</span>
          <span v-if="totalCount">共 {{ totalCount }} 条</span>
        </div>
      </div>
    </slot>

    <!-- 主表信息区 -->
    <slot name="main-info">
      <div class="print-main-info" v-if="$slots['main-info']">
        <slot name="main-info" />
      </div>
    </slot>

    <!-- 明细表格区 -->
    <slot name="table">
      <div class="print-table-wrapper">
        <slot name="table" />
      </div>
    </slot>

    <!-- 汇总区 -->
    <slot name="summary">
      <div class="print-summary" v-if="$slots.summary">
        <slot name="summary" />
      </div>
    </slot>

    <!-- 签名区 -->
    <slot name="signature">
      <div class="print-signature" v-if="includeSignature && $slots.signature">
        <slot name="signature" />
      </div>
      <div class="print-signature" v-else-if="includeSignature && !$slots.signature">
        <SignatureDefault :fields="signatureFields" />
      </div>
    </slot>

    <!-- 条码/二维码 -->
    <div class="print-codes" v-if="includeBarcode || includeQRCode">
      <PrintBarcode v-if="includeBarcode && barcodeValue" :value="barcodeValue" :format="barcodeFormat" />
      <PrintQRCode v-if="includeQRCode && qrcodeValue" :value="qrcodeValue" :size="qrcodeSize" />
    </div>

    <!-- 页脚 -->
    <slot name="footer">
      <div class="print-footer" v-if="showFooter">
        <span class="page-info">第 {{ currentPage }} 页 / 共 {{ totalPages }} 页</span>
        <span class="company-info">{{ companyName }} · 验真伪：400-xxx-xxxx</span>
      </div>
    </slot>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import PrintBarcode from './fields/PrintBarcode.vue'
import PrintQRCode from './fields/PrintQRCode.vue'
import SignatureDefault from './fields/PrintSignature.vue'

const props = defineProps({
  // 模板key
  templateKey: {
    type: String,
    default: '',
  },
  // 公司名称
  companyName: {
    type: String,
    default: '山东万欣和经贸有限公司',
  },
  // 单据标题
  documentTitle: {
    type: String,
    required: true,
  },
  // 单据编号
  docNo: {
    type: String,
    default: '',
  },
  // 单据日期
  docDate: {
    type: String,
    default: '',
  },
  // 操作人
  operator: {
    type: String,
    default: '',
  },
  // 总条数
  totalCount: {
    type: [Number, String],
    default: 0,
  },
  // 纸张尺寸
  paperSize: {
    type: String,
    default: 'A4',
  },
  // 方向
  orientation: {
    type: String,
    default: 'portrait',
  },
  // 是否显示元信息
  showMeta: {
    type: Boolean,
    default: true,
  },
  // 是否显示页脚
  showFooter: {
    type: Boolean,
    default: true,
  },
  // 是否包含签名区
  includeSignature: {
    type: Boolean,
    default: true,
  },
  // 签名区字段
  signatureFields: {
    type: Array,
    default: () => ['制单人', '审核人', '客户签字'],
  },
  // 是否包含水印
  includeWatermark: {
    type: Boolean,
    default: false,
  },
  // 是否包含条码
  includeBarcode: {
    type: Boolean,
    default: false,
  },
  // 条码值
  barcodeValue: {
    type: String,
    default: '',
  },
  // 条码格式
  barcodeFormat: {
    type: String,
    default: 'CODE128',
  },
  // 是否包含二维码
  includeQRCode: {
    type: Boolean,
    default: false,
  },
  // 二维码值
  qrcodeValue: {
    type: String,
    default: '',
  },
  // 二维码尺寸
  qrcodeSize: {
    type: Number,
    default: 60,
  },
  // 当前页
  currentPage: {
    type: Number,
    default: 1,
  },
  // 总页数
  totalPages: {
    type: Number,
    default: 1,
  },
})
</script>

<style scoped>
.print-layout {
  width: 100%;
  min-height: 100%;
  position: relative;
  font-family: 'Microsoft YaHei', '宋体', 'SimSun', serif;
  font-size: 12px;
  color: #000;
  background: #fff;
}

.print-watermark {
  position: fixed;
  top: 0; left: 0;
  width: 100%; height: 100%;
  pointer-events: none;
  z-index: 999;
  overflow: hidden;
}

.print-watermark .watermark-text {
  position: absolute;
  top: 50%; left: 50%;
  transform: translate(-50%, -50%) rotate(-45deg);
  font-size: 48px;
  font-weight: bold;
  color: rgba(0,0,0,0.03);
  white-space: nowrap;
  letter-spacing: 8px;
}

.print-header {
  text-align: center;
  margin-bottom: 20px;
  padding-bottom: 12px;
  border-bottom: 2px solid #333;
}

.print-header .company-name {
  font-size: 18px;
  font-weight: bold;
  color: #000;
  letter-spacing: 2px;
}

.print-header .document-title {
  font-size: 20px;
  font-weight: bold;
  color: #000;
  letter-spacing: 4px;
  margin: 8px 0;
}

.print-header .doc-meta {
  display: flex;
  justify-content: center;
  gap: 24px;
  font-size: 11px;
  color: #555;
  margin-top: 6px;
}

.print-main-info {
  margin: 12px 0;
}

.print-table-wrapper {
  margin: 12px 0;
}

.print-summary {
  margin: 16px 0;
  padding: 12px 0;
  border-top: 2px solid #333;
  border-bottom: 1px solid #333;
}

.print-signature {
  margin: 24px 0 16px;
}

.print-codes {
  display: flex;
  justify-content: center;
  gap: 32px;
  margin: 16px 0;
}

.print-footer {
  position: fixed;
  bottom: 8mm;
  left: 0; right: 0;
  display: flex;
  justify-content: space-between;
  font-size: 10px;
  color: #888;
  border-top: 1px solid #ddd;
  padding-top: 4px;
}

/* 横向模式 */
.print-layout.landscape {
  /* 横向布局特殊处理 */
}
</style>
