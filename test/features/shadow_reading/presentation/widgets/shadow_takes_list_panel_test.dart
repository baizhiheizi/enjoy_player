import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/core/audio/recording_preview_player.dart';
import 'package:enjoy_player/core/audio/recording_preview_player_provider.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_take_providers.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_takes_ui_state.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_takes_list_panel.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _kScoredJson = '''
{
  "NBest": [
    {
      "PronunciationAssessment": {
        "PronScore": 92
      }
    }
  ]
}
''';

RecordingRow _row({
  required String id,
  String? localPath,
  String? assessmentJson,
  int? pronunciationScore,
  int duration = 3900,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return RecordingRow(
    id: id,
    targetType: 'Audio',
    targetId: 'm1',
    referenceStart: 0,
    referenceDuration: 5000,
    referenceText: 'Hi',
    language: 'en',
    duration: duration,
    md5: null,
    audioUrl: null,
    pronunciationScore: pronunciationScore,
    assessmentJson: assessmentJson,
    localPath: localPath,
    syncStatus: 'local',
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

class _RecordingPreviewStub implements RecordingPreviewPlayback {
  _RecordingPreviewStub();

  String? _loaded;
  final _playing = StreamController<bool>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();

  @override
  String? get loadedPath => _loaded;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<Duration> get duration => _duration.stream;

  @override
  Future<void> play(String path) async {
    _loaded = path;
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> playClip(String path, Duration start, Duration end) async {
    _loaded = path;
  }

  @override
  Future<void> playOrPauseTake(String path) async {
    _loaded = path;
  }

  @override
  Future<void> stop() async {
    _loaded = null;
  }

  @override
  Future<void> dispose() async {
    await _playing.close();
    await _position.close();
    await _duration.close();
  }
}

Future<AppLocalizations> _loadL10n() =>
    AppLocalizations.delegate.load(const Locale('en'));

const _query = EchoRegionRecordingsQuery(
  targetType: 'Audio',
  targetId: 'm1',
  language: 'en',
  echoStartMs: 0,
  echoEndMs: 5000,
);

Widget _wrap({
  required AppDatabase db,
  required _RecordingPreviewStub preview,
  required Widget child,
  List<RecordingRow> takes = const [],
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      recordingPreviewPlayerProvider.overrideWithValue(preview),
      echoRegionRecordingsProvider(
        _query,
      ).overrideWithValue(Stream.value(takes)),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _RecordingPreviewStub preview;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    preview = _RecordingPreviewStub();
  });

  tearDown(() async {
    await db.close();
  });

  final takes = [
    _row(id: 't2', localPath: '/tmp/t2.wav', assessmentJson: _kScoredJson),
    _row(id: 't1', localPath: '/tmp/t1.wav'),
  ];

  Future<(List<String>, List<String>)> pumpList(WidgetTester tester) async {
    final played = <String>[];
    final deleted = <String>[];
    await tester.pumpWidget(
      _wrap(
        db: db,
        preview: preview,
        takes: takes,
        child: SizedBox(
          width: 360,
          height: 600,
          child: ShadowTakesListPanel(
            query: _query,
            onClose: () {},
            onPlayOrPause: (r) => played.add(r.id),
            onDelete: (r) async => deleted.add(r.id),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return (played, deleted);
  }

  testWidgets('lists every take, newest first, scores uncolored', (
    tester,
  ) async {
    final l10n = await _loadL10n();
    await pumpList(tester);

    expect(find.text('Take 2'), findsOneWidget);
    expect(find.text('Take 1'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Take 2')).dy,
      lessThan(tester.getTopLeft(find.text('Take 1')).dy),
    );
    expect(find.text('92'), findsOneWidget);
    expect(find.text(l10n.assessmentScoreAction), findsOneWidget);
  });

  testWidgets('playing a take selects it', (tester) async {
    final (played, _) = await pumpList(tester);

    await tester.tap(find.byKey(const ValueKey('take-play-t1')));
    await tester.pump();
    expect(played, ['t1']);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ShadowTakesListPanel)),
    );
    expect(container.read(selectedTakeProvider), 't1');
  });

  testWidgets('delete asks first, then deletes the take (R2)', (tester) async {
    final l10n = await _loadL10n();
    final (_, deleted) = await pumpList(tester);

    await tester.tap(find.byKey(const ValueKey('take-delete-t1')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.shadowRecordingDeleteConfirmTitle), findsOneWidget);
    expect(deleted, isEmpty);

    await tester.tap(find.text(l10n.shadowRecordingDelete).last);
    await tester.pumpAndSettle();
    expect(deleted, ['t1']);
  });

  testWidgets('the pitch toggle flips the loop contour', (tester) async {
    await pumpList(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ShadowTakesListPanel)),
    );
    expect(container.read(loopPitchVisibleProvider), isFalse);

    await tester.tap(find.byKey(const ValueKey('takes-pitch-toggle')));
    await tester.pump();
    expect(container.read(loopPitchVisibleProvider), isTrue);
  });
}
