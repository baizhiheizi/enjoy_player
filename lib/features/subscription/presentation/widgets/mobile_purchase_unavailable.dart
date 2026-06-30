/// Informational dialog when mobile in-app purchase is not yet available.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Future<void> showMobilePurchaseUnavailableDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showEnjoyAlertDialog<void>(
    context: context,
    title: Text(l10n.subscriptionMobilePurchaseTitle),
    content: Text(l10n.subscriptionMobilePurchaseMessage),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).okButtonLabel),
      ),
    ],
  );
}
