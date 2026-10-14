/// Shared visual primitives for the subtitle track picker.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';

/// Uppercase section heading inside the Subtitles & display panel.
class SubtitlePanelOverline extends StatelessWidget {
  const SubtitlePanelOverline(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 11 * 0.09,
          color: t.ink3,
        ),
      ),
    );
  }
}

/// Hairline between the panel's sections.
class SubtitlePanelDivider extends StatelessWidget {
  const SubtitlePanelDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: t.line,
    );
  }
}

/// Display switch row: title over an ink3 hint, switch at the end.
class SubtitleToggleTile extends StatelessWidget {
  const SubtitleToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final enabled = onChanged != null;
    return MergeSemantics(
      child: EnjoyPressable(
        onTap: enabled ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(12),
        pressedScale: 1,
        washColor: t.sunk,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: enabled ? t.ink : t.ink3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: tt.bodySmall?.copyWith(
                        fontSize: 12.5,
                        height: 1.4,
                        color: t.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded pill used to show a provider source or language code.
///
/// Sized for dense single-line picker rows; do not reuse as a standalone badge.
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
          height: 1.1,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
