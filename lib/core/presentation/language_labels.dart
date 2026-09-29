/// Localized labels for focus/media language tags.
library;

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/language_descriptor.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Localized (gen-l10n) label getters for exactly the descriptor rows in
/// [kSupportedFocusLanguageTags] ∪ [kSupportedNativeLanguageTags] — the tags
/// the settings / profile / media pickers can render (media items can also
/// carry a stored native tag such as `zh-CN`).
///
/// The **keys are derived** from [kLanguageDescriptorRows] (review on #798):
/// a row with `focus: true` or `native: true` contributes its key
/// automatically, so the map cannot drift out of lockstep with the table.
/// The only hand-written part is the tag → getter dispatch
/// ([_localizedLabelGetter]), which throws for a row that lacks a case
/// instead of silently missing — pinned by the derivation tests in
/// `language_labels_test.dart`. Static endonym labels for the lookup sheet
/// live separately in [kLookupLanguageLabels].
final Map<String, String Function(AppLocalizations)>
localizedLanguageLabelGetters = <String, String Function(AppLocalizations)>{
  for (final row in kLanguageDescriptorRows)
    if (row.focus || row.native) row.tag: _localizedLabelGetter(row.tag),
};

/// The .arb seam of the descriptor table: one case per focus / native row,
/// pointing at its gen-l10n getter. Adding a focus or native language means
/// adding its `.arb` entries **and** a case here in the same change — a
/// forgotten case throws `UnsupportedError` when the map above is built
/// (loudly, not a silent `null` label at runtime).
String Function(AppLocalizations) _localizedLabelGetter(String tag) =>
    switch (tag) {
      'en-US' => (l10n) => l10n.settingsLanguageOptionEnUs,
      'en-GB' => (l10n) => l10n.settingsLanguageOptionEnGb,
      'zh-CN' => (l10n) => l10n.settingsLanguageOptionZhCn,
      'ja-JP' => (l10n) => l10n.settingsLanguageOptionJaJp,
      'ko-KR' => (l10n) => l10n.settingsLanguageOptionKoKr,
      'es-ES' => (l10n) => l10n.settingsLanguageOptionEsEs,
      'es-MX' => (l10n) => l10n.settingsLanguageOptionEsMx,
      'fr-FR' => (l10n) => l10n.settingsLanguageOptionFrFr,
      'fr-CA' => (l10n) => l10n.settingsLanguageOptionFrCa,
      'nb-NO' => (l10n) => l10n.settingsLanguageOptionNbNo,
      _ => throw UnsupportedError(
        'No localized label getter for descriptor row "$tag" — add its .arb '
        'entries and a case in _localizedLabelGetter (issue #798 seam).',
      ),
    };

/// Localized label for [tag] when it is exactly one of
/// [kSupportedFocusLanguageTags] or [kSupportedNativeLanguageTags]. Returns
/// `null` for anything else so callers can apply their own fallback instead
/// of silently returning English.
String? _supportedFocusLabel(AppLocalizations l10n, String tag) =>
    localizedLanguageLabelGetters[normalizeBcp47Tag(tag)]?.call(l10n);

/// User-visible label for a focus or media language BCP-47 tag.
String focusLanguageLabel(AppLocalizations l10n, String tag) {
  if (tagsEqual(tag, kUnknownMediaLanguageTag)) {
    return l10n.mediaLanguageUnknown;
  }
  final exact = _supportedFocusLabel(l10n, tag);
  if (exact != null) return exact;

  // Primary-subtag fallback, run *after* alias normalization so `no`, `nb`,
  // `nob`, and `nor` all resolve to the Bokmål label. Deliberately does NOT
  // route through `canonicalFocusLanguageTag`, which coerces unknown primaries
  // to `en-US` and would therefore mislabel e.g. a Nynorsk `nn` track as
  // "English". Tags whose primary matches nothing supported keep showing the
  // raw tag (previous behavior).
  final primary = primaryLanguageSubtag(tag);
  if (primary.isEmpty) return tag;
  for (final supported in kSupportedFocusLanguageTags) {
    if (primaryLanguageSubtag(supported) != primary) continue;
    return _supportedFocusLabel(l10n, supported) ?? tag;
  }
  return tag;
}

/// Options for focus learning language picker.
List<LanguageChoiceEntry> focusLanguageChoices(AppLocalizations l10n) {
  return kSupportedFocusLanguageTags
      .map(
        (tag) => LanguageChoiceEntry(
          value: tag,
          label: focusLanguageLabel(l10n, tag),
        ),
      )
      .toList(growable: false);
}

/// Options for media content language picker (includes Unknown).
List<LanguageChoiceEntry> mediaLanguageChoices(AppLocalizations l10n) {
  return kSupportedMediaLanguageTags
      .map(
        (tag) => LanguageChoiceEntry(
          value: tag,
          label: focusLanguageLabel(l10n, tag),
        ),
      )
      .toList(growable: false);
}

class LanguageChoiceEntry {
  const LanguageChoiceEntry({required this.value, required this.label});

  final String value;
  final String label;
}
