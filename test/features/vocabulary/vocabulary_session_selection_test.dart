import 'dart:math';

import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_srs.dart';
import 'package:flutter_test/flutter_test.dart';

VocabularyItem _item({
  required String id,
  VocabularyStatus status = VocabularyStatus.new_,
  DateTime? nextReviewAt,
  DateTime? lastReviewedAt,
  String language = 'en',
}) {
  final created = DateTime.utc(2024, 1, 1);
  return VocabularyItem(
    id: id,
    word: id,
    language: language,
    targetLanguage: 'zh',
    status: status,
    easeFactor: kDefaultEaseFactor,
    interval: 0,
    nextReviewAt: nextReviewAt ?? DateTime.utc(2024, 6, 15, 12),
    reviewsCount: 0,
    lastReviewedAt: lastReviewedAt,
    contextsCount: 0,
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  final now = DateTime.utc(2024, 6, 15, 12);

  List<VocabularyItem> sampleItems() => [
    _item(id: 'a', status: VocabularyStatus.new_),
    _item(
      id: 'b',
      status: VocabularyStatus.learning,
      language: 'ja',
      nextReviewAt: now.add(const Duration(days: 2)),
    ),
    _item(
      id: 'c',
      status: VocabularyStatus.reviewing,
      nextReviewAt: now.subtract(const Duration(hours: 2)),
      lastReviewedAt: now.subtract(const Duration(days: 3)),
    ),
    _item(
      id: 'd',
      status: VocabularyStatus.mastered,
      language: 'ja',
      nextReviewAt: now.add(const Duration(days: 10)),
    ),
  ];

  group('buildVocabularySessionQueue', () {
    test('due filters with foundation predicate', () {
      final queue = buildVocabularySessionQueue(
        items: sampleItems(),
        options: const ReviewSelectionOptions(mode: VocabularyReviewMode.due),
        now: now,
      );
      expect(queue.map((e) => e.id), ['a', 'c']);
    });

    test('all returns every item in order', () {
      final items = sampleItems();
      final queue = buildVocabularySessionQueue(
        items: items,
        options: const ReviewSelectionOptions(mode: VocabularyReviewMode.all),
        now: now,
      );
      expect(queue.map((e) => e.id), ['a', 'b', 'c', 'd']);
      expect(identical(queue, items), isFalse);
    });

    test('byStatus filters status', () {
      final queue = buildVocabularySessionQueue(
        items: sampleItems(),
        options: const ReviewSelectionOptions(
          mode: VocabularyReviewMode.byStatus,
          status: VocabularyStatus.learning,
        ),
        now: now,
      );
      expect(queue.map((e) => e.id), ['b']);
    });

    test('byStatus with null status returns empty', () {
      final queue = buildVocabularySessionQueue(
        items: sampleItems(),
        options: const ReviewSelectionOptions(
          mode: VocabularyReviewMode.byStatus,
        ),
        now: now,
      );
      expect(queue, isEmpty);
    });

    test('byLanguage filters language', () {
      final queue = buildVocabularySessionQueue(
        items: sampleItems(),
        options: const ReviewSelectionOptions(
          mode: VocabularyReviewMode.byLanguage,
          language: 'ja',
        ),
        now: now,
      );
      expect(queue.map((e) => e.id), ['b', 'd']);
    });

    test('byLanguage with null language returns empty', () {
      final queue = buildVocabularySessionQueue(
        items: sampleItems(),
        options: const ReviewSelectionOptions(
          mode: VocabularyReviewMode.byLanguage,
        ),
        now: now,
      );
      expect(queue, isEmpty);
    });

    test('empty source yields empty queue for each mode', () {
      for (final mode in VocabularyReviewMode.values) {
        final queue = buildVocabularySessionQueue(
          items: const [],
          options: ReviewSelectionOptions(
            mode: mode,
            status: VocabularyStatus.new_,
            language: 'en',
          ),
          now: now,
        );
        expect(queue, isEmpty, reason: mode.name);
      }
    });

    test('random takes min(randomCount, length) with seeded shuffle', () {
      final items = [for (var i = 0; i < 5; i++) _item(id: '$i')];
      final a = buildVocabularySessionQueue(
        items: items,
        options: const ReviewSelectionOptions(
          mode: VocabularyReviewMode.random,
          randomCount: 3,
        ),
        now: now,
        random: Random(42),
      );
      final b = buildVocabularySessionQueue(
        items: items,
        options: const ReviewSelectionOptions(
          mode: VocabularyReviewMode.random,
          randomCount: 3,
        ),
        now: now,
        random: Random(42),
      );
      expect(a.length, 3);
      expect(a.map((e) => e.id).toList(), b.map((e) => e.id).toList());

      final all = buildVocabularySessionQueue(
        items: items,
        options: const ReviewSelectionOptions(
          mode: VocabularyReviewMode.random,
          randomCount: 20,
        ),
        now: now,
        random: Random(7),
      );
      expect(all.length, 5);
      expect(all.map((e) => e.id).toSet(), {'0', '1', '2', '3', '4'});
    });

    test('random does not mutate source list order', () {
      final items = [for (var i = 0; i < 8; i++) _item(id: '$i')];
      final before = items.map((e) => e.id).toList();
      buildVocabularySessionQueue(
        items: items,
        options: const ReviewSelectionOptions(
          mode: VocabularyReviewMode.random,
          randomCount: 4,
        ),
        now: now,
        random: Random(99),
      );
      expect(items.map((e) => e.id).toList(), before);
    });
  });
}
