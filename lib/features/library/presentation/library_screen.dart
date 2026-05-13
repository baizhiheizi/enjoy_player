/// Library: editorial header, audio list / video grid with MediaCard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/library_media_provider.dart';
import '../domain/media.dart';
import 'library_actions.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(libraryFilteredListsProvider);
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: listsAsync.when(
        data: (lists) {
          final audioItems = lists.audio;
          final videoItems = lists.video;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Editorial header
              EditorialHeader(
                title: l10n.libraryTitle,
                trailing: FilledButton.icon(
                  onPressed: () => showImportChooser(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.actionImport),
                ),
              ),

              // Tab segment
              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.space24,
                  0,
                  t.space24,
                  t.space12,
                ),
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    return SegmentedButton<String>(
                      style: SegmentedButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: cs.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        ),
                        foregroundColor: cs.onSurfaceVariant,
                        selectedForegroundColor: cs.onPrimaryContainer,
                        selectedBackgroundColor: cs.primaryContainer.withValues(
                          alpha: 0.65,
                        ),
                        side: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(t.radiusFull),
                        ),
                        textStyle: tt.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      showSelectedIcon: false,
                      emptySelectionAllowed: false,
                      segments: [
                        ButtonSegment<String>(
                          value: 'audio',
                          icon: const Icon(Icons.graphic_eq_rounded, size: 16),
                          label: Text(l10n.libraryTabAudio),
                        ),
                        ButtonSegment<String>(
                          value: 'video',
                          icon: const Icon(Icons.movie_outlined, size: 16),
                          label: Text(l10n.libraryTabVideo),
                        ),
                      ],
                      selected: {_tabController.index == 0 ? 'audio' : 'video'},
                      onSelectionChanged: (next) {
                        final v = next.single;
                        final i = v == 'audio' ? 0 : 1;
                        if (_tabController.index != i) {
                          _tabController.animateTo(i);
                        }
                      },
                    );
                  },
                ),
              ),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _AudioLibraryBody(items: audioItems),
                    _VideoLibraryBody(items: videoItems),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const SkeletonMediaList(),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(t.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
                SizedBox(height: t.space16),
                Text(
                  '${l10n.error}: $e',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: t.space16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(libraryFilteredListsProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Audio tab ───────────────────────────────────────────────────────────────

class _AudioLibraryBody extends StatelessWidget {
  const _AudioLibraryBody({required this.items});

  final List<Media> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.graphic_eq_rounded,
        illustrationAsset: EnjoyIllustrations.emptyLibrary,
        title: l10n.libraryEmptyAudioTitle,
        subtitle: l10n.libraryEmptyAudioHint,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(t.space16, t.space8, t.space16, t.space24),
      itemCount: items.length,
      separatorBuilder: (context, _) => SizedBox(height: t.space8),
      itemBuilder: (context, index) {
        final m = items[index];
        return _AudioRow(media: m);
      },
    );
  }
}

class _AudioRow extends ConsumerWidget {
  const _AudioRow({required this.media});

  final Media media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final playingId = ref.watch(
      playerControllerProvider.select((s) => s?.mediaId),
    );
    final thumb = localThumbnailFileForCard(media.thumbnailPath);
    final netThumb = remoteThumbnailForCard(media.thumbnailPath);
    final dur = formatDurationHms(Duration(milliseconds: media.durationMs));
    // See `_HomeMediaTile` for rationale: per-tile palette extraction stalls
    // the main isolate when many cards mount at once.
    final accent = generativeAccentForSeed(media.coverSeed);

    return MediaCardRow(
      title: media.title,
      subtitle: dur,
      badge: media.language,
      providerBadge: media.provider == 'youtube' ? l10n.youtubeBadge : null,
      thumbnailFile: thumb,
      thumbnailNetworkUrl: netThumb,
      coverSeed: media.coverSeed,
      isVideo: false,
      accentColor: accent,
      heroArtworkMediaId: playingId == media.id ? null : media.id,
      deleteTooltip: l10n.libraryDeleteMediaTooltip,
      onDelete: () => confirmAndDeleteMedia(context, ref, media),
      onTap: () => openPlayerRoute(context, media.id),
    );
  }
}

// ── Video tab ───────────────────────────────────────────────────────────────

class _VideoLibraryBody extends StatelessWidget {
  const _VideoLibraryBody({required this.items});

  final List<Media> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.movie_outlined,
        illustrationAsset: EnjoyIllustrations.emptyRecordings,
        title: l10n.libraryEmptyVideoTitle,
        subtitle: l10n.libraryEmptyVideoHint,
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(t.space16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 16 / 11.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _VideoTile(media: items[index]),
    );
  }
}

class _VideoTile extends ConsumerWidget {
  const _VideoTile({required this.media});

  final Media media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final playingId = ref.watch(
      playerControllerProvider.select((s) => s?.mediaId),
    );
    final thumb = localThumbnailFileForCard(media.thumbnailPath);
    final netThumb = remoteThumbnailForCard(media.thumbnailPath);
    final dur = formatDurationHms(Duration(milliseconds: media.durationMs));
    // See `_HomeMediaTile` for rationale: per-tile palette extraction stalls
    // the main isolate when many cards mount at once.
    final accent = generativeAccentForSeed(media.coverSeed);

    return MediaCardTile(
      title: media.title,
      subtitle: '${l10n.miniPlayerMediaVideo} · $dur',
      thumbnailFile: thumb,
      providerBadge: media.provider == 'youtube' ? l10n.youtubeBadge : null,
      thumbnailNetworkUrl: netThumb,
      coverSeed: media.coverSeed,
      isVideo: true,
      accentColor: accent,
      heroArtworkMediaId: playingId == media.id ? null : media.id,
      deleteTooltip: l10n.libraryDeleteMediaTooltip,
      onDelete: () => confirmAndDeleteMedia(context, ref, media),
      onTap: () => openPlayerRoute(context, media.id),
    );
  }
}
