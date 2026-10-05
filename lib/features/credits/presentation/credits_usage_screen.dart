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
import 'package:enjoy_player/core/theme/widgets/enjoy_progress_ring.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/credits/application/credits_usage_provider.dart';
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
                SliverToBoxAdapter(
                  child: Text(
                    l10n.creditsUsageDescription,
                    maxLines: 2,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: t.ink3),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: t.space16)),
                SliverToBoxAdapter(
                  child: _FiltersGroup(filters: filters, ctrl: ctrl),
                ),
                SliverToBoxAdapter(child: SizedBox(height: t.space24)),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnjoySectionHeader(
          title: l10n.vocabularyFilters,
          trailing: hasFilters
              ? EnjoyButton.ghost(
                  onPressed: ctrl.clearFilters,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(EnjoyIcons.clearAll, size: 16),
                      SizedBox(width: t.space4),
                      Text(l10n.creditsUsageClearFilters),
                    ],
                  ),
                )
              : null,
        ),
        SizedBox(height: t.space8),
        EnjoyCard(
          padding: EdgeInsets.all(t.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FilterDateField(
                      label: l10n.creditsUsageStartDate,
                      value: filters.startDate,
                      onPick: () => pickCreditsUsageDate(
                        context,
                        initial: filters.startDate,
                        onYmd: ctrl.setStartDate,
                      ),
                      onClear: filters.startDate != null
                          ? () => ctrl.setStartDate(null)
                          : null,
                    ),
                  ),
                  SizedBox(width: t.space12),
                  Expanded(
                    child: _FilterDateField(
                      label: l10n.creditsUsageEndDate,
                      value: filters.endDate,
                      onPick: () => pickCreditsUsageDate(
                        context,
                        initial: filters.endDate,
                        onYmd: ctrl.setEndDate,
                      ),
                      onClear: filters.endDate != null
                          ? () => ctrl.setEndDate(null)
                          : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: t.space12),
              DropdownButtonFormField<String>(
                key: ValueKey<String>(
                  'credits-svc-${filters.serviceType ?? ''}',
                ),
                initialValue: filters.serviceType ?? '',
                decoration: InputDecoration(
                  labelText: l10n.creditsUsageServiceType,
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(l10n.creditsServiceTypeAll),
                  ),
                  for (final v in kCreditsUsageServiceTypeValues)
                    DropdownMenuItem(
                      value: v,
                      child: Text(serviceTypeLabel(l10n, v)),
                    ),
                ],
                onChanged: (v) {
                  ctrl.setServiceType(v == null || v.isEmpty ? null : v);
                },
              ),
            ],
          ),
        ),
      ],
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
      child: _EmptyState(
        hasFilters: _CreditsUsageBody.hasActiveFilters(filters),
      ),
    );
  }
  final localeName = Localizations.localeOf(context).toString();
  return SliverMainAxisGroup(
    slivers: [
      SliverToBoxAdapter(
        child: _UsageTotalsCard(
          logs: page.logs,
          shownLabel: l10n.creditsUsageTotalRecords(page.logs.length),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: t.space24)),
      SliverLayoutBuilder(
        builder: (context, constraints) {
          if (constraints.crossAxisExtent >= _kWideBreakpoint) {
            return SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.crossAxisExtent,
                  ),
                  child: _UsageTable(logs: page.logs, localeName: localeName),
                ),
              ),
            );
          }
          return SliverList.separated(
            itemCount: page.logs.length,
            separatorBuilder: (_, _) => SizedBox(height: t.space12),
            itemBuilder: (context, index) =>
                _UsageLogCard(log: page.logs[index], localeName: localeName),
          );
        },
      ),
      SliverToBoxAdapter(child: SizedBox(height: t.space16)),
      SliverLayoutBuilder(
        builder: (context, constraints) {
          final currentPage = (filters.offset ~/ filters.limit) + 1;
          final pageInfo =
              '${l10n.creditsUsagePageInfo(currentPage)}'
              '${!page.hasMore && page.logs.isNotEmpty ? ' · ${l10n.creditsUsageTotalRecords(filters.offset + page.logs.length)}' : ''}';
          final pageInfoStyle = Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: t.ink3);
          final prev = EnjoyButton.secondary(
            onPressed: filters.offset == 0 ? null : ctrl.goToPreviousPage,
            child: Text(l10n.creditsUsagePrevious),
          );
          final next = EnjoyButton.secondary(
            onPressed: !page.hasMore ? null : ctrl.goToNextPage,
            child: Text(l10n.creditsUsageNext),
          );
          final narrow = constraints.crossAxisExtent < _kWideBreakpoint;
          if (narrow) {
            return SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(pageInfo, style: pageInfoStyle),
                  SizedBox(height: t.space8),
                  Row(
                    children: [
                      Expanded(child: prev),
                      SizedBox(width: t.space8),
                      Expanded(child: next),
                    ],
                  ),
                ],
              ),
            );
          }
          return SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(child: Text(pageInfo, style: pageInfoStyle)),
                prev,
                SizedBox(width: t.space8),
                next,
              ],
            ),
          );
        },
      ),
    ],
  );
}

/// Credits meter for the loaded page: total required, ringed by the share the
/// Worker allowed.
class _UsageTotalsCard extends StatelessWidget {
  const _UsageTotalsCard({required this.logs, required this.shownLabel});

  final List<CreditsUsageLog> logs;
  final String shownLabel;

  static const double _ringSize = 96;
  static const double _ringStroke = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;

    final required = logs.fold<int>(0, (sum, l) => sum + l.creditsRequired);
    final consumed = logs
        .where((l) => l.allowed)
        .fold<int>(0, (sum, l) => sum + l.creditsRequired);
    final denied = logs
        .where((l) => !l.allowed)
        .fold<int>(0, (sum, l) => sum + l.creditsRequired);
    final ratio = required <= 0 ? 0.0 : consumed / required;
    final percent = (ratio * 100).round();
    final clean = denied == 0 && required > 0;

    final ringColor = t.ink;
    final figure = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    ).format(required);

    return EnjoyCard(
      padding: EdgeInsets.all(t.space20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _ringSize,
            height: _ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(_ringSize, _ringSize),
                  painter: EnjoyProgressRingPainter(
                    progress: ratio,
                    trackColor: t.fill,
                    gradientColors: clean
                        ? [ringColor, ringColor]
                        : [t.logoStart, t.logoEnd],
                    strokeWidth: _ringStroke,
                  ),
                ),
                if (clean)
                  Icon(
                    EnjoyIcons.check,
                    size: _ringSize * 0.36,
                    color: ringColor,
                  )
                else
                  Text(
                    '$percent%',
                    style: enjoyMonoStyle(
                      context,
                      size: 20,
                      weight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: t.space20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EnjoyOverline(l10n.creditsUsageTableRequired),
                SizedBox(height: t.space4),
                Text(
                  figure,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: enjoyMonoStyle(
                    context,
                    size: 28,
                    weight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: t.space4),
                Text(
                  shownLabel,
                  maxLines: 2,
                  style: tt.bodySmall?.copyWith(color: t.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageErrorBody extends ConsumerWidget {
  const _PageErrorBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      title: l10n.creditsUsageError,
      subtitle: l10n.creditsUsageErrorDescription,
      action: () => ref.invalidate(creditsUsagePageProvider),
      actionLabel: l10n.creditsUsageRetry,
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

class _FilterDateField extends StatelessWidget {
  const _FilterDateField({
    required this.label,
    required this.value,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final display = value == null || value!.isEmpty ? '—' : value!;

    return EnjoyPressable(
      onTap: onPick,
      borderRadius: BorderRadius.circular(t.radiusMd),
      semanticsLabel: label,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onClear != null)
                EnjoyIconButton(
                  icon: EnjoyIcons.close,
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip,
                  onPressed: onClear,
                  variant: EnjoyButtonVariant.ghost,
                  size: 28,
                ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(EnjoyIcons.calendar, size: 20),
              ),
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            display,
            style: enjoyMonoStyle(context, size: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
    final df = DateFormat.yMMMd(localeName);
    final tf = DateFormat.yMMMd().add_jm();
    final cellStyle = enjoyMonoStyle(context, size: 13, color: t.ink3);

    return DataTable(
      headingRowColor: WidgetStatePropertyAll(t.paper),
      headingTextStyle: enjoyMonoStyle(
        context,
        size: 12,
        weight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.6,
      ),
      dataTextStyle: cellStyle,
      columns: [
        DataColumn(label: Text(l10n.creditsUsageTableDate)),
        DataColumn(label: Text(l10n.creditsUsageTableTime)),
        DataColumn(label: Text(l10n.creditsUsageTableService)),
        DataColumn(label: Text(l10n.creditsUsageTableTier)),
        DataColumn(numeric: true, label: Text(l10n.creditsUsageTableRequired)),
        DataColumn(
          numeric: true,
          label: Text(l10n.creditsUsageTableUsedBefore),
        ),
        DataColumn(numeric: true, label: Text(l10n.creditsUsageTableUsedAfter)),
        DataColumn(label: Text(l10n.creditsUsageTableStatus)),
      ],
      rows: [
        for (final log in logs)
          DataRow(
            cells: [
              DataCell(
                Text(
                  df.format(DateTime.parse('${log.date}T00:00:00Z')),
                  style: cellStyle,
                ),
              ),
              DataCell(
                Text(
                  tf.format(
                    DateTime.fromMillisecondsSinceEpoch(
                      log.timestampMs,
                      isUtc: true,
                    ).toLocal(),
                  ),
                  style: cellStyle,
                ),
              ),
              DataCell(
                Text(serviceTypeLabel(l10n, log.serviceType), style: cellStyle),
              ),
              DataCell(Text(log.tier, style: cellStyle)),
              DataCell(Text('${log.creditsRequired}', style: cellStyle)),
              DataCell(Text('${log.usedBefore}', style: cellStyle)),
              DataCell(Text('${log.usedAfter}', style: cellStyle)),
              DataCell(
                _UsageBadge(
                  allowed: log.allowed,
                  label: log.allowed
                      ? l10n.creditsUsageAllowed
                      : l10n.creditsUsageDenied,
                ),
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
    final cs = Theme.of(context).colorScheme;
    final fg = allowed ? t.ink : cs.error;
    final bg = allowed ? t.sunk : cs.error.withValues(alpha: 0.10);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.space8, vertical: t.space4),
      decoration: ShapeDecoration(
        color: bg,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(t.radiusFull),
          side: BorderSide(color: fg.withValues(alpha: 0.28)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allowed ? EnjoyIcons.check : EnjoyIcons.close,
            size: 12,
            color: fg,
          ),
          SizedBox(width: t.space4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Neutral metadata pill carrying a service type or tier.
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
