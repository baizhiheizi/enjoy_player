import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/core/audio/recording_preview_player.dart';
import 'package:enjoy_player/core/audio/recording_preview_player_provider.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_takes_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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

Widget _wrap({
  required AppDatabase db,
  required _RecordingPreviewStub preview,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      recordingPreviewPlayerProvider.overrideWithValue(preview),
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

  Future<AppLocalizations> pumpRow(
    WidgetTester tester, {
    required List<RecordingRow> takes,
    String? selectedId,
    bool hasMediaPath = true,
  }) async {
    final l10n = await _loadL10n();
    await tester.pumpWidget(
      _wrap(
        db: db,
        preview: preview,
        child: ShadowTakesRow(
          takes: takes,
          selectedId: selectedId,
          echoActive: true,
          pitchExpanded: false,
          hasMediaPath: hasMediaPath,
          onPlayOrPause: (_) {},
          onChooseTake: (_) {},
          onTogglePitch: () {},
        ),
      ),
    );
    await tester.pump();
    return l10n;
  }

  testWidgets('renders one chip per take, newest first, with durations', (
    tester,
  ) async {
    final l10n = await pumpRow(
      tester,
      takes: [
        _row(id: 't2', localPath: '/tmp/t2.wav', duration: 4600),
        _row(id: 't1', localPath: '/tmp/t1.wav', duration: 3900),
      ],
      selectedId: 't2',
    );

    expect(find.text('${l10n.shadowRecordingTake} 2'), findsOneWidget);
    expect(find.text('${l10n.shadowRecordingTake} 1'), findsOneWidget);
    expect(find.text('4.6 s'), findsOneWidget);
    expect(find.text('3.9 s'), findsOneWidget);
    expect(find.text(l10n.shadowTakesLabel.toUpperCase()), findsOneWidget);
  });

  testWidgets('scored take shows its uncolored score chip', (tester) async {
    final l10n = await pumpRow(
      tester,
      takes: [
        _row(id: 't1', localPath: '/tmp/t1.wav', assessmentJson: _kScoredJson),
      ],
      selectedId: 't1',
    );

    expect(find.text('92'), findsOneWidget);
    expect(find.text(l10n.assessmentScoreAction), findsNothing);
  });

  testWidgets('unscored take shows the Score action', (tester) async {
    final l10n = await pumpRow(
      tester,
      takes: [_row(id: 't1', localPath: '/tmp/t1.wav')],
      selectedId: 't1',
    );

    expect(find.text(l10n.assessmentScoreAction), findsOneWidget);
  });

  testWidgets('chips sit on one horizontally scrollable line', (tester) async {
    await pumpRow(
      tester,
      takes: [
        _row(id: 't3', localPath: '/tmp/t3.wav'),
        _row(id: 't2', localPath: '/tmp/t2.wav'),
        _row(id: 't1', localPath: '/tmp/t1.wav'),
      ],
      selectedId: 't3',
    );

    final scrolls = tester.widgetList<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scrolls, isNotEmpty);
    expect(scrolls.every((s) => s.scrollDirection == Axis.horizontal), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mouse wheel scrolls the chip line horizontally', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.binding.setSurfaceSize(const Size(420, 300));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpRow(
        tester,
        takes: [
          _row(id: 't3', localPath: '/tmp/t3.wav'),
          _row(id: 't2', localPath: '/tmp/t2.wav'),
          _row(id: 't1', localPath: '/tmp/t1.wav'),
        ],
        selectedId: 't3',
      );

      final scrollable = find
          .descendant(
            of: find.byType(ShadowTakesRow),
            matching: find.byType(Scrollable),
          )
          .first;
      final center = tester.getCenter(scrollable);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(center));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 60)));
      await tester.pump();

      final state = tester.state<ScrollableState>(scrollable);
      expect(state.position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('empty region shows the hint with the R keycap', (tester) async {
    final l10n = await pumpRow(tester, takes: const []);

    expect(find.textContaining(l10n.shadowTakesEmptyPrefix), findsOneWidget);
    expect(find.byType(EnjoyKeycap), findsOneWidget);
  });
}
