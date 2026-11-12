/// Dictation (blur-mode) subtree of the echo region: the reference word band
/// inside the loop block and the attempt panel/list under it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/dictation/application/dictation_providers.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_band.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_list.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_panel.dart';
import 'package:enjoy_player/features/player/application/display_position_provider.dart';

typedef EchoDictationRegionKey = ({
  String targetType,
  String mediaId,
  int startMs,
  int durationMs,
  String referenceText,
  String language,
});

DictationSessionCtrlProvider echoRegionSessionCtrl(
  EchoDictationRegionKey key,
) => dictationSessionCtrlProvider(
  key.targetType,
  key.mediaId,
  key.startMs,
  key.durationMs,
  key.referenceText,
  key.language,
);

class EchoRegionDictationBand extends ConsumerWidget {
  const EchoRegionDictationBand({
    required this.region,
    required this.lines,
    required this.echoStartLineIndex,
    required this.echoEndLineIndex,
    required this.loopFontSize,
    super.key,
  });

  final EchoDictationRegionKey region;
  final List<TranscriptLine> lines;
  final int echoStartLineIndex;
  final int echoEndLineIndex;
  final double loopFontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = EnjoyThemeTokens.of(context);
    final session = ref.watch(echoRegionSessionCtrl(region));
    final posAsync = ref.watch(displayPositionProvider);
    final currentPlaybackMs = switch (posAsync) {
      AsyncData(:final value) => value.inMilliseconds,
      _ => 0,
    };
    final selectedLines = [
      for (
        var i = echoStartLineIndex;
        i <= echoEndLineIndex && i < lines.length;
        i++
      )
        lines[i],
    ];

    return DictationBand(
      lines: selectedLines,
      fallbackReferenceText: region.referenceText,
      regionStartMs: region.startMs,
      regionDurationMs: region.durationMs,
      currentPlaybackMs: currentPlaybackMs,
      diffResult: session.activeDiff,
      textStyle: TextStyle(
        fontSize: loopFontSize,
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

  final EchoDictationRegionKey region;
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
                targetId: region.mediaId,
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
          controller: ctrl.controller,
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
