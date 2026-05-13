/// Single transcript cue row with timestamp, markup, and tap target.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_markup.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

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

  /// Invoked when the user chooses **Look up** in the text selection toolbar
  /// (1–100 characters after trim).
  final ValueChanged<String>? onLookupRequested;

  final VoidCallback onTap;

  @override
  State<TranscriptLineTile> createState() => _TranscriptLineTileState();
}

class _TranscriptLineTileState extends State<TranscriptLineTile> {
  bool _hover = false;

  /// [SelectableText]'s [EditableText] is internal; locate it to open the
  /// selection toolbar on desktop mouse drag (Flutter otherwise only auto-shows
  /// the toolbar for touch/stylus or double-tap+drag).
  static EditableTextState? _findEditableTextState(BuildContext context) {
    EditableTextState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is EditableTextState) {
        found = element.state as EditableTextState;
        return;
      }
      element.visitChildren(visit);
    }

    final element = context as Element?;
    if (element == null) return null;
    visit(element);
    return found;
  }

  void _onSelectableSelectionChanged(
    BuildContext selectableSubtreeContext,
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    if (!widget.selectable) return;
    // Match [SelectableText] handle visibility: keyboard-driven selection does
    // not surface the floating toolbar by default.
    if (cause == SelectionChangedCause.keyboard) return;
    if (!selection.isValid || selection.isCollapsed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!selectableSubtreeContext.mounted) return;
      final editable = _findEditableTextState(selectableSubtreeContext);
      if (editable == null || !editable.mounted) return;
      final sel = editable.textEditingValue.selection;
      if (!sel.isValid || sel.isCollapsed) return;
      editable.showToolbar();
    });
  }

  /// Raw substring for the current [selection] (no trim), or `null` if invalid.
  static String? _rawSelectedSlice(String plain, TextSelection selection) {
    if (!selection.isValid || selection.isCollapsed) return null;
    final max = plain.length;
    final start = selection.start.clamp(0, max);
    final end = selection.end.clamp(0, max);
    if (end <= start) return null;
    return plain.substring(start, end);
  }

  /// Trimmed slice suitable for lookup, max 100 characters, or `null`.
  static String? _lookupSlice(String plain, TextSelection selection) {
    final raw = _rawSelectedSlice(plain, selection);
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.length > 100) return null;
    return trimmed;
  }

  List<ContextMenuButtonItem> _selectionToolbarItems({
    required BuildContext menuContext,
    required EditableTextState editableTextState,
    required AppLocalizations l10n,
  }) {
    final value = editableTextState.textEditingValue;
    final plain = value.text;
    final selection = value.selection;
    final items = <ContextMenuButtonItem>[];

    final lookupText = widget.onLookupRequested == null
        ? null
        : _lookupSlice(plain, selection);
    if (lookupText != null) {
      items.add(
        ContextMenuButtonItem(
          label: l10n.lookupSheetTitle,
          onPressed: () {
            Haptics.selection(menuContext);
            editableTextState.hideToolbar();
            widget.onLookupRequested!(lookupText);
          },
        ),
      );
    }

    if (editableTextState.copyEnabled) {
      items.add(
        ContextMenuButtonItem(
          type: ContextMenuButtonType.copy,
          label: l10n.lookupCopy,
          onPressed: () async {
            Haptics.selection(menuContext);
            final raw = _rawSelectedSlice(plain, editableTextState.textEditingValue.selection);
            if (raw != null && raw.isNotEmpty) {
              await Clipboard.setData(ClipboardData(text: raw));
            } else {
              editableTextState.copySelection(SelectionChangedCause.toolbar);
            }
            editableTextState.hideToolbar();
            if (menuContext.mounted) {
              AppNotice.success(menuContext, l10n.lookupCopySuccess);
            }
          },
        ),
      );
    }

    if (editableTextState.selectAllEnabled) {
      items.add(
        ContextMenuButtonItem(
          type: ContextMenuButtonType.selectAll,
          onPressed: () {
            Haptics.selection(menuContext);
            editableTextState.selectAll(SelectionChangedCause.toolbar);
          },
        ),
      );
    }

    return items;
  }

  Widget _selectionToolbar(
    BuildContext menuContext,
    EditableTextState editableTextState,
  ) {
    final l10n = AppLocalizations.of(menuContext);
    if (l10n == null) {
      return AdaptiveTextSelectionToolbar.editableText(
        editableTextState: editableTextState,
      );
    }
    final items = _selectionToolbarItems(
      menuContext: menuContext,
      editableTextState: editableTextState,
      l10n: l10n,
    );
    if (items.isEmpty) {
      return AdaptiveTextSelectionToolbar.editableText(
        editableTextState: editableTextState,
      );
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: items,
    );
  }

  Widget _richSelectable({required TextSpan span}) {
    return Builder(
      builder: (selectableSubtreeContext) {
        return SelectableText.rich(
          span,
          contextMenuBuilder: (menuContext, editableTextState) {
            return _selectionToolbar(menuContext, editableTextState);
          },
          onSelectionChanged: (selection, cause) {
            _onSelectableSelectionChanged(
              selectableSubtreeContext,
              selection,
              cause,
            );
          },
        );
      },
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
        ? l10n.transcriptAccessibilityCue(
            formatTranscriptTimestampMs(widget.line.startMs),
            _snippet(primaryPlain),
          )
        : '${formatTranscriptTimestampMs(widget.line.startMs)}. ${_snippet(primaryPlain)}';
    final semanticsLabel = statePrefix.isEmpty
        ? cueLabel
        : '$statePrefix $cueLabel';

    final primaryWidget = widget.selectable
        ? _richSelectable(
            span: transcriptMarkupToTextSpan(
              widget.line.text,
              baseBody,
              defaultColor: defaultFg,
              emphasize: widget.isActive,
            ),
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
      return Semantics(
        container: true,
        label: semanticsLabel,
        focusable: true,
        child: Material(color: bg ?? Colors.transparent, child: content),
      );
    }

    if (widget.groupedInEcho) {
      return Semantics(
        container: true,
        label: semanticsLabel,
        button: true,
        child: Material(
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
        ),
      );
    }

    return Semantics(
      container: true,
      label: semanticsLabel,
      button: true,
      child: MouseRegion(
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
      ),
    );
  }
}
