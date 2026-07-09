/// Typed failures for the Craft flow.
library;

import 'package:enjoy_player/l10n/app_localizations.dart';

/// What the learner can do next when a Craft failure occurs.
enum CraftFailureAction { retry, openAiSettings, switchToSpeakDirectly, signIn }

/// Sealed hierarchy of Craft pipeline failures.
///
/// Each kind maps to a calm, localized message and an actionable next step.
/// Raw exception text MUST NOT reach the user (spec FR-022).
sealed class CraftFailure {
  const CraftFailure(this.action);

  final CraftFailureAction action;

  String message(AppLocalizations l10n);
}

final class CraftTranslateFailure extends CraftFailure {
  const CraftTranslateFailure({this.detail}) : super(CraftFailureAction.retry);
  final String? detail;

  @override
  String message(AppLocalizations l10n) => l10n.craftFailureTranslate;
}

final class CraftTtsFailure extends CraftFailure {
  const CraftTtsFailure({
    this.detail,
    CraftFailureAction action = CraftFailureAction.retry,
  }) : super(action);

  final String? detail;

  @override
  String message(AppLocalizations l10n) => l10n.craftFailureTts;
}

final class CraftSaveFailure extends CraftFailure {
  const CraftSaveFailure({this.detail}) : super(CraftFailureAction.retry);
  final String? detail;

  @override
  String message(AppLocalizations l10n) => l10n.craftFailureSave;
}

final class CraftSignInRequiredFailure extends CraftFailure {
  const CraftSignInRequiredFailure() : super(CraftFailureAction.signIn);

  @override
  String message(AppLocalizations l10n) => l10n.craftSignInRequired;
}

final class CraftOfflineFailure extends CraftFailure {
  const CraftOfflineFailure() : super(CraftFailureAction.retry);

  @override
  String message(AppLocalizations l10n) => l10n.craftOfflineBanner;
}

final class CraftSameLanguageFailure extends CraftFailure {
  const CraftSameLanguageFailure()
    : super(CraftFailureAction.switchToSpeakDirectly);

  @override
  String message(AppLocalizations l10n) => l10n.craftSameLanguageHint;
}

final class CraftVendorUnsupportedLanguageFailure extends CraftFailure {
  const CraftVendorUnsupportedLanguageFailure({required this.language})
    : super(CraftFailureAction.retry);
  final String language;

  @override
  String message(AppLocalizations l10n) => l10n.craftFailureTts;
}
