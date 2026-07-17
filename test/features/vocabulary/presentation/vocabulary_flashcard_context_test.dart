import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_flashcard.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuthSignedInCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(id: 'test-user', email: 't@example.com', name: 'Test'),
  );
}

VocabularyItem _item({String? explanation}) => VocabularyItem(
  id: 'i1',
  word: 'hello',
  language: 'en',
  targetLanguage: 'zh',
  status: VocabularyStatus.new_,
  easeFactor: 2.5,
  interval: 0,
  nextReviewAt: DateTime.utc(2030),
  reviewsCount: 0,
  contextsCount: 1,
  explanation: explanation,
  createdAt: DateTime.utc(2020),
  updatedAt: DateTime.utc(2020),
);

VocabularyContext _context({String? explanation}) => VocabularyContext(
  id: 'c1',
  vocabularyItemId: 'i1',
  text: 'Hello world.',
  sourceType: VocabularySourceType.video,
  sourceId: 'v1',
  locator: const MediaLocator(start: 1000, duration: 2000),
  explanation: explanation,
  createdAt: DateTime.utc(2020),
  updatedAt: DateTime.utc(2020),
);

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [authCtrlProvider.overrideWith(_AuthSignedInCtrl.new)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('Dictionary tab shows cached explanation', (tester) async {
    final explanation = encodeDictionaryExplanation(
      const DictionaryResult(
        word: 'hello',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        senses: [DictionarySense(definition: 'a greeting')],
      ),
    );
    await tester.pumpWidget(
      _wrap(
        VocabularyFlashcard(
          item: _item(explanation: explanation),
          primaryContext: _context(),
          flipped: true,
          ratingInFlight: false,
          dictionaryFetchInFlight: false,
          contextualFetchInFlight: false,
          clipPlayInFlight: false,
          onFlip: () {},
          onRate: (_) {},
          onFetchDictionary: () {},
          onFetchContextual: () {},
          onPlayClip: () {},
          onOpenInPlayer: () {},
          onShadowReading: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dictionary'));
    await tester.pumpAndSettle();
    expect(find.textContaining('a greeting'), findsOneWidget);
  });

  testWidgets('Context tab shows play and open actions for media', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        VocabularyFlashcard(
          item: _item(),
          primaryContext: _context(),
          flipped: true,
          ratingInFlight: false,
          dictionaryFetchInFlight: false,
          contextualFetchInFlight: false,
          clipPlayInFlight: false,
          onFlip: () {},
          onRate: (_) {},
          onFetchDictionary: () {},
          onFetchContextual: () {},
          onPlayClip: () {},
          onOpenInPlayer: () {},
          onShadowReading: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hello world.'), findsOneWidget);
    expect(find.text('Play segment'), findsOneWidget);
    expect(find.text('Open in player'), findsOneWidget);
    expect(find.text('Shadow reading'), findsOneWidget);
  });
}
