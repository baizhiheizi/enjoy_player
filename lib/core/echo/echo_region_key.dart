import 'package:flutter/foundation.dart';

/// Identity of the echo region a practice surface (shadow-reading takes,
/// dictation attempts) is keyed on: which media, which window, which
/// reference text and language.
///
/// [startMs] and [durationMs] are canonical; [endMs] derives from them so
/// every surface computes the same window from the same pair. The
/// seconds-to-milliseconds rounding lives in [EchoRegionKey.fromSeconds] —
/// the only place it should happen.
@immutable
class EchoRegionKey {
  const EchoRegionKey({
    required this.targetType,
    required this.targetId,
    required this.startMs,
    required this.durationMs,
    required this.referenceText,
    required this.language,
  });

  factory EchoRegionKey.fromSeconds({
    required String targetType,
    required String targetId,
    required String referenceText,
    required String language,
    required double startSec,
    required double endSec,
  }) {
    return EchoRegionKey(
      targetType: targetType,
      targetId: targetId,
      startMs: (startSec * 1000).round(),
      durationMs: ((endSec - startSec) * 1000).round(),
      referenceText: referenceText,
      language: language,
    );
  }

  final String targetType;
  final String targetId;
  final int startMs;
  final int durationMs;
  final String referenceText;
  final String language;

  int get endMs => startMs + durationMs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EchoRegionKey &&
          runtimeType == other.runtimeType &&
          targetType == other.targetType &&
          targetId == other.targetId &&
          startMs == other.startMs &&
          durationMs == other.durationMs &&
          referenceText == other.referenceText &&
          language == other.language;

  @override
  int get hashCode => Object.hash(
    targetType,
    targetId,
    startMs,
    durationMs,
    referenceText,
    language,
  );

  @override
  String toString() =>
      'EchoRegionKey($targetType/$targetId [$startMs..$endMs]ms lang=$language)';
}
