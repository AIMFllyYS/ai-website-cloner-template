# 1:1 前端网站复刻技能 · Frontend Website Replication Skill

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![仅供学习研究 · Learning Only](https://img.shields.io/badge/用途-仅供学习研究%20Learning%20Only-orange.svg)](#法律声明)
[![Claude · Codex · Default](https://img.shields.io/badge/Variants-Claude%20%7C%20Codex%20%7C%20Default-blueviolet)](#三个平台变体)

> **⚠️ 本项目仅供个人学习、技术研究与离线备份参考使用。**
> 任何公网再部署、商用、或声称原创，均须取得目标网站权利方的授权。镜像或重建并不转移任何版权。

**语言 / Language：[中文说明](#中文说明)（默认） · [English](#english)**

一套面向 [Claude Code](https://claude.ai/code)、[OpenAI Codex](https://developers.openai.com/codex/) 及任意合规 Agent 的**两阶段前端网站复刻技能**。Stage 1 把网站的编译产物原样下载成可交互离线镜像；Stage 2（可选，仅编译站）用 AI 把它重建成干净、可编辑的现代源码。

---

## 中文说明

### 这是什么

| 阶段 | 做什么 | 产物 | 层级 |
|---|---|---|---|
| **Stage 1 · 交互镜像** | 指纹识别 → 选手册 → 下载编译产物 → 本地服务 → 验收 | `<project>-mirror/` | T0 资产归档 + T1 离线镜像 |
| **Stage 2 · AI 等价重建**（可选，仅编译站） | 搭工作区 → clone 引擎 → 跑 `/clone-website` → 验收 | `<project>-clone/` | T2-AI 等价源码 |

```
Stage 1 · 交互镜像（默认，所有站）
  指纹 → 选手册 → 下载编译产物 → 本地服务 → 验收
        │
        ▼  ★ 交接门（强制）：诚实说明"这是编译产物镜像，不是可读源码" + 按形态分流
   ┌─ 非编译站（纯静态/手写）→ "镜像≈源码，无需 Stage 2"
   └─ 编译站（SPA/WebGL/SSR/打包）→ 引导是否进行 Stage 2
        │（用户确认后）
        ▼
Stage 2 · AI 等价源码重建（仅编译站，opt-in）
  搭 3 文件夹 → clone 引擎 → live+mirror 双源跑 /clone-website → 产物 <project>-clone/
```

### 诚实原则（核心）

Stage 2 产出的是 **「AI 等价重建（现代栈）」，不是原站打包前的原始源码**。编译/压缩产物不可逆——原模块结构、未压缩逻辑、着色器源、3D 原始工程在 build 时已永久丢失。重建在视觉与交互上对齐原站，但**任何工具都无法还原出原始工程**。所有 Stage 2 交付都必须标注「AI 等价重建，非原站原始源码」。

### 三个平台变体

`skills/` 下提供三份按各平台规范微调的变体，每份都含两个技能（`replicating-frontend-websites` + `clone-website`）：

| 变体 | 适用 Agent | 安装目录 | 触发方式 | 关键差异 |
|---|---|---|---|---|
| **`skills/claude/`** | Claude Code | `~/.claude/skills/` | 描述自动激活 / `/replicating-frontend-websites` | 含 `license` + `metadata`；`claude --chrome` 取浏览器；Task 子代理 + worktree |
| **`skills/codex/`** | OpenAI Codex | `~/.agents/skills/` | `/skills` 或 `$replicating-frontend-websites` | frontmatter 仅 `name`+`description`；shell + `apply_patch` 模型；**网络默认关闭**需手动开启；浏览器经 MCP 配置 |
| **`skills/default/`** | 任意合规 Agent | 你的 agent 技能目录 | 取决于你的 agent | 工具无关措辞；声明 `compatibility`；可移植到 Copilot CLI / Gemini CLI / Amp 等 |

### 仓库结构

```
skills/
  claude/  | codex/  | default/        # 三个平台变体，结构相同
    replicating-frontend-websites/     # ★ 主技能：Stage 1 路由 + Stage 2 交接
    │   SKILL.md
    │   references/                    # fingerprinting / playbook-{static,spa,webgl,hybrid,reconstruction} / verification / risks-degradation
    │   scripts/                       # fingerprint.sh / lib.sh / capture.js / har2urls.sh / serve.js
    └── clone-website/                 # Stage 2 引擎技能
        SKILL.md

src/                                   # Next.js 16 脚手架 —— Stage 2 引擎工程
docs/  scripts/                        # 引擎的研究输出模板与资产脚本
```

### 安装

到 [Releases 页面](../../releases/latest)下载与你的 Agent 匹配的 zip，解压到对应技能目录。

**Claude Code（Windows PowerShell）：**
```powershell
Expand-Archive skills-claude.zip "$env:USERPROFILE\.claude\skills\"
```
**OpenAI Codex（Windows PowerShell）：**
```powershell
Expand-Archive skills-codex.zip "$env:USERPROFILE\.agents\skills\"
```
**macOS / Linux（任选变体）：**
```bash
unzip skills-claude.zip   -d ~/.claude/skills/     # Claude Code
unzip skills-codex.zip    -d ~/.agents/skills/     # OpenAI Codex
unzip skills-default.zip  -d <你的-agent-技能目录>/  # 其它 Agent
```

或直接 clone 本仓库，手动复制对应变体：
```bash
git clone https://github.com/AIMFllyYS/ai-website-cloner-template
cp -r ai-website-cloner-template/skills/claude/* ~/.claude/skills/
```

### 环境要求

| 功能 | 要求 |
|---|---|
| Stage 1（镜像） | shell（bash）、Node.js（本地服务 + 捕获脚本）、wget 或 curl、对目标站的网络访问 |
| Stage 2（重建） | Node.js ≥ 24、浏览器自动化能力（Claude Code 用 `claude --chrome`；Codex / 其它用 MCP） |

> Codex 注意：网络默认关闭，抓取/下载步骤需开启 `network_access = true` 或逐次批准。

### 用法

安装后，在 Agent 会话里直接说：

```
# Stage 1 — 交互镜像
1:1 复刻这个网站：https://example.com

# Stage 2 — AI 等价源码重建（仅编译站）
复刻 https://example.com 并重建出可二次开发的源代码
```

技能会自动激活并依次走：合规声明 → 开源检查 → 指纹识别 → 选手册 → Stage 1 下载 → 硬验收 →（编译站）诚实交接 → 询问是否 Stage 2。

**Stage 2 工作区（3 文件夹）：**
```
<workspace>/
├── <project>-mirror/            # Stage 1 产物（已存在）
├── ai-website-cloner-template/  # 引擎：保持纯净作参考
└── <project>-clone/            # Stage 2 产物：复制引擎到此并跑 /clone-website
```

### 已验证案例

| 站点 | 形态 | 结果 |
|---|---|---|
| `shuchenglin-handbook.pages.dev` | 纯静态 / SSG | Stage 1 T0+T1，正确判定"无需 Stage 2" |
| `www.igloo.inc` | WebGL SPA（Vite + Three.js） | Stage 1 T0+T1 完成；Stage 2 工作区就绪，需 `claude --chrome` |

### 致谢

- **Stage 1（交互镜像 + 两阶段调度，`*/replicating-frontend-websites/`）** —— 完全由 **羽升（[AIMFllyYS](https://github.com/AIMFllyYS)）本人**设计与制作，并在 igloo.inc（Three.js/WebGL 体验站）、shuchenglin（Cloudflare Pages 静态站）等真实站点上反复验证。
- **Stage 2 引擎（`*/clone-website/` + `src/` Next.js 脚手架）** —— 源自开源贡献者 **[JCodesMore](https://github.com/JCodesMore)** 的 [ai-website-cloner-template](https://github.com/JCodesMore/ai-website-cloner-template)（MIT © 2025）；羽升在其基础上做了**适当微调**（重定位为本技能的 Stage 2 引擎、删除非必要的多 agent 配置、重写文档、三平台适配）。原 MIT 署名完整保留于 [NOTICE](NOTICE)。

### 许可证

本项目采用 **Apache License 2.0** —— 见 [LICENSE](LICENSE)。
其中 `*/clone-website/` 技能与 `src/` Next.js 脚手架衍生自 JCodesMore 的工作（MIT © 2025），署名见 [NOTICE](NOTICE)。

### 法律声明

本工具**仅供个人学习、技术研究与离线备份参考**。

- 目标站点的品牌、设计、字体、图片、3D 资产、音频、源代码可能受版权/商标等法律保护。
- **镜像网站不转移任何权利。** 公网再部署、商用、分发、或声称原创，均须取得权利方明确授权。
- 抓取请遵守 `robots.txt` 礼仪与频率限制，不对源站造成压力。
- Stage 2 的 AI 等价重建**不消除**目标站的内容与设计版权，再发布仍需授权。
- 作者对任何滥用不承担责任。使用即代表你同意仅将其用于合法、非商业的个人用途。

---

## English

A two-stage frontend website replication skill for [Claude Code](https://claude.ai/code), [OpenAI Codex](https://developers.openai.com/codex/), and any spec-compliant agent. Stage 1 downloads the compiled production output as an interactive offline mirror. Stage 2 (opt-in, compiled sites only) uses AI to rebuild the site into clean, editable modern source code.

### What it is

| Stage | What it does | Output | Tier |
|---|---|---|---|
| **Stage 1 · Interactive Mirror** | Fingerprint → select playbook → download compiled output → local server → verify | `<project>-mirror/` | T0 asset archive + T1 interactive mirror |
| **Stage 2 · AI Equivalent Rebuild** (opt-in, compiled sites only) | Set up workspace → clone engine → run `/clone-website` → verify | `<project>-clone/` | T2-AI equivalent source |

### Honesty Principle (core)

Stage 2 produces an **AI equivalent rebuild on a modern stack — NOT the target's original pre-bundle source code.** Compiled/minified output is irreversible; original modules, un-minified logic, shaders, and 3D project files are permanently lost at build time. The rebuild aligns visually and interactively with the original but **no tool can recover the original project**. Every Stage 2 output must be labeled *"AI equivalent rebuild, not original source."*

### Three Platform Variants

`skills/` ships three variants tuned to each platform's conventions; each contains both skills (`replicating-frontend-websites` + `clone-website`):

| Variant | Agent | Install to | Invoke | Key differences |
|---|---|---|---|---|
| **`skills/claude/`** | Claude Code | `~/.claude/skills/` | auto from description / `/replicating-frontend-websites` | `license` + `metadata` frontmatter; `claude --chrome` for browser; Task subagents + worktrees |
| **`skills/codex/`** | OpenAI Codex | `~/.agents/skills/` | `/skills` or `$replicating-frontend-websites` | frontmatter trimmed to `name`+`description`; shell + `apply_patch` model; **network OFF by default**; browser via configured MCP |
| **`skills/default/`** | any compliant agent | your agent's skills dir | depends on your agent | tool-agnostic phrasing; declares `compatibility`; portable to Copilot CLI / Gemini CLI / Amp / etc. |

### Repository Structure

```
skills/
  claude/  | codex/  | default/        # three variants, identical layout
    replicating-frontend-websites/     # main skill: Stage 1 routing + Stage 2 handoff
    │   SKILL.md
    │   references/                    # fingerprinting / playbooks / verification / risks-degradation
    │   scripts/                       # fingerprint.sh / lib.sh / capture.js / har2urls.sh / serve.js
    └── clone-website/                 # Stage 2 engine skill
        SKILL.md

src/                                   # Next.js 16 scaffold — the Stage 2 engine project
docs/  scripts/                        # engine research templates + asset scripts
```

### Installation

Download the zip matching your agent from the [Releases page](../../releases/latest) and extract it to the right skills directory.

```bash
# macOS / Linux
unzip skills-claude.zip   -d ~/.claude/skills/      # Claude Code
unzip skills-codex.zip    -d ~/.agents/skills/      # OpenAI Codex
unzip skills-default.zip  -d <your-agent-skills-dir>/  # any other agent
```
```powershell
# Windows PowerShell — Claude Code
Expand-Archive skills-claude.zip "$env:USERPROFILE\.claude\skills\"
```

Or clone and copy manually:
```bash
git clone https://github.com/AIMFllyYS/ai-website-cloner-template
cp -r ai-website-cloner-template/skills/claude/* ~/.claude/skills/
```

### Requirements

| Feature | Requirement |
|---|---|
| Stage 1 (mirror) | shell (bash), Node.js, wget or curl, network access to the target |
| Stage 2 (rebuild) | Node.js >= 24, browser automation (`claude --chrome` for Claude Code; MCP for Codex/others) |

> Codex note: network is OFF by default — enable `network_access = true` or approve prompts for the download steps.

### Usage

```
# Stage 1 — interactive mirror
1:1 clone this website: https://example.com

# Stage 2 — AI equivalent source rebuild (compiled sites only)
Clone https://example.com and rebuild editable source code
```

Stage 2 workspace (3 folders):
```
<workspace>/
├── <project>-mirror/            # Stage 1 output (already exists)
├── ai-website-cloner-template/  # engine: keep pristine as reference
└── <project>-clone/            # Stage 2 output: copy engine here, run /clone-website
```

### Verified Test Cases

| Site | Type | Result |
|---|---|---|
| `shuchenglin-handbook.pages.dev` | Pure static / SSG | Stage 1 T0+T1, correctly routes "no Stage 2 needed" |
| `www.igloo.inc` | WebGL SPA (Vite + Three.js) | Stage 1 T0+T1 complete; Stage 2 workspace ready, needs `claude --chrome` |

### Credits

- **Stage 1** (interactive mirror + two-stage orchestration, `*/replicating-frontend-websites/`) — designed and built **entirely by 羽升 ([AIMFllyYS](https://github.com/AIMFllyYS))**, and validated on real sites including igloo.inc (Three.js/WebGL) and a Cloudflare Pages static site.
- **Stage 2 engine** (`*/clone-website/` + the `src/` Next.js scaffold) — derived from open-source contributor **[JCodesMore](https://github.com/JCodesMore)**'s [ai-website-cloner-template](https://github.com/JCodesMore/ai-website-cloner-template) (MIT © 2025), with **appropriate fine-tuning** on top (repurposed as this skill's Stage 2 engine, removed non-essential multi-agent configs, rewrote docs, added three-platform variants). The original MIT attribution is preserved in [NOTICE](NOTICE).

### License

Licensed under the **Apache License 2.0** — see [LICENSE](LICENSE). The `*/clone-website/` skill and `src/` scaffold are derived from JCodesMore's work (MIT © 2025) — see [NOTICE](NOTICE).

### Legal Notice

This tool is for **personal learning, technical research, and offline archiving only**.

- A target site's brand, design, fonts, images, 3D assets, audio, and source code may be protected by copyright and trademark law.
- **Mirroring a site transfers no rights.** Public redeployment, commercial use, distribution, or claiming authorship requires explicit authorization from the rights holder.
- Respect `robots.txt`, rate limits, and server load.
- Stage 2's AI equivalent rebuild does **not** eliminate the target's content and design copyright; re-publishing still requires authorization.
- The authors assume no liability for misuse. By using this skill you agree to use it solely for lawful, non-commercial, personal purposes.
