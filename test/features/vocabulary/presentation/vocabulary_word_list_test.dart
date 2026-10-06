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

  testWidgets('a word row carries its context, status, language, delete', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = VocabularyRepository(db);
    await repo.addWithContext(
      word: 'relic',
      language: 'en-US',
      targetLanguage: 'zh',
      text: 'an ancient relic',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 0, duration: 1000),
    );

    await pumpScreen(tester);

    expect(find.text('relic'), findsOneWidget);
    expect(find.text('an ancient relic'), findsOneWidget);
    expect(find.text('New'), findsWidgets);
    expect(find.text('EN'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
    expect(find.text('Status: All'), findsOneWidget);
    expect(find.text('Language: All'), findsOneWidget);

    await tester.tap(find.text('Status: All'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Mastered').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('relic'), findsNothing);
    expect(find.text('No matching words'), findsOneWidget);

    await disposeHarness(tester);
  });
}
