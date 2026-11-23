/// Legend chips that toggle the pitch contour chart layers.
library;

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Legend entry that toggles one chart layer on and off.
class PitchContourLegendToggle extends StatelessWidget {
  const PitchContourLegendToggle({
    required this.label,
    required this.swatch,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final PitchContourLegendSwatch swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Semantics(
      button: true,
      toggled: selected,
      child: EnjoyPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusFull),
        child: AnimatedContainer(
          duration: t.motionFast,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: ShapeDecoration(
            color: selected ? t.paper : Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(color: selected ? t.line : Colors.transparent),
            ),
          ),
          child: Opacity(
            opacity: selected ? 1 : 0.45,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                swatch,
                const SizedBox(width: 7),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: selected ? t.ink2 : t.ink3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Miniature of a chart layer: the reference band, the take line, or the
/// amplitude envelope.
class PitchContourLegendSwatch extends StatelessWidget {
  const PitchContourLegendSwatch.band(this.color, {super.key}) : kind = 0;
  const PitchContourLegendSwatch.line(this.color, {super.key}) : kind = 1;
  const PitchContourLegendSwatch.envelope(this.color, {super.key}) : kind = 2;

  final Color color;
  final int kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      0 => Container(
        width: 16,
        height: 7,
        decoration: ShapeDecoration(
          color: color.withValues(alpha: 0.35),
          shape: const StadiumBorder(),
        ),
      ),
      1 => Container(
        width: 16,
        height: 3,
        decoration: ShapeDecoration(color: color, shape: const StadiumBorder()),
      ),
      _ => Container(
        width: 16,
        height: 9,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    };
  }
}
