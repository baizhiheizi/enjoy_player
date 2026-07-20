# Tasks: Vocabulary Screen & Review

**Input**: Design documents from `specs/022-vocabulary-screen-review/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are required for changed behavior (constitution + plan QR-002 / SC-003). Manual desktop shortcuts + E2E review per [quickstart.md](./quickstart.md).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/vocabulary/{application,data,domain,presentation}/`
- **Routing**: `lib/core/routing/app_router.dart`
- **Profile entry**: `lib/features/auth/presentation/widgets/profile_content.dart`
- **Tests**: `test/features/vocabulary/`
- **Feature docs**: `docs/features/vocabulary.md`
- **ADRs**: `docs/decisions/0053-vocabulary-secondary-route.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm touch points and doc/ADR/l10n targets before code changes

- [x] T001 Confirm affected paths from plan (`lib/features/vocabulary/`, `lib/core/routing/app_router.dart`, `lib/features/auth/presentation/widgets/profile_content.dart`, `lib/l10n/`) against current tree and foundation APIs (`VocabularyRepository.listDue` / `markReviewed` / `undoLatestReview` / `deleteItem`)
- [x] T002 [P] Identify doc/ADR/l10n targets: `docs/features/vocabulary.md`, `docs/decisions/0053-vocabulary-secondary-route.md`, `docs/decisions/README.md`, `lib/l10n/app_en.arb` (+ other locale ARBs)
- [x] T003 Remove `lib/features/vocabulary/presentation/.gitkeep` when first presentation file lands; ensure `test/features/vocabulary/presentation/` directory exists for widget tests

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain helpers, repository list/watch surface, shared providers, ADR, routes, and ARB keys that all stories need

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Implement `computeVocabularyStats` in `lib/features/vocabulary/domain/vocabulary_stats.dart` per [data-model.md](./data-model.md)
- [x] T005 [P] Implement `buildVocabularySessionQueue` (modes + Fisher–Yates with injectable `Random`, default N=20) in `lib/features/vocabulary/domain/vocabulary_session_selection.dart` per [contracts/vocabulary-review-session.md](./contracts/vocabulary-review-session.md)
- [x] T006 [P] Implement `relativeNextReviewLabel` (overdue / today / tomorrow / inDays) in `lib/features/vocabulary/domain/vocabulary_relative_review.dart`
- [x] T007 Extend `VocabularyRepository` with `listAll()` (and `watchAll()` stream if using Drift watch) in `lib/features/vocabulary/data/vocabulary_repository.dart`; reuse existing DAO `listAll` in `lib/data/db/daos/vocabulary_item_dao.dart`
- [x] T008 [P] Add Riverpod providers for watched/listed items + derived stats in `lib/features/vocabulary/application/vocabulary_providers.dart` (run `dart run build_runner build` after `@Riverpod` changes)
- [x] T009 [P] Add Vocabulary ARB keys (stats, tabs, empty states, review modes, ratings, list/delete, shortcuts hint) to `lib/l10n/app_en.arb` and mirror in `app_zh.arb` / `app_zh_CN.arb` (and other locales as project requires); run `flutter gen-l10n` if needed
- [x] T010 Write ADR-0053 secondary route decision in `docs/decisions/0053-vocabulary-secondary-route.md` and index in `docs/decisions/README.md` per [contracts/vocabulary-navigation.md](./contracts/vocabulary-navigation.md)
- [x] T011 Register `/vocabulary` and `/vocabulary/review` under `ShellRoute` in `lib/core/routing/app_router.dart` (placeholder screens OK until US1/US3)
- [x] T012 Add Profile Vocabulary `SettingsRow` that `context.push('/vocabulary')` in `lib/features/auth/presentation/widgets/profile_content.dart`

**Checkpoint**: Domain helpers + list/stats providers + route/Profile entry ready — user story UI can begin

---

## Phase 3: User Story 1 - Open Vocabulary and see progress (Priority: P1) 🎯 MVP

**Goal**: Dedicated Vocabulary destination with stats strip and Review / All Words tabs; empty-book and no-due empty states.

**Independent Test**: Seed local items → Profile → Vocabulary → stats match seed; both tabs available; empty book shows guidance (SC-001 / SC-005).

### Tests for User Story 1

- [x] T013 [P] [US1] Unit test `computeVocabularyStats` in `test/features/vocabulary/vocabulary_stats_test.dart`
- [x] T014 [P] [US1] Widget test Vocabulary screen stats strip + tabs + empty-book state in `test/features/vocabulary/presentation/vocabulary_screen_test.dart`

### Implementation for User Story 1

- [x] T015 [P] [US1] Implement stats strip widget in `lib/features/vocabulary/presentation/widgets/vocabulary_stats_strip.dart`
- [x] T016 [P] [US1] Implement empty-state widgets (no words / no due) in `lib/features/vocabulary/presentation/widgets/vocabulary_empty_states.dart`
- [x] T017 [US1] Implement `VocabularyScreen` (AppBar, stats, TabBar Review | All Words) in `lib/features/vocabulary/presentation/vocabulary_screen.dart` wired to stats providers; Review tab shows no-due empty + placeholder for options (US2); All Words tab placeholder until US5
- [x] T018 [US1] Point `/vocabulary` route builder at `VocabularyScreen` in `lib/core/routing/app_router.dart`
- [x] T019 [US1] Verify Vocabulary open stays responsive for a typical seeded book (~1s) and note evidence in PR or quickstart comment per plan QR-004

**Checkpoint**: US1 independently testable — open Vocabulary, see stats/tabs/empty states without review session

---

## Phase 4: User Story 5 - Browse, search, filter, and delete words (Priority: P1)

**Goal**: All Words tab with status/language filters, client-side search, relative next-review labels, delete-with-confirm.

**Independent Test**: Seed mixed book → filter/search → delete confirm removes item and refreshes stats (SC-004).

**Depends on**: US1 screen shell (All Words tab host).

### Tests for User Story 5

- [x] T020 [P] [US5] Unit test `relativeNextReviewLabel` in `test/features/vocabulary/vocabulary_relative_review_test.dart`
- [x] T021 [P] [US5] Widget test All Words filter/search/delete confirm-cancel in `test/features/vocabulary/presentation/vocabulary_word_list_test.dart`

### Implementation for User Story 5

- [x] T022 [P] [US5] Add list filter/search state providers (status, language, debounced query ≥150ms) in `lib/features/vocabulary/application/vocabulary_list_controller.dart` (or extend `vocabulary_providers.dart`)
- [x] T023 [US5] Implement word list row + list UI in `lib/features/vocabulary/presentation/vocabulary_word_list.dart` per [contracts/vocabulary-list-ui.md](./contracts/vocabulary-list-ui.md)
- [x] T024 [US5] Wire delete confirm via `showEnjoyAlertDialog` → `VocabularyRepository.deleteItem` and refresh list/stats
- [x] T025 [US5] Mount All Words tab content in `lib/features/vocabulary/presentation/vocabulary_screen.dart`; show filtered-empty vs empty-book distinctly

**Checkpoint**: US5 independently testable on All Words tab with manage flows

---

## Phase 5: User Story 2 - Start a review session with selection options (Priority: P1)

**Goal**: Review options (due / all / by status / by language / random N) build a queue and navigate to the review session route; empty queue blocked with message.

**Independent Test**: Open options with prepared book → each mode yields expected queue membership; empty mode shows message and does not open session (SC-002 start path).

**Depends on**: Foundational queue builder (T005); US1 Review tab host.

### Tests for User Story 2

- [x] T026 [P] [US2] Unit test `buildVocabularySessionQueue` modes + empty + random N + seeded Fisher–Yates in `test/features/vocabulary/vocabulary_session_selection_test.dart`
- [x] T027 [P] [US2] Widget test review options sheet/dialog mode selection + empty-queue message in `test/features/vocabulary/presentation/vocabulary_review_options_test.dart`

### Implementation for User Story 2

- [x] T028 [US2] Implement review options UI in `lib/features/vocabulary/presentation/vocabulary_review_options.dart` (due/all/status/language/random + N default 20)
- [x] T029 [US2] Create review session notifier shell that accepts a built queue and exposes start/dispose in `lib/features/vocabulary/application/vocabulary_review_session.dart` (full flip/rate in US3)
- [x] T030 [US2] Wire Review tab: open options → build queue → `context.push('/vocabulary/review')` when non-empty; block empty with localized message in `lib/features/vocabulary/presentation/vocabulary_screen.dart`
- [x] T031 [US2] Ensure `/vocabulary/review` redirects or pops to `/vocabulary` when no active session in `lib/core/routing/app_router.dart` / session screen guard

**Checkpoint**: US2 independently testable — options produce correct queues and navigation guard works

---

## Phase 6: User Story 3 - Study with flip, rate, skip, and undo (Priority: P1)

**Goal**: Fullscreen flashcard session: progress, flip, rate 0/1/2, skip, undo, complete, exit; SRS via foundation repository; card back tabs Context/Dictionary/Notes (P1-limited).

**Independent Test**: 5-card session — skip, all three ratings, one undo behave correctly; complete/exit keep committed ratings (SC-002 / SC-003).

**Depends on**: US2 session start + notifier shell.

### Tests for User Story 3

- [x] T032 [P] [US3] Unit/notifier test flip/rate/skip/undo/in-flight guard in `test/features/vocabulary/vocabulary_review_session_test.dart` (fake or in-memory repository)
- [x] T033 [P] [US3] Widget test flashcard front/back, rating row, progress, complete chrome in `test/features/vocabulary/presentation/vocabulary_review_session_screen_test.dart`

### Implementation for User Story 3

- [x] T034 [US3] Complete `VocabularyReviewSession` notifier (queue index, flipped, ratingInFlight, ratedStack, history, markReviewed/undoLatestReview/skip/previous/complete/exit) in `lib/features/vocabulary/application/vocabulary_review_session.dart` per [data-model.md](./data-model.md) and [contracts/vocabulary-review-session.md](./contracts/vocabulary-review-session.md)
- [x] T035 [P] [US3] Implement flashcard widget (front word + primary context; back tabs Context text / Dictionary cached-only / Notes placeholder; rating row) in `lib/features/vocabulary/presentation/vocabulary_flashcard.dart`
- [x] T036 [US3] Implement `VocabularyReviewSessionScreen` (progress, skip, undo, exit, complete) in `lib/features/vocabulary/presentation/vocabulary_review_session_screen.dart`; load primary context via `getContextsForItem` (earliest `createdAt`)
- [x] T037 [US3] Point `/vocabulary/review` at session screen; on exit/complete pop to `/vocabulary` and ensure stats providers refresh
- [x] T038 [US3] Block rating controls while `ratingInFlight`; ignore duplicate taps/keys during mutation

**Checkpoint**: US3 independently testable — full study loop without requiring desktop shortcuts

---

## Phase 7: User Story 4 - Desktop keyboard control during review (Priority: P2)

**Goal**: In-session shortcuts Space / 1/2/3 / ← / → / Esc with discoverable hint; no global AppHotkeys registration.

**Independent Test**: Desktop manual pass per quickstart; widget/binding tests where practical (SC-006).

**Depends on**: US3 session screen.

### Tests for User Story 4

- [x] T039 [P] [US4] Widget/binding test for in-session shortcuts (Space flip, digits rate when flipped, arrows, Esc) in `test/features/vocabulary/presentation/vocabulary_review_shortcuts_test.dart`

### Implementation for User Story 4

- [x] T040 [US4] Add `Shortcuts` / `Actions` (or `CallbackShortcuts`) focus scope on `VocabularyReviewSessionScreen` mapping keys per contract; respect `ratingInFlight` and flip state
- [x] T041 [US4] Add localized shortcut legend/hint in review chrome in `lib/features/vocabulary/presentation/vocabulary_review_session_screen.dart` (or small widget under `presentation/widgets/`)
- [x] T042 [US4] Confirm review keys are **not** added to `lib/features/hotkeys/` global definitions

**Checkpoint**: US4 complete — desktop keyboard drives session

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Docs, gates, and quickstart validation across stories

- [x] T043 [P] Update `docs/features/vocabulary.md` P1 checklist/status (stats, review UI, shortcuts, list, empty states) and note deferred P2–P4
- [x] T044 [P] Ensure ADR-0053 + `docs/decisions/README.md` index are complete and match shipped navigation
- [x] T045 Run `dart run build_runner build` if any `@Riverpod` / Drift annotations changed; commit generated `*.g.dart`
- [x] T046 Run `flutter analyze` and fix issues
- [x] T047 Run `flutter test test/features/vocabulary/` (and affected Profile/router tests if any)
- [x] T048 Run `bash .github/scripts/validate_ci_gates.sh --fix`
- [x] T049 Execute [quickstart.md](./quickstart.md) manual scenarios (open/stats, review loop, desktop shortcuts, All Words manage, empty states) and note results in PR
- [x] T050 Confirm scope: no Anki export, no sync UI, no clip play / open-in-player / AI persist on review tabs (FR-014 / SC-007)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** all user stories
- **US1 (Phase 3)**: After Foundational — 🎯 MVP
- **US5 (Phase 4)**: After US1 shell (All Words tab host)
- **US2 (Phase 5)**: After Foundational + US1 Review tab host; uses T005 queue builder
- **US3 (Phase 6)**: After US2 session start / notifier shell
- **US4 (Phase 7)**: After US3 session screen
- **Polish (Phase 8)**: After desired stories complete

### User Story Dependencies

| Story | Priority | Depends on | Independently testable? |
|-------|----------|------------|-------------------------|
| US1 Open Vocabulary / stats | P1 | Foundational | Yes — stats/tabs/empty without review |
| US5 All Words manage | P1 | US1 tab host | Yes — list/filter/delete on All Words |
| US2 Review options | P1 | Foundational + US1 | Yes — queue/options without full flashcard chrome if session stub present |
| US3 Flashcard loop | P1 | US2 | Yes — rate/skip/undo with programmatic session start |
| US4 Desktop shortcuts | P2 | US3 | Yes — bindings on existing session |

### Within Each User Story

- Tests marked first SHOULD fail before implementation
- Domain/providers before UI
- Story complete before next priority when staffing is serial

### Parallel Opportunities

- T004 / T005 / T006 domain helpers in parallel
- T009 ARB and T010 ADR in parallel with T007–T008
- After Foundational: US1 then US5 serial on `vocabulary_screen.dart`; US2 queue tests (T026) can start as soon as T005 lands
- Within a story, `[P]` test tasks and unrelated widgets can run in parallel
- US4 only after US3

---

## Parallel Example: Foundational + US1

```bash
# After T001–T003, launch domain helpers together:
Task: "T004 vocabulary_stats.dart"
Task: "T005 vocabulary_session_selection.dart"
Task: "T006 vocabulary_relative_review.dart"

# After T008 providers exist:
Task: "T013 vocabulary_stats_test.dart"
Task: "T014 vocabulary_screen_test.dart"
Task: "T015 vocabulary_stats_strip.dart"
Task: "T016 vocabulary_empty_states.dart"
```

## Parallel Example: User Story 3

```bash
Task: "T032 vocabulary_review_session_test.dart"
Task: "T033 vocabulary_review_session_screen_test.dart"
Task: "T035 vocabulary_flashcard.dart"   # after notifier API sketched
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL)
3. Complete Phase 3: US1 — open Vocabulary, stats, tabs, empty states
4. **STOP and VALIDATE** independently
5. Demo: Profile → Vocabulary shows real counts from lookup-saved words

### Incremental Delivery

1. Setup + Foundational → routes/providers ready
2. US1 → Vocabulary home (MVP)
3. US5 → manage book
4. US2 → start reviews
5. US3 → study loop (core value)
6. US4 → desktop polish
7. Polish → docs + CI gates + quickstart

### Parallel Team Strategy

1. Team completes Setup + Foundational together
2. Dev A: US1 → US5
3. Dev B: US2 queue/options (after T005) → US3 session → US4 shortcuts
4. Integrate on `/vocabulary` Review / All Words tabs

---

## Notes

- [P] tasks = different files, no incomplete-task dependencies
- [Story] label maps task to US1–US5 for traceability
- Foundation (021) SRS/undo/delete MUST remain unchanged in behavior; this feature only consumes them
- No schema bump; no sync/Anki/home due widget in this task list
- Commit after each task or logical group
- Stop at any checkpoint to validate the story independently
