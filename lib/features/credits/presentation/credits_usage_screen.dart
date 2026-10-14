/// Read-only credits consumption audit (Worker `GET /credits/usages`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/credits/application/credits_usage_provider.dart';
import 'package:enjoy_player/features/credits/domain/credits_usage_filters.dart';
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

const double _kWideBreakpoint = 720;

class CreditsUsageScreen extends ConsumerWidget {
  const CreditsUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authCtrlProvider);

    return EnjoyPage(
      kind: EnjoyPageKind.hub,
      title: l10n.creditsUsageTitle,
      showBack: true,
      body: (context, metrics) => auth.when(
        data: (state) {
          if (state is! AuthSignedIn) {
            return const Center(
              child: AuthRequiredCallout(
                surface: AuthRequiredSurface.credits,
                compact: false,
              ),
            );
          }
          return _CreditsUsageBody(metrics: metrics);
        },
        loading: () => const SkeletonSettingsList(rowCount: 8),
        error: (Object e, StackTrace s) => Center(child: Text('$e')),
      ),
    );
  }
}

class _CreditsUsageBody extends ConsumerWidget {
  const _CreditsUsageBody({required this.metrics});

  final EnjoyPageMetrics metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
                  data: (CreditsUsagePage page) =>
                      _logsSliverGroup(context, l10n, t, filters, ctrl, page),
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

Widget _logsSliverGroup(
  BuildContext context,
  AppLocalizations l10n,
  EnjoyThemeTokens t,
  CreditsUsageFilters filters,
  CreditsUsageFiltersCtrl ctrl,
  CreditsUsagePage page,
) {
  if (page.logs.isEmpty) {
    return SliverToBoxAdapter(
      child: CreditsUsageEmptyState(
        hasFilters: hasActiveCreditsUsageFilters(filters),
      ),
    );
  }
  final localeName = Localizations.localeOf(context).toString();
  return SliverMainAxisGroup(
    slivers: [
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
      SliverLayoutBuilder(
        builder: (context, constraints) {
          if (constraints.crossAxisExtent >= _kWideBreakpoint) {
            return SliverToBoxAdapter(
              child: EnjoyCard(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.crossAxisExtent - 36,
                    ),
                    child: UsageTable(logs: page.logs, localeName: localeName),
                  ),
                ),
              ),
            );
          }
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            sliver: SliverList.separated(
              itemCount: page.logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  UsageLogCard(log: page.logs[index], localeName: localeName),
            ),
          );
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      SliverLayoutBuilder(
        builder: (context, constraints) {
          final currentPage = (filters.offset ~/ filters.limit) + 1;
          final pageInfo =
              '${l10n.creditsUsagePageInfo(currentPage)}'
              '${!page.hasMore && page.logs.isNotEmpty ? ' · ${l10n.creditsUsageTotalRecords(filters.offset + page.logs.length)}' : ''}';
          final pageInfoStyle = Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontSize: 13, color: t.ink3);
          final prev = EnjoyButton.secondary(
            size: EnjoyButtonSize.small,
            onPressed: filters.offset == 0 ? null : ctrl.goToPreviousPage,
            child: Text(l10n.creditsUsagePrevious),
          );
          final next = EnjoyButton.secondary(
            size: EnjoyButtonSize.small,
            onPressed: !page.hasMore ? null : ctrl.goToNextPage,
            child: Text(l10n.creditsUsageNext),
          );
          if (constraints.crossAxisExtent < _kWideBreakpoint) {
            return SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(pageInfo, style: pageInfoStyle),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: prev),
                      const SizedBox(width: 8),
                      Expanded(child: next),
                    ],
                  ),
                ],
              ),
            );
          }
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  Expanded(child: Text(pageInfo, style: pageInfoStyle)),
                  prev,
                  const SizedBox(width: 8),
                  next,
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}
