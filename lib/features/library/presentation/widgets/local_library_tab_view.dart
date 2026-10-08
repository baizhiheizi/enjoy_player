/// Local Drift library lists (audio rows / video grid).
library;

import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/core/presentation/relative_day_label.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/theme/widgets/media_card/media_card_sync_badge.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/application/library_search_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/library/presentation/library_actions.dart';
import 'package:enjoy_player/features/player/application/local_thumbnail_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/youtube_warm.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Tab bodies for local library media, driven by a shared [TabController].
class LocalLibraryTabView extends ConsumerWidget {
  const LocalLibraryTabView({required this.tabController, super.key});

  final TabController tabController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(libraryFilteredListsProvider);
    final counts = ref.watch(libraryKindCountsProvider).asData?.value;
    final query = ref.watch(librarySearchProvider);
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return listsAsync.when(
      data: (lists) {
        return TabBarView(
          controller: tabController,
          children: [
            LocalVideoLibraryBody(
              items: lists.video,
              searchQuery: query,
              totalInLibraryOfKind: counts?.video ?? 0,
            ),
            LocalAudioLibraryBody(
              items: lists.audio,
              searchQuery: query,
              totalInLibraryOfKind: counts?.audio ?? 0,
            ),
          ],
        );
      },
      loading: () => TabBarView(
        controller: tabController,
        children: const [SkeletonMediaGrid(), SkeletonMediaList()],
      ),
      error: (e, _) => Center(
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
                onPressed: () => ref.invalidate(libraryFilteredListsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LocalAudioLibraryBody extends StatelessWidget {
  const LocalAudioLibraryBody({
    required this.items,
    required this.searchQuery,
    required this.totalInLibraryOfKind,
    super.key,
  });

  final List<Media> items;
  final String searchQuery;
  final int totalInLibraryOfKind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    if (items.isEmpty) {
      final filteredBySearch =
          searchQuery.isNotEmpty && totalInLibraryOfKind > 0;
      if (filteredBySearch) {
        return EmptyState(
          title: l10n.librarySearchNoMatchesTitle,
          subtitle: l10n.librarySearchNoMatchesHint,
          action: () {
            final notifier = ProviderScope.containerOf(
              context,
            ).read(librarySearchProvider.notifier);
            notifier.clear();
          },
          actionLabel: l10n.librarySearchClear,
        );
      }
      return EmptyState(
        title: l10n.libraryEmptyAudioTitle,
        subtitle: l10n.libraryEmptyAudioHint,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = libraryBodyInset(context, constraints.maxWidth);
        return CustomScrollView(
          slivers: [
            if (searchQuery.isNotEmpty)
              LibrarySearchResultLine(
                count: items.length,
                query: searchQuery,
                inset: inset,
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, t.space4, inset, t.space32),
              sliver: DecoratedSliver(
                decoration: ShapeDecoration(
                  color: t.paper,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(t.radiusCard),
                    side: BorderSide(color: t.line),
                  ),
                ),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, _) =>
                      Divider(height: 1, thickness: 1, color: t.line),
                  itemBuilder: (context, index) =>
                      LocalAudioRow(media: items[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Browse-column inset for library bodies (matches the page header).
double libraryBodyInset(BuildContext context, double paneWidth) =>
    EnjoyPageMetrics.of(
      context,
      kind: EnjoyPageKind.browse,
      paneWidth: paneWidth,
    ).horizontalInset;

/// "2 matches for “ferry”" above search results.
class LibrarySearchResultLine extends StatelessWidget {
  const LibrarySearchResultLine({
    super.key,
    required this.count,
    required this.query,
    required this.inset,
  });

  final int count;
  final String query;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(inset, 2, inset, 14),
      sliver: SliverToBoxAdapter(
        child: Text(
          l10n.librarySearchResults(count, query),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontSize: 13, color: t.ink3),
        ),
      ),
    );
  }
}

class LocalAudioRow extends ConsumerWidget {
  const LocalAudioRow({required this.media, super.key});

  final Media media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final playingId = ref.watch(
      playerControllerProvider.select((s) => s?.mediaId),
    );
    final thumb = ref
        .watch(
          localThumbnailFileProvider(
            localThumbnailPathForCard(media.thumbnailPath),
          ),
        )
        .value;
    final netThumb = remoteThumbnailForCard(media.thumbnailPath);
    final dur = formatDurationHmsMs(media.durationMs);
    final accent = generativeAccentForSeed(media.coverSeed);

    final locale = Localizations.localeOf(context).toLanguageTag();

    return MediaCardRow(
      title: media.title,
      subtitle: l10n.libraryTileAdded(
        relativeDayLabel(l10n, locale, media.createdAt),
      ),
      language: languageCodeLabel(media.language),
      onLanguageTap: () => editMediaLanguage(context, ref, media),
      durationLabel: media.durationMs > 0 ? dur : null,
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
      thumbnailFile: thumb,
      thumbnailNetworkUrl: netThumb,
      coverSeed: media.coverSeed,
      isVideo: false,
      accentColor: accent,
      heroArtworkMediaId: playingId == media.id ? null : media.id,
      deleteTooltip: l10n.libraryDeleteMediaTooltip,
      onDelete: () => confirmAndDeleteMedia(context, ref, media),
      onTap: () {
        warmYoutubeSurfaceIfNeeded(ref, provider: media.provider);
        openPlayerRoute(context, media.id);
      },
    );
  }
}

class LocalVideoLibraryBody extends StatelessWidget {
  const LocalVideoLibraryBody({
    required this.items,
    required this.searchQuery,
    required this.totalInLibraryOfKind,
    super.key,
  });

  final List<Media> items;
  final String searchQuery;
  final int totalInLibraryOfKind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    if (items.isEmpty) {
      final filteredBySearch =
          searchQuery.isNotEmpty && totalInLibraryOfKind > 0;
      if (filteredBySearch) {
        return EmptyState(
          title: l10n.librarySearchNoMatchesTitle,
          subtitle: l10n.librarySearchNoMatchesHint,
          action: () {
            final notifier = ProviderScope.containerOf(
              context,
            ).read(librarySearchProvider.notifier);
            notifier.clear();
          },
          actionLabel: l10n.librarySearchClear,
        );
      }
      return EmptyState(
        title: l10n.libraryEmptyVideoTitle,
        subtitle: l10n.libraryEmptyVideoHint,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = libraryBodyInset(context, constraints.maxWidth);
        final crossAxisExtent = constraints.maxWidth - inset * 2;
        return CustomScrollView(
          slivers: [
            if (searchQuery.isNotEmpty)
              LibrarySearchResultLine(
                count: items.length,
                query: searchQuery,
                inset: inset,
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, t.space4, inset, t.space32),
              sliver: SliverGrid(
                gridDelegate: mediaCardTileGridDelegateForMinTileWidth(
                  crossAxisExtent: crossAxisExtent,
                  minTileWidth: _kLibraryTileMinWidth,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 20,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Align(
                    alignment: Alignment.topCenter,
                    child: LocalVideoTile(media: items[index]),
                  ),
                  childCount: items.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

const double _kLibraryTileMinWidth = 210;

class LocalVideoTile extends ConsumerWidget {
  const LocalVideoTile({required this.media, super.key});

  final Media media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final playingId = ref.watch(
      playerControllerProvider.select((s) => s?.mediaId),
    );
    final thumb = ref
        .watch(localThumbnailFileProvider(localThumbnailPathForMedia(media)))
        .value;
    final netThumb = networkThumbnailForMedia(media);
    final dur = formatDurationHmsMs(media.durationMs);
    final accent = generativeAccentForSeed(media.coverSeed);

    final locale = Localizations.localeOf(context).toLanguageTag();

    return MediaCardTile(
      title: media.title,
      subtitle: l10n.libraryTileAdded(
        relativeDayLabel(l10n, locale, media.createdAt),
      ),
      language: languageCodeLabel(media.language),
      languagePlacement: MediaCardLanguagePlacement.title,
      onLanguageTap: () => editMediaLanguage(context, ref, media),
      durationLabel: media.durationMs > 0 ? dur : null,
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
      isVideo: true,
      accentColor: accent,
      heroArtworkMediaId: playingId == media.id ? null : media.id,
      deleteTooltip: l10n.libraryDeleteMediaTooltip,
      onDelete: () => confirmAndDeleteMedia(context, ref, media),
      onTap: () {
        warmYoutubeSurfaceIfNeeded(ref, provider: media.provider);
        openPlayerRoute(context, media.id);
      },
    );
  }
}
