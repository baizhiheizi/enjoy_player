/// Single transcript cue row with timestamp, markup, and tap target.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_focus_policy.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_preferences_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_cue_reveal_provider.dart';
import 'package:enjoy_player/features/transcript/application/tap_reveal_hold_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_blur_text.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_recording_badge.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_markup.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_text_selection_scope.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TranscriptLineTile extends ConsumerStatefulWidget {
  const TranscriptLineTile({
    required this.line,
    required this.mediaId,
    required this.secondaryText,
    required this.isActive,
    required this.inEcho,
    required this.onTap,
    this.groupedInEcho = false,
    this.selectable = false,
    this.recordingCount,
    this.onLookupRequested,
    super.key,
  });

  final TranscriptLine line;
  final String mediaId;
  final String? secondaryText;
  final bool isActive;
  final bool inEcho;

  /// Echo cues rendered inside the echo-region transcript shell: flat rows.
  final bool groupedInEcho;

  /// When true, cue text is selectable and tap-to-seek is disabled (active / echo lines).
  final bool selectable;

  /// Overlapping shadow-reading take count when known; `null` while loading.
  final int? recordingCount;

  /// Invoked when the user chooses **Look up** in the text selection toolbar
  /// (1–100 characters after trim).
  final ValueChanged<String>? onLookupRequested;

  final VoidCallback onTap;

  @override
  ConsumerState<TranscriptLineTile> createState() => _TranscriptLineTileState();
}

class _TranscriptLineTileState extends ConsumerState<TranscriptLineTile> {
  bool _hover = false;
  Timer? _selectionToolbarTimer;

  static const _toolbarDebounce = Duration(milliseconds: 200);

  @override
  void dispose() {
    _selectionToolbarTimer?.cancel();
    super.dispose();
  }

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

  void _handleTap(BuildContext context) {
    Haptics.selection(context);
    final prefs = ref.read(transcriptBlurPreferencesCtrlProvider).valueOrNull;
    if (prefs?.enabled == true) {
      ref
          .read(tapRevealHoldCtrlProvider(widget.mediaId).notifier)
          .setHold(
            cueId: cueIdFor(widget.line),
            holdSeconds: prefs!.tapRevealSeconds,
          );
    }
    widget.onTap();
  }

  /// Reveal-only tap for selectable (active / echo) cues: starts the
  /// tap-reveal hold without seeking, since selectable cues disable
  /// tap-to-seek. No-op when blur practice is off.
  void _revealHoldOnly() {
    final prefs = ref.read(transcriptBlurPreferencesCtrlProvider).valueOrNull;
    if (prefs?.enabled != true) return;
    ref
        .read(tapRevealHoldCtrlProvider(widget.mediaId).notifier)
        .setHold(
          cueId: cueIdFor(widget.line),
          holdSeconds: prefs!.tapRevealSeconds,
        );
  }

  void _onSelectableSelectionChanged(
    BuildContext selectableSubtreeContext,
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    _selectionToolbarTimer?.cancel();
    _selectionToolbarTimer = null;

    if (!widget.selectable) return;
    // Match [SelectableText] handle visibility: keyboard-driven selection does
    // not surface the floating toolbar by default.
    if (cause == SelectionChangedCause.keyboard) return;
    if (!selection.isValid || selection.isCollapsed) return;

    if (cause == SelectionChangedCause.drag) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!selectableSubtreeContext.mounted) return;
        final editable = _findEditableTextState(selectableSubtreeContext);
        if (editable == null || !editable.mounted) return;
        editable.hideToolbar();
      });
    }

    _selectionToolbarTimer = Timer(_toolbarDebounce, () {
      _selectionToolbarTimer = null;
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
            releasePrimaryFocusForGlobalHotkeys();
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
            final raw = _rawSelectedSlice(
              plain,
              editableTextState.textEditingValue.selection,
            );
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

  Widget _richSelectable({required TextSpan span, VoidCallback? onTap}) {
    return Builder(
      builder: (selectableSubtreeContext) {
        return TranscriptTextSelectionScope(
          child: SelectableText.rich(
            span,
            onTap: onTap,
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
          ),
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

    final prefs = ref.watch(transcriptBlurPreferencesCtrlProvider).valueOrNull;
    final blurEnabled = prefs?.enabled ?? false;
    final cueId = cueIdFor(widget.line);
    final providerRevealed = ref.watch(
      transcriptCueRevealProvider(widget.mediaId, cueId),
    );
    // The active playback cue has no privileged state — `providerRevealed`
    // may be `true` only because the user explicitly hovered or tapped.
    final isRevealed = !blurEnabled || _hover || providerRevealed;

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
    var semanticsLabel = statePrefix.isEmpty
        ? cueLabel
        : '$statePrefix $cueLabel';
    final recordingCount = widget.recordingCount;
    if (recordingCount != null && recordingCount > 0 && l10n != null) {
      semanticsLabel =
          '$semanticsLabel. ${l10n.transcriptLineRecordingCount(recordingCount)}';
    }

    final primaryWidget = widget.selectable
        ? _richSelectable(
            span: transcriptMarkupToTextSpan(
              widget.line.text,
              baseBody,
              defaultColor: defaultFg,
              emphasize: widget.isActive,
            ),
            onTap: _revealHoldOnly,
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
              onTap: _revealHoldOnly,
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

    final blurredPrimary = TranscriptBlurText(
      revealed: isRevealed,
      child: primaryWidget,
    );
    final blurredSecondary = secondaryWidget == null
        ? null
        : TranscriptBlurText(revealed: isRevealed, child: secondaryWidget);

    final textBody = Padding(
      padding: tok.transcriptLinePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatTranscriptTimestampMs(widget.line.startMs),
                style: timestampStyle,
              ),
              const Spacer(),
              TranscriptLineRecordingBadge(count: widget.recordingCount),
            ],
          ),
          SizedBox(height: tok.space4),
          blurredPrimary,
          if (blurredSecondary != null) ...[
            SizedBox(height: tok.space8),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.22),
                    width: 2,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(left: tok.space12),
                child: blurredSecondary,
              ),
            ),
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
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Material(color: bg ?? Colors.transparent, child: content),
        ),
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
            onTap: () => _handleTap(context),
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
            onTap: () => _handleTap(context),
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
