/// Physical-style key cap chips for shortcut display.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

import 'package:enjoy_player/features/hotkeys/presentation/hotkey_format.dart';

/// One key cap (single token label).
class KbdChip extends StatelessWidget {
  const KbdChip({super.key, required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final padH = compact ? t.space8 : t.space12;
    final padV = compact ? t.space4 : t.space8;
    final fontSize = compact ? 11.0 : 12.0;
    final minH = compact ? 22.0 : 26.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(t.radiusSm),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minH),
          child: Center(
            child: Text(
              label,
              style: tt.labelMedium?.copyWith(
                fontFamily: 'monospace',
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: cs.onSurface.withValues(alpha: 0.92),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders a chord as a row of [KbdChip]s joined by faint `+` signs.
class KbdChordRow extends StatelessWidget {
  const KbdChordRow({super.key, required this.binding, this.compact = false});

  final String binding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = hotkeyDisplayTokens(binding);
    if (tokens.isEmpty) {
      return const SizedBox.shrink();
    }

    final gap = compact ? 3.0 : 5.0;
    final chord = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tokens.length; i++) ...[
          if (i > 0) ...[
            SizedBox(width: gap),
            Text(
              '+',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: gap),
          ],
          KbdChip(label: tokens[i], compact: compact),
        ],
      ],
    );

    // Stay on one line; scale down only if a parent gives a tight max width.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerEnd,
      child: chord,
    );
  }
}
