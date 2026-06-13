# 手册 C · WebGL / Canvas 体验站

> 适用：canvas 主导、Three.js/WebGPU/自定义着色器、3D 资产（ktx2/draco/glb/exr）、Web Worker、音频驱动的"震撼前端"。
> 可达上限 Stage 1：**T0 资产归档 + T1 可交互镜像**。T2 原始源码（着色器/3D 原始工程）**不可逆、禁止声称已还原**；编译站完成 Stage 1 后可进行 **T2-AI AI 等价源码重建**（opt-in，用户确认），见 `references/playbook-reconstruction.md`。
> 实战锚点：www.igloo.inc（Vite + Three.js + 4 workers + wasm 解码器，Vercel 套 CF）。

---

## 为什么静态方法必败（先说服自己）

- 外壳 HTML 近空，资源 URL 由 JS **运行时拼接**（编码 manifest），静态 grep 只能看到极少数文件名（igloo 实测：1.48MB 主包里仅 4 个 worker 名可见，其余 300+ 资产全部运行时构造）。
- 资产按**交互状态懒加载**：不滚动、不点击、不解锁音频，对应请求永远不会发生。
- **结论：用 Playwright 真实"玩通"全站、录 HAR，是唯一可靠的资产枚举法。**

## Phase 1 · 静态初始化

```bash
export BASE="https://<host>"; export MIRROR="./mirror"
export SOFT404_SIZE=<指纹实测值>     # igloo 实测外壳 1410B → 取 1600
source scripts/lib.sh
dl "$BASE/" "index.html"
# 从 index.html 提取入口 JS → dl；从入口 JS grep 'name-[a-f0-9]{8}\.js' 抓 worker/chunk
```

hash 文件名以**当次抓到的 index.html 为准**，不要照抄任何文档示例（重部署即漂移）。

## Phase 2 · 穷尽交互 HAR 捕获（本手册核心）

```bash
node scripts/capture.js "$BASE/" HAR 60 1200
# 默认多视口 1920x1080 / 1366x768 / 390x844；可用 VIEWPORTS 环境变量覆盖
```

capture.js 已内置的关键动作（缺一个就漏一类资源）：
- **点击页面中心**：解锁 AudioContext（音频文件在手势之后才请求）。
- **分步滚动到底**（默认 60 步 × 1200ms）：触发滚动状态机的每一段加载。
- **遍历 hover 所有 `a`/`button`/`[role=button]`/`canvas`**：触发 project 切换等分支。
- **多视口合并**：移动端/桌面端可能加载不同档位的纹理。

## Phase 2.5 · HAR → 权威清单

```bash
bash scripts/har2urls.sh <host> HAR > ASSETS.urls
```

har2urls 会在 stderr 输出**命名空间计数**（按一级路径分组）。某命名空间为 0（如 fonts/、audio/）→ 对应交互没触发，**回 Phase 2 补交互**，不要带病进入下载。

## Phase 3 · 落盘（续传 + 校验）

```bash
while read -r url; do dl "$url" "${url#"$BASE"/}"; done < ASSETS.urls
```

`dl()` 自带：DONE.list 续传（断了重跑即可）、`real_asset` 双判（soft-200 外壳不落盘，记 MISSING.log）。

## Phase 4 · 关键依赖专项核验（漏一个=离线白屏/缺料）

| 类别 | 检查 |
|---|---|
| wasm 解码器 | `draco_decoder.wasm`、`basis_transcoder.wasm`（或站点等价物）存在且 `file` 魔数为 wasm——缺了则所有 .drc/.ktx2 解不开 |
| Web Worker | 入口 JS 里 grep 到的全部 `*worker-*.js` 已落盘 |
| 字体 | woff2 + MSDF datatexture（3D 文字站常用 ktx2 存字形图集） |
| 音频 | ogg/mp3 已落盘（没有→Phase 2 没解锁音频，回去补） |
| 3D 资产 | glb/gltf/drc/exr/ktx2 抽样 `file` 魔数核验，防 soft-200 假文件 |

## Phase 5 · 本地服务（普通静态服务器必白屏）

```bash
node scripts/serve.js "$MIRROR" 8080
```

serve.js 提供两件普通服务器没有的东西：
1. **完整 MIME 表**：`application/wasm`、`image/ktx2`、`.drc`、`.exr`、`audio/ogg`——MIME 错则 wasm 编译失败/纹理解码失败。
2. **跨源隔离头**（SharedArrayBuffer 需要）：
   - `Cross-Origin-Opener-Policy: same-origin`
   - `Cross-Origin-Embedder-Policy: require-corp`
   - `Cross-Origin-Resource-Policy: cross-origin`

确认站点未用 SAB 时可去掉 COEP；不确定就带上。

## Phase 6 · 验收

按 `verification.md`：L0（清单全落盘+核验过）→ L1（断网可跑：开场动画、主场景、零致命 Console 错误）→ L2（滚动各阶段、project 切换、音频解锁与线上一致；Network **零 404、零 soft-200**）。L3 逐帧像素属加分项，GPU/驱动差异记"已知差异"。

## ★ Stage 1 完成 → 交接门（见 `SKILL.md`）

Phase 0–6 验收过后，**强制**先发诚实交接说明：「已完成编译产物镜像（T0+T1），非可读源码」→ 本站属编译站（SPA/WebGL），询问是否进入 Stage 2 AI 等价源码重建（`references/playbook-reconstruction.md`）。用户否 → 结束；用户是 → 进 R0。

## Phase 7 · 部署（须用户确认授权）

任何平台都要在平台层注入 COOP/COEP/CORP 与 MIME（vercel.json / netlify.toml / nginx conf），或干脆带着 serve.js 跑。

## 本手册风险速查

| 风险 | 处置 |
|---|---|
| wget 只抓到空壳 | 根本不用 wget 做发现 |
| 交互分支漏触发 | 多视口+穷尽交互；命名空间计数为 0 即回补 |
| soft-200 假资产 | `real_asset` 双判，假文件删除并记账 |
| wasm/解码器缺失 | Phase 4 专项核验 |
| 音频在手势门后 | capture.js 先点击再滚动 |
| MIME/COOP 配错 | 用 serve.js，不用 python http.server |
| hash 随重部署漂移 | 捕获后尽快下完；记录抓取时间戳 |
| 限速/盾 | 真 UA、降并发、指数退避，必要时 headful |
| 版权（品牌/3D/音乐） | 默认仅本地；公网部署先授权 |
