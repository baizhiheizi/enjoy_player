# ADR-0091: YouTube playback on Linux via the WPE WebKit WebView backend

**Status**: Accepted (2026-10-02)
**Supersedes**: [ADR-0048](0048-linux-platform-support.md) R1 / R6 (the v1 Linux YouTube opt-out) and the "flip a single constant" follow-up clause.
**Feature spec**: [specs/047-youtube-linux-playback](../../specs/047-youtube-linux-playback/spec.md)

## Context

ADR-0048 shipped Linux as a first-class platform but opted YouTube playback out: at the time, `flutter_inappwebview` (the only sanctioned YouTube transport, ADR-0015) had no Linux backend, and the assumed WebKitGTK route would have added a dependency absent on default Ubuntu 22.04. The opt-out was one compile-time constant consulted by every gate call site.

Two things changed by late 2026:

1. `flutter_inappwebview` 6.2.0-beta added an endorsed Linux implementation (`flutter_inappwebview_linux`, WPE WebKit backend) with the API surface the YouTube engine needs — JS bridge injection, `addJavaScriptHandler`, `evaluateJavascript`, navigation interception — and a CMake bundling story (`$ORIGIN` RPATH, WPE libraries shipped inside the Flutter bundle).
2. YouTube's SABR rollout made the alternative route (bundled extractor → direct stream URLs → `media_kit`) structurally fragile: direct-URL playback is the mechanism being retired, which would put the app on an extractor-churn treadmill (frequent binary/runtime updates) that a WebView route never faces because it renders YouTube's own player.

## Decision

Enable YouTube playback on Linux through the same embedded-browser engine the other desktop platforms use:

1. **Dependency**: `flutter_inappwebview` pinned exactly to `6.2.0-beta.3` (first line with a Linux backend; exact pin per the ADR-0029 supply-chain precedent). The upgrade is shared with the four healthy platforms and is gated by the per-platform smoke checklist (specs/047 US5).
2. **Runtime availability, not compile-time opt-out**: the single decision point stays in `lib/core/platform/linux_platform_availability.dart`, but the build-time constant becomes a lazy, once-per-process runtime capability probe (create a headless WebView, bounded at 5 s). Systems that can play, play; systems that cannot get the localized unavailable message plus an "open in browser" fallback. A build-time kill-switch constant (`youtubeEngineKillSwitchOn`) is ANDed into every result — the rollback posture remains a one-line change.
3. **Self-contained packaging** (Phase 2 of the rollout, specs/047 US4): the WPE libraries ride the plugin's bundling; the GStreamer runtime and plugin set WPE needs for MSE playback are bundled at the AppImage level explicitly, because link-time dependency walkers never see runtime-`dlopen`ed GStreamer plugins. Budget: ≤ +150 MB download, ≤ +2 s cold start. The rollout gate is the clean-VM verification in the feature quickstart; failing the bundling gate within budget reopens the route decision rather than relaxing the self-containment contract.
4. **YouTube sign-in screen stays disabled on Linux** until the playback runtime is proven in release; in-player anonymous playback remains the supported posture everywhere (ADR-0025 unchanged).

## Alternatives considered

- **Bundled extractor + `media_kit` (Route B)**: full native control (ideal for shadowing UX: exact seeking, A-B loops) and reuses the CLI-tool pattern; rejected as primary because SABR makes direct-URL streaming the active target of YouTube's anti-extraction work — the operational cost is a perpetual update treadmill, and 2026 field reports already show whole player ecosystems breaking per YouTube change. Retained as the documented fallback if the Route A spike fails its criteria.
- **Pure-Dart extraction** (`youtube_explode_dart` / extending the in-house InnerTube caption fetcher): same churn exposure with a fraction of the fix capacity → rejected.
- **Invidious / Piped public instances**: instance mortality and bot-checks make them unusable as a production dependency → rejected.
- **CEF-based webview**: stale packages, +100 MB Chromium, heavy process model → rejected.
- **Stay opted out**: leaves Linux users with a dead end for a first-class content source → rejected.

## Consequences

- Linux joins the YouTube platform matrix; transcripts/captions needed no change (already platform-independent HTTP).
- The app now ships a second web engine on Linux (WPE + GStreamer alongside libmpv); packaging docs record bundled runtime identities and licenses per release.
- The kill switch gives support a per-release off switch without a code change to call sites; diagnostics keep flowing through the session-banner logging pipeline.
- `youtubeEngineAvailableOnLinux` / `youTubeEngineOptedOutHere` are gone; `YouTubePlaybackUnavailableException` carries the canonical watch URL so the player can offer the browser fallback.

## Risks

- The Linux backend is beta (`0.1.0-beta.1`); the app pins exactly and re-evaluates on every stable 6.2.x release.
- WPE's desktop-Linux diversity (compositors, GL drivers, GPU vendors) is unproven at scale; software rendering is the fallback path and the graceful-unavailable state is the failure path.
- GStreamer plugin completeness inside the AppImage is the highest-risk packaging item (see specs/047 research D3 and quickstart S2).
