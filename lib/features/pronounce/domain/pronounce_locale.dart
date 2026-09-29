/// Map app language tags → Worker `/pronounce` locales.
library;

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/language_descriptor.dart';

/// Worker allowlist — descriptor rows with `pronounce: true`.
///
/// Mirrors Enjoy worker's `/pronounce` `DEFAULT_VOICES` / `ALLOWED_VOICES`
/// (baizhiheizi/enjoy#1313 added `nb-NO`). The **worker must ship first** —
/// a player release ahead of it would send `nb-NO` and get a 400. Today the
/// set is set-identical to [kSupportedLookupLanguageTags] (worker parity
/// policy, pinned by the derivation tests); a deliberate divergence while
/// the worker catches up means flipping a row's `pronounce` flag and that
/// pin together.
final Set<String> kPronounceSupportedLocales = <String>{
  for (final row in kLanguageDescriptorRows)
    if (row.pronounce) row.tag,
};

/// Bare / unknown-region primary → default regional Worker locale.
///
/// Vocabulary items and recordings often store ISO 639-1 primaries (`ja`,
/// `zh`). Never cross into a different primary language. Derived: the first
/// pronounce descriptor row of each primary ([firstTagPerPrimary]).
final Map<String, String> kPronounceDefaultLocaleByPrimary = firstTagPerPrimary(
  kLanguageDescriptorRows.where((row) => row.pronounce),
);

const int kPronounceMaxChars = 200;

/// Resolves [tag] to a Worker pronounce locale, or `null` if unsupported.
///
/// - `en-UK` → `en-GB`
/// - bare / other `en*` (not GB/UK) → `en-US`
/// - exact allowlist match for remaining tags
/// - bare primary (`ja`, `zh`, …) or unknown region → primary default when
///   that default is allowlisted
String? resolvePronounceLocale(String? tag) {
  if (tag == null || tag.trim().isEmpty) return null;
  final normalized = normalizeBcp47Tag(normalizeLanguageAlias(tag.trim()));
  if (normalized.isEmpty) return null;
  if (!isValidLanguageTag(normalized)) return null;

  if (normalized == 'en-UK' || tagsEqual(normalized, 'en-GB')) {
    return 'en-GB';
  }

  for (final supported in kPronounceSupportedLocales) {
    if (tagsEqual(normalized, supported)) return supported;
  }

  final primary = primaryLanguageSubtag(normalized);
  if (primary == 'en') {
    return 'en-US';
  }

  final byPrimary = kPronounceDefaultLocaleByPrimary[primary];
  if (byPrimary != null && kPronounceSupportedLocales.contains(byPrimary)) {
    return byPrimary;
  }
  return null;
}

/// Whether [text] is eligible for a pronounce request (after trim).
bool isPronounceTextEligible(String text) {
  final t = text.trim();
  return t.isNotEmpty && t.length <= kPronounceMaxChars;
}
