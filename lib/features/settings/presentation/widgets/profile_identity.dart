/// Shared profile identity primitives for the Settings surfaces.
///
/// Both the Account section card and the phone hub card render the signed-in
/// identity row; the typography lives here so the two surfaces cannot drift.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';

/// Logo-ring avatar shared by the account surfaces (settings pane, hub card).
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      width: 46,
      height: 46,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: t.logo),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: t.paper, width: 2),
        ),
        child: EnjoyAvatar(name: name, size: 38),
      ),
    );
  }
}

/// Signed-in identity row: logo-ring avatar, name over a secondary line, and
/// an optional trailing affordance (tier chip, chevron).
class SettingsProfileIdentityRow extends StatelessWidget {
  const SettingsProfileIdentityRow({
    super.key,
    required this.name,
    required this.secondaryText,
    this.trailing,
  });

  final String name;
  final String secondaryText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        AccountAvatar(name: name),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                secondaryText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(fontSize: 13, color: t.ink3),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}
