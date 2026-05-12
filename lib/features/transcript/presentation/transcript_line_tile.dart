/// Single transcript cue row with timestamp, markup, and tap target.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_markup.dart';

class TranscriptLineTile extends StatefulWidget {
  const TranscriptLineTile({
    required this.line,
    required this.secondaryText,
    required this.isActive,
    required this.inEcho,
    required this.onTap,
    this.groupedInEcho = false,
    super.key,
  });

  final TranscriptLine line;
  final String? secondaryText;
  final bool isActive;
  final bool inEcho;

  /// Echo cues rendered inside the echo-region transcript shell: flat rows.
  final bool groupedInEcho;
  final VoidCallback onTap;

  @override
  State<TranscriptLineTile> createState() => _TranscriptLineTileState();
}

class _TranscriptLineTileState extends State<TranscriptLineTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);
    final typography = TranscriptTypographyTokens.of(context);
    final baseBody = typography.bodyStyle;
    final defaultFg = scheme.onSurface;

    final echoCurrent = widget.isActive && widget.inEcho;

    // Editorial active-line: soft fill + left rail instead of heavy background.
    Color? bg;
    Color? railColor;
    if (widget.groupedInEcho) {
      if (echoCurrent) {
        bg = tok.echoActive.withValues(alpha: 0.06);
        // Parent [EchoRegionMergedCard] already paints an 8px echo rail; do not add
        // a second inner rail or the active row reads as a wider orange stripe.
        railColor = null;
      } else if (widget.inEcho) {
        bg = Colors.transparent;
      }
    } else if (echoCurrent) {
      bg = tok.echoActive.withValues(alpha: 0.06);
      railColor = tok.echoActive;
    } else if (widget.isActive) {
      bg = scheme.primary.withValues(alpha: 0.08);
      railColor = scheme.primary;
    } else if (widget.inEcho) {
      bg = tok.echoActive.withValues(alpha: 0.04);
    } else if (_hover) {
      bg = scheme.onSurface.withValues(alpha: 0.04);
    }

    final timestampStyle = typography.timestampStyle;

    final textBody = Padding(
      padding: tok.transcriptLinePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatTranscriptTimestampMs(widget.line.startMs),
            style: timestampStyle,
          ),
          SizedBox(height: tok.space4),
          Text.rich(
            transcriptMarkupToTextSpan(
              widget.line.text,
              baseBody,
              defaultColor: defaultFg,
              emphasize: widget.isActive,
            ),
          ),
          if (widget.secondaryText != null) ...[
            SizedBox(height: tok.space4),
            Text.rich(
              transcriptMarkupToTextSpan(
                widget.secondaryText!,
                typography.secondaryStyle,
                defaultColor: scheme.onSurfaceVariant,
                emphasize: false,
              ),
            ),
          ],
        ],
      ),
    );

    // Left rail for active lines
    final content = railColor != null
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: tok.motionFast,
                  width: 3,
                  decoration: BoxDecoration(
                    color: railColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Expanded(child: textBody),
              ],
            ),
          )
        : textBody;

    if (widget.groupedInEcho) {
      return Material(
        color: bg ?? Colors.transparent,
        child: InkWell(
          onTap: () {
            Haptics.selection(context);
            widget.onTap();
          },
          highlightColor: scheme.onSurface.withValues(alpha: 0.04),
          splashColor: scheme.primary.withValues(alpha: 0.06),
          child: content,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: bg ?? Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tok.radiusSm),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(tok.radiusSm),
          onTap: () {
            Haptics.selection(context);
            widget.onTap();
          },
          hoverColor: Colors.transparent,
          highlightColor: scheme.primary.withValues(alpha: 0.06),
          splashColor: scheme.primary.withValues(alpha: 0.10),
          child: content,
        ),
      ),
    );
  }
}
