part of 'youtube_caption_fetcher.dart';

/// Track selection: manual-vs-auto preference and language-tag ranking.
extension _YoutubeCaptionFetcherTrackSelection on YoutubeCaptionFetcher {
  /// Determines source label from the selected track's kind.
  String _determineSource(CaptionTrack track) {
    if (track.vssId != null && track.vssId!.startsWith('a.')) return 'auto';
    if (track.kind == 'asr') return 'auto';
    return 'official';
  }

  /// Returns true when [candidate] is a better choice than [current] for a
  /// given language. Prefers manual captions over auto, and prefers tracks
  /// matching [preferredLang] — an exact tag first, then a match on the
  /// primary subtag so `no` counts as `nb` via [kLanguageTagAliases].
  bool _isBetterMatch(
    CaptionTrack candidate,
    CaptionTrack current, {
    String preferredLang = 'en',
  }) {
    final cVss = candidate.vssId ?? '';
    final curVss = current.vssId ?? '';
    final cIsManual = cVss.startsWith('.');
    final curIsManual = curVss.startsWith('.');
    if (cIsManual && !curIsManual) return true;
    if (!cIsManual && curIsManual) return false;
    final prefPrimary = primaryLanguageSubtag(preferredLang);
    final cRank = _preferredLanguageRank(
      candidate.languageCode ?? '',
      preferredLang: preferredLang,
      preferredPrimary: prefPrimary,
      vssId: candidate.vssId,
    );
    final curRank = _preferredLanguageRank(
      current.languageCode ?? '',
      preferredLang: preferredLang,
      preferredPrimary: prefPrimary,
      vssId: current.vssId,
    );
    if (cRank < curRank) return true;
    return false;
  }
}

/// How well [language] matches the requested [preferredLang]: `0` for an
/// exact tag match, `1` for a match on the primary subtag only (so `no`
/// counts as `nb-NO` via [kLanguageTagAliases]), `2` for no match. An
/// exact match must outrank a sibling region — with `en-US` preferred, a
/// video offering both `en-US` and `en-GB` should lead with `en-US`, not
/// whichever tag sorts first alphabetically.
int _preferredLanguageRank(
  String language, {
  required String preferredLang,
  required String preferredPrimary,
  String? vssId,
}) {
  if (vssId == '.$preferredLang') return 0;
  if (language.isEmpty) return 2;
  if (language == preferredLang) return 0;
  if (primaryLanguageSubtag(language) == preferredPrimary) return 1;
  return 2;
}
