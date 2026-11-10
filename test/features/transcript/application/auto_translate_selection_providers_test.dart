// ignore_for_file: scoped_providers_should_specify_dependencies
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_selection_providers.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';

class _SignedInAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(id: 'u1', email: 't@example.com', name: 'Test'),
  );
}

class _SignedOutAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

class _ZhNativePrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async => AppPreferencesState.initial
      .copyWith(nativeLanguage: 'zh-CN', learningLanguage: 'en-US');
}

void main() {
  group('isAutoTranslateSecondary provider', () {
    late AppDatabase db;
    late TranscriptRepository repo;
    late ProviderContainer container;
    const mediaId = 'media-is-ai';

    setUp(() async {
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = TranscriptRepository(db);

      final now = DateTime.now();
      await db.videoDao.insertRow(
        VideoRow(
          id: mediaId,
          vid: 'vid12345678',
          provider: 'user',
          title: 'Test',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 60,
          language: 'en',
          source: 'local',
          localUri: '/tmp/test.mp4',
          md5: null,
          size: null,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      const lines = [
        TranscriptLine(text: 'Hello', startMs: 0, durationMs: 1000),
      ];
      await db.transcriptDao.upsert(
        TranscriptRow(
          id: 'user-track',
          targetType: 'Video',
          targetId: mediaId,
          language: 'en',
          source: 'user',
          timelineJson: jsonEncode(lines.map((e) => e.toJson()).toList()),
          referenceId: null,
          label: 'English',
          trackIndex: null,
          syncStatus: 'local',
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db.transcriptDao.upsert(
        TranscriptRow(
          id: 'ai-track',
          targetType: 'Video',
          targetId: mediaId,
          language: 'zh-CN',
          source: 'ai',
          timelineJson: jsonEncode(lines.map((e) => e.toJson()).toList()),
          referenceId: 'user-track',
          label: 'Auto translate',
          trackIndex: null,
          syncStatus: 'local',
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          transcriptRepositoryProvider.overrideWithValue(repo),
          authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
          appPreferencesCtrlProvider.overrideWith(_ZhNativePrefsCtrl.new),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('returns false for null secondaryId', () async {
      final result = await container.read(
        isAutoTranslateSecondaryProvider(mediaId, null).future,
      );
      expect(result, isFalse);
    });

    test('returns false for non-AI track', () async {
      final result = await container.read(
        isAutoTranslateSecondaryProvider(mediaId, 'user-track').future,
      );
      expect(result, isFalse);
    });

    test('returns true for AI track', () async {
      final result = await container.read(
        isAutoTranslateSecondaryProvider(mediaId, 'ai-track').future,
      );
      expect(result, isTrue);
    });

    test('returns false for nonexistent track', () async {
      final result = await container.read(
        isAutoTranslateSecondaryProvider(mediaId, 'nonexistent').future,
      );
      expect(result, isFalse);
    });
  });

  group('autoTranslateSelectionId provider', () {
    late AppDatabase db;
    late TranscriptRepository repo;
    late ProviderContainer container;
    const mediaId = 'media-sel-id';

    setUp(() async {
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = TranscriptRepository(db);

      final now = DateTime.now();
      await db.videoDao.insertRow(
        VideoRow(
          id: mediaId,
          vid: 'vid12345678',
          provider: 'user',
          title: 'Test',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 60,
          language: 'en',
          source: 'local',
          localUri: '/tmp/test.mp4',
          md5: null,
          size: null,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('returns null when not signed in', () async {
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          transcriptRepositoryProvider.overrideWithValue(repo),
          authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new),
          appPreferencesCtrlProvider.overrideWith(_ZhNativePrefsCtrl.new),
        ],
      );
      await container.read(authCtrlProvider.future);

      final result = await container.read(
        autoTranslateSelectionIdProvider(mediaId).future,
      );
      expect(result, isNull);
    });

    test(
      'returns predicted AI track id when signed in with native language',
      () async {
        container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            transcriptRepositoryProvider.overrideWithValue(repo),
            authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
            appPreferencesCtrlProvider.overrideWith(_ZhNativePrefsCtrl.new),
          ],
        );
        await container.read(authCtrlProvider.future);
        await container.read(appPreferencesCtrlProvider.future);

        final result = await container.read(
          autoTranslateSelectionIdProvider(mediaId).future,
        );
        expect(result, isNotNull);
        expect(
          result,
          autoTranslateAiTrackId(
            targetType: 'Video',
            mediaId: mediaId,
            targetLanguage: 'zh-CN',
          ),
        );
      },
    );

    test('returns null for unknown media id', () async {
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          transcriptRepositoryProvider.overrideWithValue(repo),
          authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
          appPreferencesCtrlProvider.overrideWith(_ZhNativePrefsCtrl.new),
        ],
      );
      await container.read(authCtrlProvider.future);
      await container.read(appPreferencesCtrlProvider.future);
      final result = await container.read(
        autoTranslateSelectionIdProvider('nonexistent-media').future,
      );
      expect(result, isNull);
    });
  });
}
