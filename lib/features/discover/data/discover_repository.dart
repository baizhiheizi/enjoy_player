/// Discover feeds: subscriptions, RSS refresh, add-to-library bridge.
library;

import 'dart:async';
import 'dart:collection';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/utils/stream_distinct.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:http/http.dart' as http;

import '../domain/discover_channel.dart';
import '../domain/feed_entry.dart';
import '../domain/recommended_channel.dart';
import 'recommended_channels_loader.dart';
import 'catalog_channel_ids.dart';
import 'youtube_channel_resolver.dart';
import 'youtube_fetch.dart';
import 'youtube_rss_parser.dart';
import 'youtube_video_duration.dart';

final _log = logNamed('discover.repository');

/// Maximum number of channels refreshed in parallel. YouTube's RSS
/// endpoints are rate-limit sensitive; 4 keeps us well under the
/// soft-limit and finishes a 20-channel refresh in ~5 RTTs.
const int _kRefreshChannelConcurrency = 4;

/// Maximum number of duration-enrichment fetches in parallel.
const int _kEnrichDurationConcurrency = 4;

/// Maximum number of distinct channel avatars to keep in memory.
/// LinkedHashMap-based LRU; oldest unread entry is evicted on insert.
const int _kAvatarCacheCapacity = 256;

class DiscoverRefreshResult {
  const DiscoverRefreshResult({
    required this.refreshedChannels,
    required this.failedChannelIds,
  });

  final int refreshedChannels;
  final List<String> failedChannelIds;

  bool get hasFailures => failedChannelIds.isNotEmpty;
}

class YoutubeFeedFetchException implements Exception {
  YoutubeFeedFetchException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class DiscoverRepository {
  DiscoverRepository(
    this._db, {
    http.Client? httpClient,
    RecommendedChannelsLoader? recommendedLoader,
    YoutubeChannelResolver? channelResolver,
    YoutubeRssParser? rssParser,
    this._libraryRepository,
  }) : _recommendedLoader = recommendedLoader ?? RecommendedChannelsLoader(),
       _rssParser = rssParser ?? const YoutubeRssParser() {
    _client = httpClient ?? http.Client();
    _channelResolver =
        channelResolver ?? YoutubeChannelResolver(client: _client);
  }

  final AppDatabase _db;
  late final http.Client _client;
  final RecommendedChannelsLoader _recommendedLoader;
  late final YoutubeChannelResolver _channelResolver;
  final YoutubeRssParser _rssParser;
  MediaLibraryRepository? _libraryRepository;

  /// Bounded LRU cache for channel avatar URLs. LinkedHashMap preserves
  /// insertion order; we move-to-end on every hit, and evict from the
  /// head when the cache is full. Prevents unbounded growth on a
  /// user who subscribes / unsubscribes many channels.
  final LinkedHashMap<String, String> _avatarUrlCache = LinkedHashMap();

  static const minRefreshInterval = Duration(hours: 1);
  static const rssFeedBase =
      'https://www.youtube.com/feeds/videos.xml?channel_id=';

  void bindLibraryRepository(MediaLibraryRepository repo) {
    _libraryRepository = repo;
  }

  Future<List<RecommendedChannel>> loadRecommendedChannels() =>
      _recommendedLoader.load();

  Stream<List<DiscoverChannel>> watchSubscriptions() {
    return _db.youtubeChannelSubscriptionDao
        .watchAll()
        .map((rows) => rows.map(_mapSubscription).toList(growable: false))
        .distinctBy(_listEqualsDiscoverChannel);
  }

  Stream<List<FeedEntry>> watchTimeline() {
    return _db.youtubeFeedEntryDao
        .watchTimeline()
        .map((rows) => rows.map(_mapFeedEntry).toList(growable: false))
        .distinctBy(_listEqualsFeedEntry);
  }

  Stream<List<FeedEntry>> watchChannelFeed(String channelId) {
    return _db.youtubeFeedEntryDao
        .watchForChannel(channelId)
        .map((rows) => rows.map(_mapFeedEntry).toList(growable: false))
        .distinctBy(_listEqualsFeedEntry);
  }

  Future<DiscoverChannel?> getSubscription(String channelId) async {
    final row = await _db.youtubeChannelSubscriptionDao.getByChannelId(
      channelId,
    );
    return row == null ? null : _mapSubscription(row);
  }

  Future<void> subscribeRecommended(RecommendedChannel channel) async {
    await subscribeChannel(
      channelId: channel.channelId,
      displayName: channel.name,
      source: 'recommended',
    );
  }

  Future<void> subscribeFromUserInput(String rawInput) async {
    final resolved = await _channelResolver.resolveDetailed(rawInput);
    var displayName = resolved.displayName?.trim();
    displayName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : rawInput.trim();
    await subscribeChannel(
      channelId: resolved.channelId,
      displayName: displayName,
      source: 'user',
    );
  }

  Future<void> subscribeChannel({
    required String channelId,
    required String displayName,
    required String source,
    String? thumbnailUrl,
  }) async {
    final existing = await _db.youtubeChannelSubscriptionDao.getByChannelId(
      channelId,
    );
    final now = DateTime.now();
    await _db.youtubeChannelSubscriptionDao.upsert(
      YoutubeChannelSubscriptionRow(
        channelId: channelId,
        displayName: displayName,
        thumbnailUrl: thumbnailUrl ?? existing?.thumbnailUrl,
        source: source,
        subscribedAt: existing?.subscribedAt ?? now,
        lastFetchedAt: existing?.lastFetchedAt,
      ),
    );
  }

  Future<void> unsubscribe(String channelId) async {
    await _db.youtubeChannelSubscriptionDao.deleteChannelId(channelId);
    await _db.youtubeFeedEntryDao.deleteForChannel(channelId);
  }

  Future<bool> isVideoInLibrary(String videoId) async {
    final row = await _db.videoDao.getYoutubeByVid(videoId);
    return row != null;
  }

  /// Channel profile photo from the public channel page — cached in memory.
  Future<String?> fetchChannelAvatarUrl(String channelId) async {
    final cached = _avatarUrlCache.remove(channelId);
    if (cached != null) {
      // Move-to-end on hit; preserves the LRU ordering.
      _avatarUrlCache[channelId] = cached;
      return cached;
    }

    try {
      final url = await _channelResolver.fetchChannelAvatarUrl(channelId);
      if (url != null && url.isNotEmpty) {
        _avatarUrlCache[channelId] = url;
        while (_avatarUrlCache.length > _kAvatarCacheCapacity) {
          _avatarUrlCache.remove(_avatarUrlCache.keys.first);
        }
      }
      return url;
    } catch (e, st) {
      _log.fine('channel avatar fetch failed for $channelId', e, st);
      return null;
    }
  }

  Future<String> addFeedEntryToLibrary(
    FeedEntry entry, {
    String? signedInUserId,
  }) async {
    final library = _libraryRepository;
    if (library == null) {
      throw StateError('DiscoverRepository library bridge not bound');
    }
    return library.importYoutubeVideo(
      entry.videoId,
      signedInUserId: signedInUserId,
      prefetchedTitle: entry.title,
      prefetchedThumbnailUrl: entry.thumbnailUrl,
    );
  }

  Future<DiscoverRefreshResult> refreshFeeds({bool force = false}) async {
    await _repairLegacyCatalogChannelIds();

    final subs = await _db.youtubeChannelSubscriptionDao.listAll();
    if (subs.isEmpty) {
      return const DiscoverRefreshResult(
        refreshedChannels: 0,
        failedChannelIds: [],
      );
    }

    final now = DateTime.now();
    final work = <YoutubeChannelSubscriptionRow>[];
    for (final sub in subs) {
      if (!force &&
          sub.lastFetchedAt != null &&
          now.difference(sub.lastFetchedAt!) < minRefreshInterval) {
        continue;
      }
      work.add(sub);
    }
    if (work.isEmpty) {
      return const DiscoverRefreshResult(
        refreshedChannels: 0,
        failedChannelIds: [],
      );
    }

    // Run up to [_kRefreshChannelConcurrency] channel refreshes in
    // parallel. YouTube's RSS endpoints are soft-rate-limited; 4
    // concurrent is well below the threshold and turns a 20-channel
    // refresh from 20 RTTs into ~5 RTTs.
    final results = <_ChannelRefreshOutcome>[];
    for (var i = 0; i < work.length; i += _kRefreshChannelConcurrency) {
      final batch = work.sublist(
        i,
        i + _kRefreshChannelConcurrency > work.length
            ? work.length
            : i + _kRefreshChannelConcurrency,
      );
      results.addAll(
        await Future.wait(
          batch.map((sub) => _refreshChannelGuarded(sub, fetchedAt: now)),
        ),
      );
    }

    var refreshed = 0;
    final failed = <String>[];
    for (final outcome in results) {
      if (outcome.success) {
        refreshed++;
      } else {
        failed.add(outcome.channelId);
      }
    }

    return DiscoverRefreshResult(
      refreshedChannels: refreshed,
      failedChannelIds: List.unmodifiable(failed),
    );
  }

  Future<_ChannelRefreshOutcome> _refreshChannelGuarded(
    YoutubeChannelSubscriptionRow sub, {
    required DateTime fetchedAt,
  }) async {
    final id = sub.channelId;
    try {
      await _refreshChannel(
        canonicalCatalogChannelId(id),
        fetchedAt: fetchedAt,
      );
      return _ChannelRefreshOutcome.success(id);
    } on YoutubeFeedFetchException catch (e, st) {
      _log.warning('RSS refresh failed for $id: ${e.message}', e, st);
      return _ChannelRefreshOutcome.failure(id);
    } catch (e, st) {
      _log.warning('RSS refresh failed for $id', e, st);
      return _ChannelRefreshOutcome.failure(id);
    }
  }

  Future<void> _refreshChannel(
    String channelId, {
    required DateTime fetchedAt,
  }) async {
    final uri = Uri.parse('$rssFeedBase$channelId');
    final response = await YoutubeFetch.getRss(_client, uri);
    if (response.statusCode != 200) {
      throw YoutubeFeedFetchException(
        'RSS HTTP ${response.statusCode} for $channelId',
        statusCode: response.statusCode,
      );
    }

    final body = response.body;
    if (!YoutubeRssParser.isValidFeedDocument(body)) {
      throw YoutubeFeedFetchException(
        'RSS response for $channelId is not a YouTube Atom feed '
        '(likely bot block or HTML error page)',
        statusCode: response.statusCode,
      );
    }

    final entries = _rssParser.parse(body, channelId: channelId);
    final keepVideoIds = entries.map((e) => e.videoId).toSet();
    await _db.youtubeFeedEntryDao.deleteStaleForChannel(
      channelId,
      keepVideoIds,
    );

    // Read and write per-entry work is keyed by (channelId, videoId), so
    // entries do not contend with each other. Fan the reads out, then fan
    // the writes out — a typical YouTube RSS feed of ~15 entries turns
    // ~45 sequential awaits into two parallel batches.
    final resolved = await Future.wait(
      entries.map((entry) async {
        final existing = await _db.youtubeFeedEntryDao.getEntry(
          channelId: channelId,
          videoId: entry.videoId,
        );
        final libraryVideo = await _db.videoDao.getYoutubeByVid(entry.videoId);
        final durationSeconds =
            libraryVideo != null && libraryVideo.durationSeconds > 0
            ? libraryVideo.durationSeconds
            : existing?.durationSeconds;
        return (entry: entry, durationSeconds: durationSeconds);
      }),
    );

    await Future.wait(
      resolved.map(
        (r) => _db.youtubeFeedEntryDao.upsertEntry(
          YoutubeFeedEntryRow(
            videoId: r.entry.videoId,
            channelId: r.entry.channelId,
            title: r.entry.title,
            thumbnailUrl: r.entry.thumbnailUrl,
            durationSeconds: r.durationSeconds,
            publishedAt: r.entry.publishedAt,
            fetchedAt: fetchedAt,
          ),
        ),
      ),
    );

    unawaited(_enrichMissingDurations(channelId, entries));

    final feedTitle = _rssParser.parseFeedTitle(body);
    if (feedTitle != null && feedTitle.isNotEmpty) {
      await _db.youtubeChannelSubscriptionDao.updateDisplayName(
        channelId,
        feedTitle,
      );
    }

    await _db.youtubeChannelSubscriptionDao.touchLastFetched(
      channelId,
      fetchedAt,
    );

    unawaited(_maybeUpdateChannelAvatar(channelId));
  }

  Future<void> _enrichMissingDurations(
    String channelId,
    List<FeedEntry> entries,
  ) async {
    // Cap parallel HTML page fetches at [_kEnrichDurationConcurrency]
    // using a counting semaphore (queue of waiters). Previously this
    // loop ran sequentially — for a 15-entry channel that was 15 RTTs
    // of latency on every refresh, and 15 × 20 channels = 300 HTML
    // page requests when many subscriptions refresh together.
    final immutableEntries = List<FeedEntry>.unmodifiable(entries);
    var inFlight = 0;
    final waiters = <Completer<void>>[];

    Future<void> acquire() async {
      if (inFlight < _kEnrichDurationConcurrency) {
        inFlight += 1;
        return;
      }
      final c = Completer<void>();
      waiters.add(c);
      await c.future;
    }

    void release() {
      if (waiters.isNotEmpty) {
        // Hand the slot to the next waiter in FIFO order; do not
        // decrement inFlight because the waiter immediately claims
        // the same slot.
        waiters.removeAt(0).complete();
      } else {
        inFlight -= 1;
      }
    }

    final tasks = <Future<void>>[];
    for (final entry in immutableEntries) {
      await acquire();
      tasks.add(() async {
        try {
          final cached = await _db.youtubeFeedEntryDao.getEntry(
            channelId: channelId,
            videoId: entry.videoId,
          );
          if (cached?.durationSeconds != null && cached!.durationSeconds! > 0) {
            return;
          }

          final seconds = await YoutubeVideoDuration.fetchSeconds(
            _client,
            entry.videoId,
          );
          if (seconds == null || seconds <= 0) return;

          await _db.youtubeFeedEntryDao.updateDurationSeconds(
            channelId: channelId,
            videoId: entry.videoId,
            durationSeconds: seconds,
          );
        } finally {
          release();
        }
      }());
    }
    await Future.wait(tasks);
  }

  Future<void> _repairLegacyCatalogChannelIds() async {
    for (final entry in catalogChannelIdCorrections.entries) {
      final oldId = entry.key;
      final newId = entry.value;
      final oldSub = await _db.youtubeChannelSubscriptionDao.getByChannelId(
        oldId,
      );
      if (oldSub == null) continue;

      final newSub = await _db.youtubeChannelSubscriptionDao.getByChannelId(
        newId,
      );
      if (newSub == null) {
        await _db.youtubeChannelSubscriptionDao.upsert(
          YoutubeChannelSubscriptionRow(
            channelId: newId,
            displayName: oldSub.displayName,
            thumbnailUrl: oldSub.thumbnailUrl,
            source: oldSub.source,
            subscribedAt: oldSub.subscribedAt,
            lastFetchedAt: null,
          ),
        );
      }

      await _db.youtubeFeedEntryDao.deleteForChannel(oldId);
      await _db.youtubeChannelSubscriptionDao.deleteChannelId(oldId);
      _log.info('Repaired legacy catalog channel id $oldId → $newId');
    }
  }

  Future<void> _maybeUpdateChannelAvatar(String channelId) async {
    final sub = await _db.youtubeChannelSubscriptionDao.getByChannelId(
      channelId,
    );
    if (sub == null ||
        sub.thumbnailUrl == null ||
        looksLikeVideoThumbnail(sub.thumbnailUrl)) {
      final avatarUrl = await fetchChannelAvatarUrl(channelId);
      if (avatarUrl != null) {
        await _db.youtubeChannelSubscriptionDao.updateThumbnail(
          channelId,
          avatarUrl,
        );
      }
    }
  }

  DiscoverChannel _mapSubscription(YoutubeChannelSubscriptionRow row) {
    return DiscoverChannel(
      channelId: row.channelId,
      displayName: row.displayName,
      thumbnailUrl: row.thumbnailUrl,
      source: row.source,
      subscribedAt: row.subscribedAt,
      lastFetchedAt: row.lastFetchedAt,
    );
  }

  FeedEntry _mapFeedEntry(YoutubeFeedEntryRow row) {
    return FeedEntry(
      videoId: row.videoId,
      channelId: row.channelId,
      title: row.title,
      thumbnailUrl: row.thumbnailUrl,
      durationSeconds: row.durationSeconds,
      publishedAt: row.publishedAt,
    );
  }

  static bool looksLikeVideoThumbnail(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains('i.ytimg.com/vi/');
  }
}

/// Internal: outcome of a single per-channel refresh.
class _ChannelRefreshOutcome {
  const _ChannelRefreshOutcome._(this.channelId, this.success);
  factory _ChannelRefreshOutcome.success(String channelId) =>
      _ChannelRefreshOutcome._(channelId, true);
  factory _ChannelRefreshOutcome.failure(String channelId) =>
      _ChannelRefreshOutcome._(channelId, false);

  final String channelId;
  final bool success;
}

bool _listEqualsDiscoverChannel(
  List<DiscoverChannel> previous,
  List<DiscoverChannel> current,
) {
  if (identical(previous, current)) return true;
  if (previous.length != current.length) return false;
  for (var i = 0; i < previous.length; i++) {
    if (previous[i] != current[i]) return false;
  }
  return true;
}

bool _listEqualsFeedEntry(List<FeedEntry> previous, List<FeedEntry> current) {
  if (identical(previous, current)) return true;
  if (previous.length != current.length) return false;
  for (var i = 0; i < previous.length; i++) {
    if (previous[i] != current[i]) return false;
  }
  return true;
}
