// ignore_for_file: scoped_providers_should_specify_dependencies
import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/data/db/media_registry_provider.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/library/presentation/edit_media_details.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

final _media = Media(
  id: 'media-1',
  kind: MediaKind.video,
  title: 'Sample',
  sourceUri: 'file:///sample.mp4',
  durationMs: 1000,
  language: 'en-US',
  contentHash: 'hash-1',
  fileSize: 1024,
  createdAt: DateTime.utc(2024, 1, 1),
  updatedAt: DateTime.utc(2024, 1, 1),
);

enum _EntryKind {
  forMedia('Edit details'),
  forId('Edit by id');

  const _EntryKind(this.label);

  final String label;
}

class _NoSessionPlayerController extends PlayerController {
  @override
  PlaybackSession? build() => null;
}

class _SessionPlayerController extends PlayerController {
  _SessionPlayerController(this._session);
  final PlaybackSession _session;

  @override
  PlaybackSession? build() => _session;
}

class _FakePrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async => AppPreferencesState.initial;
}

class _CountingLibraryRepository implements MediaLibraryRepository {
  _CountingLibraryRepository();

  bool failTitle = false;

  int titleCalls = 0;
  int languageCalls = 0;
  String? lastTitleId;
  String? lastTitle;
  String? lastLanguageId;
  String? lastLanguage;

  @override
  Future<void> updateMediaTitle(String id, String title) async {
    titleCalls++;
    if (failTitle) throw const FileFailure('boom');
    lastTitleId = id;
    lastTitle = title;
  }

  @override
  Future<void> updateMediaLanguage(String id, String language) async {
    languageCalls++;
    lastLanguageId = id;
    lastLanguage = language;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class _ActionHarness extends ConsumerWidget {
  const _ActionHarness({
    required this.entryKind,
    required this.media,
    this.mediaId = 'media-1',
  });

  final _EntryKind entryKind;
  final Media media;
  final String mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            switch (entryKind) {
              case _EntryKind.forMedia:
                unawaited(editMediaDetails(context, ref, media));
              case _EntryKind.forId:
                unawaited(editMediaDetailsForId(context, ref, mediaId));
            }
          },
          child: Text(entryKind.label),
        ),
      ),
    );
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required _EntryKind entryKind,
  required _CountingLibraryRepository repo,
  Media? media,
  AppDatabase? db,
  PlaybackSession? session,
  String mediaId = 'media-1',
}) async {
  final overrides = <Override>[
    mediaLibraryRepositoryProvider.overrideWithValue(repo),
    playerControllerProvider.overrideWith(() {
      if (session != null) {
        return _SessionPlayerController(session);
      }
      return _NoSessionPlayerController();
    }),
    appPreferencesCtrlProvider.overrideWith(_FakePrefsCtrl.new),
    if (db != null) mediaRegistryProvider.overrideWithValue(MediaRegistry(db)),
  ];

  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );

  late final ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return MaterialApp(
            theme: ThemeData(
              colorScheme: scheme,
              useMaterial3: true,
              brightness: Brightness.dark,
              extensions: [EnjoyThemeTokens.build(scheme)],
            ),
            locale: const Locale('en', 'US'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            scaffoldMessengerKey: appScaffoldMessengerKey,
            home: _ActionHarness(
              entryKind: entryKind,
              media: media ?? _media,
              mediaId: mediaId,
            ),
          );
        },
      ),
    ),
  );
  return container;
}

Media _mediaWithLanguage(String language) => Media(
  id: _media.id,
  kind: _media.kind,
  title: _media.title,
  sourceUri: _media.sourceUri,
  thumbnailPath: _media.thumbnailPath,
  durationMs: _media.durationMs,
  language: language,
  contentHash: _media.contentHash,
  fileSize: _media.fileSize,
  mediaUrl: _media.mediaUrl,
  source: _media.source,
  provider: _media.provider,
  syncStatus: _media.syncStatus,
  createdAt: _media.createdAt,
  updatedAt: _media.updatedAt,
);

Future<void> _openDialogFromMedia(WidgetTester tester) async {
  await tester.tap(find.text(_EntryKind.forMedia.label));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('editMediaDetails', () {
    testWidgets('opens prefilled with the current title and language', (
      tester,
    ) async {
      final repo = _CountingLibraryRepository();
      await _pump(tester, entryKind: _EntryKind.forMedia, repo: repo);
      await tester.pumpAndSettle();
      await _openDialogFromMedia(tester);

      expect(find.text('Edit details'), findsNWidgets(2));
      expect(find.text('Sample'), findsOneWidget);
      expect(find.text('English (US)'), findsOneWidget);
    });

    testWidgets('a blank title keeps Save disabled', (tester) async {
      final repo = _CountingLibraryRepository();
      await _pump(tester, entryKind: _EntryKind.forMedia, repo: repo);
      await tester.pumpAndSettle();
      await _openDialogFromMedia(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      final saveButton = tester.widget<EnjoyButton>(
        find.ancestor(
          of: find.text('Save'),
          matching: find.byType(EnjoyButton),
        ),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('save with a rename and a language pick updates both', (
      tester,
    ) async {
      final repo = _CountingLibraryRepository();
      final session = PlaybackSession(
        mediaId: 'media-1',
        dexieTargetType: 'Video',
        mediaType: 'video',
        mediaTitle: 'Sample',
        durationSeconds: 10,
        currentTimeSeconds: 0,
        currentSegmentIndex: 0,
        language: 'en',
        startedAt: DateTime.utc(2024, 1, 1),
        lastActiveAt: DateTime.utc(2024, 1, 1),
      );
      final container = await _pump(
        tester,
        entryKind: _EntryKind.forMedia,
        repo: repo,
        session: session,
      );
      await tester.pumpAndSettle();
      await _openDialogFromMedia(tester);

      await tester.enterText(find.byType(TextField), 'Renamed');
      await tester.pump();
      await tester.tap(find.text('English (US)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Japanese'));
      await tester.pumpAndSettle();
      expect(find.text('Japanese'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.titleCalls, 1);
      expect(repo.lastTitleId, 'media-1');
      expect(repo.lastTitle, 'Renamed');
      expect(repo.languageCalls, 1);
      expect(repo.lastLanguageId, 'media-1');
      expect(repo.lastLanguage, 'ja-JP');

      final patched = container.read(playerControllerProvider)!;
      expect(patched.mediaTitle, 'Renamed');
      expect(patched.language, 'ja-JP');
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('save without changes touches nothing', (tester) async {
      final repo = _CountingLibraryRepository();
      await _pump(tester, entryKind: _EntryKind.forMedia, repo: repo);
      await tester.pumpAndSettle();
      await _openDialogFromMedia(tester);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.titleCalls, 0);
      expect(repo.languageCalls, 0);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a broad stored language is canonicalized on save', (
      tester,
    ) async {
      final repo = _CountingLibraryRepository();
      await _pump(
        tester,
        entryKind: _EntryKind.forMedia,
        repo: repo,
        media: _mediaWithLanguage('en'),
      );
      await tester.pumpAndSettle();
      await _openDialogFromMedia(tester);

      expect(find.text('English (US)'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.titleCalls, 0);
      expect(repo.languageCalls, 1);
      expect(repo.lastLanguageId, 'media-1');
      expect(repo.lastLanguage, 'en-US');
    });

    testWidgets('dismissal saves nothing', (tester) async {
      final repo = _CountingLibraryRepository();
      await _pump(tester, entryKind: _EntryKind.forMedia, repo: repo);
      await tester.pumpAndSettle();
      await _openDialogFromMedia(tester);

      await tester.enterText(find.byType(TextField), 'Renamed');
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repo.titleCalls, 0);
      expect(repo.languageCalls, 0);
    });

    testWidgets('a failing save surfaces the error notice', (tester) async {
      final repo = _CountingLibraryRepository();
      repo.failTitle = true;
      await _pump(tester, entryKind: _EntryKind.forMedia, repo: repo);
      await tester.pumpAndSettle();
      await _openDialogFromMedia(tester);

      await tester.enterText(find.byType(TextField), 'Renamed');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.titleCalls, 1);
      expect(find.byType(SnackBar), findsWidgets);
    });
  });

  group('editMediaDetailsForId', () {
    testWidgets('opens the dialog for a stored media row', (tester) async {
      final repo = _CountingLibraryRepository();
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      final now = DateTime.now();
      await db.videoDao.insertRow(
        VideoRow(
          id: 'media-1',
          vid: 'vid-1',
          provider: 'user',
          title: 'Stored row',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 0,
          language: 'en-US',
          source: null,
          localUri: null,
          md5: null,
          size: null,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _pump(tester, entryKind: _EntryKind.forId, repo: repo, db: db);
      await tester.pumpAndSettle();
      await tester.tap(find.text(_EntryKind.forId.label));
      await tester.pumpAndSettle();

      expect(find.text('Stored row'), findsOneWidget);
      expect(find.text('English (US)'), findsOneWidget);
    });

    testWidgets('a missing row surfaces the missing notice', (tester) async {
      final repo = _CountingLibraryRepository();
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);

      await _pump(tester, entryKind: _EntryKind.forId, repo: repo, db: db);
      await tester.pumpAndSettle();
      await tester.tap(find.text(_EntryKind.forId.label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('This item is no longer in your library.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
    });
  });
}
