#!/usr/bin/env bash
# fingerprint.sh —— Phase 0 站点指纹识别 (纯只读, 约 3-5 个请求)
# 用法: bash scripts/fingerprint.sh <url>
# 输出: JSON {platform, soft404, archetype, recommended_playbook, signals}
# 注意: 这是初筛, 结论须按 references/fingerprinting.md 人工复核。
set -u
URL="${1:?用法: fingerprint.sh <url>}"
URL="${URL%/}"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---------- 1) 根页面 + 响应头 ----------
if ! curl -sS -L -A "$UA" --max-time 30 -D "$TMP/root.h" -o "$TMP/root.html" "$URL/"; then
  echo "{\"error\":\"root fetch failed\",\"url\":\"$URL\"}"; exit 1
fi
ROOT_SIZE=$(wc -c <"$TMP/root.html")
HDRS=$(tr -d '\r' <"$TMP/root.h" | tr '[:upper:]' '[:lower:]')

platform="unknown"
echo "$HDRS" | grep -Eq '^x-vercel-id:|^server: *vercel'   && platform="vercel"
echo "$HDRS" | grep -Eq '^x-nf-request-id:'                && platform="netlify"
echo "$HDRS" | grep -Eq '^server: *github\.com'            && platform="github-pages"
echo "$HDRS" | grep -Eq '^server: *amazons3|^x-amz-'       && platform="s3-cdn"
if echo "$HDRS" | grep -Eq '^server: *cloudflare|^cf-ray:'; then
  if [ "$platform" = "unknown" ]; then platform="cloudflare"; else platform="$platform-behind-cloudflare"; fi
fi
if [ "$platform" = "unknown" ]; then
  sv=$(echo "$HDRS" | grep -m1 '^server:' | sed 's/^server: *//')
  [ -n "$sv" ] && platform="$sv"
fi

# ---------- 2) soft-404 标定 (请求一个肯定不存在的路径) ----------
probe="__fp_probe_$$_not_here.bin"
meta=$(curl -sS -A "$UA" --max-time 30 -o "$TMP/404.body" -w '%{http_code}|%{content_type}' "$URL/$probe" 2>/dev/null || echo "000|")
s404_code=${meta%%|*}; s404_ct=${meta#*|}
s404_size=$(wc -c <"$TMP/404.body" 2>/dev/null || echo 0)
soft404="false"
if [ "$s404_code" = "200" ]; then case "$s404_ct" in text/html*) soft404="true";; esac; fi

# ---------- 3) 形态判别 ----------
refs=$(grep -oE '(src|href)="[^"]+\.(css|js|png|jpe?g|webp|gif|svg|mp4|webm|woff2?)' "$TMP/root.html" | wc -l)
hydration=$(grep -cE 'id="__next"|data-reactroot|__NUXT__|data-server-rendered' "$TMP/root.html" || true)
entry_src=$(grep -oE '<script[^>]+type="module"[^>]+src="[^"]+"' "$TMP/root.html" \
            | grep -oE 'src="[^"]+"' | head -1 | sed 's/^src="//; s/"$//')

webgl_hits=0; api_hits=0; worker_hits=0
fetch_js() { # $1=url $2=outfile
  curl -sS -A "$UA" --max-time 60 -o "$2" "$1" 2>/dev/null
}
resolve() { # $1=ref $2=base-url-of-document
  case "$1" in
    http*) echo "$1" ;;
    /*)    echo "$URL$1" ;;
    ./*)   echo "${2%/*}/${1#./}" ;;
    *)     echo "${2%/*}/$1" ;;
  esac
}
if [ -n "$entry_src" ]; then
  eurl=$(resolve "$entry_src" "$URL/x")
  fetch_js "$eurl" "$TMP/entry.js"
  scan() { grep -ioE 'webgl|three\.|ktx2|draco|\.wasm|getContext\(.webgl' "$1" | wc -l; }
  webgl_hits=$(scan "$TMP/entry.js")
  worker_hits=$(grep -oE '[A-Za-z0-9_]*worker[A-Za-z0-9_-]*\.js' "$TMP/entry.js" | wc -l)
  api_hits=$(grep -oE '(fetch|axios)\(|/api/|graphql' "$TMP/entry.js" | wc -l)
  # 入口很小且引用更深 chunk → 追一层最大命中
  if [ "$webgl_hits" -eq 0 ] && [ "$(wc -c <"$TMP/entry.js")" -lt 50000 ]; then
    sub=$(grep -oE '\./[A-Za-z0-9_]+-[A-Za-z0-9_]{8}\.js' "$TMP/entry.js" | head -1)
    if [ -n "$sub" ]; then
      fetch_js "$(resolve "$sub" "$eurl")" "$TMP/chunk.js"
      [ -s "$TMP/chunk.js" ] && {
        webgl_hits=$(scan "$TMP/chunk.js")
        worker_hits=$((worker_hits + $(grep -oE '[A-Za-z0-9_]*worker[A-Za-z0-9_-]*\.js' "$TMP/chunk.js" | wc -l) ))
        api_hits=$((api_hits + $(grep -oE '(fetch|axios)\(|/api/|graphql' "$TMP/chunk.js" | wc -l) ))
      }
    fi
  fi
fi

# ---------- 4) 分类 ----------
if [ -n "$entry_src" ] && [ "$ROOT_SIZE" -lt 3000 ]; then
  if [ "$webgl_hits" -gt 0 ]; then archetype="webgl-spa"; playbook="playbook-webgl"
  else archetype="dom-spa"; playbook="playbook-spa"; fi
elif [ "$hydration" -gt 0 ]; then
  archetype="ssr-hydration"; playbook="playbook-spa"
elif [ "$refs" -ge 5 ]; then
  archetype="static"; playbook="playbook-static"
elif [ -n "$entry_src" ]; then
  archetype="spa-uncertain"; playbook="playbook-spa"
else
  archetype="unknown"; playbook="manual-triage"
fi
hybrid="false"; [ "$api_hits" -gt 2 ] && hybrid="true"

# ---------- 5) 输出 ----------
cat <<EOF
{
  "url": "$URL",
  "platform": "$platform",
  "soft404": { "present": $soft404, "status": "$s404_code", "content_type": "$s404_ct", "shell_size": $s404_size,
               "suggested_SOFT404_SIZE": $(( s404_size + s404_size / 10 + 64 )) },
  "archetype": "$archetype",
  "hybrid_api_suspected": $hybrid,
  "recommended_playbook": "$playbook",
  "signals": { "root_html_bytes": $ROOT_SIZE, "visible_resource_refs": $refs,
               "module_entry": "${entry_src:-none}", "webgl_hits": $webgl_hits,
               "worker_refs": $worker_hits, "api_hits": $api_hits, "hydration_markers": $hydration },
  "note": "初筛结论, 须按 references/fingerprinting.md 人工复核; soft404.present=true 时一切存在性判断走 lib.sh 双判"
}
EOF
