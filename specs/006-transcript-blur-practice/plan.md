# Implementation Plan: Transcript Blur (Practice / Listening-Focus Mode)

**Branch**: `[006-transcript-blur-practice]` | **Date**: 2026-07-08 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-transcript-blur-practice/spec.md`

**Note**: Filled by `/speckit-plan`. See `.specify/templates/plan-template.md` for the execution workflow. All Phase 0 / Phase 1 artifacts ([research.md](research.md), [data-model.md](data-model.md), [quickstart.md](quickstart.md), [contracts/](contracts/)) have been generated and integrated. `tasks.md` is the next phase.

## Summary

Add a per-user "Blur practice" mode to the transcript panel. When enabled, every cue body text renders with an `ImageFilter.blur` filter that makes it unreadable while leaving timestamps, recording badges, hover tints, and the active-line rail sharp. The user can peek at a cue in two ways:

- **Desktop** (macOS, Windows): pointer hover over the cue unblurs it; pointer-out re-blurs.
- **Every platform** (including desktop, for touchscreens and reduced-hover users): tap on a blurred cue seeks playback to that cue **and** starts a configurable hold (default 3 s, configurable in Settings → Transcript) during which the cue stays clear. The hold resets on the next tap.

The active playback cue is **never** auto-revealed — that rule was confirmed during the 2026-07-08 clarification session because the feature's purpose is hearing-focused practice. The only way to see any cue's text in blur practice mode is hover (desktop) or a tap-reveal hold (every platform). Implementation introduces **no new Drift tables**, **no new dependencies**, and **no new `media_kit` code** — it only reuses existing Riverpod, settings-Drift, and shared UI primitive plumbing.

## Technical Context

**Language/Version**: Dart 3.x, Flutter stable (current project baseline). No language version bump required.

**Primary Dependencies** (all already in the project): `flutter_riverpod`, `riverpod_annotation`, `drift`, `flutter` (`material.dart`, `widgets.dart` — for `ImageFilter.blur` and `ImageFiltered`). No new packages.

**Storage**: Drift `settings` table via the existing `SettingsDao` (`getValue` / `setValue`). Two new keys added to `lib/data/db/settings_keys.dart` (`prefs.transcript_blur_practice_enabled`, `prefs.transcript_blur_tap_reveal_seconds`). **No schema migration needed** — the table already stores arbitrary key/value rows.

**Testing**: `flutter test` for unit + widget tests; manual smoke on physical devices for scenarios that cannot be automated (Q-07 reduced-motion, Q-08 screen reader parity). No new test infrastructure.

**Target Platform**: Android, iOS, macOS, Windows (per constitution; no Flutter web).

**Project Type**: Flutter native mobile/desktop app, feature-first layout.

**Performance Goals**:
- Toggle on/off: blur appears/disappears on every visible cue within one frame (SC-001).
- Hover (desktop): reveal/unblur within one frame; no flicker between adjacent cues (SC-002).
- Tap-reveal (every platform): reveal within one frame; expiry re-blurs within one frame (SC-004).
- Long-list smoke (10 000 cues, blur on, scroll): no dropped frames beyond the existing baseline (SC-007). Filter is only attached on viewport-visible cues (per [research R-007](research.md)).

**Constraints**:
- Feature-first architecture — all new code under `lib/features/transcript/` (per AGENTS.md hard rule + ADR-0004).
- No `print()`; use `logNamed('transcript_blur')` (per AGENTS.md + docs/conventions.md).
- No new `Player()` instances; tap-to-seek goes through the existing `PlayerInteractions.seekTo(...)` path (per AGENTS.md + ADR-0003).
- Persistence flows through Drift `SettingsDao` (per AGENTS.md + ADR-0002). The existing `AppPreferencesCtrl` is profile-synced — these are device-local UI prefs and **must not** be added there (per [research R-003](research.md)).
- Shared UI primitives (`EnjoyTappableIcon`, `Haptics.selection`, tooltip + semantics conventions) per ADR-0018.
- Reuse existing hover plumbing on `TranscriptLineTile` (per [research R-004](research.md)).

**Scale/Scope**:
- Up to ~10 000 cues per transcript; blur cost bounded by `ListView.builder` viewport (only visible cues pay for the filter).
- 2 new `settings` rows; negligible.
- 1 Timer per open `mediaId` for the tap-reveal hold; bounded.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- **PASS** — All new code lives under `lib/features/transcript/{application,domain,presentation}` (no shortcuts from other features). Domain models (`TranscriptBlurPreferences`, `TapRevealHold`) are UI-free and live in `lib/features/transcript/domain/`. Persistence flows through the existing `SettingsDao`. State uses Riverpod notifiers with the same pattern as `PlayerPreferencesCtrl`.
- **PASS** — No `print()` calls; new logger name `transcript_blur` via `logNamed`. No new `Player()` instances.

### II. Testing Defines the Contract

- **PASS** — Required automated coverage (mirrors QR-002 / SC-001…SC-007):
  - Unit test: `transcript_blur_preferences_provider_test.dart` — hydration from `SettingsDao`, setter persistence, default fallbacks, clamping of `tapRevealSeconds`.
  - Widget test: `transcript_blur_tile_test.dart` — toggle on/off renders blurred / clear text; tooltip + semantics label; disabled state when no lines.
  - Widget test: `transcript_blur_hold_test.dart` — tap on a cue seeks + reveals; second tap replaces the hold; timer expiry re-blurs; the active cue never auto-reveals.
  - Widget test: `transcript_blur_active_line_stays_blurred_test.dart` — drives `transcriptPlaybackHighlightProvider` to different indices while blur is on; asserts no `ImageFiltered` is removed for the active cue until the user explicitly taps/hover-reveals.
  - Performance smoke: `transcript_blur_long_list_perf_test.dart` — pumps 10 000 cues, toggles blur on, scrolls; asserts no extra frames dropped vs. the existing baseline test (e.g. via `tester.binding.framePolicy` / `Timeline`).
- **PASS** — `dart run build_runner build` is required once for the new `@Riverpod` notifier (`.g.dart` will be generated). Listed in the verification block below.
- Manual smoke scenarios that cannot be automated (Q-07 reduced-motion, Q-08 screen reader parity, Q-09 echo mode) are documented in [quickstart.md](quickstart.md) with explicit pass criteria.

### III. User Experience Consistency

- **PASS** — New toggle uses `EnjoyTappableIcon` (per ADR-0018), reuses the existing `Haptics.selection` pipeline, has a tooltip, and announces its semantics state via `Semantics(label: ...)` (new ARB keys, see [contracts/transcript_blur_api.md C-07](contracts/transcript_blur_api.md)).
- **PASS** — All new user-facing strings live in `lib/l10n/app_en.arb` and `lib/l10n/app_zh_CN.arb`; regenerated `app_localizations*.dart` files are produced by `flutter gen-l10n` (already wired in the project).
- **PASS** — Hold-duration setting lives in the existing **Settings → Transcript** section (no new settings tab). It uses the project's existing `SettingsRow` + slider primitive (already used in other Settings sections).
- **PASS** — `docs/features/transcript.md` will be updated with a new "Blur practice mode" section (per QR-005). The section will reference the spec's Clarifications entry that documents the "no active-line auto-reveal" decision.

### IV. Performance Is a Requirement

- **PASS** — Performance budget documented in [research.md R-007](research.md) and reflected in SC-007:
  - Filter only attached when `blurEnabled == true`. When off, zero overhead.
  - Sigma is constant (`6.0`). No animated sigma — only an opacity fade (or instant on/off under reduced-motion).
  - Per-cue Riverpod providers (`transcriptCueRevealProvider(mediaId, cueId)`) so each tile only rebuilds when its own reveal state changes.
  - Hover state is local `StatefulWidget.setState` — no provider fan-out for the per-frame hover flicker.
  - `transcriptPlaybackHighlightProvider` is **not** read by the reveal model, so active-cue changes do not invalidate any reveal provider.
- **PASS** — Evidence path: `transcript_blur_long_list_perf_test.dart` (widget test) + manual smoke on the slowest supported target documented in [quickstart.md](quickstart.md).

### V. Documentation and Traceability

- **PASS** — `docs/features/transcript.md` updated with a new "Blur practice mode" section (per QR-005).
- **PASS** — No new ADR for v1 — every architectural choice reuses existing ADRs (0004 feature-first, 0002 Drift, 0018 shared primitives, 0003 single-player). The "no active-line auto-reveal" decision is captured in the spec's Clarifications section and is fully reversible (a future product change to expose a "reveal active line" toggle would be a small additive change, not an architectural reversal).
- **PASS** — `AGENTS.md` requires no update (no new hard rule or scope change).
- **PASS** — No constitution exception requested.

## Project Structure

### Documentation (this feature)

```text
specs/006-transcript-blur-practice/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/
│   └── transcript_blur_api.md   # Phase 1 output (in-app UI/API contract)
├── checklists/
│   └── requirements.md  # Created by /speckit.specify
├── spec.md              # Source spec
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── features/transcript/
│   ├── application/
│   │   ├── transcript_blur_preferences_provider.dart   # NEW — keepAlive notifier
│   │   ├── transcript_blur_preferences_provider.g.dart # NEW — codegen
│   │   ├── tap_reveal_hold_provider.dart               # NEW — autoDispose notifier (per mediaId)
│   │   ├── tap_reveal_hold_provider.g.dart             # NEW — codegen
│   │   ├── transcript_cue_reveal_provider.dart         # NEW — autoDispose derived family
│   │   └── transcript_cue_reveal_provider.g.dart       # NEW — codegen
│   ├── domain/
│   │   └── transcript_blur.dart                        # NEW — TranscriptBlurPreferences, TapRevealHold, cueIdFor
│   └── presentation/
│       ├── transcript_blur_toolbar.dart                # NEW — toolbar widget with toggle
│       ├── transcript_blur_text.dart                   # NEW — private _BlurText widget (re-exported for tests)
│       ├── transcript_line_tile.dart                   # MODIFIED — read reveal state, compose _BlurText
│       └── transcript_panel.dart                       # MODIFIED — host the toolbar widget
├── core/
│   └── (no changes)
└── data/
    └── db/
        └── settings_keys.dart                          # MODIFIED — add 2 static keys

test/
└── features/transcript/
    ├── transcript_blur_preferences_provider_test.dart   # NEW — unit
    ├── transcript_blur_tile_test.dart                  # NEW — widget
    ├── transcript_blur_hold_test.dart                  # NEW — widget
    ├── transcript_blur_active_line_stays_blurred_test.dart  # NEW — widget
    └── transcript_blur_long_list_perf_test.dart         # NEW — widget smoke

lib/l10n/
├── app_en.arb                                           # MODIFIED — add ~8 new keys
└── app_zh_CN.arb                                        # MODIFIED — mirror

docs/
└── features/transcript.md                               # MODIFIED — new "Blur practice mode" section
```

**Structure Decision**: Single feature folder (`lib/features/transcript/`) with new files scoped to the new behavior. No cross-feature imports. All persistence uses the existing `SettingsDao`. All state uses the existing Riverpod + `@riverpod_annotation` codegen pipeline.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations. No `Complexity Tracking` table needed.

---

## Phase 0 / Phase 1 artifact pointers

- **Phase 0 — Research** (all NEEDS CLARIFICATION resolved): [research.md](research.md). Decisions R-001 through R-010 cover rendering location, toolbar placement, persistence, reveal model, tap-reveal timer, reduced motion, performance budget, echo mode, documentation, and residual risks.
- **Phase 1 — Design**:
  - [data-model.md](data-model.md) — Drift `settings` keys, Riverpod entities (`TranscriptBlurPreferences`, `TapRevealHold`, `TranscriptCueBlurState`), lifecycle, failure handling.
  - [contracts/transcript_blur_api.md](contracts/transcript_blur_api.md) — Public API of the two notifiers, the per-cue derived provider, `cueIdFor` identity, `_BlurText` widget, toolbar widget, ARB keys, test seams.
  - [quickstart.md](quickstart.md) — 10 manual smoke scenarios (Q-01 through Q-10) covering toggle, hover, tap-reveal, active-line rule, hold duration, reduced motion, a11y, echo mode, empty state; plus the `flutter test` commands to run in CI.

## Re-evaluation of Constitution Check post-design

Re-running the Constitution Check after Phase 1 — **all five principles remain PASS**. No new dependencies, no new persistence layer, no new abstraction introduced beyond what is already standard in the project. The decision to *not* create an ADR for v1 is itself covered by ADR-0004 (feature-first) and ADR-0018 (shared primitives); if a future product change warrants one (e.g., promoting the "hold duration" setting to a user-facing strength slider or reversing the no-active-line rule), it will be tracked as its own ADR at that time.

## Verification commands (must run after implementation)

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/features/transcript/transcript_blur_*
flutter test
```

Manual smoke: follow [quickstart.md Q-01 … Q-10](quickstart.md).

## Done When

- [x] Spec exists at `specs/006-transcript-blur-practice/spec.md` and validates against the requirements checklist.
- [x] Phase 0 research closes all open design questions.
- [x] Phase 1 produces data-model, contracts, and quickstart artifacts.
- [x] Constitution Check passes both before and after design.
- [x] This plan.md references every Phase 0 / Phase 1 artifact.
- [ ] `/speckit.tasks` is the next step (tasks are not generated by `/speckit-plan`).
