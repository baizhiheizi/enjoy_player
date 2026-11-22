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

const List<String> _kLanguages = ['de', 'en', 'fr', 'ja', 'zh'];

final DateTime _kNow = DateTime.utc(2026, 6, 15, 12);

int _benchSink = 0;

VocabularyItem _item(
  String id, {
  required DateTime nextReviewAt,
  DateTime? lastReviewedAt,
  String language = 'en',
  String word = 'unused',
}) {
  final created = DateTime.utc(2024, 1, 1);
  return VocabularyItem(
    id: id,
    word: word,
    language: language,
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

List<VocabularyItem> _benchItems([DateTime? anchor]) {
  final now = anchor ?? _kNow;
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
        language: _kLanguages[i % _kLanguages.length],
        nextReviewAt: due
            ? now.subtract(Duration(minutes: random.nextInt(20160)))
            : now.add(Duration(minutes: random.nextInt(20160) + 1)),
        lastReviewedAt: due && random.nextBool()
            ? now.subtract(Duration(days: random.nextInt(30) + 2))
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
        language: _kLanguages[random.nextInt(_kLanguages.length)],
        nextReviewAt: _kNow.add(Duration(hours: random.nextInt(240) - 120)),
        lastReviewedAt: random.nextBool()
            ? _kNow.add(Duration(hours: random.nextInt(240) - 200))
            : null,
      ),
  ];
}

List<String> _legacyLanguages(List<VocabularyItem> items) =>
    items.map((i) => i.language).toSet().toList()..sort();

int _legacyPanelSink(List<VocabularyItem> items) {
  final languages = _legacyLanguages(items);
  final dueLength = buildVocabularySessionQueue(
    items: items,
    options: const ReviewSelectionOptions(mode: VocabularyReviewMode.due),
    now: _kNow,
  ).length;
  final allLength = buildVocabularySessionQueue(
    items: items,
    options: const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
    now: _kNow,
  ).length;
  return languages.length + dueLength + allLength + items.length;
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
  group(
    'review panel count derivations match the session-queue derivations',
    () {
      test('due boundary: preview count equals the due-mode queue length', () {
        final items = [
          _item('a', word: 'edge', nextReviewAt: _kNow),
          _item(
            'b',
            word: 'future',
            nextReviewAt: _kNow.add(const Duration(milliseconds: 1)),
          ),
        ];
        final dueQueue = buildVocabularySessionQueue(
          items: items,
          options: const ReviewSelectionOptions(mode: VocabularyReviewMode.due),
          now: _kNow,
        );
        final preview = buildVocabularyDuePreview(items: items, now: _kNow);
        expect(preview.count, dueQueue.length);
        expect(preview.count, 1);
      });

      test('all-mode count is the item count', () {
        final items = [
          _item('a', word: 'a', nextReviewAt: _kNow),
          _item('b', word: 'b', nextReviewAt: _kNow),
          _item('c', word: 'c', nextReviewAt: _kNow),
        ];
        final allQueue = buildVocabularySessionQueue(
          items: items,
          options: const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
          now: _kNow,
        );
        expect(items.length, allQueue.length);
      });

      test('seeded fuzz corpora agree on due, all, and language counts', () {
        final random = Random(20260615);
        for (var corpus = 0; corpus < _kFuzzCorpora; corpus++) {
          final items = _fuzzItems(random);
          final dueQueue = buildVocabularySessionQueue(
            items: items,
            options: const ReviewSelectionOptions(
              mode: VocabularyReviewMode.due,
            ),
            now: _kNow,
          );
          expect(
            buildVocabularyDuePreview(items: items, now: _kNow).count,
            dueQueue.length,
            reason: 'corpus $corpus due count mismatch',
          );
          expect(
            items.length,
            buildVocabularySessionQueue(
              items: items,
              options: const ReviewSelectionOptions(
                mode: VocabularyReviewMode.all,
              ),
              now: _kNow,
            ).length,
            reason: 'corpus $corpus all count mismatch',
          );
        }
      });
    },
  );

  group('vocabularyListLanguagesProvider', () {
    test('recomputes per items emission and caches between reads', () async {
      final controller = StreamController<List<VocabularyItem>>();
      addTearDown(controller.close);
      final container = ProviderContainer(
        overrides: [
          vocabularyItemsProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(vocabularyListLanguagesProvider, (_, _) {});
      addTearDown(sub.close);

      controller.add(
        List<VocabularyItem>.of([
          _item('a', word: 'a', language: 'ja', nextReviewAt: _kNow),
          _item('b', word: 'b', language: 'en', nextReviewAt: _kNow),
          _item('c', word: 'c', language: 'ja', nextReviewAt: _kNow),
        ]),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final v1 = container.read(vocabularyListLanguagesProvider);
      expect(v1, ['en', 'ja']);
      expect(
        identical(container.read(vocabularyListLanguagesProvider), v1),
        isTrue,
      );

      controller.add(
        List<VocabularyItem>.of([
          _item('a', word: 'a', language: 'ja', nextReviewAt: _kNow),
          _item('b', word: 'b', language: 'en', nextReviewAt: _kNow),
          _item('c', word: 'c', language: 'ja', nextReviewAt: _kNow),
          _item('d', word: 'd', language: 'de', nextReviewAt: _kNow),
        ]),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final v2 = container.read(vocabularyListLanguagesProvider);
      expect(identical(v2, v1), isFalse);
      expect(v2, ['de', 'en', 'ja']);
      expect(
        identical(container.read(vocabularyListLanguagesProvider), v2),
        isTrue,
      );
    });

    test('equal language sets across emissions stay equal', () async {
      final controller = StreamController<List<VocabularyItem>>();
      addTearDown(controller.close);
      final container = ProviderContainer(
        overrides: [
          vocabularyItemsProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(vocabularyListLanguagesProvider, (_, _) {});
      addTearDown(sub.close);

      controller.add(
        List<VocabularyItem>.of([
          _item('a', word: 'a', language: 'en', nextReviewAt: _kNow),
        ]),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final v1 = container.read(vocabularyListLanguagesProvider);

      controller.add(
        List<VocabularyItem>.of([
          _item('b', word: 'b', language: 'en', nextReviewAt: _kNow),
          _item('c', word: 'c', language: 'en', nextReviewAt: _kNow),
        ]),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final v2 = container.read(vocabularyListLanguagesProvider);

      expect(identical(v2, v1), isFalse);
      expect(v2, v1);
    });
  });

  test('bench (local only): legacy panel derivations per rebuild', () {
    final items = _benchItems();
    final medians = _benchRounds(() {
      _benchSink = _legacyPanelSink(items);
    }, 'review panel legacy');
    expect(medians.last, lessThan(10));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): provider-read panel counts per rebuild', () async {
    final items = _benchItems(DateTime.now());
    final controller = StreamController<List<VocabularyItem>>();
    final container = ProviderContainer(
      overrides: [
        vocabularyItemsProvider.overrideWith((ref) => controller.stream),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(controller.close);
    final sub = container.listen(vocabularyDuePreviewProvider, (_, _) {});
    addTearDown(sub.close);
    final sub2 = container.listen(vocabularyListLanguagesProvider, (_, _) {});
    addTearDown(sub2.close);
    controller.add(items);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final medians = _benchRounds(() {
      final languages = container.read(vocabularyListLanguagesProvider);
      final dueCount = container.read(vocabularyDuePreviewProvider).count;
      _benchSink = languages.length + dueCount + items.length + items.length;
    }, 'review panel provider reads');
    expect(medians.last, lessThan(10));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}
