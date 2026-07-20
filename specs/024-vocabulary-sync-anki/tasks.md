# Tasks: Vocabulary Sync & Anki Export

**Input**: Design documents from `specs/024-vocabulary-sync-anki/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are required for changed behavior (constitution + plan QR-002). Manual save/share + multi-device sync per [quickstart.md](./quickstart.md).

**Organization**: Tasks are grouped by user story. Plan order: **Anki (US1) first**, then **sync (US2)**, then limits UX (US3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Vocabulary**: `lib/features/vocabulary/{application,data,domain,presentation}/`
- **Sync**: `lib/features/sync/`
- **API**: `lib/data/api/services/`
- **Settings**: `lib/data/db/settings_keys.dart`
- **Tests**: `test/features/vocabulary/`, `test/features/sync/`
- **Feature docs**: `docs/features/vocabulary.md`, `docs/features/sync.md`
- **ADRs**: `docs/decisions/0054-vocabulary-cloud-sync.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm touch points and doc/l10n/ADR targets before code changes

- [x] T001 Confirm affected paths from plan against current tree: `lib/features/vocabulary/` (esp. `vocabulary_word_list.dart`, `vocabulary_repository.dart`), `lib/features/sync/` (`sync_types.dart`, `queue_for_sync.dart`, `sync_engine.dart`, `sync_upload_service.dart`, `sync_download_service.dart`, `sync_serializers.dart`, `sync_providers.dart`), `lib/data/api/services/audio_api.dart` (template for new API), `lib/core/diagnostics/diagnostic_export_flow.dart`, `lib/features/subscription/application/current_tier_provider.dart`
- [x] T002 [P] Identify doc/ADR/l10n targets: `docs/features/vocabulary.md` (P3/P4), `docs/features/sync.md`, `docs/decisions/0054-vocabulary-cloud-sync.md`, `docs/decisions/README.md`, `lib/l10n/app_en.arb` (+ `app_zh.arb` / `app_zh_CN.arb`)
- [x] T003 [P] Confirm no Drift schema bump needed (schema 15 already has `syncStatus` / `serverUpdatedAt` on items/contexts) per [data-model.md](./data-model.md)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared localization and repository read helpers that Anki + limits UX need; sync ADR deferred to US2

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Add Anki/export/Pro ARB keys (`exportToAnki`, `proRequired`, `proRequiredDescription`, `upgradeToPro`, export filter labels, `noItemsToExport`, sparse-cache / export-limitation note as needed) to `lib/l10n/app_en.arb` and mirror in `app_zh.arb` / `app_zh_CN.arb`; run `flutter gen-l10n` if required
- [x] T005 Extend `VocabularyRepository` with export listing helpers (e.g. load filtered items + contexts map, or thin methods used by export flow) in `lib/features/vocabulary/data/vocabulary_repository.dart` without enqueue yet
- [x] T006 [P] Add `VocabularyAnkiExportFilters` (search / status / language) domain type in `lib/features/vocabulary/domain/vocabulary_anki_export_filters.dart` per [contracts/vocabulary-anki-export.md](./contracts/vocabulary-anki-export.md)

**Checkpoint**: ARB + export filter model + repo read helpers ready — US1 can start

---

## Phase 3: User Story 1 - Export vocabulary to Anki as Pro (Priority: P1) 🎯 MVP

**Goal**: Pro learners export filtered vocabulary to Anki Basic CSV (Front/Back/Tags, UTF-8 BOM) and save/share the file; Free users see upgrade path without getting a CSV.

**Independent Test**: Seed items + contexts (+ optional explanations) → Pro Export with filters → CSV validates; Free path shows Pro-required and produces no file ([quickstart](./quickstart.md) §1–3 / SC-001 / SC-002).

### Tests for User Story 1

- [x] T007 [P] [US1] Unit test Anki CSV builder (BOM, escaping, Tags, Front/Back merge, sparse cache omits missing sections) in `test/features/vocabulary/vocabulary_anki_csv_test.dart`
- [x] T008 [P] [US1] Unit/widget test Pro gate blocks CSV and Free shows upgrade affordance in `test/features/vocabulary/vocabulary_anki_export_gate_test.dart`
- [x] T009 [P] [US1] Widget test export dialog filters reduce selectable set / empty export message in `test/features/vocabulary/presentation/vocabulary_anki_export_dialog_test.dart`

### Implementation for User Story 1

- [x] T010 [P] [US1] Implement pure `exportVocabularyToAnkiCsv` (BOM, escape, Front/Back/Tags, simple markdown→HTML) in `lib/features/vocabulary/domain/vocabulary_anki_csv.dart` per [contracts/vocabulary-anki-export.md](./contracts/vocabulary-anki-export.md) and web `export-csv.ts`
- [x] T011 [P] [US1] Implement save/share helper for CSV bytes (mobile SharePlus / desktop FilePicker.saveFile, mirror `diagnostic_export_flow.dart`) in `lib/features/vocabulary/application/vocabulary_anki_export_io.dart`
- [x] T012 [US1] Implement export orchestration (read `currentTierProvider` / active Pro, apply filters, load contexts, build CSV, progress callbacks, save/share) in `lib/features/vocabulary/application/vocabulary_anki_export.dart`
- [x] T013 [US1] Implement `VocabularyAnkiExportDialog` (search/status/language filters, progress, empty state, Pro vs Free branches) in `lib/features/vocabulary/presentation/vocabulary_anki_export_dialog.dart`
- [x] T014 [US1] Wire Export to Anki entry on All Words in `lib/features/vocabulary/presentation/vocabulary_word_list.dart` (and AppBar/action if needed in `vocabulary_screen.dart`)
- [x] T015 [US1] Free path: show Pro-required copy + navigate to `/subscription`; ensure CSV generation is not offered as a successful download
- [x] T016 [US1] Verify export stays responsive for a typical seeded book; note evidence in PR or quickstart if large-book progress is used (plan QR-004)

**Checkpoint**: US1 independently testable — Anki export works without any sync changes

---

## Phase 4: User Story 2 - Keep vocabulary on another device via sync (Priority: P1)

**Goal**: Signed-in learners sync vocabulary items and contexts (upload + download) with SRS-preserving item merge; review audits never leave the device.

**Independent Test**: Simulated remote or two stores — add/review on A, pull on B; conflict resolver keeps newer SRS; no review rows in payloads ([quickstart](./quickstart.md) §4–7 / SC-003 / SC-004).

**Depends on**: Local vocabulary mutations already exist (021–023). Does **not** depend on Anki UI, but may share repo enqueue hooks after US1 lands.

### Tests for User Story 2

- [x] T017 [P] [US2] Unit test `resolveVocabularyItemConflict` (web parity cases) in `test/features/sync/vocabulary_item_conflict_test.dart` or `test/features/vocabulary/vocabulary_item_conflict_test.dart`
- [x] T018 [P] [US2] Unit test prepareForSync / fromServer maps for item + context in `test/features/sync/vocabulary_sync_serializers_test.dart`
- [x] T019 [P] [US2] Unit test repository enqueue on add/update/delete/review and **never** on review-audit rows in `test/features/vocabulary/vocabulary_sync_enqueue_test.dart`
- [x] T020 [P] [US2] Unit test `VocabularyApi` paths/envelopes with fake `http.Client` in `test/data/api/vocabulary_api_test.dart`

### Implementation for User Story 2

- [x] T021 [P] [US2] Write ADR-0054 vocabulary cloud sync (SRS conflict, never sync reviews, auto-pull vs ADR-0013 media policy) in `docs/decisions/0054-vocabulary-cloud-sync.md` and index in `docs/decisions/README.md`
- [x] T022 [P] [US2] Add `vocabularyItem` / `vocabularyContext` to `SyncEntityType` + wire strings `vocabulary_item` / `vocabulary_context` in `lib/features/sync/domain/sync_types.dart`
- [x] T023 [P] [US2] Add cursor keys `sync.cursor.vocabulary_item` / `sync.cursor.vocabulary_context` in `lib/data/db/settings_keys.dart`
- [x] T024 [P] [US2] Implement `VocabularyApi` (`RestApi`) for list/get/upload/delete items + contexts in `lib/data/api/services/vocabulary_api.dart` per [contracts/vocabulary-api.md](./contracts/vocabulary-api.md)
- [x] T025 [P] [US2] Implement `resolveVocabularyItemConflict` in `lib/features/vocabulary/domain/vocabulary_item_conflict.dart` (or sync serializers calling into it) per [research.md](./research.md) §6
- [x] T026 [US2] Add `prepareForSyncVocabularyItemMap` / `prepareForSyncVocabularyContextMap` + fromServer + context LWW merge in `lib/features/sync/data/sync_serializers.dart`
- [x] T027 [US2] Extend `enqueuePendingSync` cases for vocabulary entity types in `lib/features/sync/application/queue_for_sync.dart`
- [x] T028 [US2] Extend `SyncUploadService` create/update/delete for vocabulary via `VocabularyApi` in `lib/features/sync/data/sync_upload_service.dart`
- [x] T029 [US2] Extend `SyncDownloadService` (or equivalent) to page-pull items/contexts with cursors and conflict merge in `lib/features/sync/data/sync_download_service.dart`
- [x] T030 [US2] Wire vocabulary pull into signed-in `fullSync` / sync controller path in `lib/features/sync/application/sync_engine.dart` and `lib/features/sync/application/sync_providers.dart` (inject `VocabularyApi`; run `dart run build_runner build` if providers change)
- [x] T031 [US2] Inject `SyncEnqueueFn` into `VocabularyRepository` and enqueue on addWithContext / explanation updates / markReviewed / undo / deleteItem; never enqueue `vocabulary_reviews` in `lib/features/vocabulary/data/vocabulary_repository.dart` and `lib/features/vocabulary/application/vocabulary_providers.dart`
- [x] T032 [US2] Update `docs/features/sync.md` scope to include vocabulary items/contexts (reviews excluded) and point to ADR-0054

**Checkpoint**: US2 independently testable — sync works even if Anki UI is disabled; reviews never uploaded

---

## Phase 5: User Story 3 - Understand sync and export limits (Priority: P2)

**Goal**: Clear Free/Pro export messaging, sync pending/failure resilience messaging where the product surfaces queue errors, and export UI note when rich Back sides need cached explanations.

**Independent Test**: Free export CTA, forced sync failure then retry, export without AI cache — user-visible copy matches contracts ([quickstart](./quickstart.md) §2–3, §7 / SC-002 / SC-005).

**Depends on**: US1 dialog/gate and US2 sync path exist to attach messaging.

### Tests for User Story 3

- [x] T033 [P] [US3] Widget/unit test Free export dialog copy + upgrade navigation in `test/features/vocabulary/presentation/vocabulary_anki_export_dialog_test.dart` (extend US1 tests)
- [x] T034 [P] [US3] Test or documented assertion that pending vocabulary queue rows survive failed drain and retry in `test/features/sync/vocabulary_sync_retry_test.dart` (or extend existing sync queue tests)

### Implementation for User Story 3

- [x] T035 [US3] Ensure export dialog documents sparse-cache / rich-back limitation (localized) in `lib/features/vocabulary/presentation/vocabulary_anki_export_dialog.dart`
- [x] T036 [US3] Surface sync failure/retry for vocabulary using existing sync queue error patterns (no silent local delete) — wire any vocabulary-specific user messaging in sync/vocabulary presentation only if product already shows queue errors elsewhere; otherwise document manual check in quickstart
- [x] T037 [US3] Optionally add Anki bullet to Pro feature list copy in subscription ARBs / `tier_comparison` only if product wants parity with Pro marketing; keep Pro gate on export regardless

**Checkpoint**: Limits UX clear; Free/Pro and sparse/sync failure paths understandable without support

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Docs, verification gates, feature-complete checklist

- [x] T038 [P] Update `docs/features/vocabulary.md` status + P3/P4 checkboxes + acceptance criteria for Anki and sync
- [x] T039 [P] Run manual scenarios in [quickstart.md](./quickstart.md) (Pro export, Free gate, sparse cache, sync add, conflict if feasible, offline retry)
- [x] T040 Run `dart run build_runner build` if `@Riverpod` / Drift annotations changed; commit generated outputs
- [x] T041 Run `flutter analyze` and fix issues
- [x] T042 Run `flutter test test/features/vocabulary/ test/features/sync/` (and full suite if time)
- [x] T043 Run `bash .github/scripts/validate_ci_gates.sh --fix` before push

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** US1–US3
- **User Story 1 (Phase 3)**: After Foundational — **MVP** (Anki); no sync required
- **User Story 2 (Phase 4)**: After Foundational — can start in parallel with US1 if staffed (different files); repo enqueue (T031) should coordinate if US1 also touches `vocabulary_repository.dart`
- **User Story 3 (Phase 5)**: After US1 + US2 messaging surfaces exist
- **Polish (Phase 6)**: After desired stories complete

### User Story Dependencies

| Story | Priority | Depends on | Independently testable? |
|-------|----------|------------|-------------------------|
| US1 Anki export | P1 MVP | Phase 2 | Yes — without sync |
| US2 Sync | P1 | Phase 2 | Yes — without Anki UI |
| US3 Limits UX | P2 | US1 + US2 | Yes — messaging/copy checks |

### Within Each User Story

- Tests SHOULD be written to fail before implementation where practical
- Domain/API before engine/UI wiring
- Story complete before next priority unless parallel staffing

### Parallel Opportunities

- T002–T003, T004–T006 (marked [P] within phase)
- US1 tests T007–T009 in parallel; T010–T011 in parallel
- US2 tests T017–T020 in parallel; T021–T025 in parallel before serializer/engine chain
- US1 and US2 can proceed in parallel if repository enqueue (T031) is sequenced after both stabilize read paths

---

## Parallel Example: User Story 1

```bash
# Tests in parallel:
Task: "Unit test Anki CSV in test/features/vocabulary/vocabulary_anki_csv_test.dart"
Task: "Pro gate test in test/features/vocabulary/vocabulary_anki_export_gate_test.dart"
Task: "Export dialog widget test in test/features/vocabulary/presentation/vocabulary_anki_export_dialog_test.dart"

# Domain + IO in parallel:
Task: "CSV builder in lib/features/vocabulary/domain/vocabulary_anki_csv.dart"
Task: "Save/share IO in lib/features/vocabulary/application/vocabulary_anki_export_io.dart"
```

## Parallel Example: User Story 2

```bash
# Docs + types + API in parallel:
Task: "ADR-0054 in docs/decisions/0054-vocabulary-cloud-sync.md"
Task: "SyncEntityType in lib/features/sync/domain/sync_types.dart"
Task: "VocabularyApi in lib/data/api/services/vocabulary_api.dart"
Task: "Conflict resolver in lib/features/vocabulary/domain/vocabulary_item_conflict.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 + Phase 2
2. Complete Phase 3 (US1 Anki)
3. **STOP and VALIDATE**: Pro/Free export + CSV contract
4. Demo solo feature-complete vocabulary (minus sync)

### Incremental Delivery

1. Setup + Foundational
2. US1 Anki → validate → optional ship
3. US2 Sync + ADR-0054 → validate merge/enqueue
4. US3 limits copy → polish
5. Phase 6 docs + CI gates → mark P3/P4 done in vocabulary.md

### Parallel Team Strategy

1. Team finishes Setup + Foundational together
2. Dev A: US1 Anki (vocabulary presentation/domain)
3. Dev B: US2 Sync (sync feature + API + ADR) — coordinate `vocabulary_repository.dart` enqueue
4. Either: US3 polish + docs

---

## Notes

- [P] = different files, no incomplete dependencies
- Do not rewrite ADR-0010 / ADR-0013 — extend via ADR-0054
- Reviews never sync; Pro gates only Anki
- Out of scope: home due widget, tags/batch import, Notes content, ebook add
- Commit after each task or logical group; keep tree green (`flutter analyze` / `flutter test`)
