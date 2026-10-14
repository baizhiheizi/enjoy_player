import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_echo_loop_edge_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class _Spy extends PlayerInteractions {
  _Spy(super.ref);

  final calls = <String>[];

  @override
  Future<void> expandEchoBackward() async => calls.add('expandBackward');

  @override
  Future<void> expandEchoForward() async => calls.add('expandForward');

  @override
  Future<void> shrinkEchoBackward() async => calls.add('shrinkBackward');

  @override
  Future<void> shrinkEchoForward() async => calls.add('shrinkForward');
}

const _line = TranscriptLine(
  text: 'Nobody was on their phone',
  startMs: 16000,
  durationMs: 4000,
);

Future<_Spy> _pump(
  WidgetTester tester, {
  required EchoLoopEdge edge,
  bool canDrop = true,
}) async {
  late _Spy spy;
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerInteractionsProvider.overrideWith((ref) => spy = _Spy(ref)),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EchoLoopEdgeRow(line: _line, edge: edge, canDrop: canDrop),
        ),
      ),
    ),
  );
  return spy;
}

void main() {
  testWidgets('the row above adds the earlier line; − drops the first', (
    tester,
  ) async {
    final spy = await _pump(tester, edge: EchoLoopEdge.above);

    expect(find.text('Nobody was on their phone'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('echo-edge-add-above')));
    await tester.tap(find.byKey(const ValueKey('echo-edge-drop-above')));
    expect(spy.calls, ['expandBackward', 'shrinkBackward']);
  });

  testWidgets('the row below adds the later line; − drops the last', (
    tester,
  ) async {
    final spy = await _pump(tester, edge: EchoLoopEdge.below);

    await tester.tap(find.byKey(const ValueKey('echo-edge-add-below')));
    await tester.tap(find.byKey(const ValueKey('echo-edge-drop-below')));
    expect(spy.calls, ['expandForward', 'shrinkForward']);
  });

  testWidgets('− does nothing on a one-line loop', (tester) async {
    final spy = await _pump(tester, edge: EchoLoopEdge.above, canDrop: false);

    await tester.tap(
      find.byKey(const ValueKey('echo-edge-drop-above')),
      warnIfMissed: false,
    );
    expect(spy.calls, isEmpty);
  });
}
