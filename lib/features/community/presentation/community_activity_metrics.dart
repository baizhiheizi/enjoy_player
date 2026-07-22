/// Reusable metric and stat block widgets for the community activity card.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

/// Internal building block for `CommunityActivityCard`; not public API.
class InlineMetric extends StatelessWidget {
  const InlineMetric({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.cs,
    required this.tabular,
  });

  final IconData icon;
  final String value;
  final String label;
  final ColorScheme cs;
  final List<FontFeature> tabular;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.primary),
        SizedBox(width: EnjoyThemeTokens.of(context).space4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: tabular,
          ),
        ),
        SizedBox(width: EnjoyThemeTokens.of(context).space4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Internal building block for `CommunityActivityCard`; not public API.
class StatBlock extends StatelessWidget {
  const StatBlock({
    super.key,
    required this.icon,
    required this.valueText,
    required this.label,
    this.compactValue = false,
  });

  final IconData icon;
  final String valueText;
  final String label;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final valueStyle = compactValue
        ? Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            SizedBox(width: t.space8),
            Expanded(
              child: Text(
                valueText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
            ),
          ],
        ),
        SizedBox(height: t.space4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
