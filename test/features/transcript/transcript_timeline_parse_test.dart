import 'dart:convert';

import 'package:enjoy_player/data/api/case_conversion.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/data/transcript_timeline_parse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('transcriptLinesFromApiTimeline', () {
    test('parses cues after convertKeysToCamel (nested maps are not Map<String,dynamic>)',
        () {
      const snake = '''
[{
  "id": "tid",
  "target_type": "Audio",
  "target_id": "mid",
  "language": "en",
  "source": "official",
  "timeline": [{"text": "hello", "start": 0, "duration": 500}],
  "created_at": "2025-01-01T00:00:00.000Z",
  "updated_at": "2025-01-01T00:00:00.000Z"
}]''';
      final decoded = convertKeysToCamel(jsonDecode(snake) as Object?) as List;
      final transcript =
          Map<String, dynamic>.from(
            (decoded.first as Map).map(
              (k, v) => MapEntry(k.toString(), v),
            ),
          );
      final timeline = transcript['timeline'];
      final firstCue = (timeline as List).first;
      expect(firstCue is Map<String, dynamic>, isFalse);

      final lines = transcriptLinesFromApiTimeline(timeline);
      expect(lines, hasLength(1));
      expect(lines.single.text, 'hello');
      expect(lines.single.startMs, 0);
      expect(lines.single.durationMs, 500);
    });

    test('still accepts Map<String, dynamic> cues', () {
      final lines = transcriptLinesFromApiTimeline(<Map<String, dynamic>>[
        {'text': 'a', 'start': 1, 'duration': 2},
      ]);
      expect(lines.single.text, 'a');
    });
  });
}
