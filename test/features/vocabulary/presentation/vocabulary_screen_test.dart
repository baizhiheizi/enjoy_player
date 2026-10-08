import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_screen.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget harness() {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const VocabularyScreen(),
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> disposeHarness(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> addHello(DateTime nextReviewAt) async {
    final repo = VocabularyRepository(db);
    final created = await repo.addWithContext(
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      text: 'Hello world',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 0, duration: 1000),
    );
    await (db.update(db.vocabularyItems)
          ..where((t) => t.id.equals(created.item.id)))
        .write(VocabularyItemsCompanion(nextReviewAt: Value(nextReviewAt)));
  }

  testWidgets('empty book shows the no-words state under the header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpScreen(tester);

    expect(find.text('YOUR WORD BOOK'), findsOneWidget);
    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.text('No words yet'), findsOneWidget);
    expect(find.text('All Words'), findsNothing);

    await disposeHarness(tester);
  });

  testWidgets('a due word shows the due card, status card and Review action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await addHello(DateTime.utc(2000));
    await pumpScreen(tester);

    expect(
      find.textContaining('due today', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Review 1 due'), findsOneWidget);
    expect(find.text('by status'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
    expect(find.text('Hello world'), findsOneWidget);

    await tester.tap(find.text('Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('1 word is waiting'), findsOneWidget);
    expect(find.text('Custom review'), findsOneWidget);

    await disposeHarness(tester);
  });

  testWidgets('nothing due drops the Review action and says so', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await addHello(DateTime.utc(2099));
    await pumpScreen(tester);

    expect(find.textContaining('Review 0'), findsNothing);

    await tester.tap(find.text('Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Nothing due right now'), findsOneWidget);
    expect(find.text('Custom review'), findsOneWidget);

    await disposeHarness(tester);
  });
}
