import 'dart:async';
import 'dart:math';

import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_due_preview.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_srs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const int _kBenchItems = 5000;
const int _kBenchDue = 654;
const int _kWarmupPasses = 200;
const int _kSamples = 30;
const int _kRounds = 3;
const int _kFuzzCorpora = 120;

final DateTime _kNow = DateTime.utc(2026, 6, 15, 12);

int _benchSink = 0;

VocabularyItem _item(
  String id, {
  required DateTime nextReviewAt,
  DateTime? lastReviewedAt,
  String word = 'unused',
}) {
  final created = DateTime.utc(2024, 1, 1);
  return VocabularyItem(
    id: id,
    word: word,
    language: 'en',
    targetLanguage: 'zh',
    status: VocabularyStatus.new_,
    easeFactor: kDefaultEaseFactor,
    interval: 0,
    nextReviewAt: nextReviewAt,
    reviewsCount: 0,
    lastReviewedAt: lastReviewedAt,
    contextsCount: 0,
    createdAt: created,
    updatedAt: created,
  );
}

List<VocabularyItem> _benchItems() {
  final random = Random(20260615);
  final items = <VocabularyItem>[];
  var dueLeft = _kBenchDue;
  for (var i = 0; i < _kBenchItems; i++) {
    final due = dueLeft > 0 && random.nextDouble() < _kBenchDue / _kBenchItems;
    if (due) dueLeft--;
    items.add(
      _item(
        'i$i',
        word: 'word$i',
        nextReviewAt: due
            ? _kNow.subtract(Duration(minutes: random.nextInt(20160)))
            : _kNow.add(Duration(minutes: random.nextInt(20160) + 1)),
        lastReviewedAt: due && random.nextBool()
            ? _kNow.subtract(Duration(days: random.nextInt(30) + 2))
            : null,
      ),
    );
  }
  return items;
}

List<VocabularyItem> _fuzzItems(Random random) {
  final count = random.nextInt(60) + 1;
  return [
    for (var i = 0; i < count; i++)
      _item(
        'f$i',
        word: 'w$i',
        nextReviewAt: _kNow.add(Duration(hours: random.nextInt(240) - 120)),
        lastReviewedAt: random.nextBool()
            ? _kNow.add(Duration(hours: random.nextInt(240) - 200))
            : null,
      ),
  ];
}

int _legacySink(List<VocabularyItem> items) {
  final words = buildVocabularySessionQueue(
    items: items,
    options: const ReviewSelectionOptions(mode: VocabularyReviewMode.due),
    now: _kNow,
  ).map((i) => i.word).toList();
  var sink = words.length;
  for (final word in words.take(kVocabularyDuePreviewWords)) {
    sink += word.length;
  }
  return sink;
}

int _previewSink(VocabularyDuePreview preview) {
  var sink = preview.count;
  for (final word in preview.firstWords) {
    sink += word.length;
  }
  return sink;
}

List<double> _benchRounds(void Function() pass, String tag) {
  final medians = <double>[];
  for (var round = 0; round < _kRounds; round++) {
    for (var i = 0; i < _kWarmupPasses; i++) {
      pass();
    }
    final samples = <double>[];
    for (var i = 0; i < _kSamples; i++) {
      final sw = Stopwatch()..start();
      pass();
      sw.stop();
      samples.add(sw.elapsedMicroseconds / 1000);
    }
    samples.sort();
    medians.add(samples[samples.length ~/ 2]);
  }
  // ignore: avoid_print
  print(
    '$tag rounds: ${medians.map((m) => m.toStringAsFixed(3)).join(' / ')} '
    'ms/pass (sink=$_benchSink)',
  );
  return medians;
}

void main() {
  group('buildVocabularyDuePreview matches the due-mode session queue', () {
    test(
      'due boundary: nextReviewAt exactly now is due, a tick later is not',
      () {
        final items = [
          _item('a', word: 'edge', nextReviewAt: _kNow),
          _item(
            'b',
            word: 'future',
            nextReviewAt: _kNow.add(const Duration(milliseconds: 1)),
          ),
        ];
        final preview = buildVocabularyDuePreview(items: items, now: _kNow);
        expect(preview.count, 1);
        expect(preview.firstWords, ['edge']);
      },
    );

    test('lastReviewedAt boundaries follow isVocabularyItemDue', () {
      final past = _kNow.subtract(const Duration(days: 2));
      final items = [
        _item('never', word: 'a', nextReviewAt: past),
        _item(
          'before',
          word: 'b',
          nextReviewAt: past,
          lastReviewedAt: _kNow.subtract(const Duration(days: 5)),
        ),
        _item('equal', word: 'c', nextReviewAt: past, lastReviewedAt: past),
        _item(
          'after',
          word: 'd',
          nextReviewAt: past,
          lastReviewedAt: _kNow.subtract(const Duration(days: 1)),
        ),
      ];
      final queue = buildVocabularySessionQueue(
        items: items,
        options: const ReviewSelectionOptions(mode: VocabularyReviewMode.due),
        now: _kNow,
      );
      final preview = buildVocabularyDuePreview(items: items, now: _kNow);
      expect(queue.map((i) => i.id), ['never', 'before']);
      expect(preview.count, 2);
      expect(preview.firstWords, ['a', 'b']);
    });

    test('item order is preserved, no sorting', () {
      final items = [
        _item(
          'z',
          word: 'zebra',
          nextReviewAt: _kNow.subtract(const Duration(days: 1)),
        ),
        _item(
          'm',
          word: 'mango',
          nextReviewAt: _kNow.add(const Duration(days: 1)),
        ),
        _item('a', word: 'apple', nextReviewAt: _kNow),
      ];
      final preview = buildVocabularyDuePreview(items: items, now: _kNow);
      expect(preview.firstWords, ['zebra', 'apple']);
    });

    test(
      'truncates to kVocabularyDuePreviewWords and keeps the overflow count',
      () {
        final items = [
          for (var i = 0; i < 7; i++)
            _item(
              'i$i',
              word: 'w$i',
              nextReviewAt: _kNow.subtract(const Duration(days: 1)),
            ),
        ];
        final preview = buildVocabularyDuePreview(items: items, now: _kNow);
        expect(preview.count, 7);
        expect(preview.firstWords, ['w0', 'w1', 'w2', 'w3', 'w4']);
        expect(preview.count - preview.firstWords.length, 2);
      },
    );

    test('fewer due words than the cap keep them all', () {
      final items = [
        for (var i = 0; i < 3; i++)
          _item(
            'i$i',
            word: 'w$i',
            nextReviewAt: _kNow.subtract(const Duration(days: 1)),
          ),
      ];
      final preview = buildVocabularyDuePreview(items: items, now: _kNow);
      expect(preview.count, 3);
      expect(preview.firstWords, ['w0', 'w1', 'w2']);
    });

    test('no due items yields count 0 and the shared empty list', () {
      final preview = buildVocabularyDuePreview(
        items: [
          _item(
            'a',
            word: 'a',
            nextReviewAt: _kNow.add(const Duration(days: 1)),
          ),
        ],
        now: _kNow,
      );
      expect(preview.count, 0);
      expect(preview.firstWords, isEmpty);
      expect(identical(preview.firstWords, const <String>[]), isTrue);
    });

    test('maxWords override bounds the preview without touching the count', () {
      final items = [
        for (var i = 0; i < 5; i++)
          _item(
            'i$i',
            word: 'w$i',
            nextReviewAt: _kNow.subtract(const Duration(days: 1)),
          ),
      ];
      final preview = buildVocabularyDuePreview(
        items: items,
        now: _kNow,
        maxWords: 2,
      );
      expect(preview.count, 5);
      expect(preview.firstWords, ['w0', 'w1']);
    });

    test('preview firstWords are unmodifiable', () {
      final items = [_item('a', word: 'a', nextReviewAt: _kNow)];
      final preview = buildVocabularyDuePreview(items: items, now: _kNow);
      expect(() => preview.firstWords.add('x'), throwsUnsupportedError);
    });

    test('value equality pins', () {
      final due = _kNow.subtract(const Duration(days: 1));
      final a = buildVocabularyDuePreview(
        items: [_item('x', word: 'w', nextReviewAt: due)],
        now: _kNow,
      );
      final b = buildVocabularyDuePreview(
        items: [_item('y', word: 'w', nextReviewAt: due)],
        now: _kNow,
      );
      final c = buildVocabularyDuePreview(
        items: [_item('x', word: 'other', nextReviewAt: due)],
        now: _kNow,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      expect(identical(a, b), isFalse);
    });

    test('seeded fuzz corpora agree with the due-mode queue', () {
      final random = Random(20260615);
      for (var corpus = 0; corpus < _kFuzzCorpora; corpus++) {
        final items = _fuzzItems(random);
        final queue = buildVocabularySessionQueue(
          items: items,
          options: const ReviewSelectionOptions(mode: VocabularyReviewMode.due),
          now: _kNow,
        );
        final preview = buildVocabularyDuePreview(items: items, now: _kNow);
        expect(
          preview.count,
          queue.length,
          reason: 'corpus $corpus count mismatch',
        );
        expect(
          preview.firstWords,
          queue
              .take(kVocabularyDuePreviewWords)
              .map((i) => i.word)
              .toList(growable: false),
          reason: 'corpus $corpus firstWords mismatch',
        );
      }
    });
  });

  group('vocabularyDuePreviewProvider', () {
    test('recomputes per items emission and caches between reads', () async {
      final controller = StreamController<List<VocabularyItem>>();
      addTearDown(controller.close);
      final container = ProviderContainer(
        overrides: [
          vocabularyItemsProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(vocabularyDuePreviewProvider, (_, _) {});
      addTearDown(sub.close);

      final realNow = DateTime.now();
      final dueA = realNow.subtract(const Duration(days: 1));
      final dueB = realNow.subtract(const Duration(hours: 2));

      final first = List<VocabularyItem>.of([
        _item('a', word: 'due-a', nextReviewAt: dueA),
      ]);
      controller.add(first);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final v1 = container.read(vocabularyDuePreviewProvider);
      expect(v1.count, 1);
      expect(v1.firstWords, ['due-a']);
      expect(
        identical(container.read(vocabularyDuePreviewProvider), v1),
        isTrue,
      );

      final second = List<VocabularyItem>.of([
        _item('a', word: 'due-a', nextReviewAt: dueA),
        _item('b', word: 'due-b', nextReviewAt: dueB),
        _item(
          'c',
          word: 'later',
          nextReviewAt: realNow.add(const Duration(days: 1)),
        ),
      ]);
      controller.add(second);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final v2 = container.read(vocabularyDuePreviewProvider);
      expect(identical(v2, v1), isFalse);
      expect(v2.count, 2);
      expect(v2.firstWords, ['due-a', 'due-b']);
      expect(
        identical(container.read(vocabularyDuePreviewProvider), v2),
        isTrue,
      );

      final third = List<VocabularyItem>.of([
        _item('a', word: 'due-a', nextReviewAt: dueA),
        _item('b', word: 'due-b', nextReviewAt: dueB),
        _item(
          'd',
          word: 'idle',
          nextReviewAt: realNow.add(const Duration(days: 2)),
        ),
      ]);
      controller.add(third);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final v3 = container.read(vocabularyDuePreviewProvider);
      expect(identical(v3, v2), isFalse);
      expect(v3, equals(v2));
    });
  });

  test('bench (local only): legacy full queue + word list per emission', () {
    final items = _benchItems();
    final medians = _benchRounds(() {
      _benchSink = _legacySink(items);
    }, 'due preview legacy');
    expect(medians.last, lessThan(10));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): single-pass due preview per emission', () {
    final items = _benchItems();
    final medians = _benchRounds(() {
      _benchSink = _previewSink(
        buildVocabularyDuePreview(items: items, now: _kNow),
      );
    }, 'due preview single-pass');
    expect(medians.last, lessThan(10));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}
