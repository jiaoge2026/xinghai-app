/**
 * 前端全页面错误扫描器
 * 用法: node test-pages.js
 * 需要先 npm install playwright
 */
const { chromium } = require('playwright');

const BASE = 'http://47.103.11.151:8077';
const USERNAME = 'admin';
const PASSWORD = 'admin123';

// 从 router/index.js 提取的所有页面路由
const PAGES = [
  '/fsm/work-orders',
  '/fsm/work-orders/create',
  '/fsm/haier-orders',
  '/fsm/haier-sync',
  '/fsm/sync-logs',
  '/fsm/projects',
  '/fsm/engineers',
  '/fsm/gps',
  '/fsm/caller-id',
  '/fsm/customers',
  '/wms/parts',
  '/wms/warehouses',
  '/wms/stock',
  '/wms/alerts',
  '/logistics/drivers',
  '/logistics/delivery-orders',
  '/logistics/routes',
  '/dispatch/board',
  '/retail/stores',
  '/retail/products',
  '/retail/sales-orders',
  '/retail/categories',
  '/retail/inventory',
  '/crm/contacts',
  '/crm/opportunities',
  '/crm/follow-ups',
  '/crm/tags',
  '/crm/customers',
  '/member/members',
  '/member/points',
  '/member/coupons',
  '/callcenter/call-records',
  '/callcenter/ivr',
  '/callcenter/callback',
  '/finance/subjects',
  '/finance/vouchers',
  '/finance/receipts',
  '/finance/payments',
  '/finance/bank-accounts',
  '/finance/reports',
  '/hr/employees',
  '/hr/employees/import',
  '/hr/departments',
  '/hr/attendance',
  '/hr/leaves',
  '/hr/salary',
  '/hr/commission',
  '/qa/inspections',
  '/qa/feedbacks',
  '/qa/templates',
  '/report/dashboard',
  '/report/fsm',
  '/report/finance',
  '/system/users',
  '/system/roles',
  '/system/menus',
  '/system/dict',
  '/system/upgrade',
  '/system/organization',
  '/system/haier-accounts',
  '/system/config',
  '/ai/chat',
  '/wecom/messages',
  '/wecom/callback',
];

async function login(page) {
  await page.goto(`${BASE}/login`);
  await page.fill('input[placeholder="用户名"]', USERNAME);
  await page.fill('input[placeholder*="密码"]', PASSWORD);
  await page.click('button:has-text("登 录")');
  await page.waitForURL('**/dashboard', { timeout: 10000 }).catch(() => {});
  await page.waitForTimeout(2000);
}

// 检测页面上所有 ElMessage 错误通知
function checkElMessageErrors() {
  return `
    (function() {
      var msgs = document.querySelectorAll('.el-message--error');
      var results = [];
      for (var i = 0; i < msgs.length; i++) {
        var el = msgs[i];
        var text = el.innerText || '';
        if (text) results.push(text.trim());
      }
      return results;
    })()
  `;
}

// 尝试触发页面上的常见按钮操作（新增/编辑/删除），等待通知出现
async function tryClickActions(page) {
  const apiErrors = [];

  // 常见按钮选择器：新增、编辑、删除、提交、保存
  const buttonSelectors = [
    'button:has-text("新增")',
    'button:has-text("添加")',
    'button:has-text("新建")',
    'button:has-text("编辑")',
    'button:has-text("保存")',
    'button:has-text("提交")',
    'button:has-text("删除")',
    'button:has-text("分配权限")',
    'text=新 增 角 色',  // 角色管理新增按钮（有多余空格）
    '.el-button--primary:not([disabled])',
  ];

  for (const sel of buttonSelectors) {
    try {
      const btn = await page.$(sel);
      if (btn) {
        const isVisible = await btn.isVisible();
        if (isVisible) {
          await btn.click();
          await page.waitForTimeout(1500); // 等待API返回 + 通知弹出
          break; // 只触发一个按钮
        }
      }
    } catch (e) {}
  }

  // 检查点击后是否出现了错误通知
  const msgErrors = await page.evaluate(checkElMessageErrors());
  for (const err of msgErrors) {
    apiErrors.push(`[ElMessage错误] ${err}`);
  }

  return apiErrors;
}

async function checkPage(page, url) {
  const errors = [];
  const warnings = [];

  // 监听 console
  page.on('console', msg => {
    if (msg.type() === 'error') {
      errors.push(`[console.error] ${msg.text()}`);
    }
  });

  // 监听请求失败
  page.on('response', resp => {
    if (resp.status() >= 400) {
      errors.push(`[${resp.status()}] ${resp.url()}`);
    }
  });

  // 监听页面崩溃
  page.on('crash', () => {
    errors.push('[CRASH] Page crashed!');
  });

  try {
    await page.goto(`${BASE}${url}`, { waitUntil: 'networkidle', timeout: 15000 });
    await page.waitForTimeout(2000);

    // 检测 ElMessage 错误通知（页面加载时就有的错误）
    const initialErrors = await page.evaluate(checkElMessageErrors());
    for (const err of initialErrors) {
      errors.push(`[ElMessage错误] ${err}`);
    }

    // 尝试点击按钮，检测操作触发的API错误
    const clickErrors = await tryClickActions(page);
    errors.push(...clickErrors);

    // 检查是否有"页面空白"典型特征
    const bodyText = await page.evaluate(() => document.body.innerText);
    const hasContent = bodyText.trim().length > 50;

    // 检查 el-table 是否崩溃（典型错误：Mt is not iterable）
    const tableError = await page.evaluate(() => {
      const tables = document.querySelectorAll('.el-table');
      for (const t of tables) {
        if (t.querySelector('.el-table__empty-text')?.innerText.includes('渲染')) {
          return true;
        }
      }
      return false;
    });

    return {
      url,
      status: errors.length === 0 && hasContent ? '✅ OK' : '❌ ERROR',
      errors,
      hasContent,
      warnings
    };
  } catch (e) {
    return { url, status: '❌ TIMEOUT/CRASH', errors: [e.message], hasContent: false };
  }
}

(async () => {
  console.log('🚀 启动浏览器...');
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await login(page);
  console.log('✅ 登录成功\n');

  const results = [];
  for (const p of PAGES) {
    process.stdout.write(`检查 ${p.padEnd(35)} `);
    const r = await checkPage(page, p);
    results.push(r);
    console.log(r.status);
    if (r.errors.length > 0) {
      for (const e of r.errors.slice(0, 3)) {
        console.log(`   └─ ${e.substring(0, 120)}`);
      }
    }
  }

  await browser.close();

  console.log('\n========== 汇总 ==========');
  const ok = results.filter(r => r.status.includes('OK')).length;
  const bad = results.filter(r => !r.status.includes('OK')).length;
  console.log(`✅ 正常: ${ok}  ❌ 异常: ${bad}`);
  if (bad > 0) {
    console.log('\n异常页面:');
    for (const r of results.filter(r => !r.status.includes('OK'))) {
      console.log(`  ${r.url}`);
    }
  }
})();
