import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_anki_export.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_anki_export_filters.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

void main() {
  group('vocabularyAnkiExportAllowedFrom', () {
    test('uses subscriptionIsPro when provided', () {
      expect(
        vocabularyAnkiExportAllowedFrom(
          tier: SubscriptionTier.free,
          subscriptionIsPro: true,
        ),
        isTrue,
      );
      expect(
        vocabularyAnkiExportAllowedFrom(
          tier: SubscriptionTier.pro,
          subscriptionIsPro: false,
        ),
        isFalse,
      );
    });

    test('falls back to tier when subscriptionIsPro is null', () {
      expect(
        vocabularyAnkiExportAllowedFrom(tier: SubscriptionTier.pro),
        isTrue,
      );
      expect(
        vocabularyAnkiExportAllowedFrom(tier: SubscriptionTier.free),
        isFalse,
      );
    });
  });

  group('runVocabularyAnkiExport', () {
    test('throws pro_required when not Pro', () async {
      expect(
        () => runVocabularyAnkiExport(
          isPro: false,
          listAll: () async => const [],
          getContextsForItem: (_) async => const [],
          filters: const VocabularyAnkiExportFilters(),
        ),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'pro_required'),
        ),
      );
    });

    test('throws no_items_to_export when filtered empty', () async {
      final now = DateTime.utc(2026, 1, 1);
      final items = [
        VocabularyItem(
          id: '1',
          word: 'hello',
          language: 'en',
          targetLanguage: 'zh',
          status: VocabularyStatus.new_,
          easeFactor: 2.5,
          interval: 0,
          nextReviewAt: now,
          reviewsCount: 0,
          contextsCount: 0,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      expect(
        () => runVocabularyAnkiExport(
          isPro: true,
          listAll: () async => items,
          getContextsForItem: (_) async => const [],
          filters: const VocabularyAnkiExportFilters(
            status: VocabularyStatus.mastered,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'no_items_to_export',
          ),
        ),
      );
    });
  });
}
