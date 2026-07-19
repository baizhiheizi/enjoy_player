import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_stats_strip.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({required VocabularyStats stats}) {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      home: Scaffold(
        body: SingleChildScrollView(child: VocabularyStatsStrip(stats: stats)),
      ),
    );
  }

  testWidgets('collapsed shows Total and Due; expand reveals statuses', (
    tester,
  ) async {
    const stats = VocabularyStats(
      total: 3,
      due: 1,
      newCount: 2,
      learningCount: 1,
      reviewingCount: 0,
      masteredCount: 0,
    );
    await tester.pumpWidget(harness(stats: stats));

    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Due'), findsOneWidget);
    expect(find.text('New'), findsNothing);

    await tester.tap(find.byTooltip('Show status breakdown'));
    await tester.pumpAndSettle();

    expect(find.text('New'), findsOneWidget);
    expect(find.text('Learning'), findsOneWidget);
    expect(find.text('Reviewing'), findsOneWidget);
    expect(find.text('Mastered'), findsOneWidget);
  });
}
