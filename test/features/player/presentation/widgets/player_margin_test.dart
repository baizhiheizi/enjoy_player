import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_margin_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_margin.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _contentKey = ValueKey('content');

PlayerMarginEntry _entry({bool echoOnly = false}) => PlayerMarginEntry(
  id: 'test',
  label: 'Test panel',
  echoOnly: echoOnly,
  builder: (context, close) => Column(
    children: [
      const Text('panel body'),
      TextButton(onPressed: close, child: const Text('close me')),
    ],
  ),
);

Future<ProviderContainer> _pump(WidgetTester tester, double width) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
  await tester.binding.setSurfaceSize(Size(width, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlayerMarginLayout(
            child: Builder(
              builder: (context) => Center(
                key: _contentKey,
                child: TextButton(
                  onPressed: () => openPlayerMargin(context, _entry()),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('wide: the margin docks and pushes the content aside', (
    tester,
  ) async {
    final container = await _pump(tester, 1280);
    expect(tester.getSize(find.byKey(_contentKey)).width, 1280);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('player-margin-docked')), findsOneWidget);
    expect(find.text('panel body'), findsOneWidget);
    expect(tester.getSize(find.byKey(_contentKey)).width, 1280 - 360);
    expect(container.read(playerMarginProvider), isNotNull);

    await tester.tap(find.text('close me'));
    await tester.pumpAndSettle();
    expect(find.text('panel body'), findsNothing);
    expect(tester.getSize(find.byKey(_contentKey)).width, 1280);
  });

  testWidgets('under 1100: the margin is a drawer route over the content', (
    tester,
  ) async {
    final container = await _pump(tester, 1000);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('player-margin-docked')), findsNothing);
    expect(find.text('panel body'), findsOneWidget);
    expect(tester.getSize(find.byKey(_contentKey)).width, 1000);
    expect(container.read(playerMarginProvider), isNull);

    await tester.tap(find.text('close me'));
    await tester.pumpAndSettle();
    expect(find.text('panel body'), findsNothing);
  });

  testWidgets('an echo-only panel closes when Echo turns off', (tester) async {
    final container = await _pump(tester, 1280);
    container
        .read(echoModeProvider.notifier)
        .activate(
          startLineIndex: 0,
          endLineIndex: 0,
          startTimeSeconds: 0,
          endTimeSeconds: 1,
        );
    container.read(playerMarginProvider.notifier).show(_entry(echoOnly: true));
    await tester.pumpAndSettle();
    expect(find.text('panel body'), findsOneWidget);

    container.read(echoModeProvider.notifier).deactivate();
    await tester.pumpAndSettle();
    expect(container.read(playerMarginProvider), isNull);
    expect(find.text('panel body'), findsNothing);
  });

  testWidgets('a lookup-style panel stays open when Echo turns off', (
    tester,
  ) async {
    final container = await _pump(tester, 1280);
    container
        .read(echoModeProvider.notifier)
        .activate(
          startLineIndex: 0,
          endLineIndex: 0,
          startTimeSeconds: 0,
          endTimeSeconds: 1,
        );
    container.read(playerMarginProvider.notifier).show(_entry());
    await tester.pumpAndSettle();

    container.read(echoModeProvider.notifier).deactivate();
    await tester.pumpAndSettle();
    expect(find.text('panel body'), findsOneWidget);
  });
}
