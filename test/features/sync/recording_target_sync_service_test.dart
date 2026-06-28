import 'package:drift/native.dart';
import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/sync/data/recording_target_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeRecordingApi extends RecordingApi {
  _FakeRecordingApi(this.responses, super._);

  final List<List<Map<String, dynamic>>> responses;
  int callCount = 0;
  String? lastUpdatedAfter;

  @override
  Future<List<Map<String, dynamic>>> recordings({
    String? targetId,
    String? targetType,
    String? language,
    int? limit,
    String? updatedAfter,
  }) async {
    callCount += 1;
    lastUpdatedAfter = updatedAfter;
    if (responses.isEmpty) return const <Map<String, dynamic>>[];
    return responses.removeAt(0);
  }
}

/// Pass-through ApiClient that the [RecordingApi] super-constructor
/// will accept; the fake subclass overrides every method that the
/// service under test actually calls.
class _NullApiClient extends ApiClient {
  _NullApiClient()
    : super(
        httpClient: _NullHttpClient(),
        getBaseUrl: () async => 'https://test.invalid',
        getAccessToken: () async => null,
      );
}

class _NullHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnsupportedError(
      'RecordingTargetSyncService tests must override '
      'every method they exercise; the base class should never be called.',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecordingTargetSyncService.pullRecordingsForTarget', () {
    late AppDatabase db;
    late _FakeRecordingApi api;
    late RecordingTargetSyncService service;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
    });

    Map<String, dynamic> recording(int i, {String? updatedAt}) => {
      'id': 'r$i',
      'targetId': 't1',
      'targetType': 'audio',
      'durationSeconds': i,
      'updatedAt':
          updatedAt ?? DateTime.utc(2024, 1, 1, 0, i).toIso8601String(),
    };

    test('respects the page cap and persists the cooldown timestamp', () async {
      // Six full pages so the cap (5) is hit.
      api = _FakeRecordingApi(
        List.generate(
          6,
          (page) => List.generate(
            50,
            (i) => recording(
              page * 50 + i,
              updatedAt: DateTime.utc(
                2024,
                1,
                1,
                0,
                page * 50 + i,
              ).toIso8601String(),
            ),
          ),
        ),
        _NullApiClient(),
      );
      service = RecordingTargetSyncService(db: db, recordingApi: api);
      final t0 = DateTime.utc(2024, 6, 1, 12);

      final result = await service.pullRecordingsForTarget(
        targetType: 'audio',
        targetId: 't1',
        now: t0,
      );

      // 5 pages * 50 = 250 rows synced, then the cap stops the loop.
      expect(result.success, isTrue);
      expect(result.synced, 250);
      expect(api.callCount, 5);

      final cooldown = await db.settingsDao.getValue(
        SettingsKeys.syncLastPullAtRecordingTarget('audio', 't1'),
      );
      expect(cooldown, t0.toUtc().toIso8601String());
    });

    test(
      'returns empty success when called inside the cooldown window',
      () async {
        api = _FakeRecordingApi([
          List.generate(10, (i) => recording(i)),
        ], _NullApiClient());
        service = RecordingTargetSyncService(db: db, recordingApi: api);
        final t0 = DateTime.utc(2024, 6, 1, 12);

        // First call hits the API.
        final r1 = await service.pullRecordingsForTarget(
          targetType: 'audio',
          targetId: 't1',
          now: t0,
        );
        expect(r1.synced, 10);
        expect(api.callCount, 1);

        // Second call 1 minute later is short-circuited.
        final r2 = await service.pullRecordingsForTarget(
          targetType: 'audio',
          targetId: 't1',
          now: t0.add(const Duration(minutes: 1)),
        );
        expect(r2.synced, 0);
        expect(r2.failed, 0);
        expect(r2.success, isTrue);
        expect(
          api.callCount,
          1,
          reason: 'cooldown should prevent a second call',
        );
      },
    );

    test('hits the API again after the cooldown elapses', () async {
      api = _FakeRecordingApi([
        List.generate(10, (i) => recording(i)),
        List.generate(5, (i) => recording(100 + i)),
      ], _NullApiClient());
      service = RecordingTargetSyncService(db: db, recordingApi: api);
      final t0 = DateTime.utc(2024, 6, 1, 12);

      final r1 = await service.pullRecordingsForTarget(
        targetType: 'audio',
        targetId: 't1',
        now: t0,
      );
      expect(r1.synced, 10);

      // 6 minutes later: cooldown is over, cursor persisted, the next
      // call should resume from the cursor and pick up new rows.
      final r2 = await service.pullRecordingsForTarget(
        targetType: 'audio',
        targetId: 't1',
        now: t0.add(const Duration(minutes: 6)),
      );
      expect(r2.synced, 5);
      expect(api.callCount, 2);
      expect(api.lastUpdatedAfter, isNotNull);
      expect(api.lastUpdatedAfter, isNot(isEmpty));
    });

    test('cooldowns are per-target and do not leak across pairs', () async {
      api = _FakeRecordingApi([
        List.generate(3, (i) => recording(i)),
        List.generate(2, (i) => recording(100 + i)),
      ], _NullApiClient());
      service = RecordingTargetSyncService(db: db, recordingApi: api);
      final t0 = DateTime.utc(2024, 6, 1, 12);

      final r1 = await service.pullRecordingsForTarget(
        targetType: 'audio',
        targetId: 't1',
        now: t0,
      );
      expect(r1.synced, 3);

      // Different targetId — separate cooldown bucket.
      final r2 = await service.pullRecordingsForTarget(
        targetType: 'audio',
        targetId: 't2',
        now: t0.add(const Duration(seconds: 30)),
      );
      expect(r2.synced, 2);
      expect(api.callCount, 2);
    });
  });
}
