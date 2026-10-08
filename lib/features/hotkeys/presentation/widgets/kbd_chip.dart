/// Chord rendering for shortcut display, built on the shared [EnjoyKeycap]
/// primitive so the app has exactly one keycap style (ADR-0089 §3 / §5).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

import 'package:enjoy_player/features/hotkeys/presentation/hotkey_format.dart';

/// Renders a chord as a row of [EnjoyKeycap]s joined by faint `+` signs.
class KbdChordRow extends StatelessWidget {
  const KbdChordRow({super.key, required this.binding, this.compact = false});

  final String binding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tokens = hotkeyDisplayTokens(binding);
    if (tokens.isEmpty) {
      return const SizedBox.shrink();
    }

    final gap = compact ? t.space4 : t.space8;
    final separator = Text(
      '+',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: t.ink3,
        fontWeight: FontWeight.w500,
      ),
    );

    final chord = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tokens.length; i++) ...[
          if (i > 0) ...[SizedBox(width: gap), separator, SizedBox(width: gap)],
          EnjoyKeycap(label: tokens[i]),
        ],
      ],
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerEnd,
      child: chord,
    );
  }
}
