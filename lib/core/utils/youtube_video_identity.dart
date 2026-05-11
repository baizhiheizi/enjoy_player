/// YouTube video id parsing and row-level inference (no Flutter / Drift).
///
/// Used by sync JSON parsing and media target resolution so `data/db` does not
/// depend on `features/library`.
library;

final RegExp _bareYoutubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Returns canonical YouTube video id or null.
String? parseYoutubeVideoId(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  if (_bareYoutubeId.hasMatch(s)) return s;

  var uri = Uri.tryParse(s);
  if (uri == null || uri.host.isEmpty) return null;
  final host = uri.host.toLowerCase();

  if (host.contains('youtu.be')) {
    final parts = uri.pathSegments.where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    final seg = parts.first;
    if (_bareYoutubeId.hasMatch(seg)) return seg;
    return null;
  }

  if (host.contains('youtube.com')) {
    final v = uri.queryParameters['v'];
    if (v != null && _bareYoutubeId.hasMatch(v)) return v;

    final parts = uri.pathSegments.where((e) => e.isNotEmpty).toList();
    for (final key in ['embed', 'shorts', 'live']) {
      final i = parts.indexOf(key);
      if (i >= 0 && i + 1 < parts.length) {
        final id = parts[i + 1];
        if (_bareYoutubeId.hasMatch(id)) return id;
      }
    }
  }

  return null;
}

bool _signalsYoutubeFromFields({
  required String vid,
  String? mediaUrl,
  String? source,
}) {
  if (source?.trim() == 'youtube') return true;
  if (parseYoutubeVideoId(mediaUrl ?? '') != null) return true;
  if (parseYoutubeVideoId(vid) != null) return true;
  return false;
}

/// Normalizes `provider` when ingesting server / cloud JSON.
///
/// Never turns an explicit `netflix` row into `youtube`. When `provider` is
/// missing or generic (`user`), infers `youtube` from [source], [mediaUrl], or
/// bare/URL [vid] (local file rows use 64-char hex `vid`; YouTube uses 11-char id).
String normalizeServerVideoProviderFields({
  String? rawProvider,
  required String vid,
  String? mediaUrl,
  String? source,
}) {
  final ex = rawProvider?.trim();
  final exLower = ex?.toLowerCase();
  if (exLower == 'netflix') return 'netflix';

  if (_signalsYoutubeFromFields(
    vid: vid,
    mediaUrl: mediaUrl,
    source: source,
  )) {
    return 'youtube';
  }

  if (exLower == 'youtube') return 'youtube';
  if (ex != null && ex.isNotEmpty) return ex;
  return 'user';
}

/// Non-null when this row should use [YoutubePlayableSource] / WebView playback.
String? youtubePlaybackVideoId({
  required String provider,
  required String vid,
  String? mediaUrl,
  String? source,
}) {
  final p = provider.toLowerCase();
  if (p == 'netflix') return null;

  final fromVid = parseYoutubeVideoId(vid);
  final fromUrl = parseYoutubeVideoId(mediaUrl ?? '');
  final inferred = _signalsYoutubeFromFields(
    vid: vid,
    mediaUrl: mediaUrl,
    source: source,
  );

  final useYt = p == 'youtube' || inferred;
  if (!useYt) return null;

  return fromVid ?? fromUrl;
}
