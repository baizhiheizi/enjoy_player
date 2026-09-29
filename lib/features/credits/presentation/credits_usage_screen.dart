/// Read-only credits consumption audit (Worker `GET /credits/usages`).
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
                SliverToBoxAdapter(
                  child: Text(
                    l10n.creditsUsageDescription,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: t.space16)),
                SliverToBoxAdapter(
                  child: _FilterCard(filters: filters, ctrl: ctrl),
                ),
                SliverToBoxAdapter(child: SizedBox(height: t.space16)),
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

  static bool _hasActiveFilters(CreditsUsageFilters f) {
    return (f.startDate != null && f.startDate!.isNotEmpty) ||
        (f.endDate != null && f.endDate!.isNotEmpty) ||
        (f.serviceType != null && f.serviceType!.isNotEmpty);
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.filters, required this.ctrl});

  final CreditsUsageFilters filters;
  final CreditsUsageFiltersCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return EnjoyCard(
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
            key: ValueKey<String>('credits-svc-${filters.serviceType ?? ''}'),
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
          if (_CreditsUsageBody._hasActiveFilters(filters)) ...[
            SizedBox(height: t.space12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: ctrl.clearFilters,
                icon: const Icon(EnjoyIcons.clearAll),
                label: Text(l10n.creditsUsageClearFilters),
              ),
            ),
          ],
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
      child: _EmptyState(
        hasFilters: _CreditsUsageBody._hasActiveFilters(filters),
      ),
    );
  }
  final localeName = Localizations.localeOf(context).toString();
  return SliverMainAxisGroup(
    slivers: [
      SliverLayoutBuilder(
        builder: (context, constraints) {
          if (constraints.crossAxisExtent >= 720) {
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
            separatorBuilder: (_, _) => SizedBox(height: t.space8),
            itemBuilder: (context, index) =>
                _UsageLogCard(log: page.logs[index], localeName: localeName),
          );
        },
      ),
      SliverToBoxAdapter(child: SizedBox(height: t.space12)),
      SliverLayoutBuilder(
        builder: (context, constraints) {
          final currentPage = (filters.offset ~/ filters.limit) + 1;
          final pageInfo =
              '${l10n.creditsUsagePageInfo(currentPage)}'
              '${!page.hasMore && page.logs.isNotEmpty ? ' · ${l10n.creditsUsageTotalRecords(filters.offset + page.logs.length)}' : ''}';
          final pageInfoStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
          final prev = EnjoyButton.secondary(
            onPressed: filters.offset == 0 ? null : ctrl.goToPreviousPage,
            child: Text(l10n.creditsUsagePrevious),
          );
          final next = EnjoyButton.secondary(
            onPressed: !page.hasMore ? null : ctrl.goToNextPage,
            child: Text(l10n.creditsUsageNext),
          );
          final narrow = constraints.crossAxisExtent < 720;
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

class _PageErrorBody extends ConsumerWidget {
  const _PageErrorBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.space24),
      child: Column(
        children: [
          Icon(
            EnjoyIcons.error,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: t.space12),
          Text(
            l10n.creditsUsageError,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: t.space8),
          Text(
            l10n.creditsUsageErrorDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: t.space16),
          EnjoyButton.primary(
            onPressed: () {
              ref.invalidate(creditsUsagePageProvider);
            },
            child: Text(l10n.creditsUsageRetry),
          ),
        ],
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
    final tt = Theme.of(context).textTheme;
    final display = value == null || value!.isEmpty ? '—' : value!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onClear != null)
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    onPressed: onClear,
                    icon: const Icon(EnjoyIcons.close, size: 20),
                    visualDensity: VisualDensity.compact,
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
              style: tt.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
              padding: EdgeInsets.only(bottom: t.space8),
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
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.space32),
      child: Column(
        children: [
          Icon(
            EnjoyIcons.inbox,
            size: 56,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: t.space12),
          Text(
            l10n.creditsUsageNoRecords,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: t.space8),
          Text(
            hasFilters
                ? l10n.creditsUsageNoRecordsWithFilters
                : l10n.creditsUsageNoRecordsDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat.yMMMd(localeName);
    final tf = DateFormat.yMMMd().add_jm();

    return DataTable(
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
                Text(df.format(DateTime.parse('${log.date}T00:00:00Z'))),
              ),
              DataCell(
                Text(
                  tf.format(
                    DateTime.fromMillisecondsSinceEpoch(
                      log.timestampMs,
                      isUtc: true,
                    ).toLocal(),
                  ),
                ),
              ),
              DataCell(Text(serviceTypeLabel(l10n, log.serviceType))),
              DataCell(Text(log.tier)),
              DataCell(Text('${log.creditsRequired}')),
              DataCell(Text('${log.usedBefore}')),
              DataCell(Text('${log.usedAfter}')),
              DataCell(
                Text(
                  log.allowed
                      ? l10n.creditsUsageAllowed
                      : l10n.creditsUsageDenied,
                  style: tt.labelMedium?.copyWith(
                    color: log.allowed ? cs.primary : cs.error,
                    fontWeight: FontWeight.w600,
                  ),
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

  static const _tabularFigures = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final when = DateTime.fromMillisecondsSinceEpoch(
      log.timestampMs,
      isUtc: true,
    ).toLocal();
    final whenText = DateFormat.yMMMd(localeName).add_jm().format(when);
    final statusLabel = log.allowed
        ? l10n.creditsUsageAllowed
        : l10n.creditsUsageDenied;
    final numberStyle = tt.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: _tabularFigures,
    );

    return EnjoyCard(
      padding: EdgeInsets.all(t.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      whenText,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: t.space4),
                    Text(
                      'UTC · ${log.date}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              SizedBox(width: t.space8),
              _UsageStatusPill(allowed: log.allowed, label: statusLabel),
            ],
          ),
          SizedBox(height: t.space12),
          Wrap(
            spacing: t.space8,
            runSpacing: t.space4,
            children: [
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(serviceTypeLabel(l10n, log.serviceType)),
              ),
              Chip(visualDensity: VisualDensity.compact, label: Text(log.tier)),
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
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
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

class _UsageStatusPill extends StatelessWidget {
  const _UsageStatusPill({required this.allowed, required this.label});

  final bool allowed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.space8, vertical: t.space4),
      decoration: BoxDecoration(
        color: allowed ? cs.primaryContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(t.radiusFull),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          color: allowed ? cs.onPrimaryContainer : cs.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
