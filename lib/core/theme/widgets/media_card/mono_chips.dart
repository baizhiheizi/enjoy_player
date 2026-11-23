/// 22px mono chip family for media card artwork corners and title rows.
library;

import 'package:enjoy_player/core/theme/typography.dart';
import 'package:flutter/material.dart';

import '../../enjoy_tokens.dart';

/// Duration overlay on artwork (bottom-right) — tabular mono numerals.
class MediaCardDurationBadge extends StatelessWidget {
  const MediaCardDurationBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) =>
      MediaCardMonoChip(label: label, weight: FontWeight.w500, size: 11.5);
}

/// Where [MediaCardTile] draws its language code: on the artwork
/// (Home) or beside the title (Library).
enum MediaCardLanguagePlacement { cover, title }

/// Mono ink3 language code beside a tile title (Library).
class MediaCardTitleLanguage extends StatelessWidget {
  const MediaCardTitleLanguage({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        label,
        style: enjoyMonoStyle(
          context,
          size: 11,
          weight: FontWeight.w600,
          color: EnjoyThemeTokens.of(context).ink3,
        ),
      ),
    );
    return mediaCardTappableChip(onTap, text);
  }
}

/// Mono language code on the artwork's bottom-left corner (`EN`).
class MediaCardCoverLanguageChip extends StatelessWidget {
  const MediaCardCoverLanguageChip({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MediaCardMonoChip(label: label, onTap: onTap);
  }
}

/// 22px mono chip shared by artwork corners and [MediaCardRow] meta.
class MediaCardMonoChip extends StatelessWidget {
  const MediaCardMonoChip({
    super.key,
    required this.label,
    this.weight = FontWeight.w600,
    this.size = 11,
    this.fillColor = const Color(0x8C0C0E12),
    this.textColor = Colors.white,
    this.onTap,
  });

  final String label;
  final FontWeight weight;
  final double size;
  final Color fillColor;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: fillColor,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(7),
        ),
      ),
      child: Text(
        label,
        style: enjoyMonoStyle(
          context,
          size: size,
          weight: weight,
          color: textColor,
          height: 1,
        ),
      ),
    );
    return mediaCardTappableChip(onTap, chip);
  }
}

/// Adds button semantics, an opaque hit target, and a click cursor when
/// [onTap] is set; returns [child] unchanged otherwise.
Widget mediaCardTappableChip(VoidCallback? onTap, Widget child) {
  if (onTap == null) return child;
  return Semantics(
    button: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: child),
    ),
  );
}
