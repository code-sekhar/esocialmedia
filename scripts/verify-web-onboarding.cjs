// C2 only: verifies separately compiled test/onboarding_browser_app.dart.
// No real backend request, DB write, production READY fixture or application activation flag.
// Runs only a loopback static server and an isolated headless Chrome profile.
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const os = require('node:os');
const http = require('node:http');
const { spawn } = require('node:child_process');
const { setTimeout: delay } = require('node:timers/promises');

async function main() {
  const root=path.resolve('build/c2-contract-browser'); const output='/tmp/eastalya-c2-browser'; const label='c2';
  assert.ok(root && output && label);
  await fs.mkdir(output, { recursive: true });
  const types = { '.js': 'text/javascript', '.css': 'text/css', '.html': 'text/html', '.ico': 'image/x-icon', '.wasm': 'application/wasm', '.json': 'application/json', '.png': 'image/png', '.ttf': 'font/ttf' };
  const server = http.createServer(async (req, res) => {
    try {
      let file = path.resolve(root, '.' + new URL(req.url, 'http://localhost').pathname);
      if (!file.startsWith(path.resolve(root) + path.sep)) file = path.join(root, 'index.html');
      try { if (!(await fs.stat(file)).isFile()) file = path.join(root, 'index.html'); }
      catch { file = path.join(root, 'index.html'); }
      const data = await fs.readFile(file);
      res.setHeader('Content-Type', types[path.extname(file)] || 'application/octet-stream');
      res.end(data);
    } catch { res.statusCode = 500; res.end(); }
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const url = `http://127.0.0.1:${server.address().port}`;
  const userData = await fs.mkdtemp(path.join(os.tmpdir(), 'eastalya-chrome-'));
  const chrome = spawn(process.env.CHROME_BIN || '/usr/bin/google-chrome', ['--headless=new', '--remote-debugging-port=0', `--user-data-dir=${userData}`, '--no-first-run', '--no-default-browser-check', 'about:blank'], { stdio: 'ignore' });
  let ws;
  const pending = new Map();
  const errors = [];
  try {
    let port;
    for (let i = 0; i < 100 && !port; i++) {
      try { port = Number((await fs.readFile(path.join(userData, 'DevToolsActivePort'), 'utf8')).split('\n')[0]); } catch { await delay(50); }
    }
    assert.ok(port, 'Chrome did not initialize');
    const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
    ws = new WebSocket(targets.find(t => t.type === 'page').webSocketDebuggerUrl);
    await new Promise((resolve, reject) => { ws.addEventListener('open', resolve, { once: true }); ws.addEventListener('error', reject, { once: true }); });
    let id = 0;
    ws.addEventListener('message', event => {
      const message = JSON.parse(event.data);
      if (message.id) {
        const waiter = pending.get(message.id); pending.delete(message.id);
        if (message.error) waiter.reject(new Error(message.error.message)); else waiter.resolve(message.result);
      } else if (message.method === 'Runtime.exceptionThrown') errors.push('runtime exception');
      else if (message.method === 'Runtime.consoleAPICalled' && message.params.type === 'error') errors.push('console error');
    });
    const send = (method, params = {}) => new Promise((resolve, reject) => { const n = ++id; pending.set(n, { resolve, reject }); ws.send(JSON.stringify({ id: n, method, params })); });
    await send('Page.enable'); await send('Runtime.enable');
    const evalValue=async expression=>{const r=await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw new Error('Flutter browser evaluation failed');return r.result.value;};
    const wait=async expr=>{for(let n=0;n<300;n++){if(await evalValue(expr))return;await delay(100);}throw new Error('Flutter contract-browser checkpoint timed out');};
    const results=[];
    await send('Page.navigate',{url});
    await wait("!!document.querySelector('flutter-view')");
    await delay(3500);
    await evalValue("document.querySelector('flt-semantics-placeholder')?.click()");
    await wait("[...document.querySelectorAll('flt-semantics')].some(e=>(e.textContent+' '+e.getAttribute('aria-label')).includes('Your astrology onboarding'))");
    const clickText=async value=>{await evalValue(`(()=>{const es=[...document.querySelectorAll('flt-semantics')];const e=es.filter(e=>e.textContent.trim()===${JSON.stringify(value)}||e.getAttribute('aria-label')===${JSON.stringify(value)}).at(-1);if(!e)throw new Error('Missing fixture control');e.click();})()`);await delay(500);};
    for(const [width,height] of [[320,800],[768,1024],[1440,900]]) {
      await send('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});await delay(700);
      const shot=await send('Page.captureScreenshot',{format:'png'});await fs.writeFile(path.join(output,`${label}-${width}-consent.png`),Buffer.from(shot.data,'base64'));
      assert.equal(await evalValue('localStorage.length+sessionStorage.length'),0);
      results.push({width,height,screen:'synthetic onboarding consent',memoryOnly:true});
    }
    const ui=await evalValue("[...document.querySelectorAll('flt-semantics')].map(e=>({text:e.textContent.trim(),label:e.getAttribute('aria-label'),role:e.getAttribute('role'),checked:e.getAttribute('aria-checked')})).filter(e=>e.role==='checkbox')");
    await fs.writeFile(path.join(output,'checkbox-semantics.json'),JSON.stringify(ui,null,2));assert.equal(ui.length,3);const controls=ui.filter(e=>e.text.includes('explicitly accept')||e.text.includes('attest')||e.label?.includes('explicitly accept')||e.label?.includes('attest'));assert.equal(new Set(controls.map(e=>e.label||e.text)).size,2);assert(controls.every(e=>e.checked==='false'));
    // Native semantics click tests consent without introducing a test activation flag.
    await clickText('I have read this notice and explicitly accept it.');
    await clickText('I explicitly attest that I am an adult. This is self-declared, not verified age assurance.');
    await clickText('Grant consent');
    await wait("[...document.querySelectorAll('flt-semantics')].some(e=>(e.textContent+' '+e.getAttribute('aria-label')).includes('Do you know your exact birth time?'))");
    assert.equal(await evalValue('localStorage.length+sessionStorage.length'),0);
    results.push({screen:'consent grants via semantics reveal literal birth form',synthetic:true});
    await fs.writeFile(path.join(output,'c2-details.png'),Buffer.from((await send('Page.captureScreenshot',{format:'png'})).data,'base64'));
    assert.deepEqual(errors, []);
    await fs.writeFile(path.join(output, `${label}.json`), JSON.stringify({ checks: results, runtimeErrors: errors }, null, 2));
    console.log(`Flutter browser: ${results.length} route/viewport cases passed; no runtime errors`);
  } finally {
    if (ws) ws.close();
    chrome.kill('SIGTERM');
    await new Promise(resolve => chrome.once('exit', resolve));
    await new Promise(resolve => server.close(resolve));
    await fs.rm(userData, { recursive: true, force: true, maxRetries: 5, retryDelay: 100 });
  }
}
main().catch(error => { console.error('C2 contract-browser check failed:',error.message); process.exitCode = 1; });
