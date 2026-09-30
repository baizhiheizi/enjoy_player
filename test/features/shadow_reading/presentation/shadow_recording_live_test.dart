import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_record_fab.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_recording_live.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppLocalizations> _pumpLive(
  WidgetTester tester, {
  double targetSec = 2.0,
}) async {
  late AppLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return ShadowRecordingLive(
              targetSec: targetSec,
              echoActive: true,
              stopTooltip: 'stop',
              onStop: () {},
              l10n: l10n,
              tt: Theme.of(context).textTheme,
              scheme: Theme.of(context).colorScheme,
              tok: EnjoyThemeTokens.of(context),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return l10n;
}

void main() {
  testWidgets('caption shows the initial elapsed seconds', (tester) async {
    final l10n = await _pumpLive(tester);
    expect(
      find.text(l10n.shadowRecordingElapsedCountdown('0.0', '2.0')),
      findsOneWidget,
    );
  });

  testWidgets('caption text ticks at ~10 Hz, not per frame', (tester) async {
    final l10n = await _pumpLive(tester);
    expect(
      find.text(l10n.shadowRecordingElapsedCountdown('0.0', '2.0')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 40));
    expect(
      find.text(l10n.shadowRecordingElapsedCountdown('0.0', '2.0')),
      findsOneWidget,
      reason: 'elapsed display is seconds-resolution at 10 Hz',
    );

    await tester.pump(const Duration(milliseconds: 60));
    expect(
      find.text(l10n.shadowRecordingElapsedCountdown('0.1', '2.0')),
      findsOneWidget,
    );
  });

  testWidgets('record FAB element is not rebuilt per frame under target', (
    tester,
  ) async {
    await _pumpLive(tester);
    final before = tester.widget<ShadowRecordFab>(find.byType(ShadowRecordFab));

    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    final after = tester.widget<ShadowRecordFab>(find.byType(ShadowRecordFab));
    expect(
      identical(before, after),
      isTrue,
      reason: 'the ring is animation-driven paint-only; no per-frame rebuild',
    );
    expect(after.overTarget, isFalse);
    expect(after.ringElapsedSec, isNotNull);
  });

  testWidgets('crossing the target flips the FAB to over state', (
    tester,
  ) async {
    final l10n = await _pumpLive(tester);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final fab = tester.widget<ShadowRecordFab>(find.byType(ShadowRecordFab));
    expect(fab.overTarget, isTrue);
    expect(find.text(l10n.shadowRecordingOverTarget('1.0')), findsOneWidget);
  });
}
