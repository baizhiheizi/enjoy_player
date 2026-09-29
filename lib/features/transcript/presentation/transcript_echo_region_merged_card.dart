/// Echo segment as one card with controls and optional shadow-reading panel.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/transcript/transcript_density.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/shadow_reading_panel.dart';
import 'package:enjoy_player/features/lookup/application/transcript_lookup_open.dart';
import 'package:enjoy_player/features/transcript/application/active_transcript_provider.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_controller.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_resolved_text.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_line_request_policy.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_recording_counts_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_alignment.dart';
import 'package:enjoy_player/features/transcript/presentation/echo_region_controls_bar.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class EchoRegionMergedCard extends ConsumerWidget {
  const EchoRegionMergedCard({
    required this.mediaId,
    required this.lines,
    required this.echo,
    required this.activeCueIndex,
    required this.secondaryLines,
    this.secondaryMatcher,
    super.key,
  });

  final String mediaId;
  final List<TranscriptLine> lines;
  final EchoState echo;
  final int activeCueIndex;
  final List<TranscriptLine> secondaryLines;

  /// When null, a matcher is built from [secondaryLines].
  final TranscriptSecondaryMatcher? secondaryMatcher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);
    final density = transcriptDensityOf(context);
    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final matcher =
        secondaryMatcher ?? TranscriptSecondaryMatcher.from(secondaryLines);
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

    final shell = scheme.surfaceContainerLow;

    final showShadow = echo.startTimeSeconds >= 0 && echo.endTimeSeconds >= 0;

    final lineWidgets = <Widget>[];
    for (var i = echo.startLineIndex; i <= echo.endLineIndex; i++) {
      if (i > echo.startLineIndex) {
        lineWidgets.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: tok.space12,
            endIndent: tok.space12,
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        );
      }

      final line = lines[i];
      final isActive = i == activeCueIndex;
      final resolved = resolveAutoTranslateTextForDisplay(
        autoTranslateActive: autoTranslateActive,
        primaryLines: lines,
        aiLines: secondaryLines,
        lineIndex: i,
        sourceLanguage: autoTranslateMode.sourceLanguage,
        targetLanguage: autoTranslateMode.targetLanguage,
        matcher: matcher,
        line: line,
        isLineFailed: (i) =>
            ref.read(autoTranslateCtrlProvider(mediaId)).isLineFailed(i),
        isLineInFlight: (i) =>
            ref.read(autoTranslateCtrlProvider(mediaId)).isLineInFlight(i),
        l10nLineFailed: AppLocalizations.of(
          context,
        )?.subtitlesAutoTranslateLineFailed,
        l10nLinePending: AppLocalizations.of(
          context,
        )?.subtitlesAutoTranslatePendingLine,
      );
      final secondaryText = resolved.secondaryText;
      final canRetranslate = resolved.canRetranslate;
      final lineFailed = resolved.isFailed;

      if (shouldRequestAutoTranslateLine(
        lineIndex: i,
        anchorLineIndex: 0,
        scope: AutoTranslateRequestScope.block,
        isAutoTranslateActive: autoTranslateActive,
        hasSecondaryText:
            secondaryText != null && secondaryText.trim().isNotEmpty,
        isLineFailed: lineFailed,
      )) {
        scheduleAutoTranslateLineRequest(
          isMounted: () => ref.context.mounted,
          request: () => ref
              .read(autoTranslateCtrlProvider(mediaId).notifier)
              .requestTranslateLine(i),
        );
      }

      final tile = TranscriptLineTile(
        key: ValueKey<String>('echo-line-$i'),
        line: line,
        lineIndex: i,
        mediaId: mediaId,
        secondaryText: secondaryText,
        isActive: isActive,
        inEcho: true,
        groupedInEcho: true,
        selectable: true,
        recordingCount: lineRecordingCounts?[i],
        onLookupRequested: (t) => openTranscriptLookup(
          ref: ref,
          context: context,
          selectedText: t,
          lines: lines,
        ),
        onRetranslateSecondary: canRetranslate
            ? () => unawaited(
                ref
                    .read(autoTranslateCtrlProvider(mediaId).notifier)
                    .retranslateLine(i),
              )
            : null,
        onTap: () => ref.read(playerInteractionsProvider).seekToLine(line, i),
      );

      lineWidgets.add(tile);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        EchoRegionControlsBar(
          position: EchoRegionBarPosition.top,
          expandDisabled: echo.startLineIndex <= 0,
          shrinkDisabled: echo.startLineIndex >= echo.endLineIndex,
          dense: true,
          onExpand: () => _deferEchoResize(
            ref,
            () => ref.read(echoModeProvider.notifier).expandEchoBackward(lines),
          ),
          onShrink: () => _deferEchoResize(
            ref,
            () => ref.read(echoModeProvider.notifier).shrinkEchoBackward(lines),
          ),
        ),
        SizedBox(height: density.echoCardGap),
        ClipRRect(
          borderRadius: BorderRadius.circular(tok.radiusMd),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 8,
                  decoration: BoxDecoration(color: tok.echoActive),
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: shell,
                      border: Border(
                        top: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.18),
                        ),
                        right: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.18),
                        ),
                        bottom: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.18),
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: lineWidgets,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: density.echoCardGap),
        EchoRegionControlsBar(
          position: EchoRegionBarPosition.bottom,
          expandDisabled: echo.endLineIndex >= lines.length - 1,
          shrinkDisabled: echo.endLineIndex <= echo.startLineIndex,
          dense: true,
          onExpand: () => _deferEchoResize(
            ref,
            () => ref.read(echoModeProvider.notifier).expandEchoForward(lines),
          ),
          onShrink: () => _deferEchoResize(
            ref,
            () => ref.read(echoModeProvider.notifier).shrinkEchoForward(lines),
          ),
        ),
        if (showShadow) ...[
          SizedBox(height: density.echoBottomPanelGap),
          ShadowReadingPanel(
            mediaId: mediaId,
            targetType: chrome?.dexieTargetType ?? 'Audio',
            language: chrome?.language ?? 'en',
            startSec: echo.startTimeSeconds,
            endSec: echo.endTimeSeconds,
            referenceText: echoReferencePlainText(lines, echo),
            echoActive: echo.active,
            showLiveProgress: true,
          ),
        ],
      ],
    );
  }
}

void _deferEchoResize(WidgetRef ref, VoidCallback apply) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!ref.context.mounted) return;
    apply();
  });
}
