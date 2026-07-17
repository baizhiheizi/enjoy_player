import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: VocabularyScreen(),
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    // Stream + first frame; avoid pumpAndSettle (Drift close timers / tab anim).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> disposeHarness(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('empty book shows no-words state and tabs', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('All Words'), findsOneWidget);
    expect(find.text('No words yet'), findsOneWidget);

    await disposeHarness(tester);
  });

  testWidgets('stats strip shows total after seed', (tester) async {
    final repo = VocabularyRepository(db);
    await repo.addWithContext(
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      text: 'Hello world',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 0, duration: 1000),
    );

    await pumpScreen(tester);

    expect(find.text('1'), findsWidgets);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('No words yet'), findsNothing);

    await disposeHarness(tester);
  });

  testWidgets('no-due state offers custom review', (tester) async {
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

    await (db.update(
      db.vocabularyItems,
    )..where((t) => t.id.equals(created.item.id))).write(
      VocabularyItemsCompanion(nextReviewAt: Value(DateTime.utc(2099))),
    );

    await pumpScreen(tester);

    expect(find.text('Nothing due right now'), findsOneWidget);
    expect(find.text('Custom review'), findsOneWidget);
    expect(find.text('Start review'), findsNothing);

    await disposeHarness(tester);
  });
}
