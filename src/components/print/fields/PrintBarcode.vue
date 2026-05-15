<template>
  <div class="print-barcode" ref="barcodeRef">
    <svg :id="barcodeId" />
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'

const props = defineProps({
  value: { type: String, required: true },
  format: { type: String, default: 'CODE128' },
  width: { type: Number, default: 2 },
  height: { type: Number, default: 60 },
  displayValue: { type: Boolean, default: true },
})

const barcodeRef = ref(null)
const barcodeId = ref('barcode-' + Math.random().toString(36).substr(2, 9))

async function renderBarcode() {
  if (!props.value || !barcodeRef.value) return
  try {
    const JsBarcode = (await import('jsbarcode')).default
    const svg = document.getElementById(barcodeId.value)
    if (!svg) return
    JsBarcode(svg, props.value, {
      format: props.format,
      width: props.width,
      height: props.height,
      displayValue: props.displayValue,
      font: 'Microsoft YaHei',
      fontSize: 12,
      textMargin: 4,
      margin: 4,
      background: '#ffffff',
      lineColor: '#000000',
    })
  } catch (e) {
    if (barcodeRef.value) {
      barcodeRef.value.innerHTML = '<div style="font-family:monospace;font-size:12px;padding:4px;border:1px solid #333;text-align:center">' + props.value + '</div>'
    }
  }
}

onMounted(() => renderBarcode())
watch(() => props.value, () => renderBarcode())
</script>

<style scoped>
.print-barcode { text-align: center; display: inline-block; }
.print-barcode svg { max-width: 100%; }
</style>
