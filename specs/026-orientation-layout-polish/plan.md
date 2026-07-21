# Implementation Plan: Phone / Tablet Orientation & Player Layout Polish

**Branch**: `main` (no git extension; spec dir `026-orientation-layout-polish`) | **Date**: 2026-07-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/026-orientation-layout-polish/spec.md`

## Summary

Polish orientation behavior in two coordinated places:

1. **App-wide orientation policy by form factor.** Phone-class Android/iOS devices lock to portrait so the app does not auto-rotate. Tablet-class devices keep full auto-rotation. Desktop windows stay freely resizable (no mobile orientation lock).

2. **Player video + transcript layout by window aspect.** `VideoPlayerLayout` switches stacked vs side-by-side from whether the layout constraints are landscape (`width > height`) or portrait (`height >= width`), replacing today’s `breakpointTranscriptSideBySide` (720) gate for that decision. Transport-bar packing and other width-driven UI keep using width breakpoints.

Technical approach: add small pure helpers under `lib/core/platform/` for form-factor classification and preferred orientations; apply them once at bootstrap via `SystemChrome.setPreferredOrientations`; change the side-by-side predicate inside `VideoPlayerLayout` to aspect-based; update widget tests and player/app-ui docs; record an ADR for the product policy.

## Technical Context

**Language/Version**: Dart / Flutter (stable channel); SDK bound in `pubspec.yaml` (`environment: sdk: ^3.12.0`). No SDK bump.

**Primary Dependencies**: Flutter `services` (`SystemChrome` / `DeviceOrientation`), existing `EnjoyThemeTokens`, Riverpod only where player layout already reads providers. No new pub packages.

**Storage**: N/A for orientation policy. Existing player `splitPx` preference remains the side-by-side transcript width store; no new settings keys.

**Testing**: `flutter test` — unit tests for form-factor / preferred-orientation / side-by-side pure helpers; update `test/features/player/video_player_layout_test.dart` for aspect-based layout (including wide-portrait stacked and narrow-landscape side-by-side). Manual device/simulator checks in `quickstart.md`. No `build_runner` unless a `@Riverpod` helper is added (prefer pure functions — none expected).

**Target Platform**: Android, iOS (phone + tablet), macOS, Windows, Linux. No Flutter web (ADR-0048).

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals**: Orientation / window-reshape must not restart the player engine or drop the session. Layout switch is a single `LayoutBuilder` rebuild (O(1) predicate). Target: settle within one frame after metrics update; playback position continuity per SC-004.

**Constraints**: Local-first; no Settings toggle in v1; do not override OS rotation lock; keep `breakpointTranscriptSideBySide` for transport / other width UI; single `media_kit` player ownership unchanged; no `print()`.

**Scale/Scope**: Phone vs tablet classification (~600 dp shortest side); player layouts from ~320×568 phones through iPad / desktop windows. Affects bootstrap + `VideoPlayerLayout` + docs/ADR.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- ✅ Orientation policy helpers live in `lib/core/platform/` (shared, not feature↔feature). Player layout change stays in `lib/features/player/presentation/layouts/`.
- ✅ Pure classification / layout predicates stay UI-free and unit-testable (no Flutter widget imports in the pure helpers file if practical; `TargetPlatform` from `foundation` is acceptable).
- ✅ No new mutable global singletons; `SystemChrome.setPreferredOrientations` is applied once at bootstrap (same pattern as other one-shot platform setup in `main.dart`).
- ✅ No `print()`; no new `media_kit` `Player()`.

### II. Testing Defines the Contract

- ✅ Unit: form factor resolution (phone / tablet / desktop), preferred orientation lists, `usePlayerSideBySideLayout(width, height)` (landscape / portrait / square).
- ✅ Widget: rewrite aspect cases in `video_player_layout_test.dart` — wide portrait stacks; landscape side-by-side even below 720 width when height is smaller; square stacks.
- ✅ Manual: phone lock + tablet rotate + desktop reshape (`quickstart.md`). Platform orientation APIs are hard to assert fully in CI.
- ✅ `dart run build_runner build` **not** required if helpers stay non-annotated.

### III. User Experience Consistency

- ✅ No new user-facing strings or settings (spec assumption).
- ✅ Shared UI primitives unchanged; haptics/tooltips unaffected.
- ✅ Docs: `docs/features/player.md`, `docs/features/app-ui.md` (VideoPlayerLayout row).

### IV. Performance Is a Requirement

- ✅ Layout predicate is O(1) inside existing `LayoutBuilder`; no new streams or isolates.
- ✅ Must not dispose/recreate `PlayerEngine` / WebView on orientation change — only rearrange stage + transcript slots.
- ✅ Evidence: widget tests + manual rotate during playback (quickstart).

### V. Documentation and Traceability

- ✅ Feature docs updates (player + app-ui).
- ✅ New ADR `docs/decisions/0059-phone-tablet-orientation-and-player-aspect-layout.md` (product-scope, costly to reverse).
- ✅ Optional: tighten `ios/Runner/Info.plist` iPhone orientations to portrait-only to match runtime policy (documented in research).

**Gate result (pre-research)**: PASS — no violations.

**Gate result (post-design)**: PASS — design keeps helpers in `lib/core/platform`, player change presentation-only, ADR + feature docs planned, Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/026-orientation-layout-polish/
├── plan.md              # This file
├── spec.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── orientation-policy.md
│   └── player-content-layout.md
└── tasks.md             # /speckit-tasks — NOT created here
```

### Source Code (repository root)

```text
lib/core/platform/
├── mobile_platform.dart                 # existing isMobilePlatform
├── device_form_factor.dart              # NEW: enum + resolve + preferred orientations
└── player_content_layout.dart           # NEW: usePlayerSideBySideLayout(width, height)
# OR single file device_orientation_policy.dart housing both — see research R1

lib/main.dart                            # apply preferred orientations after ensureInitialized

lib/features/player/presentation/layouts/
└── video_player_layout.dart             # aspect-based side-by-side predicate

ios/Runner/Info.plist                    # optional: iPhone portrait-only (research R3)

test/core/platform/
├── device_form_factor_test.dart
└── player_content_layout_test.dart

test/features/player/
└── video_player_layout_test.dart        # update aspect cases

docs/
├── features/player.md
├── features/app-ui.md
└── decisions/0059-phone-tablet-orientation-and-player-aspect-layout.md
```

**Structure Decision**: Shared orientation/form-factor logic in `lib/core/platform/` beside `mobile_platform.dart`. Player only consumes the pure side-by-side helper (or inlines the one-line `width > height` check with a named helper for tests). Bootstrap owns the one-shot `SystemChrome` call. No new feature module.

## Complexity Tracking

*(No violations — table intentionally empty.)*

## Phase 0 / Phase 1 outputs

| Artifact | Path |
|---|---|
| Research | [research.md](research.md) |
| Data model | [data-model.md](data-model.md) |
| Contracts | [contracts/](contracts/) |
| Quickstart | [quickstart.md](quickstart.md) |

**Agent context update**: No `update-agent-context` script is present under `.specify/scripts` in this repo; skipped.

## Next

Run `/speckit-tasks` to break implementation into ordered tasks.
