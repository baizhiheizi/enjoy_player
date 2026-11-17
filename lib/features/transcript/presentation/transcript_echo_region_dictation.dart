/// Dictation (blur-mode) subtree of the echo region: the reference word band
/// inside the loop block and the attempt panel/list under it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/echo/echo_region_key.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/dictation/application/dictation_providers.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_band_words.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_band.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_list.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_panel.dart';
import 'package:enjoy_player/features/player/application/display_position_provider.dart';

DictationSessionCtrlProvider echoRegionSessionCtrl(EchoRegionKey key) =>
    dictationSessionCtrlProvider(
      key.targetType,
      key.targetId,
      key.startMs,
      key.durationMs,
      key.referenceText,
      key.language,
    );

class EchoRegionDictationBand extends ConsumerStatefulWidget {
  const EchoRegionDictationBand({
    required this.region,
    required this.lines,
    required this.echoStartLineIndex,
    required this.echoEndLineIndex,
    required this.loopFontSize,
    super.key,
  });

  final EchoRegionKey region;
  final List<TranscriptLine> lines;
  final int echoStartLineIndex;
  final int echoEndLineIndex;
  final double loopFontSize;

  @override
  ConsumerState<EchoRegionDictationBand> createState() =>
      _EchoRegionDictationBandState();
}

class _EchoRegionDictationBandState
    extends ConsumerState<EchoRegionDictationBand> {
  late List<TranscriptLine> _selectedLines;
  late List<DictationBandWord> _bandWords;
  int _latestPlaybackMs = 0;

  void _rebuildMemo() {
    _selectedLines = [
      for (
        var i = widget.echoStartLineIndex;
        i <= widget.echoEndLineIndex && i < widget.lines.length;
        i++
      )
        widget.lines[i],
    ];
    _bandWords = buildDictationBandWords(
      lines: _selectedLines,
      fallbackReferenceText: widget.region.referenceText,
      regionStartMs: widget.region.startMs,
      regionDurationMs: widget.region.durationMs,
    );
  }

  @override
  void initState() {
    super.initState();
    _rebuildMemo();
  }

  @override
  void didUpdateWidget(covariant EchoRegionDictationBand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.region != widget.region ||
        oldWidget.echoStartLineIndex != widget.echoStartLineIndex ||
        oldWidget.echoEndLineIndex != widget.echoEndLineIndex ||
        !identical(oldWidget.lines, widget.lines)) {
      _rebuildMemo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tok = EnjoyThemeTokens.of(context);
    final diffResult = ref.watch(
      echoRegionSessionCtrl(widget.region).select((s) => s.activeDiff),
    );
    int? activeIndex;
    if (diffResult == null) {
      activeIndex = ref.watch(
        displayPositionProvider.select((posAsync) {
          final ms = switch (posAsync) {
            AsyncData(:final value) => value.inMilliseconds,
            _ => 0,
          };
          _latestPlaybackMs = ms;
          return findActiveDictationWordIndex(
            words: _bandWords,
            currentPlaybackMs: ms,
          );
        }),
      );
    }

    return DictationBand(
      lines: _selectedLines,
      fallbackReferenceText: widget.region.referenceText,
      regionStartMs: widget.region.startMs,
      regionDurationMs: widget.region.durationMs,
      currentPlaybackMs: _latestPlaybackMs,
      diffResult: diffResult,
      prebuiltWords: _bandWords,
      activeIndexOverride: activeIndex,
      textStyle: TextStyle(
        fontSize: widget.loopFontSize,
        fontWeight: FontWeight.w500,
        color: tok.ink,
      ),
    );
  }
}

class EchoRegionDictationAttempts extends ConsumerWidget {
  const EchoRegionDictationAttempts({
    required this.region,
    required this.onNextLine,
    super.key,
  });

  final EchoRegionKey region;
  final VoidCallback onNextLine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(echoRegionSessionCtrl(region));
    final ctrl = ref.read(echoRegionSessionCtrl(region).notifier);
    final history =
        ref
            .watch(
              dictationEchoRegionHistoryProvider((
                targetType: region.targetType,
                targetId: region.targetId,
                startMs: region.startMs,
                durationMs: region.durationMs,
              )),
            )
            .value ??
        const <DictationRow>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DictationPanel(
          state: session,
          controller: ctrl,
          onNextLine: onNextLine,
        ),
        if (history.isNotEmpty)
          DictationList(
            attempts: history,
            selectedAttempt: session.selectedHistoricalAttempt,
            onSelectAttempt: (attempt) => ctrl.selectHistoricalAttempt(attempt),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
