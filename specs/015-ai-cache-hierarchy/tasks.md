---

description: "Task list for AI Result Cache Hierarchy (issue #311)"

---

# Tasks: AI Result Cache Hierarchy

**Input**: Design documents from `/specs/015-ai-cache-hierarchy/`
**Spec**: `specs/015-ai-cache-hierarchy/spec.md` (5 user stories, FR-001..FR-017, SC-001..SC-010)
**Plan**: `specs/015-ai-cache-hierarchy/plan.md` (Constitution Check PASS on all five principles; drift migration v11 → v12)
**Research**: `specs/015-ai-cache-hierarchy/research.md` (R1..R15 resolved)
**Data model**: `specs/015-ai-cache-hierarchy/data-model.md` (new `AiCacheRow` table + `AiCacheDao` + `AiKind` enum + `AiKindPolicy` + `L1Store` + `AiResultCache`)
**Contracts**: `specs/015-ai-cache-hierarchy/contracts/` (cache API, fingerprint, LRU store)
**Quickstart**: `specs/015-ai-cache-hierarchy/quickstart.md` (12 end-to-end validation scenarios)

**Tests**: This change has both automated and (minimal) manual verification. Automated tests cover the cache abstraction (unit), the DAO (against `NativeDatabase.memory()`), the migration (v11 → v12 with data preservation), and the integration via the lookup sheet providers + auto-translate controller. Manual verification covers a cold-restart lookup (1 case, requires device).

**Organization**: Tasks are grouped by phase. Foundational work (LRU store, fingerprint helper, Drift schema bump) is in Phase 1 and is the only work that is blocked behind Setup. The five user stories are implemented in Phases 3-7. Documentation and the ADR are in Phase 8. Verification is in Phase 9.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (e.g. [US1], [US2], etc.)
- Include exact file paths in descriptions

## Path Conventions

- **Cache primitive**: `lib/core/cache/lru_store.dart`, `lib/features/ai/domain/ai_kind.dart`, `lib/features/ai/application/ai_cache_fingerprint.dart`, `lib/features/ai/application/ai_kind_policies.dart`
- **Cache class**: `lib/features/ai/application/ai_result_cache.dart`
- **Drift table + DAO**: `lib/data/db/tables/ai_cache.dart`, `lib/data/db/app_database.dart`
- **Call-site edits**: `lib/features/lookup/application/lookup_section_providers.dart`, `lib/features/lookup/application/lookup_sheet_result_cache.dart`, `lib/features/lookup/presentation/sections/contextual_translation_lookup_section.dart`, `lib/features/transcript/data/transcript_repository.dart`, `lib/features/transcript/domain/auto_translate.dart`
- **Tests**: `test/core/cache/`, `test/features/ai/`, `test/features/lookup/`, `test/data/db/`, `test/features/transcript/`
- **Docs**: `docs/features/dictionary-lookup.md`, `docs/features/transcript.md`, `docs/features/ai.md`
- **ADR**: `docs/decisions/0045-ai-result-cache-hierarchy.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization for the cache hierarchy. No new behavior yet — just the LRU primitive, the fingerprint helper, the Drift schema bump, and the new DAO.

- [ ] T001 [P] Create `lib/core/cache/lru_store.dart` with the `L1Store<K, V>` class per the contract in `contracts/lru-store.md` (hand-rolled LRU + TTL using `LinkedHashMap`, capacity and TTL via constructor)
- [ ] T002 [P] Create `test/core/cache/lru_store_test.dart` covering: `peek_returns_cached_value`, `peek_returns_null_on_miss`, `lru_evicts_oldest_on_overflow`, `peek_returns_null_after_ttl`, `peek_updates_lru_position`, `clear_drops_all_entries`, `invalidate_removes_entry`, `size_returns_count`, `capacity_must_be_positive` (assertion), `ttl_must_be_non_negative` (assertion)
- [ ] T003 [P] Create `lib/features/ai/domain/ai_kind.dart` with the `AiKind` enum (`translation`, `dictionary`, `contextualTranslation`, `autoTranslateLine`) and the `wire` getter
- [ ] T004 [P] Create `lib/features/ai/application/ai_cache_fingerprint.dart` with `AiCacheFingerprint.fingerprint({required String kind, required Map<String, Object?> payload})` per the contract in `contracts/ai-cache-fingerprint.md` (canonical encoding `<kind>|<sorted kvs joined by '|'>`, SHA-256, first 32 hex chars)
- [ ] T005 [P] Create `test/features/ai/ai_cache_fingerprint_test.dart` covering: `fingerprint_is_deterministic`, `fingerprint_length_is_32`, `fingerprint_matches_hex_pattern`, `fingerprint_discriminates_kind`, `fingerprint_is_order_independent_on_payload_keys`, `fingerprint_encodes_null_as_string_null`, `fingerprint_throws_on_unsupported_value_type`, `fingerprint_throws_on_empty_kind`
- [ ] T006 [P] Create `lib/features/ai/application/ai_kind_policies.dart` with the `AiKindPolicy` class and the `defaultPolicies` map (per `data-model.md` defaults: translation 30 min/4096/30 d, dictionary 30 min/4096/30 d, contextualTranslation 30 min/2048/14 d, autoTranslateLine ∞/8192/∞)
- [ ] T007 [P] Create `lib/data/db/tables/ai_cache.dart` with the Drift `@DataClassName('AiCacheRow') class AiCache extends Table` (kind TEXT, key TEXT, payloadJson TEXT, updatedAt INTEGER; PK `(kind, key)`)
- [ ] T008 Add `AiCache` to the `@DriftDatabase(tables: [...])` list and `AiCacheDao` to the `@DriftDatabase(daos: [...])` list in `lib/data/db/app_database.dart`; bump `schemaVersion` from 11 to 12 and add the migration step in `_runMigrations` (idempotent `CREATE TABLE IF NOT EXISTS` + `CREATE INDEX IF NOT EXISTS`)
- [ ] T009 Implement `AiCacheDao` in `lib/data/db/app_database.dart` (or split into `lib/data/db/ai_cache_dao.dart`) per the contract in `data-model.md` (read, upsert, delete, evictOldestExcept, pruneOlderThan, deleteForKind, readAllForKind; all swallow Drift exceptions and log via `logNamed('ai_cache')`)
- [ ] T010 [P] Create `test/data/db/ai_cache_dao_test.dart` against `NativeDatabase.memory()` covering: `read_returns_row`, `read_returns_null_on_miss`, `upsert_inserts_and_replaces`, `delete_removes_row`, `evict_oldest_except_keeps_recent`, `prune_older_than_removes_old`, `delete_for_kind_drops_all_rows`, `read_all_for_kind_streams_rows`, `io_failure_returns_null_on_read`, `io_failure_is_noop_on_write` (faulting `QueryExecutor`)
- [ ] T011 [P] Create `test/data/db/ai_cache_migration_test.dart` covering: constructs a v11 `AppDatabase`, populates a row in every existing table, runs the v11 → v12 migration, asserts the new `ai_cache` table exists with the expected schema, asserts every pre-existing row is preserved, asserts the new index exists
- [ ] T012 Run `dart run build_runner build` to regenerate `app_database.g.dart` and any other affected generated files; commit the regenerated files

**Checkpoint**: LRU + fingerprint + DAO + migration are in place and tested. No call-site changes yet.

---

## Phase 2: Foundational (Cache Class)

**Purpose**: The `AiResultCache` class that wires L1 + L2 + policies into the public API. This is the dependency every Phase 3+ task depends on.

- [ ] T013 Create `lib/features/ai/application/ai_result_cache.dart` with the `AiResultCache<K, V>` class per the contract in `contracts/ai-result-cache.md` (peek, lookup, remember, invalidate, evictForPair, clear, prune, stats)
- [ ] T014 Create the `aiResultCacheProvider` Riverpod provider in the same file (or `lib/features/ai/application/ai_result_cache_provider.dart`) with `keepAlive: true`, wiring `appDatabaseProvider`, `defaultPolicies`, `Logger('ai_cache')`, and an `authCtrlProvider` listener that calls `cache.clear()` on sign-out / user-id change
- [ ] T015 Create `test/features/ai/ai_result_cache_test.dart` covering all behaviors from FR-017 / the contract: `lookup_returns_l1_hit_without_calling_loader`, `lookup_returns_l2_hit_and_backfills_l1`, `lookup_writes_l1_and_l2_on_miss`, `l1_evicts_lru_tail_on_overflow`, `l1_returns_null_after_ttl`, `force_refresh_clears_l1_and_l2`, `force_refresh_propagates_loader_error`, `kinds_do_not_collide`, `evict_for_pair_clears_matching_entries`, `clear_drops_l1_and_l2_on_sign_out`, `prune_applies_per_kind_caps`, `stats_returns_snapshot`, `loader_error_does_not_pollute_cache`, `l2_io_failure_degrades_to_l1_only`
- [ ] T016 Run `dart run build_runner build` to regenerate `ai_result_cache_provider.g.dart` (and any other affected generated files); commit

**Checkpoint**: Cache class is in place and tested in isolation. User story implementation can now begin.

---

## Phase 3: User Story 1 — Translation re-open is instant (Priority: P1) 🎯 MVP

**Goal**: A learner who opens the lookup sheet on a phrase, closes it, and re-opens it on the same selection (the most common workflow) sees the Translation result appear immediately without any network call, even after killing and relaunching the app. Closes issue #311 gap C1.

**Independent Test**: Drive `lookupSheetTranslationProvider(params)` once (waits for translation); drive it again with the same params and assert the underlying `TranslationService.translate(...)` is NOT called a second time. Then construct a fresh `ProviderContainer` (simulating a kill-and-relaunch) and assert the second container's `lookupSheetTranslationProvider(params)` reads from L2 and still doesn't call `TranslationService.translate(...)`.

- [ ] T017 [P] [US1] Refactor `lookupSheetTranslationProvider` in `lib/features/lookup/application/lookup_section_providers.dart` to call `aiCache.lookup(kind: AiKind.translation, key: ..., loader: () => translationService.translate(...), forceRefresh: ...)`. Remove the direct `ref.read(translationServiceProvider).translate(...)` call. The `forceRefresh` parameter is plumbed from the provider argument (not yet wired to the UI; that's a later phase).
- [ ] T018 [US1] Add `test/features/lookup/lookup_translation_cache_test.dart` covering: warm L1 hit (no service call), cold L1 + warm L2 (no service call, returns persisted), cold L1 + cold L2 (service called, writes both), `forceRefresh: true` busts both tiers (service called again), `forceRefresh: false` does not bust. Use a fake `TranslationService` that counts calls.
- [ ] T019 [US1] Update `docs/features/dictionary-lookup.md` to add a "Cache hierarchy" section with a small diagram showing L1 + L2 + keying + eviction policy + the new `AiKind` enum

**Checkpoint**: US1 verified — Translation re-open is instant after a successful lookup, and survives app restart.

---

## Phase 4: User Story 2 — Bounded cache (Priority: P1)

**Goal**: A learner who uses the app for an entire study session does not see unbounded memory growth. The cache is bounded by L1 capacity + TTL and L2 row cap + age cutoff. Closes issue #311 gap C2.

**Independent Test**: Drive the lookup sheet dictionary provider repeatedly with > 256 distinct `(word, src, tgt)` triples and assert the L1 store never exceeds 256 entries and the LRU tail evicts on overflow. Add a test that fills L2 past the per-kind cap and asserts `evictOldestExcept` keeps the cap.

- [ ] T020 [US2] Add an integration test in `test/features/ai/ai_result_cache_lifecycle_test.dart` covering: 1000 distinct lookups → L1 size = 256, LRU eviction order is preserved (MRU-1, MRU-2, ..., LRU-N), TTL expiry frees space, L2 row cap = 4096 per kind, age cutoff prunes rows older than `now - policy.l2AgeCutoff`
- [ ] T021 [P] [US2] Verify `LookupSheetResultCache.evictForPair(sourceLanguage, targetLanguage)` still works after the slim-down (delegates to `AiResultCache.evictForPair`); the existing test in `test/features/lookup/lookup_sheet_result_cache_test.dart` is updated to use the new internal state but the public API behavior is preserved

**Checkpoint**: US2 verified — cache size is bounded by capacity and TTL; L2 row cap and age cutoff enforced.

---

## Phase 5: User Story 3 — `forceRefresh` on BYOK actually re-fetches (Priority: P2)

**Goal**: A learner who taps the contextual translation refresh icon, even when the BYOK provider is configured, sees a fresh LLM response (not the previously cached text). Closes issue #311 gap C3.

**Independent Test**: Override `translationCapabilityProvider` with a fake that records every call. Drive `TranslationService.translate(forceRefresh: true)` after a previous cached call; assert the fake was called again. Conversely, drive `TranslationService.translate(forceRefresh: false)` after a previous cached call; assert the fake was NOT called again.

- [ ] T022 [US3] Update `contextual_translation_lookup_section.dart` to read `aiResultCacheProvider` directly (no longer via `LookupSheetResultCache`) and call `aiCache.invalidate(kind: AiKind.contextualTranslation, key: fingerprint(params))` on `forceRefresh: true` before invoking the loader. The `loader` is now a closure around `contextualTranslationServiceProvider.translate(...)`.
- [ ] T023 [US3] Add `test/features/lookup/lookup_contextual_force_refresh_test.dart` covering: a fake `ContextualTranslationService` that counts calls; first call → 1 service call; `forceRefresh: true` → 2 service calls; `forceRefresh: false` after cached → 1 service call (no re-call)
- [ ] T024 [US3] Add `test/features/ai/byok_force_refresh_test.dart` covering: `TranslationService.translate(forceRefresh: true)` with a BYOK override (a `ByokTranslationCapability` wrapping a fake `LlmCapability`) calls the LLM; `TranslationService.translate(forceRefresh: false)` after a cached call does not call the LLM
- [ ] T025 [US3] Add a widget test for the contextual translation section's refresh icon: tap → loader invoked, cache invalidated, fresh result rendered

**Checkpoint**: US3 verified — `forceRefresh` busts both L1 and L2 on every provider (Enjoy and BYOK alike).

---

## Phase 6: User Story 4 — Unified keying (Priority: P2)

**Goal**: A future contributor adding a new AI modality can plug into the cache by writing a one-line `AiCacheFingerprint.fingerprint(...)` + `AiResultCache.lookup(...)` call. Closes issue #311 gap C4.

**Independent Test**: Construct two fake "modalities" backed by the cache with the same `(text, src, tgt)` payload but different `kind`; assert their cache keys differ. Add a synthetic modality (e.g. `AiKind.ttsPrompt`) and verify it can be added by registering a new `AiKind` value + a policy, with no changes to `AiResultCache` or its LRU / TTL / Drift schema.

- [ ] T026 [US4] Update `autoTranslateSourceKey` in `lib/features/transcript/domain/auto_translate.dart` to be a wrapper around `AiCacheFingerprint.fingerprint(kind: AiKind.autoTranslateLine.wire, payload: {...})` per D2 in plan.md. The wrapper preserves the existing test contract (`auto_translate_request_test.dart:175-183`).
- [ ] T027 [US4] Add `test/features/ai/kind_discrimination_test.dart` covering: two `AiKind` values with the same payload produce different fingerprints; same `AiKind` value with reordered payload keys produces the same fingerprint; the synthetic `ttsPrompt` modality can be added by registering a new enum value + policy without touching `AiResultCache`
- [ ] T028 [US4] Run the existing `auto_translate_request_test.dart` and `auto_translate_repository_test.dart` suites end-to-end to confirm SC-005 (the auto-translate semantics are preserved). If any test asserts a *specific* hex value of `cue.sourceKey`, update it to call `autoTranslateSourceKey(...)` instead of using a frozen hex.

**Checkpoint**: US4 verified — unified keying; auto-translate semantics preserved.

---

## Phase 7: User Story 5 — `linesForRow` decode memo (Priority: P3)

**Goal**: A learner who opens a media item and then any unrelated Drift table bump shifts the row's `updatedAt` does not have to re-decode the same track. Closes issue #311 gap C5.

**Independent Test**: Decode a `TranscriptRow` once via `linesForRow(row)`; bump `row.updatedAt` without changing `timelineJson`; call `linesForRow(row)` again; assert the second call returns the same list instance (no re-decode). Then mutate `timelineJson` and assert a re-decode happens.

- [ ] T029 [P] [US5] Update `_LinesCacheEntry` in `lib/features/transcript/data/transcript_repository.dart` to store `timelineJsonHash` (first 16 hex chars of SHA-1 of `row.timelineJson`) instead of `updatedAt`. Update `linesForRow` to compare the hash instead of `updatedAt`. Add a private helper `_timelineJsonHash(String)` that computes the hash.
- [ ] T030 [P] [US5] Add `test/features/transcript/transcript_repository_lines_cache_test.dart` covering: same `timelineJson` + different `updatedAt` returns cached (no re-decode); different `timelineJson` re-decodes; empty `timelineJson` returns empty list (no cache entry, edge case); large `timelineJson` (>10 KB) is hashed efficiently (test asserts the decode is O(n) and not O(n²))

**Checkpoint**: US5 verified — decode memo survives unrelated `updatedAt` bumps.

---

## Phase 8: Documentation + ADR

**Purpose**: Traceability for the change. The ADR cites issue #311; the docs describe the new cache hierarchy for users, contributors, and future maintainers.

- [ ] T031 [P] Create `docs/decisions/0045-ai-result-cache-hierarchy.md` per the ADR template in `.specify/templates/constitution-template.md` (problem, decision, alternatives, consequences; cite issue #311; partially supersede ADR-0039's scope)
- [ ] T032 [P] Update `docs/features/transcript.md` (auto-translate section) to describe the new unified cache participation; add a small diagram showing the L1 + L2 + keying + auto-translate `sourceKey` flow
- [ ] T033 [P] Update `docs/features/ai.md` (or `docs/features/dictionary-lookup.md` if a separate `ai.md` section is overkill) to list the new `AiKind` enum, the per-kind policies, the `AiResultCache` public API, and the `AiCacheFingerprint` helper
- [ ] T034 [P] Update `CHANGELOG.md` with the cache hierarchy entry: "Unified ad-hoc AI result caches (translation / dictionary / contextual / auto-translate line) into a bounded two-tier cache hierarchy; closes issue #311"

**Checkpoint**: ADR + docs + CHANGELOG updated.

---

## Phase 9: Verification

**Purpose**: Run the same cheap gates CI uses to ensure the change is green.

- [ ] T035 Run `bash .github/scripts/check_dart_format.sh --fix` to format the new files
- [ ] T036 Run `flutter analyze` and resolve every warning
- [ ] T037 Run `bash .github/scripts/check_codegen_drift.sh` (fails if any `*.g.dart` is out of date)
- [ ] T038 Run `flutter test` and resolve every failure
- [ ] T039 Run `bash .github/scripts/validate_ci_gates.sh --all` to mirror the full CI pipeline locally (slower, optional)

**Checkpoint**: All gates green. PR is ready to open.

---

## Cross-Cutting Notes

- Every new test file MUST be added under `test/` (not `test_assets/`); tests follow the existing `test/features/<feature>/<name>_test.dart` convention.
- Every new log line MUST use `logNamed('ai_cache')` (or a more specific sub-logger name); `print()` is forbidden.
- Every Drift migration MUST follow the existing `_addColumnIfMissing` discipline (idempotent `CREATE TABLE IF NOT EXISTS`, no blanket drops).
- Every cache lookup / remember MUST handle L2 I/O failure gracefully (DAO methods swallow + log, cache layer never throws except for loader errors).
- The `_ALLOW_EXISTING` and `--json` flags from `create-new-feature.sh` are not relevant here; this PR reuses the `015-ai-cache-hierarchy` spec directory created by `/speckit.specify`.
- The PR title MUST follow the existing convention (e.g. `[ai] Unify ad-hoc AI result caches into a bounded multi-tier cache (#311)`).
- The PR description MUST reference `Closes #311` so the issue is auto-closed on merge.

---

## Manual Verification (post-merge)

One case requires a real device:

- **Cold-restart lookup sheet re-open** — install the build on a target device, sign in, open the lookup sheet on a known phrase, wait for the Translation section to render, kill the app, relaunch, re-open the lookup sheet on the same phrase, observe the Translation text appears synchronously without a network spinner. This is the SC-001 / SC-002 success criterion. Documented in `quickstart.md`.

All other behaviors are covered by automated tests and do not require manual verification.