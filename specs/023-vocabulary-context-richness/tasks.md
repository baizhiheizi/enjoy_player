# Tasks: Vocabulary Context Richness

**Input**: Design documents from `specs/023-vocabulary-context-richness/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are required for changed behavior (constitution + plan QR-002). Manual clip / open-player / shadow per [quickstart.md](./quickstart.md).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/vocabulary/{application,data,domain,presentation}/`
- **DAOs**: `lib/data/db/daos/vocabulary_*.dart`
- **AI reuse**: `lib/features/ai/`
- **Player reuse**: `lib/features/player/`, `lib/core/routing/player_navigation.dart`
- **Tests**: `test/features/vocabulary/`
- **Feature docs**: `docs/features/vocabulary.md`
- **l10n**: `lib/l10n/app_*.arb`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm touch points and doc/l10n targets before code changes

- [x] T001 Confirm affected paths from plan against current tree: `lib/features/vocabulary/application/vocabulary_review_session.dart` (text-only `primaryContextByItemId`), `lib/features/vocabulary/presentation/vocabulary_flashcard.dart`, `lib/features/vocabulary/data/vocabulary_repository.dart`, `lib/data/db/daos/vocabulary_context_dao.dart` (no `updateRow` yet), `PlayerController` / `EchoMode` / `openPlayerRoute`, AI dictionary + contextual services
- [x] T002 [P] Identify doc/l10n targets: `docs/features/vocabulary.md` P2 checklist; ARB keys for open-in-player, shadow, contextual translation, play segment, confirm/error/unavailable (per feature string inventory); no new ADR (research §9)
- [x] T003 [P] Ensure `test/features/vocabulary/presentation/` exists for flashcard/context widget tests

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Write path for explanations, session primary-context enrichment, shared codecs/helpers, and P2 ARB keys — required before any user story UI

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Add `VocabularyContextDao.updateRow` in `lib/data/db/daos/vocabulary_context_dao.dart` (mirror item DAO replace/update pattern)
- [x] T005 Add `VocabularyRepository.updateItemExplanation` and `updateContextExplanation` in `lib/features/vocabulary/data/vocabulary_repository.dart` (touch `updatedAt` only; leave SRS fields unchanged) per [contracts/vocabulary-explanation-persist.md](./contracts/vocabulary-explanation-persist.md)
- [x] T006 [P] Add explanation encode/decode helpers (`DictionaryResult` / `ContextualTranslationResult` ↔ JSON string) in `lib/features/vocabulary/domain/vocabulary_explanation_codec.dart` per [data-model.md](./data-model.md)
- [x] T007 Change `ReviewSessionState.primaryContextByItemId` to `Map<String, VocabularyContext>` (or equivalent DTO) and update `start()` loading in `lib/features/vocabulary/application/vocabulary_review_session.dart`; keep primary = earliest `createdAt`; update flashcard callers that read context text via `primaryContextFor`
- [x] T008 [P] Add P2 ARB keys (play segment, open in player + description, shadow reading, contextual translation, unavailable/error) to `lib/l10n/app_en.arb` and mirror in `app_zh.arb` / `app_zh_CN.arb` (and other locales as project requires); run `flutter gen-l10n` if needed
- [x] T009 [P] Unit test repository explanation updates (item + context isolation) in `test/features/vocabulary/vocabulary_explanation_persist_test.dart` against in-memory/test DB patterns used by foundation tests

**Checkpoint**: DAO/repo write path + full primary context in session + ARB keys ready — story UI can begin

---

## Phase 3: User Story 1 - Dictionary persist on card back (Priority: P1) 🎯 MVP

**Goal**: Dictionary tab shows cached item explanation or fetches via existing dictionary AI (auth/credits), persists JSON on the item, and survives offline re-open.

**Independent Test**: Review item with empty explanation → fetch → restart offline → same Dictionary content (SC-001 / explanation-persist C1+C3).

### Tests for User Story 1

- [x] T010 [P] [US1] Unit/notifier test: persist dictionary JSON refreshes queue item explanation without changing SRS in `test/features/vocabulary/vocabulary_review_session_dictionary_test.dart`
- [x] T011 [P] [US1] Widget test Dictionary empty → fetch success → rendered senses (stub dictionary service) in `test/features/vocabulary/presentation/vocabulary_flashcard_dictionary_test.dart`

### Implementation for User Story 1

- [x] T012 [US1] Add session method(s) to fetch dictionary (reuse `dictionaryServiceProvider` / AI cache, auth gate patterns from lookup) and call `updateItemExplanation` then refresh queue item in `lib/features/vocabulary/application/vocabulary_review_session.dart`
- [x] T013 [US1] Extend Dictionary tab UI in `lib/features/vocabulary/presentation/vocabulary_flashcard.dart` (and session screen wiring if needed): show cache; fetch control when allowed; in-flight + error/unavailable states; do not block ratings except existing `ratingInFlight`
- [x] T014 [US1] Verify dictionary fetch in-flight is independent of `ratingInFlight` per explanation-persist C1

**Checkpoint**: US1 independently testable — Dictionary persist works without contextual AI or media actions

---

## Phase 4: User Story 2 - Contextual translation persist (Priority: P1)

**Goal**: Context tab shows/fetches contextual translation and persists on that context only.

**Independent Test**: Fetch contextual translation → offline re-open same context; sibling contexts unchanged (SC-002 / explanation-persist C2).

**Depends on**: Foundational session primary `VocabularyContext` (T007); can follow US1 or proceed in parallel after Phase 2.

### Tests for User Story 2

- [x] T015 [P] [US2] Unit/notifier test: contextual persist updates one context id only in `test/features/vocabulary/vocabulary_review_session_contextual_test.dart`
- [x] T016 [P] [US2] Widget test Context tab translation empty → fetch → shown in `test/features/vocabulary/presentation/vocabulary_flashcard_context_test.dart`

### Implementation for User Story 2

- [x] T017 [US2] Add session method(s) to fetch contextual translation (reuse `contextualTranslationServiceProvider` / cache + auth gate) and call `updateContextExplanation` then refresh `primaryContextByItemId` in `lib/features/vocabulary/application/vocabulary_review_session.dart`
- [x] T018 [US2] Extend Context tab in `lib/features/vocabulary/presentation/vocabulary_flashcard.dart` per [contracts/vocabulary-context-tab.md](./contracts/vocabulary-context-tab.md): show text + translation UI + fetch/error/unavailable (media action buttons can remain stubs until US3–US5)
- [x] T019 [US2] Confirm Notes tab remains placeholder only in `lib/features/vocabulary/presentation/vocabulary_flashcard.dart`

**Checkpoint**: US2 independently testable — contextual persist without requiring clip play

---

## Phase 5: User Story 3 - Play media clip from context (Priority: P1)

**Goal**: Play locator segment via shared `PlayerController` while staying in the review session.

**Independent Test**: Media context → Play segment → hear clip; still on `/vocabulary/review`; can rate afterward (SC-003 / media-actions C1).

**Depends on**: Foundational primary context with locator (T007); Context tab shell from US2 helpful but not strictly required if play action is added alongside text.

### Tests for User Story 3

- [x] T020 [P] [US3] Unit test locator ms→seconds window helper (and/or media orchestration with mocked player) in `test/features/vocabulary/vocabulary_review_session_media_test.dart`
- [x] T021 [P] [US3] Widget/notifier test: Play segment invokes openMedia+seek+play path and does not clear session in `test/features/vocabulary/vocabulary_review_session_media_test.dart` (or presentation test)

### Implementation for User Story 3

- [x] T022 [P] [US3] Implement clip-play helper in `lib/features/vocabulary/application/vocabulary_review_media.dart` (`openMedia` → seek to locator start → play; optional `EchoMode` window; never construct `Player()`) per [contracts/vocabulary-media-actions.md](./contracts/vocabulary-media-actions.md) and research §5
- [x] T023 [US3] Wire Play segment on Context tab in `lib/features/vocabulary/presentation/vocabulary_flashcard.dart` / `vocabulary_review_session_screen.dart`; hide/disable for ebook/invalid locator; failure message for missing media; stay on review route
- [x] T024 [US3] Ensure clip play does not call `markReviewed` and uses `clipPlayInFlight` (or equivalent) to avoid double-start

**Checkpoint**: US3 independently testable — clip play without open-in-player or shadow

---

## Phase 6: User Story 4 - Open in player with confirm (Priority: P2)

**Goal**: Confirm dialog; cancel keeps review; confirm exits session and opens player near locator start.

**Independent Test**: Cancel stays on card; confirm ends review and opens `/player/:mediaId` near start (SC-004 / media-actions C2).

**Depends on**: Primary context with `sourceId` + locator (T007); typically after US3 media helper exists (reuse open/seek).

### Tests for User Story 4

- [x] T025 [P] [US4] Notifier/widget test: open-in-player cancel keeps session; confirm clears session and requests navigation in `test/features/vocabulary/vocabulary_review_session_media_test.dart` (extend) or `test/features/vocabulary/presentation/vocabulary_open_in_player_test.dart`

### Implementation for User Story 4

- [x] T026 [US4] Add open-in-player flow in `lib/features/vocabulary/application/vocabulary_review_media.dart` / session: confirm via `showEnjoyAlertDialog` with ARB copy → on confirm exit/clear session → `openPlayerRoute` + seek to locator start in `lib/features/vocabulary/presentation/vocabulary_review_session_screen.dart`
- [x] T027 [US4] Wire Open in player control on Context tab; handle open failure without stuck half-session (return to `/vocabulary` if needed) per media-actions C2

**Checkpoint**: US4 independently testable with mocked navigation/player

---

## Phase 7: User Story 5 - Shadow reading hand-off (Priority: P2)

**Goal**: Confirm hand-off from Context tab → open player → activate echo for locator span → existing shadow UI (no embedded panel).

**Independent Test**: Suitable media context → Shadow → confirm → player + echo; no second player; prior ratings intact (SC-005 / media-actions C3).

**Depends on**: Open-player hand-off patterns from US4; echo APIs.

### Tests for User Story 5

- [x] T028 [P] [US5] Notifier/unit test: shadow confirm path requests openMedia + `EchoMode.activate` (or restore) with locator window and clears review session in `test/features/vocabulary/vocabulary_review_session_media_test.dart`

### Implementation for User Story 5

- [x] T029 [US5] Implement shadow hand-off in `lib/features/vocabulary/application/vocabulary_review_media.dart`: confirm → exit review → `openPlayerRoute` → activate echo for locator start/end seconds (resolve line indices when transcript available per research §7)
- [x] T030 [US5] Wire Shadow reading control on Context tab in `lib/features/vocabulary/presentation/vocabulary_flashcard.dart`; hide/disable when unsuitable; do not embed `ShadowReadingPanel` in flashcard
- [x] T031 [US5] Manual verify shadow UI appears under normal echo+transcript path (document in PR / quickstart note)

**Checkpoint**: All user stories independently functional

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Docs, unavailable polish, verification gates

- [x] T032 [P] Update `docs/features/vocabulary.md` P2 checklist/status (dictionary/contextual persist, clip play, open-in-player, shadow) and status blurb at top
- [x] T033 [P] Polish Context tab source title / locator label resolution (library lookup by `sourceId`) in `lib/features/vocabulary/presentation/vocabulary_flashcard.dart` per context-tab C2
- [x] T034 Run [quickstart.md](./quickstart.md) manual scenarios 1–6; note clip-start latency if slow
- [x] T035 Run `dart run build_runner build` if `@Riverpod` annotations changed
- [x] T036 Run `flutter analyze` and `flutter test test/features/vocabulary/`
- [x] T037 Run `bash .github/scripts/validate_ci_gates.sh --fix` before push

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** all user stories
- **US1 (Phase 3)**: After Foundational — MVP
- **US2 (Phase 4)**: After Foundational — parallelizable with US1
- **US3 (Phase 5)**: After Foundational — parallelizable with US1/US2 (Context tab chrome from US2 reduces UI churn)
- **US4 (Phase 6)**: After Foundational; prefer after US3 media helper
- **US5 (Phase 7)**: After US4 hand-off patterns (or share media helper with US4)
- **Polish (Phase 8)**: After desired stories complete

### User Story Dependencies

| Story | Priority | Depends on | Independently testable? |
|-------|----------|------------|-------------------------|
| US1 Dictionary persist | P1 | Phase 2 | Yes — MVP |
| US2 Contextual persist | P1 | Phase 2 | Yes |
| US3 Clip play | P1 | Phase 2 (+ media helper) | Yes |
| US4 Open in player | P2 | Phase 2; best after US3 | Yes (mocked nav) |
| US5 Shadow hand-off | P2 | US4-style exit + echo | Yes (mocked player/echo) |

### Within Each User Story

- Tests marked first SHOULD fail before implementation where practical
- Session/repo methods before flashcard wiring
- Story complete before next priority when staffing is serial

### Parallel Opportunities

- T002 / T003 in Setup
- T004 / T006 / T008 / T009 in Foundational (T005 after T004; T007 can parallel T004–T006 once API shapes known)
- After Phase 2: US1 and US2 in parallel; US3 media helper in parallel with AI stories
- Test tasks marked [P] within a story

---

## Parallel Example: After Foundational

```bash
# Developer A — US1 Dictionary
Task: "T010–T014 dictionary persist + flashcard Dictionary tab"

# Developer B — US2 Contextual
Task: "T015–T019 contextual persist + Context tab translation"

# Developer C — US3 Clip (after T007)
Task: "T020–T024 vocabulary_review_media clip play"
```

---

## Parallel Example: User Story 1

```bash
Task: "T010 Unit/notifier dictionary persist test in test/features/vocabulary/vocabulary_review_session_dictionary_test.dart"
Task: "T011 Widget Dictionary fetch test in test/features/vocabulary/presentation/vocabulary_flashcard_dictionary_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup  
2. Complete Phase 2: Foundational (CRITICAL)  
3. Complete Phase 3: US1 Dictionary persist  
4. **STOP and VALIDATE**: offline re-open of dictionary explanation  
5. Demo MVP value (review AI cache write-through)

### Incremental Delivery

1. Setup + Foundational → write path + session context ready  
2. US1 Dictionary → MVP  
3. US2 Contextual translation → richer Context tab  
4. US3 Clip play → hear media in-session  
5. US4 Open in player → full player dive  
6. US5 Shadow hand-off → practice parity  
7. Polish → docs + CI gates  

### Parallel Team Strategy

1. Team completes Setup + Foundational together  
2. Split US1 / US2 / US3; serialize US4 → US5 on media helper  

---

## Notes

- [P] = different files, no incomplete-task dependencies  
- No schema migration (ADR-0052 / schema 15 already has explanation columns)  
- Never construct a second `media_kit` `Player()`  
- Notes tab stays placeholder  
- Sync / Anki / home due / ebook play remain out of scope  
- Commit after each task or logical group when implementing  
- Stop at any checkpoint to validate the story independently  
