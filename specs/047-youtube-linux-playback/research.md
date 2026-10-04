# Research: YouTube Playback on Linux (Route A)

**Date**: 2026-10-02 · **Feature**: [spec.md](./spec.md) · Source research: conversation report "YouTube Linux 播放技术路线调研" (2026-10-02), verified against upstream sources same day.

## D1 — Embedded-browser dependency line

**Decision**: Upgrade `flutter_inappwebview` from `^6.1.5` to exactly `6.2.0-beta.3`, pulling the endorsed `flutter_inappwebview_linux` `0.1.0-beta.1`. Pin exactly (ADR-0029 supply-chain precedent; it is a beta from a single-publisher plugin).

**Rationale**:
- 6.1.x stable has **no** Linux backend (confirmed: pub lists Android/iOS/macOS/web/Windows only; `pubspec.lock` has no linux package). Linux support exists only on the 6.2.0-beta line.
- SDK compatibility verified: plugin line requires Flutter ≥ 3.32 / Dart ^3.8; repo pins Flutter **3.44.0** (mise) / Dart **^3.12.0**. ✔
- The Linux native implementation is substantive, not a stub: JS bridge injection (`plugin_scripts_js/javascript_bridge_js.h`), user-content controller (user scripts + handlers), `javascript_handler_function_data`, navigation-action types (URL interception), EGL/texture rendering, headless webview, software-rendering fallback, cookie/storage managers, `WebViewEnvironment` (mirrors the Windows pattern the app already ships in `lib/core/webview/windows_webview_environment.dart`).
- The app's engine only needs three bridge pillars — script evaluation, JS handler callbacks (page→Dart), navigation interception — plus a rendered surface; all four have native machinery on Linux.

**Alternatives considered**:
- `webview_flutter_linux` (community, non-endorsed, WPE): less mature, smaller API surface, no `addJavaScriptHandler`-grade bridge guarantees → rejected.
- CEF-based webviews (`flutter_linux_webview` etc.): stale packages, +100 MB Chromium, heavy process model → rejected.
- DesktopWebviewWindow: no Linux backend → rejected.
- Stay opted out / Route B (yt-dlp + media_kit): Route B is the documented fallback if the spike fails its criteria (spec Assumptions); not the primary. SABR analysis lives in the source research: direct-URL extraction is the approach YouTube is actively killing in 2026, while the embedded-browser route is immune.

## D2 — WPE WebKit rendering backend

**Decision**: Use the plugin's WPE backend as shipped: WPEPlatform API (WPE WebKit 2.40+) preferred, automatic compile-time fallback to WPEBackend-FDO, runtime software-rendering fallback (`utils/software_rendering.cc`) for GPU-less systems.

**Rationale**: The plugin's `linux/CMakeLists.txt` selects the backend itself (dual-path detection with a compile probe for `webkit_web_view_get_wpe_view`), so the app does not choose a backend at all — it inherits the best available one at build time. YouTube-via-WPE is ecosystem-proven (WPE official MSE support: MP4/WebM/VP9, H.264 via GStreamer; Igel TV browser precedent).

**Alternatives considered**: WebKitGTK route (what ADR-0048 originally assumed) — heavier, GTK-coupled, not what the plugin ships → moot.

## D3 — GStreamer codec runtime in the AppImage (highest packaging risk)

**Decision**: Bundle the GStreamer runtime **and plugin set** (at minimum: `gstreamer` core, `gst-plugins-base`, `-good`, `-bad`, `gst-libav`) into the AppImage, and export `GST_PLUGIN_PATH` (plus `GST_PLUGIN_SYSTEM_PATH`) from the AppRun wrapper. Scope of plugins to be finalized by the spike (play a VP9/Opus and an H.264/AAC video; add `webrtc`/`dtls`/`srtp`/`adaptivedemux` variants if MSE demands them).

**Rationale**: The plugin's own bundling (`flutter_inappwebview_linux_bundled_libraries`, `$ORIGIN` RPATH, "no LD_LIBRARY_PATH needed") covers `libWPEWebKit-2.0`, `libwpe-1.0`, and optionally `libWPEBackend-fdo-1.0` — **only the WebKit-side shared objects**. WPE loads its media decode/back-end plugins via `dlopen` at runtime; link-time dependency walkers (linuxdeploy) will never pull them. Without an explicit GStreamer bundle, the webview will render pages but play no video. This is the single most likely failure mode of the whole route and must be spike item #1.

**Alternatives considered**: relying on system GStreamer — violates the spec's self-contained constraint (FR-008) and re-creates the exact distro-fragmentation problem ADR-0048 opted out of → rejected.

## D4 — Runtime availability decision (replaces the build-time constant)

**Decision**: Keep the single decision point at `lib/core/platform/linux_platform_availability.dart` but change its nature from `const bool` to a runtime capability decision backed by a Riverpod provider: (1) plugin registration present, (2) one-time lazy engine-init health probe (create + tear down a headless webview), results cached for the session. Every existing gate call site keeps its shape and just consults the new decision. Retain a compile-time kill switch (const ANDed with the runtime result) so the documented rollback posture ("turn the availability decision off") is a one-line change.

**Rationale**: Spec FR-004/005 demand runtime detection with a graceful localized unavailable state; preserving the single decision point means zero drift across the six gate call sites (`player_open_coordinator`, `engine_swap_coordinator`, `player_controller.warmYoutubeSurface`, `youtube_player_engine` mount/open, `youtube_video_stage`, `youtube_login_screen`).

**Alternatives considered**: per-call-site try/catch — scatters policy, fails FR-004's "single decision point" wording → rejected. Asking the OS package manager — contradicts self-containment → rejected.

## D5 — Four-platform regression strategy (6.1.5 → 6.2.0-beta.3)

**Decision**: Treat the dependency upgrade as the risk carrier: (a) changelog diff review of 6.1.5…6.2.0-beta.3 before merge; (b) full CI matrix green (Android/iOS/macOS/Windows/Linux build workflows); (c) the per-platform smoke checklist in [contracts/platform-smoke-checklist.md](./contracts/platform-smoke-checklist.md) executed manually on all four platforms from the feature branch; (d) merge only after all four report zero diffs (spec US5/SC-007).

**Rationale**: The upgrade touches all platforms simultaneously; the spec makes "no silent trades" explicit (US5 scenario 3).

**Alternatives considered**: version-conditional code (6.1.5 on mobile, 6.2.0-beta on desktop) — pub cannot express per-platform dependency versions cleanly; two version lines of the same federated plugin in one app is not supportable → rejected.

## D6 — YouTube sign-in screen on Linux

**Decision**: Deferred (spec default). The screen stays behind the availability decision; when YouTube is available on Linux it MAY be enabled as a follow-up, out of this feature's scope. When unavailable it stays hidden with the localized explanation (FR-007).

**Rationale**: In-player anonymous playback is the app's supported posture everywhere (ADR-0025 cancels sign-in navigation inside the player); the sign-in screen is an auxiliary surface whose Linux enablement adds WebView cookie/session questions irrelevant to the core feature.

## D7 — m.youtube.com page compatibility on the Linux backend

**Decision**: Spike item: load `m.youtube.com/watch?v=<id>` on the Linux backend unchanged first. If YouTube serves a degraded/broken experience for the WPE user agent, adapt via the engine's existing initial-settings surface (custom user agent matching the Windows backend's), not by patching page HTML.

**Rationale**: The engine already loads the mobile watch page and speaks to `#movie_player` + `<video>`; the less page-side variation between platforms, the more of `youtube_webview_bridge.dart` stays genuinely shared. UA is the one lever the plugin exposes cleanly per-platform.

## D8 — Dependency update & maintenance model

**Decision**: WPE WebKit and GStreamer ride the normal release train (rebuilt per release from the build image; versions recorded in packaging docs per FR-008/SC-008). The plugin pin is revisited on every stable 6.2.x release; no auto-update machinery for bundled runtimes (matches the direct-download update model from spec 014).

**Rationale**: YouTube page changes are absorbed by YouTube's own shipped player code (the core route advantage vs. Route B's extractor-churn treadmill); native runtime updates are infrequent and release-cadenced.

## Open risks carried into the spike (all must be answered by quickstart scenarios)

1. **GStreamer plugin set completeness** for MSE playback (D3) — most likely failure.
2. **EGL/DMA-BUF surface** on Wayland + NVIDIA and on llvmpipe/VMs (software fallback path).
3. **m.youtube.com behavior under WPE UA** (D7).
4. **CPU/memory of WebKit+YouTube page** on the test VM (SC-004 budget).
5. **Plugin stability**: `0.1.0-beta.1` community reports mention hard-coded `/usr/lib/wpe-webkit-2.0` paths in the wild — current master carries the `$ORIGIN` RPATH bundling; if the pub-published revision still exhibits it, override to a git ref that includes the fix (documented in the ADR).
6. **Cold-start cost** of first WebViewEnvironment creation (SC-005 budget).
