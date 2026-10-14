/// Localized plan name for a [SubscriptionTier].
library;

import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

String subscriptionTierLabel(AppLocalizations l10n, SubscriptionTier? tier) =>
    switch (tier) {
      SubscriptionTier.pro => l10n.profileSubscriptionPro,
      SubscriptionTier.lite => l10n.subscriptionTierLiteName,
      SubscriptionTier.free || null => l10n.profileSubscriptionFree,
    };
