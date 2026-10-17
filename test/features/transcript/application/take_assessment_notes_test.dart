import 'dart:convert';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/take_assessment_notes.dart';
import 'package:enjoy_player/features/transcript/application/take_assessment_notes_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final _lines = [
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

const _echo = EchoState(
  active: true,
  startLineIndex: 0,
  endLineIndex: 0,
  startTimeSeconds: 0,
  endTimeSeconds: 4.2,
);

void main() {
  test('decodes and normalizes mispronounced words', () {
    expect(takeAssessmentErrorWords(_assessmentJson), {'dont', 'ferry'});
  });

  test('malformed or empty payloads have no notes', () {
    expect(takeAssessmentErrorWords('not json'), isEmpty);
    expect(takeAssessmentErrorWords(''), isEmpty);
    expect(takeAssessmentErrorWords('[]'), isEmpty);
  });

  test('maps normalized errors to line/word indexes', () {
    final notes = TakeAssessmentNotes.from(
      lines: _lines,
      echo: _echo,
      errorWords: takeAssessmentErrorWords(_assessmentJson),
    );

    expect(notes?.byLine, {
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
    final errors = takeAssessmentErrorWords(json);
    expect(errors, isEmpty);
    expect(
      TakeAssessmentNotes.from(lines: _lines, echo: _echo, errorWords: errors),
      isNull,
    );
  });

  test('provider memoizes notes for one assessment revision', () async {
    final container = ProviderContainer(
      overrides: [
        transcriptLinesForMediaProvider(
          'm1',
        ).overrideWith((ref) => Stream.value(_lines)),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(echoModeProvider.notifier)
        .activate(
          startLineIndex: 0,
          endLineIndex: 0,
          startTimeSeconds: 0,
          endTimeSeconds: 4.2,
        );
    final key = (
      mediaId: 'm1',
      recordingId: 'rec-1',
      assessmentJson: _assessmentJson,
    );
    final sub = container.listen(
      takeAssessmentNotesProvider(key),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    for (var i = 0; i < 50; i++) {
      if (container.read(takeAssessmentNotesProvider(key)) != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    final first = container.read(takeAssessmentNotesProvider(key));
    expect(first?.byLine, {
      0: {1, 4},
    });
    expect(
      identical(first, container.read(takeAssessmentNotesProvider(key))),
      isTrue,
      reason: 'a rebuild must reuse the memoized notes',
    );
  });

  test('a different assessment revision recomputes', () async {
    final container = ProviderContainer(
      overrides: [
        transcriptLinesForMediaProvider(
          'm1',
        ).overrideWith((ref) => Stream.value(_lines)),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(echoModeProvider.notifier)
        .activate(
          startLineIndex: 0,
          endLineIndex: 0,
          startTimeSeconds: 0,
          endTimeSeconds: 4.2,
        );
    final key = (
      mediaId: 'm1',
      recordingId: 'rec-1',
      assessmentJson: _assessmentJson,
    );
    final sub = container.listen(
      takeAssessmentNotesProvider(key),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    for (var i = 0; i < 50; i++) {
      if (container.read(takeAssessmentNotesProvider(key)) != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final other = jsonEncode({
      'RecognitionStatus': 'Success',
      'NBest': [
        {
          'Words': [
            {
              'Word': 'ferry',
              'PronunciationAssessment': {
                'AccuracyScore': 40,
                'ErrorType': 'Mispronunciation',
              },
            },
          ],
        },
      ],
    });
    final otherKey = (
      mediaId: 'm1',
      recordingId: 'rec-1',
      assessmentJson: other,
    );
    final sub2 = container.listen(
      takeAssessmentNotesProvider(otherKey),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub2.close);
    for (var i = 0; i < 50; i++) {
      if (container.read(takeAssessmentNotesProvider(otherKey)) != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(container.read(takeAssessmentNotesProvider(otherKey))?.byLine, {
      0: {4},
    });
  });
}
