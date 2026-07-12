/// Direct YouTube captions fetcher using the public InnerTube API.
///
/// Port of the [youtube-caption-extractor](https://github.com/devhims/youtube-caption-extractor)
/// TypeScript library to Dart. Calls YouTube's InnerTube `/player` endpoint with
/// spoofed client profiles, then fetches the selected caption track in `json3`
/// format.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'client_profile.dart';
import '../../../data/subtitle/transcript_line.dart';
import '../../../core/utils/html_clean.dart';

/// InnerTube API endpoint.
const _innertubeEndpoint =
    'https://youtubei.googleapis.com/youtubei/v1/player?prettyPrint=false';

/// Transient descriptor for a YouTube caption track.
class CaptionTrack {
  const CaptionTrack({
    required this.baseUrl,
    this.vssId,
    this.languageCode,
    this.kind,
  });

  final String baseUrl;
  final String? vssId;
  final String? languageCode;
  final String? kind;

  factory CaptionTrack.fromJson(Map<String, dynamic> json) {
    return CaptionTrack(
      baseUrl: json['baseUrl'] as String? ?? '',
      vssId: json['vssId'] as String?,
      languageCode: json['languageCode'] as String?,
      kind: json['kind'] as String?,
    );
  }
}

/// Outcome of a direct YouTube caption fetch attempt.
class CaptionFetchResult {
  const CaptionFetchResult({
    this.subtitles = const [],
    this.source = 'auto',
    this.language = '',
    this.fetchProfile = '',
    this.error,
  });

  final List<TranscriptLine> subtitles;
  final String source;
  final String language;
  final String fetchProfile;
  final String? error;

  bool get isSuccess => error == null && subtitles.isNotEmpty;
}

/// Fetches YouTube captions directly using the InnerTube API.
class YoutubeCaptionFetcher {
  YoutubeCaptionFetcher({
    required this.httpClient,
    this.profiles = kBuiltInClientProfiles,
  });

  final http.Client httpClient;
  final List<ClientProfile> profiles;

  /// Returns the fallback chain of profiles to try.
  List<ClientProfile> get _profileChain =>
      profiles.where((p) => p.isValid).toList();

  /// Fetches subtitles for [videoId] in [lang] by trying each client profile
  /// in sequence, selecting the best matching caption track, and parsing the
  /// json3 timed text.
  Future<CaptionFetchResult> fetchSubtitles({
    required String videoId,
    String lang = 'en',
  }) async {
    final chain = _profileChain;
    if (chain.isEmpty) {
      return const CaptionFetchResult(error: 'No valid client profiles');
    }

    final failures = <String>[];
    for (final profile in chain) {
      try {
        final playerData = await _fetchPlayer(
          videoId: videoId,
          profile: profile,
        );

        final tracks = _extractCaptionTracks(playerData);
        if (tracks.isEmpty) {
          failures.add('${profile.name}: OK but no caption tracks');
          continue;
        }

        final track = _selectCaptionTrack(tracks, lang);
        if (track == null) {
          return CaptionFetchResult(
            error: 'No caption track matching language "$lang"',
          );
        }

        final source = _determineSource(track);
        final subtitles = await _fetchCaptionTrack(track);
        return CaptionFetchResult(
          subtitles: subtitles,
          source: source,
          language: track.languageCode ?? lang,
          fetchProfile: profile.name,
        );
      } on Object catch (e) {
        failures.add('${profile.name}: $e');
      }
    }

    return CaptionFetchResult(
      error: 'All profiles failed:\n${failures.join('\n')}',
    );
  }

  /// POSTs to the InnerTube `/player` endpoint with [profile]'s credentials.
  Future<Map<String, dynamic>> _fetchPlayer({
    required String videoId,
    required ClientProfile profile,
  }) async {
    final body = {
      'context': {
        'client': {
          'clientName': profile.clientName,
          'clientVersion': profile.clientVersion,
          'hl': 'en',
          'gl': 'US',
          ...profile.context,
        },
        'user': {'lockedSafetyMode': false},
        'request': {'useSsl': true},
      },
      'videoId': videoId,
      'contentCheckOk': true,
      'racyCheckOk': true,
    };

    final response = await httpClient.post(
      Uri.parse(_innertubeEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'User-Agent': profile.userAgent,
        'X-YouTube-Client-Name': profile.clientNameHeader,
        'X-YouTube-Client-Version': profile.clientVersion,
        'Origin': 'https://www.youtube.com',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'InnerTube /player failed: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status =
        (data['playabilityStatus'] as Map<String, dynamic>?)?['status']
            as String?;

    if (status != null && status != 'OK') {
      throw Exception('Video not playable: $status');
    }

    return data;
  }

  /// Extracts caption tracks from the InnerTube player response.
  List<CaptionTrack> _extractCaptionTracks(Map<String, dynamic> playerData) {
    final captions = playerData['captions'] as Map<String, dynamic>?;
    if (captions == null) return [];
    final renderer =
        captions['playerCaptionsTracklistRenderer'] as Map<String, dynamic>?;
    if (renderer == null) return [];
    final tracks = renderer['captionTracks'] as List?;
    if (tracks == null) return [];
    return tracks
        .whereType<Map<String, dynamic>>()
        .map(CaptionTrack.fromJson)
        .where((t) => t.baseUrl.isNotEmpty)
        .toList();
  }

  /// Selects the best caption track for [lang].
  ///
  /// Precedence: manual captions > auto-generated > language code match >
  /// partial vssId match > first available.
  CaptionTrack? _selectCaptionTrack(List<CaptionTrack> tracks, String lang) {
    if (tracks.isEmpty) return null;
    return tracks.firstWhere(
      (t) => t.vssId == '.$lang',
      orElse: () => tracks.firstWhere(
        (t) => t.vssId == 'a.$lang',
        orElse: () => tracks.firstWhere(
          (t) => t.languageCode == lang,
          orElse: () => tracks.firstWhere(
            (t) => t.vssId?.contains('.$lang') ?? false,
            orElse: () => tracks.first,
          ),
        ),
      ),
    );
  }

  /// Determines source label from the selected track's kind.
  String _determineSource(CaptionTrack track) {
    if (track.vssId != null && track.vssId!.startsWith('a.')) return 'auto';
    if (track.kind == 'asr') return 'auto';
    return 'official';
  }

  /// Fetches the caption track data in json3 format and parses to segments.
  Future<List<TranscriptLine>> _fetchCaptionTrack(CaptionTrack track) async {
    var url = track.baseUrl.replaceAll(RegExp(r'&fmt=[^&]+'), '');
    url += '&fmt=json3';

    final response = await httpClient.get(
      Uri.parse(url),
      headers: {'User-Agent': kBuiltInClientProfiles.first.userAgent},
    );

    if (response.statusCode != 200) {
      throw Exception('Caption fetch failed: ${response.statusCode}');
    }

    final text = response.body.trim();
    if (text.isEmpty) return [];

    final dynamic data;
    try {
      data = jsonDecode(text);
    } on FormatException {
      throw Exception('Caption response was not valid JSON');
    }

    if (data is! Map) return [];

    final events = data['events'] as List?;
    if (events == null) return [];

    final subtitles = <TranscriptLine>[];
    for (final event in events) {
      if (event is! Map) continue;
      final aAppend = event['aAppend'];
      if (aAppend == 1) continue;
      final segs = event['segs'] as List?;
      if (segs == null || segs.isEmpty) continue;

      final raw = segs
          .whereType<Map>()
          .map((s) => (s['utf8'] as String?) ?? '')
          .join();
      final cleaned = cleanHtmlText(raw);
      if (cleaned.isEmpty) continue;

      final tStartMs = (event['tStartMs'] as num?)?.toInt() ?? 0;
      final dDurationMs = (event['dDurationMs'] as num?)?.toInt() ?? 0;

      subtitles.add(
        TranscriptLine(
          text: cleaned,
          startMs: tStartMs,
          durationMs: dDurationMs,
        ),
      );
    }

    return subtitles;
  }
}
