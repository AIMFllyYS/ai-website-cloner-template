# 手册 B · DOM SPA / SSR+水合 站

> 适用：内容由 JS 在浏览器内渲染（CSR），或服务端渲染后水合（Next/Nuxt 等）；**不含** WebGL 主导的体验站（那是手册 C）。
> 可达上限 Stage 1：**T0 资产归档 + T1 可交互镜像**。T2 原始源码**不可逆、禁止声称**；编译站完成 Stage 1 后可进行 **T2-AI AI 等价源码重建**（opt-in，用户确认），见 `references/playbook-reconstruction.md`。

---

## 核心策略：双轨

1. **首选轨 · 原始包镜像**：保留站点原有 JS 包，本地照常运行 SPA。资产清单靠 **Playwright HAR 捕获**（与手册 C 同法，交互强度低一些）。
2. **降级轨 · 渲染快照**：仅当原始包离线跑不起来（强依赖后端，见手册 D）时，用 Playwright 把每个路由渲染后的 DOM 序列化成静态 HTML。**快照会失去交互性，必须向用户声明这是降级品**。

## Phase 1 · 初始化

```bash
export BASE="https://<host>"; export MIRROR="./mirror"
export SOFT404_SIZE=<指纹实测值>
source scripts/lib.sh
dl "$BASE/" "index.html"        # 外壳
# 从外壳提取入口 JS/CSS（type=module、modulepreload、stylesheet），逐个 dl
```

## Phase 2 · 路由枚举（SPA 特有步骤）

资产因路由而异，必须先拿到全部路由：

1. `sitemap.xml` 返回真 XML → 直接作为路由清单（用 `fetch_ok` 判真伪，soft-404 平台会返回外壳冒充）。
2. 无 sitemap → Playwright 加载首页，收集所有 `a[href]` 同域链接，逐个访问再收集（BFS，去重，设深度上限）。
3. 兜底：在页面里 hook `history.pushState` 记录程序化跳转。

## Phase 3 · HAR 捕获 + 落盘

```bash
node scripts/capture.js "$BASE/" HAR 20 800          # 滚动强度按站体量调
# 多路由：对每个路由各跑一次（或在 capture.js 里顺序 goto）
bash scripts/har2urls.sh <host> HAR > ASSETS.urls
while read -r url; do dl "$url" "${url#"$BASE"/}"; done < ASSETS.urls
```

SSR+水合站额外注意：**每个路由的 HTML 都是独立文档**，逐路由 `dl "$BASE/<route>" "<route>/index.html"`，不能只抓一个外壳。

## Phase 4 · 关键校验

- 入口/chunk JS 全部 `real_asset` 通过（soft-404 外壳混进 JS 目录是最常见污染）。
- 字体（woff2）、动态 import 的懒加载 chunk（点过所有主要交互后 HAR 里才会出现）。
- 检查 JS 里是否有指向绝对域名的硬编码请求（`grep -o 'https://<host>[^"]*'`）——离线时这些会逃逸到线上，记入已知差异或本地 hosts 处理。

## Phase 5 · 本地服务（SPA fallback 必需）

CSR 路由刷新会请求 `/some/route`，本地必须回退到 `index.html`：

```bash
node scripts/serve.js "$MIRROR" 8080 --spa
```

hash 路由（`#/route`）无需 fallback；history 路由必须 `--spa`。

## Phase 6 · 验收

按 `verification.md` L0–L2：每个路由直接打开 + 站内跳转 + 刷新三种方式都正常；Network 零 404、零 soft-200；Console 无致命错误。

## ★ Stage 1 完成 → 交接门（见 `SKILL.md`）

Phase 0–6 验收过后，**强制**先发诚实交接说明：「已完成编译产物镜像（T0+T1），非可读源码」→ 本站属编译站（SPA/SSR），询问是否进入 Stage 2 AI 等价源码重建（`references/playbook-reconstruction.md`）。

## 本手册风险速查

| 风险 | 处置 |
|---|---|
| 路由枚举不全 | sitemap + BFS 爬链 + pushState hook 三法并用；存疑路由记 `MISSING.log` |
| 懒加载 chunk 漏抓 | HAR 捕获时把每个主要交互都点一遍；验收时盯 Network |
| API 数据依赖 | 转手册 D（hybrid）叠加处理 |
| 刷新路由 404 | serve.js `--spa` fallback |
| 水合不匹配警告 | SSR 站离线后常见，无碍运行则记已知差异 |
