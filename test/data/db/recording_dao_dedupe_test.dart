import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecordingDao watch dedupe', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    RecordingRow recording({
      required String id,
      String targetType = 'Video',
      String targetId = 'media-1',
      int referenceStart = 0,
      int referenceDuration = 1000,
      String referenceText = 'hello world',
      String language = 'en',
      int duration = 500,
      String? md5 = 'md5-base',
      int? pronunciationScore,
      String? assessmentJson,
      String? syncStatus,
      DateTime? serverUpdatedAt,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      final now = DateTime.utc(2024, 6, 1);
      return RecordingRow(
        id: id,
        targetType: targetType,
        targetId: targetId,
        referenceStart: referenceStart,
        referenceDuration: referenceDuration,
        referenceText: referenceText,
        language: language,
        duration: duration,
        md5: md5,
        audioUrl: null,
        pronunciationScore: pronunciationScore,
        assessmentJson: assessmentJson,
        localPath: null,
        syncStatus: syncStatus,
        serverUpdatedAt: serverUpdatedAt,
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
      );
    }

    test('watchByTarget dedupes identical re-emissions', () async {
      await db.recordingDao.insertRow(
        recording(id: 'rec-1', createdAt: DateTime.utc(2024, 6, 1)),
      );

      final emissions = <List<RecordingRow>>[];
      final sub = db.recordingDao
          .watchByTarget('Video', 'media-1')
          .listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;
      expect(baseline, greaterThanOrEqualTo(1));

      await db.recordingDao.insertRow(
        recording(id: 'rec-1', createdAt: DateTime.utc(2024, 6, 1)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, baseline);

      await sub.cancel();
    });

    test('watchByTarget re-emits when a new recording is added', () async {
      await db.recordingDao.insertRow(
        recording(id: 'rec-1', createdAt: DateTime.utc(2024, 6, 1)),
      );

      final emissions = <List<RecordingRow>>[];
      final sub = db.recordingDao
          .watchByTarget('Video', 'media-1')
          .listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;
      expect(baseline, greaterThanOrEqualTo(1));
      expect(emissions.last, hasLength(1));

      await db.recordingDao.insertRow(
        recording(id: 'rec-2', createdAt: DateTime.utc(2024, 6, 2)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, greaterThan(baseline));
      expect(emissions.last, hasLength(2));

      await sub.cancel();
    });

    test('watchByTarget re-emits when a recording is deleted', () async {
      await db.recordingDao.insertRow(
        recording(id: 'rec-1', createdAt: DateTime.utc(2024, 6, 1)),
      );
      await db.recordingDao.insertRow(
        recording(id: 'rec-2', createdAt: DateTime.utc(2024, 6, 2)),
      );

      final emissions = <List<RecordingRow>>[];
      final sub = db.recordingDao
          .watchByTarget('Video', 'media-1')
          .listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;
      expect(emissions.last, hasLength(2));

      await db.recordingDao.deleteId('rec-2');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, greaterThan(baseline));
      expect(emissions.last, hasLength(1));
      expect(emissions.last.first.id, 'rec-1');

      await sub.cancel();
    });

    test('watchByTarget re-emits when assessment is updated', () async {
      await db.recordingDao.insertRow(
        recording(id: 'rec-1', createdAt: DateTime.utc(2024, 6, 1)),
      );

      final emissions = <List<RecordingRow>>[];
      final sub = db.recordingDao
          .watchByTarget('Video', 'media-1')
          .listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;
      expect(baseline, greaterThanOrEqualTo(1));
      expect(emissions.last.first.pronunciationScore, isNull);

      await db.recordingDao.updateAssessment(
        id: 'rec-1',
        pronunciationScore: 85,
        assessmentJson: '{"score":85}',
        updatedAt: DateTime.utc(2024, 6, 3),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, greaterThan(baseline));
      expect(emissions.last.first.pronunciationScore, 85);

      await sub.cancel();
    });

    test('watchByTarget does not emit for unrelated target inserts', () async {
      await db.recordingDao.insertRow(
        recording(
          id: 'rec-1',
          targetId: 'media-1',
          createdAt: DateTime.utc(2024, 6, 1),
        ),
      );

      final emissions = <List<RecordingRow>>[];
      final sub = db.recordingDao
          .watchByTarget('Video', 'media-1')
          .listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;
      expect(emissions.last, hasLength(1));

      await db.recordingDao.insertRow(
        recording(
          id: 'rec-2',
          targetId: 'media-2',
          createdAt: DateTime.utc(2024, 6, 2),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, baseline);

      await sub.cancel();
    });

    test('watchByEchoRegion dedupes identical re-emissions', () async {
      await db.recordingDao.insertRow(
        recording(
          id: 'rec-1',
          referenceStart: 0,
          referenceDuration: 1000,
          createdAt: DateTime.utc(2024, 6, 1),
        ),
      );

      final emissions = <List<RecordingRow>>[];
      final sub = db.recordingDao
          .watchByEchoRegion(
            targetType: 'Video',
            targetId: 'media-1',
            language: 'en',
            echoStartMs: 0,
            echoEndMs: 2000,
          )
          .listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;
      expect(baseline, greaterThanOrEqualTo(1));

      await db.recordingDao.insertRow(
        recording(
          id: 'rec-1',
          referenceStart: 0,
          referenceDuration: 1000,
          createdAt: DateTime.utc(2024, 6, 1),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, baseline);

      await sub.cancel();
    });

    test('watchByEchoRegion re-emits when a new recording overlaps', () async {
      await db.recordingDao.insertRow(
        recording(
          id: 'rec-1',
          referenceStart: 0,
          referenceDuration: 500,
          createdAt: DateTime.utc(2024, 6, 1),
        ),
      );

      final emissions = <List<RecordingRow>>[];
      final sub = db.recordingDao
          .watchByEchoRegion(
            targetType: 'Video',
            targetId: 'media-1',
            language: 'en',
            echoStartMs: 0,
            echoEndMs: 2000,
          )
          .listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;
      expect(emissions.last, hasLength(1));

      await db.recordingDao.insertRow(
        recording(
          id: 'rec-2',
          referenceStart: 1000,
          referenceDuration: 800,
          createdAt: DateTime.utc(2024, 6, 2),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, greaterThan(baseline));
      expect(emissions.last, hasLength(2));

      await sub.cancel();
    });

    test(
      'watchByEchoRegion does not emit for non-overlapping inserts',
      () async {
        await db.recordingDao.insertRow(
          recording(
            id: 'rec-1',
            referenceStart: 0,
            referenceDuration: 500,
            createdAt: DateTime.utc(2024, 6, 1),
          ),
        );

        final emissions = <List<RecordingRow>>[];
        final sub = db.recordingDao
            .watchByEchoRegion(
              targetType: 'Video',
              targetId: 'media-1',
              language: 'en',
              echoStartMs: 0,
              echoEndMs: 1000,
            )
            .listen(emissions.add);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final baseline = emissions.length;
        expect(emissions.last, hasLength(1));

        await db.recordingDao.insertRow(
          recording(
            id: 'rec-2',
            referenceStart: 5000,
            referenceDuration: 800,
            createdAt: DateTime.utc(2024, 6, 2),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(emissions.length, baseline);

        await sub.cancel();
      },
    );

    test('watchByEchoRegion does not emit for a different language', () async {
      await db.recordingDao.insertRow(
        recording(
          id: 'rec-1',
          referenceStart: 0,
          referenceDuration: 500,
          createdAt: DateTime.utc(2024, 6, 1),
        ),
      );

      final emissions = <List<RecordingRow>>[];
      final sub = db.recordingDao
          .watchByEchoRegion(
            targetType: 'Video',
            targetId: 'media-1',
            language: 'en',
            echoStartMs: 0,
            echoEndMs: 2000,
          )
          .listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final baseline = emissions.length;
      expect(emissions.last, hasLength(1));

      await db.recordingDao.insertRow(
        recording(
          id: 'rec-2',
          referenceStart: 0,
          referenceDuration: 500,
          language: 'zh',
          createdAt: DateTime.utc(2024, 6, 2),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, baseline);

      await sub.cancel();
    });
  });
}
