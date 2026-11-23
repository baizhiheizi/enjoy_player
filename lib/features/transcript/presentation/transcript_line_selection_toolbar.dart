/// Selection-aware [SelectableText.rich] with custom Look Up / Copy toolbar
/// for desktop mouse-drag selections. Extracted from [TranscriptLineTile].
library;

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_focus_policy.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_text_selection_scope.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TranscriptSelectableRichText extends StatefulWidget {
  const TranscriptSelectableRichText({
    required this.span,
    this.onTap,
    this.onLookupRequested,
    super.key,
  });

  final TextSpan span;
  final VoidCallback? onTap;
  final ValueChanged<String>? onLookupRequested;

  @override
  State<TranscriptSelectableRichText> createState() =>
      _TranscriptSelectableRichTextState();
}

class _TranscriptSelectableRichTextState
    extends State<TranscriptSelectableRichText> {
  Timer? _selectionToolbarTimer;
  EditableTextState? _cachedEditable;
  BuildContext? _cachedEditableContext;

  static const _toolbarDebounce = Duration(milliseconds: 200);

  @override
  void dispose() {
    _selectionToolbarTimer?.cancel();
    _cachedEditable = null;
    _cachedEditableContext = null;
    super.dispose();
  }

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

  EditableTextState? _getEditableTextState(BuildContext context) {
    if (_cachedEditable != null &&
        _cachedEditableContext == context &&
        _cachedEditable!.mounted) {
      return _cachedEditable;
    }
    _cachedEditableContext = context;
    _cachedEditable = _findEditableTextState(context);
    return _cachedEditable;
  }

  void _onSelectionChanged(
    BuildContext selectableSubtreeContext,
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    _selectionToolbarTimer?.cancel();
    _selectionToolbarTimer = null;

    if (cause == SelectionChangedCause.keyboard) return;
    if (!selection.isValid || selection.isCollapsed) return;

    if (cause == SelectionChangedCause.drag) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!selectableSubtreeContext.mounted) return;
        final editable = _getEditableTextState(selectableSubtreeContext);
        if (editable == null || !editable.mounted) return;
        editable.hideToolbar();
      });
    }

    _selectionToolbarTimer = Timer(_toolbarDebounce, () {
      _selectionToolbarTimer = null;
      if (!mounted) return;
      if (!selectableSubtreeContext.mounted) return;
      final editable = _getEditableTextState(selectableSubtreeContext);
      if (editable == null || !editable.mounted) return;
      final sel = editable.textEditingValue.selection;
      if (!sel.isValid || sel.isCollapsed) return;
      editable.showToolbar();
    });
  }

  static String? _rawSelectedSlice(String plain, TextSelection selection) {
    if (!selection.isValid || selection.isCollapsed) return null;
    final max = plain.length;
    final start = selection.start.clamp(0, max);
    final end = selection.end.clamp(0, max);
    if (end <= start) return null;
    return plain.substring(start, end);
  }

  static String? _trimLookupSlice(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.length > 100) return null;
    return trimmed;
  }

  static String? _lookupSlice(String plain, TextSelection selection) =>
      _trimLookupSlice(_rawSelectedSlice(plain, selection));

  List<ContextMenuButtonItem> _toolbarItems({
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

  Widget _toolbarBuilder(
    BuildContext menuContext,
    EditableTextState editableTextState,
  ) {
    final l10n = AppLocalizations.of(menuContext);
    if (l10n == null) {
      return AdaptiveTextSelectionToolbar.editableText(
        editableTextState: editableTextState,
      );
    }
    final items = _toolbarItems(
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

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (selectableSubtreeContext) {
        return TranscriptTextSelectionScope(
          child: SelectableText.rich(
            widget.span,
            onTap: widget.onTap,
            contextMenuBuilder: (menuContext, editableTextState) {
              return _toolbarBuilder(menuContext, editableTextState);
            },
            onSelectionChanged: (selection, cause) {
              _onSelectionChanged(selectableSubtreeContext, selection, cause);
            },
          ),
        );
      },
    );
  }
}

class TranscriptWordSelectionArea extends StatefulWidget {
  const TranscriptWordSelectionArea({
    required this.child,
    this.onTap,
    this.onLookupRequested,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final ValueChanged<String>? onLookupRequested;

  @override
  State<TranscriptWordSelectionArea> createState() =>
      _TranscriptWordSelectionAreaState();
}

class _TranscriptWordSelectionAreaState
    extends State<TranscriptWordSelectionArea> {
  String? _selectedPlainText;

  List<ContextMenuButtonItem> _menuItems({
    required BuildContext menuContext,
    required SelectableRegionState selectableRegionState,
    required AppLocalizations l10n,
  }) {
    final items = <ContextMenuButtonItem>[];
    final lookupText = widget.onLookupRequested == null
        ? null
        : _TranscriptSelectableRichTextState._trimLookupSlice(
            _selectedPlainText,
          );
    if (lookupText != null) {
      items.add(
        ContextMenuButtonItem(
          label: l10n.lookupSheetTitle,
          onPressed: () {
            Haptics.selection(menuContext);
            selectableRegionState.hideToolbar();
            releasePrimaryFocusForGlobalHotkeys();
            widget.onLookupRequested!(lookupText);
          },
        ),
      );
    }
    items.add(
      ContextMenuButtonItem(
        type: ContextMenuButtonType.copy,
        label: l10n.lookupCopy,
        onPressed: () async {
          Haptics.selection(menuContext);
          final raw = _selectedPlainText;
          if (raw != null && raw.isNotEmpty) {
            await Clipboard.setData(ClipboardData(text: raw));
          } else {
            for (final item in selectableRegionState.contextMenuButtonItems) {
              if (item.type == ContextMenuButtonType.copy) {
                item.onPressed?.call();
                break;
              }
            }
          }
          selectableRegionState.hideToolbar();
          if (menuContext.mounted) {
            AppNotice.success(menuContext, l10n.lookupCopySuccess);
          }
        },
      ),
    );
    items.add(
      ContextMenuButtonItem(
        type: ContextMenuButtonType.selectAll,
        onPressed: () {
          Haptics.selection(menuContext);
          selectableRegionState.selectAll(SelectionChangedCause.toolbar);
        },
      ),
    );
    return items;
  }

  Widget _toolbarBuilder(
    BuildContext menuContext,
    SelectableRegionState selectableRegionState,
  ) {
    final l10n = AppLocalizations.of(menuContext);
    if (l10n == null) {
      return AdaptiveTextSelectionToolbar.selectableRegion(
        selectableRegionState: selectableRegionState,
      );
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: selectableRegionState.contextMenuAnchors,
      buttonItems: _menuItems(
        menuContext: menuContext,
        selectableRegionState: selectableRegionState,
        l10n: l10n,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.onTap == null
        ? widget.child
        : GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onTap,
            child: widget.child,
          );
    return TranscriptTextSelectionScope(
      child: SelectionArea(
        onSelectionChanged: (content) {
          _selectedPlainText = content?.plainText;
        },
        contextMenuBuilder: _toolbarBuilder,
        child: child,
      ),
    );
  }
}
