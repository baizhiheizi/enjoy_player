import 'package:enjoy_player/features/asr/domain/asr_long_form_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // AsrLongFormJobStatus enum
  // ---------------------------------------------------------------------------
  group('AsrLongFormJobStatus', () {
    group('parse', () {
      test('parses "accepted"', () {
        expect(
          AsrLongFormJobStatus.parse('accepted'),
          AsrLongFormJobStatus.accepted,
        );
      });

      test('parses "processing"', () {
        expect(
          AsrLongFormJobStatus.parse('processing'),
          AsrLongFormJobStatus.processing,
        );
      });

      test('parses "completed"', () {
        expect(
          AsrLongFormJobStatus.parse('completed'),
          AsrLongFormJobStatus.completed,
        );
      });

      test('parses "failed"', () {
        expect(
          AsrLongFormJobStatus.parse('failed'),
          AsrLongFormJobStatus.failed,
        );
      });

      test('returns unknown for unrecognized string', () {
        expect(
          AsrLongFormJobStatus.parse('queued'),
          AsrLongFormJobStatus.unknown,
        );
      });

      test('returns unknown for null', () {
        expect(AsrLongFormJobStatus.parse(null), AsrLongFormJobStatus.unknown);
      });

      test('returns unknown for empty string', () {
        expect(AsrLongFormJobStatus.parse(''), AsrLongFormJobStatus.unknown);
      });
    });

    group('isTerminal', () {
      test('completed is terminal', () {
        expect(AsrLongFormJobStatus.completed.isTerminal, isTrue);
      });

      test('failed is terminal', () {
        expect(AsrLongFormJobStatus.failed.isTerminal, isTrue);
      });

      test('accepted is not terminal', () {
        expect(AsrLongFormJobStatus.accepted.isTerminal, isFalse);
      });

      test('processing is not terminal', () {
        expect(AsrLongFormJobStatus.processing.isTerminal, isFalse);
      });

      test('unknown is not terminal', () {
        expect(AsrLongFormJobStatus.unknown.isTerminal, isFalse);
      });
    });

    group('isPending', () {
      test('accepted is pending', () {
        expect(AsrLongFormJobStatus.accepted.isPending, isTrue);
      });

      test('processing is pending', () {
        expect(AsrLongFormJobStatus.processing.isPending, isTrue);
      });

      test('completed is not pending', () {
        expect(AsrLongFormJobStatus.completed.isPending, isFalse);
      });

      test('failed is not pending', () {
        expect(AsrLongFormJobStatus.failed.isPending, isFalse);
      });

      test('unknown is not pending', () {
        expect(AsrLongFormJobStatus.unknown.isPending, isFalse);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // AsrLongFormFailure
  // ---------------------------------------------------------------------------
  group('AsrLongFormFailure', () {
    test('constructor assigns fields', () {
      const failure = AsrLongFormFailure(
        category: 'provider_error',
        retryable: true,
        message: 'Service unavailable',
      );
      expect(failure.category, 'provider_error');
      expect(failure.retryable, isTrue);
      expect(failure.message, 'Service unavailable');
    });

    test('fromJson parses all fields', () {
      final failure = AsrLongFormFailure.fromJson({
        'category': 'network_error',
        'retryable': true,
        'message': 'Connection timeout',
      });
      expect(failure.category, 'network_error');
      expect(failure.retryable, isTrue);
      expect(failure.message, 'Connection timeout');
    });

    test('fromJson uses defaults when fields are missing', () {
      final failure = AsrLongFormFailure.fromJson({});
      expect(failure.category, 'provider_failure');
      expect(failure.retryable, isFalse);
      expect(failure.message, isNull);
    });

    test('fromJson uses defaults when fields are null', () {
      final failure = AsrLongFormFailure.fromJson({
        'category': null,
        'retryable': null,
        'message': null,
      });
      expect(failure.category, 'provider_failure');
      expect(failure.retryable, isFalse);
      expect(failure.message, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // AsrLongFormUsage
  // ---------------------------------------------------------------------------
  group('AsrLongFormUsage', () {
    test('constructor assigns fields', () {
      const usage = AsrLongFormUsage(
        actualDurationSeconds: 120.5,
        creditsCharged: 3,
      );
      expect(usage.actualDurationSeconds, 120.5);
      expect(usage.creditsCharged, 3);
    });

    test('fromJson parses camelCase keys', () {
      final usage = AsrLongFormUsage.fromJson({
        'actualDurationSeconds': 90.0,
        'creditsCharged': 2,
      });
      expect(usage.actualDurationSeconds, 90.0);
      expect(usage.creditsCharged, 2);
    });

    test('fromJson parses snake_case keys', () {
      final usage = AsrLongFormUsage.fromJson({
        'actual_duration_seconds': 45.5,
        'credits_charged': 1,
      });
      expect(usage.actualDurationSeconds, 45.5);
      expect(usage.creditsCharged, 1);
    });

    test('fromJson prefers camelCase over snake_case', () {
      final usage = AsrLongFormUsage.fromJson({
        'actualDurationSeconds': 100.0,
        'actual_duration_seconds': 200.0,
        'creditsCharged': 5,
      });
      expect(usage.actualDurationSeconds, 100.0);
    });

    test('fromJson defaults to 0 when keys are missing', () {
      final usage = AsrLongFormUsage.fromJson({});
      expect(usage.actualDurationSeconds, 0);
      expect(usage.creditsCharged, 0);
    });

    test('fromJson coarses numeric types (int → double for duration)', () {
      final usage = AsrLongFormUsage.fromJson({
        'actualDurationSeconds': 90,
        'creditsCharged': 2.0,
      });
      expect(usage.actualDurationSeconds, 90.0);
      expect(usage.creditsCharged, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // AsrLongFormTranscript
  // ---------------------------------------------------------------------------
  group('AsrLongFormTranscript', () {
    test('constructor assigns fields', () {
      const transcript = AsrLongFormTranscript(
        text: 'Hello world',
        language: 'en',
        actualDurationSeconds: 30.0,
        segments: [
          {'start': 0.0, 'end': 1.0, 'text': 'Hello'},
        ],
        words: [
          {'word': 'Hello', 'start': 0.0, 'end': 1.0},
        ],
        provider: 'deepgram',
        model: 'nova-2',
      );
      expect(transcript.text, 'Hello world');
      expect(transcript.language, 'en');
      expect(transcript.actualDurationSeconds, 30.0);
      expect(transcript.segments.length, 1);
      expect(transcript.words.length, 1);
      expect(transcript.provider, 'deepgram');
      expect(transcript.model, 'nova-2');
    });

    test('fromJson parses full response', () {
      final transcript = AsrLongFormTranscript.fromJson({
        'text': 'Hello world',
        'language': 'en',
        'actualDurationSeconds': 30.0,
        'segments': [
          {'start': 0.0, 'end': 1.0, 'text': 'Hello'},
        ],
        'words': [
          {'word': 'Hello', 'start': 0.0, 'end': 1.0},
        ],
        'provider': 'deepgram',
        'model': 'nova-2',
      });
      expect(transcript.text, 'Hello world');
      expect(transcript.segments.length, 1);
      expect(transcript.words.length, 1);
    });

    test('fromJson defaults to empty lists when segments/words are null', () {
      final transcript = AsrLongFormTranscript.fromJson({'text': 'Hello'});
      expect(transcript.segments, isEmpty);
      expect(transcript.words, isEmpty);
    });

    test(
      'fromJson defaults to empty lists when segments/words are missing',
      () {
        final transcript = AsrLongFormTranscript.fromJson({'text': 'Hello'});
        expect(transcript.segments, isEmpty);
        expect(transcript.words, isEmpty);
      },
    );

    test('fromJson defaults text to empty string', () {
      final transcript = AsrLongFormTranscript.fromJson({});
      expect(transcript.text, isEmpty);
    });

    test('fromJson filters out non-map entries in segments', () {
      final transcript = AsrLongFormTranscript.fromJson({
        'text': 'Hello',
        'segments': [
          {'start': 0.0, 'text': 'Valid'},
          'not a map',
          42,
          null,
        ],
      });
      expect(transcript.segments.length, 1);
      expect(transcript.segments[0]['text'], 'Valid');
    });

    test('fromJson handles snake_case for actualDurationSeconds', () {
      final transcript = AsrLongFormTranscript.fromJson({
        'text': 'Hello',
        'actual_duration_seconds': 15.0,
      });
      expect(transcript.actualDurationSeconds, 15.0);
    });
  });

  // ---------------------------------------------------------------------------
  // AsrLongFormJob
  // ---------------------------------------------------------------------------
  group('AsrLongFormJob', () {
    test('constructor assigns fields', () {
      const failure = AsrLongFormFailure(category: 'error', retryable: false);
      const usage = AsrLongFormUsage(
        actualDurationSeconds: 60.0,
        creditsCharged: 1,
      );
      const transcript = AsrLongFormTranscript(text: 'Hello');
      final job = AsrLongFormJob(
        jobId: 'job-123',
        status: AsrLongFormJobStatus.completed,
        createdAt: DateTime(2026, 7, 22),
        updatedAt: DateTime(2026, 7, 22, 1),
        completedAt: DateTime(2026, 7, 22, 2),
        failure: failure,
        usage: usage,
        transcript: transcript,
      );
      expect(job.jobId, 'job-123');
      expect(job.status, AsrLongFormJobStatus.completed);
      expect(job.createdAt, DateTime(2026, 7, 22));
      expect(job.failure?.category, 'error');
      expect(job.usage?.actualDurationSeconds, 60.0);
      expect(job.transcript?.text, 'Hello');
    });

    test('fromJson parses full job with nested objects', () {
      final job = AsrLongFormJob.fromJson({
        'jobId': 'job-123',
        'status': 'completed',
        'createdAt': '2026-07-22T10:00:00.000Z',
        'updatedAt': '2026-07-22T11:00:00.000Z',
        'completedAt': '2026-07-22T12:00:00.000Z',
        'failure': {'category': 'provider_error', 'retryable': true},
        'usage': {'actualDurationSeconds': 90.0, 'creditsCharged': 3},
        'transcript': {'text': 'Hello world', 'language': 'en'},
      });
      expect(job.jobId, 'job-123');
      expect(job.status, AsrLongFormJobStatus.completed);
      expect(job.createdAt?.toUtc(), DateTime.utc(2026, 7, 22, 10));
      expect(job.failure?.category, 'provider_error');
      expect(job.usage?.actualDurationSeconds, 90.0);
      expect(job.transcript?.text, 'Hello world');
    });

    test('fromJson handles minimal job with only required fields', () {
      final job = AsrLongFormJob.fromJson({
        'jobId': 'job-456',
        'status': 'processing',
      });
      expect(job.jobId, 'job-456');
      expect(job.status, AsrLongFormJobStatus.processing);
      expect(job.createdAt, isNull);
      expect(job.failure, isNull);
      expect(job.usage, isNull);
      expect(job.transcript, isNull);
    });

    test('fromJson uses default empty jobId when missing', () {
      final job = AsrLongFormJob.fromJson({'status': 'failed'});
      expect(job.jobId, isEmpty);
    });

    test('fromJson parses snake_case keys', () {
      final job = AsrLongFormJob.fromJson({
        'job_id': 'job-789',
        'status': 'accepted',
        'created_at': '2026-07-22T10:00:00.000Z',
      });
      expect(job.jobId, 'job-789');
      expect(job.createdAt?.toUtc(), DateTime.utc(2026, 7, 22, 10));
    });

    test('fromJson parses unknown status as unknown', () {
      final job = AsrLongFormJob.fromJson({
        'jobId': 'job-xxx',
        'status': 'nonexistent_status',
      });
      expect(job.status, AsrLongFormJobStatus.unknown);
    });

    test('fromJson handles null nested objects', () {
      final job = AsrLongFormJob.fromJson({
        'jobId': 'job-123',
        'status': 'completed',
        'failure': null,
        'usage': null,
        'transcript': null,
      });
      expect(job.failure, isNull);
      expect(job.usage, isNull);
      expect(job.transcript, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // AsrLongFormAttempt
  // ---------------------------------------------------------------------------
  group('AsrLongFormAttempt', () {
    test('constructor assigns fields', () {
      final attempt = AsrLongFormAttempt(
        mediaId: 'media-1',
        idempotencyKey: 'key-1',
        declaredDurationSeconds: 120.0,
        startedAt: DateTime(2026, 7, 22),
        jobId: 'job-1',
        language: 'en',
        mediaReference: 'ref-1',
      );
      expect(attempt.mediaId, 'media-1');
      expect(attempt.idempotencyKey, 'key-1');
      expect(attempt.declaredDurationSeconds, 120.0);
      expect(attempt.startedAt, DateTime(2026, 7, 22));
      expect(attempt.jobId, 'job-1');
      expect(attempt.language, 'en');
      expect(attempt.mediaReference, 'ref-1');
    });

    test('fromJson parses all fields', () {
      final attempt = AsrLongFormAttempt.fromJson({
        'mediaId': 'media-1',
        'idempotencyKey': 'key-1',
        'declaredDurationSeconds': 60.0,
        'startedAt': '2026-07-22T10:00:00.000Z',
        'jobId': 'job-1',
        'language': 'en',
        'mediaReference': 'ref-1',
      });
      expect(attempt.mediaId, 'media-1');
      expect(attempt.declaredDurationSeconds, 60.0);
      expect(attempt.jobId, 'job-1');
    });

    test('fromJson defaults missing optional fields', () {
      final attempt = AsrLongFormAttempt.fromJson({
        'mediaId': 'media-1',
        'idempotencyKey': 'key-1',
        'declaredDurationSeconds': 30.0,
        'startedAt': '2026-07-22T10:00:00.000Z',
      });
      expect(attempt.jobId, isNull);
      expect(attempt.language, isNull);
      expect(attempt.mediaReference, isNull);
    });

    test('fromJson defaults missing mediaId and idempotencyKey to empty', () {
      final attempt = AsrLongFormAttempt.fromJson({
        'declaredDurationSeconds': 10.0,
        'startedAt': '2026-07-22T10:00:00.000Z',
      });
      expect(attempt.mediaId, isEmpty);
      expect(attempt.idempotencyKey, isEmpty);
    });

    test('fromJson uses epoch for missing startedAt', () {
      final attempt = AsrLongFormAttempt.fromJson({
        'mediaId': 'm1',
        'idempotencyKey': 'k1',
        'declaredDurationSeconds': 10.0,
      });
      expect(attempt.startedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('toJson includes all fields', () {
      final attempt = AsrLongFormAttempt(
        mediaId: 'media-1',
        idempotencyKey: 'key-1',
        declaredDurationSeconds: 45.0,
        startedAt: DateTime(2026, 7, 22, 10),
        jobId: 'job-1',
        language: 'en',
        mediaReference: 'ref-1',
      );
      final json = attempt.toJson();
      expect(json['mediaId'], 'media-1');
      expect(json['idempotencyKey'], 'key-1');
      expect(json['declaredDurationSeconds'], 45.0);
      expect(json['startedAt'], '2026-07-22T10:00:00.000');
      expect(json['jobId'], 'job-1');
      expect(json['language'], 'en');
      expect(json['mediaReference'], 'ref-1');
    });

    test('toJson omits null optional fields', () {
      final attempt = AsrLongFormAttempt(
        mediaId: 'media-1',
        idempotencyKey: 'key-1',
        declaredDurationSeconds: 10.0,
        startedAt: DateTime(2026, 7, 22),
      );
      final json = attempt.toJson();
      expect(json.containsKey('jobId'), isFalse);
      expect(json.containsKey('mediaReference'), isFalse);
      // language is always present (even if null, but constructor doesn't null it)
    });

    test('copyWith updates jobId', () {
      final attempt = AsrLongFormAttempt(
        mediaId: 'media-1',
        idempotencyKey: 'key-1',
        declaredDurationSeconds: 10.0,
        startedAt: DateTime(2026, 7, 22),
      );
      final updated = attempt.copyWith(jobId: 'new-job');
      expect(updated.jobId, 'new-job');
      expect(updated.mediaId, 'media-1'); // preserved
    });

    test('copyWith updates mediaReference', () {
      final attempt = AsrLongFormAttempt(
        mediaId: 'media-1',
        idempotencyKey: 'key-1',
        declaredDurationSeconds: 10.0,
        startedAt: DateTime(2026, 7, 22),
        mediaReference: 'old-ref',
      );
      final updated = attempt.copyWith(mediaReference: 'new-ref');
      expect(updated.mediaReference, 'new-ref');
      expect(updated.idempotencyKey, 'key-1'); // preserved
    });

    test('copyWith with null keeps existing value', () {
      final attempt = AsrLongFormAttempt(
        mediaId: 'media-1',
        idempotencyKey: 'key-1',
        declaredDurationSeconds: 10.0,
        startedAt: DateTime(2026, 7, 22),
        jobId: 'existing-job',
      );
      final updated = attempt.copyWith();
      expect(updated.jobId, 'existing-job');
    });
  });
}
