/// Confirmation before clearing all custom hotkey bindings.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Returns true when the user confirms resetting every custom binding.
Future<bool> confirmHotkeysResetAll(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showEnjoyAlertDialog<bool>(
    context: context,
    title: Text(l10n.hotkeysResetAllConfirmTitle),
    content: Text(l10n.hotkeysResetAllConfirmMessage),
    actionsBuilder: (ctx) => [
      TextButton(
        onPressed: () => Navigator.pop(ctx, false),
        child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
      ),
      TextButton(
        onPressed: () => Navigator.pop(ctx, true),
        child: Text(l10n.hotkeysResetAll),
      ),
    ],
  );
  return confirmed == true;
}
