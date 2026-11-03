library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/latched_retry_state.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_callout.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_retry_button.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// User-facing text for lookup failures (translation, dictionary, contextual).
///
/// The [CreditsFailure] arm routes through the shared credits message builder
/// (spec 045) so a rejected lookup spells out the credit numbers instead of
/// leaking the raw `HTTP 402` internal string. Cross-feature import is the
/// documented presentation seam (specs/045 contracts/client-presentation-api.md).
String lookupErrorUserMessage(Object error, AppLocalizations l10n) {
  return switch (error) {
    AuthFailure() => l10n.lookupCloudRequiresSignIn,
    ProviderBillingFailure() => l10n.byokProviderBillingMessage,
    CreditsFailure() => creditsFailureMessage(error, l10n),
    AppFailure(:final message) => message,
    _ => error.toString(),
  };
}

class LookupErrorRow extends ParentRetryWidget {
  const LookupErrorRow({
    required this.message,
    required super.onRetry,
    super.isRetrying,
    super.key,
  });

  final String message;

  @override
  State<LookupErrorRow> createState() => _LookupErrorRowState();
}

class _LookupErrorRowState extends State<LookupErrorRow>
    with LatchedRetryState<LookupErrorRow> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LookupCallout(
      icon: EnjoyIcons.error,
      iconColor: scheme.error,
      message: widget.message,
      messageColor: scheme.onSurface,
      backgroundColor: scheme.error.withValues(alpha: 0.08),
      borderColor: scheme.error.withValues(alpha: 0.28),
      action: LookupRetryButton(
        busy: retryBusy,
        onPressed: retry,
        variant: LookupRetryButtonVariant.callout,
      ),
    );
  }
}
