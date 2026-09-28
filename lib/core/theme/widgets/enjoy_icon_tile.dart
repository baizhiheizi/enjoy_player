/// Colored icon tile — a white glyph on a softly lit, continuous-corner
/// square. Gives grouped lists (Settings, Profile) their scannable rhythm.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

/// Named tile tints (tuned for white glyphs, both themes).
abstract final class EnjoyTint {
  static const iris = Color(0xFF6D5DFC);
  static const indigo = Color(0xFF5856D6);
  static const blue = Color(0xFF2F7CF6);
  static const sky = Color(0xFF0EA0E4);
  static const teal = Color(0xFF12A594);
  static const green = Color(0xFF22A565);
  static const amber = Color(0xFFF2A516);
  static const orange = Color(0xFFF2711C);
  static const coral = Color(0xFFEF5A3C);
  static const red = Color(0xFFE5484D);
  static const pink = Color(0xFFE54BA0);
  static const purple = Color(0xFFA259F0);
  static const slate = Color(0xFF6B7185);
}

/// Semantic default tint for common row icons.
Color enjoyTintForIcon(IconData icon) {
  final map = <IconData, Color>{
    EnjoyIcons.language: EnjoyTint.blue,
    EnjoyIcons.translate: EnjoyTint.indigo,
    EnjoyIcons.speak: EnjoyTint.teal,
    EnjoyIcons.mic: EnjoyTint.coral,
    EnjoyIcons.sun: EnjoyTint.amber,
    EnjoyIcons.moon: EnjoyTint.indigo,
    EnjoyIcons.monitor: EnjoyTint.slate,
    EnjoyIcons.cloudSync: EnjoyTint.sky,
    EnjoyIcons.cloudDownload: EnjoyTint.sky,
    EnjoyIcons.cloudDone: EnjoyTint.sky,
    EnjoyIcons.cloudOff: EnjoyTint.slate,
    EnjoyIcons.tune: EnjoyTint.slate,
    EnjoyIcons.settings: EnjoyTint.slate,
    EnjoyIcons.help: EnjoyTint.iris,
    EnjoyIcons.keyboard: EnjoyTint.slate,
    EnjoyIcons.lab: EnjoyTint.purple,
    EnjoyIcons.insights: EnjoyTint.green,
    EnjoyIcons.update: EnjoyTint.blue,
    EnjoyIcons.lightbulb: EnjoyTint.amber,
    EnjoyIcons.archive: EnjoyTint.orange,
    EnjoyIcons.code: EnjoyTint.slate,
    EnjoyIcons.forum: EnjoyTint.green,
    EnjoyIcons.book: EnjoyTint.orange,
    EnjoyIcons.vocabulary: EnjoyTint.orange,
    EnjoyIcons.manageAccount: EnjoyTint.blue,
    EnjoyIcons.receipt: EnjoyTint.teal,
    EnjoyIcons.history: EnjoyTint.indigo,
    EnjoyIcons.hourglass: EnjoyTint.amber,
    EnjoyIcons.error: EnjoyTint.red,
    EnjoyIcons.wallet: EnjoyTint.green,
    EnjoyIcons.bolt: EnjoyTint.amber,
    EnjoyIcons.robot: EnjoyTint.purple,
    EnjoyIcons.server: EnjoyTint.slate,
    EnjoyIcons.shield: EnjoyTint.green,
    EnjoyIcons.person: EnjoyTint.blue,
    EnjoyIcons.signOut: EnjoyTint.red,
    EnjoyIcons.bug: EnjoyTint.red,
    EnjoyIcons.mail: EnjoyTint.blue,
    EnjoyIcons.target: EnjoyTint.coral,
  };
  return map[icon] ?? EnjoyTint.iris;
}

class EnjoyIconTile extends StatelessWidget {
  const EnjoyIconTile({
    super.key,
    required this.icon,
    this.color,
    this.size = 30,
    this.gradient,
    this.enabled = true,
  });

  final IconData icon;

  /// Tile tint; defaults to [enjoyTintForIcon].
  final Color? color;
  final double size;

  /// Overrides the tint with a gradient (e.g. the aurora for Pro rows).
  final Gradient? gradient;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final base = color ?? enjoyTintForIcon(icon);
    if (!enabled) {
      return Container(
        width: size,
        height: size,
        decoration: ShapeDecoration(
          color: t.fill,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(size * 0.27),
          ),
        ),
        child: Icon(icon, size: size * 0.56, color: t.textFaint),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(base, Colors.white, 0.16)!, base],
            ),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(size * 0.27),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      child: Icon(icon, size: size * 0.56, color: Colors.white),
    );
  }
}
