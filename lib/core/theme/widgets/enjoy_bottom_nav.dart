/// Floating glass tab bar — Aurora mobile chrome (not stock [NavigationBar]).
///
/// A frosted capsule with a soft "lens" that glides to the selected tab;
/// glyphs switch outline → filled on selection. No ripple, no pill label
/// indicator — the lens is the indicator.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class EnjoyBottomNavDestination {
  const EnjoyBottomNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.semanticsLabel,
    this.showBadge = false,
    this.iconWidget,
    this.selectedIconWidget,
  });

  final IconData icon;
  final IconData selectedIcon;

  /// When set, rendered instead of [icon] (chrome glyph). Tests may omit this.
  final Widget? iconWidget;

  /// When set, rendered instead of [selectedIcon].
  final Widget? selectedIconWidget;
  final String label;

  /// Defaults to [label] when null.
  final String? semanticsLabel;

  /// Small notification dot on the icon (e.g. pending app update).
  final bool showBadge;
}

class EnjoyBottomNav extends StatelessWidget {
  const EnjoyBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<EnjoyBottomNavDestination> destinations;

  /// Capsule height (the rest of [EnjoyThemeTokens.bottomNavHeight] is the
  /// breathing gap above it).
  static const double capsuleHeight = 58;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final light = Theme.of(context).brightness == Brightness.light;
    final cs = Theme.of(context).colorScheme;

    final blurRaw = t.miniBarBlurSigma;
    final blur = defaultTargetPlatform == TargetPlatform.android
        ? (blurRaw > 10 ? 10.0 : blurRaw)
        : blurRaw;
    final instant = MediaQuery.disableAnimationsOf(context);
    final shape = const StadiumBorder();

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(t.space16, 0, t.space16, t.space8 + 2),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: shape,
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: light ? 0.10 : 0.45),
                  blurRadius: 24,
                  spreadRadius: -6,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: t.glassTint,
                    shape: StadiumBorder(
                      side: BorderSide(color: t.glassBorder),
                    ),
                  ),
                  child: SizedBox(
                    height: capsuleHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final n = destinations.length;
                          final itemWidth = constraints.maxWidth / n;
                          return Stack(
                            children: [
                              AnimatedPositioned(
                                duration: instant
                                    ? Duration.zero
                                    : t.motionStandard,
                                curve: EnjoyThemeTokens.emphasized,
                                left: itemWidth * selectedIndex,
                                top: 0,
                                bottom: 0,
                                width: itemWidth,
                                child: DecoratedBox(
                                  decoration: ShapeDecoration(
                                    color: light
                                        ? cs.primary.withValues(alpha: 0.09)
                                        : Colors.white.withValues(alpha: 0.08),
                                    shape: StadiumBorder(
                                      side: BorderSide(
                                        color: light
                                            ? cs.primary.withValues(alpha: 0.06)
                                            : Colors.white.withValues(
                                                alpha: 0.06,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  for (var i = 0; i < n; i++)
                                    Expanded(
                                      child: _EnjoyBottomNavItem(
                                        destination: destinations[i],
                                        selected: i == selectedIndex,
                                        onTap: () {
                                          Haptics.selection(context);
                                          onDestinationSelected(i);
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnjoyBottomNavItem extends StatelessWidget {
  const _EnjoyBottomNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final EnjoyBottomNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final label = destination.semanticsLabel ?? destination.label;
    final color = selected ? t.accentInk : cs.onSurfaceVariant;

    return EnjoyPressable(
      onTap: onTap,
      haptic: false,
      showHoverWash: false,
      pressedScale: 0.92,
      borderRadius: BorderRadius.circular(t.radiusFull),
      semanticsLabel: label,
      excludeSemantics: true,
      selected: selected,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconTheme(
                data: IconThemeData(size: 22, color: color),
                child: AnimatedSwitcher(
                  duration: t.motionFast,
                  switchInCurve: EnjoyThemeTokens.ease,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey<bool>(selected),
                    child: selected
                        ? (destination.selectedIconWidget ??
                              destination.iconWidget ??
                              Icon(destination.selectedIcon))
                        : (destination.iconWidget ?? Icon(destination.icon)),
                  ),
                ),
              ),
              if (destination.showBadge)
                Positioned(
                  right: -3,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.popover, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            destination.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: tt.labelSmall?.copyWith(
              fontSize: 10.5,
              height: 1.2,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: color,
              letterSpacing: 0.05,
            ),
          ),
        ],
      ),
    );
  }
}
