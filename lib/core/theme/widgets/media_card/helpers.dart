/// Cross-cutting helpers and grid-layout math for [MediaCardTile] / [MediaCardRow].
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/platform/mobile_platform.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/core/utils/sliver_key_index.dart';

import '../../enjoy_tokens.dart';

/// Hairline edge painted over clipped artwork ([MediaCardTile] /
/// [MediaCardRow]).
Widget mediaCardArtworkHairlineOverlay({
  required BorderRadius borderRadius,
  required bool light,
}) {
  return IgnorePointer(
    child: DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: borderRadius,
          side: BorderSide(
            color: light
                ? const Color(0x1416161D)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
      ),
    ),
  );
}

/// Shows [child] while hovered or keyboard-focused, hiding it otherwise.
class MediaCardHoverReveal extends StatefulWidget {
  const MediaCardHoverReveal({
    super.key,
    required this.hover,
    required this.child,
  });

  final bool hover;
  final Widget child;

  @override
  State<MediaCardHoverReveal> createState() => _MediaCardHoverRevealState();
}

class _MediaCardHoverRevealState extends State<MediaCardHoverReveal> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: AnimatedOpacity(
        opacity: widget.hover || _focused ? 1 : 0,
        duration: t.motionFast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// [deleteTooltip] when set and non-empty, else the framework default.
String mediaCardDeleteTooltip(BuildContext context, String? deleteTooltip) {
  return (deleteTooltip != null && deleteTooltip.isNotEmpty)
      ? deleteTooltip
      : MaterialLocalizations.of(context).deleteButtonTooltip;
}

/// Inline trash on the card is for pointer UIs; phones use long-press → sheet.
bool showMediaCardPointerDeleteButton() {
  return !isMobilePlatform;
}

/// Bottom sheet with a single destructive delete action (Android / iOS).
void showMediaCardMobileDeleteMenu(
  BuildContext context, {
  required VoidCallback onDelete,
  String? label,
}) {
  Haptics.impactMedium(context);
  final ml = MaterialLocalizations.of(context);
  final title = (label != null && label.isNotEmpty)
      ? label
      : ml.deleteButtonTooltip;
  unawaited(
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
                leading: Icon(EnjoyIcons.delete, color: cs.error),
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
    ),
  );
}

/// Wraps artwork in a [Hero] keyed by [mediaArtworkHeroTag] when [mediaId] is set.
Widget mediaCardHeroArtworkShell(String? mediaId, Widget child) {
  if (mediaId == null || mediaId.isEmpty) return child;
  return Hero(
    tag: mediaArtworkHeroTag(mediaId),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

/// Meta block under 16:9 artwork: 10 top + 20 title + 2 + 20 meta + 6 air.
const double mediaCardTileMetaHeight = 72;

/// Extra vertical allowance around the tile (artwork shadow / press scale).
const double mediaCardTileBorderInset = 3;

/// Grid width÷height for a [MediaCardTile] column of [tileWidth].
///
/// [metaHeight] is the budget the tile's meta slot renders with
/// ([MediaCardTile.metaHeight]) — pass the same value the tile was built with
/// so the cell is exactly tall enough for it.
double mediaCardTileGridAspectRatioForWidth(
  double tileWidth, {
  double metaHeight = mediaCardTileMetaHeight,
}) {
  return tileWidth /
      (tileWidth * 9 / 16 + metaHeight + mediaCardTileBorderInset);
}

/// Default max column width for library / cloud video grids.
const double mediaCardTileDefaultMaxWidth = 280;

int _mediaCardTileCrossAxisCountForMaxWidth({
  required double crossAxisExtent,
  required double maxTileWidth,
  required double crossAxisSpacing,
  required int maxCrossAxisCount,
}) {
  return ((crossAxisExtent + crossAxisSpacing) /
          (maxTileWidth + crossAxisSpacing))
      .ceil()
      .clamp(1, maxCrossAxisCount);
}

double _mediaCardTileWidth({
  required double crossAxisExtent,
  required int crossAxisCount,
  required double crossAxisSpacing,
}) {
  return (crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1)) /
      crossAxisCount;
}

/// Grid delegate with column count derived from [maxTileWidth] (library / cloud).
SliverGridDelegate mediaCardTileGridDelegateForMaxTileWidth({
  required double crossAxisExtent,
  double maxTileWidth = mediaCardTileDefaultMaxWidth,
  double mainAxisSpacing = 12,
  double crossAxisSpacing = 12,
  int maxCrossAxisCount = 99,
}) {
  final crossAxisCount = _mediaCardTileCrossAxisCountForMaxWidth(
    crossAxisExtent: crossAxisExtent,
    maxTileWidth: maxTileWidth,
    crossAxisSpacing: crossAxisSpacing,
    maxCrossAxisCount: maxCrossAxisCount,
  );
  final tileWidth = _mediaCardTileWidth(
    crossAxisExtent: crossAxisExtent,
    crossAxisCount: crossAxisCount,
    crossAxisSpacing: crossAxisSpacing,
  );
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    childAspectRatio: mediaCardTileGridAspectRatioForWidth(tileWidth),
  );
}

SliverGridDelegate mediaCardTileGridDelegateForMinTileWidth({
  required double crossAxisExtent,
}) {
  const minTileWidth = 210.0;
  const mainAxisSpacing = 24.0;
  const crossAxisSpacing = 20.0;
  const maxCrossAxisCount = 6;

  final effectiveMin = crossAxisExtent < 520 ? 150.0 : minTileWidth;
  final crossAxisCount =
      ((crossAxisExtent + crossAxisSpacing) / (effectiveMin + crossAxisSpacing))
          .floor()
          .clamp(1, maxCrossAxisCount);
  final tileWidth = _mediaCardTileWidth(
    crossAxisExtent: crossAxisExtent,
    crossAxisCount: crossAxisCount,
    crossAxisSpacing: crossAxisSpacing,
  );
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    childAspectRatio: mediaCardTileGridAspectRatioForWidth(tileWidth),
  );
}

SliverChildBuilderDelegate mediaCardKeyedDelegate<T>({
  required List<T> items,
  required String keyPrefix,
  required String Function(T) idOf,
  required Widget Function(BuildContext, T) tileBuilder,
}) {
  return SliverChildBuilderDelegate(
    (context, index) {
      final item = items[index];
      return Align(
        key: ValueKey<String>('$keyPrefix${idOf(item)}'),
        alignment: Alignment.topCenter,
        child: tileBuilder(context, item),
      );
    },
    childCount: items.length,
    findChildIndexCallback: (key) => findSliverIndexByPrefixedId(
      items: items,
      key: key,
      prefix: keyPrefix,
      idOf: idOf,
    ),
  );
}
