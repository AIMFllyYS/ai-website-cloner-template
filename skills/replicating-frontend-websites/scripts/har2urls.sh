#!/usr/bin/env bash
# har2urls.sh —— 从 HAR 提取同域资源清单 + 命名空间计数
# 用法: bash scripts/har2urls.sh <host> <har目录> > ASSETS.urls
# 例:  bash scripts/har2urls.sh www.example.com HAR > ASSETS.urls
# 清单输出到 stdout; 命名空间计数输出到 stderr (某命名空间为 0 → 回捕获阶段补交互)
set -u
HOST="${1:?用法: har2urls.sh <host> <har目录>}"
DIR="${2:?用法: har2urls.sh <host> <har目录>}"

command -v jq >/dev/null || { echo "需要 jq" >&2; exit 1; }
ls "$DIR"/*.har >/dev/null 2>&1 || { echo "目录 $DIR 下没有 .har 文件" >&2; exit 1; }

URLS=$(jq -r '.log.entries[].request.url' "$DIR"/*.har \
       | grep -F "://$HOST/" | sed 's/[?#].*$//' | sort -u)

echo "$URLS"

{
  echo "—— 命名空间计数 (一级路径) ——"
  echo "$URLS" | awk -F'/' '{print ($4=="" ? "(root)" : $4)}' | sort | uniq -c | sort -rn
  echo "—— 扩展名计数 ——"
  echo "$URLS" | grep -oE '\.[a-z0-9]{1,5}$' | sort | uniq -c | sort -rn
  echo "总计: $(echo "$URLS" | grep -c .) 条"
} >&2
