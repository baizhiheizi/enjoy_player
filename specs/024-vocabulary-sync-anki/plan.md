# Implementation Plan: Vocabulary Sync & Anki Export

**Branch**: `main` (spec directory `024-vocabulary-sync-anki` is independent of git branch naming; create `024-vocabulary-sync-anki` when implementing) | **Date**: 2026-07-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/024-vocabulary-sync-anki/spec.md`

**Parent contract**: [docs/features/vocabulary.md](../../docs/features/vocabulary.md) **P3** (Sync) + **P4** (Anki) · Prerequisites: [021](../021-vocabulary-foundation/spec.md)–[023](../023-vocabulary-context-richness/spec.md) (local vocab + review + explanation write-through shipping)

## Summary

Finish the Flutter vocabulary port: (1) **Pro-gated Anki CSV export** from All Words with web-parity filters and Front/Back/Tags BOM CSV; (2) **cloud sync** for vocabulary items and contexts via existing sync queue/engine + new `VocabularyApi`, with SRS-preserving item merge and never-synced review audits. Record vocabulary sync in **new ADR-0054** (do not rewrite ADR-0010 / ADR-0013). Prefer implementing **Anki first** (solo feature-complete), then sync (multi-device).

## Technical Context

**Language/Version**: Dart `^3.12.0`, Flutter stable (3.x), Drift `^2.31.0`, Riverpod `^3.3.1`, go_router (existing).

**Primary Dependencies**: Existing `VocabularyRepository` / DAOs / review UI; `lib/features/sync/` (`SyncEntityType`, queue, engine, upload/download); `ApiClient` + `RestApi` (`package:http`); `currentTierProvider` / subscription upgrade routes; save/share via `share_plus` + `file_picker` (same pattern as `diagnostic_export_flow.dart` / `practice_poster_export.dart`). No new media player. Optional: lightweight markdown→HTML helper for Anki backs (no need to pull unified/remark).

**Storage**: Existing Drift schema **15** — `vocabulary_items` / `vocabulary_contexts` already have `syncStatus` + `serverUpdatedAt`; `vocabulary_reviews` stays local-only. Extend `sync_queue` usage with new entity types; add `SettingsKeys` cursors for vocabulary download. **No schema bump** expected unless wire payloads reveal a missing column (unlikely).

**Testing**: Unit tests for Anki CSV builder (BOM, escaping, Front/Back/Tags, sparse cache); Pro gate widget/notifier tests; sync serializers + `resolveVocabularyItemConflict` parity with web cases; enqueue on add/update/delete/review; download merge with fake API. Manual: Pro export save/share on one desktop + one mobile; two-device or simulated remote sync. `dart run build_runner build` when `@Riverpod` / Drift annotations change.

**Target Platform**: Android, iOS, macOS, Windows, Linux (no Flutter web).

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals**:

- Anki CSV for typical personal word books (hundreds of items): generate without multi-second UI freeze; show progress for larger sets (web parity).
- Sync batch drain: reuse engine batch size 10 / retry backoff; vocabulary pull paged by `updatedAfter` + `limit` (default 50).
- Do not block review/list UI on sync drain (fire-and-forget / background, same as media).

**Constraints**:

- Pro gates **only** Anki export; core vocab stays free.
- Review audits **never** upload/download.
- Item merge ≠ plain LWW — SRS-preserving conflict (web `resolveVocabularyItemConflict`).
- Vocabulary **does** pull on signed-in sync (word book is not a local-file library); document as intentional exception to ADR-0013’s media no-auto-mirror policy.
- Feature-first: Anki builder under `lib/features/vocabulary/`; sync extensions under `lib/features/sync/` + thin `VocabularyApi` in `lib/data/api/`; repository enqueues via `SyncEnqueueFn`.
- No `print()`; logging via `logNamed`.
- Out of scope: home due widget, tags UI, batch import, Notes content, ebook add.

**Scale/Scope**: Personal vocabulary (tens–thousands of items). ~15–25 new ARB keys for export/Pro/upgrade/empty export/sync errors. New ADR-0054. Update `docs/features/vocabulary.md` + `docs/features/sync.md`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- ✅ Anki under `lib/features/vocabulary/{domain,application,presentation}`; sync entity wiring under `lib/features/sync/` + `lib/data/api/services/vocabulary_api.dart`.
- ✅ Domain CSV builder and conflict resolver stay UI-free; Drift via DAOs/repository.
- ✅ Riverpod for export flow + sync providers; no new mutable global singletons.
- ✅ No `print()`; no new `media_kit` `Player()`.

### II. Testing Defines the Contract

- ✅ Unit: CSV shape/BOM/tags/escaping; conflict resolver cases; prepareForSync maps.
- ✅ Repo/notifier: enqueue on mutations; Pro gate blocks CSV for Free.
- ✅ Widget: Export entry + filter dialog + Pro upgrade path.
- ✅ Manual: save/share platforms; multi-device sync (quickstart).
- ✅ `build_runner` when providers/API wiring added.

### III. User Experience Consistency

- ✅ ARB: `exportToAnki`, `proRequired`, `proRequiredDescription`, `upgradeToPro`, export filters, empty export, sparse-cache note as needed.
- ✅ Enjoy dialogs/buttons; upgrade → `/subscription`.
- ✅ Update `docs/features/vocabulary.md` P3/P4 + sync.md scope line.

### IV. Performance Is a Requirement

- ✅ CSV generation for ordinary sizes on isolate or chunked progress if needed; sync uses existing batch/cursor patterns.
- ✅ Evidence: unit timing optional; quickstart notes for large export.

### V. Documentation and Traceability

- ✅ **New ADR-0054** — vocabulary cloud sync + conflict policy (extends ADR-0010; clarifies pull vs ADR-0013 media policy).
- ✅ Feature docs: vocabulary.md P3/P4 checkboxes; sync.md admit vocabulary entities.
- ✅ No constitution exceptions.

**Post-design re-check**: Gates still pass after [research.md](./research.md), [data-model.md](./data-model.md), and contracts. Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/024-vocabulary-sync-anki/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── vocabulary-anki-export.md
│   ├── vocabulary-sync.md
│   └── vocabulary-api.md
└── tasks.md                 # /speckit-tasks (not this command)
```

### Source Code (repository root)

```text
lib/features/vocabulary/
├── domain/
│   ├── vocabulary_models.dart                 # existing
│   ├── vocabulary_explanation_codec.dart      # existing — Anki Back decode
│   ├── vocabulary_anki_csv.dart               # NEW — BOM CSV Front/Back/Tags builder
│   └── vocabulary_item_conflict.dart          # NEW (or under sync) — resolveVocabularyItemConflict
├── data/
│   └── vocabulary_repository.dart             # UPDATE — syncEnqueue on mutations; listForExport
├── application/
│   ├── vocabulary_providers.dart              # UPDATE
│   └── vocabulary_anki_export.dart            # NEW — filter + Pro check + save/share orchestration
└── presentation/
    ├── vocabulary_word_list.dart              # UPDATE — Export entry
    └── vocabulary_anki_export_dialog.dart     # NEW — filters + progress + Pro gate UI

lib/features/sync/
├── domain/sync_types.dart                     # UPDATE — vocabularyItem, vocabularyContext
├── application/queue_for_sync.dart            # UPDATE — prepare payloads
├── application/sync_engine.dart               # UPDATE — upload/delete cases; optional download hook
├── data/sync_serializers.dart                 # UPDATE — prepare/fromServer + item conflict + context LWW
├── data/sync_upload_service.dart              # UPDATE — VocabularyApi calls
└── data/sync_download_service.dart            # UPDATE — pull items/contexts with cursors

lib/data/api/services/vocabulary_api.dart      # NEW — /api/v1/mine/vocabulary_*
lib/data/db/settings_keys.dart                 # UPDATE — sync.cursor.vocabulary_item / _context

lib/features/subscription/…                    # REUSE — currentTierProvider, /subscription
lib/core/diagnostics/diagnostic_export_flow.dart  # REUSE pattern — share vs FilePicker.saveFile

lib/l10n/app_*.arb                             # UPDATE — export / Pro / sync strings

test/features/vocabulary/
├── vocabulary_anki_csv_test.dart
├── vocabulary_anki_export_gate_test.dart
└── …
test/features/sync/
├── vocabulary_item_conflict_test.dart
└── vocabulary_sync_enqueue_test.dart

docs/features/vocabulary.md                    # UPDATE — P3/P4
docs/features/sync.md                          # UPDATE — entity list
docs/decisions/0054-vocabulary-cloud-sync.md   # NEW
```

**Structure Decision**: Keep Anki CSV pure in vocabulary domain; reuse diagnostic/poster export UX for bytes. Extend sync feature for entity types + API (same as audio/video). Put SRS conflict resolver in vocabulary domain (or sync serializers calling into it) so tests can port web cases without Flutter UI.

## Complexity Tracking

> No constitution violations.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| — | — | — |

## Implementation Phases (for `/speckit-tasks`)

### Phase A — Anki export (P4)

1. Domain `exportVocabularyToAnkiCsv` (BOM, escape, Front/Back/Tags, markdown→HTML simple).
2. Export filter model (search + status + language) matching web dialog.
3. Application flow: Pro check → load items+contexts → CSV → share/save.
4. All Words Export CTA + dialog; Free → Pro-required + upgrade.
5. Unit/widget tests; ARB keys; feature doc P4.

### Phase B — Sync foundation (P3)

1. Write ADR-0054; extend `SyncEntityType` + wire names.
2. `VocabularyApi` + upload/download service methods + settings cursors.
3. Serializers + `resolveVocabularyItemConflict` + context LWW.
4. Repository: enqueue create/update/delete for items/contexts; review → item update only; never queue reviews.
5. Engine cases; pull vocabulary on signed-in fullSync (or dedicated vocab sync step).
6. Conflict/enqueue/API tests; update sync.md + vocabulary.md P3.

### Phase C — Polish

1. Sync failure/retry UX (reuse existing queue error patterns where shown).
2. Export limitation copy for sparse AI cache.
3. Quickstart manual pass; CI gates.

## Verification Commands

```bash
dart run build_runner build   # if @Riverpod / Drift annotations changed
flutter analyze
flutter test test/features/vocabulary/ test/features/sync/
bash .github/scripts/validate_ci_gates.sh --fix
```
