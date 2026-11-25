part of 'home_screen.dart';

/// Home layout while [libraryHomeRecentsProvider] has not emitted yet — mirrors the
/// loaded scroll view except insight cards (Today's Goal / community), which
/// mount only after the first media emission to avoid competing with the
/// initial DB query.
class _HomeLoadingScrollView extends ConsumerWidget {
  const _HomeLoadingScrollView({required this.metrics});

  final EnjoyPageMetrics metrics;

  static const int _kSkeletonTileCount = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final gutter = metrics.horizontalInset;

    return SkeletonTickerHost(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _HomeHeader()),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, t.space12, gutter, t.space12),
            sliver: SliverToBoxAdapter(
              child: EnjoySectionHeader(title: l10n.homeRecentMedia),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: SliverLayoutBuilder(
              builder: (context, gridConstraints) {
                return SliverGrid(
                  gridDelegate: mediaCardTileGridDelegateForMinTileWidth(
                    crossAxisExtent: gridConstraints.crossAxisExtent,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const _HomeRecentGridSkeletonTile(),
                    childCount: _kSkeletonTileCount,
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: t.space24)),
        ],
      ),
    );
  }
}

class _HomeRecentGridSkeletonTile extends StatelessWidget {
  const _HomeRecentGridSkeletonTile();

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth.isFinite ? c.maxWidth : 0.0;
        final artworkHeight = width * 9 / 16;
        return ClipRSuperellipse(
          borderRadius: BorderRadius.circular(t.radiusMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Skeleton.box(
                width: width,
                height: artworkHeight,
                borderRadius: BorderRadius.zero,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.space12,
                  t.space8,
                  t.space12,
                  t.space12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Skeleton.line(width: double.infinity, height: 14),
                    SizedBox(height: t.space4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Skeleton.line(width: 88, height: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
