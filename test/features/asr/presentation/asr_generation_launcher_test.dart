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

      expect(find.byType(AlertDialog), findsNothing);
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

  group('refresh after language dialog', () {
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
      await _insertVideo(
        db,
        id: 'refresh-1',
        vid: 'local-fingerprint-deadbeefcafebabe1234567890abcdef',
        localUri: '${tempDir.path}/refresh.mp4',
        durationSeconds: 0,
      );

      await pumpTapAndDialog(tester, 'refresh-1');

      final row = await db.videoDao.getById('refresh-1');
      await db.videoDao.insertRow(row!.copyWith(durationSeconds: 1200));

      await tester.runAsync(() async {
        await tester.tap(find.text('OK'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

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

        await db.videoDao.deleteId('gone-1');

        await tester.runAsync(() async {
          await tester.tap(find.text('OK'));
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();

        expect(find.text('This may take a while'), findsNothing);
        expect(
          container.read(asrGenerationControllerProvider('gone-1')).valueOrNull,
          isNull,
        );
      },
    );
  });
}

const AsrResult _emptyResult = AsrResult(text: '');
