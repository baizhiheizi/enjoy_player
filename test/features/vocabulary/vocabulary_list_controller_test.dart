// ignore_for_file: scoped_providers_should_specify_dependencies
import 'package:enjoy_player/features/vocabulary/application/vocabulary_list_controller.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

VocabularyItem _item({
  required String id,
  required String word,
  String language = 'en',
  VocabularyStatus status = VocabularyStatus.learning,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return VocabularyItem(
    id: id,
    word: word,
    language: language,
    targetLanguage: 'zh-CN',
    status: status,
    easeFactor: 2.5,
    interval: 1,
    nextReviewAt: now,
    reviewsCount: 0,
    contextsCount: 0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('VocabularyListFilters', () {
    test('copyWith updates status', () {
      const f = VocabularyListFilters();
      final updated = f.copyWith(status: VocabularyStatus.mastered);
      expect(updated.status, VocabularyStatus.mastered);
      expect(updated.language, isNull);
      expect(updated.query, '');
    });

    test('copyWith updates language', () {
      const f = VocabularyListFilters();
      final updated = f.copyWith(language: 'ja');
      expect(updated.language, 'ja');
    });

    test('copyWith updates query', () {
      const f = VocabularyListFilters();
      final updated = f.copyWith(query: 'hello');
      expect(updated.query, 'hello');
    });

    test('copyWith clearStatus removes status', () {
      const f = VocabularyListFilters(status: VocabularyStatus.new_);
      final updated = f.copyWith(clearStatus: true);
      expect(updated.status, isNull);
    });

    test('copyWith clearLanguage removes language', () {
      const f = VocabularyListFilters(language: 'en');
      final updated = f.copyWith(clearLanguage: true);
      expect(updated.language, isNull);
    });

    test('equality works', () {
      const a = VocabularyListFilters(
        status: VocabularyStatus.learning,
        language: 'en',
        query: 'test',
      );
      const b = VocabularyListFilters(
        status: VocabularyStatus.learning,
        language: 'en',
        query: 'test',
      );
      const c = VocabularyListFilters(
        status: VocabularyStatus.mastered,
        language: 'en',
        query: 'test',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('VocabularyListFiltersNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty filters', () {
      final state = container.read(vocabularyListFiltersProvider);
      expect(state.status, isNull);
      expect(state.language, isNull);
      expect(state.query, '');
    });

    test('setStatus sets status', () {
      container
          .read(vocabularyListFiltersProvider.notifier)
          .setStatus(VocabularyStatus.reviewing);
      final state = container.read(vocabularyListFiltersProvider);
      expect(state.status, VocabularyStatus.reviewing);
    });

    test('setStatus null clears status', () {
      final notifier = container.read(vocabularyListFiltersProvider.notifier);
      notifier.setStatus(VocabularyStatus.reviewing);
      notifier.setStatus(null);
      final state = container.read(vocabularyListFiltersProvider);
      expect(state.status, isNull);
    });

    test('setLanguage sets language', () {
      container.read(vocabularyListFiltersProvider.notifier).setLanguage('ja');
      final state = container.read(vocabularyListFiltersProvider);
      expect(state.language, 'ja');
    });

    test('setLanguage null clears language', () {
      final notifier = container.read(vocabularyListFiltersProvider.notifier);
      notifier.setLanguage('ja');
      notifier.setLanguage(null);
      final state = container.read(vocabularyListFiltersProvider);
      expect(state.language, isNull);
    });

    test('setQuery debounces and trims', () async {
      final notifier = container.read(vocabularyListFiltersProvider.notifier);
      notifier.setQuery('  hello  ');

      var state = container.read(vocabularyListFiltersProvider);
      expect(state.query, '');

      await Future<void>.delayed(
        kVocabularySearchDebounce + const Duration(milliseconds: 50),
      );

      state = container.read(vocabularyListFiltersProvider);
      expect(state.query, 'hello');
    });

    test('clearQuery cancels debounce and clears immediately', () async {
      final notifier = container.read(vocabularyListFiltersProvider.notifier);
      notifier.setQuery('pending');
      notifier.clearQuery();

      final state = container.read(vocabularyListFiltersProvider);
      expect(state.query, '');

      await Future<void>.delayed(
        kVocabularySearchDebounce + const Duration(milliseconds: 50),
      );

      final afterDebounce = container.read(vocabularyListFiltersProvider);
      expect(afterDebounce.query, '');
    });
  });

  group('filterVocabularyItems', () {
    final items = [
      _item(
        id: '1',
        word: 'apple',
        language: 'en',
        status: VocabularyStatus.learning,
      ),
      _item(
        id: '2',
        word: 'banana',
        language: 'en',
        status: VocabularyStatus.mastered,
      ),
      _item(
        id: '3',
        word: 'cherry',
        language: 'ja',
        status: VocabularyStatus.learning,
      ),
      _item(
        id: '4',
        word: 'date',
        language: 'ja',
        status: VocabularyStatus.new_,
      ),
    ];

    test('no filters returns all items', () {
      const filters = VocabularyListFilters();
      expect(filterVocabularyItems(items, filters), hasLength(4));
    });

    test('filters by status', () {
      const filters = VocabularyListFilters(status: VocabularyStatus.learning);
      final result = filterVocabularyItems(items, filters);
      expect(result, hasLength(2));
      expect(result.map((i) => i.id), containsAll(['1', '3']));
    });

    test('filters by language', () {
      const filters = VocabularyListFilters(language: 'ja');
      final result = filterVocabularyItems(items, filters);
      expect(result, hasLength(2));
      expect(result.map((i) => i.id), containsAll(['3', '4']));
    });

    test('filters by query (case-insensitive word match)', () {
      const filters = VocabularyListFilters(query: 'BANANA');
      final result = filterVocabularyItems(items, filters);
      expect(result, hasLength(1));
      expect(result.first.id, '2');
    });

    test('filters by query matching language', () {
      const filters = VocabularyListFilters(query: 'ja');
      final result = filterVocabularyItems(items, filters);
      expect(result, hasLength(2));
    });

    test('combines status and language filters', () {
      const filters = VocabularyListFilters(
        status: VocabularyStatus.learning,
        language: 'ja',
      );
      final result = filterVocabularyItems(items, filters);
      expect(result, hasLength(1));
      expect(result.first.id, '3');
    });

    test('combines all filters', () {
      const filters = VocabularyListFilters(
        status: VocabularyStatus.learning,
        language: 'en',
        query: 'app',
      );
      final result = filterVocabularyItems(items, filters);
      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });

    test('returns empty when no match', () {
      const filters = VocabularyListFilters(status: VocabularyStatus.reviewing);
      final result = filterVocabularyItems(items, filters);
      expect(result, isEmpty);
    });
  });
}
