# Implementation Plan: Vocabulary Context Richness

**Branch**: `main` (spec directory `023-vocabulary-context-richness` is independent of git branch naming; create `023-vocabulary-context-richness` when implementing) | **Date**: 2026-07-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/023-vocabulary-context-richness/spec.md`

**Parent contract**: [docs/features/vocabulary.md](../../docs/features/vocabulary.md) **P2** · Prerequisites: [021-vocabulary-foundation](../021-vocabulary-foundation/spec.md), [022-vocabulary-screen-review](../022-vocabulary-screen-review/spec.md) (shipped)

## Summary

Enrich the existing Vocabulary review flashcard **Context** and **Dictionary** tabs: write-through dictionary and contextual-translation AI onto item/context `explanation` fields; play the media locator clip via the single shared `PlayerController` while staying in review; confirm-then-exit for Open in player and shadow-reading hand-off (reuse `/player/:mediaId`, echo mode, and existing `ShadowReadingPanel`). No schema bump (columns already on Drift schema **15**). Defer sync, Anki, home due nudge, ebook play, and Notes content.

## Technical Context

**Language/Version**: Dart `^3.12.0`, Flutter stable (3.x), Drift `^2.31.0`, Riverpod `^3.3.1`, go_router (existing).

**Primary Dependencies**: Existing vocabulary feature (`VocabularyRepository`, review session notifier, flashcard UI), AI `DictionaryService` / `ContextualTranslationService` (+ caches), lookup auth/credits gates, `PlayerController` (`openMedia`, `seekToSeconds`, `play`), `EchoMode`, `openPlayerRoute`, `ShadowReadingPanel` patterns. No new third-party packages. **Never** construct `media_kit` `Player()` outside the player engine/controller.

**Storage**: Existing Drift tables — `vocabulary_items.explanation`, `vocabulary_contexts.explanation`, `vocabulary_contexts.locator` (JSON). **No schema migration**. Add DAO/repo update methods for explanation write-through; session state must retain full primary `VocabularyContext` (not text-only).

**Testing**: Unit tests for explanation encode/decode round-trips and repo update methods; notifier tests for persist + session item refresh, clip/open/shadow hand-off state (mock player/router); widget tests for Dictionary fetch/persist empty/success, Context AI + action buttons, open-in-player confirm cancel/confirm. Manual: local media clip play, open-in-player seek, shadow hand-off (see [quickstart.md](./quickstart.md)). `dart run build_runner build` if new `@Riverpod` annotations.

**Target Platform**: Android, iOS, macOS, Windows, Linux (no Flutter web).

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals**:

- Opening Dictionary/Context with cached JSON explanation: no multi-second freeze; parse/render on main isolate is fine for typical sense lists (QR-004).
- Clip play start for local resolvable media: audible within a few seconds of tap (SC-003); do not block rating UI on AI fetches (separate in-flight flags).
- AI fetch uses existing cache fingerprint path to avoid duplicate network when L1/Drift AI cache hits.

**Constraints**:

- Local-first write-through only; do **not** extend sync queue or Anki in this phase.
- Single shared player — clip play and shadow MUST go through `PlayerController` / existing echo APIs.
- Clip play keeps review session active; Open in player and shadow hand-off end or leave review only after confirm.
- Ebook locators: unavailable for play/open/shadow (schema-ready only).
- Notes tab remains placeholder.
- Feature-first under `lib/features/vocabulary/`; call player/AI via providers/application seams — avoid deep presentation imports across features.
- No `print()`; logging via `logNamed`.
- Auth/credits for AI match dictionary-lookup / AI feature rules.

**Scale/Scope**: Personal vocabulary; one primary context per card (earliest `createdAt`, same as P1). ~10–20 new ARB keys × locales for open-in-player, shadow, contextual translation, play-segment, errors. No new routes beyond existing `/vocabulary` + `/vocabulary/review` + `/player/:mediaId`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- ✅ Changes stay in `lib/features/vocabulary/{application,data,domain,presentation}`; player/AI reused via existing providers — no new `Player()`.
- ✅ Domain models remain UI-free; explanation JSON encode/decode helpers in domain or next to existing locator JSON helpers.
- ✅ Persistence through Drift DAOs + `VocabularyRepository` (add context `updateRow` + repo update methods).
- ✅ Riverpod for session enrichments; no new mutable global singletons.
- ✅ No `print()`.

### II. Testing Defines the Contract

- ✅ Unit: persist encode/decode; repo update item/context explanation; optional clip-span helper (ms→seconds window).
- ✅ Notifier: after AI success, session queue item/context refresh; open-in-player clears session; rating in-flight independent of AI in-flight.
- ✅ Widget: Dictionary empty → fetch → shown; Context translation; confirm dialogs cancel/confirm; unavailable ebook actions.
- ✅ Manual: real media clip + open player + shadow (automation of player audio is brittle).
- ✅ `build_runner` when adding providers.

### III. User Experience Consistency

- ✅ ARB for Context actions, confirm copy, shadow, contextual translation, unavailable/error states (feature string inventory).
- ✅ Enjoy dialogs/buttons (`showEnjoyAlertDialog`, `EnjoyButton`); tooltips on icon-only actions.
- ✅ Update `docs/features/vocabulary.md` P2 checkboxes/status when behavior lands.

### IV. Performance Is a Requirement

- ✅ Prefer AI cache hit before network; write-through is a single-row Drift update.
- ✅ Clip play: open + seek + play; avoid reloading entire library.
- ✅ Evidence: unit/widget + quickstart timing note if clip start feels slow.

### V. Documentation and Traceability

- ✅ No new ADR required: schema already ADR-0052; navigation ADR-0053; single-player rule is constitution / ADR-0003 family.
- ✅ Update `docs/features/vocabulary.md` P2; optionally cross-link shadow-reading.md if hand-off semantics need a sentence.
- ✅ No constitution exceptions.

**Post-design re-check**: Gates still pass after [research.md](./research.md), [data-model.md](./data-model.md), and contracts. Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/023-vocabulary-context-richness/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── vocabulary-explanation-persist.md
│   ├── vocabulary-context-tab.md
│   └── vocabulary-media-actions.md
└── tasks.md                 # /speckit-tasks (not this command)
```

### Source Code (repository root)

```text
lib/features/vocabulary/
├── domain/
│   ├── vocabulary_models.dart              # existing — VocabularyContext already has fields
│   ├── vocabulary_locator_json.dart        # existing
│   └── vocabulary_explanation_codec.dart   # NEW (optional) — DictionaryResult / ContextualTranslationResult ↔ DB string
├── data/
│   └── vocabulary_repository.dart          # UPDATE — updateItemExplanation, updateContextExplanation
├── application/
│   ├── vocabulary_review_session.dart      # UPDATE — primary VocabularyContext map; AI persist; media actions
│   └── vocabulary_review_media.dart        # NEW (optional) — clip play / open-player / shadow hand-off orchestration
└── presentation/
    ├── vocabulary_flashcard.dart           # UPDATE — Context/Dictionary richness UI
    └── vocabulary_review_session_screen.dart # UPDATE — wire actions / confirm dialogs

lib/data/db/daos/
└── vocabulary_context_dao.dart             # UPDATE — updateRow (or equivalent)

lib/features/ai/…                           # REUSE — DictionaryService, ContextualTranslationService, caches
lib/features/player/…                       # REUSE — PlayerController, EchoMode
lib/core/routing/player_navigation.dart     # REUSE — openPlayerRoute
lib/features/lookup/…                       # REUSE — auth gate patterns (or thin shared helper)

lib/l10n/app_*.arb                          # UPDATE — P2 strings

test/features/vocabulary/
├── vocabulary_explanation_persist_test.dart
├── vocabulary_review_session_media_test.dart
└── presentation/
    └── vocabulary_flashcard_context_test.dart

docs/features/vocabulary.md                 # UPDATE — P2
```

**Structure Decision**: Keep orchestration inside the vocabulary feature (session notifier + thin media helper). Reuse AI and player application APIs; do not embed `ShadowReadingPanel` inside the flashcard — hand off to the player/transcript surface after confirm (see research).

## Complexity Tracking

> No constitution violations.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| — | — | — |

## Implementation Phases (for `/speckit-tasks`)

### Phase A — Persist explanations

1. `VocabularyContextDao.updateRow` + repository `updateItemExplanation` / `updateContextExplanation`.
2. Session state: store primary `VocabularyContext` (id, text, source*, locator, explanation), keep item snapshots refreshable.
3. Dictionary tab: show cache → fetch via dictionary service/cache → persist JSON on item → refresh UI.
4. Context tab: show/persist contextual translation on context; multi-context isolation.
5. Unit/widget tests for persist + empty/error states.

### Phase B — Clip play + open in player

1. Context tab chrome: source label, play segment (media locator only).
2. Clip: `openMedia` + seek to locator start + play; optional echo window from start/end seconds; stay on review route.
3. Open in player: confirm dialog → clear/exit session → `openPlayerRoute` + seek.
4. Ebook / missing media unavailable states.
5. Tests with mocked player/router.

### Phase C — Shadow hand-off + polish

1. Shadow action: confirm if leaving review → open player → activate echo for locator span → existing shadow UI appears with echo.
2. ARB inventory for new strings; feature doc P2 checkboxes.
3. Quickstart manual pass; `flutter analyze` / `flutter test` / CI gates.

## Verification Commands

```bash
dart run build_runner build   # if new @Riverpod
flutter analyze
flutter test test/features/vocabulary/
bash .github/scripts/validate_ci_gates.sh --fix
```
