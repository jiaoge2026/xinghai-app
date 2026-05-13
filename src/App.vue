<template>
  <router-view />
</template>

<script setup>
import { onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useTabStore } from '@/stores/tab'
import COMPONENT_MAP, { PATH_TO_NAME } from '@/utils/tab'

const router = useRouter()
const tabStore = useTabStore()

// 自动打开 Tab（路由变化时）
router.afterEach((to) => {
  if (to.meta?.public) return
  const name = PATH_TO_NAME[to.path]
  if (name) {
    tabStore.addTab({
      path: to.path,
      name: name,
      title: to.meta?.title || name,
      component: COMPONENT_MAP[name],
      closable: true,
    })
  }
})
</script>

<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif; background: #f0f2f5; }
#app { height: 100vh; display: flex; flex-direction: column; }
</style>
