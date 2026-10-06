/// Echo loop lens: the loop block grows in place inside `you` corner
/// brackets, with Earlier / Later line handles and the live recording readout.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/transcript/transcript_density.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/shadow_reading_panel.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_recording_caption.dart';
import 'package:enjoy_player/features/lookup/application/transcript_lookup_open.dart';
import 'package:enjoy_player/features/transcript/application/active_transcript_provider.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_controller.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_resolved_text.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_line_request_policy.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_recording_counts_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_alignment.dart';
import 'package:enjoy_player/features/transcript/presentation/echo_loop_brackets.dart';
import 'package:enjoy_player/core/transcript/transcript_lens_metrics.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_markup.dart';
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
    final tok = EnjoyThemeTokens.of(context);
    final density = transcriptDensityOf(context);
    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final recording = ref.watch(
      shadowReadingHotkeyBusProvider.select((s) => s.isRecordingActive),
    );
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

    final showShadow = echo.startTimeSeconds >= 0 && echo.endTimeSeconds >= 0;
    final loopLines = echo.endLineIndex - echo.startLineIndex + 1;
    final metrics = TranscriptLensMetrics.of(context);
    final loopFontSize = metrics.loopFontSize(
      loopLines,
      mediaWidth: MediaQuery.sizeOf(context).width,
    );

    final lineWidgets = <Widget>[];
    var maxTakeNumber = 0;
    for (var i = echo.startLineIndex; i <= echo.endLineIndex; i++) {
      final line = lines[i];
      final isActive = i == activeCueIndex;
      maxTakeNumber = switch (lineRecordingCounts?[i]) {
        final int n when n > maxTakeNumber => n,
        _ => maxTakeNumber,
      };
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
        loopFontSize: loopFontSize,
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

      lineWidgets.add(
        i == echo.endLineIndex
            ? tile
            : Padding(
                padding: EdgeInsets.only(bottom: metrics.loopLineGap),
                child: tile,
              ),
      );
    }

    final loopSeconds = (echo.endTimeSeconds - echo.startTimeSeconds).clamp(
      0.0,
      3600.0,
    );
    final secondsLabel = loopSeconds.toStringAsFixed(1);
    final lineRangeLabel = loopLines > 1
        ? 'LINES ${echo.startLineIndex + 1}–${echo.endLineIndex + 1}'
        : 'LINE ${echo.startLineIndex + 1}';
    final loopLabel = recording
        ? 'RECORDING TAKE ${maxTakeNumber + 1}'
        : 'LOOP · $lineRangeLabel · $secondsLabel S';

    final tt = Theme.of(context).textTheme;
    final typography = TranscriptTypographyTokens.of(context);
    final gutterStyle = typography.timestampStyle.copyWith(
      fontSize: metrics.timeFontSize,
      color: tok.youInk,
    );
    final labelStyle = tt.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.08,
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
                ...lineWidgets,
                if (recording && loopSeconds > 0) ...[
                  SizedBox(height: metrics.loopRecordingTopGap),
                  _LoopRecordingProgress(targetSec: loopSeconds),
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
            top: metrics.loopTopMargin - _kLoopHandleHalfHeight,
            bottom: 21,
            left: metrics.loopSideMargin,
            right: metrics.loopSideMargin,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: _kLoopHandleHalfHeight,
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
              if (!recording)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _EchoLoopHandle(
                      position: _EchoLoopHandlePosition.top,
                      expandDisabled: echo.startLineIndex <= 0,
                      shrinkDisabled: echo.startLineIndex >= echo.endLineIndex,
                      onExpand: () => _deferEchoResize(
                        ref,
                        () => ref
                            .read(echoModeProvider.notifier)
                            .expandEchoBackward(lines),
                      ),
                      onShrink: () => _deferEchoResize(
                        ref,
                        () => ref
                            .read(echoModeProvider.notifier)
                            .shrinkEchoBackward(lines),
                      ),
                    ),
                  ),
                ),
              if (!recording)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _EchoLoopHandle(
                      position: _EchoLoopHandlePosition.bottom,
                      expandDisabled: echo.endLineIndex >= lines.length - 1,
                      shrinkDisabled: echo.endLineIndex <= echo.startLineIndex,
                      onExpand: () => _deferEchoResize(
                        ref,
                        () => ref
                            .read(echoModeProvider.notifier)
                            .expandEchoForward(lines),
                      ),
                      onShrink: () => _deferEchoResize(
                        ref,
                        () => ref
                            .read(echoModeProvider.notifier)
                            .shrinkEchoForward(lines),
                      ),
                    ),
                  ),
                ),
            ],
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
            takesRowInLoop: true,
          ),
        ],
      ],
    );
  }
}

const double _kLoopHandleHalfHeight = 17;

enum _EchoLoopHandlePosition { top, bottom }

class _EchoLoopHandle extends ConsumerWidget {
  const _EchoLoopHandle({
    required this.position,
    required this.expandDisabled,
    required this.shrinkDisabled,
    required this.onExpand,
    required this.onShrink,
  });

  final _EchoLoopHandlePosition position;
  final bool expandDisabled;
  final bool shrinkDisabled;
  final VoidCallback onExpand;
  final VoidCallback onShrink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final top = position == _EchoLoopHandlePosition.top;

    final expandId = top
        ? 'player.expandEchoBackward'
        : 'player.expandEchoForward';
    final shrinkId = top
        ? 'player.shrinkEchoBackward'
        : 'player.shrinkEchoForward';
    final expandTip = hotkeyTooltipLabel(
      ref,
      expandId,
      top ? l10n.expandEchoBackward : l10n.expandEchoForward,
    );
    final shrinkTip = hotkeyTooltipLabel(
      ref,
      shrinkId,
      top ? l10n.shrinkEchoBackward : l10n.shrinkEchoForward,
    );
    final pillLabel = top ? l10n.echoLoopEarlierLine : l10n.echoLoopLaterLine;

    Widget action({
      required String tip,
      required VoidCallback? onTap,
      required Widget child,
    }) {
      final disabled = onTap == null;
      return Tooltip(
        message: tip,
        child: Opacity(
          opacity: disabled ? 0.38 : 1,
          child: IgnorePointer(
            ignoring: disabled,
            child: EnjoyPressable(
              onTap: onTap,
              pressedScale: 0.94,
              borderRadius: BorderRadius.circular(t.radiusFull),
              child: child,
            ),
          ),
        ),
      );
    }

    final expandButton = action(
      tip: expandTip,
      onTap: expandDisabled ? null : onExpand,
      child: Container(
        height: 28,
        padding: top
            ? const EdgeInsets.only(left: 8, right: 11)
            : const EdgeInsets.only(left: 11, right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (top) ...[
              Icon(EnjoyIcons.add, size: 14, color: t.youInk),
              const SizedBox(width: 5),
            ],
            Text(
              pillLabel,
              style: tt.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.youInk,
              ),
            ),
            if (!top) ...[
              const SizedBox(width: 5),
              Icon(EnjoyIcons.add, size: 14, color: t.youInk),
            ],
          ],
        ),
      ),
    );

    final shrinkButton = action(
      tip: shrinkTip,
      onTap: shrinkDisabled ? null : onShrink,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Center(child: Icon(EnjoyIcons.minus, size: 14, color: t.youInk)),
      ),
    );

    final divider = Container(width: 1, height: 14, color: t.youLine);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: ShapeDecoration(
        color: t.paper,
        shape: StadiumBorder(side: BorderSide(color: t.youLine)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: top
            ? [expandButton, divider, shrinkButton]
            : [shrinkButton, divider, expandButton],
      ),
    );
  }
}

class _LoopRecordingProgress extends StatefulWidget {
  const _LoopRecordingProgress({required this.targetSec});

  final double targetSec;

  @override
  State<_LoopRecordingProgress> createState() => _LoopRecordingProgressState();
}

class _LoopRecordingProgressState extends State<_LoopRecordingProgress>
    with TickerProviderStateMixin {
  late final AnimationController _elapsedSec;
  late final Ticker _ticker;
  final ValueNotifier<int> _elapsedTenths = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _elapsedSec = AnimationController.unbounded(vsync: this);
    _ticker = createTicker(_onTick);
    unawaited(_ticker.start());
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsedSec.dispose();
    _elapsedTenths.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _elapsedSec.value = elapsed.inMicroseconds / 1e6;
    final tenths = (elapsed.inMicroseconds ~/ 100000);
    if (tenths != _elapsedTenths.value) _elapsedTenths.value = tenths;
  }

  @override
  Widget build(BuildContext context) {
    final tok = EnjoyThemeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height: 4,
                width: constraints.maxWidth,
                child: CustomPaint(
                  painter: _LoopBarPainter(
                    elapsed: _elapsedSec,
                    targetSec: widget.targetSec,
                    track: tok.youSoft,
                    fill: tok.you,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ValueListenableBuilder<int>(
          valueListenable: _elapsedTenths,
          builder: (context, tenths, _) {
            final elapsedSec = tenths / 10;
            final overTarget =
                widget.targetSec > 0 && elapsedSec > widget.targetSec;
            return ShadowRecordingCaptionRow(
              elapsedSec: elapsedSec,
              targetSec: widget.targetSec,
              overTarget: overTarget,
              overBySec: overTarget ? elapsedSec - widget.targetSec : 0.0,
              l10n: l10n,
              tt: tt,
              scheme: scheme,
              tok: tok,
            );
          },
        ),
      ],
    );
  }
}

class _LoopBarPainter extends CustomPainter {
  _LoopBarPainter({
    required this.elapsed,
    required this.targetSec,
    required this.track,
    required this.fill,
  }) : super(repaint: elapsed);

  final Animation<double> elapsed;
  final double targetSec;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = track;
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);

    final fraction = targetSec > 0
        ? (elapsed.value / targetSec).clamp(0.0, 1.0)
        : 1.0;
    if (fraction <= 0) return;
    paint.color = fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * fraction, size.height),
        radius,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_LoopBarPainter oldDelegate) => false;
}

void _deferEchoResize(WidgetRef ref, VoidCallback apply) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!ref.context.mounted) return;
    apply();
  });
}
