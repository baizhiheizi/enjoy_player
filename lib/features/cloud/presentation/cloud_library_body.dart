/// Remote cloud index tab bodies (paginated audio / video).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/cloud/application/cloud_providers.dart';
import 'package:enjoy_player/features/cloud/data/cloud_index_repository.dart';
import 'package:enjoy_player/features/cloud/domain/remote_library_item.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Paginated cloud catalog mounted inside the unified Library shell.
class CloudLibraryBody extends ConsumerStatefulWidget {
  const CloudLibraryBody({required this.tabController, super.key});

  final TabController tabController;

  @override
  ConsumerState<CloudLibraryBody> createState() => CloudLibraryBodyState();
}

class CloudLibraryBodyState extends ConsumerState<CloudLibraryBody> {
  final _audios = _CloudPagedList();
  final _videos = _CloudPagedList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadInitial());
    });
  }

  Future<void> _loadInitial() async {
    await Future.wait([
      _loadAudioPage(reset: true),
      _loadVideoPage(reset: true),
    ]);
  }

  Future<void> _loadAudioPage({required bool reset}) {
    return _loadPage(
      page: _audios,
      reset: reset,
      fetch: (cursor) => ref
          .read(cloudIndexRepositoryProvider)
          .fetchAudios(updatedAfter: cursor),
    );
  }

  Future<void> _loadVideoPage({required bool reset}) {
    return _loadPage(
      page: _videos,
      reset: reset,
      fetch: (cursor) => ref
          .read(cloudIndexRepositoryProvider)
          .fetchVideos(updatedAfter: cursor),
    );
  }

  Future<void> _loadPage({
    required _CloudPagedList page,
    required bool reset,
    required Future<List<RemoteLibraryItem>> Function(String? cursor) fetch,
  }) async {
    final auth = ref.read(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) return;
    await page.load(
      reset: reset,
      isMounted: () => mounted,
      setState: setState,
      fetch: fetch,
    );
  }

  /// Refreshes the video or audio tab matching [tabController.index].
  void refreshActiveTab() {
    if (widget.tabController.index == 0) {
      unawaited(_loadVideoPage(reset: true));
    } else {
      unawaited(_loadAudioPage(reset: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authCtrlProvider);

    return auth.when(
      data: (state) {
        if (state is! AuthSignedIn) {
          return const Center(
            child: AuthRequiredCallout(
              surface: AuthRequiredSurface.cloud,
              compact: false,
            ),
          );
        }
        return TabBarView(
          controller: widget.tabController,
          children: [
            _CloudVideoGrid(
              items: _videos.items,
              loading: _videos.loading,
              done: _videos.done,
              onLoadMore: () => _loadVideoPage(reset: false),
              onRefresh: () => _loadVideoPage(reset: true),
            ),
            _CloudAudioList(
              items: _audios.items,
              loading: _audios.loading,
              done: _audios.done,
              onLoadMore: () => _loadAudioPage(reset: false),
              onRefresh: () => _loadAudioPage(reset: true),
            ),
          ],
        );
      },
      loading: () => const SkeletonMediaList(),
      error: (e, _) => Center(child: Text(l10n.errorGenericLoadFailed)),
    );
  }
}

String _coverSeed(RemoteLibraryItem item) {
  final m = item.md5?.trim();
  if (m != null && m.isNotEmpty) return m;
  return item.id;
}

/// Cursor + loading state for one cloud catalog tab.
class _CloudPagedList {
  final List<RemoteLibraryItem> items = [];
  String? cursor;
  bool loading = false;
  bool done = false;

  Future<void> load({
    required bool reset,
    required bool Function() isMounted,
    required void Function(VoidCallback fn) setState,
    required Future<List<RemoteLibraryItem>> Function(String? cursor) fetch,
  }) async {
    if (loading || done && !reset) return;
    setState(() => loading = true);
    try {
      if (reset) {
        items.clear();
        cursor = null;
        done = false;
      }
      final batch = await fetch(cursor);
      if (!isMounted()) return;
      setState(() {
        items.addAll(batch);
        if (batch.isEmpty) {
          done = true;
        } else {
          cursor = batch.last.rawJson['updatedAt']?.toString();
          if (batch.length < CloudIndexRepository.pageSize) {
            done = true;
          }
        }
      });
    } finally {
      if (isMounted()) setState(() => loading = false);
    }
  }
}

/// Shared "is in library / add to library" state for cloud list/grid tiles.
mixin _CloudItemMembershipMixin<W extends ConsumerStatefulWidget>
    on ConsumerState<W> {
  bool? _inLibrary;
  bool _busy = false;

  RemoteLibraryItem get cloudItem;

  Future<void> loadMembership() async {
    final v = await ref.read(cloudAddToLibraryProvider).isInLibrary(cloudItem);
    if (mounted) setState(() => _inLibrary = v);
  }

  Future<void> addToLibrary() async {
    final l10n = AppLocalizations.of(context)!;
    final add = ref.read(cloudAddToLibraryProvider);
    setState(() => _busy = true);
    try {
      await add.add(cloudItem);
      ref.invalidate(libraryMediaProvider);
      ref.invalidate(libraryHomeRecentsProvider);
      ref.invalidate(libraryFilteredListsProvider);
      if (!mounted) return;
      setState(() {
        _inLibrary = true;
        _busy = false;
      });
      AppNotice.success(context, l10n.cloudAddedToLibrary);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _CloudAudioList extends ConsumerStatefulWidget {
  const _CloudAudioList({
    required this.items,
    required this.loading,
    required this.done,
    required this.onLoadMore,
    required this.onRefresh,
  });

  final List<RemoteLibraryItem> items;
  final bool loading;
  final bool done;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_CloudAudioList> createState() => _CloudAudioListState();
}

class _CloudAudioListState extends ConsumerState<_CloudAudioList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.done &&
        !widget.loading &&
        _scroll.hasClients &&
        _scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
      unawaited(widget.onLoadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    if (widget.items.isEmpty && widget.loading) {
      return const SkeletonMediaList();
    }

    if (widget.items.isEmpty && widget.done) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: EmptyState(
              icon: Icons.graphic_eq_rounded,
              illustrationAsset: EnjoyIllustrations.emptyCloud,
              title: l10n.cloudEmptyAudioTitle,
              subtitle: l10n.cloudEmptyAudioSubtitle,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(t.space16, t.space8, t.space16, t.space24),
        itemCount: widget.items.length + 1,
        separatorBuilder: (_, _) => SizedBox(height: t.space8),
        itemBuilder: (context, index) {
          if (index == widget.items.length) {
            if (widget.loading) {
              return Padding(
                padding: EdgeInsets.all(t.space16),
                child: Center(child: Skeleton.circle(diameter: 28)),
              );
            }
            return const SizedBox.shrink();
          }
          return _CloudAudioRow(item: widget.items[index]);
        },
      ),
    );
  }
}

class _CloudAudioRow extends ConsumerStatefulWidget {
  const _CloudAudioRow({required this.item});

  final RemoteLibraryItem item;

  @override
  ConsumerState<_CloudAudioRow> createState() => _CloudAudioRowState();
}

class _CloudAudioRowState extends ConsumerState<_CloudAudioRow>
    with _CloudItemMembershipMixin {
  @override
  RemoteLibraryItem get cloudItem => widget.item;

  @override
  void initState() {
    super.initState();
    unawaited(loadMembership());
  }

  @override
  Widget build(BuildContext context) {
    final playingId = ref.watch(
      playerControllerProvider.select((s) => s?.mediaId),
    );
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final dur = formatDurationHmsSeconds(widget.item.durationSeconds);
    final item = widget.item;
    final seed = _coverSeed(item);
    final accent = generativeAccentForSeed(seed);

    Widget? trailing;
    if (_busy) {
      trailing = const LoadingIcon(size: 22);
    } else if (_inLibrary == true) {
      trailing = Icon(Icons.check_circle_rounded, color: cs.primary, size: 22);
    } else {
      trailing = IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 22,
        tooltip: l10n.cloudAddToLibraryTooltip,
        icon: Icon(Icons.library_add_outlined, color: cs.onSurfaceVariant),
        onPressed: () => unawaited(addToLibrary()),
      );
    }

    return MediaCardRow(
      title: item.title,
      subtitle: dur,
      badge: item.language,
      thumbnailFile: null,
      thumbnailNetworkUrl: remoteThumbnailForCard(
        item.thumbnailUrl,
        youtubeVideoId: item.provider == 'youtube' ? item.md5 : null,
        mediaUrl: item.mediaUrl,
      ),
      coverSeed: seed,
      isVideo: false,
      accentColor: accent,
      heroArtworkMediaId: _inLibrary == true && playingId != item.id
          ? item.id
          : null,
      trailing: trailing,
      providerBadge: item.provider == 'youtube' ? l10n.youtubeBadge : null,
      onTap: () {
        if (_inLibrary == true) {
          openPlayerRoute(context, item.id);
        }
      },
    );
  }
}

class _CloudVideoGrid extends ConsumerStatefulWidget {
  const _CloudVideoGrid({
    required this.items,
    required this.loading,
    required this.done,
    required this.onLoadMore,
    required this.onRefresh,
  });

  final List<RemoteLibraryItem> items;
  final bool loading;
  final bool done;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_CloudVideoGrid> createState() => _CloudVideoGridState();
}

class _CloudVideoGridState extends ConsumerState<_CloudVideoGrid> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.done &&
        !widget.loading &&
        _scroll.hasClients &&
        _scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
      unawaited(widget.onLoadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    if (widget.items.isEmpty && widget.loading) {
      return const SkeletonMediaGrid();
    }

    if (widget.items.isEmpty && widget.done) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: EmptyState(
              icon: Icons.movie_outlined,
              illustrationAsset: EnjoyIllustrations.emptyCloud,
              title: l10n.cloudEmptyVideoTitle,
              subtitle: l10n.cloudEmptyVideoSubtitle,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisExtent = constraints.maxWidth - t.space16 * 2;
          return GridView.builder(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(t.space16),
            gridDelegate: mediaCardTileGridDelegateForMaxTileWidth(
              crossAxisExtent: crossAxisExtent,
            ),
            itemCount:
                widget.items.length + (widget.loading && !widget.done ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= widget.items.length) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(t.space24),
                    child: Skeleton.circle(diameter: 32),
                  ),
                );
              }
              return Align(
                alignment: Alignment.topCenter,
                child: _CloudVideoTile(item: widget.items[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _CloudVideoTile extends ConsumerStatefulWidget {
  const _CloudVideoTile({required this.item});

  final RemoteLibraryItem item;

  @override
  ConsumerState<_CloudVideoTile> createState() => _CloudVideoTileState();
}

class _CloudVideoTileState extends ConsumerState<_CloudVideoTile>
    with _CloudItemMembershipMixin {
  @override
  RemoteLibraryItem get cloudItem => widget.item;

  @override
  void initState() {
    super.initState();
    unawaited(loadMembership());
  }

  @override
  Widget build(BuildContext context) {
    final playingId = ref.watch(
      playerControllerProvider.select((s) => s?.mediaId),
    );
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final dur = formatDurationHmsSeconds(widget.item.durationSeconds);
    final item = widget.item;
    final seed = _coverSeed(item);
    final accent = generativeAccentForSeed(seed);

    Widget cornerChip(Widget child) {
      return Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(width: 36, height: 36, child: Center(child: child)),
      );
    }

    Widget overlay;
    if (_busy) {
      overlay = cornerChip(LoadingIcon(size: 20, color: cs.onSurfaceVariant));
    } else if (_inLibrary == true) {
      overlay = cornerChip(
        Icon(Icons.check_circle_rounded, color: cs.primary, size: 22),
      );
    } else {
      overlay = IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 20,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        tooltip: l10n.cloudAddToLibraryTooltip,
        style: IconButton.styleFrom(
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.92),
          foregroundColor: cs.onSurfaceVariant,
          shape: const CircleBorder(),
        ),
        icon: const Icon(Icons.library_add_outlined),
        onPressed: () => unawaited(addToLibrary()),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        MediaCardTile(
          title: item.title,
          subtitle: l10n.miniPlayerMediaVideo,
          durationLabel: item.durationSeconds > 0 ? dur : null,
          thumbnailFile: null,
          thumbnailNetworkUrl: remoteThumbnailForCard(
            item.thumbnailUrl,
            youtubeVideoId: item.provider == 'youtube' ? item.md5 : null,
            mediaUrl: item.mediaUrl,
          ),
          coverSeed: seed,
          isVideo: true,
          accentColor: accent,
          heroArtworkMediaId: _inLibrary == true && playingId != item.id
              ? item.id
              : null,
          providerBadge: item.provider == 'youtube' ? l10n.youtubeBadge : null,
          onTap: () {
            if (_inLibrary == true) {
              openPlayerRoute(context, item.id);
            }
          },
        ),
        Positioned(top: 8, right: 8, child: overlay),
      ],
    );
  }
}
