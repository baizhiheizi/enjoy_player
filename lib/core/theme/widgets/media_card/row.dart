/// Horizontal [MediaCardRow] for list views (audio) — Aurora list row.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/platform/mobile_platform.dart';

import '../../enjoy_tokens.dart';
import '../../typography.dart';
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
    this.language,
    this.durationLabel,
    this.providerBadge,
    this.cloudSyncBadge,
    this.isVideo = false,
    this.accentColor,
    this.trailing,
    this.onDelete,
    this.deleteTooltip,
    this.onLanguageTap,
    this.heroArtworkMediaId,
    this.maxTitleLines = 1,
  });

  final String title;

  /// Titles longer than this wrap; rows with a subtitle line keep 1.
  final int maxTitleLines;
  final VoidCallback onTap;
  final File? thumbnailFile;
  final String? thumbnailNetworkUrl;
  final String? coverSeed;
  final String? subtitle;

  /// Short language code chip (`EN`) before the duration.
  final String? language;
  final VoidCallback? onLanguageTap;

  /// Mono duration at the trailing edge (`0:56`).
  final String? durationLabel;

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
    final language = widget.language;
    final duration = widget.durationLabel;
    final meta = <Widget>[
      if (language != null)
        _RowLanguageChip(label: language, onTap: widget.onLanguageTap),
      if (duration != null)
        SizedBox(
          width: 64,
          child: Text(
            duration,
            textAlign: TextAlign.right,
            style: enjoyMonoStyle(context, size: 13, color: t.ink2),
          ),
        ),
    ];
    final Widget? action;
    if (widget.trailing != null) {
      action = widget.trailing;
    } else if (widget.onDelete != null && showMediaCardPointerDeleteButton()) {
      action = Focus(
        onFocusChange: (f) => setState(() => _deleteFocused = f),
        child: ValueListenableBuilder<bool>(
          valueListenable: _hover,
          builder: (context, hover, child) => AnimatedOpacity(
            opacity: hover || _deleteFocused ? 1 : 0,
            duration: t.motionFast,
            curve: Curves.easeOut,
            child: child,
          ),
          child: IconButton(
            iconSize: 17,
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
            icon: Icon(EnjoyIcons.delete, color: t.ink3),
          ),
        ),
      );
    } else {
      action = null;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, w) in meta.indexed) ...[
          if (i > 0) const SizedBox(width: 20),
          w,
        ],
        if (action != null) ...[const SizedBox(width: 12), action],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final artRadius = BorderRadius.circular(10);

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
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
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
                  width: 56,
                  height: 56,
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
                    maxLines: widget.maxTitleLines,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      height: 1.3,
                      color: t.ink,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(
                        fontSize: 12.5,
                        color: t.ink3,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildTrailing(cs, t),
          ],
        ),
      ),
    );
  }
}

class _RowLanguageChip extends StatelessWidget {
  const _RowLanguageChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final chip = Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: t.sunk,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(7),
        ),
      ),
      child: Text(
        label,
        style: enjoyMonoStyle(
          context,
          size: 11,
          weight: FontWeight.w600,
          color: t.ink2,
        ),
      ),
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
