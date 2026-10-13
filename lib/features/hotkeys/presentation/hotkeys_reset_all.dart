/// Confirmation before clearing all custom hotkey bindings.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Returns true when the user confirms resetting every custom binding.
Future<bool> confirmHotkeysResetAll(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showEnjoyConfirmDialog(
    context: context,
    title: l10n.hotkeysResetAllConfirmTitle,
    message: l10n.hotkeysResetAllConfirmMessage,
    confirmLabel: l10n.hotkeysResetAll,
    destructive: true,
  );
  return confirmed == true;
}
