import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_band.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DictationBand displays masked blocks when unchecked', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DictationBand(
            lines: [
              TranscriptLine(startMs: 0, durationMs: 1000, text: 'Hello world'),
            ],
            fallbackReferenceText: '',
            regionStartMs: 0,
            regionDurationMs: 1000,
            currentPlaybackMs: 0,
            diffResult: null,
          ),
        ),
      ),
    );

    expect(find.byType(Container), findsWidgets);
    expect(find.text('Hello'), findsNothing);
    expect(find.text('world'), findsNothing);
  });

  testWidgets('DictationBand displays diff spans and legend when checked', (
    tester,
  ) async {
    const diff = DictationDiffResult(
      tokens: [
        DictationDiffToken(word: 'hello', op: DictationWordDiffOp.correct),
        DictationDiffToken(word: 'brave', op: DictationWordDiffOp.extra),
        DictationDiffToken(word: 'world', op: DictationWordDiffOp.missed),
      ],
      accuracy: 50,
      correctWords: 1,
      missedWords: 1,
      extraWords: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DictationBand(
            lines: [],
            fallbackReferenceText: 'hello world',
            regionStartMs: 0,
            regionDurationMs: 1000,
            currentPlaybackMs: 0,
            diffResult: diff,
          ),
        ),
      ),
    );

    expect(find.byType(RichText), findsWidgets);
    expect(find.text('brave'), findsOneWidget);
    expect(find.text('[world]'), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('[Missed]'), findsOneWidget);
    expect(find.text('Extra'), findsOneWidget);
  });
}
