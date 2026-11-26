import 'package:material_ui/material_ui.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart'
    show Skeleton, SkeletonTickerHost;

/// Full-viewport loading shell (e.g. app bootstrap).
class SkeletonAppBootstrap extends StatelessWidget {
  const SkeletonAppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return SkeletonTickerHost(
      child: Center(
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

    Widget rowAt(int i) {
      return Row(
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
                Skeleton.line(width: i.isEven ? 180.0 : 220.0, height: 12),
              ],
            ),
          ),
        ],
      );
    }

    return SkeletonTickerHost(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = EdgeInsets.symmetric(
            horizontal: t.space16,
            vertical: t.space8,
          );

          if (constraints.maxHeight.isFinite) {
            return ListView.separated(
              padding: padding,
              itemCount: itemCount,
              separatorBuilder: (context, _) => SizedBox(height: t.space8),
              itemBuilder: (context, i) => rowAt(i),
            );
          }

          return Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < itemCount; i++) ...[
                  if (i > 0) SizedBox(height: t.space8),
                  rowAt(i),
                ],
              ],
            ),
          );
        },
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
    return SkeletonTickerHost(
      child: GridView.builder(
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
      ),
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
    return SkeletonTickerHost(
      child: Padding(
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
      ),
    );
  }
}
