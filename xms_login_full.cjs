const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ 
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
  });
  const ctx = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    extraHTTPHeaders: { 'Accept-Language': 'zh-CN,zh;q=0.9' }
  });
  const page = await ctx.newPage();

  // 拦截所有请求，找最终Cookie
  let finalCookies = [];
  page.on('response', async resp => {
    const url = resp.url();
    if (url.includes('workbench/onlogin')) {
      const cookies = resp.headers()['set-cookie'];
      console.log('=== GOT onlogin RESPONSE ===');
      console.log('Status:', resp.status());
      console.log('Set-Cookie:', cookies ? cookies.substring(0, 300) : 'none');
      finalCookies.push({ url, cookies, status: resp.status() });
    }
  });

  console.log('=== Step 1: Navigate to XMS login ===');
  await page.goto('https://xms.be.xiaomi.com/', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2000);
  console.log('URL after initial:', page.url());

  // 检查页面内容
  const initialState = await page.evaluate(() => ({
    url: window.location.href,
    title: document.title,
    bodyText: document.body.innerText.substring(0, 300)
  }));
  console.log('Page state:', JSON.stringify(initialState, null, 2));

  // 如果跳转到account.xiaomi.com，填写登录表单
  if (page.url().includes('account.xiaomi.com')) {
    console.log('\n=== Step 2: Filling login form ===');
    
    // 等待并填写用户名
    await page.waitForSelector('input[name="user"]', { timeout: 10000 }).catch(() => null);
    await page.fill('input[name="user"]', '13153195607').catch(() => 
      page.fill('input[placeholder*="手机"]', '13153195607').catch(() => 
        page.fill('input[type="text"]', '13153195607').catch(e => console.log('Fill user error:', e.message))
      )
    );
    
    // 填写密码
    await page.fill('input[name="password"]', 'aA123256@').catch(() =>
      page.fill('input[type="password"]', 'aA123256@').catch(e => console.log('Fill pass error:', e.message))
    );
    
    console.log('Filled credentials');
    await page.waitForTimeout(500);
    
    // 点击登录
    const loginBtns = await page.locator('button').filter({ hasText: /登\s*录|Login|sign\s*in/i }).all();
    if (loginBtns.length > 0) {
      await loginBtns[0].click();
      console.log('Clicked login button');
    } else {
      await page.keyboard.press('Enter');
      console.log('Pressed Enter');
    }
    
    await page.waitForTimeout(3000);
    console.log('URL after login:', page.url());
  }

  // 检查是否到了验证码页面
  console.log('\n=== Step 3: Check current state ===');
  const currentState = await page.evaluate(() => ({
    url: window.location.href,
    title: document.title,
    hasInput: document.querySelectorAll('input').length,
    hasButton: document.querySelectorAll('button').length,
    bodyText: document.body.innerText.substring(0, 500),
    // 找React root
    reactRoot: !!document.getElementById('root')?._reactRoot
  }));
  console.log('Current state:', JSON.stringify(currentState, null, 2));

  // 检查cookies
  const cookies = await ctx.cookies();
  console.log('\nCurrent cookies:', cookies.map(c => c.name).join(', '));

  // 如果还在验证页面，等待OTP输入
  if (currentState.url.includes('verifyPhone') || currentState.bodyText.includes('验证码')) {
    console.log('\n=== Step 4: OTP page detected - waiting 120s ===');
    await page.waitForTimeout(120000); // 等待焦哥手动输入OTP
    console.log('URL after wait:', page.url());
    
    // 检查最终cookies
    const finalCks = await ctx.cookies();
    const serviceToken = finalCks.find(c => c.name.includes('serviceToken'));
    console.log('serviceToken cookie:', serviceToken ? 'FOUND' : 'NOT FOUND');
    if (serviceToken) console.log('Value:', serviceToken.value);
  }

  await browser.close();
  console.log('\nDONE');
})().catch(e => console.error('FATAL:', e.message));
