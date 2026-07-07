/// Shared visual primitives for the subtitle track picker.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

/// Small rounded pill used to show a provider source or language code.
class MetaChip extends StatelessWidget {
  const MetaChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: t.space8,
        vertical: t.space4 - 1,
      ),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(t.radiusFull),
        border: Border.all(color: foreground.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.25,
          height: 1.1,
        ),
      ),
    );
  }
}
