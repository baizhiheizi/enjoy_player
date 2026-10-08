/// Icon tile for grouped lists (Settings, Profile, Sync): a soft square
/// with an ink glyph. Duet keeps lists in ink; only brand rows (Pro, AI,
/// Vocabulary) and the original-voice rows (Cloud sync) take a tone.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

enum EnjoyIconTileTone { neutral, brand, original }

class EnjoyIconTile extends StatelessWidget {
  const EnjoyIconTile({
    super.key,
    required this.icon,
    this.tone = EnjoyIconTileTone.neutral,
    this.size = 30,
    this.enabled = true,
  });

  final IconData icon;
  final EnjoyIconTileTone tone;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final (background, foreground) = !enabled
        ? (t.sunk, t.ink3)
        : switch (tone) {
            EnjoyIconTileTone.neutral => (t.sunk, t.ink2),
            EnjoyIconTileTone.brand => (t.brandSoft, t.brandInk),
            EnjoyIconTileTone.original => (t.originalSoft, t.originalInk),
          };
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(size * 0.29),
        ),
      ),
      child: Icon(icon, size: size * 0.54, color: foreground),
    );
  }
}
