/// Shimmer skeleton placeholders for loading UX (respects reduced motion).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  factory Skeleton.box({
    Key? key,
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) => Skeleton(
    key: key,
    width: width,
    height: height,
    borderRadius: borderRadius ?? BorderRadius.zero,
  );

  factory Skeleton.line({
    Key? key,
    required double width,
    double height = 14,
    BorderRadius? borderRadius,
  }) => Skeleton(
    key: key,
    width: width,
    height: height,
    borderRadius: borderRadius ?? BorderRadius.circular(6),
  );

  factory Skeleton.circle({Key? key, required double diameter}) => Skeleton(
    key: key,
    width: diameter,
    height: diameter,
    borderRadius: BorderRadius.circular(diameter / 2),
  );

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = MediaQuery.disableAnimationsOf(context);
      if (!reduce) {
        unawaited(_ctrl.repeat());
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      unawaited(_ctrl.repeat());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.surfaceContainerHighest.withValues(alpha: 0.55);
    final hi = cs.surfaceContainerHigh.withValues(alpha: 0.95);
    final br =
        widget.borderRadius ??
        (widget.width == widget.height
            ? BorderRadius.circular(widget.width / 2)
            : BorderRadius.circular(8));

    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      return ClipRRect(
        borderRadius: br,
        child: Container(
          width: widget.width,
          height: widget.height,
          color: base,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return ClipRRect(
          borderRadius: br,
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _ShimmerPainter(
              progress: t,
              baseColor: base,
              highlightColor: hi,
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.progress,
    required this.baseColor,
    required this.highlightColor,
  });

  final double progress;
  final Color baseColor;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final dx = (progress * 2 - 0.5) * size.width;
    final gradient = LinearGradient(
      begin: Alignment(dx - size.width * 0.6, 0),
      end: Alignment(dx + size.width * 0.4, 0),
      colors: [baseColor, highlightColor, baseColor],
      stops: const [0.25, 0.5, 0.75],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Full-viewport loading shell (e.g. app bootstrap).
class SkeletonAppBootstrap extends StatelessWidget {
  const SkeletonAppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(t.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Skeleton.circle(diameter: 56),
            SizedBox(height: t.space24),
            Skeleton.line(width: 200, height: 18),
            SizedBox(height: t.space12),
            Skeleton.line(width: 160, height: 14),
          ],
        ),
      ),
    );
  }
}

/// Audio list placeholder.
class SkeletonMediaList extends StatelessWidget {
  const SkeletonMediaList({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space16, vertical: t.space8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) SizedBox(height: t.space8),
            Row(
              children: [
                Skeleton.box(
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(t.radiusMd),
                ),
                SizedBox(width: t.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Skeleton.line(width: double.infinity, height: 16),
                      SizedBox(height: t.space8),
                      Skeleton.line(
                        width: i.isEven ? 180.0 : 220.0,
                        height: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Video grid placeholder.
class SkeletonMediaGrid extends StatelessWidget {
  const SkeletonMediaGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(t.space16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  return Skeleton.box(
                    width: c.maxWidth,
                    height: c.maxHeight,
                    borderRadius: BorderRadius.circular(t.radiusXl),
                  );
                },
              ),
            ),
            SizedBox(height: t.space8),
            Skeleton.line(width: double.infinity, height: 14),
            SizedBox(height: t.space4),
            Skeleton.line(width: 120, height: 12),
          ],
        );
      },
    );
  }
}

/// Settings-style stacked rows.
class SkeletonSettingsList extends StatelessWidget {
  const SkeletonSettingsList({super.key, this.rowCount = 10});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.all(t.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rowCount; i++) ...[
            if (i > 0) SizedBox(height: t.space12),
            Row(
              children: [
                Skeleton.box(
                  width: 36,
                  height: 36,
                  borderRadius: BorderRadius.circular(t.radiusSm),
                ),
                SizedBox(width: t.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.line(
                        width: i % 3 == 0 ? 220.0 : 160.0,
                        height: 15,
                      ),
                      SizedBox(height: t.space8),
                      Skeleton.line(width: 280, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Transcript cue list placeholder.
class SkeletonTranscript extends StatelessWidget {
  const SkeletonTranscript({
    super.key,
    this.lineCount = 14,
    this.controller,
    this.physics = const AlwaysScrollableScrollPhysics(),
  });

  final int lineCount;
  final ScrollController? controller;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return ListView.separated(
      controller: controller,
      physics: physics,
      padding: EdgeInsets.symmetric(horizontal: t.space16, vertical: t.space8),
      itemCount: lineCount,
      separatorBuilder: (context, index) => SizedBox(height: t.space12),
      itemBuilder: (context, i) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton.box(
              width: 44,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(width: t.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Skeleton.line(width: double.infinity, height: 14),
                  SizedBox(height: t.space8),
                  Skeleton.line(
                    width: i % 2 == 0 ? double.infinity : 200.0,
                    height: 14,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Profile header + stat row placeholder.
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(t.space24),
      child: Column(
        children: [
          Skeleton.circle(diameter: 88),
          SizedBox(height: t.space16),
          Skeleton.line(width: 200, height: 22),
          SizedBox(height: t.space8),
          Skeleton.line(width: 140, height: 14),
          SizedBox(height: t.space32),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 72,
                  child: LayoutBuilder(
                    builder: (context, c) => Skeleton.box(
                      width: c.maxWidth,
                      height: 72,
                      borderRadius: BorderRadius.circular(t.radiusLg),
                    ),
                  ),
                ),
              ),
              SizedBox(width: t.space12),
              Expanded(
                child: SizedBox(
                  height: 72,
                  child: LayoutBuilder(
                    builder: (context, c) => Skeleton.box(
                      width: c.maxWidth,
                      height: 72,
                      borderRadius: BorderRadius.circular(t.radiusLg),
                    ),
                  ),
                ),
              ),
              SizedBox(width: t.space12),
              Expanded(
                child: SizedBox(
                  height: 72,
                  child: LayoutBuilder(
                    builder: (context, c) => Skeleton.box(
                      width: c.maxWidth,
                      height: 72,
                      borderRadius: BorderRadius.circular(t.radiusLg),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
