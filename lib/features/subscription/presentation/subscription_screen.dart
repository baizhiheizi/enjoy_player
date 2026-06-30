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
          return _SubscriptionBody(
            balance: state.profile.balance,
            onRefresh: _refresh,
          );
        },
        loading: () => const SkeletonSettingsList(rowCount: 6),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _SubscriptionBody extends ConsumerWidget {
  const _SubscriptionBody({required this.balance, required this.onRefresh});

  final double? balance;
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
            Text(
              l10n.subscriptionDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: t.space16),
            SubscriptionStatusCard(status: status),
            SizedBox(height: t.space24),
            TierComparison(status: status, accountBalance: balance),
          ],
        ),
        loading: () => ListView(
          padding: EdgeInsets.all(t.space16),
          children: [
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
            Text('$e'),
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
