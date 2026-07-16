# Implementation Plan: AI Result Cache Hierarchy (issue #311)

**Branch**: `015-ai-cache-hierarchy` | **Date**: 2026-07-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/015-ai-cache-hierarchy/spec.md`

## Summary

Replace the four ad-hoc AI result caches in `lib/features/lookup/` and `lib/features/transcript/` with a single, bounded, two-tier (`memory → Drift → worker`) hierarchy that is shared across every AI modality. Close issue #311's gaps C1–C5: route plain translation through the cache (C1); bound dictionary / contextual caches with LRU + TTL (C2); make `forceRefresh` actually bust the cache on the BYOK path (C3); introduce a single fingerprinting helper so adding a new modality is a one-line call (C4); and fix the `transcript_repository.linesForRow` decode memo to invalidate on `timelineJson` content, not `updatedAt` (C5). The change ships a new Drift table `ai_cache` at `schemaVersion: 12`, a new `AiResultCache` abstraction, a new `AiCacheFingerprint` helper, a new `L1Store` (hand-rolled LRU + TTL, matching the `artwork_palette.dart` pattern), and the corresponding call-site migrations in `lookup_section_providers.dart`, `contextual_translation_lookup_section.dart`, `lookup_sheet_result_cache.dart`, and `transcript_repository.dart`. The auto-translate `sourceKey` becomes a thin wrapper around `AiCacheFingerprint.fingerprint(...)`, preserving every existing test verbatim.

## Technical Context

**Language/Version**: Dart `^3.12.0` (per `pubspec.yaml`) on the Flutter stable channel pinned in `.github/flutter-version`. No language version bump is required.

**Primary Dependencies** (no new dependencies — the cache is pure-Dart + Drift):

- `drift: ^2.31.0` + `drift_flutter: ^0.2.8` — existing. The new `ai_cache` table is a standard Drift `@DataClassName` declaration.
- `crypto: ^3.0.6` — existing. Used by `AiCacheFingerprint` (SHA-256) and the `transcript_repository.dart` `timelineJson` hash (SHA-1). Both are already in `pubspec.yaml`.
- `logging: ^1.3.0` — existing. The cache layer uses `logNamed('ai_cache')` for hit/miss/error events.

**Storage**: One new Drift table `ai_cache(kind, key, payloadJson, updatedAt)` under `lib/data/db/tables/ai_cache.dart`. Lives in the same `enjoy_player.sqlite` (or per-user `enjoy_player_<userId>.sqlite`) as every other table. No other persistence changes.

**Testing**: `flutter test` (host VM) against `NativeDatabase.memory()` (the existing pattern in `auto_translate_request_test.dart`). The cache layer is split so the pure-Dart core is testable without Riverpod, the DAO is testable against an in-memory Drift database, and the integration (via `lookup_section_providers.dart` and `auto_translate_controller.dart`) is testable via `ProviderContainer` with overrides — mirroring the existing transcript test suite.

**Target Platform**: Android, iOS, macOS, Windows, Linux (unchanged; per ADR-0048). The cache has no platform-conditional code.

**Project Type**: Flutter native mobile/desktop app — no new project type.

**Performance Goals** (per FR/SC in the spec):

- Lookup sheet Translation re-open with warm L1: **< 50 ms p95** (SC-001).
- Lookup sheet Translation re-open after app restart (warm L2, cold L1): **< 250 ms p95** (SC-002).
- L1 size: **<= 256 entries** at default cap; **<= 8 MiB** at default payload sizes (QR-004).
- L1 hit ratio over a 30-min study session with repeated lookups: **>= 60%** (QR-004).
- Drift L2 row count per kind: **<= 4096** at default cap; **<= 30 days** at default age cutoff.

**Constraints** (inherited from AGENTS.md and the constitution):

- Local-first, offline-capable.
- No `print()`, no `kIsWeb`, no new `media_kit` `Player()`.
- Drift DAOs are the only SQLite path. The new `AiCacheDao` is a `@DriftAccessor` next to the existing DAOs.
- No new dependencies without an ADR (the cache uses only existing packages).
- `autoTranslateSourceKey` must remain compatible with the existing tests in `auto_translate_request_test.dart:175-183`.
- `appDatabaseProvider` already wires `AppDatabase` per-user; the cache provider listens to `authCtrlProvider` and clears L1 on sign-out.

**Scale/Scope**:

- 1 new file: `lib/features/ai/application/ai_result_cache.dart`.
- 1 new file: `lib/features/ai/application/ai_kind_policies.dart`.
- 1 new file: `lib/features/ai/application/ai_cache_fingerprint.dart`.
- 1 new file: `lib/features/ai/domain/ai_kind.dart`.
- 1 new file: `lib/data/db/tables/ai_cache.dart`.
- 1 new file: `lib/core/cache/lru_store.dart` (promoted to `core/` because the LRU primitive is generic).
- 1 new DAO: `AiCacheDao` (in `lib/data/db/app_database.dart` or `lib/data/db/ai_cache_dao.dart`).
- Edits to `lib/features/lookup/application/lookup_section_providers.dart`.
- Edits to `lib/features/lookup/application/lookup_sheet_result_cache.dart`.
- Edits to `lib/features/lookup/presentation/sections/contextual_translation_lookup_section.dart`.
- Edits to `lib/features/transcript/data/transcript_repository.dart` (the `_linesCache` memo).
- Edits to `lib/features/transcript/domain/auto_translate.dart` (`autoTranslateSourceKey` becomes a wrapper).
- Drift schema bump: `AppDatabase.schemaVersion: 11` → `12`, migration step.
- Regenerated: `app_database.g.dart`, `ai_capability_providers.g.dart` (no change to providers, just drift codegen), `lookup_section_providers.g.dart` (no change to providers, just for symmetry).
- 1 new ADR: `docs/decisions/0045-ai-result-cache-hierarchy.md`.
- Edits: `docs/features/dictionary-lookup.md` (new "Cache hierarchy" section), `docs/features/transcript.md` (auto-translate line cache), `docs/features/ai.md` (new "Cache" subsection).
- Tests: ~15 new test cases across `test/core/cache/`, `test/features/ai/`, `test/features/lookup/`, `test/data/db/`, `test/features/transcript/`.

---

## Constitution Check

*GATE: Must pass before Phase 1 design. Re-check after Phase 2 implementation.*

### I. Architecture and Code Quality

- The cache lives in `lib/features/ai/application/` (R1) and `lib/core/cache/` (R2, for the LRU primitive). Both placements follow the feature-first layout. No new top-level folders.
- The cache is a Drift DAO consumer (existing pattern) and a Riverpod provider consumer (existing pattern). No mutable global singletons; the `keepAlive: true` provider is the standard Riverpod pattern.
- No `print()` (uses `logNamed('ai_cache')`). No `kIsWeb`. No new `media_kit` `Player()`. The cache does not touch native code.
- The auto-translate path stays feature-first: `auto_translate_controller.dart` calls into `aiResultCacheProvider` (new), not into `lookup_sheet_result_cache.dart`.

**Verdict: PASS.**

### II. Testing Defines the Contract

- Pure-Dart core (`L1Store`, `AiCacheFingerprint`, `AiKindPolicy`, `AiResultCache`) — unit tests in `test/core/cache/` and `test/features/ai/`.
- DAO (`AiCacheDao`) — tests against `NativeDatabase.memory()` in `test/data/db/ai_cache_dao_test.dart`.
- Integration via Riverpod — tests in `test/features/lookup/` and `test/features/transcript/` extending the existing `auto_translate_request_test.dart` patterns.
- The existing `auto_translate_request_test.dart` suite (which currently asserts `cue.sourceKey == autoTranslateSourceKey(...)`) MUST pass without modification other than the new keying call (R10). This is the regression contract.
- Edge cases in the spec (L2 I/O failure, sign-out clear, `evictForPair` correctness) get dedicated tests.

**Verdict: PASS.**

### III. User Experience Consistency

- The cache is internal. No new UI, no new strings, no new controls.
- The lookup sheet's user-visible behavior changes in three places: (a) Translation re-open is instant, (b) refresh icon on BYOK actually re-fetches, (c) source/target swap still clears stale results. All three are already part of the existing UX — the cache just makes them correct.
- No haptics, tooltips, or keyboard affordances change.

**Verdict: PASS.**

### IV. Performance Is a Requirement

- SC-001 / SC-002 (cold and warm L1 / L2 latencies) are measurable. The cache layer's synchronous L1 fast-path is `Map.get` + a TTL check — sub-microsecond. The L2 path is a single Drift `SELECT` against `(kind, key)` PK — sub-millisecond on `NativeDatabase.memory()`, tens of milliseconds on real disk on first launch.
- The QR-004 budget (`<= 8 MiB` L1 footprint) is documented and tested.
- The Drift migration adds one table and one index — both cheap.
- No expensive work in `build` methods (the cache provider is `keepAlive`, the lookup path is async via the existing `Future.when`).

**Verdict: PASS.**

### V. Documentation and Traceability

- New ADR `0045-ai-result-cache-hierarchy.md` (R12) cites issue #311 and supersedes ADR-0039's scope.
- `docs/features/dictionary-lookup.md` gets a new "Cache hierarchy" section.
- `docs/features/transcript.md` (auto-translate section) describes the unified cache participation.
- `docs/features/ai.md` (or a new subsection in `docs/features/dictionary-lookup.md`) lists the new `AiKind` enum and the policies.
- The cache's relationship to ADR-0015 (YouTube playback) is documented (R12: unrelated).

**Verdict: PASS.**

---

## Design Decisions

### D1. Two-tier cache shape

```
Caller
  │   aiCache.lookup(kind, key, loader, forceRefresh: false)
  ▼
┌─────────────┐  hit   ┌─────────────┐  hit   ┌─────────────┐  miss  ┌────────────┐
│  L1 (in-mem │───►────│  Return V   │        │  L2 (Drift  │───►────│  loader()  │
│   LRU+TTL)  │        │             │◄───backfill L1│  ai_cache)  │  return V  │
└─────────────┘        └─────────────┘        └─────────────┘        └─────┬──────┘
       │ miss                                                         │
       ▼                                                              │
┌─────────────┐  hit   ┌─────────────┐                                  │
│  L2 (Drift  │───►────│  Return V,  │                                  │
│   ai_cache) │        │  backfill L1│                                  │
└─────────────┘        └─────────────┘                                  │
       │ miss                                                         │
       ▼                                                              │
   loader() ──────────────────────────────────────────────────────────►│
                                                                       │
   remember(L1 sync, L2 async fire-and-forget; failure logged)        ▼
```

### D2. Fingerprint compatibility for auto-translate

`autoTranslateSourceKey(...)` becomes:

```dart
String autoTranslateSourceKey({
  required String primaryText,
  required String sourceLanguage,
  required String targetLanguage,
}) {
  final normalized = normalizeAutoTranslateSourceText(primaryText);
  final src = workerLanguageBase(sourceLanguage);
  final tgt = workerLanguageBase(targetLanguage);
  return AiCacheFingerprint.fingerprint(
    kind: AiKind.autoTranslateLine.wire,
    payload: {
      'primaryText': normalized,
      'sourceLanguage': src,
      'targetLanguage': tgt,
    },
  );
}
```

The canonical encoding inside `AiCacheFingerprint.fingerprint(...)` is `auto_translate_line|<sorted kvs joined by '|'>`. For this payload, the sorted kvs are `primaryText`, `sourceLanguage`, `targetLanguage` (alphabetical), joined by `|`. So the canonical input is `auto_translate_line|<normalized>|<src>|<tgt>`, which is exactly the string the current implementation hashes (modulo the `auto_translate_line|` prefix). The SHA-256 prefix differs from the current output, so the existing test's `expect(cue.sourceKey, autoTranslateSourceKey(...))` still passes (both sides use the new function) — but any *frozen* sourceKey value in tests or fixtures needs an update.

Wait — re-reading the existing test (auto_translate_request_test.dart:175-183):

```dart
expect(
  cue.sourceKey,
  autoTranslateSourceKey(
    primaryText: 'Hello',
    sourceLanguage: 'en',
    targetLanguage: 'zh-CN',
  ),
);
```

This compares `cue.sourceKey` (the value stored on the AI cue JSON) against the output of `autoTranslateSourceKey(...)`. As long as both sides use the same function, the assertion holds. The function's output may differ from any pre-change snapshot, but the test does not assert a specific hex value — it asserts the round-trip equality. So the test passes without modification.

Verified.

### D3. Sign-out / per-user L1 clearing

```dart
@Riverpod(keepAlive: true)
AiResultCache aiResultCache(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final cache = AiResultCache(db.aiCacheDao);
  ref.listen(authCtrlProvider, (prev, next) {
    final wasSignedIn = prev is AuthSignedIn;
    final isSignedIn = next is AuthSignedIn;
    final userChanged = wasSignedIn && isSignedIn &&
        (prev as AuthSignedIn).profile.id != (next as AuthSignedIn).profile.id;
    if (!isSignedIn || userChanged) {
      unawaited(cache.clear());
    }
  });
  return cache;
}
```

L2 is naturally scoped: when the user signs out, `appDatabaseProvider` is updated by `SyncCtrl._onSignedIn` to point at the device-global DB (or the new user's DB on sign-in). The cache's `_l2` field re-reads `db.aiCacheDao` via the provider's `watch`, so L2 hits the right DB.

### D4. `evictForPair` correctness

```dart
Future<void> evictForPair({required String sourceLanguage, required String targetLanguage}) async {
  // L1: synchronous scan.
  final keysToRemove = <String>[];
  _l1.forEach((key, _payload) {
    final decoded = jsonDecode(_payload) as Map<String, dynamic>;
    if (decoded['sourceLanguage'] == sourceLanguage &&
        decoded['targetLanguage'] == targetLanguage) {
      keysToRemove.add(key);
    }
  });
  for (final k in keysToRemove) {
    _l1.invalidate(k);
  }
  // L2: SELECT then DELETE in a transaction.
  final hits = await _l2.readAllForKindWhere(
    payloadContainsSourceAndTarget(sourceLanguage, targetLanguage),
  );
  for (final row in hits) {
    await _l2.delete(row.kind, row.key);
  }
}
```

For the L2 scan, the SQL is `SELECT kind, key FROM ai_cache WHERE payload_json LIKE '%"sourceLanguage":"<src>"%' AND payload_json LIKE '%"targetLanguage":"<tgt>"%'`. At the documented L2 row cap (4096 per kind, three lookup kinds), this is a small LIKE scan — acceptable. A future optimization could materialize `sourceLanguage` / `targetLanguage` as columns, but the spec scope does not require it.

### D5. Drift schema migration discipline

The migration step (`AppDatabase._runMigrations`, case `next == 12`) uses `customStatement('CREATE TABLE IF NOT EXISTS ...')` and `customStatement('CREATE INDEX IF NOT EXISTS ...')`. This is idempotent across interrupted launches, mirroring the `_addColumnIfMissing` pattern in `app_database.dart:138-154`.

A migration test (`test/data/db/ai_cache_migration_test.dart`) constructs a v11 `AppDatabase`, populates a row in every existing table, runs the v11 → v12 migration, and asserts:
- The new `ai_cache` table exists with the expected schema.
- Every pre-existing row is preserved.
- The new index exists.

---

## Project Structure

### New files

| Path | Purpose |
|------|---------|
| `lib/features/ai/application/ai_result_cache.dart` | `AiResultCache<K, V>` abstraction |
| `lib/features/ai/application/ai_cache_fingerprint.dart` | `AiCacheFingerprint.fingerprint(...)` pure helper |
| `lib/features/ai/application/ai_kind_policies.dart` | `AiKindPolicy` defaults + `defaultPolicies` map |
| `lib/features/ai/domain/ai_kind.dart` | `AiKind` enum (`translation`, `dictionary`, `contextualTranslation`, `autoTranslateLine`) |
| `lib/data/db/tables/ai_cache.dart` | Drift `@DataClassName('AiCacheRow') class AiCache extends Table` |
| `lib/core/cache/lru_store.dart` | `L1Store<K, V>` hand-rolled LRU + TTL |

### Modified files

| Path | Change |
|------|--------|
| `lib/data/db/app_database.dart` | Add `AiCache` to tables, `AiCacheDao` to daos, bump `schemaVersion` to 12, add migration step |
| `lib/features/lookup/application/lookup_section_providers.dart` | `lookupSheetTranslationProvider` calls `aiCache.lookup(...)` (closes C1); `lookupSheetDictionaryProvider` calls `aiCache.lookup(...)` |
| `lib/features/lookup/application/lookup_sheet_result_cache.dart` | Remove `_dictionary` / `_contextual` maps; keep `evictForPair` as a delegator |
| `lib/features/lookup/presentation/sections/contextual_translation_lookup_section.dart` | Reads `aiResultCacheProvider` directly; uses `aiCache.invalidate(...)` on `forceRefresh` (closes C3 for contextual) |
| `lib/features/transcript/data/transcript_repository.dart` | `_linesCache` keyed on `timelineJson` SHA-1 hash, not `updatedAt` (closes C5) |
| `lib/features/transcript/domain/auto_translate.dart` | `autoTranslateSourceKey` becomes a wrapper around `AiCacheFingerprint.fingerprint(...)` (preserves existing tests) |
| `lib/features/ai/application/ai_capability_providers.dart` | No functional change; the capability-level `forceRefresh` is preserved for the wire-level contract but is no longer the client-side cache-bust mechanism (R5) |
| `docs/features/dictionary-lookup.md` | Add "Cache hierarchy" section |
| `docs/features/transcript.md` | Add "Auto-translate line cache" subsection |
| `docs/features/ai.md` | Add "Cache" subsection listing `AiKind` + policies |
| `docs/decisions/0045-ai-result-cache-hierarchy.md` | New ADR citing issue #311 |

### New test files

| Path | Purpose |
|------|---------|
| `test/core/cache/lru_store_test.dart` | Capacity, LRU eviction, TTL expiry, `clear` |
| `test/features/ai/ai_cache_fingerprint_test.dart` | Determinism, `kind` discrimination, no collision with auto-translate's old hash length |
| `test/features/ai/ai_result_cache_test.dart` | L1 hit skips loader, L1 miss + L2 hit returns persisted and backfills L1, L1+L2 miss calls loader, `forceRefresh` busts both tiers, `evictForPair`, sign-out clear |
| `test/data/db/ai_cache_dao_test.dart` | All DAO methods, I/O failure injection, eviction, prune |
| `test/data/db/ai_cache_migration_test.dart` | v11 → v12 preserves existing data |
| `test/features/lookup/lookup_ai_cache_integration_test.dart` | End-to-end through `lookupSheetTranslationProvider` / `lookupSheetDictionaryProvider` |
| `test/features/transcript/auto_translate_cache_integration_test.dart` | End-to-end through `AutoTranslateCtrl._translateLine` against the new cache |

---

## Implementation Phases

### Phase 1: Foundation (cache primitive + DAO)

**Tasks** (see `tasks.md` for the full list with IDs):

- T001 — Create `lib/core/cache/lru_store.dart` with `L1Store<K, V>`.
- T002 — Create `test/core/cache/lru_store_test.dart`.
- T003 — Create `lib/features/ai/domain/ai_kind.dart` with `AiKind` enum.
- T004 — Create `lib/features/ai/application/ai_cache_fingerprint.dart` with the canonical encoding.
- T005 — Create `test/features/ai/ai_cache_fingerprint_test.dart`.
- T006 — Create `lib/features/ai/application/ai_kind_policies.dart` with the default policy map.
- T007 — Create `lib/data/db/tables/ai_cache.dart` with the Drift table.
- T008 — Add `AiCacheDao` to `lib/data/db/app_database.dart` (or split into `ai_cache_dao.dart`).
- T009 — Bump `schemaVersion` to 12 and add the migration step.
- T010 — Create `test/data/db/ai_cache_dao_test.dart`.
- T011 — Create `test/data/db/ai_cache_migration_test.dart`.
- T012 — Run `dart run build_runner build` to regenerate `app_database.g.dart`.

**Checkpoint**: LRU + fingerprint + DAO + migration are in place and tested. No call-site changes yet.

### Phase 2: Cache class

- T013 — Create `lib/features/ai/application/ai_result_cache.dart` with `AiResultCache<K, V>` (L1 + L2 wiring, `lookup`, `peek`, `remember`, `invalidate`, `evictForPair`, `clear`, `prune`).
- T014 — Create the `aiResultCacheProvider` Riverpod provider with `authCtrlProvider` listener for sign-out clearing.
- T015 — Create `test/features/ai/ai_result_cache_test.dart` (all behaviors from FR-017).

**Checkpoint**: Cache class is in place and tested in isolation.

### Phase 3: User Story 1 (Translation re-open is instant)

- T016 — Refactor `lookupSheetTranslationProvider` to call `aiCache.lookup(...)` (closes C1).
- T017 — Add `test/features/lookup/lookup_ai_cache_integration_test.dart` covering warm L1, warm L2, forceRefresh.
- T018 — Update `docs/features/dictionary-lookup.md` with the new "Cache hierarchy" section.

### Phase 4: User Story 2 (Bounded cache)

- Already covered by Phase 1 (`L1Store` cap + TTL tests) and Phase 2 (`AiResultCache` cap enforcement + Drift row cap).
- T019 — Add an integration test that fills L1 past its cap and asserts eviction.
- T020 — Add an integration test for L2 row cap and age cutoff.

### Phase 5: User Story 3 (`forceRefresh` on BYOK)

- T021 — Verify `ByokTranslationCapability.translate(...)` is unaffected by the cache change (the capability does not need to bust the cache; the cache layer does).
- T022 — Add a test in `test/features/ai/byok_force_refresh_test.dart` that drives `TranslationService.translate(forceRefresh: true)` with a BYOK override and asserts the LLM is called.
- T023 — Update `contextual_translation_lookup_section.dart` to use `aiCache.invalidate(...)` on `forceRefresh` (closes C3 for contextual).
- T024 — Add a widget test for the contextual translation refresh icon.

### Phase 6: User Story 4 (Unified keying)

- T025 — Update `auto_translate_controller.dart` and `auto_translate.dart` to use `AiCacheFingerprint.fingerprint(...)` via the new `autoTranslateSourceKey` wrapper.
- T026 — Add a test that verifies two modalities with the same payload do not collide (kind discrimination).
- T027 — Add a test that verifies a new modality can be added by registering an `AiKind` value + a policy, with no changes to the cache class.

### Phase 7: User Story 5 (`linesForRow` decode memo)

- T028 — Update `_LinesCacheEntry` to store `timelineJsonHash` instead of `updatedAt`.
- T029 — Add a test that bumps `updatedAt` without changing `timelineJson` and asserts no re-decode.
- T030 — Add a test that mutates `timelineJson` and asserts a re-decode.

### Phase 8: Documentation + ADR

- T031 — Create `docs/decisions/0045-ai-result-cache-hierarchy.md`.
- T032 — Update `docs/features/dictionary-lookup.md`, `docs/features/transcript.md`, `docs/features/ai.md`.
- T033 — Update CHANGELOG.md with the cache hierarchy entry.

### Phase 9: Verification

- T034 — Run `bash .github/scripts/check_dart_format.sh`.
- T035 — Run `flutter analyze`.
- T036 — Run `bash .github/scripts/check_codegen_drift.sh`.
- T037 — Run `flutter test`.
- T038 — Run `bash .github/scripts/validate_ci_gates.sh --all`.

**Checkpoint**: All gates green. PR is ready to open.

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| `autoTranslateSourceKey` change breaks existing fixtures (any frozen hex values in tests) | Low | Medium | The existing test compares both sides via the new function (R10); no frozen hex values. |
| Drift schema migration fails on devices with partial migration from a prior crash | Low | High | Idempotent `CREATE TABLE IF NOT EXISTS` + `CREATE INDEX IF NOT EXISTS` (D5). Migration test in `test/data/db/ai_cache_migration_test.dart`. |
| L1 cache grows past `8 MiB` budget in pathological lookups | Low | Low | Default 256 entries × 2 KiB max payload = 512 KiB; budget has 16× headroom. LRU enforces the cap. |
| `evictForPair` LIKE scan on L2 is slow | Low | Low | At 4096 rows per kind × 3 lookup kinds, LIKE scan is sub-millisecond. Test asserts p95 < 50 ms. |
| Sign-out clearing races a concurrent lookup | Medium | Low | `clear()` is async; L1 is cleared synchronously, L2 is cleared before the next L2 read. The race is benign — a stale L2 read may return a value from the previous user, but the next lookup misses L1+L2 and re-fetches. |
| `forceRefresh` semantics differ between BYOK and worker paths | Low | Medium | R5: cache layer is the enforcement point; both paths go through the same cache. |
| New Drift table name `ai_cache` clashes with a future table | Very low | Low | `ai_cache` is unique; grep confirms no existing table with this name. |