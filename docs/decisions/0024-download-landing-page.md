# ADR-0024: Download landing page on Cloudflare Pages

## Status

Accepted

## Context

Enjoy Player ships on four platforms (Windows, macOS, Android, iOS), with binaries distributed through `dl.enjoy.bot` (direct) and through TestFlight / Play test track (store). There is no human-facing page that helps a new user identify the right download for their OS. Links are scattered across release notes and the README.

The app explicitly forbids Flutter web (ADR-0005), so the landing page must be a separate static site, not a Flutter web build.

## Decision

1. **Static site in `landing/`** — A hand-authored HTML/CSS/JS site, not a Flutter web target and not under `web/`. No build step, no SSG framework; the output is the `landing/` directory itself.

2. **Hosted on Cloudflare Pages** — Project name `enjoy-player-landing`, served at `https://get.enjoy.bot` (CNAME → `enjoy-player-landing.pages.dev`). Cloudflare Pages provides free TLS, global CDN, preview deployments per PR, and Pages Functions.

3. **Same-origin manifest proxy** — A Pages Function at `/api/latest` fetches `https://dl.enjoy.bot/player/latest.json` server-side, caches it at the edge (5-minute TTL + stale-while-revalidate), and returns it same-origin. The client reads `assets.windows.url`, `assets.macos.url`, and `assets.android_arm64_v8a.url` to populate download buttons at runtime — no version numbers are hard-coded in the HTML.

4. **Static fallback links** — When JS is disabled or the manifest is unreachable, all platform buttons fall back to the GitHub releases/latest page, so no action is ever missing.

5. **Store/TestFlight links in `config.js`** — iOS (TestFlight) and Android Play beta have stable URLs that do not come from `latest.json`. They live in `landing/config.js` (the single file to update for link maintenance), applied by JS on load. URLs are validated by origin (`https://testflight.apple.com/join/...` / `https://play.google.com/...`); anything else — including `null` — renders the matching card with a disabled **Coming soon** button (`btn--disabled`, `aria-disabled="true"`) instead of dropping the card or exposing a broken link.

6. **OS detection with progressive enhancement** — `navigator.userAgentData` / `userAgent` / `platform` heuristics; iPadOS is disambiguated from macOS via `navigator.maxTouchPoints > 1`. The detected platform's card is reordered to the front and highlighted with a gradient border. All four platform cards always render.

7. **Deployed via Wrangler + GitHub Actions** — `.github/workflows/deploy_landing.yml` runs `wrangler pages deploy` with preview deploys on PRs touching `landing/**` and production deploys on `main`. Auth uses `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` CI secrets — no credentials committed to the repo.

## Consequences

- `landing/` must not contain a `web/` subdirectory or any Flutter web artefacts.
- The TestFlight invite URL and Play beta URL in `landing/config.js` must be updated manually when they change (invite expiry, new TestFlight group, etc.).
- When either URL is `null` or fails origin validation, the corresponding store card stays visible with a disabled **Coming soon** button — visitors see the platform exists, but cannot click through to a missing invite.
- A new version of the app automatically surfaces on the landing page on the next page load, because the manifest proxy reflects the live `latest.json`.
- Wrangler and the deploy workflow have no impact on the Flutter app build pipeline.
- Two CI secrets (`CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`) must be set in the repository before the deploy workflow can run.
