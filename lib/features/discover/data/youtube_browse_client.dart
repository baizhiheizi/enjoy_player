/// InnerTube `browse` client for YouTube channel refresh.
///
/// The Discover refresh path uses this client as its **primary** data source:
/// `POST /youtubei/v1/browse` with `browseId: "UC<channelId>"` returns a richer
/// payload than the legacy Atom RSS feed (per-video `lengthText`,
/// `publishedTimeText`, `viewCountText`) and is materially less likely to be
/// blocked by YouTube's bot detection. When this client throws
/// [YoutubeBrowseException], the repository falls back to the legacy RSS path.
///
/// Mirrors the posture of [YoutubeCaptionFetcher] in
/// `lib/features/transcript/data/youtube_caption_fetcher.dart`:
/// - Anonymous InnerTube surface (`youtubei.googleapis.com`, no API key).
/// - Reuses the shared [ClientProfile] model and the worker-driven rotation.
/// - `package:http` POST with `Content-Type: application/json` and the
///   `X-YouTube-Client-Name` / `X-YouTube-Client-Version` headers.
/// - `logNamed('discover.browse')` for diagnostics; never `print()`.
///
/// ADR-0047.
library;

import 'dart:convert';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/transcript/data/client_profile.dart';
import 'package:http/http.dart' as http;

final _log = logNamed('discover.browse');

/// Anonymous InnerTube `browse` endpoint. The same surface is used by the
/// YouTube caption fetcher's `/player` calls.
const _innertubeBrowseEndpoint =
    'https://youtubei.googleapis.com/youtubei/v1/browse?prettyPrint=false';

/// Profile names to try in order when issuing a browse call. `WEB` is the
/// desktop client documented as the most reliable for `browse`; `MWEB` is the
/// documented mobile fallback. `IOS` / `ANDROID_VR` are deliberately excluded —
/// `ANDROID_VR` rejects `browse` with 401 in our testing.
const List<String> kBrowsePreferredProfileOrder = ['web', 'mweb'];

/// Hard cap on continuation pages per `fetchChannelVideos` call.
const int kBrowseMaxPages = 5;

/// Per-video projection parsed from an InnerTube `videoRenderer`.
///
/// Internal to the Discover data layer; never persisted directly. The
/// repository consumes this type and projects it to `YoutubeFeedEntryRow`.
class BrowseVideoEntry {
  const BrowseVideoEntry({
    required this.videoId,
    required this.title,
    required this.publishedAt,
    this.thumbnailUrl,
    this.durationSeconds,
    this.viewCountText,
    this.nextPageToken,
  });

  final String videoId;
  final String title;
  final DateTime publishedAt;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? viewCountText;

  /// Continuation token that follows this entry. Only set on the **last**
  /// entry of a page when the source indicates more pages exist. The token is
  /// opaque and must not be parsed or transformed.
  final String? nextPageToken;
}

/// Outcome of an InnerTube `browse` call for one channel.
class BrowseFetchOutcome {
  const BrowseFetchOutcome({
    required this.entries,
    required this.pagesFetched,
    required this.exhaustedPages,
    required this.profileUsed,
  });

  final List<BrowseVideoEntry> entries;

  /// Total number of pages fetched (initial + continuation pages).
  final int pagesFetched;

  /// True iff `maxPages` was reached while a continuation token was still
  /// being returned by the source.
  final bool exhaustedPages;

  /// Name of the [ClientProfile] that ultimately succeeded. Useful for
  /// diagnostics and for `YoutubeFetch.userAgent` logging.
  final String profileUsed;
}

/// Thrown by [YoutubeBrowseClient] on transport, parse, or auth errors.
class YoutubeBrowseException implements Exception {
  YoutubeBrowseException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() =>
      'YoutubeBrowseException(${statusCode ?? '-'}) $message${cause == null ? '' : ' ($cause)'}';
}

/// InnerTube `browse` client with per-profile retry and continuation
/// pagination.
class YoutubeBrowseClient {
  YoutubeBrowseClient({
    required this._client,
    required this._profiles,
    this._preferredProfileOrder = kBrowsePreferredProfileOrder,
    this._maxPages = kBrowseMaxPages,
    this._perCallTimeout,
  });

  final http.Client _client;
  final List<ClientProfile> _profiles;
  final List<String> _preferredProfileOrder;
  final int _maxPages;
  final Duration? _perCallTimeout;

  /// Fetches up to `maxPages` of InnerTube `browse` pages for the given
  /// channel. Throws [YoutubeBrowseException] on transport, parse, or
  /// authentication errors.
  Future<BrowseFetchOutcome> fetchChannelVideos({
    required String channelId,
    required DateTime fetchedAt,
  }) async {
    final ordered = _resolveProfileOrder();
    if (ordered.isEmpty) {
      throw YoutubeBrowseException(
        'No usable client profiles for InnerTube browse',
      );
    }

    final errors = <String>[];
    int? lastStatusCode;

    for (final profile in ordered) {
      try {
        final initial = await _post(
          profile: profile,
          body: _buildInitialBody(channelId, profile),
        );
        lastStatusCode = initial.statusCode;
        if (initial.statusCode != 200) {
          errors.add('${profile.name} HTTP ${initial.statusCode}');
          // Retry on the next profile for auth-style failures; bail otherwise.
          if (_isRetryableStatus(initial.statusCode)) continue;
          throw YoutubeBrowseException(
            'InnerTube browse failed (${profile.name}): ${initial.statusCode}',
            statusCode: initial.statusCode,
          );
        }

        // Success: parse the initial page, then follow continuations with the
        // same profile.
        return await _followContinuations(
          initialBody: initial.body,
          profile: profile,
          fetchedAt: fetchedAt,
          errors: errors,
        );
      } on YoutubeBrowseException catch (e) {
        // Surface non-retryable failures immediately.
        if (e.statusCode != null && !_isRetryableStatus(e.statusCode!)) {
          rethrow;
        }
        errors.add('${profile.name}: ${e.message}');
        continue;
      } catch (e, st) {
        _log.warning('InnerTube browse threw for ${profile.name}', e, st);
        errors.add('${profile.name}: $e');
        continue;
      }
    }

    throw YoutubeBrowseException(
      'all profiles failed: ${errors.join('; ')}',
      statusCode: lastStatusCode,
    );
  }

  /// Filters `_profiles` to the names in `_preferredProfileOrder` (in that
  /// order), keeping only valid profiles. Unknown names are silently skipped.
  List<ClientProfile> _resolveProfileOrder() {
    final byName = {for (final p in _profiles) p.name: p};
    return [
      for (final name in _preferredProfileOrder)
        if (byName[name] != null && byName[name]!.isValid) byName[name]!,
    ];
  }

  bool _isRetryableStatus(int code) => code == 401 || code == 403;

  Map<String, dynamic> _buildInitialBody(
    String channelId,
    ClientProfile profile,
  ) => {
    'context': {
      'client': {
        'clientName': profile.clientName,
        'clientVersion': profile.clientVersion,
        'hl': 'en',
        'gl': 'US',
        'userAgent': profile.userAgent,
        ...profile.context,
      },
    },
    'browseId': 'UC$channelId',
  };

  Map<String, dynamic> _buildContinuationBody(
    String token,
    ClientProfile profile,
  ) => {
    'context': {
      'client': {
        'clientName': profile.clientName,
        'clientVersion': profile.clientVersion,
        'hl': 'en',
        'gl': 'US',
        'userAgent': profile.userAgent,
        ...profile.context,
      },
    },
    'continuation': token,
  };

  Future<http.Response> _post({
    required ClientProfile profile,
    required Map<String, dynamic> body,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': '*/*',
      'User-Agent': profile.userAgent,
      'X-YouTube-Client-Name': profile.clientNameHeader,
      'X-YouTube-Client-Version': profile.clientVersion,
      'Origin': 'https://www.youtube.com',
    };
    final request = http.Request('POST', Uri.parse(_innertubeBrowseEndpoint))
      ..headers.addAll(headers)
      ..body = jsonEncode(body);
    final future = _perCallTimeout == null
        ? _client.send(request)
        : _client.send(request).timeout(_perCallTimeout);
    final streamed = await future;
    return http.Response.fromStream(streamed);
  }

  Future<BrowseFetchOutcome> _followContinuations({
    required String initialBody,
    required ClientProfile profile,
    required DateTime fetchedAt,
    required List<String> errors,
  }) async {
    final allEntries = <BrowseVideoEntry>[];
    var pagesFetched = 0;
    var exhausted = false;
    String? nextToken;
    String? currentBody = initialBody;

    while (true) {
      pagesFetched += 1;
      Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(currentBody!) as Map<String, dynamic>;
      } on FormatException catch (e) {
        throw YoutubeBrowseException(
          'InnerTube browse response was not valid JSON (${profile.name})',
          cause: e,
        );
      }

      final page = _extractPage(parsed, fetchedAt);
      allEntries.addAll(page.entries);

      nextToken = page.continuationToken;
      if (nextToken == null) break;
      if (pagesFetched >= _maxPages) {
        exhausted = true;
        break;
      }

      _log.fine(
        'InnerTube browse (${profile.name}) following continuation page ${pagesFetched + 1}',
      );
      final response = await _post(
        profile: profile,
        body: _buildContinuationBody(nextToken, profile),
      );
      if (response.statusCode != 200) {
        // Non-200 on continuation is non-retryable in this client: we already
        // committed to the profile. Surface as a partial success.
        errors.add(
          '${profile.name} continuation HTTP ${response.statusCode} after page $pagesFetched',
        );
        _log.warning(
          'InnerTube browse continuation failed for ${profile.name}: HTTP ${response.statusCode}',
        );
        break;
      }
      currentBody = response.body;
    }

    _log.info(
      'InnerTube browse (${profile.name}) returned ${allEntries.length} entries across $pagesFetched page(s); exhausted=$exhausted',
    );

    return BrowseFetchOutcome(
      entries: List.unmodifiable(allEntries),
      pagesFetched: pagesFetched,
      exhaustedPages: exhausted,
      profileUsed: profile.name,
    );
  }
}

class _PageExtract {
  const _PageExtract({required this.entries, required this.continuationToken});
  final List<BrowseVideoEntry> entries;
  final String? continuationToken;
}

/// Walks the InnerTube `browse` response looking for a list of
/// `BrowseVideoEntry` projections. Three paths are tried in order:
///
/// 1. **`richGridRenderer`** (uploads tab shape) — extracts
///    `richItemRenderer.content.<renderer>` items and the trailing
///    `continuationItemRenderer` token. Paginated.
/// 2. **`sectionListRenderer` → `shelfRenderer` → `horizontalListRenderer`**
///    (Home / Videos-tab-as-shelf shape used by some large channels like TED).
///    Not paginated.
/// 3. **Deep recursive search** — last-resort fallback that walks the entire
///    response JSON looking for any recognised renderer
///    (`videoRenderer`, `gridVideoRenderer`, `compactVideoRenderer`,
///    `lockupViewModel`, `shortsLockupViewModel`, `reelItemRenderer`),
///    either wrapped in a `richItemRenderer.content` envelope or as a direct
///    child. Not paginated.
///
/// If all three paths return no entries, throws
/// [YoutubeBrowseException]. Otherwise returns a [_PageExtract] whose
/// `continuationToken` is set only on path 1.
_PageExtract _extractPage(Map<String, dynamic> json, DateTime fetchedAt) {
  // Path 1: richGridRenderer.
  final grid = _findRichGridContents(json);
  if (grid != null) {
    return _extractFromRichGrid(grid, fetchedAt);
  }

  // Path 2: sectionListRenderer / shelfRenderer.
  final shelfEntries = _findShelfVideoRenderers(json, fetchedAt);
  if (shelfEntries.isNotEmpty) {
    return _PageExtract(entries: shelfEntries, continuationToken: null);
  }

  // Path 3: deep recursive search.
  final deepEntries = _deepFindVideoRenderers(json, fetchedAt);
  if (deepEntries.isNotEmpty) {
    return _PageExtract(entries: deepEntries, continuationToken: null);
  }

  throw YoutubeBrowseException(
    'InnerTube browse response has no recognisable videoRenderers',
  );
}

/// Extracts entries + continuation token from a `richGridRenderer.contents`
/// list. Items are either `richItemRenderer.content.<renderer>` projections
/// (recognised via [_tryExtractEntry]) or trailing `continuationItemRenderer`s
/// that carry the next-page token.
_PageExtract _extractFromRichGrid(List<dynamic> contents, DateTime fetchedAt) {
  final entries = <BrowseVideoEntry>[];
  String? continuationToken;

  for (final raw in contents) {
    if (raw is! Map) continue;

    // Try the generic extractor first — handles richItemRenderer.content
    // wrapping any of the recognised renderer types (videoRenderer,
    // gridVideoRenderer, compactVideoRenderer, lockupViewModel, etc.).
    final entry = _tryExtractEntry(raw, fetchedAt);
    if (entry != null) {
      entries.add(entry);
      continue;
    }

    final continuation = raw['continuationItemRenderer'];
    if (continuation is Map) {
      final endpoint = continuation['continuationEndpoint'];
      if (endpoint is Map) {
        final command = endpoint['continuationCommand'];
        if (command is Map) {
          final token = command['token'];
          if (token is String && token.isNotEmpty) {
            continuationToken = token;
          }
        }
      }
    }
  }

  return _PageExtract(entries: entries, continuationToken: continuationToken);
}

/// Walks the response JSON for the `contents` array under
/// `twoColumnBrowseResultsRenderer.tabs[*].tabRenderer.content.richGridRenderer`.
///
/// Returns the first non-null `contents` list encountered, or `null` when the
/// expected shape is absent (in which case the caller falls back to the
/// sectionListRenderer or deep-search paths). An empty list is a valid "no
/// videos on this page" response and is returned as-is.
List<dynamic>? _findRichGridContents(Map<String, dynamic> json) {
  final tabs = _findTabs(json);
  if (tabs == null) return null;

  for (final tab in tabs) {
    if (tab is! Map) continue;
    final content = _tabContent(tab);
    if (content == null) continue;
    final grid = content['richGridRenderer'];
    if (grid is Map) {
      final contents = grid['contents'];
      if (contents is List) return contents;
    }
  }
  return null;
}

/// Walks `twoColumnBrowseResultsRenderer.tabs[*].tabRenderer.content.sectionListRenderer.contents[*].itemSectionRenderer.contents[*].shelfRenderer.content.horizontalListRenderer.items[*]`,
/// parsing each `gridVideoRenderer` (or `richItemRenderer.content.videoRenderer`)
/// as a [BrowseVideoEntry]. Deduplicates by `videoId`. Returns an empty list
/// when the shape is absent or no items parse.
List<BrowseVideoEntry> _findShelfVideoRenderers(
  Map<String, dynamic> json,
  DateTime fetchedAt,
) {
  final tabs = _findTabs(json);
  if (tabs == null) return const [];

  final entries = <BrowseVideoEntry>[];
  final seen = <String>{};

  void add(BrowseVideoEntry? entry) {
    if (entry == null) return;
    if (seen.add(entry.videoId)) entries.add(entry);
  }

  for (final tab in tabs) {
    if (tab is! Map) continue;
    final content = _tabContent(tab);
    if (content == null) continue;

    final sectionList = content['sectionListRenderer'];
    if (sectionList is! Map) continue;
    final sectionContents = sectionList['contents'];
    if (sectionContents is! List) continue;

    for (final section in sectionContents) {
      if (section is! Map) continue;
      final itemSection = section['itemSectionRenderer'];
      if (itemSection is! Map) continue;
      final items = itemSection['contents'];
      if (items is! List) continue;

      for (final item in items) {
        if (item is! Map) continue;
        final shelf = item['shelfRenderer'];
        if (shelf is! Map) continue;
        final shelfContent = shelf['content'];
        if (shelfContent is! Map) continue;
        final horizontalList = shelfContent['horizontalListRenderer'];
        if (horizontalList is! Map) continue;
        final shelfItems = horizontalList['items'];
        if (shelfItems is! List) continue;

        for (final shelfItem in shelfItems) {
          if (shelfItem is! Map) continue;
          add(_tryExtractEntry(shelfItem, fetchedAt));
        }
      }
    }
  }

  return entries;
}

/// Last-resort fallback: walks the entire response JSON recursively and
/// collects every recognisable [BrowseVideoEntry]. Used when neither the
/// `richGridRenderer` nor the `sectionListRenderer` shape is present, which
/// happens for some channel responses (e.g., channels whose Videos tab uses
/// a non-standard renderer tree). Deduplicates by `videoId`.
List<BrowseVideoEntry> _deepFindVideoRenderers(
  Map<String, dynamic> json,
  DateTime fetchedAt,
) {
  final entries = <BrowseVideoEntry>[];
  final seen = <String>{};

  void walk(dynamic node) {
    if (node is Map) {
      // Try every node as a possible renderer envelope. Skip a node we
      // already entered via `richItemRenderer.content` (those are recursed
      // into by `_tryExtractEntry`); instead just ask the generic extractor.
      final entry = _tryExtractEntry(node, fetchedAt);
      if (entry != null && seen.add(entry.videoId)) entries.add(entry);
      for (final value in node.values) {
        walk(value);
      }
    } else if (node is List) {
      for (final value in node) {
        walk(value);
      }
    }
  }

  walk(json);
  return entries;
}

/// Tries to extract a [BrowseVideoEntry] from any Map node. Recognises the
/// `richItemRenderer.content.<renderer>` wrapper as well as renderer objects
/// appearing directly as a child.
BrowseVideoEntry? _tryExtractEntry(
  Map<dynamic, dynamic> node,
  DateTime fetchedAt,
) {
  // richItemRenderer.content.<renderer>
  final richItem = node['richItemRenderer'];
  if (richItem is Map) {
    final inner = richItem['content'];
    if (inner is Map) {
      final entry = _tryExtractRendererMap(inner, fetchedAt);
      if (entry != null) return entry;
    }
  }

  // Standalone renderer.
  return _tryExtractRendererMap(node, fetchedAt);
}

/// Tries to extract a [BrowseVideoEntry] from a Map that holds a single
/// renderer object (i.e. one of the recognised renderer keys is present
/// directly). Returns `null` when the map doesn't match a known shape.
BrowseVideoEntry? _tryExtractRendererMap(
  Map<dynamic, dynamic> node,
  DateTime fetchedAt,
) {
  // Older renderer family (2014–2024). They share a similar shape
  // (`videoId`, `title`, `thumbnail`, `lengthText`, `publishedTimeText`,
  // `viewCountText`); one parser handles them all.
  for (final key in const [
    'videoRenderer',
    'gridVideoRenderer',
    'compactVideoRenderer',
  ]) {
    final renderer = node[key];
    if (renderer is Map) {
      final entry = _parseVideoRenderer(
        renderer.cast<String, dynamic>(),
        fetchedAt,
      );
      if (entry != null) return entry;
    }
  }

  // Newer "view model" renderer family (2024+). TED's browse response uses
  // `lockupViewModel` for individual videos.
  final lockup = node['lockupViewModel'];
  if (lockup is Map) {
    final entry = _parseLockupViewModel(lockup, fetchedAt);
    if (entry != null) return entry;
  }

  // Shorts. We extract the videoId for visibility but the existing
  // discover refresh already filters Shorts in the RSS layer; this is a
  // best-effort parse.
  final shortsLockup = node['shortsLockupViewModel'];
  if (shortsLockup is Map) {
    final entry = _parseShortsLockupViewModel(shortsLockup, fetchedAt);
    if (entry != null) return entry;
  }

  return null;
}

/// Parses a `lockupViewModel` node (the modern 2024+ InnerTube renderer).
/// Structure (verified against yt-dlp's `_extract_lockup_view_model`):
///
/// ```text
/// lockupViewModel:
///   contentId: "<videoId>"
///   contentType: "LOCKUP_CONTENT_TYPE_VIDEO" | ... | (absent on some shapes)
///   contentImage:
///     thumbnailViewModel:
///       image:
///         sources: [ { url: "..." }, ... ]
///       overlays: [
///         thumbnailBottomOverlayViewModel: { badges: [ { thumbnailBadgeViewModel: { text: "12:34" } } ] }
///         // OR
///         thumbnailOverlayBadgeViewModel: { thumbnailBadges: [ ... ] }
///       ]
///   metadata:
///     lockupMetadataViewModel:
///       title: { content: "Title" }
///       metadata:
///         contentMetadataViewModel:
///           metadataRows: [
///             { metadataParts: [ { text: { content: "12K views" } }, ... ] },
///             { metadataParts: [ { text: { content: "3 days ago" } } ] }
///           ]
/// ```
BrowseVideoEntry? _parseLockupViewModel(
  Map<dynamic, dynamic> l,
  DateTime fetchedAt,
) {
  final videoId = l['contentId'];
  if (videoId is! String || videoId.isEmpty) return null;

  // Skip non-video lockups (playlists, podcasts, etc.). `contentType` is
  // sometimes absent, so we treat absence as "assume video".
  final contentType = l['contentType'];
  if (contentType is String &&
      contentType != 'LOCKUP_CONTENT_TYPE_VIDEO' &&
      contentType.isNotEmpty) {
    return null;
  }

  // Title: metadata.lockupMetadataViewModel.title.content
  final lockupMdvm = _readMap(
    l['metadata'],
  )?.cast<String, dynamic>()['lockupMetadataViewModel'];
  String? title;
  if (lockupMdvm is Map) {
    final titleRaw = lockupMdvm['title'];
    if (titleRaw is Map) {
      final content = titleRaw['content'];
      if (content is String) title = content;
      title ??= _readTitle(titleRaw);
    }
  }

  // Thumbnail: contentImage.thumbnailViewModel.image.sources[0].url
  String? thumbnailUrl;
  final contentImage = _readMap(l['contentImage']);
  if (contentImage != null) {
    final thumbVm = _readMap(contentImage['thumbnailViewModel']);
    if (thumbVm != null) {
      final image = _readMap(thumbVm['image']);
      if (image != null) {
        final sources = image['sources'];
        if (sources is List) {
          for (final s in sources) {
            if (s is Map && s['url'] is String) {
              thumbnailUrl = s['url'] as String;
              break;
            }
          }
        }
      }
    }
  }

  // Duration: contentImage.thumbnailViewModel.overlays[*].badgeViewModel.text
  int? durationSeconds;
  if (contentImage != null) {
    final thumbVm = _readMap(contentImage['thumbnailViewModel']);
    final overlays = thumbVm?['overlays'];
    if (overlays is List) {
      for (final overlay in overlays) {
        if (overlay is! Map) continue;
        final text = _readLockupBadgeText(overlay);
        if (text != null) {
          durationSeconds = parseInnerTubeLengthText(text);
          if (durationSeconds != null) break;
        }
      }
    }
  }

  // Published time + view count: metadataRows[*].metadataParts[*].text.content
  String? relativeTimeText;
  if (lockupMdvm is Map) {
    final innerMeta = _readMap(lockupMdvm['metadata']);
    final contentMeta = innerMeta == null
        ? null
        : _readMap(innerMeta['contentMetadataViewModel']);
    final rows = contentMeta?['metadataRows'];
    if (rows is List) {
      for (final row in rows) {
        if (row is! Map) continue;
        final parts = row['metadataParts'];
        if (parts is! List || parts.isEmpty) continue;
        // Last metadataPart of the last row: usually the relative time text.
        final lastPart = parts.last;
        if (lastPart is Map) {
          final text = _readMap(lastPart['text']);
          if (text != null) {
            final content = text['content'];
            if (content is String && _looksLikeRelativeTime(content)) {
              relativeTimeText = content;
            }
          }
        }
      }
    }
  }

  DateTime publishedAt = fetchedAt;
  if (relativeTimeText != null) {
    publishedAt = parseInnerTubePublishedTimeText(relativeTimeText, fetchedAt);
  }

  return BrowseVideoEntry(
    videoId: videoId,
    title: title ?? videoId,
    thumbnailUrl: thumbnailUrl,
    durationSeconds: durationSeconds,
    publishedAt: publishedAt,
  );
}

/// Reads the duration text from a single overlay entry in a `lockupViewModel`.
/// Two shapes are supported:
///
/// 1. `thumbnailBottomOverlayViewModel.badges[*].thumbnailBadgeViewModel.text`
/// 2. `thumbnailOverlayBadgeViewModel.thumbnailBadges[*].thumbnailBadgeViewModel.text`
String? _readLockupBadgeText(Map<dynamic, dynamic> overlay) {
  // Shape 1: thumbnailBottomOverlayViewModel.badges
  final bottom = overlay['thumbnailBottomOverlayViewModel'];
  if (bottom is Map) {
    final badges = bottom['badges'];
    if (badges is List) {
      for (final b in badges) {
        if (b is! Map) continue;
        final badge = _readMap(b['thumbnailBadgeViewModel']);
        if (badge != null && badge['text'] is String) {
          return badge['text'] as String;
        }
      }
    }
  }
  // Shape 2: thumbnailOverlayBadgeViewModel.thumbnailBadges
  final top = overlay['thumbnailOverlayBadgeViewModel'];
  if (top is Map) {
    final badges = top['thumbnailBadges'];
    if (badges is List) {
      for (final b in badges) {
        if (b is! Map) continue;
        final badge = _readMap(b['thumbnailBadgeViewModel']);
        if (badge != null && badge['text'] is String) {
          return badge['text'] as String;
        }
      }
    }
  }
  return null;
}

/// Parses a `shortsLockupViewModel` node. We extract the videoId (via
/// `onTap.innertubeCommand.reelWatchEndpoint.videoId`) but defer most
/// metadata to playback-time enrichment; the RSS layer filters Shorts.
BrowseVideoEntry? _parseShortsLockupViewModel(
  Map<dynamic, dynamic> s,
  DateTime fetchedAt,
) {
  final onTap = s['onTap'];
  if (onTap is! Map) return null;
  final command = onTap['innertubeCommand'];
  if (command is! Map) return null;
  final reelWatch = command['reelWatchEndpoint'];
  if (reelWatch is! Map) return null;
  final videoId = reelWatch['videoId'];
  if (videoId is! String || videoId.isEmpty) return null;
  return BrowseVideoEntry(
    videoId: videoId,
    title: videoId,
    publishedAt: fetchedAt,
  );
}

/// True when the string looks like a relative-time phrase we can parse
/// (e.g. "3 days ago", "Streamed live 2 days ago", "Premiered 5 months ago").
bool _looksLikeRelativeTime(String text) {
  final lower = text.toLowerCase();
  if (lower.contains('streamed live') || lower.contains('premiered'))
    return true;
  return RegExp(
    r'\d+\s+(second|minute|hour|day|week|month|year)s?\s+ago',
  ).hasMatch(lower);
}

Map<String, dynamic>? _readMap(dynamic raw) =>
    raw is Map ? raw.cast<String, dynamic>() : null;

List<dynamic>? _findTabs(Map<String, dynamic> json) {
  final outer = json['contents'];
  if (outer is! Map) return null;
  final twoCol = outer['twoColumnBrowseResultsRenderer'];
  if (twoCol is! Map) return null;
  final tabs = twoCol['tabs'];
  return tabs is List ? tabs : null;
}

Map<String, dynamic>? _tabContent(Map<dynamic, dynamic> tab) {
  final tabRenderer = tab['tabRenderer'];
  if (tabRenderer is! Map) return null;
  final content = tabRenderer['content'];
  return content is Map<String, dynamic> ? content : null;
}

BrowseVideoEntry? _parseVideoRenderer(
  Map<String, dynamic> v,
  DateTime fetchedAt,
) {
  final videoId = v['videoId'];
  if (videoId is! String || videoId.isEmpty) return null;

  final title = _readTitle(v['title']) ?? videoId;

  final thumbnailUrl = _readThumbnailUrl(v['thumbnail']);

  final lengthText = _readLengthText(v);
  final durationSeconds = lengthText == null
      ? null
      : parseInnerTubeLengthText(lengthText);

  final publishedAt = _readSimpleText(v['publishedTimeText']) == null
      ? fetchedAt
      : parseInnerTubePublishedTimeText(
          _readSimpleText(v['publishedTimeText'])!,
          fetchedAt,
        );

  final viewCountText = _readSimpleText(v['viewCountText']);

  return BrowseVideoEntry(
    videoId: videoId,
    title: title,
    thumbnailUrl: thumbnailUrl,
    durationSeconds: durationSeconds,
    publishedAt: publishedAt,
    viewCountText: viewCountText,
  );
}

/// Reads the duration string from a videoRenderer / gridVideoRenderer. Looks
/// at three places in order:
/// 1. `lengthText.simpleText` (canonical location on `videoRenderer`).
/// 2. `thumbnailOverlays[*].thumbnailOverlayTimeStatusRenderer.text.simpleText`
///    (canonical location on `gridVideoRenderer` — the duration is rendered as
///    an overlay, not as a sibling field).
/// 3. A top-level `thumbnailOverlayTimeStatusRenderer.text.simpleText`
///    (older responses).
String? _readLengthText(Map<String, dynamic> v) {
  final direct = _readSimpleText(v['lengthText']);
  if (direct != null) return direct;

  final overlays = v['thumbnailOverlays'];
  if (overlays is List) {
    for (final overlay in overlays) {
      if (overlay is! Map) continue;
      final status = overlay['thumbnailOverlayTimeStatusRenderer'];
      if (status is! Map) continue;
      final text = _readSimpleText(status['text']);
      if (text != null) return text;
    }
  }

  final legacy = v['thumbnailOverlayTimeStatusRenderer'];
  if (legacy is Map) {
    final text = _readSimpleText(legacy['text']);
    if (text != null) return text;
  }
  return null;
}

String? _readTitle(dynamic raw) {
  if (raw is! Map) return null;
  final runs = raw['runs'];
  if (runs is List) {
    final parts = <String>[];
    for (final r in runs) {
      if (r is Map) {
        final text = r['text'];
        if (text is String) parts.add(text);
      }
    }
    if (parts.isNotEmpty) return parts.join();
  }
  final simple = raw['simpleText'];
  return simple is String ? simple : null;
}

String? _readSimpleText(dynamic raw) {
  if (raw is Map && raw['simpleText'] is String) {
    return raw['simpleText'] as String;
  }
  return null;
}

String? _readThumbnailUrl(dynamic raw) {
  if (raw is! Map) return null;
  final thumbs = raw['thumbnails'];
  if (thumbs is List) {
    for (final t in thumbs) {
      if (t is Map && t['url'] is String) {
        return t['url'] as String;
      }
    }
  }
  return null;
}

/// Parses InnerTube `lengthText.simpleText` ("H:MM:SS" / "MM:SS" / "SS") into
/// whole seconds. Returns `null` when the input is missing, empty, or not a
/// parseable duration. "0:00" is treated as null so we do not cache a
/// zero-second duration that would block the legacy enrichment path later.
int? parseInnerTubeLengthText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  // Strip a trailing locale suffix like " hrs" if present.
  final stripped = trimmed.replaceFirst(
    RegExp(r'\s+(?:hrs?|min(?:utes?)?|seconds?)\s*$', caseSensitive: false),
    '',
  );
  final parts = stripped.split(':');
  if (parts.isEmpty || parts.length > 3) return null;

  final ints = <int>[];
  for (final p in parts) {
    final n = int.tryParse(p.trim());
    if (n == null) return null;
    ints.add(n);
  }
  if (ints.any((n) => n < 0)) return null;

  final total = switch (ints.length) {
    1 => ints[0],
    2 => ints[0] * 60 + ints[1],
    _ => ints[0] * 3600 + ints[1] * 60 + ints[2],
  };
  return total > 0 ? total : null;
}

/// Parses InnerTube `publishedTimeText.simpleText` ("3 days ago",
/// "Streamed live 2 days ago", "Premiered 5 months ago") into a UTC
/// [DateTime] by subtracting the relative duration from [fetchedAt]. Returns
/// [fetchedAt] itself for shapes the parser does not recognize (defensive
/// fallback so the entry is still cached).
DateTime parseInnerTubePublishedTimeText(String text, DateTime fetchedAt) {
  var working = text.trim();

  // Strip common prefixes that YouTube prepends.
  for (final prefix in const [
    'Streamed live ',
    'Premiered ',
    'Scheduled for ',
    'Starts ',
  ]) {
    if (working.startsWith(prefix)) {
      working = working.substring(prefix.length);
    }
  }

  final re = RegExp(
    r'^(\d+)\s+(year|years|month|months|week|weeks|day|days|hour|hours|minute|minutes)\s+ago$',
    caseSensitive: false,
  );
  final m = re.firstMatch(working);
  if (m == null) return fetchedAt;

  final n = int.parse(m.group(1)!);
  final unit = m.group(2)!.toLowerCase();
  final months = {'month', 'months'};
  final years = {'year', 'years'};
  final weeks = {'week', 'weeks'};
  final days = {'day', 'days'};
  final hours = {'hour', 'hours'};
  final minutes = {'minute', 'minutes'};

  if (months.contains(unit)) return fetchedAt.subtract(Duration(days: n * 30));
  if (years.contains(unit)) return fetchedAt.subtract(Duration(days: n * 365));
  if (weeks.contains(unit)) return fetchedAt.subtract(Duration(days: n * 7));
  if (days.contains(unit)) return fetchedAt.subtract(Duration(days: n));
  if (hours.contains(unit)) return fetchedAt.subtract(Duration(hours: n));
  if (minutes.contains(unit)) {
    return fetchedAt.subtract(Duration(minutes: n));
  }
  return fetchedAt;
}
