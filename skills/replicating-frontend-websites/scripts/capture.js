#!/usr/bin/env node
// capture.js —— 穷尽交互 HAR 捕获 (资产发现的权威方法)
// 用法: node scripts/capture.js <url> [outDir=HAR] [scrolls=60] [scrollWaitMs=1200]
// 环境变量:
//   VIEWPORTS   "1920x1080,1366x768,390x844"  多视口列表 (移动/桌面可能加载不同资源)
//   SELECTORS   "a,button,[role=button],canvas" 要 hover 遍历的交互元素
//   HAR_CONTENT "omit"(默认, 只要清单) | "embed"(录 API 响应体时用, 见 playbook-hybrid)
// 依赖: npm i playwright && npx playwright install chromium
const { chromium } = require('playwright');
const fs = require('fs');

const url = process.argv[2];
if (!url) { console.error('用法: node capture.js <url> [outDir] [scrolls] [scrollWaitMs]'); process.exit(1); }
const outDir = process.argv[3] || 'HAR';
const scrolls = parseInt(process.argv[4] || '60', 10);
const wait = parseInt(process.argv[5] || '1200', 10);
const viewports = (process.env.VIEWPORTS || '1920x1080,1366x768,390x844')
  .split(',').map(s => s.trim().split('x').map(Number));
const selectors = (process.env.SELECTORS || 'a,button,[role=button],canvas').split(',');
const harContent = process.env.HAR_CONTENT || 'omit';
fs.mkdirSync(outDir, { recursive: true });

(async () => {
  // WebGL 站必须启用 GPU 相关参数, 否则场景不初始化、对应资源不请求
  const browser = await chromium.launch({
    args: ['--use-gl=angle', '--enable-webgl', '--ignore-gpu-blocklist'],
  });
  for (const [w, h] of viewports) {
    const ctx = await browser.newContext({
      viewport: { width: w, height: h },
      recordHar: { path: `${outDir}/capture-${w}x${h}.har`, content: harContent },
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36',
    });
    const page = await ctx.newPage();
    await page.goto(url, { waitUntil: 'networkidle', timeout: 120000 });

    // 1) 点击页面中心: 解锁 AudioContext (音频资源在用户手势之后才会请求)
    await page.mouse.click(w / 2, h / 2).catch(() => {});

    // 2) 分步滚动到底: 触发滚动状态机每一段的按需加载
    for (let i = 0; i < scrolls; i++) {
      await page.mouse.wheel(0, 800);
      await page.waitForTimeout(wait);
    }

    // 3) 遍历 hover 交互元素: 触发 hover/切换分支的懒加载
    for (const sel of selectors) {
      for (const el of await page.$$(sel)) {
        try { await el.hover({ timeout: 500 }); } catch {}
      }
    }

    await page.waitForTimeout(8000);   // 收尾等待挂起请求落地
    await ctx.close();                 // HAR 在 close 时写盘
    console.log(`✓ ${w}x${h} -> ${outDir}/capture-${w}x${h}.har`);
  }
  await browser.close();
  console.log('完成。下一步: bash scripts/har2urls.sh <host> ' + outDir + ' > ASSETS.urls');
})().catch(e => { console.error(e); process.exit(1); });
