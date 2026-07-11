/// Subscription management: status, plan comparison, and platform-scoped purchase.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/centered_max_width_scroll.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/subscription_status_card.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_comparison.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(subscriptionStatusProvider);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(subscriptionStatusProvider);
    await ref.read(subscriptionStatusProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authCtrlProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscriptionTitle)),
      body: auth.when(
        data: (state) {
          if (state is! AuthSignedIn) {
            return const Center(
              child: AuthRequiredCallout(
                surface: AuthRequiredSurface.subscription,
                compact: false,
              ),
            );
          }
          return _SubscriptionBody(onRefresh: _refresh);
        },
        loading: () => const SkeletonSettingsList(rowCount: 6),
        error: (e, _) => Center(child: Text(l10n.errorGenericLoadFailed)),
      ),
    );
  }
}

class _SubscriptionBody extends ConsumerWidget {
  const _SubscriptionBody({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final statusAsync = ref.watch(subscriptionStatusProvider);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: statusAsync.when(
        data: (status) => CenteredMaxWidthListView(
          maxWidth: t.contentMaxWidth + 96,
          padding: EdgeInsets.all(t.space16),
          children: [
            _SubscriptionHeroHeader(
              isPro: status.subscriptionTier == SubscriptionTier.pro,
            ),
            SizedBox(height: t.space20),
            SubscriptionStatusCard(status: status),
            SizedBox(height: t.space24),
            TierComparison(status: status),
          ],
        ),
        loading: () => ListView(
          padding: EdgeInsets.all(t.space16),
          children: [
            Skeleton.line(width: double.infinity, height: 120),
            SizedBox(height: t.space16),
            Skeleton.line(width: double.infinity, height: 160),
            SizedBox(height: t.space16),
            Skeleton.line(width: double.infinity, height: 280),
          ],
        ),
        error: (e, _) => ListView(
          padding: EdgeInsets.all(t.space16),
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

class _SubscriptionHeroHeader extends StatelessWidget {
  const _SubscriptionHeroHeader({required this.isPro});

  final bool isPro;

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
            colors: isPro
                ? [
                    cs.primary.withValues(alpha: 0.28),
                    cs.tertiary.withValues(alpha: 0.22),
                  ]
                : [
                    t.gradientStart.withValues(alpha: 0.55),
                    t.gradientEnd.withValues(alpha: 0.45),
                  ],
          ),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: EdgeInsets.all(t.space20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(t.radiusMd),
                ),
                child: Padding(
                  padding: EdgeInsets.all(t.space12),
                  child: Icon(
                    isPro
                        ? Icons.verified_rounded
                        : Icons.workspace_premium_rounded,
                    color: isPro ? cs.primary : cs.onSurface,
                    size: 28,
                  ),
                ),
              ),
              SizedBox(width: t.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.subscriptionTitle,
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: t.space4),
                    Text(
                      l10n.subscriptionDescription,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.82),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
