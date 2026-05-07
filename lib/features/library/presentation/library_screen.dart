/// Library: Music / Video tabs, search filter, WMP-style tiles & lists.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/local_thumbnail.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/library_media_provider.dart';
import '../domain/media.dart';
import '../application/library_search_provider.dart';
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

  List<Media> _filter(List<Media> items, String query) {
    if (query.isEmpty) return items;
    final lower = query.toLowerCase();
    return items
        .where((m) => m.title.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(libraryMediaProvider);
    final query = ref.watch(librarySearchProvider);
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: mediaAsync.when(
        data: (items) {
          final filtered = _filter(items, query);
          final audioItems =
              filtered.where((m) => m.kind == MediaKind.audio).toList()
                ..sort((a, b) => a.title.compareTo(b.title));
          final videoItems =
              filtered.where((m) => m.kind == MediaKind.video).toList()
                ..sort((a, b) => a.title.compareTo(b.title));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.space24,
                  t.space24,
                  t.space24,
                  t.space16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.libraryTitle,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => importMediaFromPicker(context, ref),
                      icon: const Icon(Icons.folder_open_rounded),
                      label: Text(l10n.actionOpenFiles),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.space24),
                child: Material(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(t.radiusFull),
                  ),
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      return SegmentedButton<String>(
                        style: SegmentedButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.transparent,
                          foregroundColor: cs.onSurfaceVariant,
                          selectedForegroundColor: cs.onPrimaryContainer,
                          selectedBackgroundColor:
                              cs.primaryContainer.withValues(alpha: 0.55),
                          side: BorderSide.none,
                          splashFactory: NoSplash.splashFactory,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(t.radiusFull),
                          ),
                        ),
                        showSelectedIcon: false,
                        emptySelectionAllowed: false,
                        segments: [
                          ButtonSegment<String>(
                            value: 'audio',
                            label: Text(l10n.libraryTabMusic),
                          ),
                          ButtonSegment<String>(
                            value: 'video',
                            label: Text(l10n.libraryTabVideo),
                          ),
                        ],
                        selected: {
                          _tabController.index == 0 ? 'audio' : 'video',
                        },
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
              ),
              SizedBox(height: t.space8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _MusicLibraryBody(items: audioItems),
                    _VideoLibraryBody(items: videoItems),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
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
                  onPressed: () => ref.invalidate(libraryMediaProvider),
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

class _MusicLibraryBody extends StatelessWidget {
  const _MusicLibraryBody({required this.items});

  final List<Media> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    if (items.isEmpty) {
      return _LibraryEmptyHero(
        icon: Icons.music_note_rounded,
        title: l10n.libraryEmptyMusicTitle,
        subtitle: l10n.libraryEmptyMusicHint,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(t.space24, t.space16, t.space24, t.space24),
      itemCount: items.length,
      separatorBuilder: (context, _) => SizedBox(height: t.space8),
      itemBuilder: (context, index) {
        final m = items[index];
        return _MusicRowCard(media: m);
      },
    );
  }
}

class _VideoLibraryBody extends StatelessWidget {
  const _VideoLibraryBody({required this.items});

  final List<Media> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    if (items.isEmpty) {
      return _LibraryEmptyHero(
        icon: Icons.movie_outlined,
        title: l10n.libraryEmptyVideoTitle,
        subtitle: l10n.libraryEmptyVideoHint,
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(t.space24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 16 / 11,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _VideoTile(media: items[index]),
    );
  }
}

class _LibraryEmptyHero extends StatelessWidget {
  const _LibraryEmptyHero({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: t.contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.all(t.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                ).createShader(bounds),
                child: Icon(icon, size: 120, color: Colors.white),
              ),
              SizedBox(height: t.space24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: t.space8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              SizedBox(height: t.space24),
              Consumer(
                builder: (context, ref, _) {
                  final l10n = AppLocalizations.of(context)!;
                  return FilledButton.icon(
                    onPressed: () => importMediaFromPicker(context, ref),
                    icon: const Icon(Icons.folder_open_rounded),
                    label: Text(l10n.actionOpenFiles),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MusicRowCard extends StatefulWidget {
  const _MusicRowCard({required this.media});

  final Media media;

  @override
  State<_MusicRowCard> createState() => _MusicRowCardState();
}

class _MusicRowCardState extends State<_MusicRowCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final thumb = localThumbnailFile(widget.media.thumbnailPath);
    final dur = formatDurationHms(Duration(milliseconds: widget.media.durationMs));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: AnimatedContainer(
        duration: t.motionFast,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.radiusLg),
          color:
              _hover
                  ? cs.primary.withValues(alpha: 0.08)
                  : null,
          border: Border.all(
            color:
                _hover
                    ? cs.primary.withValues(alpha: 0.5)
                    : cs.outlineVariant.withValues(alpha: 0.18),
          ),
        ),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/player/${widget.media.id}'),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: t.space16,
                vertical: t.space12,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(t.radiusSm),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child:
                          thumb != null
                              ? Image.file(
                                thumb,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, _, _) => _musicPlaceholder(cs),
                              )
                              : _musicPlaceholder(cs),
                    ),
                  ),
                  SizedBox(width: t.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.media.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: t.space4),
                        Wrap(
                          spacing: t.space8,
                          runSpacing: t.space4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              label: Text(widget.media.language),
                              labelStyle: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              dur,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _musicPlaceholder(ColorScheme cs) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
      ),
      child: Icon(Icons.audiotrack_rounded, color: cs.primary, size: 30),
    );
  }
}

class _VideoTile extends StatefulWidget {
  const _VideoTile({required this.media});

  final Media media;

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final thumb = localThumbnailFile(widget.media.thumbnailPath);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/player/${widget.media.id}'),
        child: AnimatedContainer(
          duration: t.motionFast,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(t.radiusMd),
            color:
                _hover
                    ? cs.primary.withValues(alpha: 0.10)
                    : Colors.transparent,
            border: Border.all(
              color:
                  _hover
                      ? cs.primary.withValues(alpha: 0.85)
                      : cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                    thumb != null
                        ? Image.file(
                          thumb,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, _, _) => _videoPlaceholder(cs),
                        )
                        : _videoPlaceholder(cs),
              ),
              SizedBox(height: t.space8),
              Text(
                widget.media.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _videoPlaceholder(ColorScheme cs) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.surfaceContainerHighest, cs.surfaceContainer],
        ),
      ),
      child: Center(
        child: Icon(Icons.movie_outlined, size: 48, color: cs.onSurfaceVariant),
      ),
    );
  }
}
