import 'package:material_ui/material_ui.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart'
    show Skeleton, SkeletonTickerHost;

/// A single transcript line placeholder row.
class SkeletonTranscriptRow extends StatelessWidget {
  const SkeletonTranscriptRow({super.key, this.index = 0});

  final int index;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
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
                width: index % 2 == 0 ? double.infinity : 200.0,
                height: 14,
              ),
            ],
          ),
        ),
      ],
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
    return SkeletonTickerHost(
      child: ListView.separated(
        controller: controller,
        physics: physics,
        padding: EdgeInsets.symmetric(
          horizontal: t.space16,
          vertical: t.space8,
        ),
        itemCount: lineCount,
        separatorBuilder: (context, index) => SizedBox(height: t.space12),
        itemBuilder: (context, i) => SkeletonTranscriptRow(index: i),
      ),
    );
  }
}

/// Profile header + stat row placeholder.
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return SkeletonTickerHost(
      child: SingleChildScrollView(
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
      ),
    );
  }
}
