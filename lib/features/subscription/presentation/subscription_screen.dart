/// Subscription management: membership, plans, and credits packages.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/credits/application/credits_packages_provider.dart';
import 'package:enjoy_player/features/credits/application/credits_summary_provider.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/auto_renew_plan_sheet.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/credits_packages_section.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/mobile_purchase_unavailable.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/subscription_status_card.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_comparison.dart';
import 'package:enjoy_player/core/platform/subscription_purchase_capability.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  Future<void> _refresh() async {
    ref.invalidate(subscriptionStatusProvider);
    ref.invalidate(creditsPackagesProvider);
    ref.invalidate(creditsSummaryProvider);
    await ref.read(subscriptionStatusProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authCtrlProvider);

    return EnjoyPage(
      kind: EnjoyPageKind.hub,
      title: l10n.subscriptionTitle,
      showBack: true,
      body: (context, metrics) => auth.when(
        data: (state) {
          if (state is! AuthSignedIn) {
            return const Center(
              child: AuthRequiredCallout(
                surface: AuthRequiredSurface.subscription,
                compact: false,
              ),
            );
          }
          return _SubscriptionBody(onRefresh: _refresh, metrics: metrics);
        },
        loading: () => const SkeletonSettingsList(rowCount: 6),
        error: (e, _) => Center(child: Text(l10n.errorGenericLoadFailed)),
      ),
    );
  }
}

class _SubscriptionBody extends ConsumerWidget {
  const _SubscriptionBody({required this.onRefresh, required this.metrics});

  final Future<void> Function() onRefresh;
  final EnjoyPageMetrics metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final statusAsync = ref.watch(subscriptionStatusProvider);
    final pad = metrics.padding(top: t.space16, bottom: t.space32);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: statusAsync.when(
        data: (status) {
          final isPro = status.isPro;
          return ListView(
            padding: pad,
            children: [
              if (!isPro) ...[
                const _FreeUpgradeHero(),
                SizedBox(height: t.space20),
              ],
              SubscriptionStatusCard(status: status),
              SizedBox(height: t.space24),
              TierComparison(status: status),
              SizedBox(height: t.space32),
              const CreditsPackagesSection(),
            ],
          );
        },
        loading: () => ListView(
          padding: pad,
          children: [
            Skeleton.line(width: double.infinity, height: 120),
            SizedBox(height: t.space16),
            Skeleton.line(width: double.infinity, height: 160),
            SizedBox(height: t.space16),
            Skeleton.line(width: double.infinity, height: 280),
          ],
        ),
        error: (e, _) => ListView(
          padding: pad,
          children: [
            Text(l10n.subscriptionErrorLoading),
            SizedBox(height: t.space8),
            Text(l10n.errorGenericLoadFailed),
            SizedBox(height: t.space16),
            EnjoyButton.primary(
              onPressed: () => ref.invalidate(subscriptionStatusProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact upgrade pitch for free users (membership card covers Pro).
class _FreeUpgradeHero extends StatelessWidget {
  const _FreeUpgradeHero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(t.radiusXl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              t.gradientStart.withValues(alpha: 0.55),
              t.gradientEnd.withValues(alpha: 0.45),
            ],
          ),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: EdgeInsets.all(t.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(t.radiusMd),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(t.space12),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: cs.onSurface,
                        size: 26,
                      ),
                    ),
                  ),
                  SizedBox(width: t.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.subscriptionUpgrade,
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: t.space4),
                        Text(
                          l10n.subscriptionTierProDescription,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.82),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: t.space16),
              EnjoyButton.primary(
                onPressed: () => _openUpgrade(context),
                child: Text(l10n.subscriptionUpgrade),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUpgrade(BuildContext context) async {
    if (showsMobilePurchaseUnavailable()) {
      await showMobilePurchaseUnavailableDialog(context);
      return;
    }
    if (!supportsExternalSubscriptionPurchase()) return;
    if (!context.mounted) return;
    await showAutoRenewPlanSheet(context);
  }
}
