/// Leading content shared by every hotkey row — description + Custom badge.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';

class HotkeyRowContent extends StatelessWidget {
  const HotkeyRowContent({
    required this.description,
    required this.customized,
    required this.customizedLabel,
    super.key,
  });

  final String description;
  final bool customized;
  final String customizedLabel;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;

    return Wrap(
      spacing: t.space8,
      runSpacing: t.space4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(description, style: tt.bodyMedium),
        if (customized) EnjoyTierBadge(label: customizedLabel, muted: true),
      ],
    );
  }
}
