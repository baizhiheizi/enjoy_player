/// Whisper-style JSON response (keys camelCase after [ApiClient] decode).
final class AsrResult {
  factory AsrResult.fromJson(Map<String, dynamic> json) {
    final segs = json['segments'] as List<dynamic>?;
    final transcriptionInfo = _jsonMap(json['transcriptionInfo']);
    return AsrResult(
      text: json['text'] as String? ?? '',
      segments: segs
          ?.map((e) => AsrSegment.fromJson(_jsonMap(e) ?? const {}))
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
      words: w?.map((e) => AsrWord.fromJson(_jsonMap(e) ?? const {})).toList(),
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

/// JSON nested objects decode as [Map<dynamic, dynamic>]; normalize for casts.
Map<String, dynamic>? _jsonMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
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
