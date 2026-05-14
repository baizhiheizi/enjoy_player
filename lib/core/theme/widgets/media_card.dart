/// Shared MediaCard primitive — replaces the ad-hoc tiles in Home and Library.
///
/// Supports two layouts:
///   [MediaCard.tile] — vertical card for grids (video/home).
///   [MediaCard.row]  — horizontal row card for list views (audio).
library;

import 'dart:io';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';

import '../enjoy_tokens.dart';
import '../generative_media_cover.dart';

bool _deleteLongPressEnabledForPlatform() {
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// Inline trash on the card is for pointer UIs; phones use long-press → sheet.
bool _showPointerDeleteButton() {
  return !_deleteLongPressEnabledForPlatform();
}

/// Bottom sheet with a single destructive delete action (Android / iOS).
void _showMobileDeleteMenu(
  BuildContext context, {
  required VoidCallback onDelete,
  String? label,
}) {
  Haptics.impactMedium(context);
  final ml = MaterialLocalizations.of(context);
  final title = (label != null && label.isNotEmpty)
      ? label
      : ml.deleteButtonTooltip;
  showEnjoySheet<void>(
    context: context,
    builder: (sheetContext) {
      final cs = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PaddedSheetDragHandle(),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: cs.error),
              title: Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                onDelete();
              },
            ),
          ],
        ),
      );
    },
  );
}

Widget _heroArtworkShell(String? mediaId, Widget child) {
  if (mediaId == null || mediaId.isEmpty) return child;
  return Hero(
    tag: mediaArtworkHeroTag(mediaId),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

// ── Tile (vertical, for grids) ──────────────────────────────────────────────

class MediaCardTile extends StatefulWidget {
  const MediaCardTile({
    super.key,
    required this.title,
    required this.onTap,
    this.thumbnailFile,
    this.thumbnailNetworkUrl,
    this.coverSeed,
    this.subtitle,
    this.isVideo = false,
    this.accentColor,
    this.onDelete,
    this.deleteTooltip,
    this.providerBadge,
    this.heroArtworkMediaId,
  });

  final String title;
  final VoidCallback onTap;
  final File? thumbnailFile;

  /// When [thumbnailFile] is null, optional `http(s)` artwork (e.g. cloud index).
  final String? thumbnailNetworkUrl;

  /// When [thumbnailFile] is null or fails to load, used for [GenerativeMediaCover].
  final String? coverSeed;
  final String? subtitle;
  final bool isVideo;
  final Color? accentColor;

  /// When non-null: on desktop / web, a corner delete control on the thumbnail; on
  /// Android / iOS, long-press opens a bottom sheet with delete (then the caller’s flow).
  final VoidCallback? onDelete;

  /// Label for hover tooltip and mobile delete sheet when [onDelete] is non-null.
  final String? deleteTooltip;

  /// When set, artwork participates in a [Hero] into the player transport tile.
  final String? heroArtworkMediaId;

  /// e.g. "YouTube" — top-left on artwork.
  final String? providerBadge;

  @override
  State<MediaCardTile> createState() => _MediaCardTileState();
}

class _MediaCardTileState extends State<MediaCardTile> {
  bool _hover = false;
  bool _deleteFocused = false;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent = widget.accentColor ?? cs.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(t.radiusXl),
          onTap: () {
            Haptics.selection(context);
            widget.onTap();
          },
          onLongPress:
              widget.onDelete != null && _deleteLongPressEnabledForPlatform()
              ? () => _showMobileDeleteMenu(
                  context,
                  onDelete: widget.onDelete!,
                  label: widget.deleteTooltip,
                )
              : null,
          hoverColor: cs.onSurface.withValues(alpha: 0.04),
          splashColor: accent.withValues(alpha: 0.12),
          highlightColor: accent.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: t.motionFast,
            curve: Curves.easeOutCubic,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(t.radiusXl),
              color: _hover
                  ? accent.withValues(alpha: 0.08)
                  : cs.surfaceContainerLow,
              border: Border.all(
                color: _hover
                    ? accent.withValues(alpha: 0.6)
                    : cs.outlineVariant.withValues(alpha: 0.25),
                width: _hover ? 1.5 : 1,
              ),
              boxShadow: _hover
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            // Grid cells fix total height; thumbnail must flex so title block never overflows.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(t.radiusXl - 1),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _heroArtworkShell(
                          widget.heroArtworkMediaId,
                          _Thumbnail(
                            file: widget.thumbnailFile,
                            networkUrl: widget.thumbnailNetworkUrl,
                            coverSeed: widget.coverSeed,
                            isVideo: widget.isVideo,
                            cs: cs,
                          ),
                        ),
                        if (widget.providerBadge != null &&
                            widget.providerBadge!.isNotEmpty)
                          Positioned(
                            top: t.space8,
                            left: t.space8,
                            child: _ProviderBadgePill(
                              label: widget.providerBadge!,
                            ),
                          ),
                        // Media kind (video vs audio) — not a play affordance; tap opens player.
                        Positioned(
                          right: t.space8,
                          bottom: t.space8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.42),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                  color: Colors.black38,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(9),
                              child: Icon(
                                widget.isVideo
                                    ? Icons.videocam_rounded
                                    : Icons.audiotrack_rounded,
                                size: 22,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                        ),
                        if (widget.onDelete != null && _showPointerDeleteButton())
                          Positioned(
                            top: t.space8,
                            right: t.space8,
                            child: Focus(
                              onFocusChange: (f) =>
                                  setState(() => _deleteFocused = f),
                              child: Builder(
                                builder: (context) {
                                  final strong = _hover || _deleteFocused;
                                  return AnimatedOpacity(
                                    opacity: strong ? 1 : 0.45,
                                    duration: t.motionFast,
                                    curve: Curves.easeOut,
                                    child: IconButton(
                                      visualDensity: VisualDensity.compact,
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                      tooltip:
                                          (widget.deleteTooltip != null &&
                                              widget.deleteTooltip!.isNotEmpty)
                                          ? widget.deleteTooltip!
                                          : MaterialLocalizations.of(
                                              context,
                                            ).deleteButtonTooltip,
                                      style: IconButton.styleFrom(
                                        backgroundColor: cs
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.92),
                                        foregroundColor: cs.onSurfaceVariant,
                                        shape: const CircleBorder(),
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                      onPressed: widget.onDelete,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Meta — fixed vertical budget (ellipsis); never steals flex from overflow.
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    t.space12,
                    t.space8,
                    t.space12,
                    t.space12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        SizedBox(height: t.space4),
                        Text(
                          widget.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.2,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
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

// ── Row (horizontal, for lists) ─────────────────────────────────────────────

class MediaCardRow extends StatefulWidget {
  const MediaCardRow({
    super.key,
    required this.title,
    required this.onTap,
    this.thumbnailFile,
    this.thumbnailNetworkUrl,
    this.coverSeed,
    this.subtitle,
    this.badge,
    this.providerBadge,
    this.isVideo = false,
    this.accentColor,
    this.trailing,
    this.onDelete,
    this.deleteTooltip,
    this.heroArtworkMediaId,
  });

  final String title;
  final VoidCallback onTap;
  final File? thumbnailFile;
  final String? thumbnailNetworkUrl;
  final String? coverSeed;
  final String? subtitle;
  final String? badge;

  /// Source label on thumbnail (e.g. YouTube).
  final String? providerBadge;
  final bool isVideo;
  final Color? accentColor;
  final Widget? trailing;

  /// When non-null (and [trailing] is null): delete beside the chevron on pointer platforms;
  /// on Android / iOS, long-press opens a bottom sheet with delete.
  final VoidCallback? onDelete;

  /// Label for hover tooltip and mobile delete sheet when [onDelete] is non-null.
  final String? deleteTooltip;

  /// When set, artwork participates in a [Hero] into the player transport tile.
  final String? heroArtworkMediaId;

  @override
  State<MediaCardRow> createState() => _MediaCardRowState();
}

class _MediaCardRowState extends State<MediaCardRow> {
  bool _hover = false;
  bool _deleteFocused = false;

  Widget _buildTrailing(ColorScheme cs, EnjoyThemeTokens t) {
    if (widget.trailing != null) return widget.trailing!;
    if (widget.onDelete != null && _showPointerDeleteButton()) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Focus(
            onFocusChange: (f) => setState(() => _deleteFocused = f),
            child: Builder(
              builder: (context) {
                final strong = _hover || _deleteFocused;
                return AnimatedOpacity(
                  opacity: strong ? 1 : 0.45,
                  duration: t.motionFast,
                  curve: Curves.easeOut,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 22,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    tooltip:
                        (widget.deleteTooltip != null &&
                            widget.deleteTooltip!.isNotEmpty)
                        ? widget.deleteTooltip!
                        : MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: widget.onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      );
    }
    return Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant);
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent = widget.accentColor ?? cs.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusLg),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(t.radiusLg),
          onTap: () {
            Haptics.selection(context);
            widget.onTap();
          },
          onLongPress:
              widget.trailing == null &&
                  widget.onDelete != null &&
                  _deleteLongPressEnabledForPlatform()
              ? () => _showMobileDeleteMenu(
                  context,
                  onDelete: widget.onDelete!,
                  label: widget.deleteTooltip,
                )
              : null,
          hoverColor: cs.onSurface.withValues(alpha: 0.04),
          splashColor: accent.withValues(alpha: 0.10),
          highlightColor: accent.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: t.motionFast,
            curve: Curves.easeOutCubic,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(t.radiusLg),
              color: _hover
                  ? accent.withValues(alpha: 0.06)
                  : cs.surfaceContainerLow,
              border: Border.all(
                color: _hover
                    ? accent.withValues(alpha: 0.45)
                    : cs.outlineVariant.withValues(alpha: 0.2),
                width: _hover ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: t.space16,
                vertical: t.space12,
              ),
              child: Row(
                children: [
                  // Thumbnail square
                  ClipRRect(
                    borderRadius: BorderRadius.circular(t.radiusMd),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _heroArtworkShell(
                            widget.heroArtworkMediaId,
                            _Thumbnail(
                              file: widget.thumbnailFile,
                              networkUrl: widget.thumbnailNetworkUrl,
                              coverSeed: widget.coverSeed,
                              isVideo: widget.isVideo,
                              cs: cs,
                            ),
                          ),
                          if (widget.providerBadge != null &&
                              widget.providerBadge!.isNotEmpty)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: _ProviderBadgePill(
                                label: widget.providerBadge!,
                                compact: true,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: t.space16),
                  // Title + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.subtitle != null ||
                            widget.badge != null) ...[
                          SizedBox(height: t.space4),
                          Row(
                            children: [
                              if (widget.badge != null) ...[
                                _Badge(label: widget.badge!, cs: cs),
                                SizedBox(width: t.space8),
                              ],
                              if (widget.subtitle != null)
                                Text(
                                  widget.subtitle!,
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Trailing
                  _buildTrailing(cs, t),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.file,
    this.networkUrl,
    required this.coverSeed,
    required this.isVideo,
    required this.cs,
  });

  final File? file;
  final String? networkUrl;
  final String? coverSeed;
  final bool isVideo;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        int? cacheW;
        int? cacheH;
        if (constraints.maxWidth.isFinite && constraints.maxHeight.isFinite) {
          cacheW = (constraints.maxWidth * dpr).round().clamp(1, 4096);
          cacheH = (constraints.maxHeight * dpr).round().clamp(1, 4096);
        }

        if (file != null) {
          return Image.file(
            file!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: cacheW,
            cacheHeight: cacheH,
            errorBuilder: (_, _, _) => _fallback(),
          );
        }
        final url = networkUrl;
        if (url != null && url.isNotEmpty) {
          return Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: cacheW,
            cacheHeight: cacheH,
            errorBuilder: (_, _, _) => _fallback(),
          );
        }
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    if (coverSeed != null && coverSeed!.isNotEmpty) {
      return GenerativeMediaCover(seed: coverSeed!, isVideo: isVideo);
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.surfaceContainerHighest, cs.surfaceContainerHigh],
        ),
      ),
      child: Center(
        child: Icon(
          isVideo ? Icons.movie_outlined : Icons.audiotrack_rounded,
          size: 28,
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.cs});

  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _ProviderBadgePill extends StatelessWidget {
  const _ProviderBadgePill({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE62117).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 9 : 11,
        ),
      ),
    );
  }
}
