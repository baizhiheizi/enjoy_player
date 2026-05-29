/// Resolves YouTube channel URLs, handles, or raw ids to `channel_id`.

library;

import 'package:http/http.dart' as http;

import 'youtube_fetch.dart';

class YoutubeChannelResolveException implements Exception {
  YoutubeChannelResolveException(this.message);

  final String message;

  @override
  String toString() => message;
}

class YoutubeChannelResolved {
  const YoutubeChannelResolved({required this.channelId, this.displayName});

  final String channelId;

  final String? displayName;
}

class YoutubeChannelResolver {
  YoutubeChannelResolver({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static final _channelIdPattern = RegExp(r'^UC[\w-]{22}$');

  static final _urlChannelId = RegExp(r'/channel/(UC[\w-]{22})');

  static final _htmlChannelId = RegExp(r'"channelId"\s*:\s*"(UC[\w-]{22})"');

  static final _htmlExternalId = RegExp(r'"externalId"\s*:\s*"(UC[\w-]{22})"');

  static final _browseChannelId = RegExp(
    r'browse\?[^"]*channel_id=(UC[\w-]{22})',
  );

  static final _htmlOgTitle = RegExp(
    r'<meta\s+property="og:title"\s+content="([^"]+)"',

    caseSensitive: false,
  );

  static final _htmlPageTitle = RegExp(
    r'<title>([^<]+)</title>',

    caseSensitive: false,
  );

  static final _htmlAvatarUrl = RegExp(
    r'"avatar"\s*:\s*\{[^}]*"thumbnails"\s*:\s*\[\s*\{\s*"url"\s*:\s*"([^"]+)"',
  );

  static final _htmlChannelAvatarUrl = RegExp(
    r'"channelAvatarRenderer"[^}]*"thumbnails"\s*:\s*\[\s*\{\s*"url"\s*:\s*"([^"]+)"',
  );

  static const _allowedHosts = {
    'youtube.com',

    'www.youtube.com',

    'm.youtube.com',

    'music.youtube.com',
  };

  Future<String> resolve(String rawInput) async {
    final resolved = await resolveDetailed(rawInput);

    return resolved.channelId;
  }

  Future<YoutubeChannelResolved> resolveDetailed(String rawInput) async {
    final trimmed = rawInput.trim();

    if (trimmed.isEmpty) {
      throw YoutubeChannelResolveException('Channel URL or ID is required.');
    }

    if (_channelIdPattern.hasMatch(trimmed)) {
      return YoutubeChannelResolved(channelId: trimmed);
    }

    final uri = _normalizeInput(trimmed);

    _ensureAllowedHost(uri);

    final fromUrl = _channelIdFromUrl(uri);

    if (fromUrl != null) {
      return YoutubeChannelResolved(channelId: fromUrl);
    }

    final html = await _fetchChannelHtml(uri);

    for (final pattern in [_htmlChannelId, _htmlExternalId, _browseChannelId]) {
      final match = pattern.firstMatch(html);

      if (match != null) {
        return YoutubeChannelResolved(
          channelId: match.group(1)!,

          displayName: _displayNameFromHtml(html),
        );
      }
    }

    throw YoutubeChannelResolveException(
      'Could not resolve a YouTube channel ID from that input.',
    );
  }

  Uri _normalizeInput(String input) {
    if (input.startsWith('@')) {
      return Uri.parse('https://www.youtube.com/$input');
    }

    if (input.startsWith('http://') || input.startsWith('https://')) {
      return Uri.parse(input);
    }

    if (input.contains('/')) {
      return Uri.parse('https://www.youtube.com/$input');
    }

    return Uri.parse('https://www.youtube.com/@$input');
  }

  void _ensureAllowedHost(Uri uri) {
    final host = uri.host.toLowerCase();

    if (!_allowedHosts.contains(host)) {
      throw YoutubeChannelResolveException(
        'Only YouTube channel URLs and handles are supported.',
      );
    }
  }

  String? _channelIdFromUrl(Uri uri) {
    final pathMatch = _urlChannelId.firstMatch(uri.path);

    if (pathMatch != null) return pathMatch.group(1);

    final queryId = uri.queryParameters['channel_id'];

    if (queryId != null && _channelIdPattern.hasMatch(queryId)) return queryId;

    return null;
  }

  Future<String> _fetchChannelHtml(Uri uri) async {
    _ensureAllowedHost(uri);

    final response = await YoutubeFetch.getHtml(_client, uri);

    if (response.statusCode != 200) {
      throw YoutubeChannelResolveException(
        'Could not load channel page (HTTP ${response.statusCode}).',
      );
    }

    return response.body;
  }

  String? _displayNameFromHtml(String html) {
    final og = _htmlOgTitle.firstMatch(html)?.group(1)?.trim();

    if (og != null && og.isNotEmpty) {
      return _cleanDisplayName(og);
    }

    final title = _htmlPageTitle.firstMatch(html)?.group(1)?.trim();

    if (title != null && title.isNotEmpty) {
      return _cleanDisplayName(title);
    }

    return null;
  }

  static String? _cleanDisplayName(String value) {
    var name = value.trim();

    if (name.endsWith(' - YouTube')) {
      name = name.substring(0, name.length - ' - YouTube'.length).trim();
    }

    return name.isEmpty ? null : name;
  }

  /// Public channel page avatar (profile photo), not RSS video thumbnails.

  Future<String?> fetchChannelAvatarUrl(String channelId) async {
    if (!_channelIdPattern.hasMatch(channelId)) return null;

    final uri = Uri.parse('https://www.youtube.com/channel/$channelId');

    final html = await _fetchChannelHtml(uri);

    return parseAvatarUrlFromHtml(html);
  }

  static String? parseAvatarUrlFromHtml(String html) {
    for (final pattern in [_htmlAvatarUrl, _htmlChannelAvatarUrl]) {
      final match = pattern.firstMatch(html);

      if (match case final m?) {
        final url = _unescapeJsonUrl(m.group(1)!);

        if (url.startsWith('https://')) return url;
      }
    }

    return null;
  }

  static String _unescapeJsonUrl(String value) {
    return value
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\/', '/')
        .replaceAll(r'\\', '\\');
  }
}
