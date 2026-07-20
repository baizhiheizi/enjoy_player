import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/vocabulary_context_pager.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({
    required int index,
    required int total,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
  }) {
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
        body: VocabularyContextPager(
          index: index,
          total: total,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
      ),
    );
  }

  testWidgets('hidden when total is 1', (tester) async {
    await tester.pumpWidget(harness(index: 0, total: 1));
    expect(find.textContaining('of'), findsNothing);
  });

  testWidgets('shows n of m and invokes next', (tester) async {
    var next = 0;
    await tester.pumpWidget(harness(index: 0, total: 3, onNext: () => next++));
    expect(find.text('1 of 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Next context'));
    await tester.pump();
    expect(next, 1);
  });
}
