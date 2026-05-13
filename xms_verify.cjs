const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext();
  const page = await ctx.newPage();

  await page.goto('https://account.xiaomi.com/fe/service/identity/verifyPhone?sid=midun_n&context=p-n0oBUBA2NSLbc3yvUO8B-fiBvWBi0vNHS2lj3NkgRu8KwbQ4vsAFUNxTD93fcJl2AK6WndZCaHdNSE4bdfcwwst4EP5TYnSeJsjntSxkPkF5D5COWEglR2yXSc8QLF_WcyrCAUVK-xJRnRT0WE6Sy5rjzfiaPTBKJo6OpmI-S3zEpwsqCpSFuVhgHnqFgqyJgv9dsNIK5eEIBBXwx2c-HKRwU9faSgNAOELnRKB-BiM7f85hP0PKNUyxR06_u3FF4VP_J60We-FJo9uGgrFN4UanqQGtmCa1iX0hkHChneKn2D8gYq_oBXbkdDpC9kK5Oe6cuE_SpumuHuS4TOpvRMVjCwGyNNpXxHjnFtDCp8fqPlo4PwhfcKH7dA1R9oWGkwIljs0-3CdMYxzd7epOGViacg9WXjjUSyfPGdKl4sCqk1Iu2POHkTCYwLzjQJLL8VuONhmZXZuCdeNdpdQuRZY7okydOFejmYIP3Vtq4upjRqrdUDoaehvQomjXnne-RXah7uRtREYt131DyWatCGug2dVeNFMKmNBnlJBlYwjMPVFtEgIT64WIsy8HWwQK-pXXe_mExySoP_9IfUK0nWmmbflqj0Xrf3e1GF8dFdWOa2DnVUXeAUp6MRulY_Kt-yqspdiRf4BborPS7XIPhrmaZYBnE1T2mTV9PtwqP7BF1R5I6EDfkAigBr5JbZIlVoKJh-XU3ZPZ1FFpBLuH54re0XELqukVecMTzqWki5jP_aFSq3TOeJkEM7qdAyIAvf0JIsYTEQGTQkRhaQ-tDdT4AZ8uiVjXffuLrP9a_iPpXPL6qoEbCpDIGJ0eh00AbaG_biTEEmYH4xseiULcODf7PDKlyny57qaAMWgHWXEDclZ8dQTK9E_2dW_N8ROoqqVI-VVgbytQTp7iUm-F3_AMjt_Zv_7gm-oOmVDts&_locale=zh_CN');

  // Wait for JS to fully load
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(5000);

  const allInputs = await page.locator('input').all();
  console.log('Total inputs found:', allInputs.length);
  for (const i of allInputs) {
    const ph = await i.getAttribute('placeholder');
    const type = await i.getAttribute('type');
    console.log('  input:', type, '|', ph);
  }

  // Try page.fill which doesn't require a locator
  try {
    await page.fill('input[placeholder="请输入验证码"]', '655398');
    console.log('SUCCESS: Filled via page.fill');
    await page.waitForTimeout(500);
    await page.click('button:has-text("确定")');
    console.log('Clicked 确定');
    await page.waitForTimeout(5000);
    console.log('URL after:', page.url());
  } catch(e) {
    console.log('Error:', e.message);
  }

  await browser.close();
})().catch(e => console.error('FATAL:', e.message));
