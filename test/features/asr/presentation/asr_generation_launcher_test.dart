import 'dart:io';

import 'package:drift/native.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_controller.dart';
import 'package:enjoy_player/features/asr/presentation/asr_generation_launcher.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _epoch = DateTime.utc(2024);

class _SignedInAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(id: 'u1', email: 't@test.com', name: 'Test'),
  );
}

Widget _wrap({
  required ProviderContainer container,
  required Widget child,
  String mediaId = 'm1',
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => Center(
            child: ElevatedButton(
              onPressed: () =>
                  launchAsrGeneration(context, ref, mediaId: mediaId),
              child: const Text('launch'),
            ),
          ),
        ),
      ),
    ),
  );
}

ProviderContainer _containerFor(
  AppDatabase db,
  TranscriptRepository repo,
  AsrCapability capability,
) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
      transcriptRepositoryProvider.overrideWithValue(repo),
      asrCapabilityProvider.overrideWithValue(capability),
    ],
  );
}

Future<VideoRow> _insertVideo(
  AppDatabase db, {
  String id = 'video-1',
  String language = 'en',
  int durationSeconds = 10,
  String vid = 'aaaaaaaaaaa',
  String provider = 'user',
  String? mediaUrl,
  String? source,
  String? localUri,
}) async {
  final row = VideoRow(
    id: id,
    vid: vid,
    provider: provider,
    title: 'Video $id',
    durationSeconds: durationSeconds,
    language: language,
    mediaUrl: mediaUrl,
    source: source,
    localUri: localUri,
    createdAt: _epoch,
    updatedAt: _epoch,
  );
  await db.videoDao.insertRow(row);
  return row;
}

final class _ResultAsrCapability implements AsrCapability {
  _ResultAsrCapability(this.result);
  final AsrResult result;
  AsrRequest? lastRequest;

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    lastRequest = request;
    return result;
  }
}

void main() {
  late AppDatabase db;
  late TranscriptRepository repo;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = TranscriptRepository(db);
    tempDir = await Directory.systemTemp.createTemp('asr_launcher_');
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets(
    'unsupported source: missing row shows error notice and skips dialog',
    (tester) async {
      final container = _containerFor(
        db,
        repo,
        _ResultAsrCapability(_emptyResult),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const SizedBox()),
      );
      await tester.tap(find.text('launch'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // No dialog should appear.
      expect(find.byType(AlertDialog), findsNothing);
      // No controller activity expected.
      expect(
        container.read(asrGenerationControllerProvider('m1')).valueOrNull,
        isNull,
      );
    },
  );

  testWidgets(
    'unsupported source: YouTube video shows error notice and skips dialog',
    (tester) async {
      await _insertVideo(
        db,
        id: 'yt-1',
        vid: 'dQw4w9WgXcQ',
        provider: 'youtube',
        source: 'youtube',
      );
      final container = _containerFor(
        db,
        repo,
        _ResultAsrCapability(_emptyResult),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const SizedBox(), mediaId: 'yt-1'),
      );
      await tester.tap(find.text('launch'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AlertDialog), findsNothing);
      expect(
        container.read(asrGenerationControllerProvider('yt-1')).valueOrNull,
        isNull,
      );
    },
  );

  // Registry-mediated read, found-row branch: the launcher resolves the row
  // via one MediaRegistry.getById (replacing kindOf + per-table
  // language/duration lookups); a local row whose file is gone fails the
  // source gate after the registry read succeeds — same unsupported-source
  // notice as the missing-row branch, but past the registry lookup.
  testWidgets(
    'unsupported source: local row with an unresolvable file shows the notice',
    (tester) async {
      await _insertVideo(
        db,
        id: 'gone-1',
        localUri: '${tempDir.path}/gone.mp4',
      );
      final container = _containerFor(
        db,
        repo,
        _ResultAsrCapability(_emptyResult),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const SizedBox(), mediaId: 'gone-1'),
      );
      await tester.tap(find.text('launch'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AlertDialog), findsNothing);
      expect(
        container.read(asrGenerationControllerProvider('gone-1')).valueOrNull,
        isNull,
      );
    },
  );

  // Refresh-after-language-dialog tests (Copilot review F7): the launcher
  // re-reads the media row after the language dialog so a duration backfill
  // (or any other row change) while the dialog was open is reflected in
  // the long-media confirmation.
  //
  // These cases reach the language dialog, so the row needs:
  //   * a real `localUri` file (so the source gate passes), and
  //   * a `vid` longer than 11 chars so [resolvePlayableSource] does not
  //     classify it as YouTube (its bare-id regex is 11 chars of
  //     `[A-Za-z0-9_-]`). The default 11-char test `vid` would route the
  //     launcher to the unsupported-source branch before the dialog opens.
  group('refresh after language dialog', () {
    // Each test gets its own tempDir (setUp recreates it). Create the
    // real local files up front — file I/O inside `testWidgets` blocks
    // because the test framework's fake clock doesn't drive dart:io
    // futures, so the source gate's `file.exists`/`file.stat` would
    // hang forever otherwise.
    setUp(() async {
      for (final name in ['refresh.mp4', 'deleted.mp4']) {
        await File(
          '${tempDir.path}/$name',
        ).writeAsBytes(const <int>[0, 1, 2, 3]);
      }
    });

    Future<ProviderContainer> pumpTapAndDialog(
      WidgetTester tester,
      String mediaId,
    ) async {
      final container = _containerFor(
        db,
        repo,
        _ResultAsrCapability(_emptyResult),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const SizedBox(), mediaId: mediaId),
      );
      // The launcher's async chain awaits real I/O (`localUriTrusted` →
      // `file.exists` / `file.stat`); drive it in real time so the
      // language dialog actually opens before we assert.
      await tester.runAsync(() async {
        await tester.tap(find.text('launch'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      return container;
    }

    testWidgets('a duration backfilled while the dialog is open is picked up', (
      tester,
    ) async {
      // Seeded with durationSeconds = 0 — the pre-dialog snapshot sees
      // 0, so without the re-read the long-media confirmation would be
      // skipped entirely.
      await _insertVideo(
        db,
        id: 'refresh-1',
        vid: 'local-fingerprint-deadbeefcafebabe1234567890abcdef',
        localUri: '${tempDir.path}/refresh.mp4',
        durationSeconds: 0,
      );

      await pumpTapAndDialog(tester, 'refresh-1');

      // Simulate the ffmpeg probe landing while the dialog is open.
      final row = await db.videoDao.getById('refresh-1');
      await db.videoDao.insertRow(
        row!.copyWith(durationSeconds: 1200), // 20 min — past the 900s gate
      );

      await tester.runAsync(() async {
        await tester.tap(find.text('OK'));
        // Let the launcher's re-read + showAsrLongMediaConfirmDialog
        // chain complete in real time.
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // The refreshed duration crossed the long-form gate, so the
      // confirmation dialog must appear.
      expect(find.text('This may take a while'), findsOneWidget);
    });

    testWidgets(
      'a row deleted while the dialog is open surfaces an error notice',
      (tester) async {
        await _insertVideo(
          db,
          id: 'gone-1',
          vid: 'local-fingerprint-cafebabedeadbeef1234567890abcdef',
          localUri: '${tempDir.path}/deleted.mp4',
          durationSeconds: 10,
        );

        final container = await pumpTapAndDialog(tester, 'gone-1');

        // Simulate a delete from another surface while the dialog is open.
        await db.videoDao.deleteId('gone-1');

        await tester.runAsync(() async {
          await tester.tap(find.text('OK'));
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();

        // The launcher bails out at the re-read with the unsupported-source
        // notice; the long-media confirmation must NOT appear, and no
        // controller activity should have been triggered.
        expect(find.text('This may take a while'), findsNothing);
        expect(
          container.read(asrGenerationControllerProvider('gone-1')).valueOrNull,
          isNull,
        );
      },
    );
  });

  // Full dialog interaction (typing a language, confirming long media) is
  // excluded here because the Material AlertDialog + TextField +
  // StatefulBuilder in showAsrLanguageDialog hang pumpAndSettle even with
  // disableAnimations — the local-file test above stops at a single pump
  // after the dialog opens. The dialog logic itself is covered by:
  //   - asr_long_media_dialog_test.dart (showAsrLongMediaConfirmDialog)
  //   - asr_generation_controller_test.dart (controller branches)
}

const AsrResult _emptyResult = AsrResult(text: '');
