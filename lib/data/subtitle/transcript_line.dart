/// Single subtitle cue line: text + start + duration in milliseconds (web parity).
library;

import 'package:meta/meta.dart';

@immutable
class TranscriptLine {
  const TranscriptLine({
    required this.text,
    required this.startMs,
    required this.durationMs,
    this.sourceKey,
  });

  final String text;
  final int startMs;
  final int durationMs;

  /// Content fingerprint for AI auto-translate overlays (optional).
  ///
  /// When set, bilingual UI may validate that this cue still matches the
  /// primary line text + language pair before showing [text].
  final String? sourceKey;

  double get startSeconds => startMs / 1000.0;

  double get endSeconds => (startMs + durationMs) / 1000.0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranscriptLine &&
        other.text == text &&
        other.startMs == startMs &&
        other.durationMs == durationMs &&
        other.sourceKey == sourceKey;
  }

  @override
  int get hashCode => Object.hash(text, startMs, durationMs, sourceKey);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'text': text,
      'start': startMs,
      'duration': durationMs,
    };
    final key = sourceKey;
    if (key != null && key.isNotEmpty) {
      map['sourceKey'] = key;
    }
    return map;
  }

  static TranscriptLine fromJson(Map<String, dynamic> json) {
    final rawKey = json['sourceKey'] as String?;
    return TranscriptLine(
      text: json['text'] as String? ?? '',
      startMs: (json['start'] as num?)?.toInt() ?? 0,
      durationMs: (json['duration'] as num?)?.toInt() ?? 0,
      sourceKey: (rawKey != null && rawKey.isNotEmpty) ? rawKey : null,
    );
  }
}
