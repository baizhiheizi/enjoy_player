#!/usr/bin/env node
/**
 * Render every Duet design board to docs/design/duet/renders/*.webp.
 * Needs Node 22+, Chrome or Chromium, and ImageMagick with WebP.
 * Run from repo root: node tool/render_design_boards.mjs <path/to/dc-runtime.js>
 * The runtime is the Design artifact type's `artifact-type/dc-runtime.js`
 * (see docs/design/duet/README.md → "Re-rendering").
 */
import { spawn, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const duet = join(root, 'docs', 'design', 'duet');
const boardsDir = join(duet, 'boards');
const rendersDir = join(duet, 'renders');
const blobs = {
  '747775ae97e736fcc52ae3074fe11fa4': join(root, 'assets', 'logo-light.svg'),
};
const fullLength = new Set([
  'Home', 'LibraryCloud', 'Vocabulary', 'Subscription', 'Credits', 'Keyboard',
  'PhHome', 'PhDiscover', 'PhLibrary', 'PhVocabulary', 'PhProfile',
]);
const phoneMaxWidth = 600;

const runtimePath = process.argv[2];
if (!runtimePath || !existsSync(runtimePath)) {
  console.error('Usage: node tool/render_design_boards.mjs <path/to/dc-runtime.js>');
  process.exit(2);
}
const runtime = readFileSync(runtimePath);
const canvas = JSON.parse(readFileSync(join(boardsDir, 'canvas.json'), 'utf8'));
const only = new Set(process.argv.slice(3));
const boards = canvas.order
  .map((file) => ({ name: file.replace(/\.dc\.html$/, ''), ...canvas.boards[file] }))
  .filter((b) => only.size === 0 || only.has(b.name));

const chromeBin = [
  process.env.CHROME,
  'google-chrome-stable', 'google-chrome', 'chromium', 'chromium-browser',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
].find((c) => c && spawnSync(c, ['--version']).status === 0);
const magickBin = ['magick', 'convert'].find((c) => spawnSync(c, ['-version']).status === 0);
if (!chromeBin || !magickBin) {
  console.error(`Missing ${chromeBin ? 'ImageMagick' : 'Chrome (set CHROME=…)'}`);
  process.exit(2);
}

const server = createServer((req, res) => {
  const path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  const blob = path.match(/^\/_blob\/([0-9a-f]+)$/);
  const send = (file, type) => {
    if (!file || !existsSync(file)) return res.writeHead(404).end();
    res.writeHead(200, { 'content-type': type }).end(readFileSync(file));
  };
  if (path === '/support.js') return res.writeHead(200, { 'content-type': 'text/javascript' }).end(runtime);
  if (blob) return send(blobs[blob[1]], 'image/svg+xml');
  const file = join(boardsDir, path.slice(1));
  if (!file.startsWith(boardsDir)) return res.writeHead(403).end();
  send(file, path.endsWith('.json') ? 'application/json' : 'text/html; charset=utf-8');
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const origin = `http://127.0.0.1:${server.address().port}`;

const profile = mkdtempSync(join(tmpdir(), 'duet-render-'));
const chrome = spawn(chromeBin, [
  '--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-first-run',
  `--user-data-dir=${profile}`, '--remote-debugging-port=0', 'about:blank',
], { stdio: ['ignore', 'ignore', 'pipe'] });
const wsUrl = await new Promise((resolve, reject) => {
  let buf = '';
  chrome.stderr.on('data', (d) => {
    buf += d;
    const m = buf.match(/DevTools listening on (ws:\/\/\S+)/);
    if (m) resolve(m[1]);
  });
  chrome.once('exit', () => reject(new Error(`Chrome exited before DevTools was ready:\n${buf.slice(-2000)}`)));
});

const ws = new WebSocket(wsUrl);
await new Promise((r) => (ws.onopen = r));
let seq = 0;
const pending = new Map();
const waiters = [];
ws.onmessage = (e) => {
  const m = JSON.parse(e.data);
  if (m.id && pending.has(m.id)) {
    pending.get(m.id)(m);
    pending.delete(m.id);
    return;
  }
  const i = waiters.findIndex((w) => w.method === m.method);
  if (i >= 0) waiters.splice(i, 1)[0].resolve(m.params);
};
const cdp = (method, params = {}, sessionId) => new Promise((resolve, reject) => {
  const id = ++seq;
  pending.set(id, (m) => (m.error ? reject(new Error(`${method}: ${m.error.message}`)) : resolve(m.result)));
  ws.send(JSON.stringify({ id, method, params, sessionId }));
});
const nextEvent = (method) => new Promise((resolve) => waiters.push({ method, resolve }));
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const { targetId } = await cdp('Target.createTarget', { url: 'about:blank' });
const { sessionId } = await cdp('Target.attachToTarget', { targetId, flatten: true });
const page = (method, params) => cdp(method, params, sessionId);
await page('Page.enable');

const overflowScript = `(() => {
  let extra = document.documentElement.scrollHeight - innerHeight;
  for (const el of document.querySelectorAll('*')) {
    if (/(auto|scroll)/.test(getComputedStyle(el).overflowY)) extra = Math.max(extra, el.scrollHeight - el.clientHeight);
  }
  return Math.round(extra);
})()`;

const setViewport = (b, height) => page('Emulation.setDeviceMetricsOverride', {
  width: b.w, height, deviceScaleFactor: b.w <= phoneMaxWidth ? 2 : 1, mobile: false,
});
const settle = async () => {
  await page('Runtime.evaluate', { expression: 'document.fonts.ready.then(() => 1)', awaitPromise: true });
  await sleep(1500);
  await page('Runtime.evaluate', { expression: 'document.fonts.ready.then(() => 1)', awaitPromise: true });
};
const capture = async (out) => {
  const { data } = await page('Page.captureScreenshot', { format: 'png' });
  const png = join(profile, 'shot.png');
  writeFileSync(png, Buffer.from(data, 'base64'));
  const r = spawnSync(magickBin, [png, '-define', 'webp:lossless=true', '-define', 'webp:method=6', out]);
  if (r.status !== 0) throw new Error(`${magickBin} failed: ${r.stderr}`);
};

mkdirSync(rendersDir, { recursive: true });
for (const b of boards) {
  await setViewport(b, b.h);
  const loaded = nextEvent('Page.loadEventFired');
  await page('Page.navigate', { url: `${origin}/${b.name}.dc.html` });
  await loaded;
  await settle();
  await capture(join(rendersDir, `${b.name}.webp`));
  let line = `${b.name} ${b.w}x${b.h}`;
  if (fullLength.has(b.name)) {
    const { result } = await page('Runtime.evaluate', { expression: overflowScript, returnByValue: true });
    await setViewport(b, b.h + Math.max(0, result.value));
    await settle();
    await capture(join(rendersDir, `${b.name}.full.webp`));
    line += ` + full ${b.w}x${b.h + Math.max(0, result.value)}`;
  }
  console.log(line);
}

ws.close();
const chromeExited = new Promise((r) => chrome.once('exit', r));
chrome.kill();
await chromeExited;
server.close();
rmSync(profile, { recursive: true, force: true });
