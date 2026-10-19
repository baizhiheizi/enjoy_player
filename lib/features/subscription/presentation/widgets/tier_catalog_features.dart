/// Localized feature-list builders shared by the Free / Lite / Pro catalog
/// cards.
library;

import 'package:enjoy_player/l10n/app_localizations.dart';

/// Features available on every tier, including Free.
List<String> sharedAiFeatures(AppLocalizations l10n) => [
  l10n.subscriptionFeatureTranslation,
  l10n.subscriptionFeatureSmartTranslation,
  l10n.subscriptionFeatureDictionary,
  l10n.subscriptionFeatureAsr,
  l10n.subscriptionFeatureTts,
  l10n.subscriptionFeatureAssessment,
];

/// Features reserved for the paid tiers (Lite and Pro).
List<String> paidTierFeatures(AppLocalizations l10n) => [
  ...sharedAiFeatures(l10n),
  l10n.subscriptionFeaturePaidFlashcards,
  l10n.subscriptionFeaturePaidMoreComing,
];
