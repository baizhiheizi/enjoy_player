import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/widgets/video_line_info_chip.dart';
import 'package:enjoy_player/features/player/presentation/widgets/video_paused_gate.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const _mediaId = 'chip-media';
final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

class _SessionPlayerController extends PlayerController {
  @override
  PlaybackSession? build() => PlaybackSession(
    mediaId: _mediaId,
    dexieTargetType: 'Video',
    mediaType: 'video',
    mediaTitle: 'Chip media',
    durationSeconds: 120,
    currentTimeSeconds: 0,
    currentSegmentIndex: 0,
    language: 'en',
    startedAt: _epoch,
    lastActiveAt: _epoch,
  );
}

final _cueIndexProvider = NotifierProvider<_CueNotifier, int>(_CueNotifier.new);

class _CueNotifier extends Notifier<int> {
  @override
  int build() => 2;
}

final _playingProvider = NotifierProvider<_PlayingNotifier, bool>(
  _PlayingNotifier.new,
);

class _PlayingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

List<Override> _overrides() {
  final db = AppDatabase(executor: NativeDatabase.memory());
  return [
    appDatabaseProvider.overrideWithValue(db),
    deviceGlobalAppDatabaseProvider.overrideWithValue(db),
    playerControllerProvider.overrideWith(_SessionPlayerController.new),
    playerIsPlayingProvider.overrideWith(
      (ref) => Stream.value(ref.watch(_playingProvider)),
    ),
    playerIsBufferingProvider.overrideWith((ref) => Stream.value(false)),
    transcriptLinesForMediaProvider(_mediaId).overrideWith(
      (ref) => Stream.value(
        List.generate(
          5,
          (i) => TranscriptLine(
            text: 'Line $i',
            startMs: i * 1000,
            durationMs: 1000,
          ),
        ),
      ),
    ),
    transcriptPlaybackHighlightProvider(_mediaId).overrideWith(
      (ref) => (cueIndex: ref.watch(_cueIndexProvider), wordIndex: null),
    ),
  ];
}

Future<ProviderContainer> _pumpChip(WidgetTester tester) async {
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(),
      child: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(left: 12, bottom: 12, child: VideoLineInfoChip()),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  return container;
}

void main() {
  testWidgets('chip shows line caption while paused', (tester) async {
    await _pumpChip(tester);

    expect(find.text('Line 3 of 5'), findsOneWidget);
  });

  testWidgets('chip appends looping suffix while echo is active', (
    tester,
  ) async {
    final container = await _pumpChip(tester);

    container
        .read(echoModeProvider.notifier)
        .activate(
          startLineIndex: 2,
          endLineIndex: 4,
          startTimeSeconds: 2,
          endTimeSeconds: 5,
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Line 3 of 5 · looping'), findsOneWidget);
  });

  testWidgets('chip blocks taps and fades while playing', (tester) async {
    final container = await _pumpChip(tester);

    container.read(_playingProvider.notifier).state = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Line 3 of 5'), findsOneWidget);
    final opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(VideoPausedGate),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, 0.0);
    final ignore = tester.widget<IgnorePointer>(
      find.descendant(
        of: find.byType(VideoPausedGate),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(ignore.ignoring, isTrue);
  });

  testWidgets('chip is absent when the cue is outside any line', (
    tester,
  ) async {
    final container = await _pumpChip(tester);

    container.read(_cueIndexProvider.notifier).state = -1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Line 3 of 5'), findsNothing);
    expect(find.byType(Text), findsNothing);
  });
}
