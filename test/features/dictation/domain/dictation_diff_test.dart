import 'package:enjoy_player/features/dictation/domain/dictation_diff.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dictationWordOf', () {
    test('normalizes casing and strips apostrophes and punctuation', () {
      expect(dictationWordOf("It's"), 'its');
      expect(dictationWordOf('don’t'), 'dont');
      expect(dictationWordOf('Hello,'), 'hello');
      expect(dictationWordOf('world!'), 'world');
      expect(dictationWordOf('semi;colon:'), 'semicolon');
      expect(dictationWordOf('[brackets]'), 'brackets');
      expect(dictationWordOf('dash-dash—em'), 'dashdashem');
    });
  });

  group('tokenizeDictationWords', () {
    test('splits whitespace and skips empty entries', () {
      expect(tokenizeDictationWords('  Hello   world \t from \n dart  '), [
        'Hello',
        'world',
        'from',
        'dart',
      ]);
    });
  });

  group('computeDictationDiff', () {
    test('returns 100% accuracy and correct tokens for identical input', () {
      final res = computeDictationDiff('Hello, world!', 'hello WORLD');
      expect(res.accuracy, 100);
      expect(res.correctWords, 2);
      expect(res.missedWords, 0);
      expect(res.extraWords, 0);
      expect(res.tokens.map((t) => (t.word, t.op)), [
        ('Hello,', DictationWordDiffOp.correct),
        ('world!', DictationWordDiffOp.correct),
      ]);
    });

    test('handles missed and extra tokens correctly', () {
      final res = computeDictationDiff('the quick brown fox', 'the fast fox');
      expect(res.correctWords, 2);
      expect(res.missedWords, 2);
      expect(res.extraWords, 1);
      expect(res.accuracy, 40);

      expect(
        res.tokens.any(
          (t) => t.word == 'quick' && t.op == DictationWordDiffOp.missed,
        ),
        isTrue,
      );
      expect(
        res.tokens.any(
          (t) => t.word == 'brown' && t.op == DictationWordDiffOp.missed,
        ),
        isTrue,
      );
      expect(
        res.tokens.any(
          (t) => t.word == 'fast' && t.op == DictationWordDiffOp.extra,
        ),
        isTrue,
      );
      expect(
        res.tokens.any(
          (t) => t.word == 'the' && t.op == DictationWordDiffOp.correct,
        ),
        isTrue,
      );
      expect(
        res.tokens.any(
          (t) => t.word == 'fox' && t.op == DictationWordDiffOp.correct,
        ),
        isTrue,
      );
    });

    test('handles completely empty input and reference', () {
      final resEmpty = computeDictationDiff('', '');
      expect(resEmpty.accuracy, 100);
      expect(resEmpty.tokens, isEmpty);

      final resMissed = computeDictationDiff('hello world', '');
      expect(resMissed.accuracy, 0);
      expect(resMissed.missedWords, 2);
      expect(resMissed.correctWords, 0);
    });

    test(
      'ignores standalone dashes and punctuation in accuracy calculation',
      () {
        final res = computeDictationDiff('Hello — world', 'hello world');
        expect(res.accuracy, 100);
        expect(res.correctWords, 2);
        expect(res.missedWords, 0);
        expect(res.extraWords, 0);
        expect(res.tokens.map((t) => t.word), ['Hello', 'world']);
      },
    );
  });
}
