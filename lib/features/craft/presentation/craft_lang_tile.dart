/// Shared tile shell for craft language pickers (translate + synthesize).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';

/// Pressable tile surface: inset card, continuous corners, standard padding.
/// The content ([child]) decides the layout axis (column vs row).
class CraftLangTile extends StatelessWidget {
  const CraftLangTile({
    super.key,
    required this.child,
    required this.onTap,
    this.verticalPadding,
  });

  final Widget child;
  final VoidCallback onTap;

  /// Defaults to the compact translate-tool rhythm; the synthesize tool
  /// passes a taller padding.
  final double? verticalPadding;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return EnjoyCard(
      elevated: false,
      radius: t.radiusMd,
      padding: EdgeInsets.zero,
      child: EnjoyPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusMd),
        pressedScale: 0.995,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: t.space12,
            vertical: verticalPadding ?? t.space8,
          ),
          child: child,
        ),
      ),
    );
  }
}
