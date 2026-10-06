/// Single transcript cue row with timestamp, markup, and tap target.
library;

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/interaction/mouse_tracker_safe.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/data/subtitle/current_transcript_word.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/settings/application/ipa_overlay_settings.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_cue_reveal_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/features/transcript/application/tap_reveal_hold_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_blur_text.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_selection_toolbar.dart';
import 'package:enjoy_player/core/transcript/transcript_lens_metrics.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_markup.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_word_ipa_layer.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TranscriptLineTile extends ConsumerStatefulWidget {
  const TranscriptLineTile({
    required this.line,
    required this.mediaId,
    required this.secondaryText,
    required this.isActive,
    required this.inEcho,
    required this.onTap,
    this.lineIndex = 0,
    this.groupedInEcho = false,
    this.selectable = false,
    this.recordingCount,
    this.loopFontSize,
    this.lensDistance = 0,
    this.onLookupRequested,
    this.onRetranslateSecondary,
    this.dimWhenInactive = false,
    super.key,
  });

  final TranscriptLine line;
  final String mediaId;
  final String? secondaryText;
  final bool isActive;
  final bool inEcho;

  /// Index of [line] in the primary track (word seek).
  final int lineIndex;

  /// Echo cues rendered inside the echo-region transcript shell: flat rows.
  final bool groupedInEcho;

  /// When true, cue text is selectable and tap-to-seek is disabled (active / echo lines).
  final bool selectable;

  /// Overlapping shadow-reading take count when known; `null` while loading.
  final int? recordingCount;

  /// Literata size for cues inside the Echo loop (the loop grows in place).
  /// Null outside the loop.
  final double? loopFontSize;

  /// 1–3 while the cue sits that many lines outside the echo loop; fades and
  /// shrinks the row through `echoLensOpacity`. 0 outside echo mode.
  final int lensDistance;

  /// Invoked when the user chooses **Look up** in the text selection toolbar
  /// (1–100 characters after trim).
  final ValueChanged<String>? onLookupRequested;

  /// When set (auto-translate active), shows an inline refresh control on the
  /// secondary translation line.
  final VoidCallback? onRetranslateSecondary;

  final VoidCallback onTap;

  /// Lyric-style focus: rest this cue slightly dimmed unless it is active,
  /// in the echo region, or hovered. Set by lists while a cue is playing.
  final bool dimWhenInactive;

  @override
  ConsumerState<TranscriptLineTile> createState() => _TranscriptLineTileState();
}

class _TranscriptLineTileState extends ConsumerState<TranscriptLineTile> {
  final _hover = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  void _handleTap(BuildContext context) {
    Haptics.selection(context);
    if (ref.read(transcriptBlurModeProvider)) {
      ref
          .read(tapRevealHoldCtrlProvider(widget.mediaId).notifier)
          .setHold(
            cueId: cueIdFor(widget.line),
            holdSeconds: kTapRevealHoldSeconds,
          );
    }
    widget.onTap();
  }

  /// Reveal-only tap for selectable (active / echo) cues: starts the
  /// tap-reveal hold without seeking, since selectable cues disable
  /// tap-to-seek. No-op when blur practice is off.
  void _revealHoldOnly() {
    if (!ref.read(transcriptBlurModeProvider)) return;
    ref
        .read(tapRevealHoldCtrlProvider(widget.mediaId).notifier)
        .setHold(
          cueId: cueIdFor(widget.line),
          holdSeconds: kTapRevealHoldSeconds,
        );
  }

  bool _cueRevealed() {
    if (!ref.read(transcriptBlurModeProvider)) return true;
    if (_hover.value) return true;
    return ref.read(
      transcriptCueRevealProvider(widget.mediaId, cueIdFor(widget.line)),
    );
  }

  void _onIpaTap(int wordIndex) {
    if (!_cueRevealed()) return;
    if (wordMediaWindowMs(widget.line, wordIndex) == null) return;
    Haptics.selection(context);
    unawaited(
      ref
          .read(playerInteractionsProvider)
          .seekToWord(widget.line, widget.lineIndex, wordIndex),
    );
  }

  String _snippet(String plain) {
    final t = plain.replaceAll('\n', ' ').trim();
    if (t.length <= 120) return t;
    return '${t.substring(0, 120)}…';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);
    final typography = TranscriptTypographyTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final metrics = TranscriptLensMetrics.of(context);
    final loopActive = widget.groupedInEcho && widget.loopFontSize != null;
    final lensDistance = widget.lensDistance.clamp(0, 3);
    final inLens = lensDistance > 0 && !loopActive;
    final bodyFontSize = loopActive
        ? widget.loopFontSize!
        : inLens
        ? metrics.contextFontSize(lensDistance)
        : metrics.lineFontSize(active: widget.isActive);
    final emphasized = (loopActive || widget.isActive) && !inLens;
    final baseBody = typography.bodyStyle.copyWith(
      height: loopActive
          ? metrics.loopLineHeight
          : inLens
          ? metrics.contextLineHeight
          : metrics.plainLineHeight,
      fontSize: bodyFontSize,
      fontWeight: emphasized ? FontWeight.w500 : FontWeight.w400,
      letterSpacing: loopActive
          ? bodyFontSize * metrics.loopLetterSpacingEm
          : emphasized
          ? bodyFontSize * metrics.listenLetterSpacingEm
          : null,
    );
    final secondaryTypographyStyle = typography.secondaryStyle.copyWith(
      height: loopActive
          ? metrics.loopSecondaryLineHeight
          : metrics.secondaryLineHeight,
      fontSize: loopActive
          ? metrics.loopSecondaryFontSize
          : metrics.secondaryFontSize(active: widget.isActive),
    );
    final defaultFg = scheme.onSurface;

    final echoCurrent = widget.isActive && widget.inEcho;
    final timestampText = formatTranscriptTimestampMs(widget.line.startMs);
    final timestampStyle = typography.timestampStyle.copyWith(
      fontSize: metrics.timeFontSize,
    );

    final primaryPlain = transcriptPlainForSelection(widget.line.text);

    final overlayOn = ref.watch(ipaOverlaySettingsProvider).value == true;
    final words = widget.line.timeline;
    final useAligned =
        overlayOn && transcriptWordsHavePhones(words) && words != null;

    WordTextRange? karaokeRange;
    int? karaokeWordIndex;
    if (widget.isActive) {
      karaokeWordIndex = ref
          .watch(transcriptPlaybackHighlightProvider(widget.mediaId))
          .wordIndex;
      if (!useAligned && karaokeWordIndex != null) {
        karaokeRange = wordHighlightRange(
          primaryPlain,
          widget.line.timeline,
          karaokeWordIndex,
        );
      }
    }
    final karaokeFill = karaokeRange == null ? null : tok.original;

    final blurEnabled = ref.watch(transcriptBlurModeProvider);
    final cueId = cueIdFor(widget.line);
    final providerRevealed = ref.watch(
      transcriptCueRevealProvider(widget.mediaId, cueId),
    );

    String statePrefix = '';
    if (l10n != null) {
      if (echoCurrent) {
        statePrefix = l10n.transcriptAccessibilityEchoCurrentLine;
      } else if (widget.isActive) {
        statePrefix = l10n.transcriptAccessibilityCurrentLine;
      } else if (widget.inEcho) {
        statePrefix = l10n.transcriptAccessibilityEchoRegion;
      }
    }
    final cueLabel = l10n != null
        ? l10n.transcriptAccessibilityCue(timestampText, _snippet(primaryPlain))
        : '$timestampText. ${_snippet(primaryPlain)}';
    var semanticsLabel = statePrefix.isEmpty
        ? cueLabel
        : '$statePrefix $cueLabel';
    final recordingCount = widget.recordingCount;
    if (recordingCount != null && recordingCount > 0 && l10n != null) {
      semanticsLabel =
          '$semanticsLabel. ${l10n.transcriptLineRecordingCount(recordingCount)}';
    }

    Widget? secondaryWidget;
    if (widget.secondaryText != null && !inLens) {
      secondaryWidget = widget.selectable
          ? TranscriptSelectableRichText(
              span: transcriptMarkupToTextSpan(
                widget.secondaryText!,
                secondaryTypographyStyle,
                defaultColor: scheme.onSurfaceVariant,
                emphasize: false,
              ),
              onTap: _revealHoldOnly,
              onLookupRequested: widget.onLookupRequested,
            )
          : Text.rich(
              transcriptMarkupToTextSpan(
                widget.secondaryText!,
                secondaryTypographyStyle,
                defaultColor: scheme.onSurfaceVariant,
                emphasize: false,
              ),
            );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _hover,
      builder: (context, hover, _) {
        Color? bg;
        if (widget.groupedInEcho) {
          bg = Colors.transparent;
        } else if (hover) {
          bg = tok.sunk.withValues(alpha: 0.55);
        }

        final isRevealed = !blurEnabled || hover || providerRevealed;
        final focused =
            !widget.dimWhenInactive ||
            widget.isActive ||
            widget.inEcho ||
            hover;
        final lineFg = inLens
            ? (hover ? defaultFg : tok.ink3)
            : focused
            ? defaultFg
            : tok.ink3;

        Widget primaryWidget;
        if (useAligned && isRevealed) {
          final ipaStyle = transcriptIpaTextStyle(
            baseBody,
            tok.ink3,
            fontSize: loopActive
                ? metrics.loopIpaFontSize
                : metrics.listenIpaFontSize,
          );
          final alignedBody = loopActive
              ? baseBody
              : baseBody.copyWith(height: metrics.alignedLineHeight);
          primaryWidget = TranscriptAlignedWords(
            words: words,
            wordStyle: alignedBody,
            ipaStyle: ipaStyle,
            defaultColor: lineFg,
            emphasize: widget.isActive,
            activeWordIndex: karaokeWordIndex,
            activeUnderlineColor: tok.original,
            onIpaTap: _onIpaTap,
            selectableWordBuilder: widget.selectable
                ? (context, text, style) => TranscriptSelectableRichText(
                    span: TextSpan(text: text, style: style),
                    onTap: _revealHoldOnly,
                    onLookupRequested: widget.onLookupRequested,
                  )
                : null,
          );
        } else {
          final primarySpan = transcriptMarkupToTextSpan(
            widget.line.text,
            baseBody,
            defaultColor: lineFg,
            emphasize: false,
            highlightRange: karaokeRange,
            highlightFill: karaokeFill,
            highlightUnderline: true,
          );
          primaryWidget = widget.selectable
              ? TranscriptSelectableRichText(
                  span: primarySpan,
                  onTap: _revealHoldOnly,
                  onLookupRequested: widget.onLookupRequested,
                )
              : Text.rich(primarySpan);
        }

        final blurredPrimary = TranscriptBlurText(
          revealed: isRevealed,
          shapeWords: transcriptPlainForSelection(widget.line.text),
          shapeFontSize: baseBody.fontSize,
          onShapesTap: widget.selectable ? _revealHoldOnly : null,
          child: primaryWidget,
        );
        final blurredSecondary = secondaryWidget == null
            ? null
            : TranscriptBlurText(
                revealed: isRevealed,
                shapeWords: widget.secondaryText,
                shapeFontSize: secondaryTypographyStyle.fontSize,
                child: secondaryWidget,
              );

        final hasTakes = recordingCount != null && recordingCount > 0;
        final showGutter = !widget.groupedInEcho;
        final practicedDot = Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: tok.you, shape: BoxShape.circle),
        );
        final gutterTop = inLens
            ? metrics.contextGutterTop
            : metrics.gutterTop(active: widget.isActive);
        final textBody = Padding(
          padding: widget.groupedInEcho
              ? EdgeInsets.zero
              : inLens
              ? metrics.contextPadding
              : metrics.linePadding(active: widget.isActive),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showGutter) ...[
                SizedBox(
                  width: metrics.gutterWidth,
                  child: Padding(
                    padding: EdgeInsets.only(top: gutterTop),
                    child: metrics.timeInGutter
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(timestampText, style: timestampStyle),
                              if (hasTakes) ...[
                                SizedBox(height: metrics.practicedDotGap),
                                practicedDot,
                              ],
                            ],
                          )
                        : Align(
                            alignment: Alignment.topLeft,
                            child: hasTakes
                                ? practicedDot
                                : const SizedBox.shrink(),
                          ),
                  ),
                ),
                SizedBox(width: metrics.gutterGap),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showGutter &&
                        !metrics.timeInGutter &&
                        widget.isActive &&
                        !inLens) ...[
                      Text(
                        timestampText,
                        style: timestampStyle.copyWith(color: tok.originalInk),
                      ),
                      SizedBox(height: metrics.timeAboveLineGap),
                    ],
                    blurredPrimary,
                    if (blurredSecondary != null) ...[
                      SizedBox(
                        height: loopActive
                            ? metrics.loopSecondaryTopGap
                            : metrics.secondaryTopGap,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: blurredSecondary),
                          if (widget.onRetranslateSecondary != null) ...[
                            SizedBox(width: tok.space4),
                            EnjoyTappableIcon(
                              icon: EnjoyIcons.refresh,
                              tooltip:
                                  AppLocalizations.of(
                                    context,
                                  )?.subtitlesAutoTranslateRetranslateLine ??
                                  'Re-translate this line',
                              iconSize: 18,
                              color: scheme.onSurfaceVariant,
                              visualDensity: VisualDensity.compact,
                              onPressed: widget.onRetranslateSecondary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );

        final content = textBody;

        final lineRadius = BorderRadius.circular(metrics.lineRadius);
        if (widget.selectable) {
          return _lensFade(
            hover,
            child: Semantics(
              container: true,
              label: semanticsLabel,
              focusable: true,
              child: MouseRegion(
                onEnter: (_) => _setHoverSafe(true),
                onExit: (_) => _setHoverSafe(false),
                child: widget.groupedInEcho
                    ? ColoredBox(
                        color: bg ?? Colors.transparent,
                        child: content,
                      )
                    : DecoratedBox(
                        decoration: ShapeDecoration(
                          color: bg ?? Colors.transparent,
                          shape: RoundedSuperellipseBorder(
                            borderRadius: lineRadius,
                          ),
                        ),
                        child: ClipRSuperellipse(
                          borderRadius: lineRadius,
                          child: content,
                        ),
                      ),
              ),
            ),
          );
        }

        if (widget.groupedInEcho) {
          return _lensFade(
            hover,
            child: Semantics(
              container: true,
              label: semanticsLabel,
              button: true,
              child: EnjoyPressable(
                onTap: () => _handleTap(context),
                borderRadius: lineRadius,
                child: ColoredBox(
                  color: bg ?? Colors.transparent,
                  child: content,
                ),
              ),
            ),
          );
        }

        return _lensFade(
          hover,
          child: Semantics(
            container: true,
            label: semanticsLabel,
            button: true,
            child: MouseRegion(
              onEnter: (_) => _setHoverSafe(true),
              onExit: (_) => _setHoverSafe(false),
              child: EnjoyPressable(
                shape: RoundedSuperellipseBorder(borderRadius: lineRadius),
                onTap: () => _handleTap(context),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: bg ?? Colors.transparent,
                    shape: RoundedSuperellipseBorder(borderRadius: lineRadius),
                  ),
                  child: ClipRSuperellipse(
                    borderRadius: lineRadius,
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _setHoverSafe(bool value) {
    runOutsideMouseTrackerIfMounted(
      () => mounted,
      () => setValueNotifierOutsideMouseTracker(_hover, value),
    );
  }

  Widget _lensFade(bool hover, {required Widget child}) {
    final distance = widget.lensDistance.clamp(0, 3);
    if (distance == 0) return child;
    final tok = EnjoyThemeTokens.of(context);
    return AnimatedOpacity(
      opacity: hover ? 1.0 : tok.echoLensOpacity[distance],
      duration: tok.motionMedium,
      curve: Curves.easeOut,
      child: child,
    );
  }
}
