// Same-origin local Flutter web hosting; no CORS or token-storage changes.
const http = require('node:http');
const fs = require('node:fs/promises');
const path = require('node:path');

async function serve({ root = path.resolve(__dirname, '../build/web'), port = 4300, backend = 'http://127.0.0.1:3000' } = {}) {
  const target = new URL(backend);
  if (target.protocol !== 'http:' || target.hostname !== '127.0.0.1' || target.username || target.password || target.pathname !== '/' || target.search || target.hash) throw new Error('Backend must be a plain loopback HTTP origin');
  root = path.resolve(root);
  await fs.access(path.join(root, 'index.html'));
  const server = http.createServer(async (req, res) => {
    // Reject DNS rebinding and forwarded public proxies. This is a local tool.
    const host = req.headers.host || '';
    if (!/^(127\.0\.0\.1|localhost)(:\d+)?$/.test(host) || req.headers.forwarded || Object.keys(req.headers).some(k => k.startsWith('x-forwarded-'))) { res.writeHead(403); res.end(); return; }
    if (req.headers.origin && req.headers.origin !== `http://${host}`) { res.writeHead(403); res.end(); return; }
    if (req.url.startsWith('/api/v1/') || req.url.startsWith('/health/')) {
      const upstream = http.request(new URL(req.url, target), { method: req.method, headers: req.headers }, reply => { res.writeHead(reply.statusCode, reply.headers); reply.pipe(res); });
      upstream.setTimeout(20000, () => upstream.destroy());
      upstream.on('error', () => { if (!res.headersSent) { res.writeHead(503, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }); res.end(JSON.stringify({ statusCode: 503, code: 'DEPENDENCY_UNAVAILABLE', message: 'Local backend unavailable' })); } else res.destroy(); });
      req.pipe(upstream); return;
    }
    if (req.method !== 'GET' && req.method !== 'HEAD') { res.writeHead(405); res.end(); return; }
    try {
      const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
      let file = path.resolve(root, '.' + pathname);
      if (file !== root && !file.startsWith(root + path.sep)) { res.writeHead(403); res.end(); return; }
      try { if (!(await fs.stat(file)).isFile()) file = path.join(root, 'index.html'); }
      catch { file = path.join(root, 'index.html'); }
      // Do not follow a file symlink outside the selected build directory.
      const real = await fs.realpath(file);
      if (!real.startsWith(root + path.sep)) { res.writeHead(403); res.end(); return; }
      const types = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.css': 'text/css', '.png': 'image/png', '.svg': 'image/svg+xml', '.ttf': 'font/ttf' };
      res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store' });
      res.end(req.method === 'HEAD' ? undefined : await fs.readFile(real));
    } catch { res.writeHead(404); res.end(); }
  });
  await new Promise((resolve, reject) => { server.once('error', reject); server.listen(port, '127.0.0.1', resolve); });
  return server;
}
module.exports = { serve };
if (require.main === module) serve({ port: Number(process.env.FLUTTER_WEB_PORT || 4300), backend: process.env.LOCAL_API_ORIGIN || 'http://127.0.0.1:3000' }).then(server => {
  console.log(`Local Flutter web: http://127.0.0.1:${server.address().port} (same-origin API proxy)`);
  for (const signal of ['SIGTERM', 'SIGINT']) process.once(signal, () => { server.closeAllConnections(); server.close(() => process.exit(0)); });
}).catch(() => { console.error('Local Flutter server failed; check build directory, loopback backend origin and free port.'); process.exitCode = 1; });
