/// Stable locator JSON for vocabulary context IDs (web id-generator parity).
library;

import 'dart:convert';

import 'vocabulary_models.dart';

/// Matches web `JSON.stringify(locator, Object.keys(locator).sort())`.
///
/// For [MediaLocator] keys order is always `duration`, `start`, `type`.
String stableLocatorJson(MediaLocator locator) =>
    '{"duration":${locator.duration},"start":${locator.start},"type":"media"}';

/// Stable JSON for an [EbookLocator] (sorted top-level keys, nested as-is).
String stableEbookLocatorJson(EbookLocator locator) {
  final map = locator.toJson();
  final keys = map.keys.toList()..sort();
  final ordered = <String, Object?>{for (final k in keys) k: map[k]};
  return jsonEncode(ordered);
}

/// Encode a media or ebook locator for a Drift text column.
String encodeLocatorForDb({MediaLocator? media, EbookLocator? ebook}) {
  if (media != null) return jsonEncode(media.toJson());
  if (ebook != null) return jsonEncode(ebook.toJson());
  throw ArgumentError('Either media or ebook locator is required');
}

/// Decode a Drift locator text column into media or ebook.
({MediaLocator? media, EbookLocator? ebook}) decodeLocatorFromDb(String json) {
  final map = jsonDecode(json) as Map<String, dynamic>;
  final typed = Map<String, Object?>.from(map);
  final type = typed['type'];
  if (type == MediaLocator.type) {
    return (media: MediaLocator.fromJson(typed), ebook: null);
  }
  if (type == EbookLocator.type) {
    return (media: null, ebook: EbookLocator.fromJson(typed));
  }
  throw FormatException('Unknown locator type: $type');
}
