/// Shared visual sub-widgets for [MediaCardTile] and [MediaCardRow].
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/utils/local_thumbnail.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';

import '../../enjoy_tokens.dart';
import '../../generative_media_cover.dart';

/// Thumbnail with file / network / cover-seed fallback chain.
class MediaCardThumbnail extends StatelessWidget {
  const MediaCardThumbnail({
    super.key,
    required this.file,
    this.networkUrl,
    required this.coverSeed,
    required this.isVideo,
    required this.cs,
    this.width,
  });

  /// Known layout width; skips measuring (keeps the thumbnail usable under
  /// intrinsic sizing such as [IntrinsicHeight]).
  final double? width;

  final File? file;
  final String? networkUrl;
  final String? coverSeed;
  final bool isVideo;
  final ColorScheme cs;

  static const _coverFit = BoxFit.cover;

  static const _unconstrainedDecodeWidth = 600;

  Widget _networkImage(String url, int decodeWidth) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: _coverFit,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: decodeWidth,
      placeholder: (context, _) => _loading(),
      errorWidget: (context, attemptedUrl, _) {
        final mqFallback = youtubeMqFallbackForCardUrl(attemptedUrl);
        if (mqFallback != null && mqFallback != attemptedUrl) {
          return _networkImage(mqFallback, decodeWidth);
        }
        return _fallback();
      },
    );
  }

  Widget _loading() {
    if (coverSeed != null && coverSeed!.isNotEmpty) {
      return GenerativeMediaCover(seed: coverSeed!, isVideo: isVideo);
    }
    return ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: cs.onSurfaceVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final knownWidth = width;
    if (knownWidth != null) {
      return _image(thumbnailCacheWidthFor(knownWidth));
    }
    return LayoutBuilder(
      builder: (context, constraints) => _image(
        constraints.hasBoundedWidth
            ? thumbnailCacheWidthFor(constraints.maxWidth)
            : _unconstrainedDecodeWidth,
      ),
    );
  }

  Widget _image(int decodeWidth) {
    if (file != null) {
      return Image.file(
        file!,
        fit: _coverFit,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: decodeWidth,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _loading();
        },
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    final url = networkUrl;
    if (url != null && url.isNotEmpty) {
      return _networkImage(url, decodeWidth);
    }
    return _fallback();
  }

  Widget _fallback() {
    if (coverSeed != null && coverSeed!.isNotEmpty) {
      return GenerativeMediaCover(seed: coverSeed!, isVideo: isVideo);
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(
          isVideo ? EnjoyIcons.video : EnjoyIcons.audio,
          size: 28,
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// Duration overlay on artwork (bottom-right) — tabular mono numerals.
class MediaCardDurationBadge extends StatelessWidget {
  const MediaCardDurationBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) =>
      _MediaCardCoverChip(label: label, weight: FontWeight.w500, size: 11.5);
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
    if (onTap == null) return text;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: text),
      ),
    );
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
    final chip = _MediaCardCoverChip(
      label: label,
      weight: FontWeight.w600,
      size: 11,
    );
    if (onTap == null) return chip;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: chip),
      ),
    );
  }
}

class _MediaCardCoverChip extends StatelessWidget {
  const _MediaCardCoverChip({
    required this.label,
    required this.weight,
    required this.size,
  });

  final String label;
  final FontWeight weight;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: const Color(0x8C0C0E12),
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
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// Language / metadata chip in [MediaCardRow] meta.
class MediaCardBadge extends StatelessWidget {
  const MediaCardBadge({
    super.key,
    required this.label,
    required this.cs,
    this.onTap,
    this.showLanguageIcon = false,
  });

  final String label;
  final ColorScheme cs;
  final VoidCallback? onTap;
  final bool showLanguageIcon;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final interactive = onTap != null;
    final fg = interactive ? t.brandInk : cs.onSurfaceVariant;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: ShapeDecoration(
        color: interactive ? t.brandSoft : t.sunk,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLanguageIcon) ...[
            Icon(EnjoyIcons.translate, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (!interactive) return child;
    return EnjoyPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(t.radiusFull),
      pressedScale: 0.95,
      child: child,
    );
  }
}

/// Inline language link for a tile's meta line (tap to edit when [onTap]).
class MediaCardMetaLanguage extends StatelessWidget {
  const MediaCardMetaLanguage({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final short = label.split(RegExp(r'\s*[（(]')).first.trim();
    final text = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(EnjoyIcons.translate, size: 12.5, color: t.ink3),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            short.isEmpty ? label : short,
            semanticsLabel: label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
    if (onTap == null) return Tooltip(message: label, child: text);
    return Tooltip(
      message: label,
      child: EnjoyPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusXs),
        pressedScale: 0.96,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: text,
        ),
      ),
    );
  }
}

/// Middle-dot separator for meta lines.
class MediaCardMetaDot extends StatelessWidget {
  const MediaCardMetaDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
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
      decoration: ShapeDecoration(
        color: const Color(0x99000000),
        shape: StadiumBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 8.5 : 10.5,
          letterSpacing: 0.1,
          height: 1.25,
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
    return Container(
      width: 24,
      height: 24,
      decoration: ShapeDecoration(
        color: const Color(0x99000000),
        shape: CircleBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
      ),
      child: const Icon(EnjoyIcons.check, size: 13, color: Colors.white),
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
