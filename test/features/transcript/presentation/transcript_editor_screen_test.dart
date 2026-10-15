import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_editor_screen.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _mediaId = 'editor-media';
const _transcriptId = 'editor-transcript';

final _seededRow = TranscriptRow(
  id: _transcriptId,
  targetType: 'Video',
  targetId: _mediaId,
  language: 'en',
  source: 'user',
  timelineJson: '[]',
  label: 'EN',
  createdAt: DateTime.utc(2026, 3, 1),
  updatedAt: DateTime.utc(2026, 3, 1),
);

const _seededLines = [
  TranscriptLine(
    text: 'Hello',
    startMs: 1000,
    durationMs: 500,
    timeline: [TranscriptWord(text: 'Hello', startMs: 0, durationMs: 500)],
  ),
  TranscriptLine(text: 'World', startMs: 2000, durationMs: 750),
];

class _FakeEditorRepository extends TranscriptRepository {
  _FakeEditorRepository({this.row, this.lines = const [], this.rows = const []})
    : super(AppDatabase(executor: NativeDatabase.memory()));

  final TranscriptRow? row;
  final List<TranscriptLine> lines;
  final List<TranscriptRow> rows;

  List<TranscriptLine>? savedLines;
  String? savedTranscriptId;

  @override
  Future<TranscriptRow?> primaryTranscriptRowForMedia(String mediaId) async =>
      row;

  @override
  Future<List<TranscriptRow>> transcriptRowsForMedia(String mediaId) async =>
      rows;

  @override
  Future<List<TranscriptLine>> linesForRowPreloaded(TranscriptRow row) async =>
      lines;

  @override
  Future<bool> replaceTimeline({
    required String transcriptId,
    required List<TranscriptLine> lines,
  }) async {
    savedTranscriptId = transcriptId;
    savedLines = lines;
    return true;
  }
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeEditorRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [transcriptRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TranscriptEditorScreen(mediaId: _mediaId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  Future<void> pumpEditorOverHome(
    WidgetTester tester,
    _FakeEditorRepository repo,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [transcriptRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const TranscriptEditorScreen(mediaId: _mediaId),
                ),
              ),
              child: const Text('open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open editor'));
    await tester.pumpAndSettle();
  }

  testWidgets('saves edited text and timing through the repository', (
    tester,
  ) async {
    final repo = _FakeEditorRepository(row: _seededRow, lines: _seededLines);
    await pumpEditorOverHome(tester, repo);

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('World'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('transcript-editor-text-1')),
      'Hi there',
    );
    await tester.enterText(
      find.byKey(const ValueKey('transcript-editor-start-1')),
      '1.25',
    );
    await tester.enterText(
      find.byKey(const ValueKey('transcript-editor-duration-1')),
      '0.5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('transcript-editor-duration-2')),
      '0',
    );
    await tester.tap(find.byKey(const ValueKey('transcript-editor-save')));
    await tester.pumpAndSettle();

    expect(find.byType(TranscriptEditorScreen), findsNothing);
    expect(repo.savedTranscriptId, _transcriptId);
    expect(repo.savedLines, hasLength(2));
    expect(repo.savedLines![0].text, 'Hi there');
    expect(repo.savedLines![0].startMs, 1250);
    expect(repo.savedLines![0].durationMs, 500);
    expect(repo.savedLines![0].timeline, isNull);
    expect(repo.savedLines![1].text, 'World');
    expect(repo.savedLines![1].startMs, 2000);
    expect(repo.savedLines![1].durationMs, 0);
    expect(repo.savedLines![1].timeline, isNull);
  });

  testWidgets('keeps word timings when only the timing changed', (
    tester,
  ) async {
    final repo = _FakeEditorRepository(row: _seededRow, lines: _seededLines);
    await pumpEditorOverHome(tester, repo);

    await tester.enterText(
      find.byKey(const ValueKey('transcript-editor-duration-1')),
      '2',
    );
    await tester.tap(find.byKey(const ValueKey('transcript-editor-save')));
    await tester.pumpAndSettle();

    expect(repo.savedLines![0].text, 'Hello');
    expect(repo.savedLines![0].durationMs, 2000);
    expect(repo.savedLines![0].timeline, isNotNull);
  });

  testWidgets('rejects blank timing and saves nothing', (tester) async {
    final repo = _FakeEditorRepository(row: _seededRow, lines: _seededLines);
    await _pumpScreen(tester, repo);

    await tester.enterText(
      find.byKey(const ValueKey('transcript-editor-start-1')),
      '',
    );
    await tester.tap(find.byKey(const ValueKey('transcript-editor-save')));
    await tester.pumpAndSettle();

    expect(
      find.text('Start and duration must be times in seconds, like 1.25.'),
      findsOneWidget,
    );
    expect(repo.savedLines, isNull);
  });

  testWidgets('denies malformed timing keystrokes in the field', (
    tester,
  ) async {
    final repo = _FakeEditorRepository(row: _seededRow, lines: _seededLines);
    await _pumpScreen(tester, repo);

    await tester.enterText(
      find.byKey(const ValueKey('transcript-editor-start-1')),
      '1.2.5',
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('1.2.5'), findsNothing);
  });

  testWidgets('pops back without a dialog when nothing was edited', (
    tester,
  ) async {
    final repo = _FakeEditorRepository(row: _seededRow, lines: _seededLines);
    await pumpEditorOverHome(tester, repo);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(TranscriptEditorScreen), findsNothing);
    expect(find.text('open editor'), findsOneWidget);
  });

  testWidgets('asks before discarding unsaved edits on back', (tester) async {
    final repo = _FakeEditorRepository(row: _seededRow, lines: _seededLines);
    await pumpEditorOverHome(tester, repo);

    await tester.enterText(
      find.byKey(const ValueKey('transcript-editor-text-1')),
      'Hi',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(TranscriptEditorScreen), findsOneWidget);
    expect(find.text('Discard unsaved edits?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(TranscriptEditorScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(TranscriptEditorScreen), findsNothing);
    expect(repo.savedLines, isNull);
  });

  testWidgets('shows the empty state without a transcript', (tester) async {
    await _pumpScreen(tester, _FakeEditorRepository());

    expect(find.text('This media has no transcript to edit.'), findsOneWidget);
    final save = tester.widget<TextButton>(
      find.byKey(const ValueKey('transcript-editor-save')),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('shows the no-cues state for a row without lines', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      _FakeEditorRepository(row: _seededRow, lines: const []),
    );

    expect(find.text('This transcript has no lines to edit.'), findsOneWidget);
  });

  testWidgets('falls back to the first row when no session is active', (
    tester,
  ) async {
    final repo = _FakeEditorRepository(rows: [_seededRow], lines: _seededLines);
    await _pumpScreen(tester, repo);

    expect(find.text('Hello'), findsOneWidget);
  });
}
