import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';

void main() {
  test('AsrResult.fromJson parses segments and words', () {
    final json = <String, dynamic>{
      'text': 'hello world',
      'segments': [
        {
          'start': 0.0,
          'end': 1.2,
          'text': 'hello',
          'words': [
            {'word': 'hello', 'start': 0.0, 'end': 0.5},
          ],
        },
      ],
      'transcriptionInfo': {'language': 'en', 'duration': 3.5},
      'wordCount': 2,
    };
    final r = AsrResult.fromJson(json);
    expect(r.text, 'hello world');
    expect(r.language, 'en');
    expect(r.duration, 3.5);
    expect(r.wordCount, 2);
    expect(r.segments, isNotNull);
    expect(r.segments!.length, 1);
    expect(r.segments!.first.words!.length, 1);
    expect(r.segments!.first.words!.first.word, 'hello');
  });
}
