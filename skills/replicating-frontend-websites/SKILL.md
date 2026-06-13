---
name: replicating-frontend-websites
description: Use when asked to clone, mirror, archive, scrape, or 1:1 replicate an existing website's frontend (复刻/克隆/镜像/抓站/扒站/离线备份/还原网站/搬运网站), including static sites, SPAs, SSG/SSR sites, and WebGL/Three.js experience sites. Use even if the user only gives a URL and says "copy this site", "把这个网站搬下来", or asks how to make an offline copy of a web page's design.
---

# 1:1 复刻前端网站（通解）

## 核心原则

**在弄清网站形态之前，不抓取任何东西。** 错误的发现方法（如对 SPA 用 `wget --mirror`）只会抓到一个 1-2KB 的空壳，浪费数小时并产出残废镜像。正确顺序：指纹识别 → 选对作业手册（playbook）→ 按 Phase 执行。

## 第 0 步（永远先做，缺一不可）

1. **合规声明**：默认用途 = 本地 / 离线 / 学习研究。向用户说明：公网再部署或商用须取得权利方授权（模板见 `references/risks-degradation.md` §法律）。
2. **开源检查**：搜 GitHub / 页面 meta / 页脚 / 作者博客。**找到官方源码仓库 → 直接 `git clone`，整个复刻流程跳过。**
3. **指纹识别**：`bash scripts/fingerprint.sh <url>`，再按 `references/fingerprinting.md` 人工复核（脚本只是初筛，结论以人工复核为准）。

## 决策树

```
官方开源？ ──是──► git clone，结束
  │否
  ▼
指纹识别（平台 + soft-404 签名 + 形态）
  ├─ 入口HTML>10KB、资源引用直接可见 ──► 纯静态/SSG ──► references/playbook-static.md
  ├─ 入口HTML近空 + <script type=module> ─┬─ 入口JS含 webgl/ktx2/draco/wasm/worker ──► references/playbook-webgl.md
  │                                       └─ 否 ──► DOM SPA / SSR水合 ──► references/playbook-spa.md
  ├─ 运行时调用 /api/、动态数据 ──► 叠加 references/playbook-hybrid.md
  └─ 需要服务端语言运行时(PHP/Rails模板) ──► 仅快照级可行，先向用户声明
```

混合形态 → 手册叠加（如 SPA + API 数据 → spa + hybrid 两份手册一起用）。本技能语言范围：HTML/CSS/JS/TS 产物。

## 两阶段复刻

- **Stage 1 · 交互镜像（默认，所有站）**：指纹 → 选手册 → 下载**编译产物** → 本地服务 → 验收。产物 `<project-name>-mirror/`，层级 **T0+T1**。这是本技能的既有主线，不变。
- **Stage 2 · AI 等价源码重建（仅编译站，opt-in）**：Stage 1 验收过且用户确认要**可编辑源码**后，用 cloner 引擎把编译站重建成干净现代栈源码。产物 `<project-name>-clone/`，层级 **T2-AI**。手册 `references/playbook-reconstruction.md`。

工作区 3 文件夹：
```
<workspace>/
├── <project-name>-mirror/          # Stage 1：交互镜像
├── ai-website-cloner-template/     # Stage 2 引擎：git clone 用户 fork（保持纯净）
└── <project-name>-clone/           # Stage 2：等价源码重建产物
```

## 六条铁律（违反任何一条不得宣称完成）

1. **永不信任 HTTP 状态码。** 各托管平台（Vercel/CF Pages/Netlify）对缺失路径普遍返回 `200` + HTML 外壳（soft-404）。存在性判断一律走 `fetch_ok()` / `real_asset()`（`scripts/lib.sh`），soft-404 签名以指纹识别实测为准。
2. **一切下载走 `dl()` 封装**：幂等 + `DONE.list` 续传 + `MISSING.log` 记账。绝不静默截断。
3. **资源拉不到不停车**：重试 → 降并发 → 占位 → 记账，最后统一汇报。处置规则见 `references/risks-degradation.md`。
4. **动手前声明诚实分层**（定义见 `references/verification.md`）。**原始源码（字节级原始工程）不可逆，禁止声称"还原了原站源码"。** 但编译站可在 Stage 2 用 cloner 做 **AI 等价源码重建（T2-AI）**：产出视觉&交互对齐、可二次开发的现代栈源码，**必须诚实标注为"AI 等价重建，非原站原始源码"**（手册 `references/playbook-reconstruction.md`）。
5. **验收是硬门槛**：本地起服务逐状态对照线上，DevTools Network **零 404、零 soft-200**。未过验收不得宣称完成。
6. **部署前停下确认授权**。本地镜像 ≠ 可公开发布。

## 通用 Phase 骨架

| Phase | 内容 | 工具 |
|---|---|---|
| 0 | 合规 + 开源检查 + 指纹识别 | `scripts/fingerprint.sh` |
| 1 | 静态初始化（外壳/入口JS/robots） | `scripts/lib.sh` |
| 2 | 资产发现（**方法由手册决定**） | wget / `scripts/capture.js` + `scripts/har2urls.sh` |
| 3 | 落盘（续传 + 校验） | `dl()` |
| 4 | 关键依赖校验（wasm/worker/字体等） | 手册检查单 |
| 5 | 本地服务（MIME/头按手册要求） | `scripts/serve.js` |
| 6 | 验收 | `references/verification.md` |
| ★ | **交接门**：Stage 1 验收过后**强制**先发诚实交接说明（"现完成=编译产物镜像 T0+T1，非可读源码"）→ 形态分流 | — |
| R0–R4 | **Stage 2 源码重建**（仅编译站 + 用户确认，opt-in） | `references/playbook-reconstruction.md` |
| 7 | 部署（须用户确认授权） | — |

**★ 交接门分流**：非编译站（纯静态/手写站）→ 说明"mirror 产物≈源码，**无需 stage2**"，结束；编译站（SPA/WebGL/SSR/打包）→ 引导"是否进行 Stage 2 等价源码重建？"，用户确认后才进 R0。

每个 Phase 结束一行汇报：`Phase N ✓ <完成项> | 资源 X 个 | MISSING Y 条 | 下一步 <...>`。

## 常见错误（自检表）

| 想法 | 现实 |
|---|---|
| "wget --mirror 一把梭" | SPA/WebGL 站只会抓到 <2KB 空壳。先指纹识别。 |
| "返回 200 就是抓到了" | soft-404 也返回 200+HTML。按签名双判（大小+类型），不看状态码。 |
| "这个文件抓不到，停下来问" | 不停车。记 `MISSING.log`，按降级矩阵处置，最后汇总。 |
| "我能还原出原站源码" | Vite/webpack 产物不可逆，原始源码拿不回。编译站可做 Stage 2 **AI 等价重建**（T2-AI），但须标注"非原站原始源码"。 |
| "用户只要镜像，我顺手把源码也重建了" | Stage 2 仅在编译站 + 用户确认后启动，不自作主张。非编译站直接说"无需 stage2"。 |
| "python -m http.server 就够了" | WebGL 站需要 wasm/ktx2 MIME + COOP/COEP 头，否则白屏。 |
| "没开源，直接开抓" | 先搜官方仓库。存在时复刻是纯浪费。 |
| "首页跑通了就算完成" | 必须穷尽全部交互状态 + Network 零 404/零 soft-200 才算。 |
