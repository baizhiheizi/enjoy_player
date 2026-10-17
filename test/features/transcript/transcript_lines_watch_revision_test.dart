import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _mediaId = 'media-watch';
const _transcriptId = 'tr-watch';

String _timeline(String text) => jsonEncode([
  TranscriptLine(text: text, startMs: 0, durationMs: 500).toJson(),
]);

AudioRow _audio() {
  final now = DateTime.utc(2026, 10, 17);
  return AudioRow(
    id: _mediaId,
    aid: 'f',
    provider: 'user',
    title: 't',
    description: null,
    thumbnailUrl: null,
    durationSeconds: 0,
    language: 'und',
    translationKey: null,
    sourceText: null,
    voice: null,
    source: null,
    localUri: 'file:///a.mp3',
    md5: null,
    size: 1,
    mediaUrl: null,
    syncStatus: null,
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

TranscriptRow _transcript({required String text, required DateTime updatedAt}) {
  return TranscriptRow(
    id: _transcriptId,
    targetType: 'Audio',
    targetId: _mediaId,
    language: 'en',
    source: 'user',
    timelineJson: _timeline(text),
    referenceId: null,
    label: 'en',
    trackIndex: null,
    syncStatus: null,
    serverUpdatedAt: null,
    createdAt: DateTime.utc(2026, 10, 17),
    updatedAt: updatedAt,
  );
}

EchoSessionRow _session() {
  final now = DateTime.utc(2026, 10, 17);
  return EchoSessionRow(
    id: 'echo-watch',
    targetType: 'Audio',
    targetId: _mediaId,
    language: 'und',
    currentTimeMs: 0,
    playbackRate: 1,
    volume: 1,
    echoStartMs: null,
    echoEndMs: null,
    transcriptId: _transcriptId,
    secondaryTranscriptId: null,
    recordingsCount: 0,
    recordingsDurationMs: 0,
    lastRecordingAt: null,
    currentSegmentIndex: -1,
    echoActive: false,
    echoStartLine: -1,
    echoEndLine: -1,
    blurActive: false,
    startedAt: now,
    lastActiveAt: now,
    completedAt: null,
    syncStatus: null,
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

class _CountingRepository extends TranscriptRepository {
  _CountingRepository(super.db);

  int rowReads = 0;

  @override
  Future<TranscriptRow?> transcriptRowById(String transcriptId) {
    rowReads++;
    return super.transcriptRowById(transcriptId);
  }
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 80));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _CountingRepository repo;
  late List<List<TranscriptLine>> emissions;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    await db.audioDao.insertRow(_audio());
    await db.transcriptDao.upsert(
      _transcript(text: 'hello', updatedAt: DateTime.utc(2026, 10, 17, 10)),
    );
    await db.echoSessionDao.upsert(_session());
    repo = _CountingRepository(db);
    emissions = <List<TranscriptLine>>[];
  });

  test('playback clock writes do not re-read the transcript row', () async {
    final sub = repo.watchPrimaryLines(_mediaId).listen(emissions.add);
    addTearDown(sub.cancel);
    await _settle();

    expect(emissions, hasLength(1));
    expect(emissions.single.single.text, 'hello');
    expect(repo.rowReads, 1);

    for (var tick = 1; tick <= 5; tick++) {
      await (db.update(
        db.echoSessions,
      )..where((s) => s.id.equals('echo-watch'))).write(
        EchoSessionsCompanion(
          currentTimeMs: Value(tick * 400),
          lastActiveAt: Value(DateTime.utc(2026, 10, 17, 10, 0, tick)),
          updatedAt: Value(DateTime.utc(2026, 10, 17, 10, 0, tick)),
        ),
      );
    }
    await _settle();

    expect(emissions, hasLength(1), reason: 'clock writes must not emit lines');
    expect(repo.rowReads, 1, reason: 'clock writes must not read the row');
  });

  test('a transcript edit reads the row once and emits new lines', () async {
    final sub = repo.watchPrimaryLines(_mediaId).listen(emissions.add);
    addTearDown(sub.cancel);
    await _settle();
    expect(repo.rowReads, 1);

    await db.transcriptDao.upsert(
      _transcript(text: 'world', updatedAt: DateTime.utc(2026, 10, 17, 11)),
    );
    await _settle();

    expect(repo.rowReads, 2);
    expect(emissions, hasLength(2));
    expect(emissions.last.single.text, 'world');
  });

  test('an unrelated transcript write neither reads nor emits', () async {
    final sub = repo.watchPrimaryLines(_mediaId).listen(emissions.add);
    addTearDown(sub.cancel);
    await _settle();
    expect(repo.rowReads, 1);

    await db.transcriptDao.upsert(
      TranscriptRow(
        id: 'tr-other',
        targetType: 'Audio',
        targetId: _mediaId,
        language: 'en',
        source: 'user',
        timelineJson: _timeline('other'),
        referenceId: null,
        label: 'en',
        trackIndex: null,
        syncStatus: null,
        serverUpdatedAt: null,
        createdAt: DateTime.utc(2026, 10, 17),
        updatedAt: DateTime.utc(2026, 10, 17, 11),
      ),
    );
    await _settle();

    expect(repo.rowReads, 1);
    expect(emissions, hasLength(1));
  });

  test('switching the active transcript id emits the new lines', () async {
    await db.transcriptDao.upsert(
      TranscriptRow(
        id: 'tr-second',
        targetType: 'Audio',
        targetId: _mediaId,
        language: 'ja',
        source: 'user',
        timelineJson: _timeline('konnichiwa'),
        referenceId: null,
        label: 'ja',
        trackIndex: null,
        syncStatus: null,
        serverUpdatedAt: null,
        createdAt: DateTime.utc(2026, 10, 17),
        updatedAt: DateTime.utc(2026, 10, 17, 10),
      ),
    );
    final sub = repo.watchPrimaryLines(_mediaId).listen(emissions.add);
    addTearDown(sub.cancel);
    await _settle();
    expect(emissions, hasLength(1));

    await (db.update(db.echoSessions)..where((s) => s.id.equals('echo-watch')))
        .write(const EchoSessionsCompanion(transcriptId: Value('tr-second')));
    await _settle();

    expect(emissions, hasLength(2));
    expect(emissions.last.single.text, 'konnichiwa');
    expect(repo.rowReads, 2);
  });

  test('contentById serves cached lines without rereading the row', () async {
    final first = await repo.contentById(_transcriptId);
    expect(first, isNotNull);
    expect(first!.language, 'en');
    expect(first.lines.single.text, 'hello');
    expect(repo.rowReads, 1);

    final second = await repo.contentById(_transcriptId);
    expect(second!.lines.single.text, 'hello');
    expect(repo.rowReads, 1);

    await db.transcriptDao.upsert(
      _transcript(text: 'again', updatedAt: DateTime.utc(2026, 10, 17, 11)),
    );
    final third = await repo.contentById(_transcriptId);
    expect(third!.lines.single.text, 'again');
    expect(repo.rowReads, 2);
  });
}
