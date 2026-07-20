# Tasks: Vocabulary Foundation

**Input**: Design documents from `specs/021-vocabulary-foundation/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are required for changed behavior (constitution + plan QR-002 / SC-003). Manual playback smoke per [quickstart.md](./quickstart.md).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `lib/features/vocabulary/{application,data,domain,presentation}/`
- **Shared code**: `lib/core/ids/`, `lib/data/db/`
- **Lookup seam**: `lib/features/lookup/`
- **Tests**: `test/features/vocabulary/`, `test/core/ids/`, `test/features/lookup/`
- **Feature docs**: `docs/features/vocabulary.md`
- **ADRs**: `docs/decisions/0052-vocabulary-local-first-schema.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm touch points and doc/ADR targets before code changes

- [x] T001 Confirm affected paths from plan (`lib/core/ids/enjoy_ids.dart`, `lib/data/db/app_database.dart`, `lib/features/vocabulary/`, `lib/features/lookup/domain/lookup_request.dart`, `lib/features/lookup/application/transcript_lookup_open.dart`, `lib/features/lookup/presentation/dictionary_lookup_sheet.dart`) against current tree
- [x] T002 [P] Identify doc/ADR/l10n targets: `docs/features/vocabulary.md`, `docs/decisions/0052-vocabulary-local-first-schema.md`, `docs/decisions/README.md`, `lib/l10n/app_en.arb` (+ other locale ARBs as needed)
- [x] T003 Create feature directory skeleton `lib/features/vocabulary/{application,data,domain,presentation}/` and `test/features/vocabulary/` per plan structure

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain models + Drift schema/DAOs that all stories need

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Define domain models (item, context, review, media/ebook locator, status, rating, add result) in `lib/features/vocabulary/domain/vocabulary_models.dart` per [data-model.md](./data-model.md)
- [x] T005 [P] Create Drift table `VocabularyItems` in `lib/data/db/tables/vocabulary_items.dart` (fields + indexes per data-model)
- [x] T006 [P] Create Drift table `VocabularyContexts` in `lib/data/db/tables/vocabulary_contexts.dart`
- [x] T007 [P] Create Drift table `VocabularyReviews` in `lib/data/db/tables/vocabulary_reviews.dart`
- [x] T008 Register vocabulary tables/DAOs, bump `schemaVersion` to **15**, and add additive migration in `lib/data/db/app_database.dart`
- [x] T009 [P] Implement `VocabularyItemDao` CRUD + by-id / by-word lookups in `lib/data/db/daos/vocabulary_item_dao.dart`
- [x] T010 [P] Implement `VocabularyContextDao` CRUD + by-item / by-source queries in `lib/data/db/daos/vocabulary_context_dao.dart`
- [x] T011 [P] Implement `VocabularyReviewDao` insert/latest-by-item/delete in `lib/data/db/daos/vocabulary_review_dao.dart`
- [x] T012 Run `dart run build_runner build` and commit regenerated Drift `*.g.dart` outputs
- [x] T013 Create `VocabularyRepository` shell (db access, JSON encode/decode helpers for locator/explanation) in `lib/features/vocabulary/data/vocabulary_repository.dart` without full add/delete yet
- [x] T014 [P] Add Riverpod `vocabularyRepositoryProvider` (and any db wiring) in `lib/features/vocabulary/application/vocabulary_providers.dart`

**Checkpoint**: Schema 15 + DAOs + models ready — user story implementation can begin

---

## Phase 3: User Story 4 - Word identity & SRS contracts (Priority: P1)

**Goal**: Unicode-safe normalize, deterministic UUID v5 ids, stable locator JSON, pure `calculateNextReview` / due predicate, and mark-reviewed + undo persistence matching Enjoy web — without flashcard UI.

**Independent Test**: Ported identity/SRS/undo unit + repository tests pass (SC-003); no lookup UI required.

### Tests for User Story 4

- [x] T015 [P] [US4] Extend `test/core/ids/enjoy_ids_test.dart` for `enjoyVocabularyItemId` / `enjoyVocabularyContextId` determinism and language-pair sensitivity
- [x] T016 [P] [US4] Add normalize + stable locator JSON tests in `test/features/vocabulary/vocabulary_normalize_test.dart` and `test/features/vocabulary/vocabulary_locator_json_test.dart`
- [x] T017 [P] [US4] Port web SRS fixtures into `test/features/vocabulary/vocabulary_srs_test.dart` (ratings 0/1/2, clamps, mastery, pre/post status, nextReviewAt UTC midnight, due predicate)
- [x] T018 [P] [US4] Add mark-reviewed + undo repository tests in `test/features/vocabulary/vocabulary_repository_srs_test.dart`

### Implementation for User Story 4

- [x] T019 [P] [US4] Implement `normalizeWord` in `lib/features/vocabulary/domain/vocabulary_normalize.dart` per [contracts/vocabulary-identity-srs.md](./contracts/vocabulary-identity-srs.md)
- [x] T020 [P] [US4] Implement `stableLocatorJson` (sorted keys) in `lib/features/vocabulary/domain/vocabulary_locator_json.dart`
- [x] T021 [P] [US4] Add `enjoyVocabularyItemId` / `enjoyVocabularyContextId` to `lib/core/ids/enjoy_ids.dart`
- [x] T022 [P] [US4] Implement `calculateNextReview`, constants, and due predicate in `lib/features/vocabulary/domain/vocabulary_srs.dart`
- [x] T023 [US4] Implement `markReviewed` and `undoLatestReview` atomic transactions in `lib/features/vocabulary/data/vocabulary_repository.dart` (audit pre-image; never enqueue sync)
- [x] T024 [US4] Implement due-items query helper on DAO/repository for predicate coverage in `lib/data/db/daos/vocabulary_item_dao.dart` / `lib/features/vocabulary/data/vocabulary_repository.dart`

**Checkpoint**: US4 independently testable — identity + SRS + undo green without UI

---

## Phase 4: User Story 1 - Save a word from transcript lookup (Priority: P1) 🎯 MVP

**Goal**: From the dictionary lookup sheet, add a new vocabulary item + media context (sentence + locator) with correct defaults; CTA shows in-book state after success.

**Independent Test**: Open lookup on a transcript selection → Add to Vocabulary → item+context persisted; control leaves “not in book” state; languages stored from sheet.

**Depends on**: Phase 3 (US4) for normalize/ids/defaults helpers.

### Tests for User Story 1

- [x] T025 [P] [US1] Add structured media context builder tests in `test/features/vocabulary/media_vocabulary_context_builder_test.dart` (echo ≥2 lines; sentence expansion; ms locator)
- [x] T026 [P] [US1] Add `addWithContext` new-item repository tests in `test/features/vocabulary/vocabulary_repository_add_test.dart` (defaults, contextsCount=1, atomic write)
- [x] T027 [P] [US1] Add widget test for Add to Vocabulary busy → in-book transition in `test/features/lookup/add_to_vocabulary_control_test.dart` (or vocabulary presentation test)

### Implementation for User Story 1

- [x] T028 [US1] Implement `buildMediaVocabularyContext` in `lib/features/vocabulary/application/media_vocabulary_context_builder.dart` (sibling to string-only `lib/features/lookup/application/vocabulary_context_builder.dart`)
- [x] T029 [US1] Implement `addWithContext` (create path) in `lib/features/vocabulary/data/vocabulary_repository.dart` per [contracts/vocabulary-persistence.md](./contracts/vocabulary-persistence.md)
- [x] T030 [US1] Extend `LookupRequest` with media linkage / persistable context fields in `lib/features/lookup/domain/lookup_request.dart`
- [x] T031 [US1] Pass media id, source type, and structured context (or builder inputs) from `lib/features/lookup/application/transcript_lookup_open.dart`
- [x] T032 [US1] Add Riverpod existence/action APIs for current selection in `lib/features/vocabulary/application/vocabulary_providers.dart`
- [x] T033 [P] [US1] Add ARB keys for add / adding states in `lib/l10n/app_en.arb` (and mirror locales) + run `flutter gen-l10n`
- [x] T034 [US1] Implement `AddToVocabularyControl` in `lib/features/vocabulary/presentation/add_to_vocabulary_control.dart` (not-in-book + busy)
- [x] T035 [US1] Mount CTA on `lib/features/lookup/presentation/dictionary_lookup_sheet.dart` without changing lookup language catalogs (ADR-0042)
- [x] T036 [US1] Verify add path stays off AI network and document ~1s playback responsiveness check per quickstart / SC-007

**Checkpoint**: US1 independently testable — capture from lookup works for new words

---

## Phase 5: User Story 2 - Add context or recognize exact duplicate (Priority: P1)

**Goal**: Same language-pair word gets a new context when locator differs; exact media locator duplicate is a no-op with **Already in Vocabulary** state; different language pairs stay separate items.

**Independent Test**: Add once; add at new locator → contextsCount+1; add at same locator → no bump; different targetLanguage → new item id.

### Tests for User Story 2

- [x] T037 [P] [US2] Extend `test/features/vocabulary/vocabulary_repository_add_test.dart` for second context, exact duplicate no-op, and different targetLanguage → different item
- [x] T038 [P] [US2] Extend CTA widget tests for Add Context vs Already in Vocabulary in `test/features/lookup/add_to_vocabulary_control_test.dart`

### Implementation for User Story 2

- [x] T039 [US2] Complete `addWithContext` merge/dedup branches (existing item, media start/duration equality) in `lib/features/vocabulary/data/vocabulary_repository.dart`
- [x] T040 [US2] Derive CTA state (add context vs already in) from item + current locator in `lib/features/vocabulary/application/vocabulary_providers.dart` / `lib/features/vocabulary/presentation/add_to_vocabulary_control.dart`
- [x] T041 [P] [US2] Add ARB key for add-context / already-in-vocabulary labels in `lib/l10n/app_en.arb` (+ locales) if not already added in T033

**Checkpoint**: US2 independently testable — merge/dedup + CTA states correct

---

## Phase 6: User Story 3 - Remove word from lookup control (Priority: P2)

**Goal**: From **Already in Vocabulary**, confirm delete removes the whole item (all contexts + review audits); cancel leaves data; control returns to Add to Vocabulary.

**Independent Test**: Add word (optionally with multiple contexts) → confirm remove → gone; cancel → unchanged.

### Tests for User Story 3

- [x] T042 [P] [US3] Add cascade-delete repository tests in `test/features/vocabulary/vocabulary_repository_delete_test.dart` (contexts + reviews removed)
- [x] T043 [P] [US3] Extend CTA widget tests for confirm/cancel delete in `test/features/lookup/add_to_vocabulary_control_test.dart`

### Implementation for User Story 3

- [x] T044 [US3] Implement `deleteItem` cascade in `lib/features/vocabulary/data/vocabulary_repository.dart` (no sync enqueue)
- [x] T045 [US3] Wire confirm dialog + remove action on Already in Vocabulary in `lib/features/vocabulary/presentation/add_to_vocabulary_control.dart`
- [x] T046 [P] [US3] Add ARB keys for confirm delete / delete action in `lib/l10n/app_en.arb` (+ locales) + `flutter gen-l10n`

**Checkpoint**: US3 independently testable — remove from lookup restores Add state

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Docs, ADR, gates, and end-to-end validation

- [x] T047 [P] Write ADR-0052 local-first vocabulary Drift schema (no sync yet) in `docs/decisions/0052-vocabulary-local-first-schema.md` and index in `docs/decisions/README.md`
- [x] T048 [P] Update P0 status/checkboxes in `docs/features/vocabulary.md` for foundation behavior landed
- [x] T049 Confirm lookup multilang catalog tests still pass (`test/features/lookup/` language catalog/picker coverage) — no ADR-0042 regression
- [x] T050 Run quickstart automated commands: `dart run build_runner build`, `flutter analyze`, targeted `flutter test` paths from [quickstart.md](./quickstart.md)
- [x] T051 Run `bash .github/scripts/validate_ci_gates.sh --fix` (format + codegen drift + analyze/test as scripted)
- [ ] T052 Manual smoke: add / add-context / duplicate / delete during playback per [quickstart.md](./quickstart.md); note SC-007 responsiveness in PR

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** all user stories
- **US4 (Phase 3)**: Depends on Foundational — identity/SRS before capture defaults
- **US1 (Phase 4)**: Depends on US4 (normalize/ids/SRS defaults) — 🎯 user-facing MVP with US4
- **US2 (Phase 5)**: Depends on US1 `addWithContext` create path (extends merge/dedup + CTA)
- **US3 (Phase 6)**: Depends on US1/US2 persistence (needs items to delete); can start after US1 if only single-context delete is tested first
- **Polish (Phase 7)**: Depends on all desired stories complete

### User Story Dependencies

- **User Story 4 (P1)**: After Foundational — no UI dependency
- **User Story 1 (P1)**: After US4 domain helpers
- **User Story 2 (P1)**: After US1 create path
- **User Story 3 (P2)**: After US1 (ideally after US2 for multi-context cascade)

### Within Each User Story

- Tests marked [P] can be written to fail first, then implementation tasks
- Domain/helpers before repository before providers before UI
- Story complete before moving to next priority when staffing is serial

### Parallel Opportunities

- Phase 1: T002 parallel with T001/T003 sequencing as needed
- Phase 2: T004–T007, T009–T011 parallel after table files exist; T005–T007 parallel
- Phase 3 (US4): T015–T018 tests parallel; T019–T022 implementation parallel
- Phase 4 (US1): T025–T027 tests parallel; T033 ARB parallel with T028–T029
- Phase 5–6: test tasks [P] parallel within story
- Phase 7: T047–T048 docs parallel

---

## Parallel Example: User Story 4

```bash
# Tests in parallel:
Task: "Extend enjoy_ids_test.dart for vocabulary v5 helpers"
Task: "Add vocabulary_normalize_test.dart + vocabulary_locator_json_test.dart"
Task: "Port SRS fixtures to vocabulary_srs_test.dart"
Task: "Add vocabulary_repository_srs_test.dart for mark/undo"

# Domain helpers in parallel (after models exist):
Task: "normalizeWord in vocabulary_normalize.dart"
Task: "stableLocatorJson in vocabulary_locator_json.dart"
Task: "enjoyVocabulary*Id in enjoy_ids.dart"
Task: "calculateNextReview in vocabulary_srs.dart"
```

## Parallel Example: User Story 1

```bash
# After US4:
Task: "media_vocabulary_context_builder_test.dart"
Task: "vocabulary_repository_add_test.dart (new item)"
Task: "add_to_vocabulary_control_test.dart (add busy)"
```

---

## Implementation Strategy

### MVP First (US4 domain + US1 capture)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (schema/DAOs)
3. Complete Phase 3: User Story 4 (identity/SRS)
4. Complete Phase 4: User Story 1 (lookup add)
5. **STOP and VALIDATE**: Unit/repo/widget tests + manual add during playback
6. Demo: save a word from transcript lookup

### Incremental Delivery

1. Setup + Foundational → persistence ready
2. US4 → SRS/identity contract green
3. US1 → MVP capture
4. US2 → context merge/dedup
5. US3 → remove escape hatch
6. Polish → ADR-0052, feature doc, CI gates

### Parallel Team Strategy

1. Team completes Setup + Foundational together
2. Dev A: US4 (domain + SRS tests)
3. After US4: Dev A continues US1; Dev B prepares US2/US3 tests against repository API
4. Integrate CTA states once US1 control exists

---

## Notes

- Do **not** extend `SyncEntityType` or enqueue vocabulary in this feature
- Do **not** ship vocabulary shell page, flashcards, Anki, or ebook add UI
- Keep string-only `buildVocabularyContext` for AI; structured builder is a sibling
- Commit regenerated `*.g.dart` after Drift/Riverpod codegen
- Suggested MVP scope: **US4 + US1** (domain contract + first user-visible value)
