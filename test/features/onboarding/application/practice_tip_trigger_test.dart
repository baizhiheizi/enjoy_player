/// Pure policy tests for the one practice-tip trigger module (issue #794).
///
/// Covers the three WHEN policies the module centralized:
/// * the transport bar's `mediaId|echo=` mount-scoped dedupe key,
/// * the transcript panel's query-resolution + fetch-status gates,
/// * the home route normalization.
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/onboarding/application/onboarding_controller.dart';
import 'package:enjoy_player/features/onboarding/application/practice_tip_trigger.dart';
import 'package:enjoy_player/features/onboarding/domain/tip_eligibility.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/video_row_for_media_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';

/// Records every [OnboardingController] entry point the module can reach,
/// without touching progress persistence or ShowcaseView.
class _RecordingOnboardingCtrl extends OnboardingController {
  final practiceChainCtxs = <TriggerContext>[];
  final emptyTranscriptCtxs = <TriggerContext>[];
  final homeCtxs = <TriggerContext>[];
  final transcriptsMarkedAvailable = <String>[];

  @override
  int build() => 0;

  @override
  Future<void> tryStartPracticeChain(TriggerContext ctx) async {
    practiceChainCtxs.add(ctx);
  }

  @override
  Future<void> tryStartEmptyTranscript(TriggerContext ctx) async {
    emptyTranscriptCtxs.add(ctx);
  }

  @override
  Future<void> tryStartHomeEntries(TriggerContext ctx) async {
    homeCtxs.add(ctx);
  }

  @override
  Future<void> onTranscriptAvailable(String mediaId) async {
    transcriptsMarkedAvailable.add(mediaId);
  }
}

const _lines = <TranscriptLine>[
  TranscriptLine(text: 'hello', startMs: 0, durationMs: 900),
];

VideoRow _youtubeRow(String id) {
  final now = DateTime(2026, 1, 1);
  return VideoRow(
    id: id,
    vid: 'v1',
    provider: 'youtube',
    title: 'Some video',
    durationSeconds: 60,
    language: 'en',
    createdAt: now,
    updatedAt: now,
  );
}

ProviderContainer _container({List<Override> extra = const []}) {
  final container = ProviderContainer(
    overrides: [
      onboardingControllerProvider.overrideWith(_RecordingOnboardingCtrl.new),
      ...extra,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

_RecordingOnboardingCtrl _ctrlOf(ProviderContainer container) =>
    container.read(onboardingControllerProvider.notifier)
        as _RecordingOnboardingCtrl;

/// The automated test binding only draws frames that were explicitly
/// scheduled — [TransportPracticeTips.schedule] defers its fire to a
/// post-frame callback, which otherwise never runs between frames.
Future<void> _pumpFrame(WidgetTester tester) async {
  SchedulerBinding.instance.scheduleFrame();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TransportPracticeTips dedupe key', () {
    testWidgets('drops redundant schedules for the same media and echo state', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final container = _container();
      final tips = container.read(practiceTipTriggerProvider).transportBar();

      tips.schedule(routePath: '/player/m1', mediaId: 'm1', echoActive: false);
      tips.schedule(routePath: '/player/m1', mediaId: 'm1', echoActive: false);
      await _pumpFrame(tester);

      expect(_ctrlOf(container).practiceChainCtxs, hasLength(1));
    });

    testWidgets('echo toggles re-arm the key for the same media', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final container = _container();
      final tips = container.read(practiceTipTriggerProvider).transportBar();

      tips.schedule(routePath: '/player/m1', mediaId: 'm1', echoActive: false);
      await _pumpFrame(tester);
      tips.schedule(routePath: '/player/m1', mediaId: 'm1', echoActive: true);
      await _pumpFrame(tester);
      tips.schedule(routePath: '/player/m1', mediaId: 'm1', echoActive: false);
      await _pumpFrame(tester);

      final ctxs = _ctrlOf(container).practiceChainCtxs;
      expect(ctxs, hasLength(3));
      expect(ctxs.map((c) => c.echoActive), [false, true, false]);
    });

    testWidgets('a media change re-arms the key', (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final container = _container();
      final tips = container.read(practiceTipTriggerProvider).transportBar();

      tips.schedule(routePath: '/player/m1', mediaId: 'm1', echoActive: false);
      await _pumpFrame(tester);
      tips.schedule(routePath: '/player/m2', mediaId: 'm2', echoActive: false);
      await _pumpFrame(tester);

      expect(_ctrlOf(container).practiceChainCtxs.map((c) => c.mediaId), [
        'm1',
        'm2',
      ]);
    });

    testWidgets('empty media is ignored without consuming the memo', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final container = _container();
      final tips = container.read(practiceTipTriggerProvider).transportBar();

      tips.schedule(routePath: '/player/', mediaId: '', echoActive: false);
      await _pumpFrame(tester);
      expect(_ctrlOf(container).practiceChainCtxs, isEmpty);

      tips.schedule(routePath: '/player/m1', mediaId: 'm1', echoActive: false);
      await _pumpFrame(tester);
      expect(_ctrlOf(container).practiceChainCtxs, hasLength(1));
    });

    testWidgets('a fresh channel (bar remount) re-arms the memo', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final container = _container();
      final trigger = container.read(practiceTipTriggerProvider);

      final firstVisit = trigger.transportBar();
      firstVisit.schedule(
        routePath: '/player/m1',
        mediaId: 'm1',
        echoActive: false,
      );
      await _pumpFrame(tester);

      final secondVisit = trigger.transportBar();
      secondVisit.schedule(
        routePath: '/player/m1',
        mediaId: 'm1',
        echoActive: false,
      );
      await _pumpFrame(tester);

      expect(_ctrlOf(container).practiceChainCtxs, hasLength(2));
    });

    testWidgets('fires post-frame with the practice context shape', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final container = _container();
      final tips = container.read(practiceTipTriggerProvider).transportBar();

      tips.schedule(routePath: '/player/m1', mediaId: 'm1', echoActive: true);
      expect(_ctrlOf(container).practiceChainCtxs, isEmpty);
      await _pumpFrame(tester);

      final ctx = _ctrlOf(container).practiceChainCtxs.single;
      expect(ctx.routePath, '/player/m1');
      expect(ctx.mediaId, 'm1');
      expect(ctx.hasTranscript, isTrue);
      expect(ctx.echoActive, isTrue);
      expect(ctx.recordUiReady, isTrue);
      expect(ctx.assessUiReady, isTrue);
    });
  });

  group('startEmptyTranscriptIfSettled gates', () {
    test('gives up while the lines query is unresolved', () {
      final container = _container(
        extra: [
          transcriptLinesForMediaProvider(
            'm1',
          ).overrideWithValue(const AsyncValue.loading()),
        ],
      );

      container
          .read(practiceTipTriggerProvider)
          .startEmptyTranscriptIfSettled(
            mediaId: 'm1',
            routePath: '/player/m1',
          );

      final ctrl = _ctrlOf(container);
      expect(ctrl.emptyTranscriptCtxs, isEmpty);
      expect(ctrl.transcriptsMarkedAvailable, isEmpty);
    });

    test('marks the transcript available when lines exist', () {
      final container = _container(
        extra: [
          transcriptLinesForMediaProvider(
            'm1',
          ).overrideWithValue(const AsyncValue.data(_lines)),
        ],
      );

      container
          .read(practiceTipTriggerProvider)
          .startEmptyTranscriptIfSettled(
            mediaId: 'm1',
            routePath: '/player/m1',
          );

      final ctrl = _ctrlOf(container);
      expect(ctrl.transcriptsMarkedAvailable, ['m1']);
      expect(ctrl.emptyTranscriptCtxs, isEmpty);
    });

    test('aborts while the fetch status is loading', () {
      final container = _container(
        extra: [
          transcriptLinesForMediaProvider(
            'm1',
          ).overrideWithValue(const AsyncValue.data([])),
          transcriptFetchStatusProvider('m1').overrideWithValue(
            const TranscriptFetchUiState(status: TranscriptFetchStatus.loading),
          ),
        ],
      );

      container
          .read(practiceTipTriggerProvider)
          .startEmptyTranscriptIfSettled(
            mediaId: 'm1',
            routePath: '/player/m1',
          );

      expect(_ctrlOf(container).emptyTranscriptCtxs, isEmpty);
    });

    test('aborts when the fetch status is error', () {
      final container = _container(
        extra: [
          transcriptLinesForMediaProvider(
            'm1',
          ).overrideWithValue(const AsyncValue.data([])),
          transcriptFetchStatusProvider('m1').overrideWithValue(
            const TranscriptFetchUiState(status: TranscriptFetchStatus.error),
          ),
        ],
      );

      container
          .read(practiceTipTriggerProvider)
          .startEmptyTranscriptIfSettled(
            mediaId: 'm1',
            routePath: '/player/m1',
          );

      expect(_ctrlOf(container).emptyTranscriptCtxs, isEmpty);
    });

    test('starts the local empty-transcript tip when settled', () {
      final container = _container(
        extra: [
          transcriptLinesForMediaProvider(
            'm1',
          ).overrideWithValue(const AsyncValue.data([])),
          transcriptFetchStatusProvider('m1').overrideWithValue(
            const TranscriptFetchUiState(status: TranscriptFetchStatus.idle),
          ),
          videoRowForMediaProvider(
            'm1',
          ).overrideWithValue(const AsyncValue.data(null)),
        ],
      );

      container
          .read(practiceTipTriggerProvider)
          .startEmptyTranscriptIfSettled(
            mediaId: 'm1',
            routePath: '/player/m1',
          );

      final ctx = _ctrlOf(container).emptyTranscriptCtxs.single;
      expect(ctx.routePath, '/player/m1');
      expect(ctx.mediaId, 'm1');
      expect(ctx.hasTranscript, isFalse);
      expect(ctx.isYoutube, isFalse);
    });

    test('starts the youtube variant for youtube media', () {
      final container = _container(
        extra: [
          transcriptLinesForMediaProvider(
            'm1',
          ).overrideWithValue(const AsyncValue.data([])),
          transcriptFetchStatusProvider('m1').overrideWithValue(
            const TranscriptFetchUiState(status: TranscriptFetchStatus.empty),
          ),
          videoRowForMediaProvider(
            'm1',
          ).overrideWithValue(AsyncValue.data(_youtubeRow('m1'))),
        ],
      );

      container
          .read(practiceTipTriggerProvider)
          .startEmptyTranscriptIfSettled(
            mediaId: 'm1',
            routePath: '/player/m1',
          );

      expect(_ctrlOf(container).emptyTranscriptCtxs.single.isYoutube, isTrue);
    });

    test('an unresolved video row resolves to the local variant', () {
      final container = _container(
        extra: [
          transcriptLinesForMediaProvider(
            'm1',
          ).overrideWithValue(const AsyncValue.data([])),
          transcriptFetchStatusProvider('m1').overrideWithValue(
            const TranscriptFetchUiState(status: TranscriptFetchStatus.idle),
          ),
          videoRowForMediaProvider(
            'm1',
          ).overrideWithValue(const AsyncValue.loading()),
        ],
      );

      container
          .read(practiceTipTriggerProvider)
          .startEmptyTranscriptIfSettled(
            mediaId: 'm1',
            routePath: '/player/m1',
          );

      expect(_ctrlOf(container).emptyTranscriptCtxs.single.isYoutube, isFalse);
    });
  });

  group('startHomeEntries', () {
    test('passes the route through', () {
      final container = _container();

      container
          .read(practiceTipTriggerProvider)
          .startHomeEntries(routePath: '/');

      expect(_ctrlOf(container).homeCtxs.single.routePath, '/');
    });

    test('normalizes an empty route to the root', () {
      final container = _container();

      container
          .read(practiceTipTriggerProvider)
          .startHomeEntries(routePath: '');

      expect(_ctrlOf(container).homeCtxs.single.routePath, '/');
    });
  });

  group('markTranscriptAvailable', () {
    test('forwards to the controller', () {
      final container = _container();

      container
          .read(practiceTipTriggerProvider)
          .markTranscriptAvailable(mediaId: 'm1');

      expect(_ctrlOf(container).transcriptsMarkedAvailable, ['m1']);
    });
  });
}
