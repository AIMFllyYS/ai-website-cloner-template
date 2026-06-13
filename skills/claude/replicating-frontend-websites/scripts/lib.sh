#!/usr/bin/env bash
# lib.sh —— 复刻通用函数库。用法: source scripts/lib.sh
#
# 必需环境变量:
#   BASE          站点根, 如 https://www.example.com (无尾斜杠)
#   MIRROR        本地镜像目录 (默认 ./mirror)
# 可选环境变量:
#   SOFT404_SIZE  soft-404 外壳大小上限字节数 (指纹脚本实测值+余量, 默认 2048)
#   UA            User-Agent

: "${UA:=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36}"
: "${SOFT404_SIZE:=2048}"
: "${MIRROR:=./mirror}"
mkdir -p "$MIRROR"

# fetch_ok <url> —— 下载前判存在性 (看响应 Content-Type + 大小, 永不看状态码)
# 注意: 期望拿到的是"资源"时用; 目标本身是 HTML 页面时不要用 (HTML 会被拒), 直接 dl。
fetch_ok() {
  local r
  r=$(curl -s -o /dev/null -A "$UA" --max-time 60 -w "%{content_type}|%{size_download}" "$1") || return 1
  case "$r" in
    text/html*) return 1 ;;   # 资源请求落回 HTML = soft-404
    *"|0")      return 1 ;;   # 空响应
    *)          return 0 ;;
  esac
}

# real_asset <本地文件> —— 落盘后校验: 小于 soft-404 签名且含 <html> 的文件是假资产
real_asset() {
  local f="$1" sz
  [ -f "$f" ] || return 1
  sz=$(wc -c <"$f")
  [ "$sz" -gt 0 ] || return 1
  if [ "$sz" -lt "$SOFT404_SIZE" ] && grep -qiI "<html" "$f" 2>/dev/null; then
    return 1
  fi
  return 0
}

# dl <url> <本地相对路径> —— 幂等下载: DONE.list 续传 + real_asset 校验 + MISSING.log 记账
dl() {
  local url="$1" rel="$2" meta
  if [ -f "$MIRROR/$rel" ] && grep -qxF "$rel" "$MIRROR/DONE.list" 2>/dev/null; then
    return 0                                    # 已下载校验过, 续传跳过
  fi
  mkdir -p "$MIRROR/$(dirname "$rel")"
  meta=$(curl -s -A "$UA" --max-time 300 --retry 2 \
         -o "$MIRROR/$rel" -w '%{http_code} %{content_type} %{size_download}' "$url")
  if real_asset "$MIRROR/$rel"; then
    echo "$rel" >>"$MIRROR/DONE.list"
    echo "OK   $rel"
  else
    echo "$rel  [$meta]" >>"$MIRROR/MISSING.log"
    rm -f "$MIRROR/$rel"                        # 假资产不落盘
    echo "MISS $url"
  fi
}

# dl_page <url> <本地相对路径> —— 专抓 HTML 页面 (跳过 real_asset 的 <html> 拒判, 只拒空文件)
dl_page() {
  local url="$1" rel="$2"
  mkdir -p "$MIRROR/$(dirname "$rel")"
  curl -s -A "$UA" --max-time 120 -o "$MIRROR/$rel" "$url"
  if [ -s "$MIRROR/$rel" ]; then echo "OK   $rel"; echo "$rel" >>"$MIRROR/DONE.list"
  else echo "$rel  [empty]" >>"$MIRROR/MISSING.log"; rm -f "$MIRROR/$rel"; echo "MISS $url"; fi
}

# probe_seq <url printf模板> <本地 printf模板> [start=1] [miss上限=3] [安全阀=800]
# 例: probe_seq "$BASE/seq/frame_%04d.webp" "seq/frame_%04d.webp"
# 逻辑: 连续 miss上限 次失败即认为到达边界; 安全阀防失控。
probe_seq() {
  local utpl="$1" ltpl="$2" i="${3:-1}" lim="${4:-3}" cap="${5:-800}" miss=0 u l
  while [ "$miss" -lt "$lim" ] && [ "$i" -le "$cap" ]; do
    # shellcheck disable=SC2059
    u=$(printf "$utpl" "$i"); l=$(printf "$ltpl" "$i")
    if fetch_ok "$u"; then dl "$u" "$l"; miss=0
    else miss=$((miss+1)); fi
    i=$((i+1))
  done
}

# report <phase号> <说明> —— 一行汇报 (铁律要求的格式)
report() {
  local done_n=0 miss_n=0
  [ -f "$MIRROR/DONE.list" ]   && done_n=$(wc -l <"$MIRROR/DONE.list")
  [ -f "$MIRROR/MISSING.log" ] && miss_n=$(wc -l <"$MIRROR/MISSING.log")
  echo "Phase $1 ✓ $2 | 资源 $done_n 个 | MISSING $miss_n 条"
}
