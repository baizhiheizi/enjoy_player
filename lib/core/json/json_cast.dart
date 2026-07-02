/// Defensive `Map<String, dynamic>` coercion for decoded JSON.
///
/// `dart:convert`-decoded JSON objects sometimes surface as
/// `Map<dynamic, dynamic>` rather than `Map<String, dynamic>` — e.g. after
/// [package:enjoy_player/data/api/case_conversion.dart] key conversion, or
/// values crossing a platform channel. A naive `is Map<String, dynamic>`
/// check silently drops such maps, so every call site needs the same
/// "accept the fast-path type, else re-key by `.toString()`" coercion.
library;

/// Returns [value] as a `Map<String, dynamic>`, re-keying a
/// `Map<dynamic, dynamic>` via `.toString()` on each key. Returns `null` if
/// [value] is not a [Map] at all (including `null`).
Map<String, dynamic>? castJsonObjectOrNull(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return Map<String, dynamic>.from(
      value.map((k, v) => MapEntry(k.toString(), v)),
    );
  }
  return null;
}

/// Same as [castJsonObjectOrNull], but throws a [FormatException] instead of
/// returning `null` when [value] is not a JSON object.
Map<String, dynamic> castJsonObject(Object? value) {
  final map = castJsonObjectOrNull(value);
  if (map == null) {
    throw FormatException('Expected JSON object, got ${value.runtimeType}');
  }
  return map;
}
