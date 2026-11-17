part of 'youtube_caption_fetcher.dart';

/// InnerTube API endpoint.
const _innertubeEndpoint =
    'https://youtubei.googleapis.com/youtubei/v1/player?prettyPrint=false';

/// InnerTube `/player` transport and player-response parsing.
extension _YoutubeCaptionFetcherPlayer on YoutubeCaptionFetcher {
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
      throw YoutubeCaptionFetchException(
        stage: YoutubeCaptionErrorStage.innertubePlayer,
        statusCode: response.statusCode,
        message:
            'InnerTube /player failed: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final data = await decodeJsonGated(response.body) as Map<String, dynamic>;
    final status =
        (data['playabilityStatus'] as Map<String, dynamic>?)?['status']
            as String?;

    if (status != null && status != 'OK') {
      throw YoutubeCaptionFetchException(
        stage: YoutubeCaptionErrorStage.innertubePlayability,
        message: 'Video not playable: $status',
      );
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
}
