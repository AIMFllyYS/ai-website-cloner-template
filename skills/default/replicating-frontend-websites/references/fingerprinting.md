# Phase 0 · 站点指纹识别

> 目的：在抓取任何东西之前，回答三个问题——①托管在哪（决定 soft-404 行为）②什么形态（决定资产发现方法）③是否开源（决定要不要复刻）。
> 入口：`bash scripts/fingerprint.sh <url>` 自动初筛 → 本文档人工复核。

---

## §1 开源检查（最便宜的捷径）

按序检查，命中即 `git clone` 结束：

1. GitHub/GitLab 搜索：站点域名、站点标题、`"<域名>" site:github.com`
2. 页面源码 meta：`generator`、注释里的仓库链接、`humans.txt`
3. 页脚 / About / 作者博客 / Awwwards 等案例页（创意站常注明 agency/作者，可顺藤找仓库）
4. 注意：**同名仓库 ≠ 官方源码**。核对作者、demo 链接、提交历史是否对得上线上站。

## §2 平台识别（响应头）

| 响应头特征 | 平台 | soft-404 行为 |
|---|---|---|
| `x-vercel-id` / `server: Vercel` | Vercel | SPA 站：200 + 入口外壳（实测约 1.4KB） |
| `cf-ray` + `server: cloudflare` | Cloudflare（Pages 或代理） | Pages：200 + 首页 HTML（可达数十 KB） |
| 两者同时出现 | Vercel/其他源站套 Cloudflare | 以源站行为为准，必须实测 |
| `x-nf-request-id` | Netlify | 默认 404，配置了 redirect 时 200+外壳 |
| `server: GitHub.com` | GitHub Pages | 真 404（404.html） |
| `x-amz-*` / `server: AmazonS3` | S3+CDN | 取决于错误文档配置 |
| 其他 `server:` 值 | 自建 nginx/apache 等 | 通常真 404，仍须实测 |

## §3 soft-404 标定（必做，1 个请求）

请求一个**肯定不存在**的路径（如 `/__fp_probe_随机串.bin`），记录三元组：

```
status / content-type / body大小
```

- `404` → 平台诚实，后续可信状态码（仍建议双判）。
- `200 + text/html + 固定大小` → **soft-404 存在**。把该 body 大小记为 `SOFT404_SIZE` 签名，导出给 `scripts/lib.sh`（`export SOFT404_SIZE=<实测值+10%余量>`）。此后**一切存在性判断只看"类型+大小"双判，禁止看状态码**。

## §4 形态判别信号（按层递进）

### 第一层：根页面本身（已抓，0 额外请求）

| 信号 | 判读 |
|---|---|
| 入口 HTML > 10KB，`<link>/<script>/<img>` 资源引用直接可见 | 纯静态 / SSG |
| 入口 HTML < 3KB，`<body>` 近空，仅 `<script type="module" src="/assets/xxx-[hash8].js">` | Vite 构建 SPA |
| HTML 较大但含 `id="__next"` / `data-reactroot` / `__NUXT__` 等水合标记 | SSR + 水合（按 SPA 手册 + 注意每路由 HTML 都要抓） |
| 资源名形如 `name-xxxxxxxx.ext`（8位hash） | 打包器产物 → T2 源码重建不可行，提前声明 |
| 相对路径 `./sections/`、无 hash | 手写静态 → 可能字节级 1:1 |

### 第二层：入口 JS（1-2 个请求）

抓入口 JS（入口很小就再追一层它 import 的最大 chunk）：

| 信号 | 判读 |
|---|---|
| `webgl` / `three` / `ktx2` / `draco` / `wasm` / `getContext('webgl')` | WebGL 体验站 → playbook-webgl |
| `xxxworker-[hash].js` 引用（audio/exr/msdf 等） | 有 Web Worker；若配 wasm → 强 WebGL 信号 |
| manifest 数组明文可见（可枚举资源 ID） | 源码解析法可用（playbook-static §序列探测） |
| 资源路径运行时拼接（编码 manifest、字符串拼 hash） | **静态枚举不可能 → 必须 HAR 捕获** |
| `fetch(`/`axios`/`XMLHttpRequest` 指向 `/api/`、graphql 等 | 有后端数据依赖 → 叠加 playbook-hybrid。**注意**：打包产物里的 `fetch(` 大多只是资产加载（Three.js/动态 import），不是数据 API——`hybrid_api_suspected` 只是疑似信号，以 HAR 里是否真有 `/api/`、graphql 请求为准（igloo.inc 实测即为此类误报） |

### 第三层：行为信号（可选）

- `sitemap.xml`：返回真 XML → 路由可枚举；返回 200+外壳 → soft-404 的又一证据。
- `robots.txt`：记录 Disallow 与抓取礼仪要求。
- 内容是否要交互才出现（滚动加载、点击切换、音频手势解锁）→ 是则 HAR 捕获必须模拟全部交互。
- `_headers`/`_redirects`（CF Pages）、`vercel.json` 是否可直接抓到 → 部署期复用。

## §5 判定伪代码

```
if 官方仓库存在: clone; 结束
标定 soft-404 签名
if 根HTML近空 且 有 module 入口:
    入口JS含 webgl/wasm/ktx2/draco/worker ? → webgl 手册 : spa 手册
elif 根HTML资源引用可见(≥5处): → static 手册
else: → 人工分诊（抓入口JS再判 / 当 spa 处理）
任一形态 + /api/ 调用 → 叠加 hybrid 手册
```

## §6 实测案例（两个已验证锚点）

| 站点 | 指纹 | 结论 |
|---|---|---|
| shuchenglin-handbook.pages.dev | 根 HTML 49KB、资源引用可见、CF Pages、soft-404=200+首页HTML | static 手册（wget 镜像 + 源码解析 + 序列探测） |
| www.igloo.inc | 根 HTML 1.4KB 空 body、Vite module 入口、Vercel 套 CF、soft-404=200+1410B外壳、入口链含 App3D/ktx2/draco/4 workers | webgl 手册（HAR 穷尽捕获 + wasm/MIME/COOP-COEP） |
