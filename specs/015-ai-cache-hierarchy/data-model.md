# Data Model: AI Result Cache Hierarchy (issue #311)

**Feature**: [spec.md](spec.md) | **Date**: 2026-07-13

This change introduces **one new Drift table**, **one new DAO**, **one new abstract cache class**, **one new fingerprint helper**, **one new LRU+TTL in-memory store**, and small edits to **two existing classes** (`LookupSheetResultCache`, `transcript_repository.dart`'s `linesForRow` memo).

The model is intentionally narrow — every entity has a single purpose, no entity is a god-class, and the storage layer is the only place that touches SQLite.

---

## Entities

### `AiCacheRow` (new Drift row)

A single cached AI result, scoped to a `(kind, key)` pair.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `kind` | `TEXT NOT NULL` | part of PK | Discriminator that prevents cross-modality collisions. Examples: `"translation"`, `"dictionary"`, `"contextual_translation"`, `"auto_translate_line"`. |
| `key` | `TEXT NOT NULL` | part of PK | 32-char hex fingerprint from `AiCacheFingerprint.fingerprint(...)`. |
| `payloadJson` | `TEXT NOT NULL` | — | JSON-encoded result (the value cached). Type-erased; the cache layer decodes back to the concrete Dart type. |
| `updatedAt` | `INTEGER NOT NULL` | indexed (with `kind`) | Milliseconds since epoch (Drift convention). Used by `evictOldestExcept` and `pruneOlderThan`. |

**Primary key**: `(kind, key)`.

**Index**: `(kind, updatedAt DESC)` for cheap LRU eviction and age cutoff queries.

**Storage path**: same `enjoy_player.sqlite` (or per-user `enjoy_player_<userId>.sqlite`) as every other table. The cache layer treats L2 as scoped to the active `AppDatabase`.

**Validation**: `kind` MUST be one of the `AiKind` enum values (`translation`, `dictionary`, `contextual_translation`, `auto_translate_line`); a new modality adds a new enum value. `key` MUST be 32 lowercase hex chars. `payloadJson` MUST be valid JSON that round-trips through `jsonDecode` / `jsonEncode`.

**Module path**: `lib/data/db/tables/ai_cache.dart`.

---

### `AiCacheDao` (new Drift accessor)

The only path that reads or writes `ai_cache`. All methods swallow Drift exceptions, log via `logNamed('ai_cache')`, and return `null` / no-op on failure (so the cache layer never throws).

| Method | Signature | Behavior |
|--------|-----------|----------|
| `read` | `Future<AiCacheRow?> read(String kind, String key)` | Single-row lookup. Returns `null` on miss or on Drift error. |
| `upsert` | `Future<void> upsert(String kind, String key, String payloadJson, DateTime updatedAt)` | `INSERT OR REPLACE`. No-op on Drift error. |
| `delete` | `Future<void> delete(String kind, String key)` | Single-row delete. No-op if missing or on Drift error. |
| `evictOldestExcept` | `Future<int> evictOldestExcept(String kind, int keep)` | For `kind`, keep the `keep` most-recent `updatedAt` rows; delete the rest. Returns deleted count (best-effort, may be `-1` on error). |
| `pruneOlderThan` | `Future<int> pruneOlderThan(String kind, DateTime cutoff)` | For `kind`, delete every row whose `updatedAt < cutoff`. Returns deleted count. |
| `deleteForKind` | `Future<void> deleteForKind(String kind)` | Drops every row for `kind`. Used by tests + the kind-policy migration path. |
| `readAllForKind` | `Stream<List<AiCacheRow>> readAllForKind(String kind)` | Watch helper, used by tests and the diagnostic dump command. |

**Module path**: `lib/data/db/app_database.dart` (next to the existing DAOs) OR `lib/data/db/ai_cache_dao.dart` if the file grows. Decision recorded in the plan.

---

### `AiResultCache<K, V>` (new abstract cache)

The two-tier cache. One instance per app, `keepAlive: true` via a Riverpod provider.

| Field | Type | Description |
|-------|------|-------------|
| `_l1` | `L1Store<String, Object>` | Bounded LRU + TTL in-memory map. Synchronous. |
| `_l2` | `AiCacheDao` | Drift DAO. Asynchronous. |
| `_policies` | `Map<AiKind, AiKindPolicy>` | Per-kind TTL, L2 row cap, L2 row age cutoff. |
| `_lock` | `Future<void>` (chain) | Serializes L2 writes so concurrent upserts cannot race during eviction. |

**Public API**:

| Method | Signature | Notes |
|--------|-----------|-------|
| `peek` | `V? peek({required AiKind kind, required String key})` | L1 only; synchronous. Returns null on miss / TTL expiry. |
| `lookup` | `Future<V> lookup({required AiKind kind, required String key, required Future<V> Function() loader, bool forceRefresh = false})` | L1 → L2 → loader chain. `forceRefresh` busts L1+L2 for the key before the loader runs. |
| `remember` | `Future<void> remember({required AiKind kind, required String key, required V value})` | Writes L1 (synchronously) and L2 (asynchronously; failure is logged, not thrown). |
| `invalidate` | `Future<void> invalidate({required AiKind kind, required String key})` | Removes from L1 + L2. |
| `evictForPair` | `Future<void> evictForPair({required String sourceLanguage, required String targetLanguage})` | L1 + L2 scan for entries whose decoded payload contains the pair. |
| `clear` | `Future<void> clear()` | Drops L1 + every L2 row. Used on sign-out. |
| `prune` | `Future<void> prune()` | For each known `kind`, apply `evictOldestExcept(policy.l2RowCap)` and `pruneOlderThan(policy.l2AgeCutoff)`. Called at startup. |

**Encoding**: the value `V` is encoded to JSON via the existing `jsonEncode` / `jsonDecode` pattern used in `transcript_line.dart`. Each cached result type (`TranslationResult`, `DictionaryResult`, `ContextualTranslationResult`, etc.) already has a `fromJson` factory or freezed-generated `fromJson`; the cache layer uses those.

**Module path**: `lib/features/ai/application/ai_result_cache.dart`.

---

### `AiKind` (enum)

The discriminator used as the SQL column and the cache key namespace.

```dart
enum AiKind {
  translation('translation'),
  dictionary('dictionary'),
  contextualTranslation('contextual_translation'),
  autoTranslateLine('auto_translate_line');

  const AiKind(this.wire);
  final String wire;
}
```

**Why an enum**: keeps the wire string (`translation`, etc.) and the Dart type linked, and prevents typos at call sites. A new modality adds one enum value.

**Module path**: `lib/features/ai/domain/ai_kind.dart` (next to the existing `modality_kind.dart`).

---

### `AiKindPolicy` (per-kind config)

| Field | Type | Description |
|-------|------|-------------|
| `ttl` | `Duration` | L1 entry TTL. Default 30 min. |
| `l2RowCap` | `int` | Per-kind L2 row cap. Default 4096. |
| `l2AgeCutoff` | `Duration` | Per-kind L2 row age cutoff. Default 30 days. |

**Defaults** (in `ai_kind_policies.dart`):

| Kind | TTL | L2 row cap | L2 age cutoff |
|---|---|---|---|
| `translation` | 30 min | 4096 | 30 d |
| `dictionary` | 30 min | 4096 | 30 d |
| `contextualTranslation` | 30 min | 2048 | 14 d |
| `autoTranslateLine` | ∞ (no L1 TTL — content-keyed) | 8192 | ∞ |

The auto-translate line kind has no L1 TTL because the content key already enforces staleness; an L1 TTL would force a re-translation of every line on session restart, which is precisely the regression we're fixing.

**Module path**: `lib/features/ai/application/ai_kind_policies.dart`.

---

### `AiCacheFingerprint` (pure helper)

```dart
class AiCacheFingerprint {
  /// First 32 hex chars of SHA-256(canonicalUtf8(kind, payload)).
  static String fingerprint({
    required String kind,
    required Map<String, Object?> payload,
  });
}
```

**Canonical encoding**: `<kind>|<sorted kvs joined by '|'>`. The payload map's keys are sorted alphabetically; values are coerced to `String` via `Object.toString()` for non-string scalars (numbers, bools, null) and inserted verbatim for strings (no trim — whitespace matters for cache invalidation; the auto-translate path normalizes before calling).

**Worked example**: `fingerprint(kind: 'auto_translate_line', payload: {'primaryText': 'Hello', 'sourceLanguage': 'en', 'targetLanguage': 'zh-CN'})` → canonical `auto_translate_line|Hello|en|zh-CN` → SHA-256 hex, first 32 chars. **This matches** the existing `autoTranslateSourceKey(...)` output for the same inputs because the canonical encoding is the same string the current implementation hashes.

**Module path**: `lib/features/ai/application/ai_cache_fingerprint.dart`.

---

### `L1Store<K, V>` (in-memory LRU + TTL)

| Field | Type | Description |
|-------|------|-------------|
| `_capacity` | `int` | Maximum entries. |
| `_ttl` | `Duration` | Per-entry TTL. |
| `_map` | `Map<K, _Entry<V>>` | Insertion-ordered (`LinkedHashMap`) — newest at the tail. |
| `_order` | `List<K>` | Mirror list, used for O(1) tail eviction. |

**Public API**: `peek(K)`, `put(K, V)`, `invalidate(K)`, `invalidateAll()`, `clear()`, `size`, `forEach`.

**Eviction**: when `put` exceeds capacity, remove the head of `_order`. When `peek` finds an entry whose age is greater than or equal to its TTL (`now - createdAt >= ttl`), remove it and return null. A zero TTL expires immediately on read.

**Module path**: `lib/core/cache/lru_store.dart` — promoted to `core/` because the LRU is a generic primitive reused outside the AI cache (e.g. a future thumbnail LRU could adopt it). Decision recorded in the plan.

---

### `LookupSheetResultCache` (existing class, slimmed down)

**Before**:
- `_contextual` map (unbounded)
- `_dictionary` map (unbounded)
- `peekContextual` / `rememberContextual` / `evictContextual`
- `peekDictionary` / `rememberDictionary` / `evictDictionary`
- `evictForPair`

**After**:
- (no internal maps)
- `evictForPair` — delegates to the new `AiResultCache.evictForPair`
- A `keepAlive: true` Riverpod provider that returns this thin wrapper

**Call-site changes**:
- `lookup_section_providers.dart` no longer reads `lookupSheetResultCacheProvider`; it reads `aiResultCacheProvider` and calls `aiResultCache.lookup(...)`.
- `contextual_translation_lookup_section.dart` similarly reads `aiResultCacheProvider` and calls `aiResultCache.invalidate(...)` on `forceRefresh`.

**Module path**: `lib/features/lookup/application/lookup_sheet_result_cache.dart` (unchanged).

---

### `transcript_repository.dart` `_linesCache` (existing, improved)

**Before**:
```dart
final Map<String, _LinesCacheEntry> _linesCache = {};
List<TranscriptLine> linesForRow(TranscriptRow row) {
  final hit = _linesCache[row.id];
  if (hit != null && hit.updatedAt == row.updatedAt) return hit.lines;
  // re-decode
}
```

**After**:
```dart
final Map<String, _LinesCacheEntry> _linesCache = {};
List<TranscriptLine> linesForRow(TranscriptRow row) {
  final hit = _linesCache[row.id];
  final hash = _timelineJsonHash(row.timelineJson);
  if (hit != null && hit.timelineJsonHash == hash) return hit.lines;
  // re-decode
}
```

where `_LinesCacheEntry` becomes `(timelineJsonHash, lines)` and `_timelineJsonHash(timelineJson)` returns the first 16 hex chars of `sha1.convert(utf8.encode(timelineJson))`. SHA-1 is sufficient here — collision risk at the practical cache size (~10 active transcripts per session, ~256 chars per timeline JSON) is negligible.

**Module path**: `lib/features/transcript/data/transcript_repository.dart` (unchanged).

---

## State Transitions

The cache introduces **one new state transition** — the lookup-or-remember flow:

```
Caller calls aiCache.lookup(kind, key, loader, forceRefresh: false)
        │
        ▼
[L1.peek(kind, key)]
        │
   ┌────┴────┐
hit │         │ miss
   ▼         ▼
return V   [L2.read(kind, key)]
            │
       ┌────┴────┐
   hit │         │ miss
       ▼         ▼
   backfill L1   [loader()]
   return V      │
                  ▼
              remember L1 (sync)
              remember L2 (async, fire-and-forget; failure logged)
              return V
```

For `forceRefresh: true`:
```
[aiCache.lookup(kind, key, loader, forceRefresh: true)]
        │
        ▼
[L1.invalidate(kind, key)] (sync)
[L2.delete(kind, key)] (async, awaited so subsequent L2 read returns null)
        │
        ▼
[loader()]
        │
        ▼
[remember L1 + L2] (same as above)
return V
```

The `forceRefresh: true` path **awaits** the L2 delete before calling the loader, so a stale L2 read cannot race the bust. (For `forceRefresh: false`, the L2 read is the *intended* path.)

---

## Database Changes

**One new table**, registered in `AppDatabase` at `schemaVersion: 12`:

```dart
@DriftDatabase(
  tables: [
    // ... existing tables
    AiCache,  // NEW
  ],
  daos: [
    // ... existing DAOs
    AiCacheDao,  // NEW
  ],
)
```

**Migration** (`AppDatabase._runMigrations`):
```dart
} else if (next == 12) {
  await m.database.customStatement(
    'CREATE TABLE IF NOT EXISTS ai_cache ('
    'kind TEXT NOT NULL, '
    'key TEXT NOT NULL, '
    'payload_json TEXT NOT NULL, '
    'updated_at INTEGER NOT NULL, '
    'PRIMARY KEY (kind, key))',
  );
  await m.database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_ai_cache_kind_updated_at '
    'ON ai_cache (kind, updated_at DESC)',
  );
}
```

Idempotent (`IF NOT EXISTS`) so a partial-migration crash on a previous launch does not hang the app, mirroring the `_addColumnIfMissing` discipline.

**Backfill**: none. The table starts empty. Existing data (transcripts, settings, etc.) is untouched.

---

## Localization

No new user-facing strings. The cache is internal.

---

## Telemetry

No new telemetry. Cache hit / miss events are logged via `logNamed('ai_cache')` at INFO level (e.g. `ai_cache miss kind=translation key=d8a4f... src=en tgt=es`), which the existing diagnostic logs (`docs/features/diagnostics.md`) already surface.