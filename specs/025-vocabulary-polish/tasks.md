# Tasks: Vocabulary Polish

**Input**: Design documents from `specs/025-vocabulary-polish/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are required for changed behavior (constitution + plan QR-002). Manual YouTube/local/echo/full-player per [quickstart.md](./quickstart.md).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/vocabulary/{application,data,domain,presentation}/`
- **Core sheet**: `lib/core/theme/widgets/enjoy_modal.dart`
- **Player**: `lib/features/player/`, `lib/core/routing/player_navigation.dart`
- **Shadow**: `lib/features/shadow_reading/presentation/shadow_reading_panel.dart`
- **Tests**: `test/features/vocabulary/`
- **Feature docs**: `docs/features/vocabulary.md`
- **l10n**: `lib/l10n/app_*.arb`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm touch points and doc/l10n targets before code changes

- [x] T001 Confirm affected paths from plan against current tree: `lib/features/vocabulary/presentation/widgets/vocabulary_stats_strip.dart`, `vocabulary_flashcard.dart`, `vocabulary_review_session_screen.dart`, `application/vocabulary_review_session.dart`, `application/vocabulary_review_media.dart`, `lib/core/theme/widgets/enjoy_modal.dart` (`showEnjoySheet` bottom-only), `ShadowReadingPanel`, `GlobalTransportBar` / `root_shell.dart`, `openPlayerRoute`
- [x] T002 [P] Identify doc/l10n targets: `docs/features/vocabulary.md` (hub stats + flashcard practice sheet + multi-context); ARB keys for stats expand/collapse, practice sheet titles (clip/echo), dismiss, context pager n-of-m, modal/errors; no new ADR unless adaptive-sheet helper is documented in app-ui
- [x] T003 [P] Ensure test directories exist: `test/features/vocabulary/presentation/`, `test/core/theme/` (or equivalent) for adaptive sheet helper tests

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Practice mode enum, session multi-context + practice state, adaptive sheet helper, shared ARB — required before story UI

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Add `ReviewPracticeMode` (`none` | `clip` | `echo`) in `lib/features/vocabulary/domain/vocabulary_review_practice.dart` per [data-model.md](./data-model.md)
- [x] T005 Extend `VocabularyReviewSession` / state in `lib/features/vocabulary/application/vocabulary_review_session.dart`: load `contextsByItemId` (all contexts, `createdAt` asc), `activeContextIndexByItemId` (default 0), replace single-primary-only map with active-context getters; add `practiceMode`, `clearPractice()` (pause + `EchoMode.deactivate` + `practice = none`)
- [x] T006 [P] Add `showEnjoyAdaptiveSheet` (or equivalent) in `lib/core/theme/widgets/enjoy_modal.dart`: compact → bottom sheet (reuse `showEnjoySheet` styling); wide → centered dialog/`modalMaxWidthLarge`; shared scrim; document breakpoint (~600) per [research.md](./research.md) §4
- [x] T007 [P] Unit test adaptive sheet presentation choice (compact vs wide) in `test/core/theme/enjoy_adaptive_sheet_test.dart` (or `test/features/vocabulary/` if preferred)
- [x] T008 [P] Add polish ARB keys (stats expand/collapse semantics, practice sheet clip/echo titles, dismiss, context pager `n of m`, practice errors) to `lib/l10n/app_en.arb` and mirror in `app_zh.arb` / `app_zh_CN.arb` (and other project locales); run `flutter gen-l10n`
- [x] T009 [P] Unit test session context list load + default index 0 + `clearPractice` resets mode in `test/features/vocabulary/vocabulary_review_session_practice_test.dart`

**Checkpoint**: Session can expose active context list/index + practice mode; adaptive sheet API exists; ARB ready

---

## Phase 3: User Story 1 - Compact Vocabulary hub stats (Priority: P1) 🎯 MVP

**Goal**: Phone hub is list-first — collapsed Total | Due with expandable status breakdown; no tall 2×3 stats grid.

**Independent Test**: Open Vocabulary on narrow viewport → list/tabs visible without scrolling past six large cards; expand shows new/learning/reviewing/mastered ([contracts/vocabulary-hub-stats.md](./contracts/vocabulary-hub-stats.md), SC-001).

### Tests for User Story 1

- [x] T010 [P] [US1] Widget test collapsed stats show Total + Due and expand reveals status counts in `test/features/vocabulary/presentation/vocabulary_stats_strip_test.dart`
- [x] T011 [P] [US1] Widget/pump test Vocabulary screen first layout prioritizes tabs/list over tall stats grid in `test/features/vocabulary/presentation/vocabulary_screen_test.dart` (extend existing)

### Implementation for User Story 1

- [x] T012 [US1] Redesign `VocabularyStatsStrip` in `lib/features/vocabulary/presentation/widgets/vocabulary_stats_strip.dart`: collapsed summary row (Total | Due emphasized); expandable dense status breakdown; remove default phone 2×3 bordered tile grid per hub-stats contract
- [x] T013 [US1] Wire expand/collapse + l10n/semantics in `vocabulary_stats_strip.dart` / `vocabulary_screen.dart` as needed; keep `EnjoyPageKind.hub`
- [x] T014 [US1] Verify empty-book stats treatment still looks coherent with `VocabularyEmptyState` in `lib/features/vocabulary/presentation/widgets/vocabulary_empty_states.dart`

**Checkpoint**: US1 independently testable — hub usable without practice sheet work

---

## Phase 4: User Story 2 - Play clip in practice sheet (Priority: P1)

**Goal**: Play clip opens shared modal adaptive practice sheet with mini-player (YouTube + local); review stays active; not global mini-bar.

**Independent Test**: Seed YT + local contexts → Play clip → sheet opens with stage, locator window plays, dismiss returns to card ([contracts/vocabulary-practice-sheet.md](./contracts/vocabulary-practice-sheet.md) C2/C6, SC-002/003).

### Tests for User Story 2

- [x] T015 [P] [US2] Notifier test: open clip sets `practiceMode = clip`; `clearPractice` resets in `test/features/vocabulary/vocabulary_review_session_practice_test.dart`
- [x] T016 [P] [US2] Widget test: Play clip opens practice sheet host (stub player) in `test/features/vocabulary/presentation/vocabulary_practice_sheet_test.dart`

### Implementation for User Story 2

- [x] T017 [US2] Add session API `openPracticeClip()` (or equivalent) calling `playVocabularyClip` then setting `practiceMode = clip` in `lib/features/vocabulary/application/vocabulary_review_session.dart` / `vocabulary_review_media.dart`
- [x] T018 [P] [US2] Create `VocabularyPracticeClipBody` hosting `activeEngine.buildVideoStage` + compact transport/dismiss in `lib/features/vocabulary/presentation/widgets/vocabulary_practice_clip_body.dart`
- [x] T019 [US2] Create `showVocabularyPracticeSheet` / `VocabularyPracticeSheet` host using `showEnjoyAdaptiveSheet` in `lib/features/vocabulary/presentation/widgets/vocabulary_practice_sheet.dart` (clip body when mode=clip)
- [x] T020 [US2] Wire Play clip from `vocabulary_flashcard.dart` / `vocabulary_review_session_screen.dart` to open sheet (do **not** embed stage in Context tab); on dismiss call `clearPractice()`
- [x] T021 [US2] Suppress `GlobalTransportBar` while practice clip stage mounted in `lib/features/player/presentation/root_shell.dart` (or session-derived flag) per practice-sheet C2

**Checkpoint**: US2 independently testable with stub/local media — sheet clip path works without echo UI

---

## Phase 5: User Story 3 - Echo reading in practice sheet (Priority: P1)

**Goal**: Echo reading opens the **same** sheet in echo mode with `ShadowReadingPanel` (record / playback / assess); no confirm-exit to full player.

**Independent Test**: Start echo from Context → sheet shows recorder → record/playback without leaving `/vocabulary/review` (practice-sheet C3, SC-004).

### Tests for User Story 3

- [x] T022 [P] [US3] Notifier test: open echo sets `practiceMode = echo` and does not clear session in `test/features/vocabulary/vocabulary_review_session_practice_test.dart`
- [x] T023 [P] [US3] Widget test: Echo action opens sheet echo body (stub panel if needed) in `test/features/vocabulary/presentation/vocabulary_practice_sheet_test.dart`

### Implementation for User Story 3

- [x] T024 [US3] Add session API `openPracticeEcho()` activating EchoMode window for active context locator in `vocabulary_review_session.dart` / `vocabulary_review_media.dart` (remove/default-off confirm→exit shadow hand-off from review)
- [x] T025 [P] [US3] Create `VocabularyPracticeEchoBody` hosting `ShadowReadingPanel` in `lib/features/vocabulary/presentation/widgets/vocabulary_practice_echo_body.dart` (optional compact density on `shadow_reading_panel.dart`)
- [x] T026 [US3] Extend `VocabularyPracticeSheet` to show echo body when `practiceMode = echo`; wire Echo action in `vocabulary_flashcard.dart` / `vocabulary_review_session_screen.dart`
- [x] T027 [US3] Ensure unavailable/mic-denied paths show localized errors without ending review

**Checkpoint**: US3 independently testable — echo sheet works; clip may still be separate until US4 swap polish

---

## Phase 6: User Story 4 - Mutual exclusivity + modal sheet (Priority: P1)

**Goal**: One sheet host; clip XOR echo; modal (no rate/flip until dismiss); Esc dismisses sheet first.

**Independent Test**: Clip → Echo swaps body; rate blocked while open; dismiss then rate works (SC-005, SC-010, practice-sheet C4/C5).

### Tests for User Story 4

- [x] T028 [P] [US4] Notifier test: opening echo while clip (and reverse) leaves exactly one mode in `test/features/vocabulary/vocabulary_review_session_practice_test.dart`
- [x] T029 [P] [US4] Widget test: with sheet open, rating controls on card are not usable until dismiss in `test/features/vocabulary/presentation/vocabulary_practice_sheet_test.dart`

### Implementation for User Story 4

- [x] T030 [US4] Enforce mode swap in session + sheet host: entering clip tears down echo body and vice versa in `vocabulary_review_session.dart` + `vocabulary_practice_sheet.dart`
- [x] T031 [US4] Modal behavior: barrierDismissible + block rate/flip/skip while sheet route open in `vocabulary_review_session_screen.dart` (and keyboard: Esc dismisses sheet before exit review)
- [x] T032 [US4] On dismiss/swap/card change: `clearPractice()` always unmounts stage/panel and deactivates echo

**Checkpoint**: US4 — exclusivity + modal rules verified

---

## Phase 7: User Story 5 - Open in player full screen (Priority: P1)

**Goal**: Open in player confirms, ends review, lands expanded `/player/:id` at locator start (YT + local); not mini-bar.

**Independent Test**: Confirm hand-off → full player at timestamp; cancel stays in review (SC-006, practice-sheet C7).

### Tests for User Story 5

- [x] T033 [P] [US5] Notifier/widget test: confirm clears session + practice; cancel keeps session in `test/features/vocabulary/vocabulary_review_session_media_test.dart` (extend) or presentation test

### Implementation for User Story 5

- [x] T034 [US5] Open in player: confirm → `replacePlayerLaunch(PlayerLaunchRequest.vocabularyOpenSource)` (expanded `/player/:id` at locator start; review `onExit` clears session) — ADR-0057
- [x] T035 [US5] Verify expanded player (`PlayerUi.expand`) and failure recovery to Vocabulary; keep confirm dialog copy localized

**Checkpoint**: US5 independently testable — full-player destination correct

---

## Phase 8: User Story 6 - Multi-context switcher (Priority: P1)

**Goal**: Items with 2+ contexts show pager; actions/sheet bind to active context; switch dismisses practice.

**Independent Test**: Item with 3 contexts → visit each via pager; play/echo/open target selected context (SC-007, [vocabulary-context-switcher.md](./contracts/vocabulary-context-switcher.md)).

### Tests for User Story 6

- [x] T036 [P] [US6] Unit test: `selectContext` clamps index, updates active context, forces `practice = none` in `test/features/vocabulary/vocabulary_review_session_practice_test.dart`
- [x] T037 [P] [US6] Widget test: pager visible iff ≥2 contexts; n-of-m updates in `test/features/vocabulary/presentation/vocabulary_context_pager_test.dart`

### Implementation for User Story 6

- [x] T038 [P] [US6] Create `VocabularyContextPager` in `lib/features/vocabulary/presentation/widgets/vocabulary_context_pager.dart` (prev/next + localized n of m + tooltips/semantics)
- [x] T039 [US6] Add `selectContext(index)` / next/prev on session in `vocabulary_review_session.dart`; front preview + Context tab bind to `activeContext`
- [x] T040 [US6] Insert pager into `vocabulary_flashcard.dart` Context (and front preview as applicable); block or dismiss sheet before context change per FR-006a
- [x] T041 [US6] Confirm rating still writes item-level SRS only (no per-context scores)

**Checkpoint**: US6 independently testable — multi-context navigation works

---

## Phase 9: User Story 7 - Flashcard layout usable on mobile (Priority: P2)

**Goal**: Context tab stays clean without embedded practice chrome; sheet sizing works on short viewports; wide centered modal.

**Independent Test**: Phone + desktop passes for layout contracts ([vocabulary-flashcard-layout.md](./contracts/vocabulary-flashcard-layout.md), SC-008, SC-011).

### Tests for User Story 7

- [x] T042 [P] [US7] Widget test: Context tab tree has no embedded video/recorder when sheet closed in `test/features/vocabulary/presentation/vocabulary_flashcard_context_test.dart` (extend)
- [x] T043 [P] [US7] Widget test: wide viewport uses centered adaptive sheet path (pump width) in `test/features/vocabulary/presentation/vocabulary_practice_sheet_test.dart`

### Implementation for User Story 7

- [x] T044 [US7] Apply practice sheet max heights / scroll for clip + echo bodies per flashcard-layout C2 in `vocabulary_practice_clip_body.dart` / `vocabulary_practice_echo_body.dart`
- [x] T045 [US7] Polish Context tab vertical order (quote → pager → meta → actions → AI) in `vocabulary_flashcard.dart`; sticky rating footer unchanged
- [x] T046 [US7] Manual pass quickstart §1–§9 layout/stress notes; fix overflow if found

**Checkpoint**: US7 — mobile + desktop layout acceptable

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Docs, CI green, quickstart sign-off

- [x] T047 [P] Update `docs/features/vocabulary.md` — hub stats, practice sheet (clip/echo modal adaptive), supersede review shadow hand-off, multi-context pager
- [x] T048 [P] Optionally note adaptive sheet helper in `docs/features/app-ui.md` if the new API is shared
- [x] T049 Run [quickstart.md](./quickstart.md) manual scenarios §1–§9; record any follow-ups
- [x] T050 Run `bash .github/scripts/validate_ci_gates.sh --fix` (format + codegen + analyze/test as scripted)
- [x] T051 Run `flutter analyze` and `flutter test`; fix until green
- [x] T052 Run `dart run build_runner build` if any `@Riverpod` / Drift annotations changed; commit generated files

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** all user stories
- **US1 (Phase 3)**: After Foundational — independent of practice sheet
- **US2 (Phase 4)**: After Foundational — needs adaptive sheet + session practice mode
- **US3 (Phase 5)**: After Foundational — ideally after US2 sheet host exists (T019), or implement host in US3 if US2 deferred
- **US4 (Phase 6)**: After US2 + US3 sheet modes exist
- **US5 (Phase 7)**: After Foundational; integrate with sheet dismiss (US2+)
- **US6 (Phase 8)**: After Foundational session multi-context (T005); integrate dismiss-with-sheet (US4)
- **US7 (Phase 9)**: After US2–US4 sheet + US6 pager in place
- **Polish (Phase 10)**: After desired stories complete

### User Story Dependencies

| Story | Depends on | Independently testable? |
|-------|------------|-------------------------|
| US1 Hub stats | Phase 2 ARB optional | Yes — hub only |
| US2 Clip sheet | Phase 2 adaptive sheet + session | Yes — with stubs |
| US3 Echo sheet | Phase 2 + sheet host (US2 T019) | Yes — echo path |
| US4 Exclusivity/modal | US2 + US3 | Yes — interaction rules |
| US5 Open in player | Phase 2; sheet dismiss nice-to-have | Yes |
| US6 Context pager | Phase 2 T005 | Yes — without media |
| US7 Layout | US2–US4, US6 | Yes — layout checks |

### Parallel Opportunities

- T002/T003 after T001
- T004, T006, T007, T008 in parallel during Phase 2 (T005 sequential with T009)
- US1 can run in parallel with US2 once Phase 2 done
- Within a story, [P] tests and [P] widget files can proceed together

---

## Parallel Example: After Foundational

```text
# Developer A — MVP hub:
Task: T010–T014 (US1 stats)

# Developer B — practice sheet clip:
Task: T015–T021 (US2)

# Developer C — context pager (uses T005):
Task: T036–T041 (US6)
```

---

## Parallel Example: User Story 2

```text
Task: "Notifier test open clip in test/features/vocabulary/vocabulary_review_session_practice_test.dart"
Task: "Clip body widget in lib/features/vocabulary/presentation/widgets/vocabulary_practice_clip_body.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 + Phase 2
2. Complete Phase 3 (US1 compact stats)
3. **STOP and VALIDATE** hub on phone
4. Demo list-first Vocabulary

### Recommended incremental path

1. Setup + Foundational  
2. **US1** hub stats (immediate UX win)  
3. **US2** clip sheet → **US3** echo → **US4** exclusivity/modal  
4. **US5** open-in-player polish  
5. **US6** context pager  
6. **US7** layout polish  
7. Phase 10 docs + CI  

### Parallel Team Strategy

- After Phase 2: A=US1, B=US2 sheet host+clip, C=US6 pager  
- Then B continues US3/US4; A or C takes US5/US7 + polish  

---

## Notes

- [P] = different files, no incomplete-task dependencies
- Practice chrome is a **modal adaptive sheet**, not Context-tab embed (clarifications 2026-07-19)
- Never construct a second lesson-media `Player()`; WAV preview may use `RecordingPreviewPlayer`
- Commit after each task or logical group; keep tree green (`flutter analyze` / `flutter test`)
- Stop at any checkpoint to validate the story independently
