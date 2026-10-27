part of 'youtube_session.dart';

/// First-play unmute state machine and the page-side seek hand-off.
mixin YoutubeSessionVolumeRestore on YoutubeSessionBase {
  /// First-play unmute is deferred until [position] advances (or fallback).
  bool _volumeRestorePending = false;
  Duration? _volumeRestoreBaselinePosition;
  int _progressAdvanceTicks = 0;

  /// Generation of the loaded watch document. Bumped on every open and watch
  /// load stop (ads reload the page into a fresh document whose `<video>`
  /// starts muted again).
  int _documentGen = 0;

  /// [_documentGen] for which volume was last restored, or `-1` when never.
  /// The unmute runs at most once per document: redundant programmatic
  /// unMutes are pause triggers under Chromium's autoplay gesture lock (the
  /// play-then-pause root cause), so later `playing` events in an already
  /// restored document must not touch volume at all.
  int _volumeRestoredDocGen = -1;

  double _volumeNormalized = 1;
  double? _pendingSeekSeconds;

  bool get volumeRestorePending => _volumeRestorePending;
  int get documentGen => _documentGen;
  int get volumeRestoredDocGen => _volumeRestoredDocGen;
  double get volumeNormalized => _volumeNormalized;

  /// True when the current document still needs its first volume restore.
  bool get needsVolumeRestore =>
      _volumeRestoredDocGen != _documentGen && !_disposed;

  void clearVolumeRestorePending() {
    _volumeRestorePending = false;
    _volumeRestoreBaselinePosition = null;
    _progressAdvanceTicks = 0;
  }

  /// Pins the current document as volume-restored so later `playing` events
  /// skip the unmute entirely (idempotence against the gesture lock).
  void noteVolumeRestored() => _volumeRestoredDocGen = _documentGen;

  /// Bumps the watch-document generation (open / watch load stop).
  void noteWatchDocumentLoaded() => _documentGen++;

  void armVolumeRestorePending({required Duration baseline}) {
    _volumeRestorePending = true;
    _volumeRestoreBaselinePosition = baseline;
    _progressAdvanceTicks = 0;
  }

  /// Returns true when [position] has advanced enough to safely unmute.
  bool noteProgressForVolumeRestore(Duration position) {
    if (!_volumeRestorePending) return false;
    final baseline = _volumeRestoreBaselinePosition ?? Duration.zero;
    if (position > baseline) {
      _progressAdvanceTicks++;
      _volumeRestoreBaselinePosition = position;
    }
    return _progressAdvanceTicks >= YoutubeSession.progressConfirmTicks;
  }

  /// Stores the normalized volume and returns the clamped value applied to
  /// the page player.
  double storeVolumeNormalized(double volume) {
    _volumeNormalized = volume.clamp(0, 1);
    return _volumeNormalized;
  }

  /// Seek requested from the page side (ad-reload position hand-off).
  void setPendingSeekSeconds(double? seconds) => _pendingSeekSeconds = seconds;

  /// Claims and clears the page-side pending seek.
  double? takePendingSeekSeconds() {
    final seconds = _pendingSeekSeconds;
    _pendingSeekSeconds = null;
    return seconds;
  }
}
