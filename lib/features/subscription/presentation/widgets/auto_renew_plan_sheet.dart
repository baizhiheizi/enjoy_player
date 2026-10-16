/// Opens the unified purchase modal that presents two payment paths in one
/// flow: auto-renew via Stripe Checkout (default-selected, recommended) and
/// pay-once, which inlines the prepaid duration and processor controls.
///
/// Only one non-terminal auto-renew subscription is allowed per account, so a
/// second attempt surfaces the server's `SubscriptionConflictFailure` instead
/// of being silently swallowed.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/mobile_purchase_unavailable.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/unified_purchase_sheet_body.dart';

/// Opens the unified purchase modal in auto-renew-default mode.
///
/// Kept for backwards compatibility with callers that don't yet know the
/// selected catalog interval (e.g. legacy upgrade CTAs). New code should call
/// [showUnifiedPurchaseSheet] and pass the tier + interval chosen on the catalog.
Future<void> showAutoRenewPlanSheet(BuildContext context) {
  return showUnifiedPurchaseSheet(
    context,
    tier: SubscriptionTier.pro,
    interval: CatalogInterval.month,
  );
}

/// Opens the unified purchase modal at the chosen catalog tier + interval.
///
/// On compact widths this is a bottom sheet; on wide widths it presents as a
/// centered adaptive dialog so the side-by-side payment cards stay legible.
Future<void> showUnifiedPurchaseSheet(
  BuildContext context, {
  required SubscriptionTier tier,
  required CatalogInterval interval,
}) async {
  if (await guardMobilePurchase(context)) return;
  if (!context.mounted) return;
  await showEnjoyAdaptiveSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) =>
        UnifiedPurchaseSheetBody(initialTier: tier, initialInterval: interval),
  );
}
