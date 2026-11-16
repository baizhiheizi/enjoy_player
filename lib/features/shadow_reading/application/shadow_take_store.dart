/// Shadow-reading take capture + persistence (issue #597).
///
/// A deep module behind a small interface: `start` / `cancel` /
/// `stopAndPersist` / `deleteTake`. It hides take-path construction and
/// identity (uuid filename = row id), WAV hashing / duration parsing, the
/// silence heuristic, 18-field [RecordingRow] construction, Drift insert, and
/// sync enqueue; the microphone lifecycle itself (permission, the shared
/// config, the recreate-after-stop workaround) lives in [MicCaptureSession].
/// The panel shrinks to view + callbacks; tests exercise the seam directly.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import 'package:enjoy_player/core/audio/mic_capture_session.dart';
import 'package:enjoy_player/core/audio/mic_recorder.dart';
import 'package:enjoy_player/core/audio/wav_duration_ms.dart';
import 'package:enjoy_player/core/audio/wav_signal_peak.dart';
import 'package:enjoy_player/core/echo/echo_region_key.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

final _log = logNamed('ShadowTakeStore');

/// Outcome of a successful [ShadowTakeStore.stopAndPersist].
class TakePersistResult {
  const TakePersistResult({required this.row, required this.looksSilent});

  final RecordingRow row;

  /// True when the captured WAV looks silent (low RMS / non-zero ratio). The
  /// caller surfaces a warning; the row is persisted regardless.
  final bool looksSilent;
}

/// The captured WAV is missing or unreadable at persist time.
final class TakeFileMissingException implements Exception {
  const TakeFileMissingException(this.path);

  final String path;

  @override
  String toString() => 'recording wav missing at path: $path';
}

/// Builds stores already bound to the app's database and sync seam.
///
/// Supplied by `shadowTakeStoreFactoryProvider` so callers that own a store
/// for their own lifetime (the shadow-reading panel) never wire the handles
/// themselves. Tests pass a `recorderFactory` / `takeDirectory` to stay off
/// the real microphone and the real documents directory.
///
/// A class rather than a function typedef because a provider returning a
/// function type trips `riverpod_generator`'s type resolution.
class ShadowTakeStoreFactory {
  const ShadowTakeStoreFactory({
    required AppDatabase db,
    required SyncEnqueueFn enqueueSync,
  })
    // ignore: prefer_initializing_formals
    : _db = db,
       // ignore: prefer_initializing_formals
       _enqueueSync = enqueueSync;

  final AppDatabase _db;
  final SyncEnqueueFn _enqueueSync;

  ShadowTakeStore call({
    MicRecorder Function()? recorderFactory,
    Directory? takeDirectory,
  }) => ShadowTakeStore(
    db: _db,
    enqueueSync: _enqueueSync,
    recorderFactory: recorderFactory,
    takeDirectory: takeDirectory,
  );
}

final class _TakeAudioFacts {
  const _TakeAudioFacts({
    required this.byteLength,
    required this.sha256Hex,
    required this.durationMs,
    required this.peak,
  });
  final int byteLength;
  final String sha256Hex;
  final int? durationMs;
  final WavPeakScan? peak;
}

_TakeAudioFacts _readTakeAudioFacts(String wavPath) {
  final bytes = File(wavPath).readAsBytesSync();
  return _TakeAudioFacts(
    byteLength: bytes.length,
    sha256Hex: sha256.convert(bytes).toString(),
    durationMs: wavDurationMsFromBytes(bytes),
    peak: scanWavDataPeakFromBytes(bytes),
  );
}

class ShadowTakeStore {
  ShadowTakeStore({
    required AppDatabase db,
    required SyncEnqueueFn enqueueSync,
    MicRecorder Function()? recorderFactory,
    Directory? takeDirectory,
  }) {
    _db = db;
    _enqueueSync = enqueueSync;
    _takeDirectoryOverride = takeDirectory;
    _capture = MicCaptureSession(recorderFactory: recorderFactory);
  }

  late final AppDatabase _db;
  late final SyncEnqueueFn _enqueueSync;
  late final Directory? _takeDirectoryOverride;
  late final MicCaptureSession _capture;

  /// Whether a take capture is currently in flight on the microphone.
  bool get isActive => _capture.isActive;

  Future<Directory> _takeDirectory() async {
    final override = _takeDirectoryOverride;
    if (override != null) return override;
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'recordings'));
  }

  /// Begins capturing a take. Throws [MicPermissionDeniedException] when the
  /// OS denies the microphone, or propagates recorder errors.
  Future<void> start({required InputDevice? device}) async {
    final dir = await _takeDirectory();
    final id = const Uuid().v4();
    await _capture.start(directory: dir, filename: '$id.wav', device: device);
  }

  /// Discards an in-progress take without persisting it.
  Future<void> cancel() async {
    await _capture.cancel();
  }

  /// Stops the capture and persists it as a [RecordingRow]. Returns the row
  /// plus a silence verdict; throws [TakeFileMissingException] when nothing
  /// was captured, or propagates DB / sync errors for the caller to surface.
  Future<TakePersistResult> stopAndPersist({
    required EchoRegionKey region,
  }) async {
    final path = await _capture.stop();

    if (path == null || path.isEmpty) {
      _log.warning('recorder.stop returned no path');
      throw const TakeFileMissingException('');
    }
    _log.fine('recorder.stop wrote $path');
    return _persistRecording(path, region);
  }

  /// Removes a persisted take: sync-enqueue delete, file GC, then DAO delete.
  /// Callers stop any preview playback of [row] first (a presentation concern).
  Future<void> deleteTake(RecordingRow row) async {
    await _enqueueSync(SyncEntityType.recording, row.id, SyncAction.delete);
    final lp = row.localPath;
    if (lp != null && lp.isNotEmpty) {
      await _deleteFileIfExists(lp);
    }
    await _db.recordingDao.deleteId(row.id);
  }

  /// Stops any in-flight capture (discarding the WAV) and releases the
  /// recorder. Safe to call from a widget `dispose`.
  Future<void> dispose() async {
    await _capture.dispose();
  }

  Future<void> _deleteFileIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e, st) {
      _log.fine('delete recording wav failed', e, st);
    }
  }

  Future<TakePersistResult> _persistRecording(
    String wavPath,
    EchoRegionKey region,
  ) async {
    final file = File(wavPath);
    if (!await file.exists()) {
      _log.warning('recording wav missing at path: $wavPath');
      throw TakeFileMissingException(wavPath);
    }
    final facts = await Isolate.run(
      () => _readTakeAudioFacts(wavPath),
      debugName: 'shadow-take-facts',
    );

    final durationMs = facts.durationMs ?? 0;
    if (facts.durationMs == null && facts.byteLength > 0) {
      _log.warning(
        'could not parse WAV duration ($wavPath, ${facts.byteLength} bytes)',
      );
    }

    var looksSilent = false;
    final peak = facts.peak;
    if (peak != null) {
      _log.fine(
        'recording wav fmt=${peak.fmt.audioFormat} '
        'ch=${peak.fmt.numChannels} ${peak.fmt.sampleRate}Hz '
        '${peak.fmt.bitsPerSample}bit '
        'peak≈${peak.peakNormalized.toStringAsFixed(5)} '
        'rms≈${peak.rmsNormalized.toStringAsFixed(6)} '
        'nonZero=${(peak.nonZeroRatio * 100).toStringAsFixed(2)}% '
        'samples=${peak.totalSamples} '
        'bytes=${facts.byteLength} durMs=$durationMs',
      );
      const minRms = 0.001;
      const minNonZeroRatio = 0.01;
      looksSilent =
          peak.rmsNormalized < minRms || peak.nonZeroRatio < minNonZeroRatio;
      if (looksSilent) {
        _log.warning(
          'recording wav appears silent '
          '(peak≈${peak.peakNormalized.toStringAsFixed(6)} '
          'rms≈${peak.rmsNormalized.toStringAsFixed(6)} '
          'nonZero=${(peak.nonZeroRatio * 100).toStringAsFixed(2)}%). '
          'Check Windows microphone privacy / default input device.',
        );
      }
    }

    final id = p.basenameWithoutExtension(wavPath);
    final now = DateTime.now();
    final row = RecordingRow(
      id: id,
      targetType: region.targetType,
      targetId: region.targetId,
      referenceStart: region.startMs,
      referenceDuration: region.durationMs,
      referenceText: region.referenceText,
      language: region.language,
      duration: durationMs,
      md5: facts.sha256Hex,
      audioUrl: null,
      pronunciationScore: null,
      assessmentJson: null,
      localPath: wavPath,
      syncStatus: 'local',
      serverUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    );
    await _db.recordingDao.insertRow(row);
    await _enqueueSync(SyncEntityType.recording, id, SyncAction.create);
    return TakePersistResult(row: row, looksSilent: looksSilent);
  }
}
