import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/presentation/layouts/video_player_layout.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_player_engine.dart';

void main() {
  Future<void> pumpLayout(
    WidgetTester tester, {
    required double width,
    required double height,
  }) async {
    final fake = FakePlayerEngine();
    addTearDown(() async {
      await fake.dispose();
    });
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: height,
              child: VideoPlayerLayout(
                engine: fake,
                transcript: const Text('TR_STUB'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('VideoPlayerLayout shows transcript beside video when wide', (
    tester,
  ) async {
    await pumpLayout(tester, width: 900, height: 600);
    expect(find.text('TR_STUB'), findsOneWidget);
    expect(find.byType(Row), findsWidgets);
  });

  testWidgets('VideoPlayerLayout stacks transcript when narrow', (tester) async {
    await pumpLayout(tester, width: 500, height: 700);
    expect(find.text('TR_STUB'), findsOneWidget);
    expect(find.byType(Column), findsWidgets);
  });
}
