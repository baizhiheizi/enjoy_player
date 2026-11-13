import 'package:enjoy_player/data/db/transcript_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime(2026, 1, 1, 9);
  final written = DateTime(2026, 11, 13, 12);

  test('defaults the structural columns the nine upsert sites omit', () {
    final row = buildTranscriptRow(
      id: 'Video:media-1:en:official',
      targetType: 'Video',
      targetId: 'media-1',
      language: 'en',
      source: 'official',
      timelineJson: '[]',
      createdAt: created,
    );

    expect(row.referenceId, isNull);
    expect(row.trackIndex, isNull);
    expect(row.serverUpdatedAt, isNull);
    expect(row.label, '');
    expect(row.syncStatus, 'local');
    expect(row.createdAt, created);
    expect(row.updatedAt, created);
  });

  test('a rewrite that preserves createdAt still advances updatedAt', () {
    final row = buildTranscriptRow(
      id: 'Video:media-1:en:ai',
      targetType: 'Video',
      targetId: 'media-1',
      language: 'en',
      source: 'ai',
      timelineJson: '[]',
      createdAt: created,
      updatedAt: written,
    );

    expect(row.createdAt, created);
    expect(row.updatedAt, written);
  });

  test('explicit divergent values override every default', () {
    final row = buildTranscriptRow(
      id: 'Video:media-1:en:user',
      targetType: 'Video',
      targetId: 'media-1',
      language: 'en',
      source: 'user',
      timelineJson: '[]',
      referenceId: 'embedded:1',
      label: 'YouTube captions (en)',
      trackIndex: 1,
      syncStatus: 'synced',
      serverUpdatedAt: written,
      createdAt: created,
      updatedAt: written,
    );

    expect(row.referenceId, 'embedded:1');
    expect(row.label, 'YouTube captions (en)');
    expect(row.trackIndex, 1);
    expect(row.syncStatus, 'synced');
    expect(row.serverUpdatedAt, written);
    expect(row.createdAt, created);
    expect(row.updatedAt, written);
  });
}
