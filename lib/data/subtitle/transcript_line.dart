/// Single subtitle cue line: text + start + duration in milliseconds (web parity).
library;

import 'package:meta/meta.dart';

@immutable
class TranscriptLine {
  const TranscriptLine({
    required this.text,
    required this.startMs,
    required this.durationMs,
  });

  final String text;
  final int startMs;
  final int durationMs;

  double get startSeconds => startMs / 1000.0;

  double get endSeconds => (startMs + durationMs) / 1000.0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranscriptLine &&
        other.text == text &&
        other.startMs == startMs &&
        other.durationMs == durationMs;
  }

  @override
  int get hashCode => Object.hash(text, startMs, durationMs);

  Map<String, dynamic> toJson() => {
    'text': text,
    'start': startMs,
    'duration': durationMs,
  };

  static TranscriptLine fromJson(Map<String, dynamic> json) {
    return TranscriptLine(
      text: json['text'] as String? ?? '',
      startMs: (json['start'] as num?)?.toInt() ?? 0,
      durationMs: (json['duration'] as num?)?.toInt() ?? 0,
    );
  }
}
