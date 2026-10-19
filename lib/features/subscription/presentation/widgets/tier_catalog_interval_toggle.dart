/// Monthly / Yearly segmented toggle for the tier catalog, with the yearly
/// savings pill that renders beside it.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_segmented_control.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_interval.dart';

/// Billing-interval selector; stacks the [TierSavingsBadge] below the toggle
/// in compact layouts and beside it otherwise.
class TierIntervalToggle extends StatelessWidget {
  const TierIntervalToggle({
    required this.value,
    required this.onChanged,
    required this.monthlyLabel,
    required this.yearlyLabel,
    this.savingsLabel,
    super.key,
  });

  final CatalogInterval value;
  final ValueChanged<CatalogInterval> onChanged;
  final String monthlyLabel;
  final String yearlyLabel;
  final String? savingsLabel;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final toggle = EnjoySegmentedControl<CatalogInterval>(
      value: value,
      onChanged: onChanged,
      segments: [
        EnjoySegment(value: CatalogInterval.month, label: monthlyLabel),
        EnjoySegment(value: CatalogInterval.year, label: yearlyLabel),
      ],
    );
    if (savingsLabel == null) {
      return Center(child: toggle);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final savings = TierSavingsBadge(label: savingsLabel!, tt: tt);
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              toggle,
              SizedBox(height: t.space8),
              savings,
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            toggle,
            SizedBox(width: t.space8),
            Flexible(child: savings),
          ],
        );
      },
    );
  }
}

class TierSavingsBadge extends StatelessWidget {
  const TierSavingsBadge({required this.label, required this.tt, super.key});

  final String label;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: t.space8,
        vertical: t.space4 / 2,
      ),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(t.radiusFull),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tt.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onTertiaryContainer,
        ),
      ),
    );
  }
}
