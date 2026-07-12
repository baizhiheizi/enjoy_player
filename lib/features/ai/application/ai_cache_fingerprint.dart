/// Stable, process-portable cache key for any AI modality.
///
/// Canonical encoding: `<kind>|<sorted kvs joined by '|'>`, then SHA-256,
/// first 32 lowercase hex chars. The `kind` prefix prevents cross-modality
/// collisions in the cache hierarchy even if two callers happen to build
/// the same payload by accident.
///
/// See `specs/015-ai-cache-hierarchy/contracts/ai-cache-fingerprint.md`
/// for the full contract.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

class AiCacheFingerprint {
  AiCacheFingerprint._();

  /// Returns the first 32 lowercase hex chars of SHA-256 of the canonical
  /// encoding of [kind] and [payload].
  ///
  /// The canonical encoding is the UTF-8 form of
  /// `<kind>|<sorted kvs joined by '|'>`, where `kvs` are produced by
  /// iterating the payload's keys in alphabetical order and joining
  /// `'<k>=<_canonicalize(v)>'` with `'|'`. Map values are coerced via
  /// `Object.toString()` for primitive scalars (`String` passed verbatim,
  /// no trim).
  ///
  /// Throws [ArgumentError] if [kind] is empty or [payload] contains a
  /// value of an unsupported type.
  static String fingerprint({
    required String kind,
    required Map<String, Object?> payload,
  }) {
    if (kind.isEmpty) {
      throw ArgumentError.value(kind, 'kind', 'kind must not be empty');
    }

    final sortedKeys = payload.keys.toList(growable: false)..sort();
    final parts = <String>[kind];
    for (final key in sortedKeys) {
      parts.add(key);
      parts.add(_canonicalize(payload[key]));
    }
    final canonical = parts.join('|');
    final digest = sha256.convert(utf8.encode(canonical));
    return digest.toString().substring(0, 32);
  }

  static String _canonicalize(Object? value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    if (value is List) {
      return value.map(_canonicalize).join(',');
    }
    if (value is Map) {
      final keys = value.keys.toList(growable: false)..sort();
      final pairs = keys.map((k) => '$k=${_canonicalize(value[k])}');
      return '{${pairs.join(',')}}';
    }
    throw ArgumentError('Unsupported value type: ${value.runtimeType}');
  }
}
