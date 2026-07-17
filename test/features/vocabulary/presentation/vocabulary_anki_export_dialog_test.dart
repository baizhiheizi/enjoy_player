import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_anki_export_dialog.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

VocabularyItem _item(String id, String word) {
  final now = DateTime.utc(2026, 1, 1);
  return VocabularyItem(
    id: id,
    word: word,
    language: 'en',
    targetLanguage: 'zh',
    status: VocabularyStatus.learning,
    easeFactor: 2.5,
    interval: 1,
    nextReviewAt: now,
    reviewsCount: 1,
    contextsCount: 1,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap(Widget child, {required SubscriptionTier tier}) {
  return ProviderScope(
    overrides: [
      currentTierProvider.overrideWithValue(tier),
      vocabularyItemsProvider.overrideWith(
        (ref) => Stream.value([_item('1', 'hello'), _item('2', 'world')]),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('Free tier shows Pro required and upgrade CTA', (tester) async {
    await tester.pumpWidget(
      _wrap(const VocabularyAnkiExportDialog(), tier: SubscriptionTier.free),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Pro'), findsWidgets);
    expect(find.text('Upgrade to Pro'), findsOneWidget);
    expect(find.text('Export'), findsNothing);
  });

  testWidgets('Pro tier shows filters and export action', (tester) async {
    await tester.pumpWidget(
      _wrap(const VocabularyAnkiExportDialog(), tier: SubscriptionTier.pro),
    );
    await tester.pumpAndSettle();

    expect(find.text('Export'), findsOneWidget);
    expect(find.textContaining('richer'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
