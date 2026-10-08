/// Credits packages card (the `Credits` board): one-time permanent credits,
/// a brandSoft available chip, and a row of package tiles with Buy buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/credits/application/credits_packages_provider.dart';
import 'package:enjoy_player/features/credits/application/credits_summary_provider.dart';
import 'package:enjoy_player/features/credits/domain/credits_package.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/mobile_purchase_unavailable.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class CreditsPackagesCard extends ConsumerWidget {
  const CreditsPackagesCard({super.key});

  Future<void> _buy(
    BuildContext context,
    WidgetRef ref,
    CreditsPackage pkg,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (await guardMobilePurchase(context)) return;
    if (!context.mounted) return;

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
      final msg = e is CreditsFailure
          ? creditsFailureMessage(e, l10n)
          : e.message.isNotEmpty
          ? e.message
          : l10n.creditsPackagePurchaseFailed;
      AppNotice.error(context, msg);
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
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final packagesAsync = ref.watch(creditsPackagesProvider);
    final summaryAsync = ref.watch(creditsSummaryProvider);
    final busy = ref.watch(creditsPackagePurchaseCtrlProvider).isLoading;

    return EnjoyCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.creditsPackagesTitle,
                      style: tt.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: t.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.creditsPackagesSubtitle,
                      style: tt.bodySmall?.copyWith(
                        fontSize: 13,
                        color: t.ink3,
                      ),
                    ),
                  ],
                ),
                summaryAsync.maybeWhen(
                  data: (s) => Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: t.brandSoft,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      l10n.creditsPermanentAvailable(
                        number.format(s.permanentAvailable),
                      ),
                      style: enjoyMonoStyle(
                        context,
                        size: 13,
                        color: t.brandInk,
                      ),
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            packagesAsync.when(
              data: (packages) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final pkg in packages)
                    SizedBox(
                      width: 220,
                      child: _PackageTile(
                        credits: number.format(pkg.credits),
                        price: '${pkg.amount} USD',
                        busy: busy,
                        onBuy: () => _buy(context, ref, pkg),
                      ),
                    ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.credits,
    required this.price,
    required this.busy,
    required this.onBuy,
  });

  final String credits;
  final String price;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: t.paper,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: t.line),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credits,
                  style: enjoyDisplayStyle(
                    context,
                    size: 26,
                    color: t.ink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: enjoyMonoStyle(context, size: 12.5, color: t.ink3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          EnjoyButton.secondary(
            size: EnjoyButtonSize.small,
            onPressed: busy ? null : onBuy,
            child: Text(l10n.creditsPackageBuy),
          ),
        ],
      ),
    );
  }
}
