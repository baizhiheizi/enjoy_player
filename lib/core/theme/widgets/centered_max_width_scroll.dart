/// Scroll surfaces that stay full-width for pointer/wheel hit-testing while
/// content is centered and width-capped on large layouts.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// [CustomScrollView] whose slivers are centered with a [maxWidth] cap.
///
/// Unlike wrapping the scroll view in [Align] + [ConstrainedBox], the scroll
/// viewport spans the full parent width so mouse wheel / trackpad scrolling
/// works anywhere in the content pane.
class CenteredMaxWidthScrollView extends StatelessWidget {
  const CenteredMaxWidthScrollView({
    super.key,
    required this.maxWidth,
    required this.slivers,
    this.controller,
    this.physics,
  });

  final double maxWidth;
  final List<Widget> slivers;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: physics,
      slivers: [
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final hPad = math.max(
              0.0,
              (constraints.crossAxisExtent - maxWidth) / 2,
            );
            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              sliver: SliverMainAxisGroup(slivers: slivers),
            );
          },
        ),
      ],
    );
  }
}

/// [ListView] with the same full-width scroll hit area behavior.
class CenteredMaxWidthListView extends StatelessWidget {
  const CenteredMaxWidthListView({
    super.key,
    required this.maxWidth,
    required this.children,
    this.controller,
    this.physics,
    this.padding,
  });

  final double maxWidth;
  final List<Widget> children;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hPad = math.max(0.0, (constraints.maxWidth - maxWidth) / 2);
        final base = padding ?? EdgeInsets.zero;
        final resolved = base.resolve(Directionality.of(context));
        return ListView(
          controller: controller,
          physics: physics,
          padding: EdgeInsets.fromLTRB(
            resolved.left + hPad,
            resolved.top,
            resolved.right + hPad,
            resolved.bottom,
          ),
          children: children,
        );
      },
    );
  }
}
