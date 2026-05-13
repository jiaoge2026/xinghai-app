import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src')
    }
  },
  build: {
    rollupOptions: {
      output: {
        // 固定 chunk 命名策略，避免 hash 每次构建变化
        manualChunks(id) {
          if (id.includes('node_modules')) return 'vendors'
          // tab.js 单独打包到 vendors，主包需要用到 COMPONENT_MAP
          if (id.includes('/utils/tab.js')) return 'tab-utils'
          if (id.includes('/stores/tab.js')) return 'tab-utils'
        }
      }
    }
  },
  server: {
    port: 8080,
    host: '0.0.0.0',
    proxy: {
      '/api': {
        target: 'http://47.103.11.151:38080',
        changeOrigin: true
      }
    }
  }
})