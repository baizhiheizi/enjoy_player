/// Shimmer skeleton placeholders for loading UX (respects reduced motion).
library;

import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

export 'skeleton_presets.dart';
export 'skeleton_scrollable_presets.dart';

/// Hosts the single shared shimmer ticker for every [Skeleton] below it
/// (issue #810 G): a loading surface with dozens of boxes drives one
/// animation clock instead of one full-rate ticker per box. A [Skeleton]
/// without a host above it falls back to hosting its own ticker.
class SkeletonTickerHost extends StatefulWidget {
  const SkeletonTickerHost({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonTickerHost> createState() => _SkeletonTickerHostState();
}

class _SkeletonTickerHostState extends State<SkeletonTickerHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

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
    return _SkeletonTickerScope(animation: _ctrl, child: widget.child);
  }
}

class _SkeletonTickerScope extends InheritedWidget {
  const _SkeletonTickerScope({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_SkeletonTickerScope oldWidget) =>
      !identical(animation, oldWidget.animation);
}

class Skeleton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tokens = EnjoyThemeTokens.of(context);
    final light = Theme.of(context).brightness == Brightness.light;
    final base = tokens.fill;
    final hi = Color.lerp(base, Colors.white, light ? 0.55 : 0.07)!;
    final br =
        borderRadius ??
        (width == height
            ? BorderRadius.circular(width / 2)
            : BorderRadius.circular(8));

    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      return ClipRRect(
        borderRadius: br,
        child: Container(width: width, height: height, color: base),
      );
    }

    final scope = context
        .dependOnInheritedWidgetOfExactType<_SkeletonTickerScope>();
    if (scope != null) {
      return _shimmer(scope.animation, br, base, hi);
    }
    return SkeletonTickerHost(
      child: Builder(
        builder: (scopedContext) {
          final scoped = scopedContext
              .dependOnInheritedWidgetOfExactType<_SkeletonTickerScope>()!;
          return _shimmer(scoped.animation, br, base, hi);
        },
      ),
    );
  }

  Widget _shimmer(
    Animation<double> animation,
    BorderRadius br,
    Color base,
    Color hi,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return ClipRRect(
          borderRadius: br,
          child: CustomPaint(
            size: Size(width, height),
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
