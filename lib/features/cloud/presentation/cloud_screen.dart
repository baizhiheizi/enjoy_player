/// Browse remote audio/video metadata and copy selected rows into the local library.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/cloud/application/cloud_providers.dart';
import 'package:enjoy_player/features/cloud/data/cloud_index_repository.dart';
import 'package:enjoy_player/features/cloud/domain/remote_library_item.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class CloudScreen extends ConsumerStatefulWidget {
  const CloudScreen({super.key});

  @override
  ConsumerState<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends ConsumerState<CloudScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<RemoteLibraryItem> _audios = [];
  final List<RemoteLibraryItem> _videos = [];
  String? _audioCursor;
  String? _videoCursor;
  bool _loadingAudio = false;
  bool _loadingVideo = false;
  bool _audioDone = false;
  bool _videoDone = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await Future.wait([
      _loadAudioPage(reset: true),
      _loadVideoPage(reset: true),
    ]);
  }

  Future<void> _loadAudioPage({required bool reset}) async {
    if (_loadingAudio || _audioDone && !reset) return;
    final auth = ref.read(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) return;

    setState(() => _loadingAudio = true);
    try {
      if (reset) {
        _audios.clear();
        _audioCursor = null;
        _audioDone = false;
      }
      final repo = ref.read(cloudIndexRepositoryProvider);
      final batch = await repo.fetchAudios(updatedAfter: _audioCursor);
      if (!mounted) return;
      setState(() {
        _audios.addAll(batch);
        if (batch.isEmpty) {
          _audioDone = true;
        } else {
          final last = batch.last.rawJson['updatedAt']?.toString();
          _audioCursor = last;
          if (batch.length < CloudIndexRepository.pageSize) {
            _audioDone = true;
          }
        }
      });
    } finally {
      if (mounted) setState(() => _loadingAudio = false);
    }
  }

  Future<void> _loadVideoPage({required bool reset}) async {
    if (_loadingVideo || _videoDone && !reset) return;
    final auth = ref.read(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) return;

    setState(() => _loadingVideo = true);
    try {
      if (reset) {
        _videos.clear();
        _videoCursor = null;
        _videoDone = false;
      }
      final repo = ref.read(cloudIndexRepositoryProvider);
      final batch = await repo.fetchVideos(updatedAfter: _videoCursor);
      if (!mounted) return;
      setState(() {
        _videos.addAll(batch);
        if (batch.isEmpty) {
          _videoDone = true;
        } else {
          final last = batch.last.rawJson['updatedAt']?.toString();
          _videoCursor = last;
          if (batch.length < CloudIndexRepository.pageSize) {
            _videoDone = true;
          }
        }
      });
    } finally {
      if (mounted) setState(() => _loadingVideo = false);
    }
  }

  void _refreshActiveTab() {
    if (_tabController.index == 0) {
      _loadAudioPage(reset: true);
    } else {
      _loadVideoPage(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = ref.watch(authCtrlProvider);

    return Scaffold(
      body: auth.when(
        data: (state) {
          if (state is! AuthSignedIn) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(t.space24),
                child: Text(
                  l10n.cloudSignedOutBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EditorialHeader(
                title: l10n.cloudScreenTitle,
                trailing: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  tooltip: l10n.cloudRefreshTooltip,
                  onPressed: _refreshActiveTab,
                ),
              ),
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
                          label: Text(l10n.cloudTabAudio),
                        ),
                        ButtonSegment<String>(
                          value: 'video',
                          icon: const Icon(Icons.movie_outlined, size: 16),
                          label: Text(l10n.cloudTabVideo),
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
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CloudAudioList(
                      items: _audios,
                      loading: _loadingAudio,
                      done: _audioDone,
                      onLoadMore: () => _loadAudioPage(reset: false),
                      onRefresh: () => _loadAudioPage(reset: true),
                    ),
                    _CloudVideoGrid(
                      items: _videos,
                      loading: _loadingVideo,
                      done: _videoDone,
                      onLoadMore: () => _loadVideoPage(reset: false),
                      onRefresh: () => _loadVideoPage(reset: true),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

String _coverSeed(RemoteLibraryItem item) {
  final m = item.md5?.trim();
  if (m != null && m.isNotEmpty) return m;
  return item.id;
}

// ── Audio tab ───────────────────────────────────────────────────────────────

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
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    if (widget.items.isEmpty && widget.loading) {
      return const Center(child: CircularProgressIndicator());
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
        padding: EdgeInsets.fromLTRB(
          t.space16,
          t.space8,
          t.space16,
          t.space24,
        ),
        itemCount: widget.items.length + 1,
        separatorBuilder: (_, _) => SizedBox(height: t.space8),
        itemBuilder: (context, index) {
          if (index == widget.items.length) {
            if (widget.loading) {
              return Padding(
                padding: EdgeInsets.all(t.space16),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            if (widget.done) {
              return const SizedBox.shrink();
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

class _CloudAudioRowState extends ConsumerState<_CloudAudioRow> {
  bool? _inLibrary;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await ref.read(cloudAddToLibraryProvider).isInLibrary(widget.item);
    if (mounted) setState(() => _inLibrary = v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final add = ref.watch(cloudAddToLibraryProvider);
    final dur = formatDurationHms(
      Duration(seconds: widget.item.durationSeconds),
    );
    final item = widget.item;
    final seed = _coverSeed(item);
    final accent = generativeAccentForSeed(seed);

    Widget? trailing;
    if (_busy) {
      trailing = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (_inLibrary == true) {
      trailing = Icon(
        Icons.check_circle_rounded,
        color: cs.primary,
        size: 22,
      );
    } else {
      trailing = IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 22,
        tooltip: l10n.cloudAddToLibraryTooltip,
        icon: Icon(Icons.library_add_outlined, color: cs.onSurfaceVariant),
        onPressed: () async {
          setState(() => _busy = true);
          try {
            await add.add(item);
            ref.invalidate(libraryMediaProvider);
            if (!context.mounted) return;
            setState(() {
              _inLibrary = true;
              _busy = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.cloudAddedToLibrary)),
            );
          } catch (_) {
            if (mounted) setState(() => _busy = false);
          }
        },
      );
    }

    return MediaCardRow(
      title: item.title,
      subtitle: dur,
      badge: item.language,
      thumbnailFile: null,
      thumbnailNetworkUrl: remoteThumbnailForCard(item.thumbnailUrl),
      coverSeed: seed,
      isVideo: false,
      accentColor: accent,
      trailing: trailing,
      onTap: () {
        if (_inLibrary == true) {
          openPlayerRoute(context, item.id);
        }
      },
    );
  }
}

// ── Video tab ───────────────────────────────────────────────────────────────

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
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    if (widget.items.isEmpty && widget.loading) {
      return const Center(child: CircularProgressIndicator());
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
              title: l10n.cloudEmptyVideoTitle,
              subtitle: l10n.cloudEmptyVideoSubtitle,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: GridView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(t.space16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 16 / 11.5,
        ),
        itemCount: widget.items.length + (widget.loading && !widget.done ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= widget.items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return _CloudVideoTile(item: widget.items[index]);
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

class _CloudVideoTileState extends ConsumerState<_CloudVideoTile> {
  bool? _inLibrary;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await ref.read(cloudAddToLibraryProvider).isInLibrary(widget.item);
    if (mounted) setState(() => _inLibrary = v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final add = ref.watch(cloudAddToLibraryProvider);
    final dur = formatDurationHms(
      Duration(seconds: widget.item.durationSeconds),
    );
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
      overlay = cornerChip(
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: cs.onSurfaceVariant,
          ),
        ),
      );
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
        onPressed: () async {
          setState(() => _busy = true);
          try {
            await add.add(item);
            ref.invalidate(libraryMediaProvider);
            if (!context.mounted) return;
            setState(() {
              _inLibrary = true;
              _busy = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.cloudAddedToLibrary)),
            );
          } catch (_) {
            if (mounted) setState(() => _busy = false);
          }
        },
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        MediaCardTile(
          title: item.title,
          subtitle: '${l10n.miniPlayerMediaVideo} · $dur',
          thumbnailFile: null,
          thumbnailNetworkUrl: remoteThumbnailForCard(item.thumbnailUrl),
          coverSeed: seed,
          isVideo: true,
          accentColor: accent,
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
