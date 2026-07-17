import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/vocabulary/application/media_vocabulary_context_builder.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/presentation/add_to_vocabulary_control.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  LookupRequest request({
    String text = 'hello',
    int start = 1000,
    int duration = 2000,
  }) {
    return LookupRequest(
      selectedText: text,
      sourceLanguage: 'en-US',
      targetLanguage: 'zh-CN',
      mediaVocabularyContext: MediaVocabularyContext(
        text: 'Hello world.',
        sourceType: VocabularySourceType.video,
        sourceId: 'vid-1',
        locator: MediaLocator(start: start, duration: duration),
      ),
    );
  }

  Widget harness(LookupRequest req) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AddToVocabularyControl(request: req)),
      ),
    );
  }

  testWidgets('shows Add to Vocabulary then Already in after tap', (
    tester,
  ) async {
    await tester.pumpWidget(harness(request()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Add to Vocabulary'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_add_outlined), findsOneWidget);
    await tester.tap(find.byTooltip('Add to Vocabulary'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Already in Vocabulary'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
  });

  testWidgets('Add Context when locator differs', (tester) async {
    await tester.pumpWidget(harness(request(start: 1000)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to Vocabulary'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(harness(request(start: 5000)));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add Context'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_add_rounded), findsOneWidget);
  });

  testWidgets('cancel delete leaves item', (tester) async {
    await tester.pumpWidget(harness(request()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to Vocabulary'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Already in Vocabulary'));
    await tester.pumpAndSettle();
    expect(find.text('Remove from vocabulary?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Already in Vocabulary'), findsOneWidget);
  });

  testWidgets('confirm delete returns to Add', (tester) async {
    await tester.pumpWidget(harness(request()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to Vocabulary'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Already in Vocabulary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add to Vocabulary'), findsOneWidget);
  });
}
