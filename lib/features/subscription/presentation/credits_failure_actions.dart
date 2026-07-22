/// Surfaces [CreditsFailure] with navigation to subscription management.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

void showCreditsFailureWithUpgradeAction(
  BuildContext context,
  CreditsFailure failure,
) {
  final l10n = AppLocalizations.of(context)!;
  AppNotice.error(
    context,
    failure.message.isNotEmpty
        ? failure.message
        : l10n.subscriptionCreditsLimitMessageWithPackages,
    action: SnackBarAction(
      label: l10n.subscriptionViewPlansAndPackages,
      onPressed: () => context.push('/subscription'),
    ),
  );
}
