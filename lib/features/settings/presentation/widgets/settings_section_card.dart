/// A Settings section: icon/title/hint header + an [EnjoyCard] of rows.
///
/// Always expanded — for the small number of low-frequency sections that
/// should default-collapse (Developer, About), use
/// [SettingsCollapsibleSection] instead. See
/// specs/004-settings-redesign/contracts/settings-section-registry.md.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.hint,
    required this.icon,
    required this.child,
    this.padding,
    this.headerTrailing,
  });

  final String title;
  final String hint;
  final IconData icon;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Optional control shown at the trailing edge of the header row.
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(
          title: title,
          hint: hint,
          icon: icon,
          trailing: headerTrailing,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: t.space16),
          child: EnjoyCard(
            padding: padding ?? EdgeInsets.all(t.space16),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Icon + title + hint row above a [SettingsSectionCard] or
/// [SettingsCollapsibleSection]'s card body.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    super.key,
    required this.title,
    required this.hint,
    required this.icon,
    this.subdued = false,
    this.trailing,
  });

  final String title;
  final String hint;
  final IconData icon;
  final bool subdued;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final iconFg = subdued ? cs.onSurfaceVariant : cs.primary;

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space24, t.space16, t.space24, t.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(icon, size: 20, color: iconFg),
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
                    color: subdued
                        ? cs.onSurface.withValues(alpha: 0.92)
                        : null,
                  ),
                ),
                SizedBox(height: t.space4),
                Text(
                  hint,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(
                      alpha: subdued ? 0.75 : 0.9,
                    ),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: t.space12), trailing!],
        ],
      ),
    );
  }
}
