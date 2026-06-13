#!/usr/bin/env node
// serve.js —— 复刻验收专用本地服务器
// 用法: node scripts/serve.js [root=.] [port=8080] [--spa]
//   --spa  未命中路径回退 index.html (history 路由的 SPA 必需)
// 普通静态服务器 (python -m http.server) 缺两样东西, WebGL 站会白屏:
//   1. wasm/ktx2/drc/exr/ogg 的正确 MIME
//   2. SharedArrayBuffer 需要的 COOP/COEP/CORP 跨源隔离头
const http = require('http');
const fs = require('fs');
const p = require('path');

const args = process.argv.slice(2);
const spa = args.includes('--spa');
const pos = args.filter(a => a !== '--spa');
const root = p.resolve(pos[0] || '.');
const port = parseInt(pos[1] || '8080', 10);

const MIME = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.css': 'text/css', '.json': 'application/json', '.map': 'application/json',
  '.wasm': 'application/wasm',
  '.ktx2': 'image/ktx2', '.basis': 'application/octet-stream',
  '.drc': 'application/octet-stream', '.glb': 'model/gltf-binary', '.gltf': 'model/gltf+json',
  '.exr': 'image/x-exr', '.hdr': 'application/octet-stream',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp',
  '.gif': 'image/gif', '.svg': 'image/svg+xml', '.ico': 'image/x-icon', '.avif': 'image/avif',
  '.mp4': 'video/mp4', '.webm': 'video/webm',
  '.ogg': 'audio/ogg', '.mp3': 'audio/mpeg', '.wav': 'audio/wav',
  '.woff2': 'font/woff2', '.woff': 'font/woff', '.ttf': 'font/ttf', '.otf': 'font/otf',
  '.txt': 'text/plain; charset=utf-8', '.xml': 'application/xml',
};
const HEADERS = {
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Cross-Origin-Embedder-Policy': 'require-corp',
  'Cross-Origin-Resource-Policy': 'cross-origin',
  'Cache-Control': 'no-store',
};

function send(res, file) {
  fs.readFile(file, (e, d) => {
    if (e) { res.writeHead(404); return res.end('404'); }
    res.writeHead(200, { 'Content-Type': MIME[p.extname(file).toLowerCase()] || 'application/octet-stream', ...HEADERS });
    res.end(d);
  });
}

http.createServer((req, res) => {
  let rel = decodeURIComponent((req.url || '/').split('?')[0]);
  if (rel.endsWith('/')) rel += 'index.html';
  const file = p.join(root, rel);
  if (!file.startsWith(root)) { res.writeHead(403); return res.end(); }   // 防目录穿越
  fs.stat(file, (e, st) => {
    if (!e && st.isFile()) return send(res, file);
    if (!e && st.isDirectory()) return send(res, p.join(file, 'index.html'));
    if (spa) return send(res, p.join(root, 'index.html'));                // SPA fallback
    res.writeHead(404); res.end('404');                                   // 诚实 404, 便于验收盯 Network
  });
}).listen(port, () => console.log(`http://localhost:${port}  root=${root}  spa=${spa}`));
