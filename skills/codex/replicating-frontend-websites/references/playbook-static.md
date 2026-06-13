# 手册 A · 纯静态 / SSG 站

> 适用：入口 HTML 体量大、资源引用在 HTML/CSS/JS 源码里直接可见。可达上限：**字节级 1:1（L4）**。
> 实战锚点：shuchenglin-handbook.pages.dev（CF Pages 手写静态站）。

---

## Phase 1 · 初始化

```bash
export BASE="https://<host>"; export MIRROR="./mirror"
export SOFT404_SIZE=<指纹实测值>          # 见 fingerprinting.md §3
source scripts/lib.sh                      # fetch_ok / real_asset / dl / probe_seq
```

## Phase 2 · 递归镜像（主轨）

```bash
wget --mirror --page-requisites --convert-links=off --adjust-extension=off \
     --no-parent --restrict-file-names=nocontrol -e robots=off \
     --wait=0.3 --tries=3 --timeout=30 -U "Mozilla/5.0" \
     -P "$MIRROR" -nH "$BASE/"
```

要点：
- `--convert-links=off`：**保持相对路径，不改写任何链接**（站内本就相对引用时，改写反而破坏）。
- `--restrict-file-names=nocontrol`：中文/特殊字符文件名按 UTF-8 原样保存。
- 无 wget → 降级为 curl 循环（Phase 3 的提取逻辑本身就覆盖）。

## Phase 3 · 源码二次提取（wget 必有遗漏）

wget 只跟显式链接；JS 里硬编码的资源名要正则补抓：

```bash
grep -rhoE '[A-Za-z0-9_./-]+\.(png|jpe?g|webp|gif|mp4|webm|svg|json|woff2?|css|js)' \
  "$MIRROR" --include='*.html' --include='*.js' --include='*.css' 2>/dev/null \
| sed 's#^\.\./\.\./##; s#^\./##' | sort -u \
| while read -r rel; do [ -f "$MIRROR/$rel" ] || dl "$BASE/$rel" "$rel"; done
```

## Phase 4 · 参数化序列 / manifest 资源（动态命名的帧、缩略图等）

**权威参数优先，探测兜底**——这是本手册最容易翻车的地方：

1. **先在源码里找权威参数**：序列帧总数、manifest 数组等通常以参数形式写在 JS 里（如 `new Seq("seq_coming",120)`、`["f-001","f-002",…]`）。grep 出来按清单下载：
   ```bash
   # 例：manifest 数组提取
   grep -oE '"(f|m)-[0-9]{2,3}"' "$MIRROR/path/app.js" | tr -d '"' | sort -u
   ```
2. **源码找不到 → 边界探测**（连续 3 次 miss 定界 + 安全阀）：
   ```bash
   # probe_seq <url printf模板> <本地 printf模板> [start] [miss上限] [安全阀]
   probe_seq "$BASE/seq/frame_%04d.webp" "seq/frame_%04d.webp" 1 3 800
   ```
3. 实测数量与源码参数不符 → 以实测为准并记录差异。

## Phase 5 · 特殊路径

- **中文/特殊字符 URL**：下载时 URL 编码（curl 自动处理），落盘用 UTF-8 原名。
- 平台配置文件：尝试抓 `_headers`、`_redirects`、`404.html`、`favicon.ico`、`robots.txt`、`sitemap.xml`（用 `fetch_ok` 判真伪）。

## Phase 6 · 本地服务与验收

静态站无特殊头要求：

```bash
cd "$MIRROR" && python -m http.server 8080   # 或 node scripts/serve.js "$MIRROR" 8080
```

验收按 `verification.md`：本手册可达 **L1 结构 + L2 视觉 + L3 行为 + L4 字节抽检**。逐屏滚动全站、打开 DevTools Network：**零 404、零"图片/视频请求落回 text/html"**。

## 部署期注意

| 目标平台 | 处理 |
|---|---|
| CF Pages / Netlify | `_headers`/`_redirects` 原样可用 |
| Vercel | `_redirects` 改写为 `vercel.json` 的 `rewrites` |
| GitHub Pages | 不支持自定义响应头；源站依赖头时换平台 |

## 本手册风险速查

| 风险 | 处置 |
|---|---|
| soft-404 污染镜像 | 一切经 `dl()`，签名双判 |
| JS 动态命名帧漏抓 | 权威参数 → probe 兜底（上文 Phase 4） |
| 中文路径乱码/丢失 | `--restrict-file-names=nocontrol` + UTF-8 |
| 限速/封 IP | 并发≤3、`--wait 0.3`、真实 UA、断点续传 |
| 个别资源真 404 | 同尺寸占位 + `MISSING.log`，不停车 |
