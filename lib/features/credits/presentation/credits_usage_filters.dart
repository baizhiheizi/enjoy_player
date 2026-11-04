/// Filter pill cluster shown above the credits usage results,
/// plus the date-picker plumbing that backs the start/end pills.
library;

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_filter_pill.dart';
import 'package:enjoy_player/features/credits/application/credits_usage_provider.dart';
import 'package:enjoy_player/features/credits/domain/credits_usage_filters.dart';
import 'package:enjoy_player/features/credits/presentation/credits_usage_format.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const List<String> kCreditsUsageServiceTypeValues = [
  'tts',
  'asr',
  'translation',
  'llm',
  'assessment',
];

bool hasActiveCreditsUsageFilters(CreditsUsageFilters f) {
  return (f.startDate != null && f.startDate!.isNotEmpty) ||
      (f.endDate != null && f.endDate!.isNotEmpty) ||
      (f.serviceType != null && f.serviceType!.isNotEmpty);
}

class FiltersGroup extends StatelessWidget {
  const FiltersGroup({required this.filters, required this.ctrl, super.key});

  final CreditsUsageFilters filters;
  final CreditsUsageFiltersCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final hasFilters = hasActiveCreditsUsageFilters(filters);
    final service = filters.serviceType;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        EnjoyFilterPill(
          label: l10n.creditsUsageStartDate,
          value: filters.startDate,
          onTap: () => pickCreditsUsageDate(
            context,
            initial: filters.startDate,
            onYmd: ctrl.setStartDate,
          ),
        ),
        EnjoyFilterPill(
          label: l10n.creditsUsageEndDate,
          value: filters.endDate,
          onTap: () => pickCreditsUsageDate(
            context,
            initial: filters.endDate,
            onYmd: ctrl.setEndDate,
          ),
        ),
        EnjoyFilterMenu<String?>(
          label: l10n.creditsUsageServiceType,
          value: service,
          entries: [
            (null, l10n.creditsServiceTypeAll),
            for (final v in kCreditsUsageServiceTypeValues)
              (v, serviceTypeLabel(l10n, v)),
          ],
          onChanged: ctrl.setServiceType,
        ),
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
