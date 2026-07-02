import 'package:enjoy_player/core/json/json_cast.dart';

/// Whisper-style JSON response (keys camelCase after [ApiClient] decode).
final class AsrResult {
  factory AsrResult.fromJson(Map<String, dynamic> json) {
    final segs = json['segments'] as List<dynamic>?;
    final transcriptionInfo = castJsonObjectOrNull(json['transcriptionInfo']);
    return AsrResult(
      text: json['text'] as String? ?? '',
      segments: segs
          ?.map((e) => AsrSegment.fromJson(castJsonObjectOrNull(e) ?? const {}))
          .toList(),
      language:
          transcriptionInfo?['language'] as String? ??
          json['language'] as String?,
      duration: (transcriptionInfo?['duration'] as num?)?.toDouble(),
      wordCount: json['wordCount'] as int? ?? json['word_count'] as int?,
    );
  }
  const AsrResult({
    required this.text,
    this.segments,
    this.language,
    this.duration,
    this.wordCount,
  });

  final String text;
  final List<AsrSegment>? segments;
  final String? language;
  final double? duration;
  final int? wordCount;
}

final class AsrSegment {
  factory AsrSegment.fromJson(Map<String, dynamic> json) {
    final w = json['words'] as List<dynamic>?;
    return AsrSegment(
      start: (json['start'] as num?)?.toDouble() ?? 0,
      end: (json['end'] as num?)?.toDouble() ?? 0,
      text: json['text'] as String? ?? '',
      words: w
          ?.map((e) => AsrWord.fromJson(castJsonObjectOrNull(e) ?? const {}))
          .toList(),
    );
  }
  const AsrSegment({
    required this.start,
    required this.end,
    required this.text,
    this.words,
  });

  final double start;
  final double end;
  final String text;
  final List<AsrWord>? words;
}

final class AsrWord {
  factory AsrWord.fromJson(Map<String, dynamic> json) {
    return AsrWord(
      word: json['word'] as String? ?? '',
      start: (json['start'] as num?)?.toDouble() ?? 0,
      end: (json['end'] as num?)?.toDouble() ?? 0,
    );
  }
  const AsrWord({required this.word, required this.start, required this.end});

  final String word;
  final double start;
  final double end;
}
