/// Inline icon + message callout shared by the lookup sheet surfaces.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class LookupCallout extends StatelessWidget {
  const LookupCallout({
    required this.icon,
    required this.iconColor,
    required this.message,
    this.messageColor,
    this.backgroundColor,
    this.borderColor,
    this.action,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String message;
  final Color? messageColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Padding(
        padding: EdgeInsets.all(t.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: iconColor),
                SizedBox(width: t.space8),
                Expanded(
                  child: Text(
                    message,
                    style: tt.bodySmall?.copyWith(
                      color: messageColor,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (action != null) ...[SizedBox(height: t.space12), action!],
          ],
        ),
      ),
    );
  }
}
