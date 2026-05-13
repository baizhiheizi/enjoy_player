/// Single transcript cue row with timestamp, markup, and tap target.
library;

import 'dart:async';

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
    this.selectable = false,
    this.onLookupRequested,
    super.key,
  });

  final TranscriptLine line;
  final String? secondaryText;
  final bool isActive;
  final bool inEcho;

  /// Echo cues rendered inside the echo-region transcript shell: flat rows.
  final bool groupedInEcho;

  /// When true, cue text is selectable and tap-to-seek is disabled (active / echo lines).
  final bool selectable;

  /// Invoked after the user selects 1–100 characters (debounced).
  final ValueChanged<String>? onLookupRequested;

  final VoidCallback onTap;

  @override
  State<TranscriptLineTile> createState() => _TranscriptLineTileState();
}

class _TranscriptLineTileState extends State<TranscriptLineTile> {
  bool _hover = false;
  Timer? _primaryLookupDebounce;
  Timer? _secondaryLookupDebounce;

  @override
  void dispose() {
    _primaryLookupDebounce?.cancel();
    _secondaryLookupDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(TranscriptLineTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.text != widget.line.text ||
        oldWidget.secondaryText != widget.secondaryText) {
      _primaryLookupDebounce?.cancel();
      _secondaryLookupDebounce?.cancel();
    }
  }

  void _scheduleLookup({
    required String plain,
    required TextSelection selection,
    required bool isSecondary,
  }) {
    // Do not filter by [SelectionChangedCause]: double-tap / tap word selection
    // uses [doubleTap] / [tap], not only [drag] / [longPress].
    if (!widget.selectable || widget.onLookupRequested == null) return;

    final debounce = isSecondary
        ? _secondaryLookupDebounce
        : _primaryLookupDebounce;
    debounce?.cancel();

    void run() {
      if (!mounted) return;
      if (!selection.isValid || selection.isCollapsed) return;
      final max = plain.length;
      final start = selection.start.clamp(0, max);
      final end = selection.end.clamp(0, max);
      if (end <= start) return;
      final slice = plain.substring(start, end).trim();
      if (slice.isEmpty || slice.length > 100) return;
      widget.onLookupRequested!(slice);
    }

    final t = Timer(const Duration(milliseconds: 200), run);
    if (isSecondary) {
      _secondaryLookupDebounce = t;
    } else {
      _primaryLookupDebounce = t;
    }
  }

  Widget _richSelectable({
    required TextSpan span,
    required String plainForSelection,
    required bool isSecondary,
  }) {
    return SelectableText.rich(
      span,
      contextMenuBuilder: (context, _) => const SizedBox.shrink(),
      onSelectionChanged: (sel, _) {
        _scheduleLookup(
          plain: plainForSelection,
          selection: sel,
          isSecondary: isSecondary,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);
    final typography = TranscriptTypographyTokens.of(context);
    final baseBody = typography.bodyStyle;
    final defaultFg = scheme.onSurface;

    final echoCurrent = widget.isActive && widget.inEcho;

    Color? bg;
    Color? railColor;
    if (widget.groupedInEcho) {
      if (echoCurrent) {
        bg = tok.echoActive.withValues(alpha: 0.06);
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

    final primaryPlain = transcriptPlainForSelection(widget.line.text);
    final secondaryPlain = widget.secondaryText == null
        ? ''
        : transcriptPlainForSelection(widget.secondaryText!);

    final primaryWidget = widget.selectable
        ? _richSelectable(
            span: transcriptMarkupToTextSpan(
              widget.line.text,
              baseBody,
              defaultColor: defaultFg,
              emphasize: widget.isActive,
            ),
            plainForSelection: primaryPlain,
            isSecondary: false,
          )
        : Text.rich(
            transcriptMarkupToTextSpan(
              widget.line.text,
              baseBody,
              defaultColor: defaultFg,
              emphasize: widget.isActive,
            ),
          );

    Widget? secondaryWidget;
    if (widget.secondaryText != null) {
      secondaryWidget = widget.selectable
          ? _richSelectable(
              span: transcriptMarkupToTextSpan(
                widget.secondaryText!,
                typography.secondaryStyle,
                defaultColor: scheme.onSurfaceVariant,
                emphasize: false,
              ),
              plainForSelection: secondaryPlain,
              isSecondary: true,
            )
          : Text.rich(
              transcriptMarkupToTextSpan(
                widget.secondaryText!,
                typography.secondaryStyle,
                defaultColor: scheme.onSurfaceVariant,
                emphasize: false,
              ),
            );
    }

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
          primaryWidget,
          if (secondaryWidget != null) ...[
            SizedBox(height: tok.space4),
            secondaryWidget,
          ],
        ],
      ),
    );

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

    if (widget.selectable) {
      return Material(color: bg ?? Colors.transparent, child: content);
    }

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
