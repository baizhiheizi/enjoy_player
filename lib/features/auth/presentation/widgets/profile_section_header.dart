/// Reusable section header (icon + title + hint) for the profile screen.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class ProfileSectionHeader extends StatelessWidget {
  const ProfileSectionHeader({
    required this.title,
    required this.hint,
    required this.icon,
    super.key,
  });

  final String title;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, t.space8, 0, t.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(icon, size: 20, color: cs.primary),
            ),
          ),
          SizedBox(width: t.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: t.space4),
                Text(
                  hint,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
