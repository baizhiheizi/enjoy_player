# Contract: `AiResultCache<K, V>` Public API

**Feature**: [spec.md](../spec.md) | **Date**: 2026-07-13

This document specifies the public API of the new `AiResultCache<K, V>` abstraction. It is the contract every call site depends on. The contract is enforced by tests in `test/features/ai/ai_result_cache_test.dart` and the integration tests under `test/features/lookup/` and `test/features/transcript/`.

---

## Type Signatures

```dart
// Generic cache. V is the cached result type; the cache is type-erased at L2
// (JSON-serialized) but type-safe at the call site (the loader returns V, the
// peek/lookup methods return V).
class AiResultCache<K, V> {
  AiResultCache({
    required AiCacheDao dao,
    required L1Store<String, V> l1,
    required Map<AiKind, AiKindPolicy> policies,
    Logger? logger,
  });

  /// L1-only synchronous read. Returns null on miss or TTL expiry.
  V? peek({required AiKind kind, required String key});

  /// L1 → L2 → loader chain. forceRefresh busts L1+L2 for the key before
  /// invoking the loader. Returns the loader's value (or the cached value on
  /// a non-forceRefresh hit). NEVER throws — L2 I/O failures degrade to
  /// "miss" and the loader is called.
  Future<V> lookup({
    required AiKind kind,
    required String key,
    required Future<V> Function() loader,
    bool forceRefresh = false,
  });

  /// Writes to L1 (sync) and L2 (async, fire-and-forget; failure logged).
  /// Returns when L1 write completes; L2 write may still be in flight when
  /// this Future resolves.
  Future<void> remember({
    required AiKind kind,
    required String key,
    required V value,
  });

  /// Removes the entry from L1 and L2. No-op if the key is not cached.
  Future<void> invalidate({required AiKind kind, required String key});

  /// Removes every entry whose decoded JSON payload contains
  /// sourceLanguage == X && targetLanguage == Y. Scans L1 synchronously
  /// and L2 via SQL LIKE on payloadJson.
  Future<void> evictForPair({
    required String sourceLanguage,
    required String targetLanguage,
  });

  /// Drops L1 entirely and every L2 row. Used on sign-out / user-id change.
  Future<void> clear();

  /// For each kind in `policies`, applies the L2 row cap and age cutoff.
  /// Called at startup (best-effort).
  Future<void> prune();

  /// Read-only diagnostics. Returns the current L1 size, L1 cap, and a
  /// snapshot of L2 row counts per kind.
  AiCacheStats stats();
}

class AiCacheStats {
  final int l1Size;
  final int l1Capacity;
  final Map<AiKind, int> l2RowCounts;
}

enum AiKind {
  translation('translation'),
  dictionary('dictionary'),
  contextualTranslation('contextual_translation'),
  autoTranslateLine('auto_translate_line');

  const AiKind(this.wire);
  final String wire;
}

class AiKindPolicy {
  const AiKindPolicy({
    required this.ttl,
    required this.l2RowCap,
    required this.l2AgeCutoff,
  });

  final Duration ttl;
  final int l2RowCap;
  final Duration l2AgeCutoff;
}
```

---

## Behaviors

### `peek`

**Preconditions**: none.

**Postconditions**:
- Returns the cached value if L1 has an unexpired entry for `(kind, key)`.
- Returns `null` otherwise (L1 miss, L1 TTL expiry, or unknown `kind`/`key`).
- Does NOT touch L2.
- Does NOT update LRU position (peek is read-only).

**Side effects**: none.

**Performance**: O(1) — `Map.get` + a TTL check.

---

### `lookup` (the main API)

**Preconditions**:
- `loader` MUST be a `Future<V> Function()`. It MAY throw; the exception propagates to the caller (the cache does not swallow loader errors).
- `forceRefresh: true` is honored identically for the Enjoy / worker path and the BYOK path.

**Postconditions** (when `forceRefresh: false`):

1. If L1 has an unexpired entry for `(kind, key)`, return it. Done.
2. Else, `await dao.read(kind, key)`.
   - If L2 has an entry, decode it, write it back to L1, and return it.
   - If L2 misses (or DAO errors), proceed.
3. Call `loader()`.
4. On success, `remember(kind, key, result)` and return the result.
5. On loader failure, propagate the exception. L1 and L2 are NOT modified.

**Postconditions** (when `forceRefresh: true`):

1. Synchronously remove `(kind, key)` from L1.
2. Await `dao.delete(kind, key)` so a subsequent L2 read returns null.
3. Call `loader()`.
4. On success, `remember(kind, key, result)` and return the result.
5. On loader failure, propagate the exception. L1 and L2 remain cleared.

**Side effects**:
- L1 is updated (write-through on hit/miss → L1 backfill).
- L2 may be updated (write-through on miss → L2 upsert).
- LRU position of L1 entries is updated on hit (the touched entry moves to MRU).

**Concurrency**:
- Multiple concurrent `lookup` calls for the same `(kind, key)` MAY each invoke the loader. The cache does not deduplicate in-flight loaders. (Callers that need dedup can wrap the loader; the cache is a primitive.)
- `_lock` serializes L2 writes so a concurrent `remember` + `prune` cannot race during eviction.

**Performance**:
- L1 hit: O(1) synchronous + a Future wrapper. Sub-microsecond.
- L1 miss + L2 hit: O(1) Drift SELECT + JSON decode. Sub-millisecond on `NativeDatabase.memory()`.
- L1 miss + L2 miss: as fast as the loader + one Drift INSERT.

---

### `remember`

**Preconditions**: `value` MUST be JSON-encodable (every field is a primitive, list, map, or null).

**Postconditions**:
- L1 is updated synchronously with `value`. Existing entry is overwritten (LRU position reset to MRU).
- L2 is updated asynchronously (`dao.upsert(...)`). Failure is logged via `logNamed('ai_cache')` at WARNING level; not thrown.

**Side effects**:
- L1 capacity is enforced: if `peek → put` would exceed capacity, the LRU tail is evicted.
- L2 row cap is NOT enforced here (it is enforced by `prune`, called at startup). This is intentional — `remember` is the hot path; the row cap is a maintenance concern.

**Performance**:
- L1 write: O(1).
- L2 write: `INSERT OR REPLACE` on `(kind, key)` PK. Sub-millisecond on `NativeDatabase.memory()`.

---

### `invalidate`

**Postconditions**:
- L1 entry for `(kind, key)` is removed synchronously.
- L2 row for `(kind, key)` is removed asynchronously. Failure is logged.

**Side effects**: none beyond the removals.

---

### `evictForPair`

**Postconditions**:
- Every L1 entry whose decoded JSON contains `sourceLanguage == X && targetLanguage == Y` is removed.
- Every L2 row matching the same criterion is removed.

**Implementation note**:
- L1: synchronous scan (`_l1.forEach(...)`). O(n) in L1 size.
- L2: SQL `SELECT kind, key FROM ai_cache WHERE payload_json LIKE '%"sourceLanguage":"X"%' AND payload_json LIKE '%"targetLanguage":"Y"%'`, then `DELETE` per row in a transaction.

**Side effects**: none beyond the removals.

**Performance**:
- L1 scan: at 256 entries, sub-millisecond.
- L2 LIKE scan: at 4096 rows per kind × 3 kinds, sub-50ms p95 on `NativeDatabase.memory()`. (Test asserts the bound.)

---

### `clear`

**Postconditions**:
- L1 is dropped synchronously.
- L2 is dropped via `dao.deleteForKind(kind)` for every kind in `_policies`.

**Side effects**: none beyond the removals.

**Concurrency**: safe to call concurrently with `lookup` / `remember`. The Riverpod provider's `authCtrlProvider` listener calls `clear()` on sign-out; an in-flight `lookup` may complete against the cleared state (its result is just not cached).

---

### `prune`

**Postconditions**:
- For each `(kind, policy)` in `_policies`:
  - `dao.evictOldestExcept(kind, policy.l2RowCap)` is awaited.
  - `dao.pruneOlderThan(kind, DateTime.now() - policy.l2AgeCutoff)` is awaited.

**Side effects**: as described.

**Called from**: the cache provider's `ref.onDispose` (no — it's startup-only, called explicitly from `_AiResultCacheProvider.build`).

---

### `stats`

**Postconditions**: returns a snapshot of L1 size, L1 capacity, and L2 row counts per kind. Read-only; does not touch L1 or L2.

**Used by**: the diagnostic dump command (existing `docs/features/diagnostics.md`), the cache health widget on the settings page (out of scope for this PR but designed-in).

---

## Error Contracts

| Failure | Behavior |
|---------|----------|
| L2 Drift I/O error | `dao.read` returns null; `dao.upsert` / `dao.delete` / `dao.evictOldestExcept` / `dao.pruneOlderThan` are no-ops. All failures are logged via `logNamed('ai_cache')` at WARNING level. The cache layer NEVER throws to the caller (except for loader-thrown exceptions, which propagate). |
| Loader throws | Exception propagates. L1 and L2 are NOT modified. |
| `peek` on an unknown `kind` | Returns null. No error. |
| `remember` with a non-JSON-encodable value | `jsonEncode` throws `JsonUnsupportedObjectError`. Propagates to the caller. (This is a programmer error and SHOULD be loud.) |

---

## Thread / Isolate Safety

- The cache is designed for the main isolate. L1 reads/writes happen on the main thread.
- L2 (Drift) runs on a background isolate (existing pattern; `drift_flutter` isolates SQL). Drift handles cross-isolate messaging transparently.
- L1 mutation on the main thread + L2 mutation on a Drift isolate cannot race within a single `lookup` call because the L1 mutation happens *before* the async L2 write is fired.

---

## Versioning

- `AiResultCache` is at v1.0.0. Breaking changes (signature changes, behavior changes) require a major version bump and an ADR.
- Adding a new `AiKind` value is NOT a breaking change — existing kinds' policies are unchanged.
- Adding a new field to `AiKindPolicy` is NOT a breaking change — default values are provided.

---

## Test Coverage (mandatory per FR-017)

| Behavior | Test |
|----------|------|
| L1 hit skips loader | `lookup_returns_l1_hit_without_calling_loader` |
| L1 miss + L2 hit returns persisted and backfills L1 | `lookup_returns_l2_hit_and_backfills_l1` |
| L1 + L2 miss calls loader and writes both | `lookup_writes_l1_and_l2_on_miss` |
| LRU eviction at capacity | `l1_evicts_lru_tail_on_overflow` |
| TTL expiry | `l1_returns_null_after_ttl` |
| `forceRefresh` busts both tiers | `force_refresh_clears_l1_and_l2` |
| Key collision avoided across `kind`s | `kinds_do_not_collide` |
| L2 Drift row cap | `l2_evicts_oldest_when_cap_exceeded` |
| L2 Drift age cutoff | `l2_prunes_rows_older_than_cutoff` |
| `evictForPair` clears the right entries | `evict_for_pair_clears_matching_entries` |
| `linesForRow` memo invalidates on `timelineJson` change but not `updatedAt` | `lines_for_row_memo_skips_redecode_on_updated_at_only` |
| Sign-out clear | `clear_drops_l1_and_l2_on_sign_out` |