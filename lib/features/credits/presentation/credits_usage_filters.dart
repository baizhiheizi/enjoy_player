/// Filter pill cluster shown above the credits usage results,
/// plus the date-picker plumbing that backs the start/end pills.
library;

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
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
