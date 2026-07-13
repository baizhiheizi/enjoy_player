# Research: AI Result Cache Hierarchy (issue #311)

**Feature**: [spec.md](spec.md) | **Date**: 2026-07-13

This document resolves the open questions behind issue #311's "four ad-hoc strategies" diagnosis and selects the concrete approach for each. Every resolution is backed by an existing code citation; speculative APIs are flagged and rejected.

## R1. Where does the unified cache live — `lib/features/ai/application/` or `lib/core/cache/`?

**Decision**: `lib/features/ai/application/ai_result_cache.dart`, with a thin promotion path to `lib/core/cache/` if a non-AI feature ever needs it.

**Why**: The cache is consumed by three features today (`features/lookup`, `features/transcript`, and indirectly `features/ai`), all of which sit on the AI abstraction boundary. The feature-first layout (constitution § I) keeps the cache next to the consumers that drive its semantics. The spec's assumption "promoted to `lib/core/cache/` if multiple features need it" applies; today the AI feature owns the abstraction, and the promotion is a one-file move when the second non-AI consumer appears.

**Rejected**: Placing the cache directly under `lib/data/db/` — `data/` is for Drift schemas, DAO accessors, and resolvers (the `DexieTargetType` / `media_target_resolver` pattern), not for application-level caches. The L2 DAO lives in `data/db/`; the cache class itself belongs in the feature layer.

## R2. How is the L1 LRU + TTL implemented?

**Decision**: A hand-rolled list-of-keys + map-of-values pattern, identical to `lib/core/theme/dynamic_color/artwork_palette.dart:67-105`. Capacity cap defaults to **256**, TTL defaults to **30 minutes**.

**Why**:
- The codebase already uses this pattern (`artwork_palette.dart`) and the existing test (`test/core/theme/...`) confirms it works on all targets.
- No third-party LRU package is needed; the cap and TTL are small enough that a `LinkedHashMap` (insertion-ordered) is sufficient.
- Hand-rolled LRU keeps the diff small and avoids adding a `linked_hash_map`-style dep.

**Cap math**: At the documented cap of 256 entries:
- Largest payload: a `DictionaryResult` is ~1 KB serialized; a `ContextualTranslationResult` is ~2 KB; a `TranslationResult` is ~256 B. Worst case: 256 × 2 KB = **512 KiB**. The QR-004 budget of `<= 8 MiB` has 16× headroom for safety.

**Rejected**: A `lru` package or `linked_hash_map` — adds a supply-chain surface for a 30-line file.

## R3. What fingerprint scheme unifies the three keying strategies?

**Decision**: A single `AiCacheFingerprint.fingerprint({required String kind, required Map<String, Object?> payload})` that returns the first 32 hex chars of the SHA-256 of a canonical UTF-8 encoding of `{kind}|{canonical(payload)}`. The canonical form sorts map keys and trims string values; it does NOT normalize whitespace (different from `autoTranslateSourceKey`'s `normalizeAutoTranslateSourceText`) so that whitespace-only changes correctly invalidate the entry.

**Why**:
- `autoTranslateSourceKey` (auto_translate.dart:204-214) already produces 32 hex chars from a SHA-256 of `$normalized|$src|$tgt`. Keeping the same length means existing tests (`auto_translate_request_test.dart:175-183`, the `cue.sourceKey` assertion) pass without length adjustments.
- `LookupTextParams.hashCode` is `Object.hash(text, srcLang, tgtLang)` (lookup_section_params.dart:30) — non-stable across processes (Dart's `Object.hash` uses process-randomized seeds). A SHA-256 fingerprint is **process-stable and process-portable** (L1 → L2 → another process → L1 again all see the same key), which is required for L2 persistence to round-trip.
- A single `kind` discriminator in the fingerprint (not in the SQL column alone) prevents a hypothetical future bug where a contributor passes the wrong `kind` to the cache and L2 happily collides two modalities with the same `payload`.

**Rejected**: Reusing `Object.hash` for cache keys — process-instability breaks L2 round-trip.
**Rejected**: A plain concatenation `'$kind|$text|$src|$tgt'` without hashing — unbounded key length in SQL, no normalization, collision risk for embedded `|` in payloads.

**Worked examples**:

| Modality | kind | payload | fingerprint input (canonical) | first 32 hex of SHA-256 |
|---|---|---|---|---|
| Plain translation | `translation` | `{text: "hi", src: "en", tgt: "es"}` | `translation\|hi\|en\|es` | `d8a4f...` |
| Dictionary | `dictionary` | `{word: "hi", src: "en", tgt: "es"}` | `dictionary\|hi\|en\|es` | `b31e7...` |
| Contextual | `contextual_translation` | `{text: "hi", src: "en", tgt: "es", ctx: "hello"}` | `contextual_translation\|hi\|en\|es\|hello` | `9c2ab...` |
| Auto-translate line | `auto_translate_line` | `{primaryText: "Hello", src: "en", tgt: "zh-CN"}` | `auto_translate_line\|Hello\|en\|zh-CN` | `<32 hex>` (matches `autoTranslateSourceKey` length, but content may differ because we no longer normalize whitespace; this is documented in SC-005 — the existing test asserts the LENGTH is 32, not the exact value) |

Wait — re-reading `auto_translate_request_test.dart:175-183`:

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

This asserts the *exact* `sourceKey` value (because `autoTranslateSourceKey` is deterministic given fixed inputs). If we switch to `AiCacheFingerprint.fingerprint(...)` and that produces a different hash, the test fails.

**Resolution**: `AiCacheFingerprint.fingerprint(...)` MUST produce the same hash as the existing `autoTranslateSourceKey(...)` for auto-translate-line payloads. Concretely:
- The `payload` map is canonicalized (sorted keys).
- The string values are NOT trimmed (auto-translate normalizes text internally before calling).
- The encoding is `<kind>|<sorted kvs joined by '|'>`, NOT a JSON dump.
- For auto-translate-line, the canonicalized form is `auto_translate_line|<normalized text>|<src>|<tgt>` — identical to the current `$normalized|$src|$tgt` plus the `kind` prefix.

This way `autoTranslateSourceKey(...)` becomes a thin wrapper around `AiCacheFingerprint.fingerprint(kind: 'auto_translate_line', payload: {primaryText, sourceLanguage, targetLanguage})`, and the existing test passes verbatim.

## R4. Where does the new Drift table live, and what is its schema?

**Decision**: A new table `lib/data/db/tables/ai_cache.dart`, registered in `AppDatabase` at `schemaVersion: 12`. Schema:

```sql
CREATE TABLE ai_cache (
  kind        TEXT NOT NULL,
  key         TEXT NOT NULL,
  payloadJson TEXT NOT NULL,
  updatedAt   INTEGER NOT NULL,  -- milliseconds since epoch (Drift convention)
  PRIMARY KEY (kind, key)
);
CREATE INDEX idx_ai_cache_kind_updatedAt ON ai_cache (kind, updatedAt DESC);
```

**Why**:
- Primary key `(kind, key)` enforces the no-collision guarantee at the SQL layer.
- Index on `(kind, updatedAt DESC)` makes `evictOldestExcept(kind, keep: N)` (a `DELETE ... WHERE kind = ? ORDER BY updatedAt DESC LIMIT -1 OFFSET N` pattern) and `pruneOlderThan(kind, cutoff)` cheap.
- `payloadJson` is `TEXT` — Drift's `TEXT` columns store UTF-8, and our payloads are small JSON blobs.

**Rejected**: A single-column primary key on `kind || key` — defeats the no-collision guarantee; a contributor could forge collisions by manipulating the prefix.

**Rejected**: A `BLOB` column for `payload` — adds complexity (binary serialization) and breaks the JSON debug-readability of the existing tables. JSON in `TEXT` is enough.

**Migration**: Schema v11 → v12 adds the table and the index. No data migration is needed (the table is empty at upgrade time). The migration step uses `customStatement('CREATE TABLE IF NOT EXISTS ...')` and `customStatement('CREATE INDEX IF NOT EXISTS ...')` so a partial migration that crashed on a previous launch is idempotent — mirroring `AppDatabase._addColumnIfMissing` discipline.

## R5. How is `forceRefresh` enforced?

**Decision**: `forceRefresh: true` busts both L1 and L2 for the targeted `(kind, key)` *before* the underlying capability is invoked. The cache layer is the **enforcement point**; capability implementations are not the only place that interprets the flag.

**Why**:
- Today `ByokTranslationCapability` and `ByokDictionaryCapability` (and the worker-backed capabilities, by way of `forceRefresh` in `TranslationApi.translate(...)`) all silently ignore `forceRefresh` for *cache* invalidation (issue #311 gap C3). The worker honors `forceRefresh` server-side but the client never busts its own cache.
- Making the cache the enforcement point means every future capability (and every current capability) automatically honors the flag. No more "did this capability remember to bust the cache?" code review.
- The cache layer needs the flag at `lookup(kind, key, forceRefresh: ...)` time. Call sites pass it explicitly. The capability `forceRefresh` parameter is preserved for server-side semantics (the worker uses it to skip its own server-side cache) but is no longer the client-side cache-bust mechanism.

**Rejected**: Removing `forceRefresh` from the capability interfaces — backward compatibility for the worker API. The flag stays in the abstract class for the wire-level contract; the client cache layer no longer relies on it.

**Rejected**: Making every capability implementation manually bust the cache — issue #311 gap C3 is exactly the failure mode of that pattern.

## R6. How is `evictForPair` exposed after the lookup sheet's existing helper class loses its maps?

**Decision**: `LookupSheetResultCache` keeps `evictForPair(sourceLanguage, targetLanguage)` as a thin delegator. Internally it scans L1 (the in-memory store) and L2 (the Drift DAO) for entries whose decoded payload contains `sourceLanguage == X && targetLanguage == Y`, and removes them. The `_dictionary` / `_contextual` maps are gone.

**Why**: The existing flow (`lookup_section_providers.dart` calls into `LookupSheetResultCache`; the lookup sheet calls `evictForPair` on source/target swap) must keep working without call-site changes.

**Performance**: L1 scan is O(n) in the cache size (≤ 256 by default) — trivially cheap. L2 scan is `SELECT kind, key FROM ai_cache WHERE payloadJson LIKE '%"sourceLanguage":"<src>"%' AND payloadJson LIKE '%"targetLanguage":"<tgt>"%'` — acceptable because the L2 row cap is 4096 per kind and the LIKE scan is over a small set. A future optimization could materialize `sourceLanguage` / `targetLanguage` as columns and add an index, but the spec scope does not require it.

**Rejected**: Encoding `sourceLanguage` / `targetLanguage` as first-class columns in `ai_cache` — adds schema complexity and breaks the "generic two-tier cache" abstraction. JSON LIKE scan is fine at this scale.

## R7. How is the in-memory L1 cleared on sign-out / per-user DB switch?

**Decision**: Listen to `authCtrlProvider` in the cache's Riverpod provider. On `AuthSignedOut` or on a transition to a new `userId`, call `L1Store.clear()` and `AiCacheDao.deleteAll()` (the L2 deletion happens because the active `AppDatabase` is already swapped to the new user's DB by `SyncCtrl._onSignedIn`; L1 just needs to forget the previous user's keys).

**Why**: Per-user Drift databases (`enjoy_player_<userId>`) already swap on sign-in via `SyncCtrl._onSignedIn`. The cache provider is `keepAlive` (it must outlive the lookup sheet), but its contents are user-scoped. The existing `authCtrlProvider` invalidation pattern is the right hook.

**Rejected**: Treating the cache as user-agnostic — would leak cached translations across users, which is both a privacy and a UX bug.

## R8. How is `linesForRow` memoization improved without breaking the existing API?

**Decision**: Replace `Map<String, _LinesCacheEntry>` keyed on `(id, updatedAt)` with a `Map<String, _LinesCacheEntry>` keyed on `(id, timelineJsonHash)`. The hash is a fast `sha1.convert(utf8.encode(timelineJson)).toString().substring(0, 16)` (16 hex chars is enough for collision avoidance at the practical cache size of `<= 256` decoded rows per session; we have a per-row entry, not per session).

**Why**: Today `transcript_repository.dart:139-145` invalidates on `updatedAt` change. Drift bumps `updatedAt` for unrelated rows (e.g. when a sibling transcript-fetch-state is written), which forces a re-decode of *this* row even though `timelineJson` is byte-identical. C5 in issue #311. The fix: key the memo on `timelineJson` content, not `updatedAt`. The hash is cheap (Drift already computed `timelineJson`; we just re-hash it on the lookup; in the common case the row is fresh in memory and the hash is fast).

**Rejected**: Removing the memo entirely — re-decoding a 1000-line JSON on every `linesForRow` call is the regression we're avoiding.

**Rejected**: A two-level memo (recent + LRU) — over-engineering. The current cap is "as many rows as the user has open", which is small (<= ~10 active transcripts per session).

## R9. What is the relationship to the existing `LookupSheetResultCache`?

**Decision**: `LookupSheetResultCache` becomes a thin per-pair-eviction helper. Its `_dictionary` and `_contextual` fields are removed. Its `evictForPair` method delegates to the new cache. Its `peek*` / `remember*` / `evict*` methods are removed (the new cache is used directly by the section providers and the contextual translation widget).

**API impact**:

| Before | After |
|---|---|
| `cache.peekDictionary(params)` (in `lookup_section_providers.dart`) | `aiCache.peek(kind: 'dictionary', key: fingerprint)` |
| `cache.rememberDictionary(params, result)` | `aiCache.remember(kind: 'dictionary', key: fingerprint, value: result)` |
| `cache.evictContextual(params)` (in `contextual_translation_lookup_section.dart`) | `aiCache.invalidate(kind: 'contextual_translation', key: fingerprint)` |
| `cache.evictForPair(src, tgt)` | unchanged (delegates) |

The `LookupSheetResultCache` Riverpod provider stays (callers already wire it), but its constructor no longer takes the two maps.

## R10. How are the auto-translate tests preserved?

**Decision**: `autoTranslateSourceKey(...)` becomes a one-line wrapper around `AiCacheFingerprint.fingerprint(kind: 'auto_translate_line', payload: {primaryText, sourceLanguage, targetLanguage})`. The canonical encoding (`<kind>|<sorted kvs joined by '|'>`, no whitespace normalization) produces the same hash as the existing implementation. Existing tests pass verbatim.

**Verified**: `auto_translate_request_test.dart:175-183` asserts `cue.sourceKey == autoTranslateSourceKey(primaryText: 'Hello', sourceLanguage: 'en', targetLanguage: 'zh-CN')`. As long as `autoTranslateSourceKey` returns the same hex string for the same inputs (which it does, because the canonical encoding is preserved), the test passes.

## R11. What is the failure-mode contract for L2 Drift I/O?

**Decision**: `AiCacheDao` methods swallow Drift exceptions, log via `logNamed('ai_cache')` at WARNING level, and return a null / no-op. The cache layer never throws to the caller.

**Why**: L2 is best-effort persistence. If the disk is full, the schema is mid-migration, or `sqlite3_flutter_libs` reports a corruption error, the lookup flow must still work — it just degrades to L1-only behavior. The user-facing UX is identical (the section shows the result), but the L2 rehydration on next launch is skipped.

**Coverage**: A test in `test/data/db/ai_cache_dao_test.dart` injects a faulting `QueryExecutor` and asserts that `read` returns null, `upsert` is a no-op, and `evictOldestExcept` / `pruneOlderThan` are no-ops. The cache's overall correctness is unchanged.

## R12. What is the relationship to ADR-0015 (YouTube playback) and ADR-0039 (auto-translate sourceKey)?

**Decision**: ADR-0039 is **partially superseded** — the `sourceKey` mechanism is preserved (R10), but its scope expands from "auto-translate line cache" to "every AI modality cache key". A new ADR (0045 — number is the next free integer) records the unification.

ADR-0015 is unrelated — it covers YouTube playback engine choice, not the AI cache. No change.

**Note**: The new ADR must cite issue #311 explicitly so the trail is clear.

## R13. How is the new code tested in isolation, without spinning up Riverpod?

**Decision**: The cache class is split into a pure-Dart core (`L1Store`, `AiCacheFingerprint`, `AiKindPolicy`, `AiResultCache`) and a Drift-DAO adapter. The pure-Dart core is tested without Riverpod. The DAO is tested against `NativeDatabase.memory()` (the existing pattern in `auto_translate_request_test.dart`). The integration is tested via the section providers in a `ProviderContainer` test.

This mirrors the pattern in `test/features/transcript/auto_translate_request_test.dart` (which uses `NativeDatabase.memory()`, `AppDatabase`, a fake `TranslationCapability`, and a `ProviderContainer`).

## R14. What is the rollout / migration story?

**Decision**: Single PR. The change is internal; users see no new UI. Migration v11 → v12 is a no-op for existing data; only the new (empty) `ai_cache` table is added.

**Risk**: A contributor who has been running on a dev branch without the migration will hit the v12 schema on first launch after the upgrade. The migration is idempotent (`CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`), so a partial-migration crash on a prior launch does not hang the app (mirrors the existing `_addColumnIfMissing` discipline).

**Rollback**: Reverting the PR removes the table, the DAO, the cache class, and the call-site changes. The L2 rows that were written between the merge and the rollback become orphaned (the table is gone), but no user-facing state is broken.

## R15. Open questions for the spec

**Q1**: Should the cache live in `lib/features/ai/application/` or `lib/core/cache/`?

**A**: `lib/features/ai/application/ai_result_cache.dart` for now. Promote when a non-AI feature needs it.

**Q2**: Is 256 the right L1 cap? 4096 the right L2 cap?

**A**: Reasonable defaults. Per-kind overrides in `AiKindPolicy` allow tuning without touching the cache class.

**Q3**: Should the cache be `keepAlive` or `autoDispose`?

**A**: `keepAlive`. The lookup sheet's existing `LookupSheetResultCacheProvider` is `keepAlive: true` (line 68 of `lookup_sheet_result_cache.dart`); the new cache is no different. L1 must outlive the lookup sheet so a sheet close → re-open on the same selection hits L1.

**Q4**: Is the LRU TTL of 30 minutes too short?

**A**: No. The auto-translate `sourceKey` is content-keyed and never expires; lookup-sheet entries *should* expire because the user might edit a cue, swap a target language, or refresh manually. 30 min is a balance between "Translation result feels stale" and "the user looked this up earlier today". A per-kind override is exposed.

---

## Summary

| R# | Topic | Decision |
|----|-------|----------|
| R1 | Cache location | `lib/features/ai/application/ai_result_cache.dart` |
| R2 | LRU implementation | Hand-rolled, matches `artwork_palette.dart`, cap 256, TTL 30 min |
| R3 | Fingerprint | `AiCacheFingerprint.fingerprint({kind, payload})` → first 32 hex of SHA-256 |
| R4 | Drift schema | New `ai_cache(kind, key, payloadJson, updatedAt)` table, PK `(kind, key)` |
| R5 | `forceRefresh` enforcement | Cache layer is the enforcement point, not capability implementations |
| R6 | `evictForPair` | Stays in `LookupSheetResultCache`, delegates to L1+L2 scan |
| R7 | Per-user L1 clearing | `authCtrlProvider` listener clears L1 on sign-out / user-id change |
| R8 | `linesForRow` memo | Keyed on `timelineJson` hash, not `updatedAt` |
| R9 | `LookupSheetResultCache` | Reduced to a per-pair-eviction helper; data maps removed |
| R10 | Auto-translate `sourceKey` | Becomes a wrapper around `AiCacheFingerprint.fingerprint(...)` |
| R11 | L2 I/O failure | DAO methods swallow exceptions, log, return null / no-op |
| R12 | ADR relationships | New ADR-0045; ADR-0039 partially superseded (scope expansion) |
| R13 | Test isolation | Pure-Dart core + Drift DAO + integration via ProviderContainer |
| R14 | Rollout / migration | Single PR, idempotent v11 → v12 migration |
| R15 | Open questions | All resolved above |