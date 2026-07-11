/// Cache + cancellation layer for echo pitch analysis.
///
/// Wraps the [EchoPitchPipeline] (FFmpeg → decode → YIN pitch) so that:
///
/// * Rapidly changing the echo region **cancels** the in-flight extraction
///   (kills the live FFmpeg process/session via [EchoPcmCancelToken]) instead
///   of merely discarding its result.
/// * Re-opening the same region/recording returns the **cached** analysis
///   without re-spawning FFmpeg.
///
/// Exposed as a keep-alive [echoPitchAnalysisServiceProvider] singleton.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/echo_segment_pcm_extractor.dart';
import '../domain/echo_region_analysis.dart';
import 'echo_region_pitch_analyzer.dart';

/// Underlying analysis primitive the service delegates to. Injectable so the
/// cancellation/cache logic is unit-testable without a live FFmpeg.
abstract interface class EchoPitchPipeline {
  Future<EchoRegionAnalysisResult> analyzeSegment({
    required String mediaPath,
    required double startSec,
    required double endSec,
    EchoPcmCancelToken? token,
  });

  Future<EchoRegionAnalysisResult> analyzeFile({
    required String mediaPath,
    EchoPcmCancelToken? token,
  });
}

/// Default [EchoPitchPipeline] backed by the real FFmpeg + isolate pipeline.
class DefaultEchoPitchPipeline implements EchoPitchPipeline {
  const DefaultEchoPitchPipeline();

  @override
  Future<EchoRegionAnalysisResult> analyzeSegment({
    required String mediaPath,
    required double startSec,
    required double endSec,
    EchoPcmCancelToken? token,
  }) {
    return analyzeMediaTimeRange(
      mediaPath: mediaPath,
      startSec: startSec,
      endSec: endSec,
      token: token,
    );
  }

  @override
  Future<EchoRegionAnalysisResult> analyzeFile({
    required String mediaPath,
    EchoPcmCancelToken? token,
  }) {
    return analyzeMediaFileFull(mediaPath: mediaPath, token: token);
  }
}

/// Cache + cancellation service for echo pitch analysis.
///
/// Methods return `null` when a request was **superseded** (cancelled by a
/// newer request) — callers should treat that as "do nothing", distinct from a
/// thrown [EchoPcmExtractionException] which signals a real failure.
class EchoPitchAnalysisService {
  EchoPitchAnalysisService({this.pipeline = const DefaultEchoPitchPipeline()});

  final EchoPitchPipeline pipeline;

  static const int _maxCacheEntries = 8;

  final Map<_RefCacheKey, EchoRegionAnalysisResult> _refCache = {};
  final Map<String, EchoRegionAnalysisResult> _userCache = {};

  EchoPcmCancelToken? _refToken;
  EchoPcmCancelToken? _userToken;

  /// Analyzes (or returns the cached) reference region `[startSec, endSec)`.
  ///
  /// Returns the result, or `null` if the request was cancelled by a newer
  /// call. Throws [EchoPcmExtractionException] on a genuine failure.
  Future<EchoRegionAnalysisResult?> analyzeReference({
    required String mediaPath,
    required double startSec,
    required double endSec,
  }) async {
    final key = _RefCacheKey(mediaPath, startSec, endSec);
    final cached = _refCache[key];
    if (cached != null) return cached;

    // Cancel any in-flight reference extraction (real cancellation — the FFmpeg
    // process/session is killed, not merely ignored).
    _refToken?.cancel();
    final token = EchoPcmCancelToken();
    _refToken = token;
    try {
      final result = await pipeline.analyzeSegment(
        mediaPath: mediaPath,
        startSec: startSec,
        endSec: endSec,
        token: token,
      );
      if (token.isCancelled) return null;
      _storeRef(key, result);
      return result;
    } on EchoPcmExtractionException catch (e) {
      if (e.reason == EchoPcmFailureReason.cancelled) return null;
      rethrow;
    } finally {
      if (identical(_refToken, token)) _refToken = null;
    }
  }

  /// Analyzes (or returns the cached) full user recording at [mediaPath].
  ///
  /// Returns the result, or `null` if cancelled by a newer call. Throws
  /// [EchoPcmExtractionException] on a genuine failure.
  Future<EchoRegionAnalysisResult?> analyzeUser({
    required String mediaPath,
  }) async {
    final cached = _userCache[mediaPath];
    if (cached != null) return cached;

    _userToken?.cancel();
    final token = EchoPcmCancelToken();
    _userToken = token;
    try {
      final result = await pipeline.analyzeFile(
        mediaPath: mediaPath,
        token: token,
      );
      if (token.isCancelled) return null;
      _storeUser(mediaPath, result);
      return result;
    } on EchoPcmExtractionException catch (e) {
      if (e.reason == EchoPcmFailureReason.cancelled) return null;
      rethrow;
    } finally {
      if (identical(_userToken, token)) _userToken = null;
    }
  }

  /// Drops all cached results (e.g. when a media file is replaced).
  void clearCache() {
    _refCache.clear();
    _userCache.clear();
  }

  void _storeRef(_RefCacheKey key, EchoRegionAnalysisResult result) {
    while (_refCache.length >= _maxCacheEntries) {
      _refCache.remove(_refCache.keys.first);
    }
    _refCache[key] = result;
  }

  void _storeUser(String path, EchoRegionAnalysisResult result) {
    while (_userCache.length >= _maxCacheEntries) {
      _userCache.remove(_userCache.keys.first);
    }
    _userCache[path] = result;
  }
}

class _RefCacheKey {
  const _RefCacheKey._(this.mediaPath, this.startMs, this.endMs);

  factory _RefCacheKey(String mediaPath, double startSec, double endSec) {
    return _RefCacheKey._(
      mediaPath,
      (startSec * 1000).round(),
      (endSec * 1000).round(),
    );
  }

  final String mediaPath;
  final int startMs;
  final int endMs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _RefCacheKey &&
          other.mediaPath == mediaPath &&
          other.startMs == startMs &&
          other.endMs == endMs;

  @override
  int get hashCode => Object.hash(mediaPath, startMs, endMs);
}

/// Singleton [EchoPitchAnalysisService] (keep-alive so caches survive widget
/// rebuilds). Plain provider literal — no codegen required.
final echoPitchAnalysisServiceProvider = Provider<EchoPitchAnalysisService>((
  ref,
) {
  return EchoPitchAnalysisService();
});
