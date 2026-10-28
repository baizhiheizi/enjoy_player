/// Read-only credits consumption audit (Worker `GET /credits/usages`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/signed_in_gate.dart';
import 'package:enjoy_player/features/credits/application/credits_usage_provider.dart';
import 'package:enjoy_player/features/credits/domain/credits_usage_page.dart';
import 'package:enjoy_player/features/credits/presentation/credits_packages_card.dart';
import 'package:enjoy_player/features/credits/presentation/credits_usage_filters.dart';
import 'package:enjoy_player/features/credits/presentation/credits_usage_log_views.dart';
import 'package:enjoy_player/features/credits/presentation/credits_usage_states.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

export 'package:enjoy_player/features/credits/presentation/credits_usage_filters.dart'
    show
        FiltersGroup,
        hasActiveCreditsUsageFilters,
        kCreditsUsageServiceTypeValues,
        pickCreditsUsageDate;
export 'package:enjoy_player/features/credits/presentation/credits_usage_format.dart'
    show serviceTypeLabel, serviceTypeIcon, tierLabel;
export 'package:enjoy_player/features/credits/presentation/credits_usage_states.dart'
    show CreditsUsageEmptyState, PageErrorBody;

class CreditsUsageScreen extends ConsumerWidget {
  const CreditsUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return EnjoyPage(
      kind: EnjoyPageKind.hub,
      title: l10n.creditsUsageTitle,
      showBack: true,
      body: (context, metrics) => SignedInGate(
        surface: AuthRequiredSurface.credits,
        loading: const SkeletonSettingsList(rowCount: 8),
        builder: (context, _) => _CreditsUsageBody(metrics: metrics),
      ),
    );
  }
}

class _CreditsUsageBody extends ConsumerWidget {
  const _CreditsUsageBody({required this.metrics});

  final EnjoyPageMetrics metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final filters = ref.watch(creditsUsageFiltersCtrlProvider);
    final pageAsync = ref.watch(creditsUsagePageProvider);
    final ctrl = ref.read(creditsUsageFiltersCtrlProvider.notifier);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(creditsUsagePageProvider);
        await ref.read(creditsUsagePageProvider.future);
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: metrics.padding(top: t.space16, bottom: t.space32),
            sliver: SliverMainAxisGroup(
              slivers: [
                const SliverToBoxAdapter(child: CreditsPackagesCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
                SliverToBoxAdapter(
                  child: FiltersGroup(filters: filters, ctrl: ctrl),
                ),
                pageAsync.when(
                  data: (CreditsUsagePage page) => creditsUsageLogsSliverGroup(
                    context,
                    filters: filters,
                    ctrl: ctrl,
                    page: page,
                  ),
                  loading: () => const SliverToBoxAdapter(
                    child: CreditsUsageLoadingList(),
                  ),
                  error: (Object e, StackTrace s) =>
                      const SliverToBoxAdapter(child: PageErrorBody()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
