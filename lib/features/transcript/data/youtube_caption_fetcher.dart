/// Direct YouTube captions fetcher using the public InnerTube API.
///
/// Port of the [youtube-caption-extractor](https://github.com/devhims/youtube-caption-extractor)
/// TypeScript library to Dart. Calls YouTube's InnerTube `/player` endpoint with
/// spoofed client profiles, then fetches the selected caption track in `json3`
/// format.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'client_profile.dart';
import '../../../core/application/app_language_catalog.dart';
import '../../../core/json/gated_json_decode.dart';
import '../../../data/subtitle/transcript_line.dart';
import '../../../core/logging/log.dart';
import '../../../core/utils/html_clean.dart';

part 'youtube_caption_fetcher_errors.dart';
part 'youtube_caption_fetcher_models.dart';
part 'youtube_caption_fetcher_player.dart';
part 'youtube_caption_fetcher_timedtext.dart';
part 'youtube_caption_fetcher_track_selection.dart';

/// Module-level logger for direct InnerTube fetches.
///
/// Each profile attempt logs at INFO; the cumulative "all profiles failed"
/// path in [YoutubeCaptionFetcher.fetchAllSubtitles] is logged at INFO here,
/// and the caller ([TranscriptRepository._fetchYoutubeTranscriptsWithFallback])
/// escalates it to WARNING when surfacing the result. This split keeps
/// per-profile chatter at INFO (cheap in production) while the user-visible
/// "I see captions on Windows but not on Android" failure mode still trips
/// WARNING once per open.
final Logger _log = logNamed('YoutubeCaptionFetcher');

/// Session-sticky last profile that returned usable caption tracks.
///
/// Survives [YoutubeCaptionFetcher] rebuilds when Riverpod refreshes the
/// profile list so subsequent videos try the known-good client first.
String? _lastSuccessfulCaptionProfileKey;

/// Clears the sticky caption profile (tests / forced reset).
void resetLastSuccessfulCaptionProfile() {
  _lastSuccessfulCaptionProfileKey = null;
}

/// Fetches YouTube captions directly using the InnerTube API.
class YoutubeCaptionFetcher {
  YoutubeCaptionFetcher({
    required this.httpClient,
    this.profiles = kBuiltInClientProfiles,
    this.transportFailureHint,
  });

  final http.Client httpClient;
  final List<ClientProfile> profiles;

  /// Appended to the aggregated error when every profile failed at the
  /// transport level (socket / TLS / timeout).
  final String? Function()? transportFailureHint;

  /// Returns the fallback chain of profiles to try.
  ///
  /// When a prior fetch in this process succeeded, that profile is moved to
  /// the front so later videos skip already-failed clients.
  List<ClientProfile> get _profileChain {
    final chain = profiles.where((p) => p.isValid).toList();
    final sticky = _lastSuccessfulCaptionProfileKey;
    if (sticky == null || chain.length < 2) return chain;
    final idx = chain.indexWhere(
      (p) => p.name == sticky || p.clientKey == sticky.toUpperCase(),
    );
    if (idx <= 0) return chain;
    return [chain[idx], ...chain.sublist(0, idx), ...chain.sublist(idx + 1)];
  }

  /// Fetches subtitles for [videoId] in [lang] by trying each client profile
  /// in sequence, selecting the best matching caption track, and parsing the
  /// json3 timed text.
  Future<CaptionFetchResult> fetchSubtitles({
    required String videoId,
    String lang = 'en',
  }) async {
    final result = await fetchAllSubtitles(
      videoId: videoId,
      preferredLang: lang,
    );
    if (result.error != null) {
      return CaptionFetchResult(error: result.error);
    }
    if (result.results.isEmpty) {
      return const CaptionFetchResult(error: 'No caption tracks available');
    }
    return result.results.first;
  }

  /// Fetches all available caption tracks for [videoId], returning them as a
  /// list with the [preferredLang] match first. Fetches player data once and
  /// downloads all tracks in parallel.
  ///
  /// For each language, prefers manual captions (`.lang`) over auto-generated
  /// (`a.lang`). Returns an [AllCaptionsResult] with the deduplicated results
  /// list plus combined error/failure information.
  Future<AllCaptionsResult> fetchAllSubtitles({
    required String videoId,
    String preferredLang = 'en',
  }) async {
    final chain = _profileChain;
    if (chain.isEmpty) {
      return const AllCaptionsResult(error: 'No valid client profiles');
    }

    final failures = <String>[];
    for (final profile in chain) {
      try {
        final playerData = await _fetchPlayer(
          videoId: videoId,
          profile: profile,
        );

        final allTracks = _extractCaptionTracks(playerData);
        if (allTracks.isEmpty) {
          const msg = 'OK but no caption tracks';
          failures.add('${profile.name}: $msg');
          _log.info('InnerTube profile=${profile.name} for $videoId: $msg');
          continue;
        }

        final bestByLang = <String, CaptionTrack>{};
        for (final track in allTracks) {
          final code = track.languageCode;
          if (code == null || code.isEmpty) continue;
          final existing = bestByLang[code];
          if (existing == null ||
              _isBetterMatch(track, existing, preferredLang: preferredLang)) {
            bestByLang[code] = track;
          }
        }

        if (bestByLang.isEmpty) {
          const msg = 'no tracks with valid language codes';
          failures.add('${profile.name}: $msg');
          _log.info('InnerTube profile=${profile.name} for $videoId: $msg');
          continue;
        }

        final futures = bestByLang.values.map((track) async {
          try {
            final source = _determineSource(track);
            final subtitles = await _fetchCaptionTrack(track, profile);
            return CaptionFetchResult(
              subtitles: subtitles,
              source: source,
              language: track.languageCode ?? '',
              fetchProfile: profile.name,
            );
          } on Object catch (e) {
            return CaptionFetchResult(
              error: '${track.languageCode}: $e',
              language: track.languageCode ?? '',
            );
          }
        });

        final allResults = await Future.wait(futures);

        final sorted = [...allResults];
        final prefPrimary = primaryLanguageSubtag(preferredLang);
        sorted.sort((a, b) {
          final byPreference =
              _preferredLanguageRank(
                a.language,
                preferredLang: preferredLang,
                preferredPrimary: prefPrimary,
              ).compareTo(
                _preferredLanguageRank(
                  b.language,
                  preferredLang: preferredLang,
                  preferredPrimary: prefPrimary,
                ),
              );
          if (byPreference != 0) return byPreference;
          return a.language.compareTo(b.language);
        });

        final okCount = sorted.where((r) => r.isSuccess).length;
        if (okCount > 0) {
          _lastSuccessfulCaptionProfileKey = profile.name;
        }
        _log.info(
          'InnerTube profile=${profile.name} for $videoId returned '
          '${bestByLang.length} track(s) ($okCount fetchable)',
        );
        return AllCaptionsResult(results: sorted, fetchProfile: profile.name);
      } on Object catch (e) {
        final msg = '$e';
        failures.add('${profile.name}: $msg');
        _log.info('InnerTube profile=${profile.name} for $videoId threw: $msg');
      }
    }

    _log.info(
      'InnerTube all profiles failed for $videoId (tried: '
      '${chain.map((p) => p.name).join(', ')})',
    );
    final hint = _isTransportFailure(failures)
        ? transportFailureHint?.call()
        : null;
    return AllCaptionsResult(
      error:
          'All profiles failed:\n${failures.join('\n')}'
          '${hint == null ? '' : '\nHint: $hint'}',
    );
  }
}

bool _isTransportFailure(List<String> failures) =>
    failures.isNotEmpty &&
    failures.every(
      (f) =>
          f.contains('SocketException') ||
          f.contains('TimeoutException') ||
          f.contains('HandshakeException') ||
          f.contains('ClientException'),
    );
