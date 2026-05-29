/// Optional and mandatory update dialogs.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/features/update/domain/update_types.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Future<void> showUpdatePromptDialog({
  required BuildContext context,
  required AppRelease release,
  required VoidCallback onUpdate,
  required VoidCallback onLater,
  VoidCallback? onDismiss,
}) {
  final l10n = AppLocalizations.of(context)!;
  final mandatory = release.severity == UpdateSeverity.mandatory;
  final notes = release.manifest.notes.trim();

  return showDialog<void>(
    context: context,
    barrierDismissible: !mandatory,
    builder: (ctx) {
      return PopScope(
        canPop: !mandatory,
        child: AlertDialog(
          title: Text(
            mandatory ? l10n.updateMandatoryTitle : l10n.updateAvailableTitle,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.updateVersionLine(
                    release.currentVersion,
                    release.manifest.version,
                  ),
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(notes),
                ],
              ],
            ),
          ),
          actions: [
            if (!mandatory && onDismiss != null)
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onDismiss();
                },
                child: Text(l10n.updateDismiss),
              ),
            if (!mandatory)
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onLater();
                },
                child: Text(l10n.updateLater),
              ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onUpdate();
              },
              child: Text(l10n.updateNow),
            ),
          ],
        ),
      );
    },
  );
}
