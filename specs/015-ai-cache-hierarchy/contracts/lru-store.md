# Contract: `L1Store<K, V>` (in-memory LRU + TTL)

**Feature**: [spec.md](../spec.md) | **Date**: 2026-07-13

This document specifies the in-memory LRU + TTL primitive that backs the L1 tier of `AiResultCache`. The primitive is generic over `K` and `V` and lives in `lib/core/cache/lru_store.dart` because it is reused by future caches (e.g. an LRU for AI image generation metadata).

---

## Signature

```dart
class L1Store<K, V> {
  /// Creates a new store. [capacity] is the maximum number of entries; the
  /// LRU tail is evicted on overflow. [ttl] is the per-entry time-to-live;
  /// entries older than [ttl] from their insertion time are treated as
  /// misses.
  L1Store({required int capacity, required Duration ttl})
      : assert(capacity > 0, 'capacity must be positive'),
        assert(!ttl.isNegative, 'ttl must be non-negative');

  /// Returns the cached value for [key], or null if absent or expired.
  /// On hit, the entry's LRU position is updated to MRU.
  V? peek(K key);

  /// Stores [value] under [key]. Evicts the LRU tail if the store is at
  /// capacity. Updates the entry's LRU position to MRU.
  void put(K key, V value);

  /// Removes the entry for [key] if present. No-op if absent.
  void invalidate(K key);

  /// Removes every entry.
  void clear();

  /// Current number of entries (including expired-but-not-yet-evicted).
  int get size;

  /// The configured capacity.
  int get capacity;

  /// Visits every (key, value) pair in MRU → LRU order. Expired entries
  /// are visited but the caller can choose to skip them; this method does
  /// not auto-evict (auto-eviction happens lazily on the next `peek` or
  /// `put`).
  void forEach(void Function(K key, V value) visit);
}
```

---

## Eviction Policy

**LRU**: On `put`, if the store is at capacity, the LRU tail (the entry that has been least-recently touched by `peek` or `put`) is evicted before the new entry is inserted.

**TTL**: On `peek`, if the entry's `createdAt + ttl < now`, the entry is treated as a miss and removed. The TTL clock is `DateTime.now()` at `peek` time.

**TTL + capacity interaction**:
- `put` does NOT pre-check TTL for existing entries (it just overwrites).
- `peek` evicts expired entries lazily (on read miss).
- `size` includes expired-but-not-yet-evicted entries. A periodic `pruneExpired` (NOT part of this contract — call sites can iterate) is the maintenance path.

---

## Implementation Sketch

```dart
class L1Store<K, V> {
  L1Store({required this.capacity, required this.ttl})
      : assert(capacity > 0, 'capacity must be positive'),
        assert(!ttl.isNegative, 'ttl must be non-negative');

  final int capacity;
  final Duration ttl;

  final LinkedHashMap<K, _Entry<V>> _map = LinkedHashMap();
  // LinkedHashMap iterates in insertion order; we use `remove` + `put` to
  // move an entry to the tail (MRU).

  V? peek(K key) {
    final entry = _map[key];
    if (entry == null) return null;
    final now = DateTime.now();
    if (now.difference(entry.createdAt) > ttl) {
      _map.remove(key);
      return null;
    }
    // Move to MRU.
    _map.remove(key);
    _map[key] = entry;
    return entry.value;
  }

  void put(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    } else if (_map.length >= capacity) {
      // Evict LRU tail.
      final oldestKey = _map.keys.first;
      _map.remove(oldestKey);
    }
    _map[key] = _Entry(value, DateTime.now());
  }

  void invalidate(K key) {
    _map.remove(key);
  }

  void clear() {
    _map.clear();
  }

  int get size => _map.length;

  void forEach(void Function(K, V) visit) {
    for (final entry in _map.entries) {
      visit(entry.key, entry.value);
    }
  }
}

class _Entry<V> {
  _Entry(this.value, this.createdAt);
  final V value;
  final DateTime createdAt;
}
```

`LinkedHashMap` is the standard Dart collection that preserves insertion order. Removing and re-inserting is O(1) and is the standard Dart idiom for "move to MRU".

---

## Behaviors

| Behavior | Test |
|----------|------|
| `put` then `peek` returns the value | `peek_returns_cached_value` |
| `peek` on absent key returns null | `peek_returns_null_on_miss` |
| `put` past capacity evicts the LRU tail | `lru_evicts_oldest_on_overflow` |
| `peek` after TTL elapses returns null and removes the entry | `peek_returns_null_after_ttl` |
| `clear` drops every entry | `clear_drops_all_entries` |
| `invalidate` removes a single entry | `invalidate_removes_entry` |
| `peek` updates LRU position (so a subsequent peek-after-overflow keeps the entry) | `peek_updates_lru_position` |
| `size` returns the number of entries | `size_returns_count` |
| Negative or zero capacity throws `AssertionError` | `capacity_must_be_positive` |

---

## Performance

| Operation | Complexity |
|-----------|------------|
| `peek` | O(1) |
| `put` (with eviction) | O(1) |
| `invalidate` | O(1) |
| `clear` | O(n) |
| `forEach` | O(n) |

For the AI cache use case (`n <= 256`), even O(n) operations are sub-microsecond.

---

## Thread Safety

`L1Store` is single-threaded (main isolate). Drift's SQL runs on a background isolate; the cache layer marshals L1 mutations to the main isolate (no explicit marshal — every L1 mutation is already on the main isolate because the call sites are widget callbacks or Riverpod provider builds).

---

## Reuse Beyond the AI Cache

The `L1Store` primitive is intentionally generic. Future callers (e.g. an LRU for AI image generation metadata, an LRU for ASR hot-paths) can adopt it without depending on `AiResultCache`. This is why the file lives in `lib/core/cache/` rather than `lib/features/ai/application/`.