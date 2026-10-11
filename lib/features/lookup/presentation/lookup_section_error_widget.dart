library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';
import 'package:enjoy_player/features/lookup/presentation/lookup_credits_reporting.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_credits_notice.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_error_row.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Renders the shared error surface for a lookup sheet section
/// (translation, dictionary, contextual translation) and routes the
/// matching credits side-effects.
///
/// Branches:
/// - [AuthFailure] -> [AuthRequiredCallout] (compact), credits cleared.
/// - [CreditsFailure] -> [LookupCreditsNotice] with the shared message,
///   credits reported.
/// - anything else -> [LookupErrorRow] with [lookupErrorUserMessage],
///   credits cleared.
///
/// Centralises the three-branch error handler so the lookup sheet sections
/// cannot drift apart (see the duplicate-code analysis that motivated this
/// helper: each section previously repeated the same ~25-line error block).
Widget lookupSectionErrorWidget({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l10n,
  required LookupSectionId section,
  required AuthRequiredSurface surface,
  required Object error,
  required VoidCallback onRetry,
  bool isRetrying = false,
}) {
  if (error is AuthFailure) {
    scheduleLookupCreditsClear(context, ref, section);
    return AuthRequiredCallout(surface: surface, compact: true);
  }
  if (error is CreditsFailure) {
    final message = creditsFailureMessage(error, l10n);
    scheduleLookupCreditsReport(context, ref, section, message);
    return LookupCreditsNotice(
      message: message,
      onRetry: onRetry,
      isRetrying: isRetrying,
    );
  }
  scheduleLookupCreditsClear(context, ref, section);
  return LookupErrorRow(
    message: lookupErrorUserMessage(error, l10n),
    onRetry: onRetry,
    isRetrying: isRetrying,
  );
}
