import 'package:enjoy_player/features/vocabulary/application/vocabulary_list_controller.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_anki_export_filters.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_filters.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:flutter_test/flutter_test.dart';

VocabularyItem _item({
  required String id,
  required String word,
  String language = 'en',
  VocabularyStatus status = VocabularyStatus.new_,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return VocabularyItem(
    id: id,
    word: word,
    language: language,
    targetLanguage: 'zh',
    status: status,
    easeFactor: 2.5,
    interval: 0,
    nextReviewAt: now,
    reviewsCount: 0,
    contextsCount: 0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final items = <VocabularyItem>[
    _item(id: '1', word: 'hello', language: 'en'),
    _item(id: '2', word: 'world', language: 'en'),
    _item(id: '3', word: 'hola', language: 'es'),
    _item(
      id: '4',
      word: 'learned',
      language: 'en',
      status: VocabularyStatus.learning,
    ),
  ];

  group('filterVocabularyItems', () {
    test('returns all items when no filter is set', () {
      final out = filterVocabularyItems(items, const VocabularyListFilters());
      expect(out, hasLength(4));
    });

    test('applies status, language and search as an intersection', () {
      final out = filterVocabularyItems(
        items,
        const VocabularyListFilters(
          status: VocabularyStatus.learning,
          language: 'en',
          query: 'lear',
        ),
      );
      expect(out.map((i) => i.id), <String>['4']);
    });

    test('matches the query case-insensitively', () {
      final out = filterVocabularyItems(
        items,
        const VocabularyListFilters(query: 'HEL'),
      );
      expect(out.map((i) => i.id), <String>['1']);
    });

    test('matches the query against the language too', () {
      final out = filterVocabularyItems(
        items,
        const VocabularyListFilters(query: 'es'),
      );
      expect(out.map((i) => i.id), <String>['3']);
    });

    test('trims the query so padding never changes the match', () {
      final out = filterVocabularyItems(
        items,
        const VocabularyListFilters(query: '  hello  '),
      );
      expect(out.map((i) => i.id), <String>['1']);
    });

    test('treats a whitespace-only query as no filter', () {
      final out = filterVocabularyItems(
        items,
        const VocabularyListFilters(query: '   '),
      );
      expect(out, hasLength(4));
    });

    test('returns empty when nothing matches', () {
      final out = filterVocabularyItems(
        items,
        const VocabularyListFilters(query: 'xyz123'),
      );
      expect(out, isEmpty);
    });

    test('handles an empty item list', () {
      expect(
        filterVocabularyItems(
          const <VocabularyItem>[],
          const VocabularyListFilters(language: 'en'),
        ),
        isEmpty,
      );
    });
  });

  test('the word list and the Anki export select the same rows', () {
    const listFilters = VocabularyListFilters(query: '  hello  ');
    const ankiFilters = VocabularyAnkiExportFilters(query: '  hello  ');

    expect(
      filterVocabularyItems(items, listFilters).map((i) => i.id),
      filterVocabularyItems(items, ankiFilters).map((i) => i.id),
    );
    expect(filterVocabularyItems(items, listFilters), hasLength(1));
  });
}
