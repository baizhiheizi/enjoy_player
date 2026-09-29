/// ONE per-language descriptor row — the single source of truth every
/// language catalog derives from (issue #794, ADR-0090).
///
/// Before this table the same per-language knowledge was restated in parallel
/// literals across four modules (`app_language_catalog.dart`,
/// `language_labels.dart`, `pronounce_locale.dart`, and the lookup label map),
/// so adding `nb-NO` touched ~9 hand-edited code files. Now adding a language
/// is one row here (plus its localized `.arb` entries and the worker /
/// alignment-package rollouts those deployments gate).
///
/// Authoring rules:
///
/// - One row per language, keyed by canonical BCP-47 tag (`xx-YY`).
/// - A non-null [LanguageDescriptorRow.lookupLabel] **is** lookup-sheet
///   membership: it derives both `kSupportedLookupLanguageTags` and
///   `kLookupLanguageLabels`, so the "every lookup tag has a label" invariant
///   holds by construction.
/// - Within a primary subtag, list the default regional variant **first**
///   (`en-US` before `en-GB`, `es-ES` before `es-MX`, `pt-BR` before
///   `pt-PT`): the Azure and worker broad-tag default maps derive the
///   default via [firstTagPerPrimary], so row order is load-bearing, not
///   cosmetic.
/// - Rows that only widen the Azure pronunciation-assessment allowlist carry
///   nothing but `tag`: no lookup label and no flags. They are still
///   assessment locales because [LanguageDescriptorRow.azureAssessment]
///   defaults to `true`; they are distinguishable by `lookupLabel == null`.
library;

/// One language known to the app, and which surfaces it participates in.
class LanguageDescriptorRow {
  const LanguageDescriptorRow({
    required this.tag,
    this.lookupLabel,
    this.focus = false,
    this.native = false,
    this.pronounce = false,
    this.azureAssessment = true,
  });

  /// Canonical BCP-47 tag (`en-US`, `nb-NO`).
  final String tag;

  /// Static (non-localized) endonym label for the lookup sheet pills /
  /// picker. Non-null exactly on lookup rows — see [isLookupRow]. Localized
  /// settings / media-picker labels live in `language_labels.dart` (.arb).
  final String? lookupLabel;

  /// In `kSupportedFocusLanguageTags` (profile "learning" picker; also the
  /// alignment catalog pinned by ADR-0071/0072 via its own package seam).
  final bool focus;

  /// In `kSupportedNativeLanguageTags` (profile "native" picker).
  final bool native;

  /// In the worker `/pronounce` allowlist (`kPronounceSupportedLocales`).
  /// The worker must ship a locale before this flips to `true` — a player
  /// release ahead of it would send the tag and get a 400 (ADR-0087).
  final bool pronounce;

  /// Azure Speech pronunciation-assessment locale
  /// (`kAzurePronunciationAssessmentLocales`, Microsoft language-support
  /// table). Defaults to `true` — every row today is assessable, so the flag
  /// is only written when a row must be *excluded*.
  final bool azureAssessment;

  /// Whether this row appears in `kSupportedLookupLanguageTags` / the lookup
  /// sheet's source / target pickers (ADR-0042).
  bool get isLookupRow => lookupLabel != null;
}

/// The descriptor table — one row per language, in picker order (lookup
/// languages first, then Azure-assessment-only rows).
///
/// Every catalog derives from this table; nothing may restate per-language
/// knowledge in parallel literals (see the module docs in
/// `app_language_catalog.dart`, `pronounce_locale.dart`, and
/// `language_labels.dart`).
const List<LanguageDescriptorRow>
kLanguageDescriptorRows = <LanguageDescriptorRow>[
  // Lookup / focus / native / pronounce languages (picker order; the
  // first row of each primary subtag is that primary's default).
  LanguageDescriptorRow(
    tag: 'en-US',
    lookupLabel: 'English',
    focus: true,
    native: true,
    pronounce: true,
  ),
  LanguageDescriptorRow(
    tag: 'en-GB',
    lookupLabel: 'English (UK)',
    focus: true,
    pronounce: true,
  ),
  LanguageDescriptorRow(
    tag: 'zh-CN',
    lookupLabel: '中文',
    native: true,
    pronounce: true,
  ),
  LanguageDescriptorRow(
    tag: 'ja-JP',
    lookupLabel: '日本語',
    focus: true,
    pronounce: true,
  ),
  LanguageDescriptorRow(
    tag: 'ko-KR',
    lookupLabel: '한국어',
    focus: true,
    pronounce: true,
  ),
  LanguageDescriptorRow(
    tag: 'es-ES',
    lookupLabel: 'Español (España)',
    focus: true,
    pronounce: true,
  ),
  LanguageDescriptorRow(
    tag: 'es-MX',
    lookupLabel: 'Español (México)',
    focus: true,
    pronounce: true,
  ),
  LanguageDescriptorRow(
    tag: 'fr-FR',
    lookupLabel: 'Français (France)',
    focus: true,
    pronounce: true,
  ),
  LanguageDescriptorRow(
    tag: 'fr-CA',
    lookupLabel: 'Français (Canada)',
    focus: true,
    pronounce: true,
  ),
  LanguageDescriptorRow(tag: 'de-DE', lookupLabel: 'Deutsch', pronounce: true),
  LanguageDescriptorRow(tag: 'it-IT', lookupLabel: 'Italiano', pronounce: true),
  LanguageDescriptorRow(
    tag: 'pt-BR',
    lookupLabel: 'Português (Brasil)',
    pronounce: true,
  ),
  LanguageDescriptorRow(
    tag: 'pt-PT',
    lookupLabel: 'Português (Portugal)',
    pronounce: true,
  ),
  LanguageDescriptorRow(tag: 'ru-RU', lookupLabel: 'Русский', pronounce: true),
  LanguageDescriptorRow(
    tag: 'nb-NO',
    lookupLabel: 'Norsk (bokmål)',
    focus: true,
    pronounce: true,
  ),
  // Azure pronunciation-assessment-only locales (Microsoft
  // language-support table; no picker, worker, or lookup surface yet).
  // Argless rows: no lookup label and no flags — `azureAssessment`
  // defaults to `true`, which is what puts them in the Azure set.
  LanguageDescriptorRow(tag: 'ar-EG'),
  LanguageDescriptorRow(tag: 'ar-SA'),
  LanguageDescriptorRow(tag: 'ca-ES'),
  LanguageDescriptorRow(tag: 'zh-HK'),
  LanguageDescriptorRow(tag: 'zh-TW'),
  LanguageDescriptorRow(tag: 'da-DK'),
  LanguageDescriptorRow(tag: 'nl-NL'),
  LanguageDescriptorRow(tag: 'en-AU'),
  LanguageDescriptorRow(tag: 'en-CA'),
  LanguageDescriptorRow(tag: 'en-IN'),
  LanguageDescriptorRow(tag: 'fi-FI'),
  LanguageDescriptorRow(tag: 'hi-IN'),
  LanguageDescriptorRow(tag: 'ms-MY'),
  LanguageDescriptorRow(tag: 'pl-PL'),
  LanguageDescriptorRow(tag: 'sv-SE'),
  LanguageDescriptorRow(tag: 'ta-IN'),
  LanguageDescriptorRow(tag: 'th-TH'),
  LanguageDescriptorRow(tag: 'vi-VN'),
];

// ── Tag parsing shared by every catalog module ──────────────────────────────
//
// One home for the hyphen-or-underscore character class and for the
// alias-aware "same language" definition (review on #798):
// `app_language_catalog.dart` re-imports these instead of restating them, so
// the separator pattern and `primaryLanguageSubtag` each exist exactly once.
// This direction also breaks the import cycle — the descriptor cannot import
// the catalog, so shared tag parsing lives with the rows.

/// Splits [tag] on `-` / `_` (BCP-47 hyphen or Java-style underscore).
List<String> splitLanguageTag(String tag) => tag.split(_kLanguageTagSeparator);

/// Shared separator for BCP-47 / language-tag splits. File-private so the
/// post-commit lint pass cannot grow a second character class; every split
/// goes through [splitLanguageTag].
final RegExp _kLanguageTagSeparator = RegExp(r'[-_]');

/// ISO 639-2 / legacy aliases → ISO 639-1 primary subtag.
///
/// The Norwegian entries encode a deliberate **policy**, not a neutral
/// equivalence: `no` is a macrolanguage tag, and essentially all Norwegian
/// content in the wild is Bokmål, so `no` / `nob` / `nor` collapse onto
/// Bokmål. Genuine Nynorsk (`nn`) is deliberately **not** aliased and stays
/// unsupported. See ADR-0087.
const Map<String, String> kLanguageTagAliases = <String, String>{
  'eng': 'en',
  'jpn': 'ja',
  'kor': 'ko',
  'spa': 'es',
  'fre': 'fr',
  'fra': 'fr',
  'zho': 'zh',
  'chi': 'zh',
  'no': 'nb',
  'nob': 'nb',
  'nor': 'nb',
};

/// Resolves legacy aliases such as `kor` → `ko`.
String normalizeLanguageAlias(String tag) {
  final trimmed = tag.trim();
  if (trimmed.isEmpty) return trimmed;
  final lower = trimmed.toLowerCase();
  final alias = kLanguageTagAliases[lower];
  if (alias != null) return alias;
  if (lower.contains('-') || lower.contains('_')) {
    final parts = splitLanguageTag(lower);
    final primary = parts.first;
    final aliased = kLanguageTagAliases[primary];
    if (aliased != null && parts.length >= 2) {
      return '$aliased-${parts[1].toUpperCase()}';
    }
  }
  return trimmed;
}

/// Primary language subtag of [tag], lowercased (`en-US` → `en`, `kor` → `ko`).
///
/// Normalizes legacy aliases first (e.g. `kor` → `ko`) via
/// [normalizeLanguageAlias], then splits on `-` / `_` and returns the first
/// subtag lowercased. Shared by the catalog resolvers, the lookup language
/// resolvers, and [firstTagPerPrimary] so every module uses one definition of
/// "same language" (see `matchesLanguageBroad`, `resolveLookupSource`, etc.
/// in `app_language_catalog.dart` / `lookup_target_languages.dart`).
String primaryLanguageSubtag(String tag) {
  final normalized = normalizeLanguageAlias(tag);
  return splitLanguageTag(normalized).first.toLowerCase();
}

/// Maps each primary subtag in [rows] to that primary's **first** row tag.
///
/// This is how bare / unknown-region primaries (`ja`, `zh`, `en-AU`) resolve
/// to a default regional variant: the descriptor table lists the default
/// variant first within each primary, so this derivation makes that authoring
/// convention the rule. Never crosses into a different primary language.
Map<String, String> firstTagPerPrimary(Iterable<LanguageDescriptorRow> rows) {
  final defaults = <String, String>{};
  for (final row in rows) {
    defaults.putIfAbsent(primaryLanguageSubtag(row.tag), () => row.tag);
  }
  return defaults;
}
