/// YouTube-style Discover feed video card with add / play actions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/domain/feed_entry.dart';
import 'package:enjoy_player/features/player/application/youtube_warm.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Width / height for [SliverGrid] cells (16:9 thumb + compact metadata).
const double discoverFeedTileGridAspectRatio = 1.24;

/// Per-locale bundle of `DateFormat` instances used by [_formatPublishedLabel].
///
/// Each `DateFormat` constructor compiles ICU `DateSymbols` (~1 KB per call),
/// so the per-locale bundle is allocated lazily on first use and reused for
/// every subsequent tile in the feed.
class _DiscoverFeedTileDateFormats {
  _DiscoverFeedTileDateFormats(this.jm, this.mmmd, this.yMMMd);

  final DateFormat jm;
  final DateFormat mmmd;
  final DateFormat yMMMd;
}

final Map<String, _DiscoverFeedTileDateFormats> _dateFormatCache = {};

_DiscoverFeedTileDateFormats _discoverFeedTileDateFormats(String locale) {
  return _dateFormatCache.putIfAbsent(
    locale,
    () => _DiscoverFeedTileDateFormats(
      DateFormat.jm(locale),
      DateFormat.MMMd(locale),
      DateFormat.yMMMd(locale),
    ),
  );
}

/// Discover feed entry: shared poster artwork ([MediaCardTile], Aurora) plus
/// this feature's own meta row (channel avatar, two-line title, channel ·
/// published) and add-to-library affordances.
///
/// The tile never probes the library or the subscription list: membership and
/// channel display fields arrive as [inLibrary], [channelName] and
/// [channelAvatarUrl] via `discoverFeedItemsProvider` (ADR-0088), and the
/// transient "adding" state lives here because only discover imports from its
/// own grid.
class DiscoverFeedTile extends ConsumerStatefulWidget {
  const DiscoverFeedTile({
    required this.entry,
    required this.inLibrary,
    required this.channelName,
    required this.channelAvatarUrl,
    super.key,
  });

  final FeedEntry entry;

  /// Already resolved by `discoverFeedItemsProvider` (issue #764 candidate 6).
  /// The tile used to probe this per instance and cache it in widget state.
  final bool inLibrary;

  /// Channel display name joined by `discoverFeedItemsProvider` (issue #810 G)
  /// — the tile used to watch and linear-scan the subscription list per build.
  final String channelName;

  /// Channel avatar URL joined by `discoverFeedItemsProvider` (issue #810 G).
  final String? channelAvatarUrl;

  @override
  ConsumerState<DiscoverFeedTile> createState() => _DiscoverFeedTileState();
}

class _DiscoverFeedTileState extends ConsumerState<DiscoverFeedTile> {
  bool _adding = false;

  /// Returns `true` when the video is in the library after this call.
  ///
  /// The tile does not track membership itself: a successful import reaches it
  /// through `discoverFeedItemsProvider`, which is why the manual
  /// `ref.invalidate` calls this used to make are gone.
  Future<bool> _addToLibrary() async {
    if (_adding) return widget.inLibrary;
    setState(() => _adding = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await addDiscoverFeedEntryToLibrary(ref, widget.entry);
      if (!mounted) return false;
      AppNotice.success(context, l10n.discoverAddedToLibrary);
      return true;
    } catch (_) {
      if (mounted) {
        AppNotice.error(context, l10n.discoverAddFailed);
      }
      return false;
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _play() async {
    var inLib = widget.inLibrary;
    if (!inLib) {
      inLib = await _addToLibrary();
    }
    if (!inLib || !mounted) return;
    final mediaId = enjoyVideoId(
      provider: 'youtube',
      vid: widget.entry.videoId,
    );
    warmYoutubeSurfaceIfNeeded(ref, provider: 'youtube');
    openPlayerRoute(context, mediaId);
  }

  String? _durationLabel(FeedEntry entry) {
    final seconds = entry.durationSeconds;
    if (seconds == null || seconds <= 0) return null;
    return formatDurationHmsSeconds(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final entry = widget.entry;
    final thumb = remoteThumbnailForCard(entry.thumbnailUrl);
    final channelName = widget.channelName;
    final channelAvatar = widget.channelAvatarUrl;
    final inLibrary = widget.inLibrary;
    final publishedLabel = _formatPublishedLabel(context, entry.publishedAt);
    final durationLabel = _durationLabel(entry);

    return MediaCardTile(
      onTap: () => unawaited(_play()),
      thumbnailNetworkUrl: thumb,
      coverSeed: entry.videoId,
      isVideo: true,
      durationLabel: durationLabel,
      adding: _adding,
      inLibrary: inLibrary,
      meta: Padding(
        padding: EdgeInsets.only(top: t.space8 - 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChannelAvatar(
              imageUrl: channelAvatar,
              label: channelName,
              seed: entry.channelId,
            ),
            SizedBox(width: t.space8 + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$channelName · $publishedLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPublishedLabel(BuildContext context, DateTime dt) {
    final formats = _discoverFeedTileDateFormats(
      Localizations.localeOf(context).toString(),
    );
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inDays == 0) {
      return formats.jm.format(local);
    }
    if (diff.inDays < 7) {
      return formats.mmmd.format(local);
    }
    if (local.year == now.year) {
      return formats.mmmd.format(local);
    }
    return formats.yMMMd.format(local);
  }
}

class _ChannelAvatar extends StatelessWidget {
  const _ChannelAvatar({
    required this.label,
    required this.seed,
    this.imageUrl,
  });

  final String? imageUrl;
  final String label;
  final String seed;

  @override
  Widget build(BuildContext context) {
    return EnjoyAvatar(name: label, imageUrl: imageUrl, size: 34);
  }
}
