/// Confirm dialog when leaving Craft (or switching mode) with an unsaved
/// in-memory TTS preview.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Returns `true` when the user confirms discarding the unsaved preview.
Future<bool> confirmDiscardUnsavedCraftPreview(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showEnjoyConfirmDialog(
    context: context,
    title: l10n.craftAudioDiscardTitle,
    message: l10n.craftAudioDiscardMessage,
    confirmLabel: l10n.craftAudioDiscardConfirm,
    destructive: true,
  );
  return confirmed == true;
}
