/// Dark-glass overlays painted over media card artwork.
library;

import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Dark-glass fill + white hairline border shared by artwork pills.
ShapeDecoration mediaCardGlassPillDecoration({Color? fill}) {
  return ShapeDecoration(
    color: fill ?? const Color(0x99000000),
    shape: StadiumBorder(
      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
  );
}

/// White `labelSmall` typography shared by artwork pills.
TextStyle? mediaCardGlassPillTextStyle(
  BuildContext context, {
  double fontSize = 10.5,
}) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: fontSize,
    letterSpacing: 0.1,
    height: 1.25,
  );
}

/// Provider label (e.g. YouTube) on artwork — a small dark glass chip.
class MediaCardProviderBadgePill extends StatelessWidget {
  const MediaCardProviderBadgePill({
    super.key,
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 7,
        vertical: compact ? 1 : 2.5,
      ),
      decoration: mediaCardGlassPillDecoration(),
      child: Text(
        label,
        style: mediaCardGlassPillTextStyle(
          context,
          fontSize: compact ? 8.5 : 10.5,
        ),
      ),
    );
  }
}

/// Frosted play glyph revealed over artwork on hover.
class MediaCardPlayGlyph extends StatelessWidget {
  const MediaCardPlayGlyph({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.92),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 3),
        child: Icon(
          EnjoyIcons.play,
          size: size * 0.42,
          color: const Color(0xFF16161D),
        ),
      ),
    );
  }
}

/// Scrim + spinner painted over artwork while a discover feed import is
/// running. Sits above the play glyph and below the hairline edge.
class MediaCardAddingScrim extends StatelessWidget {
  const MediaCardAddingScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0x73000000),
      child: Center(
        child: LoadingIcon(size: 26, strokeWidth: 2.5, color: Colors.white),
      ),
    );
  }
}

/// In-library membership chip (artwork top-right) for discover feed tiles.
///
/// Purely presentational: the caller resolves membership and passes the flag
/// (ADR-0088) — the tile never probes the library itself.
class MediaCardInLibraryChip extends StatelessWidget {
  const MediaCardInLibraryChip({super.key});

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)!.discoverInLibrary;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
        decoration: mediaCardGlassPillDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(EnjoyIcons.check, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(label, style: mediaCardGlassPillTextStyle(context)),
          ],
        ),
      ),
    );
  }
}

/// Small dark glass icon button for artwork corners (delete, more).
class MediaCardGlassIconButton extends StatelessWidget {
  const MediaCardGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x8C000000),
        foregroundColor: Colors.white,
        hoverColor: const Color(0x33FFFFFF),
        fixedSize: const Size(30, 30),
        minimumSize: const Size(30, 30),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
