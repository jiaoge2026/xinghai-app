# 财务账套第一阶段：前端开发

## 防坑检查清单（必读）

### 字体问题
- [ ] index.html 里必须加 Google Fonts CDN 加载 Noto Sans SC：`https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400;500;600&display=swap`
- [ ] variables.css 和 App.vue 的 font-family 链 Noto Sans SC 放第一位

### 路由问题
- [ ] Vite dev server 已停止，外网不应访问8080（端口已切到 nginx 8077）
- [ ] nginx 配置好 content hash 后，发布不需要清缓存

### 响应式问题
- [ ] 菜单状态用 Object 不用 Set（Set 在模板里不响应）

### 参数问题
- [ ] 前端传参的类型必须和后端一致（status 是字符串 "BUSINESS"/"FINANCE" 不是数字）

### 部署问题
- [ ] npm run build 不需要 sudo
- [ ] nginx root 指向 /home/admin/xinghai-web/dist，`chmod 755 /home/admin`

---

## 上下文

- 后端已完成：tb_account_type表 + tb_menu.account_type字段 + tb_role.account_type字段
- 后端API：GET /api/v1/account-types/all 返回账套列表
- 后端API：POST /api/v1/auth/switch-account 切换账套
- 后端JAR运行在 38080，nginx 代理到 8077
- 前端项目路径：/home/admin/xinghai-web
- 登录账号：admin / admin123

---

## 第一步：理解现有代码（必须先做）

读取以下文件，理解后再动手：

```bash
# 理解登录和路由
cat /home/admin/xinghai-web/src/views/Login.vue
cat /home/admin/xinghai-web/src/router/index.ts
cat /home/admin/xinghai-web/src/stores/auth.ts
cat /home/admin/xinghai-web/src/api/auth.js

# 理解侧边栏
cat /home/admin/xinghai-web/src/views/layout/MainLayout.vue

# 理解API请求
cat /home/admin/xinghai-web/src/api/index.js
```

---

## 第二步：创建账套选择页面

路径：`/home/admin/xinghai-web/src/views/account/AccountSelect.vue`

### 功能要求
- 全屏两列卡片（业务账套 / 财务账套）
- 调用 GET /api/v1/account-types/all 获取有权限的账套列表
- 点击卡片 → 调用 POST /api/v1/auth/switch-account（body: {accountType: "FINANCE"}）→ 存 localStorage → router.push('/')
- 如果只有一个账套 → 自动进入，不需要选择页

### 页面设计
```
┌─────────────────────────────────────────────┐
│           星海ERP  ·  选择账套               │
│                                             │
│   ┌──────────────┐  ┌──────────────┐       │
│   │    🏢        │  │    💰        │       │
│   │  业务账套    │  │  财务账套    │       │
│   │              │  │              │       │
│   │ FSM工单      │  │ 凭证管理     │       │
│   │ 库存备件     │  │ 财务报表     │       │
│   │ 物流配送     │  │ 应收应付     │       │
│   │ 零售门店     │  │ 固定资产     │       │
│   │              │  │              │       │
│   │  [进入]      │  │  [进入]      │       │
│   └──────────────┘  └──────────────┘       │
│                                             │
└─────────────────────────────────────────────┘
```

### 代码模板
```vue
<template>
  <div class="account-select-page">
    <div class="account-select-container">
      <div class="page-header">
        <h2>请选择账套</h2>
        <p class="subtitle">选择您要进入的管理模块</p>
      </div>
      <div class="cards-grid">
        <div
          v-for="account in accountList"
          :key="account.code"
          class="account-card"
          @click="selectAccount(account)"
        >
          <div class="card-icon">{{ account.icon }}</div>
          <div class="card-title">{{ account.name }}</div>
          <div class="card-desc">{{ account.description }}</div>
          <div class="card-btn">进入 {{ account.name }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import axios from '@/api/index'

const router = useRouter()
const accountList = ref([])

onMounted(async () => {
  try {
    const res = await axios.get('/api/v1/account-types/all')
    accountList.value = res.data || []
  } catch (e) {
    console.error('获取账套列表失败', e)
  }
})

async function selectAccount(account) {
  try {
    await axios.post('/api/v1/auth/switch-account', {
      accountType: account.code
    })
  } catch (e) {
    // 忽略错误，继续跳转
  }
  localStorage.setItem('xinghai_last_account_type', account.code)
  localStorage.setItem('xinghai_home_url', account.homeUrl || '/')
  router.push(account.homeUrl || '/')
}
</script>

<style scoped>
.account-select-page {
  min-height: 100vh;
  background: var(--main-bg, #f0f2f5);
  display: flex;
  align-items: center;
  justify-content: center;
}
.account-select-container {
  text-align: center;
  max-width: 800px;
  width: 100%;
  padding: 40px 20px;
}
.page-header h2 {
  font-size: 24px;
  font-weight: 600;
  color: var(--text-primary, #1a1a1a);
  margin-bottom: 8px;
}
.cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 24px;
  margin-top: 32px;
}
.account-card {
  background: #fff;
  border-radius: 12px;
  padding: 32px 24px;
  cursor: pointer;
  transition: all 0.2s;
  border: 2px solid transparent;
}
.account-card:hover {
  border-color: #3b82f6;
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(59, 130, 246, 0.15);
}
.card-icon {
  font-size: 48px;
  margin-bottom: 16px;
}
.card-title {
  font-size: 20px;
  font-weight: 600;
  color: #1a1a1a;
  margin-bottom: 8px;
}
.card-desc {
  font-size: 13px;
  color: #6b7280;
  line-height: 1.6;
  margin-bottom: 24px;
}
.card-btn {
  background: #3b82f6;
  color: #fff;
  padding: 10px 24px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  display: inline-block;
}
.dark-mode .card-title { color: #e5e7eb; }
.dark-mode .account-card { background: #1a1a24; }
.dark-mode .card-desc { color: #9ca3af; }
</style>
```

---

## 第三步：修改登录逻辑

修改 Login.vue 或 stores/auth.ts：

登录成功后：
```js
// 登录成功后
const { accountTypes, defaultAccountType, lastAccountType, homeUrl } = res.data

// 存localStorage
localStorage.setItem('xinghai_last_account_type', lastAccountType || defaultAccountType)

// 如果只有一个账套或lastAccountType有值，直接进入对应首页
if (lastAccountType || accountTypes.length === 1) {
  router.push(homeUrl || lastAccountType?.homeUrl || '/')
} else {
  // 多个账套，去选择页
  router.push('/select-account')
}
```

---

## 第四步：修改路由配置

在 router/index.ts 加新路由：

```ts
{
  path: '/select-account',
  component: () => import('@/views/account/AccountSelect.vue'),
  meta: { requiresAuth: true, title: '选择账套' }
},
{
  path: '/finance/dashboard',
  component: () => import('@/views/finance/FinanceDashboard.vue'),  // 占位页
  meta: { requiresAuth: true, title: '财务驾驶舱' }
}
```

---

## 第五步：创建财务占位首页

路径：`/home/admin/xinghai-web/src/views/finance/FinanceDashboard.vue`

内容：简单卡片页面，显示"财务账套"标题 + 欢迎文字，因为财务模块业务内容还没开发，所以先用这个占位。

---

## 第六步：修改MainLayout.vue

### 6.1 Header右侧加切换按钮

在 MainLayout.vue 的 Header 右侧（用户名旁边）加：

```vue
<!-- 账套切换按钮 -->
<div class="account-switch" @click="showAccountSwitch = !showAccountSwitch">
  <span class="account-icon">{{ currentAccountIcon }}</span>
  <span class="account-name">{{ currentAccountName }}</span>
  <span class="arrow">▾</span>
</div>

<!-- 切换下拉 -->
<div v-if="showAccountSwitch" class="account-dropdown">
  <div
    v-for="acc in availableAccounts"
    :key="acc.code"
    class="dropdown-item"
    @click="switchTo(acc)"
  >
    <span>{{ acc.icon }}</span>
    <span>{{ acc.name }}</span>
  </div>
</div>
```

### 6.2 侧边栏菜单按账套过滤

在 computed menus 里加过滤：

```js
const currentAccountType = localStorage.getItem('xinghai_last_account_type') || 'BUSINESS'

const filteredMenus = computed(() => {
  if (!menus.value) return []
  return menus.value.filter(menu => {
    return menu.accountType === 'BOTH' || menu.accountType === currentAccountType
  })
})
```

---

## 第七步：axios封装

确保 `/api/v1/account-types/all` 和 `/api/v1/auth/switch-account` 能正确请求：

```js
// src/api/index.js 里 axios instance 的 baseURL
// 已配置 /api，调用时：
axios.get('/api/v1/account-types/all')  // 实际请求 /api/api/v1/... ❌

// 检查实际 baseURL，如果实际是 /api/v1
axios.get('/account-types/all')  // 正确
```

**先 curl 验证后端接口通了再写前端代码！**

```bash
curl -s http://47.103.11.151:8077/api/v1/account-types/all
```

---

## 第八步：构建和部署

```bash
cd /home/admin/xinghai-web
npm run build

# 检查dist内容
ls -la dist/

# 部署（注意不需要 sudo 启动 npm，但部署文件需要正确权限）
sudo cp -r dist/* /home/admin/xinghai-web/dist/
sudo chmod -R 755 /home/admin/xinghai-web/dist
sudo nginx -s reload
```

---

## 验证

打开浏览器访问 http://47.103.11.151:8077

1. 登录 admin/admin123
2. 如果有两个账套 → 出现账套选择页
3. 点击"财务账套" → 进入财务账套，Header显示"💰 财务账套"
4. 点击Header右侧切换按钮 → 下拉显示两个账套，选择"业务账套" → 侧边栏切换为业务菜单

---

## 交付物

1. AccountSelect.vue 完整代码
2. FinanceDashboard.vue 完整代码
3. router/index.ts 改动内容
4. Login.vue 或 stores/auth.ts 改动内容
5. MainLayout.vue Header切换按钮的完整代码
6. 构建验证（npm run build 成功 + 浏览器测试截图）
