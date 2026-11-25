part of 'home_screen.dart';

const double _kOverviewSplitMinWidth = 856;
const double _kSideColumnMinWidth = 300;
const double _kSideCardsPairMinWidth = 560;
const double _kHeroStackBelow = 600;

/// Continue practicing (or the empty-library card) beside Today's goal and
/// Community; the side cards wrap below the hero on narrower panes. [width]
/// is the band's content width from the page metrics.
class _HomeOverview extends ConsumerWidget {
  const _HomeOverview({required this.hasRecents, required this.width});

  final bool hasRecents;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(authIsSignedInProvider);
    final resume = ref.watch(continuePracticeResumeProvider);

    final Widget? hero = resume != null
        ? ContinuePracticeCard(
            resume: resume,
            stacked: width < _kHeroStackBelow,
          )
        : hasRecents
        ? null
        : const _HomeEmptyCard();
    const goal = TodaysGoalCard();
    const community = CommunityActivityCard(outerPadding: EdgeInsets.zero);

    if (!isSignedIn) return hero ?? const SizedBox.shrink();

    if (hero != null && width >= _kOverviewSplitMinWidth) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 165, child: hero),
            const SizedBox(width: 20),
            Expanded(
              flex: 100,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: _kSideColumnMinWidth,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [goal, SizedBox(height: 20), community],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final side = width >= _kSideCardsPairMinWidth
        ? const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: goal),
                SizedBox(width: 20),
                Expanded(child: community),
              ],
            ),
          )
        : const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [goal, SizedBox(height: 16), community],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hero != null) ...[hero, const SizedBox(height: 20)],
        side,
      ],
    );
  }
}

class _HomeEmptyCard extends ConsumerWidget {
  const _HomeEmptyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return EnjoyCard(
      radius: t.radiusCardLarge,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.homeEmptyTitle,
              style: enjoyDisplayStyle(context, size: 24, color: t.ink),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeEmptyHint,
              style: tt.bodyMedium?.copyWith(fontSize: 14.5, color: t.ink2),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Builder(
                  builder: (anchor) => EnjoyButton.brand(
                    onPressed: () =>
                        showImportChooser(context, ref, anchor: anchor),
                    child: Text(l10n.actionImport),
                  ),
                ),
                EnjoyButton.secondary(
                  onPressed: () => context.go('/discover'),
                  child: Text(l10n.discoverBrowseAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
