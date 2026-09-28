/// Inline metric widget for the community activity summary row.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: enjoyDisplayStyle(
            context,
            size: 30,
            color: cs.onSurface,
            height: 1.1,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: EnjoyThemeTokens.of(context).textFaint),
            SizedBox(width: EnjoyThemeTokens.of(context).space4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}
