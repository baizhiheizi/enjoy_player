import 'dart:io';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/settings/application/karaoke_highlight_settings.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_recording_counts_provider.dart';
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

List<TranscriptLine> _lines(int count) => [
  for (var i = 0; i < count; i++)
    TranscriptLine(
      text: 'Echo cue line number $i with a few more words',
      startMs: i * 1500,
      durationMs: 1500,
    ),
];

EchoState _echo(int start, int end) => EchoState(
  active: true,
  startLineIndex: start,
  endLineIndex: end,
  startTimeSeconds: -1,
  endTimeSeconds: -1,
);

Widget _harness({
  required List<TranscriptLine> lines,
  required EchoState echo,
  required int activeCueIndex,
  Map<int, int>? counts = const {},
  bool reuseUnchangedTiles = true,
}) {
  return ProviderScope(
    overrides: [
      transcriptLineRecordingCountsProvider(
        'media-1',
      ).overrideWithValue(counts),
      karaokeHighlightSettingsProvider.overrideWith(_KaraokeHighlightOff.new),
      ...transcriptWordPracticeOffOverrides(),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListView(
          children: [
            EchoRegionMergedCard(
              mediaId: 'media-1',
              lines: lines,
              echo: echo,
              activeCueIndex: activeCueIndex,
              secondaryLines: const [],
              reuseUnchangedTiles: reuseUnchangedTiles,
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'a cue change rebuilds only the outgoing and incoming active tiles',
    (tester) async {
      final lines = _lines(60);
      await tester.pumpWidget(
        _harness(lines: lines, echo: _echo(0, 59), activeCueIndex: 10),
      );
      await tester.pumpAndSettle();

      final before = transcriptTileBuildCount;
      await tester.pumpWidget(
        _harness(lines: lines, echo: _echo(0, 59), activeCueIndex: 11),
      );
      await tester.pumpAndSettle();
      expect(transcriptTileBuildCount, before + 2);
    },
  );

  testWidgets('an unchanged rebuild reuses every tile', (tester) async {
    final lines = _lines(60);
    await tester.pumpWidget(
      _harness(lines: lines, echo: _echo(0, 59), activeCueIndex: 10),
    );
    await tester.pumpAndSettle();

    final before = transcriptTileBuildCount;
    await tester.pumpWidget(
      _harness(lines: lines, echo: _echo(0, 59), activeCueIndex: 10),
    );
    await tester.pumpAndSettle();
    expect(transcriptTileBuildCount, before);
  });

  testWidgets('a recording-count change rebuilds only that line', (
    tester,
  ) async {
    final lines = _lines(60);
    await tester.pumpWidget(
      _harness(lines: lines, echo: _echo(0, 59), activeCueIndex: 10),
    );
    await tester.pumpAndSettle();

    final before = transcriptTileBuildCount;
    await tester.pumpWidget(
      _harness(
        lines: lines,
        echo: _echo(0, 59),
        activeCueIndex: 10,
        counts: const {11: 3},
      ),
    );
    await tester.pumpAndSettle();
    expect(transcriptTileBuildCount, before + 1);
  });

  testWidgets('an echo range change rebuilds the new range', (tester) async {
    final lines = _lines(60);
    await tester.pumpWidget(
      _harness(lines: lines, echo: _echo(0, 59), activeCueIndex: 10),
    );
    await tester.pumpAndSettle();

    final before = transcriptTileBuildCount;
    await tester.pumpWidget(
      _harness(lines: lines, echo: _echo(0, 29), activeCueIndex: 10),
    );
    await tester.pumpAndSettle();
    expect(transcriptTileBuildCount, before + 30);
  });

  testWidgets('a new transcript lines list invalidates the cached tiles', (
    tester,
  ) async {
    final lines = _lines(60);
    await tester.pumpWidget(
      _harness(lines: lines, echo: _echo(0, 59), activeCueIndex: 10),
    );
    await tester.pumpAndSettle();

    final before = transcriptTileBuildCount;
    await tester.pumpWidget(
      _harness(
        lines: List<TranscriptLine>.of(lines),
        echo: _echo(0, 59),
        activeCueIndex: 10,
      ),
    );
    await tester.pumpAndSettle();
    expect(transcriptTileBuildCount - before, greaterThanOrEqualTo(60));
  });

  testWidgets('without tile reuse a cue change rebuilds the whole range', (
    tester,
  ) async {
    final lines = _lines(60);
    await tester.pumpWidget(
      _harness(
        lines: lines,
        echo: _echo(0, 59),
        activeCueIndex: 10,
        reuseUnchangedTiles: false,
      ),
    );
    await tester.pumpAndSettle();

    final before = transcriptTileBuildCount;
    await tester.pumpWidget(
      _harness(
        lines: lines,
        echo: _echo(0, 59),
        activeCueIndex: 11,
        reuseUnchangedTiles: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(transcriptTileBuildCount - before, greaterThanOrEqualTo(60));
  });

  testWidgets('cue-change rebuild cost across a long echo block (local only)', (
    tester,
  ) async {
    const lineCount = 300;
    const changes = 40;
    final lines = _lines(lineCount);
    final mode = Platform.environment['ECHO_CARD_BENCH_MODE'] ?? 'cached';
    final reuseUnchangedTiles = mode != 'legacy';

    await tester.pumpWidget(
      _harness(
        lines: lines,
        echo: _echo(0, lineCount - 1),
        activeCueIndex: 0,
        reuseUnchangedTiles: reuseUnchangedTiles,
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 1; i <= 5; i++) {
      await tester.pumpWidget(
        _harness(
          lines: lines,
          echo: _echo(0, lineCount - 1),
          activeCueIndex: i,
          reuseUnchangedTiles: reuseUnchangedTiles,
        ),
      );
      await tester.pump();
    }

    final buildsBefore = transcriptTileBuildCount;
    final watch = Stopwatch()..start();
    for (var i = 6; i < 6 + changes; i++) {
      await tester.pumpWidget(
        _harness(
          lines: lines,
          echo: _echo(0, lineCount - 1),
          activeCueIndex: i,
          reuseUnchangedTiles: reuseUnchangedTiles,
        ),
      );
    }
    watch.stop();
    final builds = transcriptTileBuildCount - buildsBefore;

    final perChange = watch.elapsedMicroseconds / changes / 1000;
    // ignore: avoid_print
    print(
      'echo card cue-change ($mode): ${perChange.toStringAsFixed(3)} '
      'ms/change over $lineCount loop lines, '
      '${(builds / changes).toStringAsFixed(1)} tile builds/change',
    );
    expect(perChange, lessThan(2000));
  }, skip: true);
}
