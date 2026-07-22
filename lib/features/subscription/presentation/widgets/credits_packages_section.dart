/// One-time credits packages offer on the subscription hub.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/platform/subscription_purchase_capability.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/credits/application/credits_packages_provider.dart';
import 'package:enjoy_player/features/credits/application/credits_summary_provider.dart';
import 'package:enjoy_player/features/credits/domain/credits_package.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/mobile_purchase_unavailable.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class CreditsPackagesSection extends ConsumerWidget {
  const CreditsPackagesSection({super.key});

  Future<void> _buy(
    BuildContext context,
    WidgetRef ref,
    CreditsPackage pkg,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (showsMobilePurchaseUnavailable()) {
      await showMobilePurchaseUnavailableDialog(context);
      return;
    }
    if (!supportsExternalSubscriptionPurchase()) return;

    final creditsLabel = NumberFormat.decimalPattern().format(pkg.credits);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.creditsPackageConfirmTitle),
        content: Text(
          l10n.creditsPackageConfirmMessage(pkg.amount, creditsLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.creditsPackageConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(creditsPackagePurchaseCtrlProvider.notifier)
          .purchaseExternal(packageId: pkg.id, expectedCredits: pkg.credits);
      if (!context.mounted) return;
      AppNotice.info(context, l10n.subscriptionRedirectingToPayment);
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      AppNotice.error(
        context,
        e.message.isNotEmpty ? e.message : l10n.creditsPackagePurchaseFailed,
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = switch (e.toString()) {
        final s
            when s.contains('missing_pay_url') ||
                s.contains('invalid_pay_url') =>
          l10n.subscriptionPaymentUrlMissing,
        final s when s.contains('launch_failed') =>
          l10n.subscriptionPaymentLaunchFailed,
        _ => l10n.creditsPackagePurchaseFailed,
      };
      AppNotice.error(context, msg);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final packagesAsync = ref.watch(creditsPackagesProvider);
    final summaryAsync = ref.watch(creditsSummaryProvider);
    final busy = ref.watch(creditsPackagePurchaseCtrlProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.creditsPackagesTitle,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: t.space4),
        Text(
          l10n.creditsPackagesSubtitle,
          style: tt.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        summaryAsync.when(
          data: (s) => Padding(
            padding: EdgeInsets.only(top: t.space8),
            child: Text(
              l10n.creditsPermanentAvailable(
                NumberFormat.decimalPattern().format(s.permanentAvailable),
              ),
              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        SizedBox(height: t.space12),
        packagesAsync.when(
          data: (packages) {
            if (packages.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                for (final pkg in packages) ...[
                  EnjoyCard(
                    padding: EdgeInsets.all(t.space16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.creditsPackagePriceCredits(
                              pkg.amount,
                              NumberFormat.decimalPattern().format(pkg.credits),
                            ),
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        EnjoyButton.secondary(
                          onPressed: busy
                              ? null
                              : () => _buy(context, ref, pkg),
                          child: Text(l10n.creditsPackageBuy),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: t.space8),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
