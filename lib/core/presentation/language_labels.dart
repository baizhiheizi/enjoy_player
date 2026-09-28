/// Localized labels for focus/media language tags.
library;

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Localized label for [tag] when it is exactly one of
/// [kSupportedFocusLanguageTags]. Returns `null` for anything else so callers
/// can apply their own fallback instead of silently returning English.
String? _supportedFocusLabel(AppLocalizations l10n, String tag) {
  if (tagsEqual(tag, 'en-US')) return l10n.settingsLanguageOptionEnUs;
  if (tagsEqual(tag, 'en-GB')) return l10n.settingsLanguageOptionEnGb;
  if (tagsEqual(tag, 'ja-JP')) return l10n.settingsLanguageOptionJaJp;
  if (tagsEqual(tag, 'ko-KR')) return l10n.settingsLanguageOptionKoKr;
  if (tagsEqual(tag, 'es-ES')) return l10n.settingsLanguageOptionEsEs;
  if (tagsEqual(tag, 'es-MX')) return l10n.settingsLanguageOptionEsMx;
  if (tagsEqual(tag, 'fr-FR')) return l10n.settingsLanguageOptionFrFr;
  if (tagsEqual(tag, 'fr-CA')) return l10n.settingsLanguageOptionFrCa;
  if (tagsEqual(tag, 'zh-CN')) return l10n.settingsLanguageOptionZhCn;
  if (tagsEqual(tag, 'nb-NO')) return l10n.settingsLanguageOptionNbNo;
  return null;
}

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
