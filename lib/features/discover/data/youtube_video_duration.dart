/// Best-effort YouTube watch-page duration (public HTML, no API key).
library;

import 'package:http/http.dart' as http;

import 'youtube_fetch.dart';

abstract final class YoutubeVideoDuration {
  static final _lengthSeconds = RegExp(r'"lengthSeconds"\s*:\s*"(\d+)"');
  static final _approxDurationMs = RegExp(r'"approxDurationMs"\s*:\s*"(\d+)"');

  /// Returns duration in whole seconds, or null when unavailable.
  static Future<int?> fetchSeconds(http.Client client, String videoId) async {
    final uri = Uri.parse(
      'https://www.youtube.com/watch?v=${Uri.encodeComponent(videoId)}',
    );
    try {
      final response = await YoutubeFetch.getHtml(client, uri);
      if (response.statusCode != 200) return null;
      return parseSecondsFromHtml(response.body);
    } on Object {
      return null;
    }
  }

  static int? parseSecondsFromHtml(String html) {
    final lengthMatch = _lengthSeconds.firstMatch(html);
    if (lengthMatch != null) {
      return int.tryParse(lengthMatch.group(1)!);
    }
    final msMatch = _approxDurationMs.firstMatch(html);
    if (msMatch != null) {
      final ms = int.tryParse(msMatch.group(1)!);
      if (ms != null && ms > 0) return (ms / 1000).round();
    }
    return null;
  }
}
