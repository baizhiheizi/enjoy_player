import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_list.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();
  final attempt = DictationRow(
    id: 'd-1',
    targetType: 'video',
    targetId: 'v-1',
    referenceStartMs: 0,
    referenceDurationMs: 1000,
    referenceText: 'hello world',
    language: 'en',
    userInput: 'hello world',
    accuracy: 100,
    correctWords: 2,
    missedWords: 0,
    extraWords: 0,
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('DictationList expands and triggers onSelectAttempt', (
    tester,
  ) async {
    DictationRow? selected;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DictationList(
            attempts: [attempt],
            selectedAttempt: selected,
            onSelectAttempt: (row) {
              selected = row;
            },
          ),
        ),
      ),
    );

    expect(find.text('Previous dictations (1)'), findsOneWidget);
    expect(find.text('100% accuracy'), findsNothing);

    await tester.tap(find.text('Previous dictations (1)'));
    await tester.pumpAndSettle();

    expect(find.text('100% accuracy'), findsOneWidget);
    expect(find.text('hello world'), findsOneWidget);
    expect(find.text('2 correct'), findsOneWidget);

    await tester.tap(find.text('hello world'));
    expect(selected?.id, 'd-1');
  });
}
