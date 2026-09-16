/// Tests for [sync_queue_job.dart] — the typed enqueue seam (issue #718).
///
/// Pins both halves of the seam contract:
///   * `decode` owns row interpretation: every persisted `(entityType,
///     action)` pair maps to exactly one variant (or null when the row is
///     undecodable — dropped by the drain).
///   * `encode` reproduces the pre-seam wire columns byte-for-byte, so rows
///     written before/after the seam are indistinguishable.
library;

import 'dart:convert';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/domain/sync_queue_job.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';
import 'package:flutter_test/flutter_test.dart';

SyncQueueRow _row({
  required String entityType,
  required String entityId,
  required String action,
  String? payloadJson,
}) => SyncQueueRow(
  id: 1,
  entityType: entityType,
  entityId: entityId,
  action: action,
  payloadJson: payloadJson,
  retryCount: 0,
  lastAttempt: null,
  error: null,
  createdAt: DateTime.utc(2026, 9, 16),
);

void main() {
  group('SyncQueueJob.decode', () {
    test('maps every delete wire pair to its Delete variant', () {
      expect(
        SyncQueueJob.decode(
          _row(entityType: 'audio', entityId: 'a1', action: 'delete'),
        ),
        isA<SyncAudioDelete>().having((j) => j.id, 'id', 'a1'),
      );
      expect(
        SyncQueueJob.decode(
          _row(entityType: 'video', entityId: 'v1', action: 'delete'),
        ),
        isA<SyncVideoDelete>().having((j) => j.id, 'id', 'v1'),
      );
      expect(
        SyncQueueJob.decode(
          _row(entityType: 'recording', entityId: 'r1', action: 'delete'),
        ),
        isA<SyncRecordingDelete>().having((j) => j.id, 'id', 'r1'),
      );
      expect(
        SyncQueueJob.decode(
          _row(
            entityType: 'youtube_subscription',
            entityId: 'ch-1',
            action: 'delete',
          ),
        ),
        isA<SyncYoutubeSubscriptionDelete>().having(
          (j) => j.channelId,
          'channelId',
          'ch-1',
        ),
      );
      expect(
        SyncQueueJob.decode(
          _row(
            entityType: 'vocabulary_item',
            entityId: 'vi1',
            action: 'delete',
          ),
        ),
        isA<SyncVocabularyItemDelete>().having((j) => j.id, 'id', 'vi1'),
      );
      expect(
        SyncQueueJob.decode(
          _row(
            entityType: 'vocabulary_context',
            entityId: 'vc1',
            action: 'delete',
          ),
        ),
        isA<SyncVocabularyContextDelete>().having((j) => j.id, 'id', 'vc1'),
      );
    });

    test('maps every upsert wire pair to its Upsert variant', () {
      for (final action in [SyncAction.create, SyncAction.update]) {
        expect(
          SyncQueueJob.decode(
            _row(entityType: 'audio', entityId: 'a1', action: action.wireName),
          ),
          isA<SyncAudioUpsert>()
              .having((j) => j.id, 'id', 'a1')
              .having((j) => j.action, 'action', action),
        );
        expect(
          SyncQueueJob.decode(
            _row(entityType: 'video', entityId: 'v1', action: action.wireName),
          ),
          isA<SyncVideoUpsert>()
              .having((j) => j.id, 'id', 'v1')
              .having((j) => j.action, 'action', action),
        );
        expect(
          SyncQueueJob.decode(
            _row(
              entityType: 'recording',
              entityId: 'r1',
              action: action.wireName,
            ),
          ),
          isA<SyncRecordingUpsert>()
              .having((j) => j.id, 'id', 'r1')
              .having((j) => j.action, 'action', action),
        );
        expect(
          SyncQueueJob.decode(
            _row(
              entityType: 'youtube_subscription',
              entityId: 'ch-1',
              action: action.wireName,
            ),
          ),
          isA<SyncYoutubeSubscriptionUpsert>()
              .having((j) => j.channelId, 'channelId', 'ch-1')
              .having((j) => j.action, 'action', action),
        );
        expect(
          SyncQueueJob.decode(
            _row(
              entityType: 'vocabulary_item',
              entityId: 'vi1',
              action: action.wireName,
            ),
          ),
          isA<SyncVocabularyItemUpsert>()
              .having((j) => j.id, 'id', 'vi1')
              .having((j) => j.action, 'action', action),
        );
        expect(
          SyncQueueJob.decode(
            _row(
              entityType: 'vocabulary_context',
              entityId: 'vc1',
              action: action.wireName,
            ),
          ),
          isA<SyncVocabularyContextUpsert>()
              .having((j) => j.id, 'id', 'vc1')
              .having((j) => j.action, 'action', action),
        );
      }
    });

    test('unknown entityType or action is undecodable (null)', () {
      expect(
        SyncQueueJob.decode(
          _row(entityType: 'bogus', entityId: 'x', action: 'create'),
        ),
        isNull,
      );
      expect(
        SyncQueueJob.decode(
          _row(entityType: 'audio', entityId: 'x', action: 'bogus'),
        ),
        isNull,
      );
    });

    test('decodes a youtube_upload retry payload inside the video variant', () {
      final job = SyncQueueJob.decode(
        _row(
          entityType: 'video',
          entityId: 'dQw4w9WgXcQ/en',
          action: 'update',
          payloadJson: jsonEncode({
            'kind': 'youtube_upload',
            'videoId': 'dQw4w9WgXcQ',
            'language': 'en',
            'source': 'official',
            'timeline': [
              {'text': 'hello', 'start': 0, 'duration': 1000},
            ],
          }),
        ),
      );
      expect(job, isA<SyncYoutubeUploadRetry>());
      final retry = job! as SyncYoutubeUploadRetry;
      expect(retry.videoId, 'dQw4w9WgXcQ');
      expect(retry.language, 'en');
      expect(retry.source, 'official');
      expect(retry.timeline, [
        {'text': 'hello', 'start': 0, 'duration': 1000},
      ]);
    });

    test('malformed youtube_upload payloads are undecodable (null)', () {
      // kind matches but required fields are missing.
      expect(
        SyncQueueJob.decode(
          _row(
            entityType: 'video',
            entityId: 'broken/en',
            action: 'update',
            payloadJson: jsonEncode({'kind': 'youtube_upload'}),
          ),
        ),
        isNull,
      );
      // Empty timeline.
      expect(
        SyncQueueJob.decode(
          _row(
            entityType: 'video',
            entityId: 'broken/en',
            action: 'update',
            payloadJson: jsonEncode({
              'kind': 'youtube_upload',
              'videoId': 'v',
              'language': 'en',
              'source': 'official',
              'timeline': <Object>[],
            }),
          ),
        ),
        isNull,
      );
      // Not JSON at all — the payload kind is unreadable, so the row keeps
      // flowing through the plain video path (pre-seam behavior:
      // isYoutubeUploadPayload returned false on a decode error).
      expect(
        SyncQueueJob.decode(
          _row(
            entityType: 'video',
            entityId: 'broken/en',
            action: 'update',
            payloadJson: 'not json',
          ),
        ),
        isA<SyncVideoUpsert>(),
      );
    });

    test(
      'delete wins over a youtube_upload payload (payload only rides upserts)',
      () {
        // The drain must run the cloud DELETE, not re-upload the payload —
        // matching the pre-seam ordering (delete branch never inspected it).
        final job = SyncQueueJob.decode(
          _row(
            entityType: 'video',
            entityId: 'v-gone',
            action: 'delete',
            payloadJson: jsonEncode({
              'kind': 'youtube_upload',
              'videoId': 'v',
              'language': 'en',
              'source': 'official',
              'timeline': [
                {'text': 'hello', 'start': 0, 'duration': 1000},
              ],
            }),
          ),
        );
        expect(job, isA<SyncVideoDelete>());
      },
    );
  });

  group('SyncQueueJob.encode', () {
    test('upsert variants reproduce the pre-seam wire columns', () {
      expect(
        const SyncAudioUpsert(
          id: 'a1',
          action: SyncAction.create,
          payloadJson: '{"id":"a1"}',
        ).encode(),
        const SyncQueueJobWire(
          entityType: 'audio',
          entityId: 'a1',
          action: 'create',
          payloadJson: '{"id":"a1"}',
        ),
      );
      expect(
        const SyncVocabularyContextUpsert(
          id: 'vc1',
          action: SyncAction.update,
        ).encode(),
        const SyncQueueJobWire(
          entityType: 'vocabulary_context',
          entityId: 'vc1',
          action: 'update',
        ),
      );
    });

    test('delete variants emit a null payload', () {
      for (final wire in [
        const SyncAudioDelete(id: 'a1'),
        const SyncVideoDelete(id: 'v1'),
        const SyncRecordingDelete(id: 'r1'),
        const SyncYoutubeSubscriptionDelete(channelId: 'ch1'),
        const SyncVocabularyItemDelete(id: 'vi1'),
        const SyncVocabularyContextDelete(id: 'vc1'),
      ]) {
        final encoded = wire.encode();
        expect(encoded.action, 'delete', reason: wire.runtimeType.toString());
        expect(
          encoded.payloadJson,
          isNull,
          reason: wire.runtimeType.toString(),
        );
      }
    });

    test('upsert constructors reject delete actions (loud, not silent)', () {
      expect(
        () => SyncAudioUpsert(id: 'a1', action: SyncAction.delete),
        throwsA(isA<AssertionError>()),
      );
    });

    test(
      'SyncYoutubeUploadRetry reproduces the #726 producer payload byte-for-byte',
      () {
        const timeline = [
          {'text': 'hello', 'start': 0, 'duration': 1000},
          {'text': 'world', 'start': 1000, 'duration': 1500},
        ];
        final encoded = const SyncYoutubeUploadRetry(
          videoId: 'dQw4w9WgXcQ',
          language: 'en',
          source: 'official',
          timeline: timeline,
        ).encode();
        expect(encoded.entityType, 'video');
        expect(encoded.entityId, 'dQw4w9WgXcQ/en');
        expect(encoded.action, 'update');
        // Exact byte identity with the pre-seam hand-rolled map literal —
        // the producer test (transcript_repository_youtube_fallback_test)
        // asserts this row's decoded fields.
        expect(
          encoded.payloadJson,
          jsonEncode({
            'kind': 'youtube_upload',
            'videoId': 'dQw4w9WgXcQ',
            'language': 'en',
            'source': 'official',
            'timeline': timeline,
          }),
        );
      },
    );

    test('encode/decode round-trips the youtube_upload retry row', () {
      const retry = SyncYoutubeUploadRetry(
        videoId: 'dQw4w9WgXcQ',
        language: 'en',
        source: 'official',
        timeline: [
          {'text': 'hello', 'start': 0, 'duration': 1000},
        ],
      );
      final wire = retry.encode();
      final decoded = SyncQueueJob.decode(
        _row(
          entityType: wire.entityType,
          entityId: wire.entityId,
          action: wire.action,
          payloadJson: wire.payloadJson,
        ),
      );
      expect(decoded, isA<SyncYoutubeUploadRetry>());
      final roundTripped = decoded! as SyncYoutubeUploadRetry;
      expect(roundTripped.videoId, retry.videoId);
      expect(roundTripped.language, retry.language);
      expect(roundTripped.source, retry.source);
      expect(roundTripped.timeline, retry.timeline);
    });
  });
}
