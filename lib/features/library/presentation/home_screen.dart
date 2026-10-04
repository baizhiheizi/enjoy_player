/// Home: editorial header + insight cards + recent media grid.
///
/// No Continue practicing section — the last-practiced item is already the
/// first row of the recents grid, and desktop gets a dedicated sidebar card.
library;

import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/utils/sliver_key_index.dart';
import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/theme/widgets/media_card/media_card_sync_badge.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/community/presentation/community_activity_card.dart';
import 'package:enjoy_player/features/library/presentation/todays_goal_card.dart';
import 'package:enjoy_player/features/onboarding/application/onboarding_controller.dart';
import 'package:enjoy_player/features/onboarding/application/practice_tip_trigger.dart';
import 'package:enjoy_player/features/onboarding/domain/onboarding_tip_id.dart';
import 'package:enjoy_player/features/onboarding/presentation/onboarding_target.dart';
import 'package:enjoy_player/features/player/application/local_thumbnail_provider.dart';
import 'package:enjoy_player/features/player/application/youtube_warm.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/library_media_provider.dart';
import '../domain/media.dart';
import 'library_actions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(practiceTipTriggerProvider)
          .startHomeEntries(routePath: GoRouterState.of(context).uri.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(libraryHomeRecentsProvider);
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return EnjoyPage(
      kind: EnjoyPageKind.browse,
      body: (context, metrics) {
        final gutter = metrics.gutter;
        return mediaAsync.when(
          data: (recent) {
            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _HomeHeader()),

                const SliverToBoxAdapter(child: _HomeInsightCards()),

                if (recent.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      title: l10n.homeEmptyTitle,
                      subtitle: l10n.homeEmptyHint,
                      action: () => showImportChooser(context, ref),
                      actionLabel: l10n.actionImport,
                      secondaryAction: () => context.go('/discover'),
                      secondaryActionLabel: l10n.discoverBrowseAction,
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      t.space12,
                      gutter,
                      t.space12,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: EnjoySectionHeader(
                        title: l10n.homeRecentMedia,
                        trailing: TextButton.icon(
                          onPressed: () => context.go('/library'),
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(EnjoyIcons.chevronRight, size: 14),
                          label: Text(l10n.libraryTitle),
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        return SliverGrid(
                          gridDelegate:
                              mediaCardTileGridDelegateForMinTileWidth(
                                crossAxisExtent: constraints.crossAxisExtent,
                                mainAxisSpacing: t.space16,
                                crossAxisSpacing: t.space16,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final m = recent[index];
                              return Align(
                                key: ValueKey<String>('home-media-${m.id}'),
                                alignment: Alignment.topCenter,
                                child: _HomeMediaTile(media: m),
                              );
                            },
                            childCount: recent.length,
                            findChildIndexCallback: (key) =>
                                findSliverIndexByPrefixedId(
                                  items: recent,
                                  key: key,
                                  prefix: 'home-media-',
                                  idOf: (m) => m.id,
                                ),
                          ),
                        );
                      },
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: t.space40)),
                ],
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
                    Icon(EnjoyIcons.error, size: 48, color: cs.error),
                    SizedBox(height: t.space16),
                    Text(
                      '${l10n.error}: $e',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: t.space16),
                    EnjoyButton.tonal(
                      onPressed: () =>
                          ref.invalidate(libraryHomeRecentsProvider),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Home layout while [libraryHomeRecentsProvider] has not emitted yet — mirrors the
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

    return SkeletonTickerHost(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = pageGutterOf(context, constraints.maxWidth);
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _HomeHeader()),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  t.space12,
                  gutter,
                  t.space12,
                ),
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
                        mainAxisSpacing: t.space16,
                        crossAxisSpacing: t.space16,
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
          );
        },
      ),
    );
  }
}

/// Home editorial header — a time-of-day greeting under a date overline,
/// with the Craft + Import actions (icon-only on narrow panes). Shared by the
/// loaded and loading scroll views so both stay in sync.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? l10n.homeGreetingMorning
        : now.hour < 18
        ? l10n.homeGreetingAfternoon
        : l10n.homeGreetingEvening;
    final name = ref.watch(
      authCtrlProvider.select(
        (a) => a.maybeWhen(
          data: (s) => s is AuthSignedIn ? s.profile.name.trim() : null,
          orElse: () => null,
        ),
      ),
    );
    final firstName = (name == null || name.isEmpty)
        ? null
        : name.split(RegExp(r'\s+')).first;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return EditorialHeader(
      overline: DateFormat.MMMMEEEEd(locale).format(now),
      title: firstName == null
          ? greeting
          : l10n.homeGreetingNamed(greeting, firstName),
      trailing: _HomeHeaderActions(
        onCraft: () => context.push('/craft'),
        onImport: () => showImportChooser(context, ref),
      ),
    );
  }
}

/// Home header trailing actions — Craft entry + Import.
class _HomeHeaderActions extends ConsumerWidget {
  const _HomeHeaderActions({required this.onCraft, required this.onImport});

  final VoidCallback onCraft;
  final VoidCallback onImport;

  void _act(WidgetRef ref, OnboardingTipId tip, VoidCallback action) {
    unawaited(
      ref.read(onboardingControllerProvider.notifier).onTargetActed(tip),
    );
    action();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final narrow = MediaQuery.sizeOf(context).width < t.breakpointCompact;
    void craft() => _act(ref, OnboardingTipId.homeCraft, onCraft);
    void import() => _act(ref, OnboardingTipId.homeImport, onImport);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OnboardingTarget(
          tipId: OnboardingTipId.homeCraft,
          onTargetAction: onCraft,
          child: narrow
              ? EnjoyIconButton(
                  icon: EnjoyIcons.sparkle,
                  tooltip: l10n.homeCraftAction,
                  onPressed: craft,
                )
              : EnjoyButton.secondary(
                  size: EnjoyButtonSize.small,
                  icon: EnjoyIcons.sparkle,
                  onPressed: craft,
                  child: Text(l10n.homeCraftAction),
                ),
        ),
        SizedBox(width: t.space8),
        OnboardingTarget(
          tipId: OnboardingTipId.homeImport,
          onTargetAction: onImport,
          child: narrow
              ? EnjoyIconButton(
                  icon: EnjoyIcons.add,
                  tooltip: l10n.actionImport,
                  variant: EnjoyButtonVariant.brand,
                  onPressed: import,
                )
              : EnjoyButton.brand(
                  size: EnjoyButtonSize.small,
                  icon: EnjoyIcons.add,
                  onPressed: import,
                  child: Text(l10n.actionImport),
                ),
        ),
      ],
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

class _HomeInsightCards extends ConsumerWidget {
  const _HomeInsightCards();

  static const double _kStripSplitMinWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(authIsSignedInProvider);

    if (!isSignedIn) return const SizedBox.shrink();
    final t = EnjoyThemeTokens.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _kStripSplitMinWidth;
        final gutter = pageGutterOf(context, constraints.maxWidth);
        final pad = EdgeInsets.fromLTRB(gutter, t.space4, gutter, t.space16);

        const goal = TodaysGoalCard(variant: TodaysGoalCardVariant.bar);
        const community = CommunityActivityCard(outerPadding: EdgeInsets.zero);

        final strip = wide
            ? const IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: goal),
                    SizedBox(width: 16),
                    Expanded(flex: 4, child: community),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  goal,
                  SizedBox(height: t.space12),
                  community,
                ],
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
    final isVideo = media.kind == MediaKind.video;
    final thumb = ref
        .watch(localThumbnailFileProvider(localThumbnailPathForMedia(media)))
        .value;
    final netThumb = networkThumbnailForMedia(media);
    final dur = formatDurationHmsMs(media.durationMs);
    final accent = generativeAccentForSeed(media.coverSeed);

    return MediaCardTile(
      title: media.title,
      subtitle: isVideo
          ? l10n.miniPlayerMediaVideo
          : '${l10n.miniPlayerMediaAudio} · $dur',
      badge: focusLanguageLabel(l10n, media.language),
      onBadgeTap: () => editMediaLanguage(context, ref, media),
      durationLabel: isVideo && media.durationMs > 0 ? dur : null,
      thumbnailFile: thumb,
      providerBadge: media.provider == 'youtube'
          ? l10n.youtubeBadge
          : media.provider == 'craft'
          ? l10n.libraryProviderCraftBadge
          : null,
      cloudSyncBadge: resolveMediaCardSyncBadge(
        provider: media.provider,
        mediaUrl: media.mediaUrl,
        syncStatus: media.syncStatus,
      ),
      thumbnailNetworkUrl: netThumb,
      coverSeed: media.coverSeed,
      isVideo: isVideo,
      accentColor: accent,
      heroArtworkMediaId: media.id,
      deleteTooltip: l10n.libraryDeleteMediaTooltip,
      onDelete: () => confirmAndDeleteMedia(context, ref, media),
      onTap: () {
        warmYoutubeSurfaceIfNeeded(ref, provider: media.provider);
        openPlayerRoute(context, media.id);
      },
    );
  }
}
