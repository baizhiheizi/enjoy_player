---
description: "Task list for YouTube playback on Linux (feature 047)"
---

# Tasks: YouTube Playback on Linux

**Input**: Design documents from `/specs/047-youtube-linux-playback/`

**Prerequisites**: plan.md, spec.md, research.md (decisions D1–D8), data-model.md, contracts/runtime-availability.md, contracts/release-artifact.md, contracts/platform-smoke-checklist.md, quickstart.md

**Tests**: Included — Constitution Principle II requires the narrowest automated tests proving each changed contract (availability decision, gate call sites, unavailable UI). Native browser behavior on real systems is covered by the documented manual scenarios of quickstart.md, which are first-class tasks below (S1–S6, C1–C12).

**Organization**: Grouped by user story (spec.md: US1 P1 → US2 P1 → US3 P2 → US4 P2 → US5 P2).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1…US5)
- Exact repo paths included in every description

## Path Conventions

Single Flutter project: `lib/` and `test/` at repository root (test/ mirrors lib/). Decision home stays at `lib/core/platform/linux_platform_availability.dart`; engine work confined to `lib/features/player/`; packaging in `linux/packaging/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Branch, dependency line, and Linux build-time WPE discovery ready

- [ ] T001 Create branch `047-youtube-linux-playback` from current `main`; record baseline: `flutter analyze` and `flutter test` green on the starting commit (AGENTS.md hard rule — every later edit must return to green)
- [ ] T002 Upgrade `pubspec.yaml` to `flutter_inappwebview: 6.2.0-beta.3` (exact pin, ADR-0029 precedent; research D1) and run `flutter pub get`; verify `flutter_inappwebview_linux` 0.1.0-beta.1 resolves transitively in `pubspec.lock`; fix any compile errors on Android/iOS/macOS/Windows code paths introduced by the upgrade and note each in the PR (feeds US5 changelog review)
- [ ] T003 [P] Add build-time pkg-config discovery to `linux/CMakeLists.txt` mirroring the plugin's own probes (wpe-webkit / libwpe / wpe-platform or wpebackend-fdo / libsecret / epoxy / wayland-server per `flutter_inappwebview_linux/linux/CMakeLists.txt`) so `flutter build linux` compiles on a dev machine with WPE dev packages installed; dev-only — user machines never need these (bundling is Phase 6)

**Checkpoint**: `flutter build linux --debug` succeeds with the new dependency; all other platforms still compile; `flutter analyze` + `flutter test` green.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The runtime availability decision — every user story depends on it

**⚠️ CRITICAL**: No user story work until this phase is complete.

- [ ] T004 Replace the build-time constant in `lib/core/platform/linux_platform_availability.dart` with the runtime decision per `specs/047-youtube-linux-playback/contracts/runtime-availability.md`: `YouTubeAvailable` / `YouTubeUnavailable{reason}` sealed types (reasons `UnsupportedPlatform | RuntimeMissing | RuntimeInitFailed | DisabledByBuild`), `resolveYouTubeAvailability(Ref)` Riverpod provider (lazy, resolved once per process, concurrent callers share one probe), probe = create + trivially load + tear down a headless webview with the ≤ 5 s bound of data-model Entity 2 (`RuntimeInitFailed` on bound breach), probe failures logged via `logNamed` and never thrown to callers (A3/A6/A7), non-Linux short-circuit to available with no probe (A1), and the retained build-time kill-switch constant ANDed into every result (A4, rollback posture SC-008)
- [ ] T005 [P] Create `lib/core/webview/linux_webview_environment.dart` mirroring `lib/core/webview/windows_webview_environment.dart`: shared Linux WebViewEnvironment bootstrap consumed by all webview surfaces (plan structure; plugin requires an environment on Linux)
- [ ] T006 Wire the Linux environment bootstrap in `lib/main.dart` beside the Windows WebView2 environment creation (idempotent, off the first-frame path, failure recorded as probe input — not a startup crash)
- [ ] T007 Extend the reason taxonomy in `lib/features/player/domain/youtube_playback_unavailable_exception.dart`: map the new runtime reasons (`RuntimeMissing` / `RuntimeInitFailed`) onto the existing localized surfacing path alongside the legacy `linuxOptedOut` case (keep the old factory for the kill-switch path)
- [ ] T008 [P] Add ARB strings for every new user-facing surface in all supported locale files under `lib/l10n/`: unavailable message variants (per `RuntimeMissing` / `RuntimeInitFailed` / `DisabledByBuild`), "open in browser" action label, YouTube sign-in deferred notice (FR-012, U1)
- [ ] T009 [P] Create `test/core/platform/linux_platform_availability_test.dart`: kill switch forces `DisabledByBuild` (A4); non-Linux short-circuit never probes (A1); single resolution under concurrent callers (A2); probe timeout maps to `RuntimeInitFailed` (A6); probe failure surfaces as unavailable, not an exception (A3); fake the probe via a test seam on the provider

**Checkpoint**: Decision compiles and is proven by unit tests; app behavior unchanged everywhere (no call site consults it yet — `flutter test` green). User story implementation can begin.

---

## Phase 3: User Story 1 — A Linux user can watch a YouTube video inside Enjoy Player (Priority: P1) 🎯 MVP

**Goal**: On a dev-class Linux machine, pasting a YouTube URL plays video in-app with working transport controls and transcript tracking.

**Independent Test**: Paste a known public YouTube URL on a Linux debug build → video plays, controls work, transcript tracks (spec US1 scenarios; quickstart S1/S5/S6).

### Implementation for User Story 1

- [ ] T010 [US1] Enable the Linux path in `lib/features/player/application/engines/youtube/youtube_player_engine.dart`: replace the Linux mount no-ops and `open` throw (lines ~121/137/159-160) with consultation of `resolveYouTubeAvailability`; mount and open only when available; surface the unavailable exception otherwise
- [ ] T011 [US1] Mount the WebView surface on Linux in `lib/features/player/application/engines/youtube/youtube_webview_host.dart` using the plugin's texture/platform-view rendering with the shared Linux environment (T005); Windows/macOS mounting path must remain byte-identical in behavior
- [ ] T012 [US1] Wire controller plumbing in `lib/features/player/application/engines/youtube/youtube_webview_controller.dart` and `lib/features/player/application/engines/youtube/youtube_js_channel.dart`: environment handoff, `addJavaScriptHandler` registration (`onVideoEvent`, `onAdReload`), `evaluateJavascript` path; `youtube_webview_bridge.dart` poll loop and JS call set stay untouched (contract invariant — no Linux-only bridge dialect)
- [ ] T013 [US1] Rewire the gate call sites to the runtime decision, allow-path: `lib/features/player/application/player_open_coordinator.dart` (~line 266), `lib/features/player/application/engine_swap_coordinator.dart` (~line 230), `lib/features/player/application/player_controller.dart` `warmYoutubeSurface` (~line 383), `lib/features/player/presentation/widgets/youtube_video_stage.dart` (~line 48) — same call-site shape, new decision source
- [ ] T014 [US1] Widget test in `test/features/player/`: with the availability provider overridden to available, the video stage mounts the YouTube engine and the open coordinator proceeds; with a non-Linux platform fake, behavior is identical to today (contract A1/A5 regression guard)
- [ ] T015 [US1] Run quickstart spike **S1** on a dev machine: paste-URL → plays in debug build; if m.youtube.com misbehaves under the WPE user agent, apply the engine's existing user-agent setting per research D7 and retry once; record evidence for the PR
- [ ] T016 [P] [US1] Run quickstart spike **S3** (after S1 passes): Wayland session, X11 session, and GPU-less/llvmpipe rendering — video renders in all three, software fallback engages without crash; record evidence
- [ ] T017 [P] [US1] Run quickstart spike **S5** (after S1 passes): 10-minute video with transcript open, side-by-side vs Windows — no visible highlight drift (SC-003)
- [ ] T018 [US1] Walk spec US1 acceptance scenarios 1–5 end-to-end on the Linux build (paste URL, controls ≤ 300 ms, transcript tracking, metadata display, resume) and file the evidence block in the PR

**Checkpoint**: MVP — YouTube plays on Linux dev machines. If S1 cannot pass after documented attempts, STOP: convene the Route B fallback decision per spec Assumptions and record it in the ADR before any further work.

---

## Phase 4: User Story 2 — YouTube unavailability degrades gracefully, never crashes (Priority: P1)

**Goal**: On any Linux system where the engine cannot initialize, every YouTube entry point shows the localized unavailable state with a browser fallback; nothing crashes or hangs.

**Independent Test**: With the availability provider forced unavailable (widget tests) and with a simulated broken runtime (manual), all six entry points degrade per data-model Entity 3 (spec US2 scenarios).

### Implementation for User Story 2

- [ ] T019 [US2] Implement the unavailable surfacing for user-initiated opens on the existing exception path (`lib/features/player/presentation/expanded_player_screen.dart` ~line 53): localized message by reason (T007) + "open in browser" action opening the canonical watch URL via the existing URL-launcher pathway, launch failure contained (U2)
- [ ] T020 [US2] Implement the unavailable branches at the remaining entry points per data-model Entity 3: warm-up silent no-op with diagnostic log (`lib/features/player/application/player_controller.dart`), engine swap refusal (`lib/features/player/application/engine_swap_coordinator.dart`), stage shows unavailable state not a spinner (`lib/features/player/presentation/widgets/youtube_video_stage.dart`), sign-in screen hidden with localized notice (`lib/features/player/presentation/youtube_login_screen.dart` ~line 68)
- [ ] T021 [P] [US2] Widget tests in `test/features/player/` using the provider override seam (U3): force each unavailability reason and assert every entry point's behavior — message + action for opens, silent warm-up, no-spinner stage, hidden sign-in — no unhandled exceptions anywhere (SC-006 basis)
- [ ] T022 [US2] Manual broken-runtime simulation on a dev machine per quickstart Phase 2 step 2: force a probe failure (kill switch on + injected environment failure), walk all six entry points, confirm zero crashes and a working app afterwards; record evidence

**Checkpoint**: US1 + US2 both proven — playback works when the runtime is healthy, degradation is polished when it is not.

---

## Phase 5: User Story 3 — YouTube surfaces reach parity with other desktop platforms (Priority: P2)

**Goal**: Discover tiles, caption/transcript flows, sign-in navigation policy, and rapid engine swaps behave on Linux exactly as on Windows/macOS.

**Independent Test**: Walk Discover → open → captions → bilingual transcript → rapid local↔YouTube swaps on Linux vs Windows with no behavioral difference (spec US3 scenarios).

### Implementation for User Story 3

- [ ] T023 [US3] Verify in-player Google sign-in navigation cancellation on Linux (FR-006, ADR-0025): exercise the navigation-interception path (`lib/features/player/application/engines/youtube/youtube_webview_controller.dart` `shouldOverrideUrlLoading` wiring) on the Linux backend; adapt wiring if the Linux plugin API differs, keeping the shared policy code untouched
- [ ] T024 [US3] Finalize `lib/features/player/presentation/youtube_login_screen.dart` Linux behavior per research D6 / FR-007: hidden until the decision is available, localized deferred notice when reachable; enablement of actual sign-in on Linux stays out of scope
- [ ] T025 [US3] Rapid-swap stability: local file ↔ YouTube ×4 in both directions on Linux — no ghost audio, no leaked surface, second open succeeds (US3 scenario 5; C10); fix any engine-teardown leak found and add a regression widget test if reproducible in the test harness
- [ ] T026 [US3] Parity verification pass: captions + language-aware selection + bilingual transcript on Linux (FR-003, C5/C6) and Discover tile → open → play end-to-end (US3 scenario 2, C7); record side-by-side evidence vs Windows

**Checkpoint**: All YouTube surfaces behave identically to Windows/macOS on Linux.

---

## Phase 6: User Story 4 — The Linux release stays self-contained (Priority: P2)

**Goal**: The AppImage plays YouTube on clean VMs of every supported baseline with zero system packages, within the size/startup budgets.

**Independent Test**: Release AppImage on a clean Ubuntu 22.04 VM: launch, play local file, play YouTube video — no `apt install`; measurements within budgets (spec US4 scenarios; quickstart S2 + Phase 2 step 1).

### Implementation for User Story 4

- [ ] T027 [US4] Extend `linux/packaging/make_appimage.sh`: bundle the GStreamer runtime + plugin set and export `GST_PLUGIN_PATH` / `GST_PLUGIN_SYSTEM_PATH` from the AppRun wrapper (contract R3, research D3); iterate until quickstart **S2** passes — VP9/Opus and H.264/AAC both play from inside the AppImage; freeze the final plugin list as the R3 output
- [ ] T028 [US4] Verify the WPE bundling path end-to-end (contract R2): `libWPEWebKit-*` / `libwpe-1.0` (and FDO backend when compiled) land in the bundle and load via `$ORIGIN` RPATH with no `LD_LIBRARY_PATH`; if the pub-published plugin revision lacks the RPATH bundling, switch to a git-ref dependency override containing it and record the pin in the ADR (research risk 5)
- [ ] T029 [P] [US4] Verify transitive link-time deps resolve inside the bundle (contract R4): libsecret, epoxy, wayland-server — and that absence of a desktop keyring degrades gracefully without blocking startup
- [ ] T030 [US4] Clean-VM matrix (contract R1): Ubuntu 22.04 LTS, Debian 12, Fedora 40, Arch snapshot — on each, launch the AppImage with zero installs, play a local file AND a YouTube video; record per-VM evidence
- [ ] T031 [US4] Budget measurements (contract R5/R6, quickstart S4): download size delta vs previous release (≤ +150 MB or documented justification), cold-start median ×5 on the documented test VM (≤ +2 s), open-to-first-frame ×5 (≤ 5 s), 10-min playback CPU/memory shape; record all four
- [ ] T032 [US4] Exercise `.github/workflows/release_linux.yml` packaging path end-to-end: the release workflow produces a working AppImage containing the new runtime (not just local `make_appimage.sh`)
- [ ] T033 [US4] Broken-bundle behavior (contract R8): rename the bundled WPE library in an extracted AppImage → app starts, local playback works, YouTube shows the graceful unavailable state (US2 path), nothing crashes
- [ ] T034 [US4] License inventory (contract R9): WPE WebKit / GStreamer versions + licenses and the bundled-plugin list recorded, redistribution rights confirmed for every bundled .so

**Checkpoint**: Self-containment proven. **If S2 (T027) cannot pass within the size budget, this is the Route A failure point — convene the Route B fallback decision per spec Assumptions; do not relax the self-containment contract silently.**

---

## Phase 7: User Story 5 — Shipping Linux YouTube does not regress the other four platforms (Priority: P2)

**Goal**: Android, iOS, macOS, and Windows YouTube playback is unchanged, proven by CI plus the fixed smoke checklist.

**Independent Test**: Feature-branch builds on all four platforms pass checklist C1–C12 with `behaviorDiff: none` (spec US5; contracts/platform-smoke-checklist.md).

### Implementation for User Story 5

- [ ] T035 [P] [US5] Changelog diff review of `flutter_inappwebview` 6.1.5…6.2.0-beta.3 (research D5a): list behavior-relevant changes in the PR, note which affect the four platforms, and map each to a smoke checklist step
- [ ] T036 [US5] Full CI matrix green on the feature branch: Android, iOS, macOS, Windows, Linux build/test workflows (research D5b)
- [ ] T037 [US5] Execute checklist C1–C12 from `specs/047-youtube-linux-playback/contracts/platform-smoke-checklist.md` on Android, iOS, macOS, and Windows builds; post the four result rows in the PR; any `behaviorDiff` → fix or explicit recorded trade per US5 scenario 3 (merge gate)

**Checkpoint**: Four-platform regression gate satisfied — the merge can proceed.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, rollback posture, rollout evidence, final gates

- [ ] T038 [P] Write `docs/decisions/` ADR `00XX-youtube-linux-playback.md` (next free number): route chosen (embedded-browser, Route A) with the SABR rationale, alternatives rejected (yt-dlp+media_kit as documented fallback, pure-Dart extraction, Invidious/Piped, CEF), runtime-availability policy, bundled-runtime implications, sign-in deferral, ToS posture, and explicit supersession of the ADR-0048 Linux opt-out clause (R1/R6) (FR-011)
- [ ] T039 [P] Update `docs/features/linux-platform.md` (YouTube moves from opted-out to supported, unavailable-state behavior) and `docs/features/youtube.md` (platform matrix gains Linux) (FR-011)
- [ ] T040 [P] Update `docs/packaging.md`: bundled runtime identities/versions, GStreamer plugin list, size/cold-start budgets and the measured values (R7, data-model Entity 4)
- [ ] T041 Rollback drill (SC-008): flip the kill-switch constant in `lib/core/platform/linux_platform_availability.dart`, rebuild, confirm every YouTube entry point shows the graceful unavailable state and local playback is unaffected; revert. One-line diff, no other changes
- [ ] T042 Rollout verification: run quickstart Phase 2 in full on the release candidate — clean-VM self-containment, unavailable simulation, end-to-end timing, 24 h mixed soak (SC-004: no crash, no audio after close, flat final-hour memory), browser fallback — and file the evidence under scenario IDs (FR-009; data-model Entity 6)
- [ ] T043 Final gates: `bash .github/scripts/validate_ci_gates.sh --all` (format across `lib/`, `test/`, `packages/*/lib`, `packages/*/test`; codegen drift; analyze; full `flutter test`) — zero errors before merge request

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies — starts immediately; T002 is the risk carrier (exposes cross-platform compile fallout earliest)
- **Foundational (Phase 2)**: depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: depends on Phase 2; contains the first go/no-go evidence (S1, T015). **S1 fail = stop and convene the Route B fallback decision**
- **US2 (Phase 4)**: depends on Phase 2 (decision + reasons); independent of US1's play-path tasks except sharing T013's call sites — sequence after US1 to avoid same-file contention
- **US3 (Phase 5)**: depends on US1 + US2 (parity is only meaningful once both paths exist)
- **US4 (Phase 6)**: depends on US1 + US2 (packaging bundles what the stories proved); contains the second go/no-go evidence (S2, T027). **S2 fail within budget = Route A failure point**
- **US5 (Phase 7)**: T035 can run from Phase 1 onward; T036/T037 gate the merge after all functional phases
- **Polish (Phase 8)**: T038–T040 can draft in parallel with Phase 6/7; T041–T043 require everything before them

### User Story Dependencies

- **US1**: Foundational only. No cross-story dependency. MVP alone.
- **US2**: Foundational only (shares call-site files with US1 — implement after US1)
- **US3**: US1 + US2
- **US4**: US1 + US2
- **US5**: independent execution, merge-gating position last

### Parallel Opportunities

- Within Phase 2: T005, T008, T009 run together (different files)
- Within US1: T016, T017 after T015 passes (independent scenarios, same build)
- Within US4: T029 alongside T027/T028 (different verification surface)
- Cross-phase: T035 any time after T002; T038–T040 any time after Phase 3 evidence exists

---

## Parallel Example: User Story 1

```text
# After Phase 2 completes:
Task: "T010 engine Linux path (youtube_player_engine.dart)"
Task: "T011 host mounting (youtube_webview_host.dart)"          # different file
# T012 and T013 follow (they touch the wiring those two produce)

# After T015 (S1) passes:
Task: "T016 S3 rendering matrix"
Task: "T017 S5 transcript sync parity"                           # independent scenarios
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 Setup → Phase 2 Foundational
2. Phase 3 US1 → **STOP at T015**: S1 is the first go/no-go. Fail here = Route B decision, minimal sunk cost
3. If green: US1 alone already delivers "YouTube plays on Linux" on dev machines

### Incremental Delivery

1. Setup + Foundational → decision proven by unit tests, zero behavior change
2. US1 → playback works (MVP!) → S3/S5/S6 evidence
3. US2 → degradation polished (both P1 stories now done = feature-shippable core)
4. US3 → parity walk clean
5. US4 → **second go/no-go at S2/T027**: self-contained artifact or fallback decision
6. US5 → four-platform `behaviorDiff: none` rows posted
7. Polish → ADR/docs/rollback/soak → merge

### Parallel Team Strategy

One developer, sequential, is the baseline plan (~2–3 weeks). With two:
Engine work (US1→US3, Phases 3–5) and packaging/verification (T027–T034, US4 infrastructure tasks) can start interleaving once Phase 2 lands, meeting at the S2 evidence point.

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Quickstart scenario IDs (S1–S6) and checklist IDs (C1–C12) are stable evidence keys referenced from the spec and future ADR — do not renumber
- Every code task ends green: `flutter analyze` + `flutter test` (AGENTS.md hard rule); platform compile smoke via `flutter build linux` and the CI matrix
- Commit after each task or logical group; the two go/no-go points (T015, T027) are explicit stopping points where continuing means a recorded decision, not momentum
