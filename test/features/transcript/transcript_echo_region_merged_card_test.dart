import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/settings/application/karaoke_highlight_settings.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_recording_counts_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/echo_loop_brackets.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_echo_region_merged_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/transcript_settings_overrides.dart';

class _KaraokeHighlightOff extends KaraokeHighlightSettings {
  @override
  Future<bool> build() async => false;
}

void main() {
  testWidgets('echo card lays out inside a scrollable', (tester) async {
    const lines = [
      TranscriptLine(text: 'First echo line', startMs: 0, durationMs: 1000),
      TranscriptLine(text: 'Second echo line', startMs: 1000, durationMs: 1000),
    ];
    const echo = EchoState(
      active: true,
      startLineIndex: 0,
      endLineIndex: 1,
      startTimeSeconds: -1,
      endTimeSeconds: -1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transcriptLineRecordingCountsProvider(
            'media-1',
          ).overrideWithValue(const {}),
          karaokeHighlightSettingsProvider.overrideWith(
            _KaraokeHighlightOff.new,
          ),
          ...transcriptWordPracticeOffOverrides(),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: const [
                EchoRegionMergedCard(
                  mediaId: 'media-1',
                  lines: lines,
                  echo: echo,
                  activeCueIndex: 0,
                  secondaryLines: [],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('First echo line'), findsOneWidget);
    expect(find.text('Second echo line'), findsOneWidget);
  });

  testWidgets('loop lines keep take counts in semantics, no gutter', (
    tester,
  ) async {
    const lines = [
      TranscriptLine(text: 'First echo line', startMs: 0, durationMs: 1000),
      TranscriptLine(text: 'Second echo line', startMs: 1000, durationMs: 1000),
    ];
    const echo = EchoState(
      active: true,
      startLineIndex: 0,
      endLineIndex: 1,
      startTimeSeconds: -1,
      endTimeSeconds: -1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transcriptLineRecordingCountsProvider(
            'media-1',
          ).overrideWithValue({0: 2}),
          karaokeHighlightSettingsProvider.overrideWith(
            _KaraokeHighlightOff.new,
          ),
          ...transcriptWordPracticeOffOverrides(),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: const [
                EchoRegionMergedCard(
                  mediaId: 'media-1',
                  lines: lines,
                  echo: echo,
                  activeCueIndex: 0,
                  secondaryLines: [],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate((w) {
        final decoration = w is Container ? w.decoration : null;
        return decoration is BoxDecoration &&
            decoration.shape == BoxShape.circle;
      }),
      findsNothing,
      reason:
          'loop lines carry no gutter chrome; the section gutter shows '
          'the loop start once',
    );
  });

  testWidgets('loop block frames with corner brackets and handle pills', (
    tester,
  ) async {
    const lines = [
      TranscriptLine(text: 'First echo line', startMs: 0, durationMs: 1000),
      TranscriptLine(text: 'Second echo line', startMs: 1000, durationMs: 1000),
      TranscriptLine(text: 'Third echo line', startMs: 2000, durationMs: 1000),
    ];
    const echo = EchoState(
      active: true,
      startLineIndex: 1,
      endLineIndex: 1,
      startTimeSeconds: -1,
      endTimeSeconds: -1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transcriptLineRecordingCountsProvider(
            'media-1',
          ).overrideWithValue(const {}),
          karaokeHighlightSettingsProvider.overrideWith(
            _KaraokeHighlightOff.new,
          ),
          ...transcriptWordPracticeOffOverrides(),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: const [
                EchoRegionMergedCard(
                  mediaId: 'media-1',
                  lines: lines,
                  echo: echo,
                  activeCueIndex: 1,
                  secondaryLines: [],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is EchoLoopBrackets,
      ),
      findsOneWidget,
      reason: 'the loop is framed by the you corner brackets',
    );
    expect(find.text('Earlier line'), findsOneWidget);
    expect(find.text('Later line'), findsOneWidget);
    expect(find.text('LOOP · LINE 2 · 0.0 S'), findsOneWidget);
  });

  testWidgets('loop label reads the line span for multi-line loops', (
    tester,
  ) async {
    const lines = [
      TranscriptLine(text: 'First echo line', startMs: 0, durationMs: 1000),
      TranscriptLine(text: 'Second echo line', startMs: 1000, durationMs: 1000),
    ];
    const echo = EchoState(
      active: true,
      startLineIndex: 0,
      endLineIndex: 1,
      startTimeSeconds: -1,
      endTimeSeconds: -1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transcriptLineRecordingCountsProvider(
            'media-1',
          ).overrideWithValue(const {}),
          karaokeHighlightSettingsProvider.overrideWith(
            _KaraokeHighlightOff.new,
          ),
          ...transcriptWordPracticeOffOverrides(),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: const [
                EchoRegionMergedCard(
                  mediaId: 'media-1',
                  lines: lines,
                  echo: echo,
                  activeCueIndex: 0,
                  secondaryLines: [],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('LOOP · LINES 1–2 · 0.0 S'), findsOneWidget);
  });

  testWidgets(
    'recording mounts pulse dot and loop progress, no ticker assert',
    (tester) async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      const lines = [
        TranscriptLine(text: 'First echo line', startMs: 0, durationMs: 1000),
      ];
      const echo = EchoState(
        active: true,
        startLineIndex: 0,
        endLineIndex: 0,
        startTimeSeconds: 1,
        endTimeSeconds: 3,
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          deviceGlobalAppDatabaseProvider.overrideWithValue(db),
          transcriptLineRecordingCountsProvider(
            'media-1',
          ).overrideWithValue(const {}),
          karaokeHighlightSettingsProvider.overrideWith(
            _KaraokeHighlightOff.new,
          ),
          ...transcriptWordPracticeOffOverrides(),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(shadowReadingHotkeyBusProvider.notifier)
          .setRecordingActive(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ListView(
                children: const [
                  EchoRegionMergedCard(
                    mediaId: 'media-1',
                    lines: lines,
                    echo: echo,
                    activeCueIndex: 0,
                    secondaryLines: [],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(tester.takeException(), isNull);
      expect(find.byType(EchoRecordingPulseDot), findsOneWidget);
      expect(find.text('RECORDING TAKE 1'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
