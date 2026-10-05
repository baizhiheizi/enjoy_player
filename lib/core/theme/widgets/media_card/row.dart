/// Horizontal [MediaCardRow] for list views (audio) — Aurora list row.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/platform/mobile_platform.dart';

import '../../enjoy_tokens.dart';
import 'badges.dart';
import 'helpers.dart';
import 'media_card_sync_badge.dart';

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
    this.cloudSyncBadge,
    this.isVideo = false,
    this.accentColor,
    this.trailing,
    this.onDelete,
    this.deleteTooltip,
    this.onBadgeTap,
    this.heroArtworkMediaId,
  });

  final String title;
  final VoidCallback onTap;
  final File? thumbnailFile;
  final String? thumbnailNetworkUrl;
  final String? coverSeed;
  final String? subtitle;
  final String? badge;
  final VoidCallback? onBadgeTap;

  /// Source label on thumbnail (e.g. YouTube).
  final String? providerBadge;

  /// Cloud-sync state pill rendered on the thumbnail top-right. When set,
  /// a small icon-only pill indicates whether the audio is synced, queued
  /// for sync, or local-only.
  final MediaCardSyncBadge? cloudSyncBadge;
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
  final _hover = ValueNotifier<bool>(false);
  bool _deleteFocused = false;

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  Widget _buildTrailing(ColorScheme cs, EnjoyThemeTokens t) {
    if (widget.trailing != null) return widget.trailing!;
    final chevron = Icon(EnjoyIcons.chevronRight, size: 15, color: t.ink3);
    if (widget.onDelete != null && showMediaCardPointerDeleteButton()) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Focus(
            onFocusChange: (f) => setState(() => _deleteFocused = f),
            child: ValueListenableBuilder<bool>(
              valueListenable: _hover,
              builder: (context, hover, child) {
                final strong = hover || _deleteFocused;
                return AnimatedOpacity(
                  opacity: strong ? 1 : 0,
                  duration: t.motionFast,
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              child: IconButton(
                iconSize: 18,
                style: IconButton.styleFrom(
                  fixedSize: const Size(34, 34),
                  minimumSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                ),
                tooltip:
                    (widget.deleteTooltip != null &&
                        widget.deleteTooltip!.isNotEmpty)
                    ? widget.deleteTooltip!
                    : MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: widget.onDelete,
                icon: Icon(EnjoyIcons.delete, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          SizedBox(width: t.space4),
          chevron,
        ],
      );
    }
    return chevron;
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final artRadius = BorderRadius.circular(t.radiusSm + 2);

    return EnjoyPressable(
      onTap: widget.onTap,
      onLongPress:
          widget.trailing == null && widget.onDelete != null && isMobilePlatform
          ? () => showMediaCardMobileDeleteMenu(
              context,
              onDelete: widget.onDelete!,
              label: widget.deleteTooltip,
            )
          : null,
      onHoverChanged: (h) => _hover.value = h,
      borderRadius: BorderRadius.circular(t.radiusTile),
      pressedScale: 0.99,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: t.space8 + 2,
          vertical: t.space8,
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(borderRadius: artRadius),
                shadows: light ? t.shadowLift : const <BoxShadow>[],
              ),
              child: ClipRSuperellipse(
                borderRadius: artRadius,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      mediaCardHeroArtworkShell(
                        widget.heroArtworkMediaId,
                        MediaCardThumbnail(
                          file: widget.thumbnailFile,
                          networkUrl: widget.thumbnailNetworkUrl,
                          coverSeed: widget.coverSeed,
                          isVideo: widget.isVideo,
                          cs: cs,
                        ),
                      ),
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            shape: RoundedSuperellipseBorder(
                              borderRadius: artRadius,
                              side: BorderSide(
                                color: light
                                    ? const Color(0x1416161D)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.providerBadge != null &&
                          widget.providerBadge!.isNotEmpty)
                        Positioned(
                          top: 3,
                          left: 3,
                          child: MediaCardProviderBadgePill(
                            label: widget.providerBadge!,
                            compact: true,
                          ),
                        ),
                      if (widget.cloudSyncBadge != null)
                        Positioned(
                          top: 3,
                          right: 3,
                          child: MediaCardSyncBadgePill(
                            state: widget.cloudSyncBadge!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: t.space12 + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      height: 1.3,
                    ),
                  ),
                  if (widget.subtitle != null || widget.badge != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (widget.badge != null) ...[
                          Flexible(
                            child: MediaCardBadge(
                              label: widget.badge!,
                              cs: cs,
                              onTap: widget.onBadgeTap,
                              showLanguageIcon: widget.onBadgeTap != null,
                            ),
                          ),
                          SizedBox(width: t.space8),
                        ],
                        if (widget.subtitle != null)
                          Flexible(
                            child: Text(
                              widget.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: t.space8),
            _buildTrailing(cs, t),
          ],
        ),
      ),
    );
  }
}
