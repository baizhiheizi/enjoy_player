/// Bounded LRU + TTL in-memory key/value store.
///
/// Used as the L1 tier of [AiResultCache]. Lives under `lib/core/cache/`
/// because the primitive is intentionally generic and reusable beyond AI
/// result caching.
///
/// Eviction policy:
///   * LRU: when [put] exceeds [capacity], the least-recently touched
///     entry is evicted.
///   * TTL: when [peek] finds an entry whose age is greater than or equal
///     to [ttl], the entry is treated as a miss and removed. A `null`
///     [ttl] disables age-based expiry — entries leave only via LRU
///     overflow or explicit removal.
library;

import 'dart:collection';

class L1Store<K, V> {
  L1Store({required this.capacity, this.ttl})
    : assert(capacity > 0, 'capacity must be positive'),
      assert(ttl == null || !ttl.isNegative, 'ttl must be non-negative');

  /// Maximum number of entries. The LRU tail is evicted on overflow.
  final int capacity;

  /// Per-entry time-to-live, or `null` for no age-based expiry. Entries
  /// whose age is greater than or equal to this duration are treated as
  /// misses.
  final Duration? ttl;

  final LinkedHashMap<K, _Entry<V>> _map = LinkedHashMap<K, _Entry<V>>();

  /// Returns the cached value for [key], or `null` if absent or expired.
  /// On a fresh hit, the entry's LRU position is updated to MRU. Never
  /// consults the clock when [ttl] is `null`.
  V? peek(K key) {
    final entry = _map[key];
    if (entry == null) return null;
    if (_isExpired(entry)) {
      _map.remove(key);
      return null;
    }
    _map.remove(key);
    _map[key] = entry;
    return entry.value;
  }

  /// Returns the cached value for [key] without touching its LRU position.
  ///
  /// A read-only probe for "do I have this?" checks: unlike [peek] it never
  /// moves an entry to MRU, so probing cannot keep an entry alive or
  /// reorder the eviction queue. Treats expired entries as misses but, also
  /// unlike [peek], leaves them in place for the next [put] / LRU evict to
  /// reclaim. Never consults the clock when [ttl] is `null`.
  V? peekNoTouch(K key) {
    final entry = _map[key];
    if (entry == null) return null;
    return _isExpired(entry) ? null : entry.value;
  }

  bool _isExpired(_Entry<V> entry) {
    final ttl = this.ttl;
    return ttl != null && DateTime.now().difference(entry.createdAt) >= ttl;
  }

  /// Stores [value] under [key]. If the store is at capacity, the LRU
  /// tail is evicted first. Existing entries are overwritten and moved to MRU.
  void put(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    } else if (_map.length >= capacity) {
      final oldestKey = _map.keys.first;
      _map.remove(oldestKey);
    }
    _map[key] = _Entry<V>(value, DateTime.now());
  }

  /// Removes the entry for [key] if present. No-op if absent.
  void invalidate(K key) {
    _map.remove(key);
  }

  /// Removes every entry.
  void clear() {
    _map.clear();
  }

  /// Current number of entries (including expired-but-not-yet-evicted).
  int get size => _map.length;
}

class _Entry<V> {
  const _Entry(this.value, this.createdAt);
  final V value;
  final DateTime createdAt;
}
