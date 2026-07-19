# Implementation Plan: Vocabulary Polish

**Branch**: `main` (spec directory `025-vocabulary-polish` is independent of git branch naming; create `025-vocabulary-polish` when implementing) | **Date**: 2026-07-19 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/025-vocabulary-polish/spec.md` (includes Clarifications session 2026-07-19) · UI: Enjoy-aligned, list-first hub, practice in modal adaptive sheet.

**Parent contract**: [docs/features/vocabulary.md](../../docs/features/vocabulary.md) · Prerequisites: [021](../021-vocabulary-foundation/spec.md), [022](../022-vocabulary-screen-review/spec.md), [023](../023-vocabulary-context-richness/spec.md) (shipped). This phase **supersedes** 023’s shadow hand-off and “play via global chrome only” UX for review. **Re-plan** after clarify: practice chrome is a **shared modal adaptive sheet**, not inline Context-tab embed.

## Summary

Polish Vocabulary so the **hub is list-first** (compact secondary stats) and flashcard **Context** practice works for YouTube and local media via a **shared modal practice sheet** (adaptive Enjoy sheet: bottom sheet on compact, centered modal on wide): **clip mini-player** XOR **echo recorder** (`ShadowReadingPanel`), **Open in player → full `/player/:id`**, and a **multi-context switcher** on the card. Sheet is modal (must dismiss before rate/flip). No schema migration. Single `PlayerController` ownership preserved (ADR-0003).

## Technical Context

**Language/Version**: Dart `^3.12.0`, Flutter stable (3.x), Drift `^2.31.0`, Riverpod `^3.3.1`, go_router (existing).

**Primary Dependencies**: Vocabulary feature (`VocabularyRepository`, `VocabularyReviewSession`, flashcard UI), `PlayerController` / `PlayerEngine.buildVideoStage`, `EchoMode`, `ShadowReadingPanel`, `openPlayerRoute` / `PlayerUi.expand`, adaptive sheet helper (extend `showEnjoySheet` / `enjoy_modal.dart` — today bottom-sheet-only), optional `GlobalTransportBar` suppress while practice sheet owns video stage. No new third-party packages. **Never** construct `media_kit` `Player()` for lesson media outside the player engine/controller (`RecordingPreviewPlayer` remains the WAV-preview exception).

**Storage**: Existing Drift vocabulary tables. **No schema migration.** Session state gains: full context list per item, active context index, review practice mode (`none` | `clip` | `echo`). Sheet route is presentation-owned (modal route); session mode drives sheet content.

**Testing**: Unit tests for context ordering/index, practice exclusivity transitions; notifier tests for `selectContext` / open practice clip|echo / dismiss / hand-off; widget tests for compact stats, context pager, sheet open/swap/dismiss modal blocking, open-in-player confirm. Manual: YouTube + local clip in sheet, echo record/assess in sheet, full-player hand-off, desktop centered modal (see [quickstart.md](./quickstart.md)). `dart run build_runner build` if new `@Riverpod` annotations.

**Target Platform**: Android, iOS, macOS, Windows, Linux (no Flutter web).

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals**:

- Vocabulary hub first paint: compact stats strip ≤ ~56px collapsed height on phone (excluding optional expand); list/search visible in first viewport (SC-001).
- Context switch among ≤20 contexts: UI update &lt; 100ms.
- Practice sheet open + clip start: seek+play within a few seconds for resolvable local media; YouTube uses existing engine path.
- Sheet mode swap (clip ↔ echo): tear down prior surface before mounting the other — never dual `buildVideoStage` + recorder; prefer short `motionStandard` content swap inside one sheet host.

**Constraints**:

- Clarifications (2026-07-19): shared practice sheet; modal; adaptive compact/wide.
- Single shared player — practice-sheet video stage is the **only** mounted `buildVideoStage` while clip mode is active (stay off `/player/:id`).
- Clip and echo mutually exclusive in one sheet host.
- Modal: no rate/flip/Context controls until dismiss; card advance / context change dismisses sheet.
- Open in player ends review (confirm retained) → expanded full player at locator start.
- Echo reading is **in-session sheet** (supersedes 023 confirm→exit shadow hand-off).
- Ebook: play / echo / open unavailable.
- Feature-first under `lib/features/vocabulary/`; thin host for `ShadowReadingPanel`.
- No `print()`; ARB for new chrome.
- UI: Enjoy tokens, list-first hub, clean Context tab (no embedded tall player/recorder).

**Scale/Scope**: Personal vocabulary; multi-context pager for 2+ contexts. New widgets: compact stats, context pager, practice sheet host, clip stage in sheet, echo host in sheet; optional adaptive sheet API in `core/theme`. ~15–25 ARB keys × locales. Docs update for vocabulary UI surfaces.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- ✅ Changes in `lib/features/vocabulary/{application,domain,presentation}`; optional small adaptive-sheet helper in `lib/core/theme/widgets/enjoy_modal.dart`.
- ✅ No new lesson-media `Player()`; domain stays UI-free.
- ✅ Persistence unchanged; session notifier owns active context + practice mode.
- ✅ Riverpod; no new mutable global singletons; no `print()`.

### II. Testing Defines the Contract

- ✅ Unit: active-context selection, practice mode transitions, dismiss clears practice.
- ✅ Notifier: open clip/echo sheet modes; swap; dismiss; selectContext blocked or dismisses; open-in-player clears session.
- ✅ Widget: compact stats; pager; sheet modal (cannot rate underneath); mode swap; adaptive presentation smoke (width pump).
- ✅ Manual: YouTube/local/echo/full player (automation brittle).
- ✅ `build_runner` when adding providers.

### III. User Experience Consistency

- ✅ ARB for stats expand, pager, practice sheet titles/dismiss, errors.
- ✅ Adaptive sheet via Enjoy modal patterns; `EnjoyTappableIcon` / haptics as elsewhere.
- ✅ Update `docs/features/vocabulary.md`.

### IV. Performance Is a Requirement

- ✅ One video stage mount in sheet clip mode; tear down on dismiss/swap/echo.
- ✅ Lazy-mount `ShadowReadingPanel` only in echo mode.
- ✅ Context list loaded at session start; avoid N+1 on flip.

### V. Documentation and Traceability

- ✅ No new ADR unless adaptive-sheet helper becomes a cross-app API worth ADR-0055 adjacency — prefer docs + this plan.
- ✅ Update vocabulary.md; note supersession of 023 review shadow hand-off.
- ✅ No constitution exceptions.

**Post-design re-check**: Gates still pass after research, data-model, contracts. Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/025-vocabulary-polish/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── vocabulary-hub-stats.md
│   ├── vocabulary-practice-sheet.md    # supersedes prior inline-practice draft
│   ├── vocabulary-context-switcher.md
│   └── vocabulary-flashcard-layout.md
└── tasks.md                 # /speckit-tasks (not this command)
```

### Source Code (repository root)

```text
lib/core/theme/widgets/
└── enjoy_modal.dart                    # UPDATE — add adaptive sheet helper (compact bottom / wide centered)

lib/features/vocabulary/
├── domain/
│   └── vocabulary_review_practice.dart # NEW — ReviewPracticeMode
├── application/
│   ├── vocabulary_review_session.dart  # UPDATE — contexts list, active index, practice mode
│   └── vocabulary_review_media.dart    # UPDATE — clip play; stop on dismiss; open-in-player hand-off
├── presentation/
│   ├── vocabulary_screen.dart
│   ├── widgets/vocabulary_stats_strip.dart          # UPDATE — compact + expand
│   ├── vocabulary_flashcard.dart                    # UPDATE — pager; actions open sheet (no embed)
│   ├── vocabulary_review_session_screen.dart        # UPDATE — sheet entry; Esc order; focus
│   ├── widgets/vocabulary_context_pager.dart        # NEW
│   ├── widgets/vocabulary_practice_sheet.dart       # NEW — host + mode body
│   ├── widgets/vocabulary_practice_clip_body.dart   # NEW — buildVideoStage + transport
│   └── widgets/vocabulary_practice_echo_body.dart   # NEW — ShadowReadingPanel host

lib/features/player/presentation/
└── root_shell.dart                     # UPDATE (minimal) — suppress GlobalTransportBar when practice sheet owns stage

lib/features/shadow_reading/presentation/
└── shadow_reading_panel.dart           # UPDATE (optional) — compact density for sheet

test/features/vocabulary/
└── presentation/ … + application/ …

docs/features/vocabulary.md             # UPDATE
```

**Structure Decision**: Practice UI lives in a modal sheet route, not inside `_ContextBody` scroll. Session owns `ReviewPracticeMode`; presentation opens/closes the adaptive sheet and swaps body. Extend `enjoy_modal.dart` so wide layouts get a centered modal (today `showEnjoySheet` is bottom-sheet-only — gap vs clarified FR-006b).

## Complexity Tracking

> None — constitution gates pass without exceptions.

## UI Design Direction

| Surface | Direction |
|---------|-----------|
| **Hub stats** | Collapsed Total \| Due + chevron; expand status breakdown — not 2×3 large tiles |
| **Context tab** | Quote → pager → meta → action chips → AI — **no** embedded player/recorder |
| **Practice sheet** | Drag handle / title (Clip / Echo); body = video stage or ShadowReadingPanel; dismiss clears practice |
| **Wide** | Centered modal (`modalMaxWidthLarge` ~560) with same body |
| **Actions** | Quiet `_MediaAction`; tonal when matching mode is “would reopen” after dismiss |
| **Motion** | Enjoy sheet enter/exit; content swap without stacking two sheets |

## Phase 0 / Phase 1 outputs

| Artifact | Path |
|----------|------|
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| Contracts | [contracts/](./contracts/) |
| Quickstart | [quickstart.md](./quickstart.md) |

Next command: `/speckit-tasks`.
