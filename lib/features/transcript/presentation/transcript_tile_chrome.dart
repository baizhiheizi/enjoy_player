/// Interactive shell, gutter layout, and surface framing for a transcript tile.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/transcript/transcript_lens_metrics.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TranscriptTileChrome extends StatelessWidget {
  const TranscriptTileChrome({
    required this.child,
    required this.timestampText,
    required this.timestampStyle,
    required this.primaryPlain,
    required this.isActive,
    required this.inEcho,
    required this.groupedInEcho,
    required this.inLens,
    required this.lensDistance,
    required this.selectable,
    required this.hover,
    required this.recordingCount,
    required this.onTap,
    this.onLongPress,
    required this.onHoverChanged,
    super.key,
  });

  final Widget child;
  final String timestampText;
  final TextStyle timestampStyle;
  final String primaryPlain;
  final bool isActive;
  final bool inEcho;
  final bool groupedInEcho;
  final bool inLens;
  final int lensDistance;
  final bool selectable;
  final bool hover;
  final int? recordingCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool> onHoverChanged;

  String _snippet(String plain) {
    final t = plain.replaceAll('\n', ' ').trim();
    if (t.length <= 120) return t;
    return '${t.substring(0, 120)}…';
  }

  @override
  Widget build(BuildContext context) {
    final tok = EnjoyThemeTokens.of(context);
    final metrics = TranscriptLensMetrics.of(context);
    final l10n = AppLocalizations.of(context);

    final echoCurrent = isActive && inEcho;
    String statePrefix = '';
    if (l10n != null) {
      if (echoCurrent) {
        statePrefix = l10n.transcriptAccessibilityEchoCurrentLine;
      } else if (isActive) {
        statePrefix = l10n.transcriptAccessibilityCurrentLine;
      } else if (inEcho) {
        statePrefix = l10n.transcriptAccessibilityEchoRegion;
      }
    }
    final cueLabel = l10n != null
        ? l10n.transcriptAccessibilityCue(timestampText, _snippet(primaryPlain))
        : '$timestampText. ${_snippet(primaryPlain)}';
    var semanticsLabel = statePrefix.isEmpty
        ? cueLabel
        : '$statePrefix $cueLabel';
    final count = recordingCount;
    if (count != null && count > 0 && l10n != null) {
      semanticsLabel =
          '$semanticsLabel. ${l10n.transcriptLineRecordingCount(count)}';
    }

    Color? bg;
    List<BoxShadow>? cardShadow;
    if (groupedInEcho || inLens) {
      bg = Colors.transparent;
    } else if (isActive) {
      bg = tok.paper;
      cardShadow = tok.shadowLift;
    } else if (hover) {
      bg = tok.sunk.withValues(alpha: 0.55);
    }

    final hasTakes = count != null && count > 0;
    final showGutter = !groupedInEcho;
    final practicedDot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: tok.you, shape: BoxShape.circle),
    );
    final gutterTop = inLens
        ? metrics.contextGutterTop
        : metrics.gutterTop(active: isActive);
    final timeInGutter = showGutter && metrics.timeInGutter;
    final content = Padding(
      padding: groupedInEcho
          ? EdgeInsets.zero
          : inLens
          ? metrics.contextPadding
          : metrics.linePadding(active: isActive),
      child: Row(
        crossAxisAlignment: timeInGutter
            ? CrossAxisAlignment.baseline
            : CrossAxisAlignment.start,
        textBaseline: TextBaseline.alphabetic,
        children: [
          if (timeInGutter) ...[
            SizedBox(
              width: metrics.gutterWidth,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: AlignmentDirectional.topEnd,
                children: [
                  Text(timestampText, style: timestampStyle, maxLines: 1),
                  if (hasTakes)
                    PositionedDirectional(
                      top: metrics.timeFontSize + metrics.practicedDotGap,
                      end: 0,
                      child: practicedDot,
                    ),
                ],
              ),
            ),
            SizedBox(width: metrics.gutterGap),
          ] else if (showGutter) ...[
            SizedBox(
              width: metrics.gutterWidth,
              child: Padding(
                padding: EdgeInsets.only(top: gutterTop),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: hasTakes ? practicedDot : const SizedBox.shrink(),
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
                    isActive &&
                    !inLens) ...[
                  Text(
                    timestampText,
                    style: timestampStyle.copyWith(color: tok.originalInk),
                  ),
                  SizedBox(height: metrics.timeAboveLineGap),
                ],
                child,
              ],
            ),
          ),
        ],
      ),
    );

    final lineRadius = BorderRadius.circular(metrics.lineRadius);
    Widget decorate(Widget contentChild) => DecoratedBox(
      decoration: ShapeDecoration(
        color: bg ?? Colors.transparent,
        shadows: cardShadow,
        shape: RoundedSuperellipseBorder(borderRadius: lineRadius),
      ),
      child: ClipRSuperellipse(borderRadius: lineRadius, child: contentChild),
    );

    if (selectable) {
      return _lensFade(
        context,
        child: Semantics(
          container: true,
          label: semanticsLabel,
          focusable: true,
          child: MouseRegion(
            onEnter: (_) => onHoverChanged(true),
            onExit: (_) => onHoverChanged(false),
            child: groupedInEcho
                ? ColoredBox(color: bg ?? Colors.transparent, child: content)
                : decorate(content),
          ),
        ),
      );
    }

    if (groupedInEcho) {
      return _lensFade(
        context,
        child: Semantics(
          container: true,
          label: semanticsLabel,
          button: true,
          child: EnjoyPressable(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: lineRadius,
            child: ColoredBox(color: bg ?? Colors.transparent, child: content),
          ),
        ),
      );
    }

    return _lensFade(
      context,
      child: Semantics(
        container: true,
        label: semanticsLabel,
        button: true,
        child: MouseRegion(
          onEnter: (_) => onHoverChanged(true),
          onExit: (_) => onHoverChanged(false),
          child: EnjoyPressable(
            shape: RoundedSuperellipseBorder(borderRadius: lineRadius),
            onTap: onTap,
            onLongPress: onLongPress,
            child: decorate(content),
          ),
        ),
      ),
    );
  }

  Widget _lensFade(BuildContext context, {required Widget child}) {
    final distance = lensDistance.clamp(0, 3);
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
