/// Read-only credits consumption audit (Worker `GET /credits/usages`).
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_icon_tile.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/credits/application/credits_usage_provider.dart';
import 'package:enjoy_player/features/credits/presentation/credits_packages_card.dart';
import 'package:enjoy_player/features/credits/domain/credits_usage_filters.dart';
import 'package:enjoy_player/features/credits/domain/credits_usage_log.dart';
import 'package:enjoy_player/features/credits/domain/credits_usage_page.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Service type values accepted by the Worker filter (matches web credits page).
const List<String> kCreditsUsageServiceTypeValues = [
  'tts',
  'asr',
  'translation',
  'llm',
  'assessment',
];

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

  static bool hasActiveFilters(CreditsUsageFilters f) {
    return (f.startDate != null && f.startDate!.isNotEmpty) ||
        (f.endDate != null && f.endDate!.isNotEmpty) ||
        (f.serviceType != null && f.serviceType!.isNotEmpty);
  }

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
                  child: _FiltersGroup(filters: filters, ctrl: ctrl),
                ),
                pageAsync.when(
                  data: (CreditsUsagePage page) =>
                      _logsSliverGroup(context, l10n, t, filters, ctrl, page),
                  loading: () => const SliverToBoxAdapter(
                    child: _CreditsUsageLoadingList(),
                  ),
                  error: (Object e, StackTrace s) =>
                      const SliverToBoxAdapter(child: _PageErrorBody()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersGroup extends StatelessWidget {
  const _FiltersGroup({required this.filters, required this.ctrl});

  final CreditsUsageFilters filters;
  final CreditsUsageFiltersCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final hasFilters = _CreditsUsageBody.hasActiveFilters(filters);
    final service = filters.serviceType;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _FilterPill(
          label: l10n.creditsUsageStartDate,
          value: filters.startDate,
          onTap: () => pickCreditsUsageDate(
            context,
            initial: filters.startDate,
            onYmd: ctrl.setStartDate,
          ),
        ),
        _FilterPill(
          label: l10n.creditsUsageEndDate,
          value: filters.endDate,
          onTap: () => pickCreditsUsageDate(
            context,
            initial: filters.endDate,
            onYmd: ctrl.setEndDate,
          ),
        ),
        _ServiceFilterPill(value: service, onChanged: ctrl.setServiceType),
        if (hasFilters)
          EnjoyButton.ghost(
            onPressed: ctrl.clearFilters,
            child: Text(l10n.creditsUsageClearFilters),
          ),
        Text(
          l10n.creditsUsageUtcDates,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontSize: 12.5, color: t.ink3),
        ),
      ],
    );
  }
}

/// Paper pill: `Start date 2026-09-24`; the picked value in mono.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return EnjoyPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: ShapeDecoration(
          color: t.paper,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(11),
            side: BorderSide(color: t.line),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: tt.labelMedium?.copyWith(fontSize: 13.5, color: t.ink3),
            ),
            if (value != null && value!.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                value!,
                style: enjoyMonoStyle(context, size: 13, color: t.ink),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `Service All` pill opening a menu of service types.
class _ServiceFilterPill extends StatelessWidget {
  const _ServiceFilterPill({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final current = value == null || value!.isEmpty
        ? l10n.creditsServiceTypeAll
        : serviceTypeLabel(l10n, value!);
    return MenuAnchor(
      menuChildren: [
        for (final v in <String?>[null, ...kCreditsUsageServiceTypeValues])
          MenuItemButton(
            onPressed: () => onChanged(v),
            child: Text(
              v == null
                  ? l10n.creditsServiceTypeAll
                  : serviceTypeLabel(l10n, v),
            ),
          ),
      ],
      builder: (context, controller, _) => EnjoyPressable(
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 38,
          padding: const EdgeInsets.only(left: 12, right: 9),
          decoration: ShapeDecoration(
            color: t.paper,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(11),
              side: BorderSide(color: t.line),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${l10n.creditsUsageServiceType}  $current',
                style: tt.labelMedium?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: t.ink2,
                ),
              ),
              const SizedBox(width: 6),
              Icon(EnjoyIcons.chevronDown, size: 14, color: t.ink3),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> pickCreditsUsageDate(
  BuildContext context, {
  required String? initial,
  required void Function(String?) onYmd,
}) async {
  final now = DateTime.now();
  final parsed = initial != null ? DateTime.tryParse(initial) : null;
  final picked = await showDatePicker(
    context: context,
    initialDate: parsed ?? now,
    firstDate: DateTime.utc(2020),
    lastDate: DateTime.utc(now.year + 1, 12, 31),
  );
  if (picked == null || !context.mounted) return;
  onYmd(DateFormat('yyyy-MM-dd').format(picked.toUtc()));
}

String serviceTypeLabel(AppLocalizations l10n, String type) {
  return switch (type) {
    'tts' => l10n.creditsServiceTypeTts,
    'asr' => l10n.creditsServiceTypeAsr,
    'translation' => l10n.creditsServiceTypeTranslation,
    'llm' => l10n.creditsServiceTypeLlm,
    'assessment' => l10n.creditsServiceTypeAssessment,
    _ => type,
  };
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
      child: _EmptyState(
        hasFilters: _CreditsUsageBody.hasActiveFilters(filters),
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
                    child: _UsageTable(logs: page.logs, localeName: localeName),
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
                  _UsageLogCard(log: page.logs[index], localeName: localeName),
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

class _PageErrorBody extends ConsumerWidget {
  const _PageErrorBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.all(t.space24),
      child: EmptyState(
        title: l10n.creditsUsageError,
        subtitle: l10n.creditsUsageErrorDescription,
        action: () => ref.invalidate(creditsUsagePageProvider),
        actionLabel: l10n.creditsUsageRetry,
      ),
    );
  }
}

class _CreditsUsageLoadingList extends StatelessWidget {
  const _CreditsUsageLoadingList();

  static const _skeletonCount = 4;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return SkeletonTickerHost(
      child: Column(
        children: [
          for (var i = 0; i < _skeletonCount; i++)
            Padding(
              padding: EdgeInsets.only(bottom: t.space12),
              child: const _UsageLogCardSkeleton(),
            ),
        ],
      ),
    );
  }
}

class _UsageLogCardSkeleton extends StatelessWidget {
  const _UsageLogCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return EnjoyCard(
      padding: EdgeInsets.all(t.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton.line(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.circular(t.radiusSm),
          ),
          SizedBox(height: t.space8),
          Skeleton.line(
            width: 120,
            height: 12,
            borderRadius: BorderRadius.circular(t.radiusSm),
          ),
          SizedBox(height: t.space12),
          Row(
            children: [
              Skeleton.line(
                width: 72,
                height: 24,
                borderRadius: BorderRadius.circular(t.radiusFull),
              ),
              SizedBox(width: t.space8),
              Skeleton.line(
                width: 48,
                height: 24,
                borderRadius: BorderRadius.circular(t.radiusFull),
              ),
            ],
          ),
          SizedBox(height: t.space12),
          Row(
            children: [
              Expanded(
                child: Skeleton.line(
                  width: double.infinity,
                  height: 36,
                  borderRadius: BorderRadius.circular(t.radiusSm),
                ),
              ),
              SizedBox(width: t.space16),
              Expanded(
                child: Skeleton.line(
                  width: double.infinity,
                  height: 36,
                  borderRadius: BorderRadius.circular(t.radiusSm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      title: l10n.creditsUsageNoRecords,
      subtitle: hasFilters
          ? l10n.creditsUsageNoRecordsWithFilters
          : l10n.creditsUsageNoRecordsDescription,
    );
  }
}

class _UsageTable extends StatelessWidget {
  const _UsageTable({required this.logs, required this.localeName});

  final List<CreditsUsageLog> logs;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final tf = DateFormat.Hm();
    final number = NumberFormat.decimalPattern(localeName);
    final cell = enjoyMonoStyle(context, size: 12.5, color: t.ink);
    final cellMuted = enjoyMonoStyle(context, size: 12.5, color: t.ink3);

    Widget headerCell(String label, {bool right = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: EnjoyOverline(label),
      ),
    );

    Widget cellOf(Widget child, {bool right = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    );

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      defaultColumnWidth: const FlexColumnWidth(),
      columnWidths: const {
        3: FixedColumnWidth(90),
        4: FixedColumnWidth(90),
        5: FixedColumnWidth(92),
        6: FixedColumnWidth(100),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.line)),
          ),
          children: [
            headerCell(l10n.creditsUsageTableDate),
            headerCell(l10n.creditsUsageTableTime),
            headerCell(l10n.creditsUsageTableService),
            headerCell(l10n.creditsUsageTableTier),
            headerCell(l10n.creditsUsageTableRequired, right: true),
            headerCell(l10n.creditsUsageTableUsedAfter, right: true),
            headerCell(l10n.creditsUsageTableStatus, right: true),
          ],
        ),
        for (final log in logs)
          TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.line)),
            ),
            children: [
              cellOf(Text(log.date, style: cell)),
              cellOf(
                Text(
                  tf.format(
                    DateTime.fromMillisecondsSinceEpoch(
                      log.timestampMs,
                      isUtc: true,
                    ).toLocal(),
                  ),
                  style: cellMuted,
                ),
              ),
              cellOf(
                Text(
                  serviceTypeLabel(l10n, log.serviceType),
                  style: tt.labelLarge?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
              ),
              cellOf(Text(log.tier, style: cellMuted)),
              cellOf(
                Text(
                  number.format(log.creditsRequired),
                  style: cell,
                  textAlign: TextAlign.right,
                ),
                right: true,
              ),
              cellOf(
                Text(number.format(log.usedAfter), style: cellMuted),
                right: true,
              ),
              cellOf(
                _UsageBadge(
                  allowed: log.allowed,
                  label: log.allowed
                      ? l10n.creditsUsageAllowed
                      : l10n.creditsUsageDenied,
                ),
                right: true,
              ),
            ],
          ),
      ],
    );
  }
}

class _UsageLogCard extends StatelessWidget {
  const _UsageLogCard({required this.log, required this.localeName});

  final CreditsUsageLog log;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final when = DateTime.fromMillisecondsSinceEpoch(
      log.timestampMs,
      isUtc: true,
    ).toLocal();
    final whenText = DateFormat.yMMMd(localeName).add_jm().format(when);
    final statusLabel = log.allowed
        ? l10n.creditsUsageAllowed
        : l10n.creditsUsageDenied;
    final numberStyle = enjoyMonoStyle(
      context,
      size: 15,
      weight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return EnjoyCard(
      padding: EdgeInsets.all(t.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EnjoyIconTile(icon: serviceTypeIcon(log.serviceType)),
              SizedBox(width: t.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      whenText,
                      style: enjoyMonoStyle(
                        context,
                        size: 14,
                        weight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: t.space4),
                    Text(
                      'UTC · ${log.date}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: t.ink3),
                    ),
                  ],
                ),
              ),
              SizedBox(width: t.space8),
              _UsageBadge(allowed: log.allowed, label: statusLabel),
            ],
          ),
          SizedBox(height: t.space12),
          Row(
            children: [
              Expanded(
                child: _UsageMetaPill(
                  label: serviceTypeLabel(l10n, log.serviceType),
                ),
              ),
              SizedBox(width: t.space8),
              Expanded(child: _UsageMetaPill(label: log.tier)),
            ],
          ),
          SizedBox(height: t.space12),
          Row(
            children: [
              for (final (label, value) in [
                (l10n.creditsUsageTableRequired, '${log.creditsRequired}'),
                (l10n.creditsUsageTableUsedBefore, '${log.usedBefore}'),
                (l10n.creditsUsageTableUsedAfter, '${log.usedAfter}'),
              ])
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: t.ink3),
                      ),
                      SizedBox(height: t.space4),
                      Text(value, style: numberStyle),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData serviceTypeIcon(String serviceType) {
  return switch (serviceType) {
    'tts' => EnjoyIcons.speak,
    'asr' => EnjoyIcons.mic,
    'translation' => EnjoyIcons.translate,
    'llm' => EnjoyIcons.robot,
    'assessment' => EnjoyIcons.vocabulary,
    _ => EnjoyIcons.receipt,
  };
}

/// Aurora allowed / denied state pill.
class _UsageBadge extends StatelessWidget {
  const _UsageBadge({required this.allowed, required this.label});

  final bool allowed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: allowed ? t.sunk : t.ink,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: allowed ? t.ink2 : t.paper,
        ),
      ),
    );
  }
}

class _UsageMetaPill extends StatelessWidget {
  const _UsageMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.space12, vertical: t.space8),
      decoration: ShapeDecoration(
        color: t.fill,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(t.radiusFull),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: enjoyMonoStyle(context, size: 13, color: cs.onSurfaceVariant),
      ),
    );
  }
}
