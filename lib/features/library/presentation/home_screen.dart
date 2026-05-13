/// Home: editorial header + hero last-played card + recent media grid.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/guest_migration_banner.dart';
import 'package:enjoy_player/features/community/presentation/community_activity_card.dart';
import 'package:enjoy_player/features/library/presentation/todays_goal_card.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/library_media_provider.dart';
import '../domain/media.dart';
import 'library_actions.dart';

/// Matches the recents grid on the loaded home screen.
const SliverGridDelegateWithMaxCrossAxisExtent _kHomeRecentGridDelegate =
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 220,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 16 / 14.5,
    );

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const int _kRecentLimit = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(libraryMediaProvider);
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GuestMigrationBanner(),
          Expanded(
            child: mediaAsync.when(
              data: (items) {
                final sorted = [...items]
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                final recent = sorted.take(_kRecentLimit).toList();

                if (recent.isEmpty) {
                  return EmptyState(
                    icon: Icons.collections_bookmark_rounded,
                    illustrationAsset: EnjoyIllustrations.emptyLibrary,
                    title: l10n.homeEmptyTitle,
                    subtitle: l10n.homeEmptyHint,
                    action: () => showImportChooser(context, ref),
                    actionLabel: l10n.actionImport,
                  );
                }

                return CustomScrollView(
                  slivers: [
                    // Editorial header
                    SliverToBoxAdapter(
                      child: EditorialHeader(
                        title: l10n.homeTitle,
                        trailing: FilledButton.icon(
                          onPressed: () => showImportChooser(context, ref),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(l10n.actionImport),
                        ),
                      ),
                    ),

                    // Today's goal + community (signed-in, responsive grid)
                    const SliverToBoxAdapter(child: _HomeInsightCards()),

                    // Recents section label
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        t.space24,
                        0,
                        t.space24,
                        t.space12,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          l10n.homeRecentMedia,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ),

                    // Media grid
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: t.space24),
                      sliver: SliverGrid(
                        gridDelegate: _kHomeRecentGridDelegate,
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final m = recent[index];
                          return _HomeMediaTile(media: m);
                        }, childCount: recent.length),
                      ),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: t.space24)),
                  ],
                );
              },
              loading: () => const _HomeLoadingScrollView(),
              error: (e, _) {
                final cs = Theme.of(context).colorScheme;
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(t.space24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: cs.error,
                        ),
                        SizedBox(height: t.space16),
                        Text(
                          '${l10n.error}: $e',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: t.space16),
                        FilledButton.tonal(
                          onPressed: () => ref.invalidate(libraryMediaProvider),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Home layout while [libraryMediaProvider] has not emitted yet — mirrors the
/// loaded scroll view except insight cards (Today's Goal / community), which
/// mount only after the first media emission to avoid competing with the
/// initial DB query.
class _HomeLoadingScrollView extends ConsumerWidget {
  const _HomeLoadingScrollView();

  static const int _kSkeletonTileCount = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: EditorialHeader(
            title: l10n.homeTitle,
            trailing: FilledButton.icon(
              onPressed: () => showImportChooser(context, ref),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.actionImport),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(t.space24, 0, t.space24, t.space12),
          sliver: SliverToBoxAdapter(
            child: Text(
              l10n.homeRecentMedia,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: t.space24),
          sliver: SliverGrid(
            gridDelegate: _kHomeRecentGridDelegate,
            delegate: SliverChildBuilderDelegate(
              (context, index) => const _HomeRecentGridSkeletonTile(),
              childCount: _kSkeletonTileCount,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: t.space24)),
      ],
    );
  }
}

class _HomeRecentGridSkeletonTile extends StatelessWidget {
  const _HomeRecentGridSkeletonTile();

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final base = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(t.radiusXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ColoredBox(color: base)),
          Padding(
            padding: EdgeInsets.all(t.space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: t.space4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 12,
                    width: 88,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeInsightCards extends ConsumerWidget {
  const _HomeInsightCards();

  static const double _kWideBreakpoint = 720;
  static const double _kStripSplitMinWidth = 420;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authCtrlProvider);
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    final isSignedIn = authAsync.maybeWhen(
      data: (s) => s is AuthSignedIn,
      orElse: () => false,
    );

    if (!isSignedIn) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _kWideBreakpoint;
        final gap = t.space12;
        final pad = wide
            ? EdgeInsets.fromLTRB(t.space24, t.space24, t.space24, t.space24)
            : EdgeInsets.fromLTRB(t.space24, t.space8, t.space24, t.space8);

        if (wide) {
          return Padding(
            padding: pad,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(
                    child: TodaysGoalCard(variant: TodaysGoalCardVariant.card),
                  ),
                  SizedBox(width: gap),
                  const Expanded(
                    child: CommunityActivityCard(
                      outerPadding: EdgeInsets.zero,
                      variant: CommunityActivityCardVariant.card,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final narrowSplit = constraints.maxWidth >= _kStripSplitMinWidth;
        final strip = Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: narrowSplit
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(
                        flex: 3,
                        child: TodaysGoalCard(
                          variant: TodaysGoalCardVariant.bar,
                          containedInParentCard: true,
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.35),
                      ),
                      const Expanded(
                        flex: 2,
                        child: CommunityActivityCard(
                          outerPadding: EdgeInsets.zero,
                          variant: CommunityActivityCardVariant.summary,
                          containedInParentCard: true,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TodaysGoalCard(
                      variant: TodaysGoalCardVariant.bar,
                      containedInParentCard: true,
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                    const CommunityActivityCard(
                      outerPadding: EdgeInsets.zero,
                      variant: CommunityActivityCardVariant.summary,
                      containedInParentCard: true,
                    ),
                  ],
                ),
        );

        return Padding(padding: pad, child: strip);
      },
    );
  }
}

class _HomeMediaTile extends ConsumerWidget {
  const _HomeMediaTile({required this.media});

  final Media media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final playingId = ref.watch(
      playerControllerProvider.select((s) => s?.mediaId),
    );
    final isVideo = media.kind == MediaKind.video;
    final thumb = localThumbnailFileForCard(media.thumbnailPath);
    final netThumb = remoteThumbnailForCard(media.thumbnailPath);
    final dur = formatDurationHms(Duration(milliseconds: media.durationMs));
    // Grid tiles use the deterministic generative accent — running
    // `PaletteGenerator.fromImageProvider` per tile decodes + analyses pixels
    // on the main isolate (palette_generator 0.3.x predates isolate
    // support), and with 15+ tiles the parallel completions serialize into
    // multi-second UI freezes on Windows debug builds. The artwork-derived
    // palette is still used for the active player (hero artwork).
    final accent = generativeAccentForSeed(media.coverSeed);

    return MediaCardTile(
      title: media.title,
      subtitle:
          '${isVideo ? l10n.miniPlayerMediaVideo : l10n.miniPlayerMediaAudio} · $dur',
      thumbnailFile: thumb,
      providerBadge: media.provider == 'youtube' ? l10n.youtubeBadge : null,
      thumbnailNetworkUrl: netThumb,
      coverSeed: media.coverSeed,
      isVideo: isVideo,
      accentColor: accent,
      heroArtworkMediaId: playingId == media.id ? null : media.id,
      deleteTooltip: l10n.libraryDeleteMediaTooltip,
      onDelete: () => confirmAndDeleteMedia(context, ref, media),
      onTap: () => openPlayerRoute(context, media.id),
    );
  }
}
