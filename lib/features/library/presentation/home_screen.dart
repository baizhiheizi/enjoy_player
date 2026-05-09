/// Home: editorial header + hero last-played card + recent media grid.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/dynamic_color/dynamic_color_provider.dart';
import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/utils/local_thumbnail.dart';
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
                    action: () => importMediaFromPicker(context, ref),
                    actionLabel: l10n.actionOpenFiles,
                  );
                }

                return CustomScrollView(
                  slivers: [
                    // Editorial header
                    SliverToBoxAdapter(
                      child: EditorialHeader(
                        title: l10n.homeTitle,
                        trailing: FilledButton.icon(
                          onPressed: () => importMediaFromPicker(context, ref),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(l10n.actionOpenFiles),
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
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 16 / 14.5,
                            ),
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
              loading: () => const Center(child: CircularProgressIndicator()),
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

class _HomeInsightCards extends ConsumerWidget {
  const _HomeInsightCards();

  static const double _kWideBreakpoint = 720;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authCtrlProvider);
    final t = EnjoyThemeTokens.of(context);

    final isSignedIn = authAsync.maybeWhen(
      data: (s) => s is AuthSignedIn,
      orElse: () => false,
    );

    if (!isSignedIn) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space24, t.space24, t.space24, t.space24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _kWideBreakpoint;
          final gap = t.space12;

          if (wide) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(child: TodaysGoalCard()),
                  SizedBox(width: gap),
                  const Expanded(
                    child: CommunityActivityCard(outerPadding: EdgeInsets.zero),
                  ),
                ],
              ),
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

class _HomeMediaTile extends ConsumerWidget {
  const _HomeMediaTile({required this.media});

  final Media media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isVideo = media.kind == MediaKind.video;
    final thumb = localThumbnailFile(media.thumbnailPath);
    final dur = formatDurationHms(Duration(milliseconds: media.durationMs));
    final paletteAsync = ref.watch(artworkPaletteProvider(media.thumbnailPath));
    final accent =
        thumb == null
            ? generativeAccentForSeed(media.coverSeed)
            : paletteAsync.value?.accent;

    return MediaCardTile(
      title: media.title,
      subtitle:
          '${isVideo ? l10n.miniPlayerMediaVideo : l10n.miniPlayerMediaAudio} · $dur',
      thumbnailFile: thumb,
      coverSeed: media.coverSeed,
      isVideo: isVideo,
      accentColor: accent,
      onTap: () => context.push('/player/${media.id}'),
    );
  }
}
