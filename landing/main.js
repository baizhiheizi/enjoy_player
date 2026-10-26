'use strict';

const cfg = window.ENJOY_CONFIG;

const OS_NAMES = {
  windows: 'Windows',
  macos: 'macOS',
  linux: 'Linux',
  android: 'Android',
  ios: 'iOS',
};

// ── OS detection ────────────────────────────────────────────────
function detectOS() {
  const ua = navigator.userAgent;
  const plat = (navigator.platform || '').toLowerCase();

  // iPadOS reports as 'MacIntel' but has multiple touch points
  if (/ipad|iphone|ipod/i.test(ua)) return 'ios';
  if (/macintosh|macintel/i.test(plat) && navigator.maxTouchPoints > 1) return 'ios';
  if (/mac/i.test(plat) || /macintosh/i.test(ua)) return 'macos';
  if (/win/i.test(plat) || /windows/i.test(ua)) return 'windows';
  if (/android/i.test(ua)) return 'android';
  if (/linux/i.test(ua) || /linux/i.test(plat)) return 'linux';

  return null;
}

// ── Manifest fetch (with timeout + fallback) ────────────────────
async function fetchManifest(url, timeoutMs = 5000) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const resp = await fetch(url, { signal: ctrl.signal });
    clearTimeout(timer);
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    return await resp.json();
  } catch {
    clearTimeout(timer);
    return null;
  }
}

// ── Apply manifest data to the page ────────────────────────────
// Each asset URL embeds the version in its path (…/player/<version>/…),
// so we treat that as the source of truth for which version a platform
// actually downloads. This keeps each platform button pointing to the
// latest version uploaded for THAT platform, even when other platforms
// are still on an earlier release.
function applyManifest(manifest) {
  if (!manifest) return;

  const { assets = {} } = manifest;

  const platformMap = {
    'btn-windows': { asset: 'windows',           chipId: 'version-windows' },
    'btn-macos':   { asset: 'macos',             chipId: 'version-macos' },
    'btn-android': { asset: 'android_arm64_v8a', chipId: 'version-android' },
    'btn-linux':   { asset: 'linux',             chipId: 'version-linux' },
  };

  const parsedVersions = [];

  for (const [btnId, { asset: assetKey, chipId }] of Object.entries(platformMap)) {
    const asset = assets[assetKey];
    const btn = document.getElementById(btnId);
    if (!asset || !asset.url || !btn) continue;

    btn.href = asset.url;
    btn.setAttribute('download', '');

    const versionMatch = asset.url.match(/\/player\/([^/]+)\//);
    const platformVersion = versionMatch ? versionMatch[1] : null;
    if (!platformVersion) continue;

    parsedVersions.push(platformVersion);

    // Stamped so the i18n handler can re-compose the aria-label on a
    // language switch.
    btn.dataset.version = platformVersion;

    const chip = document.getElementById(chipId);
    if (chip) {
      chip.textContent = `v${platformVersion}`;
      chip.classList.remove('hidden');
    }

    const base = t(btn.getAttribute('data-aria-i18n'));
    if (base) btn.setAttribute('aria-label', `${base} (v${platformVersion})`);
  }

  // Hero version badge: only shown when every direct-download platform is
  // at the same version; otherwise the per-card chips are authoritative.
  const badge = document.getElementById('version-badge');
  if (badge) {
    const allAligned =
      parsedVersions.length === Object.keys(platformMap).length &&
      parsedVersions.every((v) => v === parsedVersions[0]);
    if (allAligned) {
      badge.textContent = `v${parsedVersions[0]}`;
      badge.classList.remove('hidden');
    } else {
      badge.classList.add('hidden');
    }
  }
}

// ── Highlight + reorder recommended card ───────────────────────
function highlightPlatform(os) {
  if (!os) return;

  const card = document.getElementById(`card-${os}`);
  if (!card || card.hidden) return;

  card.classList.add('card--recommended');

  const badge = document.createElement('span');
  badge.className = 'recommended-badge';
  badge.setAttribute('data-i18n', 'recommended');
  badge.textContent = t('recommended') || 'Recommended';
  card.prepend(badge);

  const grid = document.getElementById('platform-grid');
  if (grid && grid.firstElementChild !== card) {
    grid.prepend(card);
  }
}

// ── Hero CTA names the detected platform ───────────────────────
function applyHeroCta(os) {
  const label = document.getElementById('hero-download-label');
  if (!label) return;
  if (os && OS_NAMES[os]) {
    label.removeAttribute('data-i18n');
    label.textContent = t('hero.cta_os').replace('{os}', OS_NAMES[os]);
  }
}

function isUsableTestFlightUrl(url) {
  if (!url || typeof url !== 'string') return false;
  const trimmed = url.trim();
  if (!trimmed || /PLACEHOLDER/i.test(trimmed)) return false;
  return trimmed.startsWith('https://testflight.apple.com/join/');
}

function isUsablePlayBetaUrl(url) {
  if (!url || typeof url !== 'string') return false;
  const trimmed = url.trim();
  if (!trimmed) return false;
  return trimmed.startsWith('https://play.google.com/');
}

function applyStoreButton(btnId, url, labelKey, isValid, ariaLabel) {
  const btn = document.getElementById(btnId);
  if (!btn) return;

  const validUrl = isValid(url) ? url.trim() : null;
  const labelEl = btn.querySelector('[data-i18n]');

  if (validUrl) {
    btn.href = validUrl;
    btn.classList.remove('btn--disabled');
    btn.removeAttribute('aria-disabled');
    btn.removeAttribute('tabindex');
    btn.target = '_blank';
    btn.rel = 'noopener noreferrer';
    btn.setAttribute('aria-label', ariaLabel);
    if (labelEl) labelEl.setAttribute('data-i18n', labelKey);
  } else {
    btn.removeAttribute('href');
    btn.classList.add('btn--disabled');
    btn.setAttribute('aria-disabled', 'true');
    btn.setAttribute('tabindex', '-1');
    btn.removeAttribute('target');
    btn.removeAttribute('rel');
    if (labelEl) labelEl.setAttribute('data-i18n', 'download.comingSoon');
  }

  if (labelEl) {
    const text = t(labelEl.getAttribute('data-i18n'));
    if (text) labelEl.textContent = text;
  }
}

function applyConfig() {
  applyStoreButton(
    'btn-testflight',
    cfg.testFlightUrl,
    'download.ios.btn',
    isUsableTestFlightUrl,
    'Join the TestFlight beta for Enjoy Player on iOS',
  );
  applyStoreButton(
    'btn-play-beta',
    cfg.playBetaUrl,
    'download.android.btn.play',
    isUsablePlayBetaUrl,
    'Join the Google Play beta for Enjoy Player',
  );
}

// ── The 15-second film ─────────────────────────────────────────
// Plays muted while on screen, never autoplays for reduced motion, and
// swaps to the film cut for the page language.
function initFilm() {
  const video = document.getElementById('film-video');
  const toggle = document.getElementById('film-toggle');
  const replay = document.getElementById('film-replay');
  if (!video || !toggle || !replay) return;

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  let userPaused = reduceMotion;
  let visible = false;

  const sync = () => toggle.setAttribute('data-playing', String(!video.paused));
  const play = () => video.play().catch(() => {});

  const loadCut = (lang) => {
    const cut = lang === 'zh' ? 'zh-CN' : 'en';
    const src = `videos/enjoy-player-film.${cut}.mp4`;
    const source = video.querySelector('source');
    if (source.getAttribute('src') === src) return;
    source.setAttribute('src', src);
    video.poster = `videos/enjoy-player-film.${cut}.jpg`;
    video.load();
    if (visible && !userPaused) play();
  };

  video.addEventListener('play', sync);
  video.addEventListener('pause', sync);
  toggle.addEventListener('click', () => {
    if (video.paused) {
      userPaused = false;
      play();
    } else {
      userPaused = true;
      video.pause();
    }
  });
  replay.addEventListener('click', () => {
    userPaused = false;
    video.currentTime = 0;
    play();
  });

  new IntersectionObserver(([entry]) => {
    visible = entry.isIntersecting;
    if (visible && !userPaused) play();
    else if (!visible) video.pause();
  }, { threshold: 0.35 }).observe(video);

  loadCut(window.currentLanguage ? window.currentLanguage() : 'en');
  document.addEventListener('enjoy:language', (e) => loadCut(e.detail.lang));
}

// ── Reveal on scroll ───────────────────────────────────────────
function initReveal() {
  const items = document.querySelectorAll('.reveal');
  if (!('IntersectionObserver' in window)) {
    items.forEach((el) => el.classList.add('is-in'));
    return;
  }
  const observer = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      entry.target.classList.add('is-in');
      observer.unobserve(entry.target);
    }
  }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });
  items.forEach((el) => observer.observe(el));
}

// ── Main ────────────────────────────────────────────────────────
(async function init() {
  const os = detectOS();
  document.addEventListener('enjoy:language', () => applyHeroCta(os));
  if (window.initI18n) window.initI18n();
  applyConfig();
  highlightPlatform(os);
  applyHeroCta(os);
  initReveal();
  initFilm();

  const manifest = await fetchManifest(cfg.manifestUrl);
  applyManifest(manifest);
})();
