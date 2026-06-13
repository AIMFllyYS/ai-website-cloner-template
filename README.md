# AI Website Cloner — Stage-2 Source Reconstruction Engine

> The dedicated **Stage 2** engine for the `replicating-frontend-websites` Claude Code skill.
> Forked from [`JCodesMore/ai-website-cloner-template`](https://github.com/JCodesMore/ai-website-cloner-template) · MIT licensed · trimmed to **Claude Code only**.

<a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT License" /></a>
<img src="https://img.shields.io/badge/engine-Stage%202-7c3aed" alt="Stage 2 Engine" />
<img src="https://img.shields.io/badge/runs%20in-Claude%20Code-d97757" alt="Claude Code" />

This repository AI-rebuilds a target website's compiled front end into **clean, editable Next.js / React / TypeScript / Tailwind source**. You point it at a URL inside Claude Code, run `/clone-website <url>`, and it inspects the live page, extracts design tokens and assets, writes component specs, and dispatches parallel builder agents to reconstruct the site section by section.

---

## Where this fits: the two-stage replication flow

Replicating a website cleanly is a two-stage pipeline. This repo is **Stage 2**.

| Stage | Tool | Input | Output |
|-------|------|-------|--------|
| **Stage 1 — Mirror** | The `replicating-frontend-websites` skill | A live URL | `<project>-mirror/` — the **compiled** static site (minified HTML/CSS/JS, bundled assets) exactly as shipped |
| **Stage 2 — Rebuild** | **This engine** (`ai-website-cloner-template`) | The live URL (and the Stage-1 mirror as reference) | `<project>-clone/` — a **fresh, human-editable Next.js source project** that matches the original visually and behaviorally |

Stage 1 captures *what the browser receives*. Stage 2 reconstructs *maintainable source you can actually develop against*.

### Honesty about the output

**This produces an AI equivalent rebuild on a modern stack — NOT the target's original pre-bundle source code.**

Compiled, minified, tree-shaken, and bundled output cannot be reversed back into the author's original source. Variable names, file boundaries, build-time tooling, original component structure, shader sources, and 3D project files are gone for good. What this engine delivers is a **clean re-implementation** in idiomatic Next.js 16 / React 19 / TypeScript / Tailwind v4 that is **aligned to the original's visuals and interactions** — layout, spacing, colors, typography, animations, and behavior — but is its own independent codebase. Treat it as a faithful re-creation, not a decompilation.

---

## Requirements

- **Node.js >= 24**
- **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** with browser access, launched as:
  ```bash
  claude --chrome
  ```
  (Browser automation is mandatory — the engine inspects the live page via a browser MCP. Chrome MCP is preferred; Playwright/Puppeteer/Browserbase also work.)
- The `/clone-website` command (shipped in `.claude/skills/clone-website/`).

> This fork is **Claude Code only**. All other agent/IDE integrations (Cursor, Windsurf, Gemini, Codex, Copilot, Cline, Continue, Amazon Q, Augment, Aider, OpenCode) and their sync scripts have been removed.

---

## Quick start

```bash
# 1. Install dependencies
npm install

# 2. Launch Claude Code with browser access
claude --chrome

# 3. Run the engine on a target URL
/clone-website https://example.com
```

You can pass multiple URLs: `/clone-website <url1> [<url2> ...]`. Each site is kept in its own isolated extraction folder.

---

## Workspace convention (three folders)

Keep all three side by side in one workspace so the engine can cross-reference the mirror while it rebuilds:

```
my-workspace/
├── <project>-mirror/                 # Stage 1 output — compiled mirror of the live site
├── ai-website-cloner-template/       # THIS engine (Stage 2)
└── <project>-clone/                  # Stage 2 output — the rebuilt Next.js source project
```

- `<project>-mirror/` — produced by the Stage-1 mirror skill; the compiled reference and **asset library** (reuse already-downloaded images/videos/fonts instead of re-hitting the server).
- `ai-website-cloner-template/` — this repository; the reconstruction engine. Keep it pristine; instantiate a copy into `<project>-clone/` to do the actual rebuild.
- `<project>-clone/` — the editable Next.js/React/TS rebuild this engine produces.

---

## Tech stack of the rebuilt output

- **Next.js 16** — App Router, React 19, TypeScript strict
- **shadcn/ui** — Radix primitives + Tailwind CSS v4 (`cn()` utility)
- **Tailwind CSS v4** — oklch design tokens
- **Lucide React** — default icons, replaced/supplemented by SVGs extracted from the target

## How the engine works

The `/clone-website` skill runs a multi-phase pipeline:

1. **Reconnaissance** — screenshots, design-token extraction, interaction sweep (scroll/click/hover/responsive).
2. **Foundation** — fonts, colors, globals, and downloads every asset.
3. **Component specs** — detailed spec files in `docs/research/` with exact computed CSS, states, behaviors, and content.
4. **Parallel build** — builder agents in git worktrees, one per section/component.
5. **Assembly & QA** — merges worktrees, wires the page, runs a visual diff against the original.

## Commands

```bash
npm run dev        # Start dev server
npm run build      # Production build
npm run lint       # ESLint
npm run typecheck  # TypeScript check
npm run check      # lint + typecheck + build
```

---

## 中文说明

本仓库是 Claude Code 技能 **`replicating-frontend-websites`（前端网站复刻）** 的**第二阶段（Stage 2）源码重建引擎**。

**两阶段流程：**

- **第一阶段（下载镜像）** —— 由 `replicating-frontend-websites` 技能完成，把目标站点**已编译**的静态产物（压缩后的 HTML/CSS/JS、打包资源）原样抓取到 `<project>-mirror/`。
- **第二阶段（AI 重建，即本工具）** —— 在 Claude Code 中运行 `/clone-website <url>`，把已编译的站点用 AI **重建为干净、可编辑的 Next.js / React / TypeScript / Tailwind 源码**，输出到 `<project>-clone/`。

**重要的诚实声明：** 本工具的产物是**基于现代技术栈的 AI 等价重建，并非目标站点打包前的原始源码**。压缩、混淆、打包后的产物无法被逆向还原成作者最初的源代码；我们只能在**视觉与交互层面对齐**原站，生成一份独立、可维护的全新代码库。

**环境要求：**
- Node.js >= 24
- 在 Claude Code 中运行，并开启浏览器访问：`claude --chrome`
- 使用 `/clone-website <url>` 命令

**工作区三文件夹约定：**
```
<project>-mirror/              # 第一阶段：编译镜像（也作资产库）
ai-website-cloner-template/    # 本引擎（第二阶段），保持纯净
<project>-clone/               # 第二阶段产物：重建出的 Next.js 源码
```

**本分支已精简为仅支持 Claude Code**，移除了所有其它 Agent/IDE 集成。

---

## Not intended for

- Phishing, impersonation, or any unlawful use.
- Passing off someone else's design, logos, brand assets, or copy as your own.
- Violating a site's terms of service. Some sites prohibit scraping or reproduction — check first.

## Credits & license

Forked from **[JCodesMore/ai-website-cloner-template](https://github.com/JCodesMore/ai-website-cloner-template)**.
Licensed under the **MIT License** — see [`LICENSE`](./LICENSE). The original copyright (© 2025 JCodesMore) is retained as required.

This fork is trimmed to **Claude Code only** and repurposed as the Stage-2 engine for the `replicating-frontend-websites` skill.
