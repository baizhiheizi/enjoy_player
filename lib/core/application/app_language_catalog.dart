/// Supported display / learning / native / media language tags.
///
/// Every per-language collection below derives from the ONE descriptor table
/// in [`language_descriptor.dart`](language_descriptor.dart) (issue #794,
/// ADR-0090) — the public names, shapes, order, and contents are unchanged;
/// only their definitions went from hand-maintained parallel literals to
/// derivations. Shared tag parsing and the `kLanguageTagAliases` policy map
/// (ADR-0087 macrolanguage policy) live next to the rows in
/// [`language_descriptor.dart`](language_descriptor.dart) and are re-exported
/// below, so this file adds no per-language literals of its own.
library;

import 'package:enjoy_player/core/application/language_descriptor.dart';
import 'package:flutter/material.dart';

export 'package:enjoy_player/core/application/language_descriptor.dart'
    show kLanguageTagAliases, normalizeLanguageAlias, primaryLanguageSubtag;

/// Default UI locale when none is stored and not overridden by profile.
const Locale kAppDefaultDisplayLocale = Locale('zh', 'CN');

/// Selectable app UI locales (Material [Locale] → BCP-47 via [localeToBcp47]).
const List<Locale> kAppDisplayLocales = <Locale>[
  Locale('en', 'US'),
  Locale('zh', 'CN'),
];

const String kDefaultLearningLanguageTag = 'en-US';

const String kDefaultNativeLanguageTag = 'zh-CN';

const String kUnknownMediaLanguageTag = 'und';

/// Profile "native" choices — descriptor rows with `native: true` (table order).
final List<String> kSupportedNativeLanguageTags = _tagsWhere(
  (row) => row.native,
);

/// Focus learning languages selectable in settings/profile (first wave) —
/// descriptor rows with `focus: true` (table order).
final List<String> kSupportedFocusLanguageTags = _tagsWhere((row) => row.focus);

/// Media content language choices (includes Unknown).
final List<String> kSupportedMediaLanguageTags = <String>[
  kUnknownMediaLanguageTag,
  ...kSupportedFocusLanguageTags,
];

/// Azure Speech pronunciation assessment locales (Microsoft
/// language-support table) — descriptor rows with `azureAssessment: true`.
final Set<String> kAzurePronunciationAssessmentLocales = <String>{
  for (final row in kLanguageDescriptorRows)
    if (row.azureAssessment) row.tag,
};

/// Preferred Azure locale when a broad tag has multiple regional options:
/// the first focus-or-native descriptor row of each primary subtag
/// ([firstTagPerPrimary]). The app resolves broad tags only for primaries it
/// already teaches or uses as a native language; other Azure-only primaries
/// (de, it, pt, ru, …) deliberately resolve `null` until they join a catalog.
final Map<String, String> kAzureDefaultLocaleByPrimary = firstTagPerPrimary(
  kLanguageDescriptorRows.where((row) => row.focus || row.native),
);

/// ISO 639 / BCP-47 language subtags that must not be used for lookup or worker calls.
const Set<String> kInvalidLanguageTags = <String>{
  '',
  'und',
  'mul',
  'mis',
  'zxx',
};

/// Short UI labels for [kSupportedLookupLanguageTags] (lookup sheet pills /
/// picker) — each lookup descriptor row's endonym [LanguageDescriptorRow.lookupLabel].
final Map<String, String> kLookupLanguageLabels = <String, String>{
  for (final row in kLanguageDescriptorRows)
    if (row.lookupLabel case final label?) row.tag: label,
};

/// Lookup-sheet source / target catalog (separate from profile / focus / media
/// lists so widening the lookup picker does not regress profile / settings UI).
///
/// First-wave tags cover the top languages requested by Enjoy Player users as
/// of 2026-07-08 and overlap with the Azure pronunciation-assessment locale
/// table where relevant. Derived: the descriptor rows carrying a lookup label,
/// in table order — "every lookup tag has a label" holds by construction.
final List<String> kSupportedLookupLanguageTags = _tagsWhere(
  (row) => row.isLookupRow,
);

/// Descriptor rows (in table order) whose [test] passes, as their tags.
List<String> _tagsWhere(bool Function(LanguageDescriptorRow row) test) =>
    <String>[
      for (final row in kLanguageDescriptorRows)
        if (test(row)) row.tag,
    ];

/// Sorts [tags] with the user's learning language first (primary-subtag
/// match), then alphabetical by primary subtag, then by region subtag.
/// Stable for ties; returns a new list (input is not mutated).
List<String> sortLookupLanguages(
  List<String> tags, {
  required String learningTag,
}) {
  final learnPrimary = primaryLanguageSubtag(normalizeBcp47Tag(learningTag));
  final indexed = List<MapEntry<String, int>>.generate(tags.length, (i) {
    return MapEntry<String, int>(tags[i], i);
  });
  indexed.sort((a, b) {
    final aTag = normalizeBcp47Tag(a.key);
    final bTag = normalizeBcp47Tag(b.key);
    final aPrimary = primaryLanguageSubtag(aTag);
    final bPrimary = primaryLanguageSubtag(bTag);
    final aIsLearn = aPrimary == learnPrimary;
    final bIsLearn = bPrimary == learnPrimary;
    if (aIsLearn != bIsLearn) return aIsLearn ? -1 : 1;
    final byPrimary = aPrimary.compareTo(bPrimary);
    if (byPrimary != 0) return byPrimary;
    final aParts = aTag.split('-');
    final bParts = bTag.split('-');
    final aRegion = aParts.length >= 2 ? aParts[1] : '';
    final bRegion = bParts.length >= 2 ? bParts[1] : '';
    final byRegion = aRegion.compareTo(bRegion);
    if (byRegion != 0) return byRegion;
    return a.value.compareTo(b.value);
  });
  return indexed.map((e) => e.key).toList(growable: false);
}

/// True when [tag] has a non-empty primary subtag not in [kInvalidLanguageTags].
bool isValidLanguageTag(String? tag) {
  if (tag == null) return false;
  final trimmed = tag.trim();
  if (trimmed.isEmpty) return false;
  final primary = primaryLanguageSubtag(trimmed);
  if (primary.isEmpty) return false;
  return !kInvalidLanguageTags.contains(primary);
}

/// Maps a tag to a supported native tag (`en-US` / `zh-CN`), or `null` if unknown/invalid.
String? canonicalLookupTag(String? tag) {
  if (!isValidLanguageTag(tag)) return null;
  final trimmed = normalizeLanguageAlias(tag!.trim());
  final primary = primaryLanguageSubtag(trimmed);
  if (primary == 'en') return 'en-US';
  if (primary == 'zh') return 'zh-CN';
  final n = normalizeBcp47Tag(trimmed);
  for (final supported in kSupportedNativeLanguageTags) {
    if (tagsEqual(n, supported)) return supported;
  }
  return null;
}

/// Maps [tag] to a supported focus learning tag, or [kDefaultLearningLanguageTag].
String canonicalFocusLanguageTag(String? tag) {
  if (tag == null || tag.trim().isEmpty) return kDefaultLearningLanguageTag;
  final normalized = normalizeBcp47Tag(normalizeLanguageAlias(tag.trim()));
  for (final supported in kSupportedFocusLanguageTags) {
    if (tagsEqual(normalized, supported)) return supported;
  }
  final primary = primaryLanguageSubtag(normalized);
  for (final supported in kSupportedFocusLanguageTags) {
    if (primaryLanguageSubtag(supported) == primary) return supported;
  }
  return kDefaultLearningLanguageTag;
}

/// Maps [tag] to a supported media content tag, or [kUnknownMediaLanguageTag].
String canonicalMediaLanguageTag(String? tag) {
  if (tag == null || tag.trim().isEmpty) return kUnknownMediaLanguageTag;
  final trimmed = tag.trim();
  if (tagsEqual(trimmed, kUnknownMediaLanguageTag)) {
    return kUnknownMediaLanguageTag;
  }
  final normalized = normalizeBcp47Tag(normalizeLanguageAlias(trimmed));
  for (final supported in kSupportedMediaLanguageTags) {
    if (supported == kUnknownMediaLanguageTag) continue;
    if (tagsEqual(normalized, supported)) return supported;
  }
  final primary = primaryLanguageSubtag(normalized);
  for (final supported in kSupportedMediaLanguageTags) {
    if (supported == kUnknownMediaLanguageTag) continue;
    if (primaryLanguageSubtag(supported) == primary) return supported;
  }
  if (isValidLanguageTag(normalized)) return normalized;
  return kUnknownMediaLanguageTag;
}

/// True when [a] and [b] refer to the same language (broad or exact BCP-47 match).
bool matchesLanguageBroad(String? a, String? b) {
  if (a == null || b == null) return false;
  if (tagsEqual(a, b)) return true;
  return primaryLanguageSubtag(a) == primaryLanguageSubtag(b);
}

/// Resolves [tag] to an Azure pronunciation assessment locale, or `null` if unsupported.
String? resolveAzureAssessmentLocale(String? tag) {
  if (tag == null || tag.trim().isEmpty) return null;
  if (!isValidLanguageTag(tag)) return null;

  final normalized = normalizeBcp47Tag(normalizeLanguageAlias(tag.trim()));
  if (kAzurePronunciationAssessmentLocales.contains(normalized)) {
    return normalized;
  }

  final lower = normalized.toLowerCase();
  for (final locale in kAzurePronunciationAssessmentLocales) {
    if (locale.toLowerCase() == lower) return locale;
  }

  final primary = primaryLanguageSubtag(normalized);
  for (final locale in kAzurePronunciationAssessmentLocales) {
    if (primaryLanguageSubtag(locale) == primary) {
      if (normalizeBcp47Tag(normalized) == normalizeBcp47Tag(locale)) {
        return locale;
      }
    }
  }

  final defaultLocale = kAzureDefaultLocaleByPrimary[primary];
  if (defaultLocale != null &&
      kAzurePronunciationAssessmentLocales.contains(defaultLocale)) {
    return defaultLocale;
  }

  return null;
}

/// True for empty / denylisted media tags (`und`, `mul`, …) — not a real
/// spoken language choice, just "unknown content language".
bool isUnknownMediaLanguageTag(String? tag) {
  if (tag == null) return true;
  final trimmed = tag.trim();
  if (trimmed.isEmpty) return true;
  final primary = primaryLanguageSubtag(normalizeLanguageAlias(trimmed));
  return primary.isEmpty || kInvalidLanguageTags.contains(primary);
}

/// Azure locale for shadow-reading assessment.
///
/// Unknown media tags (`und` / empty — common for YouTube imports) fall back to
/// [learningLanguage] then [kDefaultLearningLanguageTag]. Real unsupported
/// languages still return `null` (no silent `en-US` coercion).
///
/// Restores pre-[33dace5] practice behavior for unknown media language without
/// reopening the unsupported-language loophole.
String? resolveAzureAssessmentLocaleForPractice(
  String? mediaOrRecordingLanguage, {
  String? learningLanguage,
}) {
  final direct = resolveAzureAssessmentLocale(mediaOrRecordingLanguage);
  if (direct != null) return direct;
  if (!isUnknownMediaLanguageTag(mediaOrRecordingLanguage)) return null;
  final fromLearning = resolveAzureAssessmentLocale(learningLanguage);
  if (fromLearning != null) return fromLearning;
  return resolveAzureAssessmentLocale(kDefaultLearningLanguageTag);
}

bool isAzurePronunciationAssessmentSupportedForPractice(
  String? mediaOrRecordingLanguage, {
  String? learningLanguage,
}) =>
    resolveAzureAssessmentLocaleForPractice(
      mediaOrRecordingLanguage,
      learningLanguage: learningLanguage,
    ) !=
    null;

/// Worker / web short language code: first subtag lowercased (`en-US` → `en`).
String workerLanguageBase(String tag) {
  final t = normalizeLanguageAlias(tag.trim());
  if (t.isEmpty) return 'en';
  return splitLanguageTag(t).first.toLowerCase();
}

String normalizeBcp47Tag(String tag) {
  final t = normalizeLanguageAlias(tag.trim());
  if (t.isEmpty) return t;
  final parts = splitLanguageTag(t);
  if (parts.length >= 2) {
    return '${parts[0].toLowerCase()}-${parts[1].toUpperCase()}';
  }
  return parts[0].toLowerCase();
}

bool tagsEqual(String a, String b) =>
    normalizeBcp47Tag(a) == normalizeBcp47Tag(b);

/// Native choices for the current learning language (native must ≠ learning).
List<String> allowedNativeTags(String learningTag) {
  final learn = normalizeBcp47Tag(learningTag);
  return kSupportedNativeLanguageTags
      .where((n) => !tagsEqual(n, learn))
      .toList(growable: false);
}

/// If [native] is null, empty, or equals [learning], pick a valid default.
String coerceNativeIfEqualsLearning(String? native, String learning) {
  final learn = normalizeBcp47Tag(learning);
  if (native == null || native.trim().isEmpty) {
    return _firstAllowedOrDefault(learn);
  }
  final n = normalizeBcp47Tag(native);
  if (tagsEqual(n, learn)) {
    return _firstAllowedOrDefault(learn);
  }
  if (!kSupportedNativeLanguageTags.any((t) => tagsEqual(t, n))) {
    return _firstAllowedOrDefault(learn);
  }
  return kSupportedNativeLanguageTags.firstWhere((t) => tagsEqual(t, n));
}

String _firstAllowedOrDefault(String normalizedLearning) {
  final allowed = allowedNativeTags(normalizedLearning);
  if (allowed.isNotEmpty) return allowed.first;
  return kDefaultNativeLanguageTag;
}

String localeToBcp47(Locale locale) => locale.toLanguageTag();

/// Maps [locale] to a supported display locale, or [kAppDefaultDisplayLocale].
Locale displayLocaleFromRawOrDefault(String? raw) {
  if (raw == null || raw.trim().isEmpty) return kAppDefaultDisplayLocale;
  final parts = splitLanguageTag(raw.trim());
  final Locale candidate = parts.length >= 2
      ? Locale(parts[0].toLowerCase(), parts[1].toUpperCase())
      : Locale(parts[0].toLowerCase());
  for (final loc in kAppDisplayLocales) {
    if (loc.languageCode == candidate.languageCode &&
        (loc.countryCode ?? '') == (candidate.countryCode ?? '')) {
      return loc;
    }
  }
  for (final loc in kAppDisplayLocales) {
    if (loc.languageCode == candidate.languageCode) return loc;
  }
  return kAppDefaultDisplayLocale;
}
