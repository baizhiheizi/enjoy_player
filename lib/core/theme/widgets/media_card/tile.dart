/// Vertical [MediaCardTile] for grids (video / home) — Aurora.
///
/// The artwork *is* the card: continuous corners, a line edge, and a
/// hover that gently zooms the frame and reveals a glass play button. Meta
/// sits below on the page (no container), like a poster wall.
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

class MediaCardTile extends StatefulWidget {
  const MediaCardTile({
    super.key,
    this.title = '',
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
    this.cloudSyncBadge,
    this.durationLabel,
    this.language,
    this.languagePlacement = MediaCardLanguagePlacement.cover,
    this.onLanguageTap,
    this.heroArtworkMediaId,
    this.adding = false,
    this.inLibrary = false,
    this.meta,
    this.metaHeight = mediaCardTileMetaHeight,
  }) : assert(
         title == '' || meta == null,
         'MediaCardTile: pass either the built-in meta block '
         '(title/subtitle/language) or a custom meta widget, not both — '
         'meta replaces the built-in block.',
       );

  /// Title in the built-in meta block. Mutually exclusive with [meta]: the
  /// built-in block only renders when [meta] is null, and passing a non-empty
  /// [title] together with a [meta] widget trips the constructor assert.
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

  /// When non-null: on desktop, a corner delete control on the thumbnail; on
  /// Android / iOS, long-press opens a bottom sheet with delete (then the caller’s flow).
  final VoidCallback? onDelete;

  /// Label for hover tooltip and mobile delete sheet when [onDelete] is non-null.
  final String? deleteTooltip;

  /// When set, artwork participates in a [Hero] into the player transport tile.
  final String? heroArtworkMediaId;

  /// e.g. "YouTube" — top-left on artwork.
  final String? providerBadge;

  /// Cloud-sync state pill rendered on the thumbnail top-right.
  /// See [MediaCardSyncBadgePill].
  final MediaCardSyncBadge? cloudSyncBadge;

  /// When set, shown on the artwork's bottom-right corner.
  final String? durationLabel;

  /// Short language code (`EN`), drawn per [languagePlacement].
  final String? language;
  final MediaCardLanguagePlacement languagePlacement;
  final VoidCallback? onLanguageTap;

  /// Discover feed: while an "add to library" import is in flight, dim the
  /// artwork behind a spinner ([MediaCardAddingScrim]) and hide the hover
  /// play glyph. Off for home / library / cloud consumers.
  final bool adding;

  /// Discover feed: paint the in-library membership chip
  /// ([MediaCardInLibraryChip]) on the artwork's top-right corner — the same
  /// corner [cloudSyncBadge] would occupy, but the two are never combined.
  /// The tile never resolves membership itself (ADR-0088); callers pass the
  /// already-joined flag.
  final bool inLibrary;

  /// When non-null, replaces the built-in title/subtitle meta block under the
  /// artwork (Discover passes its channel-avatar row). The slot is at least
  /// [metaHeight] tall — the shared [mediaCardTileMetaHeight] box the built-in
  /// block renders in — so grid rows stay aligned whichever slot a caller
  /// uses. Content taller than the budget (two-line title, a fallback font
  /// with taller metrics, a larger platform text scale) grows the tile instead
  /// of overflowing, so callers must size their grid with
  /// [mediaCardTileGridAspectRatioForWidth] at the same [metaHeight] to keep
  /// the grown tile inside its cell. Mutually exclusive with [title]
  /// (constructor assert).
  final Widget? meta;

  /// Vertical budget for the meta slot, matched by the caller's grid aspect
  /// math. Defaults to the built-in block's [mediaCardTileMetaHeight]; a
  /// custom [meta] slot with a two-line title needs its own.
  final double metaHeight;

  @override
  State<MediaCardTile> createState() => _MediaCardTileState();
}

class _MediaCardTileState extends State<MediaCardTile> {
  final _hover = ValueNotifier<bool>(false);
  bool _deleteFocused = false;

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final radius = BorderRadius.circular(t.radiusTile);
    final instant = MediaQuery.disableAnimationsOf(context);
    final pointerDelete =
        widget.onDelete != null && showMediaCardPointerDeleteButton();

    final artwork = ValueListenableBuilder<bool>(
      valueListenable: _hover,
      builder: (context, hover, _) {
        return DecoratedBox(
          decoration: ShapeDecoration(
            shape: RoundedSuperellipseBorder(borderRadius: radius),
            shadows: hover
                ? t.shadowFloat
                : (light ? t.shadowLift : const <BoxShadow>[]),
          ),
          child: ClipRSuperellipse(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: hover && !instant ? 1.035 : 1,
                  duration: t.motionStandard,
                  curve: EnjoyThemeTokens.ease,
                  child: mediaCardHeroArtworkShell(
                    widget.heroArtworkMediaId,
                    MediaCardThumbnail(
                      file: widget.thumbnailFile,
                      networkUrl: widget.thumbnailNetworkUrl,
                      coverSeed: widget.coverSeed,
                      isVideo: widget.isVideo,
                      cs: cs,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: hover ? 1 : 0.7,
                    duration: t.motionFast,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0, 0.28, 0.62, 1],
                          colors: [
                            Color(0x33000000),
                            Color(0x00000000),
                            Color(0x00000000),
                            Color(0x4D000000),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: hover && !widget.adding ? 1 : 0,
                      duration: t.motionFast,
                      child: AnimatedScale(
                        scale: hover && !widget.adding ? 1 : 0.85,
                        duration: t.motionStandard,
                        curve: EnjoyThemeTokens.ease,
                        child: const MediaCardPlayGlyph(),
                      ),
                    ),
                  ),
                ),
                if (widget.adding) const MediaCardAddingScrim(),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: RoundedSuperellipseBorder(
                        borderRadius: radius,
                        side: BorderSide(
                          color: light
                              ? const Color(0x1416161D)
                              : Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.inLibrary)
                  Positioned(
                    top: t.space8,
                    right: t.space8,
                    child: const MediaCardInLibraryChip(),
                  ),
                if (widget.providerBadge != null &&
                    widget.providerBadge!.isNotEmpty)
                  Positioned(
                    top: t.space8,
                    left: t.space8,
                    child: MediaCardProviderBadgePill(
                      label: widget.providerBadge!,
                    ),
                  ),
                if (widget.cloudSyncBadge != null)
                  Positioned(
                    top: t.space8,
                    right: pointerDelete ? 44 : t.space8,
                    child: MediaCardSyncBadgePill(
                      state: widget.cloudSyncBadge!,
                    ),
                  ),
                if (widget.language != null &&
                    widget.languagePlacement ==
                        MediaCardLanguagePlacement.cover)
                  Positioned(
                    left: t.space8,
                    bottom: t.space8,
                    child: MediaCardCoverLanguageChip(
                      label: widget.language!,
                      onTap: widget.onLanguageTap,
                    ),
                  ),
                if (widget.durationLabel != null &&
                    widget.durationLabel!.isNotEmpty)
                  Positioned(
                    right: t.space8,
                    bottom: t.space8,
                    child: MediaCardDurationBadge(label: widget.durationLabel!),
                  ),
                if (pointerDelete)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Focus(
                      onFocusChange: (f) => setState(() => _deleteFocused = f),
                      child: AnimatedOpacity(
                        opacity: hover || _deleteFocused ? 1 : 0,
                        duration: t.motionFast,
                        curve: Curves.easeOut,
                        child: MediaCardGlassIconButton(
                          icon: EnjoyIcons.delete,
                          tooltip:
                              (widget.deleteTooltip != null &&
                                  widget.deleteTooltip!.isNotEmpty)
                              ? widget.deleteTooltip!
                              : MaterialLocalizations.of(
                                  context,
                                ).deleteButtonTooltip,
                          onPressed: widget.onDelete!,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    final kindLabel = widget.subtitle;
    return EnjoyPressable(
      onTap: widget.onTap,
      onLongPress: widget.onDelete != null && isMobilePlatform
          ? () => showMediaCardMobileDeleteMenu(
              context,
              onDelete: widget.onDelete!,
              label: widget.deleteTooltip,
            )
          : null,
      onHoverChanged: (h) => _hover.value = h,
      showHoverWash: false,
      pressedScale: 0.98,
      borderRadius: radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: artwork),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.metaHeight),
            child:
                widget.meta ??
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tt.titleSmall?.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                                height: 1.35,
                                color: t.ink,
                              ),
                            ),
                          ),
                          if (widget.language != null &&
                              widget.languagePlacement ==
                                  MediaCardLanguagePlacement.title) ...[
                            const SizedBox(width: 8),
                            MediaCardTitleLanguage(
                              label: widget.language!,
                              onTap: widget.onLanguageTap,
                            ),
                          ],
                        ],
                      ),
                      if (kindLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          kindLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            fontSize: 12.5,
                            color: t.ink3,
                            height: 1.3,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
