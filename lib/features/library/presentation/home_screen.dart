/// Home: editorial header + hero last-played card + recent media grid.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/dynamic_color/dynamic_color_provider.dart';
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
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
/// loaded scroll view so insight cards (Today's Goal skeleton, community) mount
/// and network work can overlap with the first DB query.
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
        const SliverToBoxAdapter(child: _HomeInsightCards()),
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
    final base =
        Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.6,
        );

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

class _HomeInsightCards extends ConsumerStatefulWidget {
  const _HomeInsightCards();

  @override
  ConsumerState<_HomeInsightCards> createState() => _HomeInsightCardsState();
}

class _HomeInsightCardsState extends ConsumerState<_HomeInsightCards> {
  static const double _kWideBreakpoint = 720;

  bool _postFrameScheduled = false;
  bool _insightsReady = false;

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authCtrlProvider);
    final t = EnjoyThemeTokens.of(context);

    final isSignedIn = authAsync.maybeWhen(
      data: (s) => s is AuthSignedIn,
      orElse: () => false,
    );

    if (!isSignedIn) {
      _postFrameScheduled = false;
      _insightsReady = false;
      return const SizedBox.shrink();
    }

    if (!_insightsReady) {
      if (!_postFrameScheduled) {
        _postFrameScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _insightsReady = true;
            _postFrameScheduled = false;
          });
        });
      }
      return Padding(
        padding: EdgeInsets.fromLTRB(t.space24, t.space24, t.space24, t.space24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _kWideBreakpoint;
            final gap = t.space12;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _HomeInsightSkeletonCard(t: t)),
                  SizedBox(width: gap),
                  Expanded(child: _HomeInsightSkeletonCard(t: t)),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeInsightSkeletonCard(t: t),
                SizedBox(height: gap),
                _HomeInsightSkeletonCard(t: t),
              ],
            );
          },
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space24, t.space24, t.space24, t.space24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _kWideBreakpoint;
          final gap = t.space12;

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: TodaysGoalCard()),
                SizedBox(width: gap),
                const Expanded(
                  child: CommunityActivityCard(outerPadding: EdgeInsets.zero),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TodaysGoalCard(),
              SizedBox(height: gap),
              const CommunityActivityCard(outerPadding: EdgeInsets.zero),
            ],
          );
        },
      ),
    );
  }
}

/// Lightweight placeholders shown for one frame before insight API providers mount.
class _HomeInsightSkeletonCard extends StatelessWidget {
  const _HomeInsightSkeletonCard({required this.t});

  final EnjoyThemeTokens t;

  @override
  Widget build(BuildContext context) {
    final base =
        Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.6,
        );
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: 240,
        child: Padding(
          padding: EdgeInsets.all(t.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(width: t.space8),
                  Expanded(
                    child: Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: base,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMediaTile extends ConsumerWidget {
  const _HomeMediaTile({required this.media});

  final Media media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isVideo = media.kind == MediaKind.video;
    final thumb = localThumbnailFileForCard(media.thumbnailPath);
    final netThumb = remoteThumbnailForCard(media.thumbnailPath);
    final dur = formatDurationHms(Duration(milliseconds: media.durationMs));
    final paletteAsync = ref.watch(artworkPaletteProvider(media.thumbnailPath));
    final accent =
        thumb != null
            ? (paletteAsync.value?.accent ?? generativeAccentForSeed(media.coverSeed))
            : generativeAccentForSeed(media.coverSeed);

    return MediaCardTile(
      title: media.title,
      subtitle:
          '${isVideo ? l10n.miniPlayerMediaVideo : l10n.miniPlayerMediaAudio} · $dur',
      thumbnailFile: thumb,
      providerBadge:
          media.provider == 'youtube' ? l10n.youtubeBadge : null,
      thumbnailNetworkUrl: netThumb,
      coverSeed: media.coverSeed,
      isVideo: isVideo,
      accentColor: accent,
      deleteTooltip: l10n.libraryDeleteMediaTooltip,
      onDelete: () => confirmAndDeleteMedia(context, ref, media),
      onTap: () => openPlayerRoute(context, media.id),
    );
  }
}
