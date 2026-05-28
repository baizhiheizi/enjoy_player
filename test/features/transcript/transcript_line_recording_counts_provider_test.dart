import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_recording_counts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

const _mediaId = 'media-counts';
const _line = TranscriptLine(text: 'Hello', startMs: 0, durationMs: 2000);

RecordingRow _recording({required int start, required int duration}) {
  final now = DateTime.utc(2026, 1, 1);
  return RecordingRow(
    id: 'r-$start',
    targetType: 'Audio',
    targetId: _mediaId,
    referenceStart: start,
    referenceDuration: duration,
    referenceText: 'ref',
    language: 'en',
    duration: duration,
    md5: null,
    audioUrl: null,
    pronunciationScore: null,
    assessmentJson: null,
    localPath: null,
    syncStatus: null,
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('resolveTranscriptLineRecordingCounts', () {
    test('returns counts when all inputs are ready', () {
      expect(
        resolveTranscriptLineRecordingCounts(
          linesAsync: const AsyncData([_line]),
          targetTypeAsync: const AsyncData('Audio'),
          recordingsAsync: AsyncData([
            _recording(start: 0, duration: 1000),
          ]),
          mediaId: _mediaId,
        ),
        {0: 1},
      );
    });

    test('returns null while recordings are loading', () {
      expect(
        resolveTranscriptLineRecordingCounts(
          linesAsync: const AsyncData([_line]),
          targetTypeAsync: const AsyncData('Audio'),
          recordingsAsync: const AsyncLoading(),
          mediaId: _mediaId,
        ),
        isNull,
      );
    });

    test('returns null while target type is loading', () {
      expect(
        resolveTranscriptLineRecordingCounts(
          linesAsync: const AsyncData([_line]),
          targetTypeAsync: const AsyncLoading(),
          recordingsAsync: const AsyncData([]),
          mediaId: _mediaId,
        ),
        isNull,
      );
    });

    test('returns empty map when recordings fail', () {
      final logs = <LogRecord>[];
      final logger = Logger('test')
        ..onRecord.listen(logs.add);

      expect(
        resolveTranscriptLineRecordingCounts(
          linesAsync: const AsyncData([_line]),
          targetTypeAsync: const AsyncData('Audio'),
          recordingsAsync: AsyncError(
            Exception('sync failed'),
            StackTrace.empty,
          ),
          mediaId: _mediaId,
          log: logger,
        ),
        isEmpty,
      );
      expect(logs, isNotEmpty);
    });

    test('returns empty map when target type resolves to null', () {
      expect(
        resolveTranscriptLineRecordingCounts(
          linesAsync: const AsyncData([_line]),
          targetTypeAsync: const AsyncData(null),
          recordingsAsync: const AsyncData([]),
          mediaId: _mediaId,
        ),
        isEmpty,
      );
    });
  });
}
