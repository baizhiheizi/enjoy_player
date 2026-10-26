# Feature: Download landing page (`player.enjoy.bot`)

## Summary

The download landing page is a **hand-authored static site** in [`landing/`](../../landing/) — no build step, no SSG, and explicitly **not** a Flutter web target (the repo bans Flutter web — see the "Supported platforms" hard rule in [AGENTS.md](../../AGENTS.md)). It is hosted on **Cloudflare Pages** (project `enjoy-player`, custom domain `https://player.enjoy.bot`) and helps a new user pick the right download for their OS. Direct-download buttons are populated at runtime from the release manifest; store links (TestFlight / Play beta) come from a single config file. The architectural rationale is [ADR-0024](../decisions/0024-download-landing-page.md); the in-app update flow that consumes the same manifest is documented in [update.md](update.md).

## Directory structure

| Path | Role |
|------|------|
| `landing/index.html` | Single page in the Duet design language ([ADR-0093](../decisions/0093-duet-design-language.md)), structured after the `enjoy.bot` landing page in `enjoy_web`: header, hero (slogan, OS-aware download CTA, the 15-second film), the practice loop (Listen · Echo · Dictate), feature rows built on real app screenshots (transcripts, pronunciation assessment, lookup & vocabulary, Craft), the night "every device" band, pricing, five platform cards (`card-windows`, `card-macos`, `card-linux`, `card-android`, `card-ios`) plus a source card, closing band and footer. All copy carries `data-i18n` keys (`data-alt-i18n` / `data-aria-i18n` for attributes). |
| `landing/styles.css` | All styling, hand-written with the Duet tokens (ground / paper / ink, original blue, you violet, the brand gradient, the night band); light by default, dark through `prefers-color-scheme`. Fonts are self-hosted from `landing/fonts/` because the CSP allows `font-src 'self'` only. `.reveal` elements fade in on scroll (disabled under `prefers-reduced-motion`). |
| `landing/boot.js` | Adds the `js` class to `<html>` before first paint so scroll reveals only hide content when the script that reveals it can run (the CSP forbids inline scripts). |
| `landing/main.js` | OS detection, manifest fetch, store-button validation, recommended-card highlight, the hero CTA's platform label (`Download for macOS`), the film controls, and the scroll reveal. |
| `landing/i18n.js` | `en` / `zh` string tables exposed as `window.translations` and a `t(key)` helper; swaps `data-i18n` nodes, persists the choice, and dispatches `enjoy:language` so the film and hero CTA follow the language. |
| `landing/config.js` | `window.ENJOY_CONFIG` — the **only file edited for link maintenance** (see below). |
| `landing/functions/api/latest.js` | Cloudflare Pages Function: same-origin proxy for the release manifest. |
| `landing/_headers` | Cloudflare Pages security headers + per-path cache policy. |
| `landing/wrangler.toml` | Pages config; `pages_build_output_dir = "."` (the directory itself is the output). |
| `landing/icons.svg` | SVG sprite (Lucide + Material Design Icons bodies) referenced with `<use href="icons.svg#name">`. |
| `landing/images/*.webp` | App screenshots, converted from the Duet gallery renders (see [Screenshots and film](#screenshots-and-film)). |
| `landing/videos/enjoy-player-film.{en,zh-CN}.{mp4,jpg}` | The 15-second hero film and its poster, one cut per language. |
| `landing/logo.svg`, `og-image.png` | Brand mark and the 1200 × 630 social card. |

## Link maintenance — `config.js`

```js
window.ENJOY_CONFIG = {
  bundleId: 'ai.enjoy.player',
  testFlightUrl: null,   // public TestFlight invite, or null
  playBetaUrl: null,     // Play open-beta opt-in URL, or null
  manifestUrl: '/api/latest',
  releasesUrl: 'https://github.com/an-lee/enjoy_player/releases/latest',
  githubUrl: 'https://github.com/an-lee/enjoy_player',
};
```

- **`testFlightUrl`** — set when a public TestFlight invite is available. `main.js` validates the origin (`https://testflight.apple.com/join/...`, and rejects `PLACEHOLDER`); a `null`/invalid value renders the iOS card with a **disabled "Coming soon"** button (`btn--disabled`, `aria-disabled="true"`, `tabindex="-1"`) — the card stays visible, no broken link is ever exposed.
- **`playBetaUrl`** — same pattern, validated against the `https://play.google.com/` origin.
- **`releasesUrl`** — the no-JS fallback: every platform button's static `href` points at GitHub releases/latest so no action is missing with JavaScript disabled.

Direct-download buttons (`btn-windows`, `btn-macos`, `btn-android`, `btn-linux`) do **not** use `config.js`; their `href`s are rewritten at runtime from the manifest (below).

## Manifest proxy — `functions/api/latest.js`

The Pages Function serves `GET /api/latest`:

1. Fetches the upstream manifest `https://dl.enjoy.bot/player/latest.json` with Cloudflare edge caching (`cacheTtl: 300`, `cacheEverything`).
2. Returns it same-origin with `Cache-Control: public, max-age=300, stale-while-revalidate=600`, so the browser never talks to `dl.enjoy.bot` directly (also allowed by the CSP `connect-src`).
3. On upstream failure returns a JSON `{ error }` body with `502` (or the upstream status) and `Cache-Control: no-store`.

`main.js` reads `assets.windows.url`, `assets.macos.url`, `assets.android_arm64_v8a.url`, and `assets.linux.url` from the manifest, sets each button's `href` + `download` attribute, and fills the `v<version>` badge. The fetch has a **5 s `AbortController` timeout**; on any failure the static GitHub fallback links remain. The manifest schema itself is documented in [update.md § Manifest schema](update.md#manifest-schema).

## OS detection & progressive enhancement — `main.js`

- `detectOS()` uses `navigator.userAgent` / `navigator.platform` heuristics; **iPadOS is disambiguated from macOS via `navigator.maxTouchPoints > 1`** (iPadOS reports `MacIntel`).
- The detected platform's card gets the `card--recommended` gradient border plus a localized "For this device" badge, and is **moved to the front** of `#platform-grid`. All five cards always render regardless. The hero CTA names the platform (`Download for macOS`) and links to `#download`.
- Every direct-download button's static `href` is GitHub releases/latest, so nothing is missing with JavaScript disabled; the `.nojs-notice` says so.
- The film (`#film-video`) plays muted and looped only while at least 35% of it is on screen, never autoplays under `prefers-reduced-motion`, and swaps to the `zh-CN` cut (video and poster) when the page language is Chinese.
- Init order: `initI18n()` → `applyConfig()` (store buttons) → highlight → hero CTA → scroll reveal → film → manifest fetch → `applyManifest()`.

## Internationalization — `i18n.js`

Two locales, `en` (default) and `zh`, selected by the header `EN` / `中` buttons (`data-lang`). `initI18n()` swaps the text of every `[data-i18n]` node (plus `data-alt-i18n` image alts and `data-aria-i18n` labels) from `window.translations`, sets `<html lang>` to `en` / `zh-CN`, and persists the choice (localStorage, guarded — a blocked store just keeps the choice for the page view), so reloads keep the language. Dynamic strings created later (e.g., the recommended badge) look up their `data-i18n` key against the active locale at creation time.

## Pricing offers

The landing page mirrors the current subscription catalog with three informational offers:

- **Free** — $0 forever, 1,000 Enjoy AI credits per day, and all core player features.
- **Lite** — $1.99/month, 12,000 Enjoy AI credits per day.
- **Pro** — $9.99/month, 60,000 Enjoy AI credits per day.

The pricing cards link to the download section rather than pretending to provide checkout. Paid plans are managed inside the app, with platform-specific purchase availability described in [subscription.md](subscription.md). If plan prices or allowances change, update the cards and both locale tables together with the product catalog.

## Security headers & caching — `_headers`

Applied site-wide:

```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self' https://dl.enjoy.bot; font-src 'self'; frame-ancestors 'none'
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

Per-path caching: `index.html` is `no-cache, must-revalidate` (links must be fresh); `styles.css` / `main.js` / `i18n.js` / `config.js` / `boot.js` get 1 h (no build-time fingerprinting, so not immutable — bump the `?v=` query in `index.html` when they change); `/fonts/*` a year `immutable`; `/images/*`, `/videos/*`, `icons.svg` and `og-image.png` 24 h; `logo.svg` 24 h `immutable`; `/api/latest` mirrors the Function's 5 min + SWR policy. Videos fall under `default-src 'self'`.

## Screenshots and film

Every screenshot on the page, in the README and in `assets/store/` is rendered from the app itself by the Duet gallery harness (`test/duet_gallery/`, see [testing.md § Gallery](../testing.md#gallery-opt-in-screenshots)) — no device captures, so a re-shoot after a UI change is a command, not a manual session.

1. **Store screenshots** — `bash tool/store_screenshots.sh` runs every `Store…` gallery scene at the exact pixel size of the listing (iPhone 1290 × 2796, Android phone 1200 × 2670, iPad 2064 × 2752 / 2752 × 2064, Android tablet 3200 × 2136, macOS 3342 × 2324) and writes the flattened files into `assets/store/` under their listing names. The vocabulary list replaced the two flashcard shots: the review screen's pronunciation button stays in its loading state under `flutter test`.
2. **Landing images** — convert the renders in `build/duet_gallery/` to WebP (`magick <Board>.png -resize 640x -quality 82 landing/images/<name>.webp`; 1800 wide for desktop shots). Current mapping: `desktop-echo` ← `StoreMacosPlayer`, `desktop-scored` ← `StoreAndroidPadPlayer`, `phone-echo` / `phone-scored` / `phone-home` / `phone-vocabulary` / `phone-craft` ← the matching `StoreIosPhone…` scene, `phone-dark` ← `PDark`.
3. **Film and stills** — `node tool/promo/render_film.mjs` renders `tool/promo/film.html` (both language cuts, 15 s at 1920 × 1080 / 30 fps) to `landing/videos/`, plus `og.html` → `landing/og-image.png` and `showcase.html` → `assets/readme/showcase.png`. The film is a pure function of time (`renderFrame(t)`), stepped frame by frame over the Chrome DevTools Protocol and encoded with ffmpeg (libx264); `--serve` previews it at `http://localhost:4418/film.html?lang=en`. Needs Node 22+, Chrome and ffmpeg.

The Play feature graphic (`assets/store/feature-graphic.{svg,png}`, `tool/export_feature_graphic.mjs`) is unchanged.

## Deployment — Cloudflare Pages Git integration

The Cloudflare Pages project **`enjoy-player`** (account `an-lee`; domains `enjoy-player.pages.dev` and `player.enjoy.bot`) is connected to `baizhiheizi/enjoy_player` and builds on Cloudflare's side — there is no GitHub Actions workflow for the landing page:

- **Root directory** `landing`, **no build command**, output directory = the root (`landing/wrangler.toml` sets `pages_build_output_dir = "."`; its `name` must stay `enjoy-player`).
- **Production**: every push to `main` creates a production deployment; Pages Functions in `landing/functions/` deploy with it.
- **Previews**: off in the project's branch control (`preview_deployment_setting: none`), so pull requests do not get a preview URL; check changes locally (below).
- **Credentials**: none in the repository or in GitHub secrets — the Cloudflare GitHub app holds the connection.
- **Manual deploy** (a hotfix, or when a Git build is skipped): from `landing/`, signed in with `npx wrangler login`, run `npx wrangler pages deploy . --project-name enjoy-player --branch main`. It creates an `ad_hoc` production deployment that replaces the live one.
- **Checking a deploy**: `npx wrangler pages deployment list --project-name enjoy-player` lists deployments with their source commit and status; a Git deployment stuck at `queued` / `idle` was skipped by Cloudflare (`is_skipped` in the API) and never built. Retry it from the dashboard (Pages → enjoy-player → the deployment → *Retry deployment*) or deploy manually.

The GitHub Actions workflow `deploy_landing.yml` was removed on 2026-10-26: it targeted a project name (`enjoy-player-landing`) that does not exist in the account and never completed a deploy.

## Local development

No build step — serve the directory and edit files directly:

```bash
npx wrangler pages dev landing --config landing/wrangler.toml
```

(`wrangler pages dev` also executes the `/api/latest` Function locally.) Any static server works for HTML/CSS/JS-only changes, but only `wrangler pages dev` exercises the manifest proxy.

## Maintenance tasks

| Task | What to do |
|------|-----------|
| New TestFlight invite / Play beta URL | Edit `landing/config.js`, merge; the Pages Git integration deploys `main`. Confirm with `wrangler pages deployment list --project-name enjoy-player`. |
| New app release | Nothing — the manifest proxy reflects the live `latest.json` on next load. |
| New platform card | Add the `<article id="card-…">` in `index.html`, wire its button in `main.js` (`platformMap` / `applyConfig`), add `en`+`zh` strings in `i18n.js`. |
| UI changed in a way the screenshots show | Re-run the three steps in [Screenshots and film](#screenshots-and-film). |
| Copy changes | Update **both** `en` and `zh` tables in `i18n.js` (the HTML text is only the `en` fallback). |

## See also

- [ADR-0024: Download landing page on Cloudflare Pages](../decisions/0024-download-landing-page.md)
- [update.md — in-app update flow and manifest schema](update.md)
- [linux-platform.md — AppImage distribution referenced by the Linux card](linux-platform.md)
