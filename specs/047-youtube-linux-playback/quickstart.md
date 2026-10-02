# Quickstart: Validation Guide — YouTube Playback on Linux

**Feature**: [spec.md](./spec.md) · Contracts: [runtime-availability](./contracts/runtime-availability.md) · [release-artifact](./contracts/release-artifact.md) · [smoke checklist](./contracts/platform-smoke-checklist.md)

This guide has two phases: the **Spike** (go/no-go for Route A — run first,
cheap, dev machine + one clean VM) and **Rollout Verification** (FR-009
evidence — run on the release candidate). Scenario IDs are stable and are
referenced from the spec/ADR as evidence keys.

## Prerequisites

- Linux dev machine (Arch/Ubuntu) with the repo toolchain: `mise install` (Flutter 3.44.0), GTK3 + `pkg-config` headers
- Dev-time WPE packages (build only — never required on user machines): the WebKit/WPE dev packages the plugin's CMake probes for (`wpe-webkit-2.0`/`wpe-1.0`/`wpe-platform-2.0` or `wpebackend-fdo-1.0`, `libsecret-1`, `epoxy`, `wayland-server`) — on Arch: `wpewebkit libwpe wpebackend-fdo libsecret`; on Ubuntu: `libwpewebkit-2.0-dev libwpe-1.0-1 libwpebackend-fdo-1.0-dev libsecret-1-0 libepoxy-dev`
- One clean-VM image per supported baseline (Ubuntu 22.04 LTS, Debian 12, Fedora 40, Arch snapshot) for rollout phase
- A known public YouTube video with captions, and one H.264/AAC-heavy video for codec coverage

## Build & run

```bash
mise install
flutter pub get
flutter analyze && flutter test          # gates must be green before any device-level work
flutter build linux --debug              # first compile exercises the plugin's WPE detection
flutter build linux --release
bash linux/packaging/make_appimage.sh    # produces the artifact used below
```

## Phase 1 — Spike (go/no-go; each scenario answers a research risk)

| ID | Scenario | Answers | Pass criterion |
|----|----------|---------|----------------|
| S1 | From a debug build, paste a public YouTube URL and open it | risk 3 (page/UA), risk 1 (codecs) | Page loads, video plays with audio; if the page is degraded, retry once with the Windows-backend user agent before judging fail |
| S2 | Play both a VP9/Opus and an H.264/AAC video; note missing-codec errors in the diagnostic log; iterate the bundled GStreamer plugin set until both play inside the AppImage | risk 1 → produces the R3 plugin list for the artifact contract | Both codecs play from the AppImage; final plugin list recorded |
| S3 | Run the AppImage on Wayland (NVIDIA if available) and on a GPU-less VM (llvmpipe) | risk 2 (EGL/DMA-BUF, software fallback) | Video renders in both sessions; software fallback engages without crash |
| S4 | Measure: artifact size delta vs. current release; cold-start-to-window ×5 median; open-to-first-frame ×5 median; 10-min playback CPU/mem shape | risk 4, risk 6; budgets SC-005 | Size ≤ +150 MB; cold start ≤ prev + 2 s; first frame ≤ 5 s; no runaway memory |
| S5 | Watch a 10-minute video with transcript open; compare transcript highlight sync side-by-side with the same video on Windows | SC-003 parity | No visible drift vs. Windows |
| S6 | Exercise the three bridge pillars explicitly: seek via transport UI, verify page→Dart events arrive, click an in-player link that would navigate to Google sign-in | D1's bridge-pillar claim | All three behave as on Windows/macOS; sign-in navigation cancelled |

**Fail handling**: any S-scenario that cannot pass after documented attempts
convenes the Route B fallback decision (spec Assumptions) — recorded in the
ADR with the failing evidence, not silently retried forever.

## Phase 2 — Rollout verification (FR-009 evidence on the release candidate)

1. **Self-containment (US4/SC-001)**: copy the release AppImage to each clean baseline VM; launch without installing anything; play a local file AND a YouTube video. Record cold-start median ×5 per VM.
2. **Unavailable-state simulation (SC-006)**: on one VM, simulate a broken runtime by renaming the bundled WPE library inside the extracted AppImage; walk every YouTube entry point (URL paste, Discover tile, library item, warm-up, engine swap, sign-in screen) and confirm the localized unavailable message + browser action everywhere, zero crashes, app keeps working. Restore afterwards.
3. **End-to-end timing (SC-001/SC-002)**: launch → paste URL → first frame, ×5, on the Ubuntu 22.04 VM.
4. **Soak (SC-004)**: 24 h mixed local+YouTube session; confirm no crash, no audio after close, flat memory over the final hour.
5. **Browser fallback (U2)**: with playback working, invoke the unavailable-state browser action path via the simulated-broken setup from step 2; confirm the video opens in the system browser.
6. **Evidence**: file the measurements under the scenario IDs in the ADR/PR (data-model Entity 6). Rollout is blocked on any fail.

## Four-platform regression gate (before merge)

Execute [contracts/platform-smoke-checklist.md](./contracts/platform-smoke-checklist.md)
C1–C12 on Android, iOS, macOS, Windows builds from the feature branch; record
the four result rows in the PR. All `behaviorDiff: none` required (US5).

## Where each spec criterion gets its proof

| Spec | Proven by |
|------|-----------|
| SC-001 | Phase 2 step 1 + 3 |
| SC-002 | Phase 2 step 3 (vs. Windows numbers) |
| SC-003 | S5 + Phase 2 step 4 |
| SC-004 | Phase 2 step 4 |
| SC-005 | S4 + Phase 2 step 1 measurements → artifact contract R5/R6 |
| SC-006 | Phase 2 step 2 |
| SC-007 | Platform smoke rows |
| SC-008 | ADR + packaging docs (R7) landed in the same change |

## Spike evidence (2026-10-02, S1 executed)

- **S1 PASS (with caveat)**: Arch dev machine (amdgpu, Hyprland/Wayland, wpewebkit
  2.52.6). Watch page loads, availability probe passes, JS bridge live (events,
  pause/play, volume restore, position tracking all verified in logs), audio and
  playback state work end-to-end. Picture requires `LIBGL_ALWAYS_SOFTWARE=1` on
  this stack: with hardware GL, WPE 2.52's frame export delivers **zero frames**
  to the plugin (both EGL zero-copy and SHM readback stall); with software GL the
  full chain renders and animates (verified via screenshot diff + pixel stats in
  a standalone plugin-example reproduction, not just the app).
- **Codec set confirmed** (research D3): `gst-plugins-good` + `gst-plugins-bad` +
  `gst-libav` required (`base` arrives with wpewebkit); without them playback
  spins forever (no demux/decode).
- **Two upstream bugs filed as evidence**: `initialUrlRequest` is a no-op on the
  Linux backend (must `loadUrl` from `onWebViewCreated`); WebView teardown can
  hit `Fatal glibc error: pthread_mutex_lock ... ESRCH` (dispose race).
- **Rollout consequence**: hardware-frame export is the T030 matrix's first
  checkpoint (per-GPU/driver); the software-GL fallback is the verified safety
  net, and T027's bundled-WPE version choice (known-good 2.4x from the Ubuntu
  build environment) is the likely hardware fix.
