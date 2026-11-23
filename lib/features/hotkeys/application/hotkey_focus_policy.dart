/// When global hotkeys should defer to the focused widget (text fields, etc.).
library;

import 'package:material_ui/material_ui.dart';

import 'package:enjoy_player/features/transcript/presentation/transcript_text_selection_scope.dart';

/// Returns true when [FocusManager.instance.primaryFocus] is on an editable
/// text field that should consume keyboard shortcuts (search, settings, etc.).
///
/// Transcript cue [SelectableText] is read-only selection and must not block
/// player hotkeys after lookup or while shadow reading.
bool primaryFocusBlocksGlobalHotkeys() {
  final focus = FocusManager.instance.primaryFocus;
  final ctx = focus?.context;
  if (ctx == null) return false;
  if (ctx.findAncestorWidgetOfExactType<TranscriptTextSelectionScope>() !=
      null) {
    return false;
  }
  return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// Clears the primary focus so global hotkeys reach [AppHotkeysKeyboardListener].
void releasePrimaryFocusForGlobalHotkeys() {
  FocusManager.instance.primaryFocus?.unfocus();
}
