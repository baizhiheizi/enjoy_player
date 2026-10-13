/// The player top bar's outlined pill (Share, Subtitles): 36 px, paper on a
/// line border; [open] paints it in the original voice.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class PlayerTopBarChip extends StatelessWidget {
  const PlayerTopBarChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showLabel = true,
    this.open = false,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool showLabel;
  final bool open;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final fg = open ? t.originalInk : t.ink2;
    final shape = StadiumBorder(
      side: BorderSide(color: open ? t.originalLine : t.line),
    );
    return Tooltip(
      message: tooltip ?? label,
      child: EnjoyPressable(
        onTap: onTap,
        shape: shape,
        pressedScale: 0.97,
        washColor: t.sunk,
        semanticsLabel: label,
        selected: open,
        child: AnimatedContainer(
          duration: t.motionFast,
          curve: Curves.easeOutCubic,
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 10),
          decoration: ShapeDecoration(
            color: open ? t.originalSoft : t.paper,
            shape: shape,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              if (showLabel) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
