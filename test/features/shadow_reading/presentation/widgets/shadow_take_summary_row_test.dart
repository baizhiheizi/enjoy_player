import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/core/audio/recording_preview_player.dart';
import 'package:enjoy_player/core/audio/recording_preview_player_provider.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_take_summary_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
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

  Future<AppLocalizations> pumpSummary(
    WidgetTester tester, {
    required List<RecordingRow> takes,
    RecordingRow? selected,
    VoidCallback? onOpenList,
    void Function(RecordingRow row)? onPlay,
  }) async {
    final l10n = await _loadL10n();
    await tester.pumpWidget(
      _wrap(
        db: db,
        preview: preview,
        child: ShadowTakeSummaryRow(
          takes: takes,
          selected: selected,
          onPlayOrPause: onPlay ?? (_) {},
          onOpenList: onOpenList ?? () {},
        ),
      ),
    );
    await tester.pump();
    return l10n;
  }

  testWidgets('scored take reads Take n · score with its level, no hue', (
    tester,
  ) async {
    final scored = _row(
      id: 't2',
      localPath: '/tmp/t2.wav',
      assessmentJson: _kScoredJson,
    );
    final l10n = await pumpSummary(
      tester,
      takes: [
        scored,
        _row(id: 't1', localPath: '/tmp/t1.wav'),
      ],
      selected: scored,
    );

    expect(find.textContaining('Take 2'), findsOneWidget);
    expect(find.textContaining('· 92'), findsOneWidget);
    expect(find.text(l10n.assessmentLevelExcellent), findsOneWidget);
    expect(find.text('2 takes'), findsOneWidget);
  });

  testWidgets('unscored take says it is not scored yet', (tester) async {
    final row = _row(id: 't1', localPath: '/tmp/t1.wav');
    final l10n = await pumpSummary(tester, takes: [row], selected: row);

    expect(
      find.textContaining('Not scored yet'),
      findsOneWidget,
      reason: l10n.takeNotScoredClick,
    );
    expect(find.text('1 take'), findsOneWidget);
  });

  testWidgets('“n takes ›” opens the list; play plays the selected take', (
    tester,
  ) async {
    final row = _row(id: 't1', localPath: '/tmp/t1.wav');
    var opened = 0;
    final played = <String>[];
    await pumpSummary(
      tester,
      takes: [row],
      selected: row,
      onOpenList: () => opened++,
      onPlay: (r) => played.add(r.id),
    );

    await tester.tap(find.byKey(const ValueKey('takes-summary-open-list')));
    await tester.tap(find.byKey(const ValueKey('takes-summary-play')));
    expect(opened, 1);
    expect(played, ['t1']);
  });

  testWidgets('no takes: plain hint on mobile', (tester) async {
    final l10n = await pumpSummary(tester, takes: const []);

    expect(find.text(l10n.shadowRecordingEmpty), findsOneWidget);
    expect(find.byType(EnjoyKeycap), findsNothing);
  });

  testWidgets('no takes: hint with the R keycap on desktop', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final l10n = await pumpSummary(tester, takes: const []);

      expect(find.text(l10n.shadowTakesEmptyPrefix), findsOneWidget);
      expect(find.byType(EnjoyKeycap), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
