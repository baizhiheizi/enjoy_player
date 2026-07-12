'use strict';

const cfg = window.ENJOY_CONFIG;

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
function applyManifest(manifest) {
  if (!manifest) return;

  const { version, assets = {} } = manifest;

  // Version badge
  if (version) {
    const badge = document.getElementById('version-badge');
    if (badge) {
      badge.textContent = `v${version}`;
      badge.classList.remove('hidden');
    }
  }

  // Update download hrefs for direct-download platforms
  const urlMap = {
    'btn-windows':  assets.windows?.url,
    'btn-macos':    assets.macos?.url,
    'btn-android':  assets.android_arm64_v8a?.url,
    'btn-linux':    assets.linux?.url,
  };

  for (const [id, url] of Object.entries(urlMap)) {
    if (!url) continue;
    const el = document.getElementById(id);
    if (el) {
      el.href = url;
      el.setAttribute('download', '');
    }
  }
}

// ── Highlight + reorder recommended card ───────────────────────
function highlightPlatform(os) {
  if (!os) return;

  const card = document.getElementById(`card-${os}`);
  if (!card || card.hidden) return;

  card.classList.add('card--recommended');

  const badge = document.createElement('div');
  badge.className = 'recommended-badge';
  badge.setAttribute('aria-label', 'Recommended for your device');
  badge.setAttribute('data-i18n', 'recommended');
  
  // Use translation if available
  const lang = document.documentElement.lang || 'en';
  badge.textContent = (window.translations && window.translations[lang] && window.translations[lang]['recommended']) 
    ? window.translations[lang]['recommended'] 
    : 'Recommended';
    
  card.prepend(badge);

  // Move recommended card to the front of the grid
  const grid = document.getElementById('platform-grid');
  if (grid && grid.firstChild !== card) {
    grid.prepend(card);
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

  if (labelEl && window.translations) {
    const lang = document.documentElement.lang || 'en';
    const key = labelEl.getAttribute('data-i18n');
    if (window.translations[lang]?.[key]) {
      labelEl.textContent = window.translations[lang][key];
    }
  }
}

// ── Apply config URLs (store / TestFlight links from config.js) ─
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

// ── Main ────────────────────────────────────────────────────────
(async function init() {
  if (window.initI18n) window.initI18n();
  applyConfig();

  const os = detectOS();
  highlightPlatform(os);

  const manifest = await fetchManifest(cfg.manifestUrl);
  applyManifest(manifest);
})();
