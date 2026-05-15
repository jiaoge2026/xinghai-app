<template>
  <div class="print-qrcode">
    <canvas :id="qrcodeId" ref="qrRef" />
    <div class="qr-label" v-if="showLabel">扫码验真</div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'

const props = defineProps({
  value: { type: String, required: true },
  size: { type: Number, default: 60 },
  showLabel: { type: Boolean, default: true },
  level: { type: String, default: 'M' },
})

const qrRef = ref(null)
const qrcodeId = ref('qrcode-' + Math.random().toString(36).substr(2, 9))

async function renderQR() {
  if (!props.value || !qrRef.value) return
  try {
    const QRCode = (await import('qrcode')).default
    const canvas = document.getElementById(qrcodeId.value)
    if (!canvas) return
    await QRCode.toCanvas(canvas, props.value, {
      width: props.size,
      margin: 1,
      color: { dark: '#000000', light: '#ffffff' },
      errorCorrectionLevel: props.level,
    })
  } catch (e) {
    if (qrRef.value) {
      qrRef.value.insertAdjacentHTML('afterend', '<div style="font-size:9px;color:#888;margin-top:2px;text-align:center">' + props.value + '</div>')
    }
  }
}

onMounted(() => renderQR())
watch(() => props.value, () => renderQR())
</script>

<style scoped>
.print-qrcode { text-align: center; display: inline-block; }
.print-qrcode canvas { display: block; }
.qr-label { font-size: 9px; color: #888; margin-top: 2px; text-align: center; }
</style>
