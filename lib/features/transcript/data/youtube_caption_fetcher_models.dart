part of 'youtube_caption_fetcher.dart';

/// Transient descriptor for a YouTube caption track.
class CaptionTrack {
  const CaptionTrack({
    required this.baseUrl,
    this.vssId,
    this.languageCode,
    this.kind,
  });

  factory CaptionTrack.fromJson(Map<String, dynamic> json) {
    return CaptionTrack(
      baseUrl: json['baseUrl'] as String? ?? '',
      vssId: json['vssId'] as String?,
      languageCode: json['languageCode'] as String?,
      kind: json['kind'] as String?,
    );
  }

  final String baseUrl;
  final String? vssId;
  final String? languageCode;
  final String? kind;
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

/// Outcome of fetching all available caption tracks for a video.
class AllCaptionsResult {
  const AllCaptionsResult({
    this.results = const [],
    this.fetchProfile = '',
    this.error,
  });

  final List<CaptionFetchResult> results;
  final String fetchProfile;
  final String? error;

  bool get isSuccess => error == null && results.isNotEmpty;
}
