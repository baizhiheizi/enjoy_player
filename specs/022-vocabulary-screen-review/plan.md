# Implementation Plan: Vocabulary Screen & Review

**Branch**: `main` (spec directory `022-vocabulary-screen-review` is independent of git branch naming; create `022-vocabulary-screen-review` when implementing) | **Date**: 2026-07-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/022-vocabulary-screen-review/spec.md`

**Parent contract**: [docs/features/vocabulary.md](../../docs/features/vocabulary.md) **P1** · Prerequisite: [021-vocabulary-foundation](../021-vocabulary-foundation/spec.md) (shipped)

## Summary

Ship the **Vocabulary destination + review loop** on top of the existing local-first foundation: a secondary `/vocabulary` route (Profile entry, not a primary shell tab) with stats and **Review** / **All Words** tabs; review options (due / all / status / language / random N); a fullscreen review session with flip, three ratings, skip, undo, and desktop in-session shortcuts; list search/filters/delete and empty states. Reuse `VocabularyRepository` SRS/undo/delete; extend list/stats/watch APIs as needed. Defer sync, Anki, home due widget, and review-context media/AI richness to follow-ups.

## Technical Context

**Language/Version**: Dart `^3.12.0`, Flutter stable (3.x), Drift `^2.31.0`, Riverpod `^3.3.1`, go_router (existing).

**Primary Dependencies**: Existing `VocabularyRepository` / DAOs (schema **15**), `vocabulary_srs` / domain models, Riverpod providers, go_router `ShellRoute`, shared UI (`EnjoyButton`, `EnjoyTappableSurface`, `EnjoyCard`, `SettingsRow`, `showEnjoyAlertDialog`), ARB l10n. No new third-party packages. No `media_kit` `Player()` (review does not play clips in this phase). No global hotkey registration for review keys.

**Storage**: Existing Drift tables `vocabulary_items`, `vocabulary_contexts`, `vocabulary_reviews` — **no schema bump**. Add repository/DAO query helpers (list all, filter by status/language, optional watch streams, stats aggregation). Session state is ephemeral in a Riverpod notifier (not persisted).

**Testing**: Unit tests for session queue builder (modes + Fisher–Yates + empty), stats aggregation, relative next-review labels; notifier tests for flip/rate/skip/undo/in-flight guard; widget tests for Vocabulary screen stats/tabs/empty states, review options, flashcard chrome, All Words filter/search/delete; reuse foundation SRS/undo fixtures. `dart run build_runner build` for new `@Riverpod` providers. Manual: desktop shortcuts + end-to-end review (see [quickstart.md](./quickstart.md)).

**Target Platform**: Android, iOS, macOS, Windows, Linux (no Flutter web).

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals**:

- Vocabulary screen opens and stats/list render within ~1s for a typical personal book (hundreds–low thousands of items) on warm local DB (QR-004 / SC-001).
- Filter + client-side search stay on an already-loaded or watched item list — no FTS; debounce search text ≥150ms.
- Rating write is a short Drift transaction; UI blocks double-submit; no frame stalls >~100ms from list item builders doing heavy work.
- Review session does not touch playback engines.

**Constraints**:

- Depends on foundation: `markReviewed`, `undoLatestReview`, `deleteItem`, `listDue`, `getContextsForItem`, due predicate, SRS parity.
- Local-first only; do **not** extend sync or Anki in this phase.
- Navigation: secondary route under `ShellRoute`, Profile entry — ADR-0053 (see research).
- Review shortcuts: **in-session only** (Focus/Shortcuts), not `AppHotkeys`.
- Card back may show Context / Dictionary / Notes structure; Notes placeholder; no clip play / open-in-player / shadow / AI persist.
- Omit Anki Export control until P4.
- Feature-first layout under `lib/features/vocabulary/`; Profile only pushes the route (thin navigation seam).
- No `print()`; logging via `logNamed`.

**Scale/Scope**: Personal vocabulary (hundreds–low thousands). One destination + one review session route/overlay. ~40–60 ARB keys × existing locales for vocabulary inventory. No schema migration.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- ✅ New UI/notifiers under `lib/features/vocabulary/{application,presentation}`; domain helpers for stats/session selection/relative labels stay UI-free.
- ✅ Persistence remains Drift DAOs + `VocabularyRepository`; no raw SQL in widgets.
- ✅ Riverpod for stats/list/session; no new mutable global singletons.
- ✅ Profile → `context.push('/vocabulary')` only; avoid feature↔feature deep imports of presentation internals.
- ✅ No `Player()`; no `print()`.

### II. Testing Defines the Contract

- ✅ Unit: session queue modes, shuffle determinism with seeded RNG, stats counts, relative next-review labels, in-flight rating guard logic.
- ✅ Notifier/repo: rate → SRS update; undo restores; skip no write; delete refreshes list/stats.
- ✅ Widget: stats strip, empty states, review options → session, flashcard flip/rate, All Words filter/search/delete confirm.
- ✅ Manual: desktop Space/1/2/3/arrows/Esc (widget tests cover bindings where practical; OS focus quirks → quickstart).
- ✅ `build_runner` when adding `@Riverpod` providers.

### III. User Experience Consistency

- ✅ ARB keys from vocabulary string inventory (stats, modes, ratings, empty states, list/delete, review chrome, shortcut hints).
- ✅ Enjoy tappable primitives; icon-only actions get tooltips; shortcut legend in review UI.
- ✅ Update `docs/features/vocabulary.md` P1 checkboxes/status; ADR-0053 navigation.

### IV. Performance Is a Requirement

- ✅ Load/watch item list once; derive stats and filters in memory; debounce search.
- ✅ Session queue built once at start; do not re-query whole DB per card.
- ✅ Evidence: unit tests + manual timing note in PR if Vocabulary open feels slow.

### V. Documentation and Traceability

- ✅ ADR-0053: Vocabulary secondary route + Profile entry (not primary shell tab); aligns with craft/credits pattern ([0043](../../docs/decisions/0043-craft-from-text-import.md) spirit).
- ✅ `docs/features/vocabulary.md` P1 status when behavior lands.
- ✅ `docs/decisions/README.md` index entry for ADR-0053.
- ✅ No constitution exceptions.

**Post-design re-check**: Gates still pass after [research.md](./research.md), [data-model.md](./data-model.md), and contracts. Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/022-vocabulary-screen-review/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── vocabulary-navigation.md
│   ├── vocabulary-review-session.md
│   └── vocabulary-list-ui.md
└── tasks.md                 # /speckit-tasks (not this command)
```

### Source Code (repository root)

```text
lib/features/vocabulary/
├── domain/
│   ├── vocabulary_models.dart          # existing
│   ├── vocabulary_srs.dart             # existing
│   ├── vocabulary_stats.dart           # NEW — aggregate counts + due
│   ├── vocabulary_session_selection.dart # NEW — build queue from mode/options
│   └── vocabulary_relative_review.dart # NEW — overdue/today/tomorrow/inDays
├── data/
│   └── vocabulary_repository.dart      # UPDATE — listAll, watchAll?, filter helpers
├── application/
│   ├── vocabulary_providers.dart       # UPDATE — stats/list providers
│   ├── vocabulary_review_session.dart  # NEW — notifier: queue, flip, rate, skip, undo
│   └── vocabulary_list_controller.dart # NEW — filter/search state (or inline providers)
└── presentation/
    ├── add_to_vocabulary_control.dart  # existing
    ├── vocabulary_screen.dart          # NEW — stats + tabs
    ├── vocabulary_review_options.dart  # NEW — dialog/sheet
    ├── vocabulary_review_session_screen.dart # NEW — fullscreen session
    ├── vocabulary_flashcard.dart       # NEW — front/back + rating row
    ├── vocabulary_word_list.dart       # NEW — All Words list
    └── widgets/                        # stats strip, empty states, shortcut hint

lib/core/routing/
└── app_router.dart                     # UPDATE — /vocabulary (+ optional /vocabulary/review)

lib/features/auth/presentation/widgets/
└── profile_content.dart                # UPDATE — Vocabulary SettingsRow → push

lib/l10n/
└── app_*.arb                           # UPDATE — vocabulary inventory keys

test/features/vocabulary/
├── vocabulary_stats_test.dart          # NEW
├── vocabulary_session_selection_test.dart # NEW
├── vocabulary_relative_review_test.dart # NEW
├── vocabulary_review_session_test.dart # NEW
└── presentation/
    ├── vocabulary_screen_test.dart     # NEW
    ├── vocabulary_review_session_screen_test.dart # NEW
    └── vocabulary_word_list_test.dart  # NEW

docs/features/vocabulary.md             # UPDATE — P1
docs/decisions/0053-vocabulary-secondary-route.md  # NEW
docs/decisions/README.md                # UPDATE — index
```

**Structure Decision**: Keep all vocabulary UI inside `lib/features/vocabulary/presentation`. Navigation is a thin Profile + router seam (same pattern as Credits/Subscription). Domain helpers own selection/stats/labels so widgets stay thin. Review session is a pushed route (or full-screen dialog) owned by a Riverpod notifier keyed to the session instance.

## Complexity Tracking

> No constitution violations.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| — | — | — |

## Implementation Phases (for `/speckit-tasks`)

### Phase A — Destination shell + stats + All Words

1. ADR-0053 + `/vocabulary` route + Profile entry.
2. Repository `listAll` / watch + `VocabularyStats` + stats strip.
3. All Words list: status/language filters, search, relative labels, delete confirm.
4. Empty book state; ARB + docs partial.

### Phase B — Review options + session loop

1. Session selection domain (due/all/status/language/random N + Fisher–Yates).
2. Review options UI → start session route.
3. Flashcard flip / rate / skip / undo / complete / exit; in-flight guard.
4. Wire `markReviewed` / `undoLatestReview`; primary context preview from first context.
5. Card back tabs: Context text, Dictionary cached-only or empty, Notes placeholder.

### Phase C — Desktop shortcuts + polish

1. In-session Shortcuts/Actions (Space, 1/2/3, ←/→, Esc).
2. Shortcut discoverability in review chrome.
3. No-due empty state + custom review still available.
4. Widget tests + quickstart manual pass + mark P1 checkboxes in feature doc.

## Verification Commands

```bash
dart run build_runner build   # if new @Riverpod
flutter analyze
flutter test test/features/vocabulary/
bash .github/scripts/validate_ci_gates.sh --fix
```
