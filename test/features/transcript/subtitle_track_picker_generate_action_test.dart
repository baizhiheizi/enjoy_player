import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/transcript/presentation/subtitle_track_picker_actions.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF003366));
  return MaterialApp(
    theme: ThemeData(
      colorScheme: scheme,
      extensions: [EnjoyThemeTokens.build(scheme)],
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

TranscriptAction _transcribe(Future<void> Function() run) => TranscriptAction(
  kind: TranscriptActionKind.aiTranscript,
  icon: EnjoyIcons.waveform,
  label: 'Transcribe again…',
  run: (_) => run(),
);

void main() {
  testWidgets('lists each action under the Transcript heading', (tester) async {
    await tester.pumpWidget(
      _wrap(TranscriptActionsList(actions: [_transcribe(() async {})])),
    );

    expect(find.text('TRANSCRIPT'), findsOneWidget);
    expect(find.text('Transcribe again…'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('transcript-action-aiTranscript')),
      findsOneWidget,
    );
  });

  testWidgets('stays busy while the action runs', (tester) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      _wrap(
        TranscriptActionsList(actions: [_transcribe(() => completer.future)]),
      ),
    );

    await tester.tap(find.text('Transcribe again…'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('ignores a second tap while the action is in flight', (
    tester,
  ) async {
    final completer = Completer<void>();
    var invocations = 0;
    await tester.pumpWidget(
      _wrap(
        TranscriptActionsList(
          actions: [
            _transcribe(() {
              invocations++;
              return completer.future;
            }),
          ],
        ),
      ),
    );

    final tile = find.byType(ListTile).first;
    await tester.tap(tile);
    await tester.pump();
    await tester.tap(tile);
    await tester.pump();
    expect(invocations, 1);

    completer.complete();
    await tester.pumpAndSettle();
  });
}
