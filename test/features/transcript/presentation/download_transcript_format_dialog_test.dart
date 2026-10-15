import 'dart:async';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/subtitle/subtitle_serializer.dart';
import 'package:enjoy_player/features/transcript/presentation/download_transcript_format_dialog.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpHost(
  WidgetTester tester,
  ValueChanged<BuildContext> onOpened,
) async {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => onOpened(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('offers SRT and VTT and resolves the tapped format', (
    tester,
  ) async {
    SubtitleExportFormat? chosen;
    await _pumpHost(tester, (context) {
      unawaited(
        showTranscriptExportFormatDialog(context).then((f) => chosen = f),
      );
    });
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Download transcript'), findsOneWidget);
    expect(find.text('SRT'), findsOneWidget);
    expect(find.text('VTT'), findsOneWidget);
    expect(find.text('SubRip subtitle file (.srt)'), findsOneWidget);
    expect(find.text('WebVTT subtitle file (.vtt)'), findsOneWidget);

    await tester.tap(find.text('VTT'));
    await tester.pumpAndSettle();

    expect(chosen, SubtitleExportFormat.vtt);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('resolves SRT from the first row', (tester) async {
    SubtitleExportFormat? chosen;
    await _pumpHost(tester, (context) {
      unawaited(
        showTranscriptExportFormatDialog(context).then((f) => chosen = f),
      );
    });
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SRT'));
    await tester.pumpAndSettle();

    expect(chosen, SubtitleExportFormat.srt);
  });

  testWidgets('resolves null when dismissed', (tester) async {
    SubtitleExportFormat? chosen;
    await _pumpHost(tester, (context) {
      unawaited(
        showTranscriptExportFormatDialog(context).then((f) => chosen = f),
      );
    });
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(30, 300));
    await tester.pumpAndSettle();

    expect(chosen, isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
