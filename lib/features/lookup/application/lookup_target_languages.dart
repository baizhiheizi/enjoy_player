/// Resolves BCP-47 tags for transcript lookup + worker AI calls.
library;

import 'package:enjoy_player/core/application/app_language_catalog.dart';

/// Source language from transcript track, or [learningTag] when invalid/unsupported.
///
/// Recognizes any tag in [kSupportedLookupLanguageTags] (full match or primary-
/// subtag match, e.g. `ja` → `ja-JP`, `ko-KR` → `ko-KR`) so non-en/zh tracks
/// are correctly identified. Falls back to [learningTag] for `und` / empty /
/// unsupported / denylisted primaries.
String resolveLookupSource(
  String? transcriptLanguage, {
  required String learningTag,
}) {
  // Narrow path: en/zh short-circuit preserves existing en-US / zh-CN behavior.
  final canonical = canonicalLookupTag(transcriptLanguage);
  if (canonical != null) return canonical;

  // Lookup catalog: handle non-en/zh tracks (Korean, Japanese, German, etc.).
  if (transcriptLanguage != null) {
    final trimmed = transcriptLanguage.trim();
    if (trimmed.isNotEmpty && isValidLanguageTag(trimmed)) {
      final normalized = normalizeBcp47Tag(trimmed);
      // Direct match (e.g. ko-KR → ko-KR).
      for (final supported in kSupportedLookupLanguageTags) {
        if (tagsEqual(normalized, supported)) return supported;
      }
      // Primary-subtag match (e.g. ja → ja-JP, de → de-DE).
      final primary = _primarySubtagOnly(normalized);
      for (final supported in kSupportedLookupLanguageTags) {
        if (_primarySubtagOnly(supported) == primary) return supported;
      }
    }
  }
  return normalizeBcp47Tag(learningTag);
}

/// Validates a user-picked source-language override from inside the sheet.
/// Returns `null` when the override is empty / whitespace / denylisted; callers
/// should fall back to [resolveLookupSource] when null is returned.
///
/// Recognizes lookup-catalog tags (full or primary-subtag match, e.g. `ja` →
/// `ja-JP`, `ko-KR` → `ko-KR`, `kor` → `ko-KR`) so a user picking a primary-
/// subtag or legacy alias still gets a fully canonical tag.
String? resolveLookupSourceOverride(String? override) {
  if (override == null) return null;
  final trimmed = override.trim();
  if (trimmed.isEmpty) return null;
  if (!isValidLanguageTag(trimmed)) return null;
  final normalized = normalizeBcp47Tag(trimmed);
  // Direct match (e.g. ko-KR → ko-KR, ja-JP → ja-JP).
  for (final supported in kSupportedLookupLanguageTags) {
    if (tagsEqual(normalized, supported)) return supported;
  }
  // Primary-subtag match (e.g. ja → ja-JP, kor → ko-KR).
  final primary = _primarySubtagOnly(normalized);
  for (final supported in kSupportedLookupLanguageTags) {
    if (_primarySubtagOnly(supported) == primary) return supported;
  }
  return null;
}

String _primarySubtagOnly(String tag) =>
    normalizeLanguageAlias(tag).split(RegExp(r'[-_]')).first.toLowerCase();

/// Native / UI target: canonical supported tag, or coerced when equal to learning / invalid.
///
/// Resolution order:
/// 1. Direct lookup catalog match (e.g. native = `ja-JP` → `ja-JP`).
/// 2. Existing narrow path (en-US / zh-CN canonical).
/// 3. Primary-subtag fallback against the lookup catalog (e.g. `de-AT` → `de-DE`),
///    skipping source and learning.
/// 4. Legacy `coerceNativeIfEqualsLearning` so existing en-US / zh-CN users
///    with null / empty native see zero behavior change.
String resolveLookupTarget(
  String? nativeLanguage, {
  required String learningTag,
  String? sourceLanguage,
}) {
  final learn = normalizeBcp47Tag(learningTag);
  final src = sourceLanguage != null
      ? normalizeBcp47Tag(sourceLanguage)
      : null;
  final supported = kSupportedLookupLanguageTags;
  final normalized = nativeLanguage == null || nativeLanguage.trim().isEmpty
      ? null
      : normalizeBcp47Tag(nativeLanguage);

  // 1. Direct lookup catalog match.
  if (normalized != null &&
      supported.contains(normalized) &&
      !tagsEqual(normalized, learn)) {
    return normalized;
  }

  // 2. Narrow path (preserves en-US / zh-CN canonical).
  final canonical = canonicalLookupTag(nativeLanguage);
  if (canonical != null && !tagsEqual(canonical, learn)) {
    return canonical;
  }

  // 3. Primary-subtag fallback (e.g. de-AT → de-DE), skipping source / learning.
  //    Only when native is not equal to learning — otherwise legacy behavior
  //    wins so existing en-US / zh-CN users see no regression.
  if (normalized != null && !tagsEqual(normalized, learn)) {
    final wantedPrimary = _primarySubtagOnly(normalized);
    for (final candidate in supported) {
      if (tagsEqual(candidate, learn)) continue;
      if (src != null && tagsEqual(candidate, src)) continue;
      if (_primarySubtagOnly(candidate) == wantedPrimary) return candidate;
    }
  }

  // 4. Legacy fallback for null / empty / denylisted natives, or when the
  //    user picked native == learning (preserves coerceNativeIfEqualsLearning).
  return coerceNativeIfEqualsLearning(nativeLanguage, learningTag);
}
