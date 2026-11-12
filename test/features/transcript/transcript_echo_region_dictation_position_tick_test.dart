import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_band.dart';
import 'package:enjoy_player/features/player/application/display_position_provider.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/settings/application/karaoke_highlight_settings.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_recording_counts_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/echo_loop_brackets.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_echo_region_merged_card.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/transcript_settings_overrides.dart';

class _KaraokeHighlightOff extends KaraokeHighlightSettings {
  @override
  Future<bool> build() async => false;
}

class _BlurModeOn extends TranscriptBlurMode {
  @override
  bool build() => true;
}

const _lines = [
  TranscriptLine(text: 'First echo line', startMs: 0, durationMs: 1000),
];

const _echo = EchoState(
  active: true,
  startLineIndex: 0,
  endLineIndex: 0,
  startTimeSeconds: 0,
  endTimeSeconds: 1,
);

CustomPainter _loopBracketsPainter(WidgetTester tester) => tester
    .widget<CustomPaint>(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is EchoLoopBrackets,
      ),
    )
    .painter!;

int _activeDictationWordIndex(WidgetTester tester) {
  final decorations = [
    for (final element
        in find
            .descendant(
              of: find.byType(DictationBand),
              matching: find.byWidgetPredicate(
                (w) => w is Container && w.decoration is BoxDecoration,
              ),
            )
            .evaluate())
      (element.widget as Container).decoration! as BoxDecoration,
  ];
  return decorations.indexWhere((d) => d.border != null);
}

int _bandPlaybackMs(WidgetTester tester) =>
    tester.widget<DictationBand>(find.byType(DictationBand)).currentPlaybackMs;

Future<void> _pumpTick(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
}

void main() {
  testWidgets(
    'a playback tick repaints the dictation band without rebuilding the card',
    (tester) async {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final positions = StreamController<Duration>.broadcast();
      addTearDown(positions.close);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          deviceGlobalAppDatabaseProvider.overrideWithValue(db),
          displayPositionProvider.overrideWith((ref) => positions.stream),
          transcriptLineRecordingCountsProvider(
            'media-1',
          ).overrideWithValue(const {}),
          transcriptBlurModeProvider.overrideWith(_BlurModeOn.new),
          karaokeHighlightSettingsProvider.overrideWith(
            _KaraokeHighlightOff.new,
          ),
          ...transcriptWordPracticeOffOverrides(),
        ],
      );
      addTearDown(container.dispose);

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
                    lines: _lines,
                    echo: _echo,
                    activeCueIndex: 0,
                    secondaryLines: [],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      positions.add(const Duration(milliseconds: 100));
      await _pumpTick(tester);

      expect(_bandPlaybackMs(tester), 100);
      expect(_activeDictationWordIndex(tester), 0);

      final bracketsBefore = _loopBracketsPainter(tester);
      final tilesBefore = transcriptTileBuildCount;

      positions.add(const Duration(milliseconds: 500));
      await _pumpTick(tester);

      expect(
        identical(_loopBracketsPainter(tester), bracketsBefore),
        isTrue,
        reason:
            'the card constructs a fresh EchoLoopBrackets on every build, so '
            'an identical painter proves it did not rebuild on the tick',
      );
      expect(
        transcriptTileBuildCount,
        tilesBefore,
        reason: 'the cached line tiles do not rebuild on a position tick',
      );
      expect(_bandPlaybackMs(tester), 500);
      expect(_activeDictationWordIndex(tester), 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
