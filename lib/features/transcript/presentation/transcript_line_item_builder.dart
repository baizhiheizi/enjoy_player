/// Per-row rendering for the scrollable transcript list: turns one
/// [TranscriptVirtualItem] into exactly one list row.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/transcript/transcript_density.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/lookup/application/transcript_lookup_open.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_controller.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_line_request_policy.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_resolved_text.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_alignment.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_virtual_items.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_auto_scroll_controller.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_echo_loop_edge_row.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_echo_region_merged_card.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Whether the cue at [lineIndex] is worth requesting a translation for,
/// given an [anchor] cue index.
///
/// A top-level function rather than a closure built inside the item builder:
/// that builder runs once per row, so a local function there allocated a fresh
/// closure per row on every scroll-driven rebuild (issue #764 review).
/// [alternateAnchorLineIndex] stays a resolver so the policy can short-circuit
/// on eligibility before it reads the scroll controller.
bool requestableAutoTranslate({
  required int Function() alternateAnchorLineIndex,
  required int lineIndex,
  required int anchor,
  required bool isAutoTranslateActive,
  required bool hasSecondaryText,
  required bool isLineFailed,
}) {
  return shouldRequestAutoTranslateLine(
    lineIndex: lineIndex,
    anchorLineIndex: anchor,
    alternateAnchorLineIndex: alternateAnchorLineIndex,
    scope: AutoTranslateRequestScope.viewport,
    isAutoTranslateActive: isAutoTranslateActive,
    hasSecondaryText: hasSecondaryText,
    isLineFailed: isLineFailed,
  );
}

/// Values the per-row builder reads that are stable for one list build, so the
/// [ListView.builder] closure allocates one scope per build instead of
/// capturing the watch results per row.
final class TranscriptListItemScope {
  const TranscriptListItemScope({
    required this.ref,
    required this.scroll,
    required this.mediaId,
    required this.lines,
    required this.echo,
    required this.activeCueIndex,
    required this.recordingTake,
    required this.secondaryLines,
    required this.secondaryMatcher,
    required this.autoTranslateActive,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.autoTranslateCtrl,
    required this.l10n,
    required this.lineRecordingCounts,
    required this.density,
  });

  final WidgetRef ref;
  final TranscriptAutoScrollController scroll;
  final String mediaId;
  final List<TranscriptLine> lines;
  final EchoState echo;
  final int activeCueIndex;
  final bool recordingTake;
  final List<TranscriptLine> secondaryLines;
  final TranscriptSecondaryMatcher secondaryMatcher;
  final bool autoTranslateActive;
  final String? sourceLanguage;
  final String? targetLanguage;
  final AutoTranslateUiState autoTranslateCtrl;
  final AppLocalizations? l10n;
  final Map<int, int>? lineRecordingCounts;
  final TranscriptDensity density;
}

Widget buildTranscriptListItem(
  BuildContext context,
  TranscriptListItemScope scope,
  TranscriptVirtualItem item,
) {
  switch (item) {
    case TranscriptVirtualEcho e:
      return Padding(
        key: ValueKey<String>('echo-${e.startLineIndex}-${e.endLineIndex}'),
        padding: EdgeInsets.only(bottom: scope.density.lineInterGap),
        child: KeyedSubtree(
          key: scope.scroll.scrollKeyForEcho(scope.echo),
          child: EchoRegionMergedCard(
            mediaId: scope.mediaId,
            lines: scope.lines,
            echo: scope.echo,
            activeCueIndex: scope.activeCueIndex,
            secondaryLines: scope.secondaryLines,
            secondaryMatcher: scope.secondaryMatcher,
          ),
        ),
      );
    case TranscriptVirtualLine vl:
      final lineIndex = vl.lineIndex;
      final line = scope.lines[lineIndex];
      final isActive = lineIndex == scope.activeCueIndex;
      final inEcho =
          scope.echo.active &&
          lineIndex >= scope.echo.startLineIndex &&
          lineIndex <= scope.echo.endLineIndex;
      final resolved = resolveAutoTranslateTextForDisplay(
        autoTranslateActive: scope.autoTranslateActive,
        primaryLines: scope.lines,
        aiLines: scope.secondaryLines,
        lineIndex: lineIndex,
        sourceLanguage: scope.sourceLanguage,
        targetLanguage: scope.targetLanguage,
        matcher: scope.secondaryMatcher,
        line: line,
        isLineFailed: scope.autoTranslateCtrl.isLineFailed,
        isLineInFlight: scope.autoTranslateCtrl.isLineInFlight,
        l10nLineFailed: scope.l10n?.subtitlesAutoTranslateLineFailed,
        l10nLinePending: scope.l10n?.subtitlesAutoTranslatePendingLine,
      );
      final secondaryText = resolved.secondaryText;
      final canRetranslateLine = resolved.canRetranslate;
      final lineFailed = resolved.isFailed;

      final hasSecondary =
          secondaryText != null && secondaryText.trim().isNotEmpty;
      if (requestableAutoTranslate(
        alternateAnchorLineIndex: scope.scroll.scrollFocusLineIndex,
        lineIndex: lineIndex,
        anchor: scope.activeCueIndex,
        isAutoTranslateActive: scope.autoTranslateActive,
        hasSecondaryText: hasSecondary,
        isLineFailed: lineFailed,
      )) {
        scheduleAutoTranslateLineRequest(
          isMounted: scope.scroll.isMounted,
          shouldRequest: () => requestableAutoTranslate(
            alternateAnchorLineIndex: scope.scroll.scrollFocusLineIndex,
            lineIndex: lineIndex,
            anchor: scope.ref
                .read(transcriptPlaybackHighlightProvider(scope.mediaId))
                .cueIndex,
            isAutoTranslateActive: scope.autoTranslateActive,
            hasSecondaryText: hasSecondary,
            isLineFailed: lineFailed,
          ),
          request: () => scope.ref
              .read(autoTranslateCtrlProvider(scope.mediaId).notifier)
              .requestTranslateLine(lineIndex),
        );
      }

      final loopEdge = !scope.echo.active || scope.recordingTake
          ? null
          : lineIndex == scope.echo.startLineIndex - 1
          ? EchoLoopEdge.above
          : lineIndex == scope.echo.endLineIndex + 1
          ? EchoLoopEdge.below
          : null;
      if (loopEdge == EchoLoopEdge.below) {
        // Deliberate handshake with `EchoRegionMergedCard`: the board's order
        // is “+” row below · loop · takes, and the takes panel lives inside the
        // loop card — so the card draws this line and this list slot collapses
        // to keep the index space stable for auto-scroll and recordings.
        return SizedBox.shrink(key: ValueKey<String>('line-$lineIndex'));
      }
      if (loopEdge != null) {
        return Padding(
          key: ValueKey<String>('line-$lineIndex'),
          padding: EdgeInsets.only(bottom: scope.density.lineInterGap),
          child: EchoLoopEdgeRow(
            line: line,
            edge: loopEdge,
            canDrop: scope.echo.endLineIndex > scope.echo.startLineIndex,
          ),
        );
      }

      final selectable = isActive;
      final lensDistance = !scope.echo.active || inEcho
          ? 0
          : (lineIndex < scope.echo.startLineIndex
                    ? scope.echo.startLineIndex - lineIndex
                    : lineIndex - scope.echo.endLineIndex)
                .clamp(1, 3);
      Widget tile = TranscriptLineTile(
        line: line,
        lineIndex: lineIndex,
        mediaId: scope.mediaId,
        secondaryText: secondaryText,
        isActive: isActive,
        inEcho: inEcho,
        groupedInEcho: false,
        selectable: selectable,
        dimWhenInactive: scope.activeCueIndex >= 0,
        recordingCount: scope.lineRecordingCounts?[lineIndex],
        lensDistance: lensDistance,
        onLookupRequested: selectable
            ? (t) => openTranscriptLookup(
                ref: scope.ref,
                context: context,
                selectedText: t,
                lines: scope.lines,
                lineIndex: lineIndex,
              )
            : null,
        onRetranslateSecondary: canRetranslateLine && (isActive || inEcho)
            ? () => unawaited(
                scope.ref
                    .read(autoTranslateCtrlProvider(scope.mediaId).notifier)
                    .retranslateLine(lineIndex),
              )
            : null,
        onTap: () => scope.ref
            .read(playerInteractionsProvider)
            .seekToLine(line, lineIndex),
      );

      if (isActive) {
        tile = KeyedSubtree(
          key: scope.scroll.scrollKeyForActiveLine(lineIndex),
          child: tile,
        );
      }

      return Padding(
        key: ValueKey<String>('line-$lineIndex'),
        padding: EdgeInsets.only(bottom: scope.density.lineInterGap),
        child: tile,
      );
  }
}
