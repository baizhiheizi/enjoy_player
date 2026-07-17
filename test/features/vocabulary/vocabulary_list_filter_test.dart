import 'package:enjoy_player/features/vocabulary/application/vocabulary_list_controller.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:flutter_test/flutter_test.dart';

VocabularyItem item({
  required String word,
  required String language,
  VocabularyStatus status = VocabularyStatus.new_,
}) {
  final now = DateTime.utc(2024, 1, 1);
  return VocabularyItem(
    id: '$word-$language',
    word: word,
    language: language,
    targetLanguage: 'zh',
    status: status,
    easeFactor: 2.5,
    interval: 0,
    nextReviewAt: now,
    reviewsCount: 0,
    contextsCount: 1,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('filterVocabularyItems by status language and search', () {
    final items = [
      item(word: 'apple', language: 'en', status: VocabularyStatus.learning),
      item(word: 'banana', language: 'en'),
      item(word: 'pomme', language: 'fr'),
    ];

    expect(
      filterVocabularyItems(
        items,
        const VocabularyListFilters(status: VocabularyStatus.learning),
      ).map((e) => e.word),
      ['apple'],
    );

    expect(
      filterVocabularyItems(
        items,
        const VocabularyListFilters(language: 'fr'),
      ).map((e) => e.word),
      ['pomme'],
    );

    expect(
      filterVocabularyItems(
        items,
        const VocabularyListFilters(query: 'ban'),
      ).map((e) => e.word),
      ['banana'],
    );

    expect(
      filterVocabularyItems(
        items,
        const VocabularyListFilters(query: 'fr'),
      ).map((e) => e.word),
      ['pomme'],
    );
  });
}
