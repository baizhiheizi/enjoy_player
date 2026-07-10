import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/transcript/presentation/subtitle_track_picker_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  SubtitleActionsSection actions({
    required Future<void> Function() onGenerate,
    required bool hasGeneratedTrack,
  }) {
    return SubtitleActionsSection(
      horizontalPadding: 0,
      showExtractEmbedded: false,
      showImportFile: false,
      showGenerate: true,
      hasGeneratedTrack: hasGeneratedTrack,
      onExtractEmbedded: () async {},
      onRefreshCloud: () async {},
      onImportFile: () async {},
      onGenerate: onGenerate,
    );
  }

  testWidgets('shows Generate transcript when no AI track exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(actions(onGenerate: () async {}, hasGeneratedTrack: false)),
    );

    expect(find.text('Generate transcript'), findsOneWidget);
    expect(find.text('Re-generate transcript'), findsNothing);
  });

  testWidgets('shows Re-generate transcript and stays busy during work', (
    tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      _wrap(
        actions(onGenerate: () => completer.future, hasGeneratedTrack: true),
      ),
    );

    await tester.tap(find.text('Re-generate transcript'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('ignores a second tap while generation is in flight', (
    tester,
  ) async {
    final completer = Completer<void>();
    var invocations = 0;
    await tester.pumpWidget(
      _wrap(
        actions(
          onGenerate: () {
            invocations++;
            return completer.future;
          },
          hasGeneratedTrack: false,
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
