part of 'youtube_caption_fetcher.dart';

/// Strips an existing `fmt=` query parameter from a timedtext base URL.
final RegExp _fmtQueryParamRegExp = RegExp(r'&fmt=[^&]+');

/// Timedtext transport and json3 parsing.
extension _YoutubeCaptionFetcherTimedText on YoutubeCaptionFetcher {
  /// Fetches the caption track data in json3 format and parses to segments.
  ///
  /// Uses [profile]'s user agent and a matching `Referer` so the timedtext
  /// endpoint sees a consistent client identity with the `/player` call that
  /// succeeded. Mixing the iOS UA on a non-iOS profile silently returns
  /// empty / 403 on real YouTube.
  Future<List<TranscriptLine>> _fetchCaptionTrack(
    CaptionTrack track,
    ClientProfile profile,
  ) async {
    var url = track.baseUrl.replaceAll(_fmtQueryParamRegExp, '');
    url += '&fmt=json3';

    final response = await httpClient.get(
      Uri.parse(url),
      headers: {
        'User-Agent': profile.userAgent,
        'Referer': 'https://m.youtube.com/',
        'Accept-Language': 'en-US,en;q=0.9',
      },
    );

    if (response.statusCode != 200) {
      throw YoutubeCaptionFetchException(
        stage: YoutubeCaptionErrorStage.timedTextGet,
        statusCode: response.statusCode,
        message: 'Caption fetch failed: ${response.statusCode}',
      );
    }

    final text = response.body.trim();
    if (text.isEmpty) return [];

    final dynamic data;
    try {
      data = await decodeJsonGated(text);
    } on FormatException {
      throw YoutubeCaptionFetchException(
        stage: YoutubeCaptionErrorStage.timedTextJson,
        message: 'Caption response was not valid JSON',
      );
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
