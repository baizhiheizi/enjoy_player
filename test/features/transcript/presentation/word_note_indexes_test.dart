import 'dart:convert';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/word_note_indexes.dart';
import 'package:flutter_test/flutter_test.dart';

const _assessmentJson = '''
{"RecognitionStatus":"Success","NBest":[{"Words":[
 {"Word":"You","PronunciationAssessment":{"AccuracyScore":95,"ErrorType":"None"}},
 {"Word":"don't","PronunciationAssessment":{"AccuracyScore":70,"ErrorType":"Mispronunciation"}},
 {"Word":"take","PronunciationAssessment":{"AccuracyScore":96,"ErrorType":"None"}},
 {"Word":"the","PronunciationAssessment":{"AccuracyScore":0,"ErrorType":"Omission"}},
 {"Word":"ferry.","PronunciationAssessment":{"AccuracyScore":64,"ErrorType":"Mispronunciation"}}
]}]}
''';

void main() {
  final lines = [
    const TranscriptLine(
      text: "You don't take the ferry.",
      startMs: 0,
      durationMs: 4200,
      timeline: [
        TranscriptWord(text: 'You'),
        TranscriptWord(text: "don't"),
        TranscriptWord(text: 'take'),
        TranscriptWord(text: 'the'),
        TranscriptWord(text: 'ferry.'),
      ],
    ),
  ];
  const echo = EchoState(
    active: true,
    startLineIndex: 0,
    endLineIndex: 0,
    startTimeSeconds: 0,
    endTimeSeconds: 4.2,
  );

  test('maps mispronounced words to aligned word indexes', () {
    final result = mispronouncedWordIndexes(
      lines: lines,
      echo: echo,
      assessmentJson: _assessmentJson,
    );
    expect(result, {
      0: {1, 4},
    });
  });

  test('omissions and correct words carry no note', () {
    final json = jsonEncode({
      'RecognitionStatus': 'Success',
      'NBest': [
        {
          'Words': [
            {
              'Word': 'You',
              'PronunciationAssessment': {
                'AccuracyScore': 95,
                'ErrorType': 'None',
              },
            },
            {
              'Word': 'the',
              'PronunciationAssessment': {
                'AccuracyScore': 0,
                'ErrorType': 'Omission',
              },
            },
          ],
        },
      ],
    });
    expect(
      mispronouncedWordIndexes(lines: lines, echo: echo, assessmentJson: json),
      isNull,
    );
  });

  test('null or malformed json yields no notes', () {
    expect(
      mispronouncedWordIndexes(lines: lines, echo: echo, assessmentJson: null),
      isNull,
    );
    expect(
      mispronouncedWordIndexes(
        lines: lines,
        echo: echo,
        assessmentJson: 'not json',
      ),
      isNull,
    );
  });
}
