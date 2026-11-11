/// Echo loop lens: the loop block grows in place inside `you` corner
/// brackets, the live recording readout, and the “+ line” row below the loop
/// (the row above is the list's own slot for that line).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/transcript/presentation/transcript_echo_loop_edge_row.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/transcript/transcript_density.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/shadow_reading_panel.dart';
import 'package:enjoy_player/features/transcript/application/active_transcript_provider.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_recording_counts_provider.dart';
import 'package:enjoy_player/features/transcript/application/take_assessment_notes_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_alignment.dart';
import 'package:enjoy_player/features/transcript/presentation/echo_loop_brackets.dart';
import 'package:enjoy_player/features/transcript/presentation/echo_loop_recording_progress.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_echo_region_tile_builder.dart';
import 'package:enjoy_player/core/transcript/transcript_lens_metrics.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_take_providers.dart';
import 'package:enjoy_player/features/player/application/display_position_provider.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_markup.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/dictation/application/dictation_providers.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_band.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_list.dart';
import 'package:enjoy_player/features/dictation/presentation/dictation_panel.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class EchoRegionMergedCard extends ConsumerStatefulWidget {
  const EchoRegionMergedCard({
    required this.mediaId,
    required this.lines,
    required this.echo,
    required this.activeCueIndex,
    required this.secondaryLines,
    this.secondaryMatcher,
    @visibleForTesting this.reuseUnchangedTiles = true,
    super.key,
  });

  final String mediaId;
  final List<TranscriptLine> lines;
  final EchoState echo;
  final int activeCueIndex;
  final List<TranscriptLine> secondaryLines;

  /// When null, a matcher is built from [secondaryLines].
  final TranscriptSecondaryMatcher? secondaryMatcher;

  /// Whether a rebuild may reuse a tile whose inputs are unchanged.
  @visibleForTesting
  final bool reuseUnchangedTiles;

  @override
  ConsumerState<EchoRegionMergedCard> createState() =>
      _EchoRegionMergedCardState();
}

class _EchoRegionMergedCardState extends ConsumerState<EchoRegionMergedCard> {
  final EchoRegionTileCache _tiles = EchoRegionTileCache();

  @override
  void didUpdateWidget(EchoRegionMergedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.lines, widget.lines) ||
        oldWidget.mediaId != widget.mediaId ||
        oldWidget.reuseUnchangedTiles != widget.reuseUnchangedTiles ||
        oldWidget.echo.startLineIndex != widget.echo.startLineIndex ||
        oldWidget.echo.endLineIndex != widget.echo.endLineIndex) {
      _tiles.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaId = widget.mediaId;
    final lines = widget.lines;
    final echo = widget.echo;
    final activeCueIndex = widget.activeCueIndex;
    final secondaryLines = widget.secondaryLines;
    final tok = EnjoyThemeTokens.of(context);
    final density = transcriptDensityOf(context);
    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final recording = ref.watch(
      shadowReadingHotkeyBusProvider.select((s) => s.isRecordingActive),
    );
    final matcher =
        widget.secondaryMatcher ??
        TranscriptSecondaryMatcher.from(secondaryLines);
    final lineRecordingCounts = ref.watch(
      transcriptLineRecordingCountsProvider(mediaId),
    );
    final autoTranslateMode = ref.watch(
      autoTranslateCtrlProvider(mediaId).select(
        (s) => (
          isActive: s.isActive,
          aiTranscriptId: s.aiTranscriptId,
          sourceLanguage: s.sourceLanguage,
          targetLanguage: s.targetLanguage,
        ),
      ),
    );
    final secondaryId = ref.watch(secondaryTranscriptIdProvider(mediaId)).value;
    final autoTranslateActive =
        autoTranslateMode.isActive &&
        autoTranslateMode.aiTranscriptId != null &&
        secondaryId == autoTranslateMode.aiTranscriptId;

    final showShadow = echo.startTimeSeconds >= 0 && echo.endTimeSeconds >= 0;
    final blurMode = ref.watch(transcriptBlurModeProvider);
    final loopLines = echo.endLineIndex - echo.startLineIndex + 1;
    final metrics = TranscriptLensMetrics.of(context);
    final loopFontSize = metrics.loopFontSize(
      loopLines,
      mediaWidth: MediaQuery.sizeOf(context).width,
    );

    final scoredTake = ref
        .watch(echoRegionRecordingsOnceProvider(_regionQueryFor(mediaId, echo)))
        .value
        ?.where((r) => r.assessmentJson?.trim().isNotEmpty == true)
        .firstOrNull;
    final wavyByLine = scoredTake == null
        ? null
        : ref
              .watch(
                takeAssessmentNotesProvider((
                  mediaId: mediaId,
                  recordingId: scoredTake.id,
                  assessmentJson: scoredTake.assessmentJson!,
                )),
              )
              ?.byLine;

    var maxTakeNumber = 0;
    if (lineRecordingCounts != null) {
      for (var i = echo.startLineIndex; i <= echo.endLineIndex; i++) {
        final n = lineRecordingCounts[i];
        if (n != null && n > maxTakeNumber) maxTakeNumber = n;
      }
    }

    final lineWidgets = buildEchoRegionTiles(
      ref: ref,
      context: context,
      mediaId: mediaId,
      lines: lines,
      secondaryLines: secondaryLines,
      matcher: matcher,
      echo: echo,
      activeCueIndex: activeCueIndex,
      autoTranslateActive: autoTranslateActive,
      autoTranslateSourceLanguage: autoTranslateMode.sourceLanguage,
      autoTranslateTargetLanguage: autoTranslateMode.targetLanguage,
      wavyByLine: wavyByLine,
      lineRecordingCounts: lineRecordingCounts,
      loopFontSize: loopFontSize,
      loopLineGap: metrics.loopLineGap,
      reuseUnchangedTiles: widget.reuseUnchangedTiles,
      cache: _tiles,
    );

    final loopSeconds = (echo.endTimeSeconds - echo.startTimeSeconds).clamp(
      0.0,
      3600.0,
    );
    final secondsLabel = loopSeconds.toStringAsFixed(1);
    final l10n = AppLocalizations.of(context)!;
    final targetType = chrome?.dexieTargetType ?? 'Audio';
    final language = chrome?.language ?? 'en';
    final startMs = (echo.startTimeSeconds * 1000).round();
    final durationMs = ((echo.endTimeSeconds - echo.startTimeSeconds) * 1000)
        .round();
    final referenceText = echoReferencePlainText(lines, echo);

    final dictationSession = blurMode
        ? ref.watch(
            dictationSessionCtrlProvider(
              targetType,
              mediaId,
              startMs,
              durationMs,
              referenceText,
              language,
            ),
          )
        : null;
    final dictationCtrl = blurMode
        ? ref.read(
            dictationSessionCtrlProvider(
              targetType,
              mediaId,
              startMs,
              durationMs,
              referenceText,
              language,
            ).notifier,
          )
        : null;
    final dictationHistory = blurMode
        ? (ref
                  .watch(
                    dictationEchoRegionHistoryProvider((
                      targetType: targetType,
                      targetId: mediaId,
                      startMs: startMs,
                      durationMs: durationMs,
                    )),
                  )
                  .value ??
              const <DictationRow>[])
        : const <DictationRow>[];

    final posAsync = ref.watch(displayPositionProvider);
    final currentPlaybackMs = switch (posAsync) {
      AsyncData(:final value) => value.inMilliseconds,
      _ => 0,
    };
    final selectedLines = [
      for (
        var i = echo.startLineIndex;
        i <= echo.endLineIndex && i < lines.length;
        i++
      )
        lines[i],
    ];

    final loopLabel = blurMode
        ? (dictationSession?.status == DictationAttemptStatus.checked
              ? l10n.playerDictationHeaderChecked
              : l10n.playerDictationHeaderListen)
        : recording
        ? l10n.echoLoopCaptionRecording(maxTakeNumber + 1)
        : loopLines > 1
        ? l10n.echoLoopCaptionLines(
            '${echo.startLineIndex + 1}–${echo.endLineIndex + 1}',
            secondsLabel,
          )
        : l10n.echoLoopCaptionLine('${echo.startLineIndex + 1}', secondsLabel);

    final tt = Theme.of(context).textTheme;
    final typography = TranscriptTypographyTokens.of(context);
    final gutterStyle = typography.timestampStyle.copyWith(
      fontSize: metrics.timeFontSize,
      color: tok.youInk,
    );
    final labelStyle = tt.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 11 * 0.09,
      color: tok.youInk,
    );
    final textIndent = metrics.showLoopGutter
        ? metrics.gutterWidth + metrics.gutterGap
        : 0.0;

    final section = Padding(
      padding: metrics.loopPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (metrics.showLoopGutter) ...[
                SizedBox(
                  width: metrics.gutterWidth,
                  child: Text(
                    formatTranscriptTimestampMs(
                      lines[echo.startLineIndex].startMs,
                    ),
                    style: gutterStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(width: metrics.gutterGap),
              ],
              Expanded(
                child: Row(
                  children: [
                    if (recording) ...[
                      EchoRecordingPulseDot(color: tok.you),
                      SizedBox(width: metrics.loopLabelGap),
                    ],
                    Flexible(
                      child: Text(
                        loopLabel,
                        style: labelStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: metrics.loopLabelBottomGap),
          Padding(
            padding: EdgeInsets.only(left: textIndent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (blurMode)
                  DictationBand(
                    lines: selectedLines,
                    fallbackReferenceText: referenceText,
                    regionStartMs: startMs,
                    regionDurationMs: durationMs,
                    currentPlaybackMs: currentPlaybackMs,
                    diffResult: dictationSession?.activeDiff,
                    textStyle: TextStyle(
                      fontSize: loopFontSize,
                      fontWeight: FontWeight.w500,
                      color: tok.ink,
                    ),
                  )
                else
                  ...lineWidgets,
                if (recording && loopSeconds > 0) ...[
                  SizedBox(height: metrics.loopRecordingTopGap),
                  EchoLoopRecordingProgress(targetSec: loopSeconds),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: metrics.loopTopRowGap,
            bottom: 4,
            left: metrics.loopSideMargin,
            right: metrics.loopSideMargin,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: EchoLoopBrackets(
                      color: tok.you,
                      arm: metrics.bracketArm,
                      radius: metrics.bracketRadius,
                    ),
                  ),
                ),
              ),
              section,
            ],
          ),
        ),
        if (!recording && echo.endLineIndex + 1 < lines.length)
          EchoLoopEdgeRow(
            line: lines[echo.endLineIndex + 1],
            edge: EchoLoopEdge.below,
            canDrop: echo.endLineIndex > echo.startLineIndex,
          ),
        if (showShadow) ...[
          SizedBox(height: density.echoBottomPanelGap),
          if (blurMode &&
              dictationSession != null &&
              dictationCtrl != null) ...[
            DictationPanel(
              state: dictationSession,
              controller: dictationCtrl.controller,
              onNextLine: () => ref.read(playerInteractionsProvider).nextLine(),
            ),
            if (dictationHistory.isNotEmpty)
              DictationList(
                attempts: dictationHistory,
                selectedAttempt: dictationSession.selectedHistoricalAttempt,
                onSelectAttempt: (attempt) =>
                    dictationCtrl.selectHistoricalAttempt(attempt),
              ),
            const SizedBox(height: 8),
          ],
          ShadowReadingPanel(
            mediaId: mediaId,
            targetType: chrome?.dexieTargetType ?? 'Audio',
            language: chrome?.language ?? 'en',
            startSec: echo.startTimeSeconds,
            endSec: echo.endTimeSeconds,
            referenceText: echoReferencePlainText(lines, echo),
            echoActive: echo.active,
            showLiveProgress: true,
            takesRowInLoop: true,
            onTakePersisted: blurMode
                ? (row) => dictationCtrl?.onVoiceTakeRecorded(row)
                : null,
          ),
        ],
      ],
    );
  }
}

EchoRegionRecordingsQuery _regionQueryFor(String mediaId, EchoState echo) =>
    EchoRegionRecordingsQuery(
      targetType: 'Audio',
      targetId: mediaId,
      language: 'en',
      echoStartMs: (echo.startTimeSeconds * 1000).round(),
      echoEndMs: (echo.endTimeSeconds * 1000).round(),
    );
