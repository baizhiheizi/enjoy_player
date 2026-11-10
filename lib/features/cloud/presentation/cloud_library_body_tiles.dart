part of 'cloud_library_body.dart';

String _coverSeed(RemoteLibraryItem item) {
  final m = item.md5?.trim();
  if (m != null && m.isNotEmpty) return m;
  return item.id;
}

String? _thumbUrl(RemoteLibraryItem item) {
  return remoteThumbnailForCard(
    item.thumbnailUrl,
    youtubeVideoId: item.provider == kProviderYoutube ? item.md5 : null,
    mediaUrl: item.mediaUrl,
  );
}

/// Shared "is in library / add to library" state for cloud list/grid tiles.
mixin _CloudItemMembershipMixin<W extends ConsumerStatefulWidget>
    on ConsumerState<W> {
  bool? _inLibrary;
  bool _busy = false;

  RemoteLibraryItem get cloudItem;

  @override
  void initState() {
    super.initState();
    unawaited(loadMembership());
  }

  String? get playingMediaId =>
      ref.watch(playerControllerProvider.select((s) => s?.mediaId));

  String? get heroArtworkMediaId {
    if (_inLibrary != true) return null;
    return playingMediaId == cloudItem.id ? null : cloudItem.id;
  }

  void openInPlayer(BuildContext context) {
    if (_inLibrary == true) openPlayerRoute(context, cloudItem.id);
  }

  Future<void> loadMembership() async {
    final v = await ref.read(cloudAddToLibraryProvider).isInLibrary(cloudItem);
    if (mounted) setState(() => _inLibrary = v);
  }

  Future<void> addToLibrary() async {
    final l10n = AppLocalizations.of(context)!;
    final add = ref.read(cloudAddToLibraryProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _busy = true);
    try {
      await add.add(cloudItem);
      container.invalidate(libraryMediaProvider);
      container.invalidate(libraryHomeRecentsProvider);
      container.invalidate(libraryFilteredListsProvider);
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;
    final dur = formatDurationHmsSeconds(item.durationSeconds);
    final seed = _coverSeed(item);
    final accent = generativeAccentForSeed(seed);

    Widget? trailing;
    if (_busy) {
      trailing = const LoadingIcon(size: 22);
    } else if (_inLibrary == true) {
      trailing = Icon(EnjoyIcons.checkCircleFill, color: cs.primary, size: 22);
    } else {
      trailing = IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 22,
        tooltip: l10n.cloudAddToLibraryTooltip,
        icon: Icon(EnjoyIcons.libraryAdd, color: cs.onSurfaceVariant),
        onPressed: () => unawaited(addToLibrary()),
      );
    }

    return MediaCardRow(
      title: item.title,
      maxTitleLines: 2,
      language: item.language == kUnknownMediaLanguageTag
          ? null
          : languageCodeLabel(item.language),
      durationLabel: item.durationSeconds > 0 ? dur : null,
      thumbnailFile: null,
      thumbnailNetworkUrl: _thumbUrl(item),
      coverSeed: seed,
      isVideo: false,
      accentColor: accent,
      heroArtworkMediaId: heroArtworkMediaId,
      trailing: trailing,
      providerBadge: item.provider == kProviderYoutube
          ? l10n.youtubeBadge
          : null,
      onTap: () => openInPlayer(context),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;
    final dur = formatDurationHmsSeconds(item.durationSeconds);
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
        Icon(EnjoyIcons.checkCircleFill, color: cs.primary, size: 22),
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
        icon: const Icon(EnjoyIcons.libraryAdd),
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
          thumbnailNetworkUrl: _thumbUrl(item),
          coverSeed: seed,
          isVideo: true,
          accentColor: accent,
          heroArtworkMediaId: heroArtworkMediaId,
          providerBadge: item.provider == kProviderYoutube
              ? l10n.youtubeBadge
              : null,
          onTap: () => openInPlayer(context),
        ),
        Positioned(top: 8, right: 8, child: overlay),
      ],
    );
  }
}
