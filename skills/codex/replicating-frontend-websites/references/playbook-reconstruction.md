# 手册 S2 · 源码重建（AI 等价重建）

> 适用：Stage 1 已交付 `<project-name>-mirror/`（T0+T1）后，用户明确要**可编辑源码**。仅限**编译产物站**（SPA/WebGL/SSR/打包站）。
> 可达上限：**T2-AI 等价源码**——视觉 & 交互对齐、现代栈可编辑工程。**非原站原始源码**（编译后的产物不可逆，原模块结构/未压缩逻辑/着色器源/3D 原始工程在 build 时已永久丢失）。
> 引擎：`ai-website-cloner-template`（用户 fork，跑在 Claude Code 内的 AI 重写引擎，**非反编译/非 source-map 恢复**）。
> 产物：`<project-name>-clone/`——可运行的 Next.js 16 / React 19 / TypeScript / Tailwind v4 / shadcn-ui 工程。

---

## §1 何时用 / 何时不用

| 情形 | 处置 |
|---|---|
| 编译产物站（SPA/WebGL/SSR/bundled）+ 用户要可编辑源码 | ✅ 进本手册 |
| 仅完成 Stage 1，用户未确认要源码 | ⛔ 停在 T1，不主动启动 |
| Stage 1 验收未过 | ⛔ 先把 mirror 验收过了再说（`references/verification.md` §2） |
| **非编译站**（纯静态/手写站，源码即产物） | ⛔ 告知用户"镜像产物≈源码，**无需 stage2**"，停。最多做可选的轻量清理（格式化/去无关脚本） |

**触发硬条件（两者同时满足才动手）：① Stage 1 验收通过；② 用户明确确认要可编辑源码。** 缺任一不启动。

## §2 前置条件检查（动手前逐项核）

| 条件 | 核验 | 不满足 |
|---|---|---|
| Node ≥ 24 | `node -v` | → §7 降级，交付 Stage 1 镜像 |
| Claude Code 有浏览器访问 | 经 `Codex（配置好浏览器自动化 MCP）` 启动，可截图/查 DOM | → §7 降级 |
| 公开 fork 可 clone | `git ls-remote https://github.com/AIMFllyYS/ai-website-cloner-template` | 网络/权限受限 → §7 降级 |
| live URL 可达 | 线上仍在线、未大改版 | 失败 → 退化为 **mirror-only**（仍可跑，但 QA 基准只剩 mirror） |

任一硬条件（Node/浏览器/clone）不满足 → **不要硬上**，按 §7 直接把 Stage-1 镜像作为交付，并明确说明未做源码重建。

## §3 工作区 3 文件夹搭建

```
<workspace>/
├── <project-name>-mirror/          # Stage 1 产物（已存在）
├── ai-website-cloner-template/     # 引擎：克隆于此，保持纯净作引用/参考
└── <project-name>-clone/           # Stage 2 产物：在此实例化引擎并跑 clone-website 技能
```

```bash
# 1. 取引擎（保持纯净，勿在此目录直接改/跑重建）
git clone https://github.com/AIMFllyYS/ai-website-cloner-template

# 2. 实例化到 clone 目录（复制模板，或重新 clone 进去）
cp -r ai-website-cloner-template <project-name>-clone
cd <project-name>-clone
npm install

# 3. 在 clone 目录内，于 Claude Code（Codex（配置好浏览器自动化 MCP））中执行
clone-website 技能（/skills 或 $clone-website <target-url>）
```

**纪律**：引擎副本永远纯净（作机制参考 + 可重新实例化）；真正的重建只发生在 `<project-name>-clone/`。资产优先**复用** `<project-name>-mirror/`，不再回打服务器。

## §4 引擎工作机制（5 阶段映射到本流程）

引擎原生 5 阶段：Reconnaissance → Foundation → Component Specs → Parallel Build → Assembly & QA。映射为本手册 R0–R4：

| 阶段 | 内容 | 输入源 / 复用 |
|---|---|---|
| **R0 搭建+取引擎** | 建 3 文件夹；clone fork；实例化到 `-clone/`；确认 §2 前置 | — |
| **R1 跑 cloner 重建** | 在 `-clone/` 跑 `clone-website 技能（/skills 或 $clone-website <url>）`：截图+查 DOM+抽取 design tokens+测交互（Recon）→ 定字体/配色/下资产（Foundation）→ 逐区生成含精确 computed CSS 的规格（Component Specs）→ 并行派发 builder agent，各在独立 git worktree 重建一个 UI 区块（Parallel Build） | **live URL + mirror 双源**：cloner 原生抓 live；live 挂/改版则退化 mirror-only |
| **R2 资产复用自 mirror** | 把已下载的图/视频/字体从 `<project-name>-mirror/` 直接接入工程，**而非**重新打服务器；缺料才回 live 补 | mirror 作**资产库** |
| **R3 QA 逐区 diff + check** | 合并组件（Assembly & QA）：逐区视觉对照 mirror/live；`npm run check`（lint+typecheck+build）必须全过 | mirror 作**视觉基准**逐区 diff |
| **R4 诚实交付** | 按 §5 标注 T2-AI；给诚实声明；附验收结果（§6） | — |

每阶段一行汇报：`R<N> ✓ <完成项> | 区块 X/Y | check <pass/fail> | 下一步 <...>`。

## §5 诚实标注（T2-AI）

产物是 **AI 等价重建（现代栈），非原站原始源码**。编译产物不可逆——原模块结构、未压缩逻辑、着色器源、3D 原始工程在 build 时已永久丢失，**无法**从 minified 产物倒推出原始工程。

**硬规则：禁止声称"还原了原站源码"。** 与 `SKILL.md` 铁律 #4、`references/verification.md` §1（T2 / T2-AI 定义）一致——本手册的 T2-AI 是"等价重建"，不等于"原始源码 T2"。

**诚实声明模板（必须原样交付给用户）：**

```
本交付为「AI 等价重建（现代栈）」，非原站原始源码。

- 实现方式：由 AI 依据线上站点的截图/DOM/computed CSS 重新实现，视觉与交互对齐原站。
- 技术栈：Next.js 16 / React 19 / TypeScript / Tailwind CSS v4 / shadcn-ui（与原站技术栈无关）。
- 明确不包含：原站打包前的原始模块结构、未压缩业务逻辑、着色器源码、3D 原始工程文件
  ——这些在原站 build/压缩时已不可逆地丢失，任何工具都无法还原。
- 资产（图片/视频/字体）来自 Stage 1 离线镜像，版权归原权利方。
- 用途：本地/学习/二次开发起点。公网部署或商用须取得权利方授权。
```

## §6 验收（Stage 2 门槛，配合 `references/verification.md`）

| 项 | 标准 | 验证 |
|---|---|---|
| 可运行 | `npm run dev` 起得来，首屏正常渲染 | 浏览器手测 |
| 工程健康 | `npm run check`（lint + typecheck + build）**全过** | 命令输出 |
| 视觉对齐 | 逐区块与 `mirror/`（或 live）并排对照，关键区块对齐 | 截图叠加，逐 section |
| 资产复用 | 图/视频/字体取自 `<project-name>-mirror/`，非重新打服务器 | 工程资产路径核对 |
| 诚实标注 | §5 声明已交付；交付物标注 **T2-AI 等价重建** | 交付报告 |

未过上述任一项不得宣称 Stage 2 完成。视觉偏差大 → 回 R1/R3 复跑或修；仍偏 → §7 降级。

## §7 降级矩阵（Stage 2）

| 触发 | 处置 |
|---|---|
| Node < 24 | 不启动 Stage 2；交付 Stage-1 镜像，明确说明"未做源码重建（环境不满足）" |
| 无浏览器访问 | 同上；提示用户经 `Codex（配置好浏览器自动化 MCP）` 重启后可再来 |
| cloner 运行失败/中断 | 保留已产出区块；不可恢复 → 回退交付 Stage-1 镜像，说明未完成源码重建 |
| live 挂/改版 | 退化 **mirror-only**：以 mirror 为唯一基准重建 + QA；在交付中标注基准为镜像快照 |
| 重建视觉偏差大、修不收敛 | 回退交付 Stage-1 镜像（T0+T1），明确"源码重建未达标，未交付" |

**降级铁律**：任何降级都要**显式告诉用户"源码重建未完成/未做"**，并交付仍然可用的 Stage-1 镜像作为兜底。降级处置通则见 `references/risks-degradation.md`。

## 本手册风险速查

| 风险 | 处置 |
|---|---|
| 把 T2-AI 说成"还原原始源码" | 绝对禁止；按 §5 标注，铁律 #4 |
| 在引擎目录里直接改/跑 | 引擎保持纯净；只在 `-clone/` 动手 |
| 重新打服务器下资产 | 优先复用 mirror 资产库（§4 R2） |
| 对非编译站启动 stage2 | 先判形态；非编译站告知"无需 stage2" |
| Node/浏览器不满足硬上 | 按 §7 降级，不硬上 |
| live 改版后仍当基准 | 退化 mirror-only，标注快照基准 |
| `npm run check` 不过就交付 | check 全过才算工程健康（§6） |
