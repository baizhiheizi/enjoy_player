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
///   [LanguageDescriptorRow.azureAssessment] and nothing else.
library;

/// One language known to the app, and which surfaces it participates in.
class LanguageDescriptorRow {
  const LanguageDescriptorRow({
    required this.tag,
    required this.azureAssessment,
    this.lookupLabel,
    this.focus = false,
    this.native = false,
    this.pronounce = false,
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
  /// table).
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
const List<LanguageDescriptorRow> kLanguageDescriptorRows =
    <LanguageDescriptorRow>[
      // Lookup / focus / native / pronounce languages (picker order; the
      // first row of each primary subtag is that primary's default).
      LanguageDescriptorRow(
        tag: 'en-US',
        lookupLabel: 'English',
        focus: true,
        native: true,
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'en-GB',
        lookupLabel: 'English (UK)',
        focus: true,
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'zh-CN',
        lookupLabel: '中文',
        native: true,
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'ja-JP',
        lookupLabel: '日本語',
        focus: true,
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'ko-KR',
        lookupLabel: '한국어',
        focus: true,
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'es-ES',
        lookupLabel: 'Español (España)',
        focus: true,
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'es-MX',
        lookupLabel: 'Español (México)',
        focus: true,
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'fr-FR',
        lookupLabel: 'Français (France)',
        focus: true,
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'fr-CA',
        lookupLabel: 'Français (Canada)',
        focus: true,
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'de-DE',
        lookupLabel: 'Deutsch',
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'it-IT',
        lookupLabel: 'Italiano',
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'pt-BR',
        lookupLabel: 'Português (Brasil)',
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'pt-PT',
        lookupLabel: 'Português (Portugal)',
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'ru-RU',
        lookupLabel: 'Русский',
        pronounce: true,
        azureAssessment: true,
      ),
      LanguageDescriptorRow(
        tag: 'nb-NO',
        lookupLabel: 'Norsk (bokmål)',
        focus: true,
        pronounce: true,
        azureAssessment: true,
      ),
      // Azure pronunciation-assessment-only locales (Microsoft
      // language-support table; no picker, worker, or lookup surface yet).
      LanguageDescriptorRow(tag: 'ar-EG', azureAssessment: true),
      LanguageDescriptorRow(tag: 'ar-SA', azureAssessment: true),
      LanguageDescriptorRow(tag: 'ca-ES', azureAssessment: true),
      LanguageDescriptorRow(tag: 'zh-HK', azureAssessment: true),
      LanguageDescriptorRow(tag: 'zh-TW', azureAssessment: true),
      LanguageDescriptorRow(tag: 'da-DK', azureAssessment: true),
      LanguageDescriptorRow(tag: 'nl-NL', azureAssessment: true),
      LanguageDescriptorRow(tag: 'en-AU', azureAssessment: true),
      LanguageDescriptorRow(tag: 'en-CA', azureAssessment: true),
      LanguageDescriptorRow(tag: 'en-IN', azureAssessment: true),
      LanguageDescriptorRow(tag: 'fi-FI', azureAssessment: true),
      LanguageDescriptorRow(tag: 'hi-IN', azureAssessment: true),
      LanguageDescriptorRow(tag: 'ms-MY', azureAssessment: true),
      LanguageDescriptorRow(tag: 'pl-PL', azureAssessment: true),
      LanguageDescriptorRow(tag: 'sv-SE', azureAssessment: true),
      LanguageDescriptorRow(tag: 'ta-IN', azureAssessment: true),
      LanguageDescriptorRow(tag: 'th-TH', azureAssessment: true),
      LanguageDescriptorRow(tag: 'vi-VN', azureAssessment: true),
    ];

final RegExp _kLanguageTagSeparator = RegExp(r'[-_]');

/// Maps each primary subtag in [rows] to that primary's **first** row tag.
///
/// This is how bare / unknown-region primaries (`ja`, `zh`, `en-AU`) resolve
/// to a default regional variant: the descriptor table lists the default
/// variant first within each primary, so this derivation makes that authoring
/// convention the rule. Never crosses into a different primary language.
Map<String, String> firstTagPerPrimary(Iterable<LanguageDescriptorRow> rows) {
  final defaults = <String, String>{};
  for (final row in rows) {
    final primary = row.tag.split(_kLanguageTagSeparator).first.toLowerCase();
    defaults.putIfAbsent(primary, () => row.tag);
  }
  return defaults;
}
