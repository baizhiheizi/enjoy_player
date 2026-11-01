import 'dart:convert';
import 'dart:typed_data';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/platform/file_share_export.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/subtitle/subtitle_serializer.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/download_transcript.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _mediaId = 'download-media';
final _epoch = DateTime.utc(2026);

const _lines = [
  TranscriptLine(text: 'Hello world', startMs: 1000, durationMs: 2500),
  TranscriptLine(text: 'Second cue', startMs: 4000, durationMs: 1500),
];

class _Session extends PlayerController {
  _Session(this.title);

  final String title;

  @override
  PlaybackSession? build() => PlaybackSession(
    mediaId: _mediaId,
    dexieTargetType: 'Audio',
    mediaType: 'audio',
    mediaTitle: title,
    durationSeconds: 60,
    currentTimeSeconds: 0,
    currentSegmentIndex: 0,
    language: 'en',
    startedAt: _epoch,
    lastActiveAt: _epoch,
  );
}

final class _SavedExport {
  _SavedExport(this.bytes, this.fileName, this.mimeType, this.dialogTitle);

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final String dialogTitle;
}

class _FormatPickSpy {
  SubtitleExportFormat? result;
  int calls = 0;

  Future<SubtitleExportFormat?> pick(BuildContext context) {
    calls++;
    return Future.value(result);
  }
}

late BuildContext hostContext;
late WidgetRef hostRef;
late Future<void> pendingDownload;

Widget _harness(List<TranscriptLine> lines) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  return ProviderScope(
    overrides: [
      playerControllerProvider.overrideWith(() => _Session('The Ferry at Six')),
      transcriptLinesForMediaProvider(
        _mediaId,
      ).overrideWith((ref) => Stream.value(lines)),
    ],
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
              ref.watch(transcriptLinesForMediaProvider(_mediaId));
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
  Future<List<_SavedExport>> startDownload(
    WidgetTester tester, {
    _FormatPickSpy? pick,
    FileShareOutcome Function()? saveResult,
    List<TranscriptLine> lines = _lines,
  }) async {
    final saved = <_SavedExport>[];
    await tester.pumpWidget(_harness(lines));
    await tester.pumpAndSettle();
    pendingDownload = downloadActiveTranscript(
      hostContext,
      hostRef,
      _mediaId,
      pickFormat: pick?.pick,
      saveFile:
          ({
            required bytes,
            required fileName,
            required mimeType,
            required dialogTitle,
          }) async {
            saved.add(_SavedExport(bytes, fileName, mimeType, dialogTitle));
            return saveResult?.call() ?? FileShareOutcome.saved;
          },
    );
    await pendingDownload;
    tester.binding.scheduleFrame();
    await tester.pump();
    await tester.pumpAndSettle();
    return saved;
  }

  testWidgets('saves the serialized transcript named after the media title', (
    tester,
  ) async {
    final pick = _FormatPickSpy()..result = SubtitleExportFormat.srt;

    final saved = await startDownload(tester, pick: pick);

    expect(pick.calls, 1);
    expect(saved, hasLength(1));
    expect(saved.single.fileName, 'The Ferry at Six.srt');
    expect(saved.single.mimeType, 'application/x-subrip');
    expect(saved.single.dialogTitle, 'Download transcript');
    expect(utf8.decode(saved.single.bytes), serializeSrt(_lines));
    expect(find.text('Transcript downloaded.'), findsOneWidget);
  });

  testWidgets('serializes VTT when that format is picked', (tester) async {
    final pick = _FormatPickSpy()..result = SubtitleExportFormat.vtt;

    final saved = await startDownload(tester, pick: pick);

    expect(saved.single.fileName, 'The Ferry at Six.vtt');
    expect(saved.single.mimeType, 'text/vtt');
    expect(utf8.decode(saved.single.bytes), serializeVtt(_lines));
  });

  testWidgets('cancelled save shows no notice', (tester) async {
    final pick = _FormatPickSpy()..result = SubtitleExportFormat.srt;

    final saved = await startDownload(
      tester,
      pick: pick,
      saveResult: () => FileShareOutcome.cancelled,
    );

    expect(saved, hasLength(1));
    expect(find.text('Transcript downloaded.'), findsNothing);
    expect(find.text('Could not download the transcript.'), findsNothing);
  });

  testWidgets('failed save shows the error notice', (tester) async {
    final pick = _FormatPickSpy()..result = SubtitleExportFormat.srt;

    await startDownload(
      tester,
      pick: pick,
      saveResult: () => FileShareOutcome.failed,
    );

    expect(find.text('Could not download the transcript.'), findsOneWidget);
  });

  testWidgets('empty transcript shows the empty notice and skips the dialog', (
    tester,
  ) async {
    final pick = _FormatPickSpy()..result = SubtitleExportFormat.srt;

    final saved = await startDownload(tester, pick: pick, lines: const []);

    expect(pick.calls, 0);
    expect(saved, isEmpty);
    expect(find.text('No transcript to download yet.'), findsOneWidget);
  });
}
