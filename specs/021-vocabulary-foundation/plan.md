# Implementation Plan: Vocabulary Foundation

**Branch**: `021-vocabulary-foundation` | **Date**: 2026-07-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/021-vocabulary-foundation/spec.md`

**Parent contract**: [docs/features/vocabulary.md](../../docs/features/vocabulary.md) P0

## Summary

Ship the **local-first vocabulary foundation**: deterministic word/context identity (Enjoy UUID v5 parity), Unicode-safe normalization, Drift tables for items/contexts/review audits, pure SM-2-variant SRS + due/undo contracts matching Enjoy web, atomic add-with-context / cascade delete, a media context builder that returns text + locator (not string-only), and an **Add to Vocabulary** CTA on the existing dictionary lookup sheet (media contexts only). No vocabulary shell page, flashcard UI, cloud sync, Anki export, or ebook add in this phase.

## Technical Context

**Language/Version**: Dart `^3.12.0`, Flutter stable (3.x), Drift `^2.31.0`, Riverpod `^3.3.1`, `package:uuid` (existing).

**Primary Dependencies**: Existing Drift `AppDatabase`, Riverpod, lookup sheet (`dictionary_lookup_sheet`, `LookupRequest`), `enjoyUuidNamespaceUrl` / id helpers, transcript lines + echo state, native language preference providers. No new third-party packages. No `media_kit` `Player()` outside `PlayerController`. No vocabulary sync enqueue yet.

**Storage**: New Drift tables `vocabulary_items`, `vocabulary_contexts`, `vocabulary_reviews` under `lib/data/db/tables/`; DAOs; schema bump **14 → 15**. JSON text columns for `explanation` and `locator` (encode/decode like transcript timeline / AI cache). Sync bookkeeping columns present but unused by sync engine in this phase.

**Testing**: Pure unit tests for normalize, ids, SRS, due predicate; DAO/repository tests for add-with-context, duplicate no-op, cascade delete, mark-reviewed + undo; widget test for lookup CTA states; port fixtures from Enjoy web `vocabulary-srs.test.ts` and vocabulary repository tests where practical. `dart run build_runner build` after Drift/Riverpod annotations. Manual smoke: add during playback (see [quickstart.md](./quickstart.md)).

**Target Platform**: Android, iOS, macOS, Windows, Linux (no Flutter web).

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals**:

- Single add / existence check / delete from lookup completes without stalling playback/transcript UI for more than ~1s on a typical personal library (SC-007 / QR-004).
- Existence and duplicate checks use indexed lookups by id / `(word, language)` / item+source — not full-table scans of unbounded JSON.
- No network required for capture; AI dictionary fill not on the add hot path.

**Constraints**:

- Behavioral parity with Enjoy web for normalize, UUID v5 name strings, add-with-context, SRS formulas, due predicate, undo pre-image (source: `~/dev/enjoy/apps/web` vocabulary modules cited in feature doc).
- Local-first only; do **not** extend `SyncEntityType` or enqueue vocabulary in this phase (IDs/schema stay API-compatible).
- One Unicode-safe normalizer everywhere (avoid web’s ASCII `\w` existence-check bug).
- Lookup language catalogs unchanged (ADR-0042).
- Ebook add UI out of scope; ebook locator shape allowed in schema.
- Feature-first layout: `lib/features/vocabulary/{application,data,domain,presentation}`; shared ids in `lib/core/ids`; Drift in `lib/data/db`.
- No `print()`; logging via `logNamed`.

**Scale/Scope**: Personal vocabulary (hundreds–low thousands of items). One CTA surface (lookup sheet). Foundation only — later specs for review UI, sync, Anki.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- ✅ New code under `lib/features/vocabulary/{domain,data,application,presentation}` plus Drift tables/DAOs in `lib/data/db` and id helpers in `lib/core/ids`.
- ✅ Domain (models, normalize, SRS, id name builders) stays UI-free.
- ✅ Persistence through Drift DAOs; multi-row writes via `AppDatabase.transaction` in repository.
- ✅ Riverpod notifiers/providers for existence state + add/remove actions; no new mutable global singleton.
- ✅ Lookup sheet may import vocabulary **application** APIs (documented seam); avoid deep feature↔feature coupling into vocabulary presentation internals.
- ✅ No new `Player()`; no `print()`.

### II. Testing Defines the Contract

- ✅ Unit: `normalizeWord`, `enjoyVocabularyItemId` / `enjoyVocabularyContextId`, `calculateNextReview`, due predicate, stable locator JSON.
- ✅ Repository/DAO: add new item, add second context, exact duplicate no-op, cascade delete, mark reviewed + undo.
- ✅ Widget: lookup CTA states (add / add context / already in / busy) + confirm delete.
- ✅ `build_runner` after schema 15 + any `@Riverpod` providers.
- ✅ Manual: add during live playback (quickstart) — cannot fully automate media session in unit tests.

### III. User Experience Consistency

- ✅ ARB keys for add-button states and delete confirm (subset of vocabulary string inventory).
- ✅ Tappable control uses existing Enjoy primitives on the lookup sheet.
- ✅ Docs: update `docs/features/vocabulary.md` P0 checkboxes/status; new ADR-0052 local-first schema.

### IV. Performance Is a Requirement

- ✅ Indexed lookups; atomic short transactions; no AI on add path.
- ✅ Evidence: unit/repo tests + manual timing note in PR if add feels slow.

### V. Documentation and Traceability

- ✅ ADR-0052: Drift vocabulary schema + local-first (no sync yet); does not rewrite ADR-0010.
- ✅ `docs/features/vocabulary.md` updated when behavior lands.
- ✅ `docs/decisions/README.md` index entry.
- ✅ No constitution exceptions.

**Post-design re-check**: Gates still pass after [research.md](./research.md), [data-model.md](./data-model.md), and contracts. Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/021-vocabulary-foundation/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── vocabulary-identity-srs.md
│   ├── vocabulary-persistence.md
│   └── lookup-add-vocabulary-cta.md
└── tasks.md                 # /speckit-tasks (not this command)
```

### Source Code (repository root)

```text
lib/core/ids/
└── enjoy_ids.dart                    # + enjoyVocabularyItemId / enjoyVocabularyContextId

lib/data/db/
├── app_database.dart                 # schemaVersion 15; register tables/DAOs
├── tables/
│   ├── vocabulary_items.dart
│   ├── vocabulary_contexts.dart
│   └── vocabulary_reviews.dart
└── daos/
    ├── vocabulary_item_dao.dart
    ├── vocabulary_context_dao.dart
    └── vocabulary_review_dao.dart

lib/features/vocabulary/
├── domain/
│   ├── vocabulary_models.dart        # item, context, review, locators, status, rating
│   ├── vocabulary_normalize.dart
│   ├── vocabulary_srs.dart           # calculateNextReview, due predicate, constants
│   └── vocabulary_locator_json.dart  # stable key-sorted JSON for id + persist
├── data/
│   └── vocabulary_repository.dart    # addWithContext, deleteItem, markReviewed, undo
├── application/
│   ├── vocabulary_providers.dart     # by-word existence / actions (Riverpod)
│   └── media_vocabulary_context_builder.dart  # {text, sourceType, sourceId, locator}
└── presentation/
    └── add_to_vocabulary_control.dart  # CTA widget for lookup sheet

lib/features/lookup/
├── domain/lookup_request.dart        # + media linkage fields for context persist
├── application/transcript_lookup_open.dart  # pass media id / source type
└── presentation/dictionary_lookup_sheet.dart  # mount CTA

test/core/ids/enjoy_ids_test.dart
test/features/vocabulary/
test/features/lookup/                 # CTA widget + media context builder tests

docs/features/vocabulary.md
docs/decisions/0052-vocabulary-local-first-schema.md
docs/decisions/README.md
lib/l10n/*.arb                        # add/remove CTA strings
```

**Structure Decision**: New `vocabulary` feature module for domain/application/data/presentation; Drift tables live in shared `lib/data/db` (ADR-0002). Id helpers stay in `lib/core/ids` next to other Enjoy v5 generators. Lookup only gains a thin CTA + request fields needed to build a persistable media context. Keep string-only `buildVocabularyContext` for AI contextual translation; add a sibling structured builder for vocabulary persistence (research D3).

## Complexity Tracking

> None — no constitution violations.
