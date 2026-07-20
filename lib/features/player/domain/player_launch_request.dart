/// Typed expanded-player launch options (query-encoded on `/player/:id`).
library;

/// How the player chrome should present after launch.
enum PlayerLaunchMode {
  /// Full expanded player route.
  expanded,
}

/// Declarative open request for [openMediaLaunchProvider] / router helpers.
final class PlayerLaunchRequest {
  const PlayerLaunchRequest({
    required this.mediaId,
    this.startSec,
    this.endSec,
    this.autoplay = false,
    this.activateClipWindow = false,
    this.mode = PlayerLaunchMode.expanded,
    this.restoreSession,
  });

  /// Vocabulary "Open source": expanded player with the locator echo active.
  factory PlayerLaunchRequest.vocabularyOpenSource({
    required String mediaId,
    required double startSec,
    required double endSec,
  }) {
    return PlayerLaunchRequest(
      mediaId: mediaId,
      startSec: startSec,
      endSec: endSec,
      autoplay: true,
      activateClipWindow: true,
      restoreSession: false,
    );
  }

  /// Parse from a GoRouter [Uri] (path `/player/:mediaId`).
  static PlayerLaunchRequest fromUri(Uri uri, {required String mediaId}) {
    final q = uri.queryParameters;
    final start = double.tryParse(q['start'] ?? '');
    final end = double.tryParse(q['end'] ?? '');
    final autoplay = q['autoplay'] == '1' || q['autoplay'] == 'true';
    final clip = q['clip'] == '1' || q['clip'] == 'true';
    bool? restore;
    if (q.containsKey('norestore')) restore = false;
    if (q.containsKey('restore')) restore = true;
    return PlayerLaunchRequest(
      mediaId: mediaId,
      startSec: start,
      endSec: end,
      autoplay: autoplay,
      activateClipWindow: clip,
      restoreSession: restore,
    );
  }

  final String mediaId;
  final double? startSec;
  final double? endSec;
  final bool autoplay;

  /// When true with [startSec]/[endSec], activate the bounded echo window.
  final bool activateClipWindow;

  final PlayerLaunchMode mode;

  /// When null: restore session iff no explicit [startSec].
  final bool? restoreSession;

  bool get shouldRestoreSession =>
      restoreSession ?? (startSec == null && !activateClipWindow);

  bool get isExplicitLaunch => !shouldRestoreSession;

  /// Location path + query for GoRouter.
  String get location {
    final params = <String, String>{};
    if (startSec != null) {
      params['start'] = _fmt(startSec!);
    }
    if (endSec != null) {
      params['end'] = _fmt(endSec!);
    }
    if (autoplay) params['autoplay'] = '1';
    if (activateClipWindow) params['clip'] = '1';
    if (restoreSession == false) params['norestore'] = '1';
    if (restoreSession == true) params['restore'] = '1';
    final uri = Uri(
      path: '/player/$mediaId',
      queryParameters: params.isEmpty ? null : params,
    );
    return uri.toString();
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerLaunchRequest &&
        other.mediaId == mediaId &&
        other.startSec == startSec &&
        other.endSec == endSec &&
        other.autoplay == autoplay &&
        other.activateClipWindow == activateClipWindow &&
        other.mode == mode &&
        other.restoreSession == restoreSession;
  }

  @override
  int get hashCode => Object.hash(
    mediaId,
    startSec,
    endSec,
    autoplay,
    activateClipWindow,
    mode,
    restoreSession,
  );
}
