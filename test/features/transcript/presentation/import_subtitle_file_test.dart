/// Covers the single local-file subtitle import entrypoint shared by the
/// transcript empty state and the subtitle track picker sheet.
library;

import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:drift/native.dart';
import 'package:enjoy_player/core/analytics/analytics.dart';
import 'package:enjoy_player/core/analytics/analytics_events.dart';
import 'package:enjoy_player/core/analytics/analytics_provider.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/import_subtitle_file.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _epoch = DateTime.utc(2024);

final class _RecordingAnalytics implements Analytics {
  final List<({String name, Map<String, Object>? properties})> captures = [];

  @override
  void capture(String name, {Map<String, Object>? properties}) =>
      captures.add((name: name, properties: properties));

  List<String> get names => captures.map((c) => c.name).toList();

  Map<String, Object> propertiesOf(String name) =>
      captures.lastWhere((c) => c.name == name).properties ?? const {};

  @override
  void screen(String name) {}

  @override
  void identify(String userId, {Map<String, Object>? userProperties}) {}

  @override
  void reset() {}

  @override
  void setEnabled(bool enabled) {}

  @override
  Future<T> flag<T extends Object>({
    required String key,
    required T fallback,
  }) async => fallback;

  @override
  Future<void> flush() async {}
}

final class _RecordingRepository extends TranscriptRepository {
  _RecordingRepository(super.db);

  final List<({String mediaId, String path, String language})> imports = [];
  Object? failure;

  @override
  Future<void> importSubtitle({
    required String mediaId,
    required XFile file,
    required String language,
    String? label,
  }) async {
    final error = failure;
    if (error != null) throw error;
    imports.add((mediaId: mediaId, path: file.path, language: language));
  }
}

late BuildContext hostContext;
late WidgetRef hostRef;

Widget _harness(ProviderContainer container) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      scaffoldMessengerKey: appScaffoldMessengerKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Consumer(
            builder: (context, ref, _) {
              hostContext = context;
              hostRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late String srtPath;
  late Future<void> pendingImport;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('subtitle_import_');
    srtPath = '${tempDir.path}/movie.en.srt';
    await File(
      srtPath,
    ).writeAsString('1\n00:00:01,000 --> 00:00:03,000\nHello world\n');
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  ProviderContainer containerFor(
    _RecordingAnalytics analytics,
    TranscriptRepository repo,
  ) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        transcriptRepositoryProvider.overrideWithValue(repo),
        analyticsProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> startImport(
    WidgetTester tester, {
    required String? path,
    String name = 'movie.en.srt',
    String mediaId = 'm1',
  }) async {
    pendingImport = pickAndImportSubtitleFile(
      hostContext,
      hostRef,
      mediaId,
      pickFile: () async => path == null ? null : (path: path, name: name),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startRealImport(
    WidgetTester tester, {
    required String path,
    String name = 'movie.en.srt',
    String mediaId = 'm1',
  }) async {
    await tester.runAsync(() async {
      pendingImport = pickAndImportSubtitleFile(
        hostContext,
        hostRef,
        mediaId,
        pickFile: () async => (path: path, name: name),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }

  group('import flow', () {
    late _RecordingAnalytics analytics;
    late _RecordingRepository repo;

    setUp(() {
      analytics = _RecordingAnalytics();
      repo = _RecordingRepository(db);
    });

    Future<void> pumpFlow(WidgetTester tester) async {
      await tester.pumpWidget(_harness(containerFor(analytics, repo)));
      await startImport(tester, path: srtPath);
    }

    testWidgets('imports the picked file hinted by its filename', (
      tester,
    ) async {
      await pumpFlow(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.controller.text, 'en');

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await pendingImport;

      expect(repo.imports, [(mediaId: 'm1', path: srtPath, language: 'en')]);
      expect(find.text('Subtitle imported'), findsOneWidget);
    });

    testWidgets('reports the transcript generation funnel', (tester) async {
      await pumpFlow(tester);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await pendingImport;

      expect(analytics.names, [
        AnalyticsEvents.transcriptGenerationRequested,
        AnalyticsEvents.transcriptGenerationCompleted,
      ]);
      for (final event in const [
        AnalyticsEvents.transcriptGenerationRequested,
        AnalyticsEvents.transcriptGenerationCompleted,
      ]) {
        expect(
          analytics.propertiesOf(event)[AnalyticsEvents.propSource],
          AnalyticsEvents.sourceLocalFile,
          reason: event,
        );
      }
    });

    testWidgets('a cancelled picker neither opens the dialog nor imports', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(containerFor(analytics, repo)));
      await startImport(tester, path: null);
      await pendingImport;

      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.imports, isEmpty);
      expect(analytics.names, isEmpty);
    });

    testWidgets('cancelling the language dialog imports nothing', (
      tester,
    ) async {
      await pumpFlow(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await pendingImport;

      expect(repo.imports, isEmpty);
      expect(analytics.names, isEmpty);
      expect(find.text('Subtitle imported'), findsNothing);
    });

    testWidgets('a blank language imports nothing', (tester) async {
      await pumpFlow(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await pendingImport;

      expect(repo.imports, isEmpty);
      expect(analytics.names, isEmpty);
      expect(find.text('Subtitle imported'), findsNothing);
    });

    testWidgets('the chosen language is trimmed before import', (tester) async {
      await pumpFlow(tester);

      await tester.enterText(find.byType(TextField), '  fr-CA  ');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await pendingImport;

      expect(repo.imports.single.language, 'fr-CA');
    });

    testWidgets('a failing import reports the funnel and rethrows', (
      tester,
    ) async {
      repo.failure = StateError('nope');
      await pumpFlow(tester);

      final caught = expectLater(pendingImport, throwsA(isA<StateError>()));
      await tester.tap(find.text('OK'));
      await tester.pump();
      await caught;
      await tester.pumpAndSettle();

      expect(analytics.names, [
        AnalyticsEvents.transcriptGenerationRequested,
        AnalyticsEvents.transcriptGenerationFailed,
      ]);
      expect(repo.imports, isEmpty);
      expect(find.text('Subtitle imported'), findsNothing);
    });
  });

  group('repository wiring', () {
    testWidgets('persists the imported track for the chosen language', (
      tester,
    ) async {
      final analytics = _RecordingAnalytics();
      final container = containerFor(analytics, TranscriptRepository(db));
      await tester.pumpWidget(_harness(container));
      await tester.runAsync(
        () => db.videoDao.insertRow(
          VideoRow(
            id: 'm1',
            vid: 'aaaaaaaaaaa',
            provider: 'user',
            title: 'Video m1',
            durationSeconds: 10,
            language: 'en',
            mediaUrl: null,
            source: null,
            localUri: '${tempDir.path}/movie.mp4',
            createdAt: _epoch,
            updatedAt: _epoch,
          ),
        ),
      );

      await startRealImport(tester, path: srtPath);
      await tester.tap(find.text('OK'));
      await tester.runAsync(() async {
        await pendingImport;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      final rows = await db.transcriptDao.listForTarget('Video', 'm1');
      expect(rows, hasLength(1));
      expect(rows.single.language, 'en');
      expect(rows.single.source, 'user');
    });
  });
}
