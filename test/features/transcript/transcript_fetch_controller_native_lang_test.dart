import 'package:drift/native.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Prefs notifier that always reports learning `en-US` / native `zh-CN`.
class _NativePrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async => const AppPreferencesState(
    locale: kAppDefaultDisplayLocale,
    learningLanguage: 'en-US',
    nativeLanguage: 'zh-CN',
  );
}

/// Records every `resolveOnOpen` invocation so the controller test can assert
/// the native language is forwarded on both open and refresh.
class _RecordingRepo extends TranscriptRepository {
  _RecordingRepo(super.db);

  final List<
    ({
      bool forceCloud,
      bool fetchCloud,
      String? nativeLanguage,
      String? learningLanguage,
    })
  >
  calls = [];

  @override
  Future<TranscriptResolveResult> resolveOnOpen(
    String mediaId, {
    bool forceCloud = false,
    bool fetchCloud = true,
    String? nativeLanguage,
    String? learningLanguage,
  }) async {
    calls.add((
      forceCloud: forceCloud,
      fetchCloud: fetchCloud,
      nativeLanguage: nativeLanguage,
      learningLanguage: learningLanguage,
    ));
    return const TranscriptResolveResult(hasTracks: false);
  }
}

void main() {
  group('TranscriptFetchCtrl native language', () {
    late AppDatabase db;
    late ProviderContainer container;
    late _RecordingRepo repo;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = _RecordingRepo(db);
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          transcriptRepositoryProvider.overrideWithValue(repo),
          appPreferencesCtrlProvider.overrideWith(_NativePrefsCtrl.new),
        ],
      );
    });

    tearDown(() async {
      // Drain the keepAlive controller's unawaited `_hydrateFromPersisted`
      // (it reads against this in-memory db) before closing it — otherwise its
      // async continuation hits a closed db and leaks a "can't re-open" error
      // into the next test.
      for (var i = 0; i < 8; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      container.dispose();
      await db.close();
    });

    test(
      'T009: resolveOnOpen forwards native language when signed in',
      () async {
        // Prime the (async) prefs so valueOrNull is populated before the call.
        await container.read(appPreferencesCtrlProvider.future);

        const mediaId = 'media-native-open';
        final ctrl = container.read(
          transcriptFetchCtrlProvider(mediaId).notifier,
        );
        await ctrl.resolveOnOpen(signedIn: true);

        expect(repo.calls, hasLength(1));
        expect(repo.calls.single.fetchCloud, isTrue);
        expect(repo.calls.single.forceCloud, isFalse);
        expect(repo.calls.single.nativeLanguage, 'zh-CN');
        expect(repo.calls.single.learningLanguage, 'en-US');
      },
    );

    test('T009: unsigned open forwards no native language', () async {
      await container.read(appPreferencesCtrlProvider.future);

      const mediaId = 'media-native-unsigned';
      final ctrl = container.read(
        transcriptFetchCtrlProvider(mediaId).notifier,
      );
      await ctrl.resolveOnOpen(signedIn: false);

      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.fetchCloud, isFalse);
      expect(repo.calls.single.nativeLanguage, isNull);
    });

    test('T014: refreshFromCloud forwards native language (FR-010)', () async {
      await container.read(appPreferencesCtrlProvider.future);

      const mediaId = 'media-native-refresh';
      final ctrl = container.read(
        transcriptFetchCtrlProvider(mediaId).notifier,
      );
      await ctrl.refreshFromCloud(signedIn: true);

      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.fetchCloud, isTrue);
      expect(repo.calls.single.forceCloud, isTrue);
      // The refresh path must see the same native language as open — this is
      // the FR-010 gap that reading inside _runResolve closes.
      expect(repo.calls.single.nativeLanguage, 'zh-CN');
      expect(repo.calls.single.learningLanguage, 'en-US');
    });
  });
}
