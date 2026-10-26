#!/usr/bin/env node
/**
 * Renders the landing-page film and stills from tool/promo/*.html.
 *
 *   node tool/promo/render_film.mjs                  # film (en + zh-CN) and stills
 *   node tool/promo/render_film.mjs film --lang en   # one cut of the film
 *   node tool/promo/render_film.mjs stills           # og-image + README showcase
 *   node tool/promo/render_film.mjs --serve          # preview at http://localhost:4418/film.html?lang=en
 *
 * The film is stepped one frame at a time over the Chrome DevTools Protocol
 * (no real-time capture, so every frame is exact), then encoded with ffmpeg.
 * Needs Node 22+, google-chrome (or $CHROME), and ffmpeg with libx264. The
 * screenshots it shows come from landing/images/ (see tool/store_screenshots.sh).
 */
import { spawn } from 'node:child_process';
import { createReadStream, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { dirname, extname, join, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';

const promo = dirname(fileURLToPath(import.meta.url));
const root = join(promo, '..', '..');
const landing = join(root, 'landing');
const PORT = 4418;
const DEBUG_PORT = 9334;
const FPS = 30;

const args = process.argv.slice(2);
const serveOnly = args.includes('--serve');
const langArg = args.includes('--lang') ? args[args.indexOf('--lang') + 1] : null;
const langs = langArg ? [langArg] : ['en', 'zh-CN'];
const jobs = args.filter((a) => a === 'film' || a === 'stills');
const wantFilm = jobs.length === 0 || jobs.includes('film');
const wantStills = jobs.length === 0 || jobs.includes('stills');

const STILLS = [
  { page: 'og.html', width: 1200, height: 630, out: join(landing, 'og-image.png') },
  { page: 'showcase.html', width: 1800, height: 1000, out: join(root, 'assets', 'readme', 'showcase.png') },
];

function iconBodies() {
  const sprite = readFileSync(join(landing, 'icons.svg'), 'utf8');
  const icons = {};
  for (const [, id, body] of sprite.matchAll(/<symbol id="([^"]+)" viewBox="0 0 24 24">([\s\S]*?)<\/symbol>/g)) {
    icons[id] = body;
  }
  return icons;
}

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.woff2': 'font/woff2',
  '.webp': 'image/webp',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.css': 'text/css; charset=utf-8',
};
const iconScript = `<script>window.FILM_ICONS = ${JSON.stringify(iconBodies())}</script>`;

const server = createServer((req, res) => {
  const { pathname } = new URL(req.url, `http://localhost:${PORT}`);
  const base = pathname.startsWith('/landing/') ? root : promo;
  const file = normalize(join(base, decodeURIComponent(pathname)));
  if (!file.startsWith(base) || !existsSync(file) || !statSync(file).isFile()) {
    res.writeHead(404).end('not found');
    return;
  }
  const type = MIME[extname(file)] ?? 'application/octet-stream';
  if (type.startsWith('text/html')) {
    res.writeHead(200, { 'content-type': type });
    res.end(readFileSync(file, 'utf8').replace('<head>', `<head>${iconScript}`));
    return;
  }
  res.writeHead(200, { 'content-type': type });
  createReadStream(file).pipe(res);
});
await new Promise((ready) => server.listen(PORT, ready));

if (serveOnly) {
  console.log(`Previewing at http://localhost:${PORT}/film.html?lang=en (Ctrl-C to stop)`);
} else {
  try {
    if (wantFilm) {
      mkdirSync(join(landing, 'videos'), { recursive: true });
      for (const lang of langs) await renderFilm(lang);
    }
    if (wantStills) {
      for (const still of STILLS) await renderStill(still);
    }
  } finally {
    server.close();
  }
}

async function withChrome(width, height, work) {
  const scratch = mkdtempSync(join(tmpdir(), 'enjoy-player-film-'));
  const chrome = spawn(process.env.CHROME ?? 'google-chrome-stable', [
    '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-color-profile=srgb',
    `--remote-debugging-port=${DEBUG_PORT}`, `--user-data-dir=${join(scratch, 'profile')}`,
    `--window-size=${width},${height}`, 'about:blank',
  ], { stdio: 'ignore' });
  try {
    const cdp = await connect();
    await cdp.send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
    await cdp.send('Page.enable');
    await work(cdp, scratch);
    cdp.close();
  } finally {
    chrome.kill();
    await new Promise((done) => chrome.once('exit', done));
    rmSync(scratch, { recursive: true, force: true });
  }
}

async function load(cdp, url) {
  await cdp.send('Page.navigate', { url });
  return evaluate(cdp, `
    new Promise((done) => {
      const ready = () => window.FILM
        ? Promise.all([document.fonts.ready, ...[...document.images].map((img) => img.decode().catch(() => {}))]).then(() => done(window.FILM.duration))
        : setTimeout(ready, 50)
      ready()
    })`);
}

async function shot(cdp, width, height) {
  const { data } = await cdp.send('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width, height, scale: 1 } });
  return Buffer.from(data, 'base64');
}

async function renderFilm(lang) {
  const width = 1920;
  const height = 1080;
  await withChrome(width, height, async (cdp, scratch) => {
    const frames = join(scratch, 'frames');
    mkdirSync(frames);
    const duration = await load(cdp, `http://localhost:${PORT}/film.html?capture&lang=${lang}`);
    const total = Math.round(duration * FPS);
    for (let i = 0; i < total; i++) {
      await evaluate(cdp, `renderFrame(${i / FPS})`);
      writeFileSync(join(frames, `${String(i).padStart(4, '0')}.png`), await shot(cdp, width, height));
      if (i % 60 === 0) console.log(`[${lang}] frame ${i}/${total}`);
    }
    const base = join(landing, 'videos', `enjoy-player-film.${lang}`);
    await ffmpeg(['-framerate', `${FPS}`, '-i', join(frames, '%04d.png'),
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '24', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', `${base}.mp4`]);
    await ffmpeg(['-framerate', `${FPS}`, '-start_number', `${Math.round(1.95 * FPS)}`, '-i', join(frames, '%04d.png'),
      '-frames:v', '1', '-vf', 'scale=1280:-1', '-q:v', '4', `${base}.jpg`]);
    console.log(`[${lang}] wrote ${base}.mp4 and ${base}.jpg`);
  });
}

async function renderStill({ page, width, height, out }) {
  await withChrome(width, height, async (cdp) => {
    await load(cdp, `http://localhost:${PORT}/${page}`);
    mkdirSync(dirname(out), { recursive: true });
    writeFileSync(out, await shot(cdp, width, height));
    console.log(`wrote ${out}`);
  });
}

function ffmpeg(params) {
  return new Promise((done, fail) => {
    const proc = spawn('ffmpeg', ['-y', '-loglevel', 'error', ...params], { stdio: 'inherit' });
    proc.once('exit', (code) => (code === 0 ? done() : fail(new Error(`ffmpeg failed: ${params.join(' ')}`))));
  });
}

async function evaluate(cdp, expression) {
  const { result, exceptionDetails } = await cdp.send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
  if (exceptionDetails) throw new Error(exceptionDetails.exception?.description ?? exceptionDetails.text);
  return result.value;
}

async function connect() {
  let targets = [];
  for (let attempt = 0; attempt < 50 && !targets.some((t) => t.type === 'page'); attempt++) {
    await new Promise((r) => setTimeout(r, 100));
    targets = await fetch(`http://127.0.0.1:${DEBUG_PORT}/json`).then((r) => r.json()).catch(() => []);
  }
  const target = targets.find((t) => t.type === 'page');
  if (!target) throw new Error('Chrome did not start');

  const socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((ready, fail) => { socket.onopen = ready; socket.onerror = fail; });
  let id = 0;
  const pending = new Map();
  socket.onmessage = ({ data }) => {
    const message = JSON.parse(String(data));
    const waiter = pending.get(message.id);
    if (!waiter) return;
    pending.delete(message.id);
    if (message.error) waiter.reject(new Error(message.error.message));
    else waiter.resolve(message.result);
  };
  return {
    send: (method, params = {}) => new Promise((resolve, reject) => {
      pending.set(++id, { resolve, reject });
      socket.send(JSON.stringify({ id, method, params }));
    }),
    close: () => socket.close(),
  };
}
