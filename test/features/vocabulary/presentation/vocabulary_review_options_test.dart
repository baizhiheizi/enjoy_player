import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_review_options.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

VocabularyItem _item({
  required String id,
  required String word,
  required String language,
  VocabularyStatus status = VocabularyStatus.new_,
  DateTime? nextReviewAt,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return VocabularyItem(
    id: id,
    word: word,
    language: language,
    targetLanguage: 'zh',
    status: status,
    easeFactor: 2.5,
    interval: 1,
    nextReviewAt: nextReviewAt ?? now,
    reviewsCount: 1,
    contextsCount: 1,
    createdAt: now,
    updatedAt: now,
  );
}

ReviewSelectionOptions? _started;

Widget _harness({List<VocabularyItem> items = const []}) {
  _started = null;
  return ProviderScope(
    overrides: [
      vocabularyItemsProvider.overrideWith((ref) => Stream.value(items)),
    ],
    child: MaterialApp(
      theme: buildAppTheme(Brightness.light),
      locale: const Locale('en', 'US'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: VocabularyCustomReview(onStart: (o) => _started = o),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VocabularyCustomReview', () {
    testWidgets('renders all five review modes', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(find.text('Custom review'), findsOneWidget);
      expect(find.text('Choose what to review'), findsOneWidget);
      for (final title in [
        'Due items',
        'All words',
        'By status',
        'By language',
        'Random',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.byType(DropdownButton<VocabularyStatus>), findsNothing);
    });

    testWidgets('due and all tiles show their queue size', (tester) async {
      await tester.pumpWidget(
        _harness(
          items: [
            _item(
              id: '1',
              word: 'due',
              language: 'en',
              nextReviewAt: DateTime.utc(2000),
            ),
            _item(
              id: '2',
              word: 'later',
              language: 'en',
              nextReviewAt: DateTime.utc(2999),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('by status offers a status choice and starts with it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          items: [
            _item(id: '1', word: 'a', language: 'en'),
            _item(
              id: '2',
              word: 'b',
              language: 'en',
              status: VocabularyStatus.mastered,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('By status'));
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButton<VocabularyStatus>), findsOneWidget);

      await tester.tap(find.byType(DropdownButton<VocabularyStatus>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mastered').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start review'));
      await tester.pumpAndSettle();

      expect(_started?.mode, VocabularyReviewMode.byStatus);
      expect(_started?.status, VocabularyStatus.mastered);
    });

    testWidgets('by language offers a language choice', (tester) async {
      await tester.pumpWidget(
        _harness(
          items: [_item(id: '1', word: 'a', language: 'en')],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('By language'));
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('random steps the number of words', (tester) async {
      await tester.pumpWidget(
        _harness(
          items: [
            _item(id: '1', word: 'a', language: 'en'),
            _item(id: '2', word: 'b', language: 'en'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Random'));
      await tester.pumpAndSettle();
      expect(find.text('Number of words'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Fewer'));
      await tester.pumpAndSettle();
      expect(find.text('19'), findsOneWidget);

      await tester.tap(find.text('Start review'));
      await tester.pumpAndSettle();
      expect(_started?.mode, VocabularyReviewMode.random);
      expect(_started?.randomCount, 19);
    });

    testWidgets('empty queue surfaces an error and does not start', (
      tester,
    ) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start review'));
      await tester.pumpAndSettle();
      expect(find.text('No words match this selection.'), findsOneWidget);
      expect(_started, isNull);

      await tester.tap(find.text('All words'));
      await tester.pumpAndSettle();
      expect(find.text('No words match this selection.'), findsNothing);
    });
  });
}
