// Per-command tests for the Escape (`modal.close`) command (issue #719).
//
// The dismissal PRIORITY ladder is pure and unit-tested in
// `escape_dismissal_test.dart`; these tests pin the command's execution arms
// against a mounted router + real provider state (navigator pops, fullscreen
// exit, capture cancel, bus pulse, practice clear), and the fall-through when
// nothing applies.
import 'dart:async';

import 'package:enjoy_player/core/routing/app_router.dart';
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_cheatsheet_open.dart';
import 'package:enjoy_player/features/hotkeys/application/modal_close_hotkey_command.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/domain/player_settings.dart'
    as player_settings;
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_review_practice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeWindowFullscreen extends WindowFullscreen {
  _FakeWindowFullscreen({required bool fullscreen})
    : _isFullscreen = fullscreen;

  bool _isFullscreen;
  var setFullscreenCalls = <bool>[];

  @override
  bool build() => _isFullscreen;

  @override
  Future<void> setFullscreen(bool value) async {
    _isFullscreen = value;
    state = value;
    setFullscreenCalls.add(value);
  }
}

class _FakeShadowReadingHotkeyBus extends ShadowReadingHotkeyBus {
  var recordingCancelPulses = 0;

  @override
  ShadowReadingHotkeyTicks build() => ShadowReadingHotkeyTicks.initial;

  @override
  void pulseRecordingCancel() {
    recordingCancelPulses++;
    state = state.copyWith(recordingCancel: state.recordingCancel + 1);
  }

  @override
  void setRecordingActive(bool active) {
    if (state.isRecordingActive == active) return;
    state = state.copyWith(isRecordingActive: active);
  }
}

class _FakeCraftController extends CraftController {
  var cancelCaptureCalls = 0;

  @override
  CraftJobState build() => const CraftJobState();

  @override
  void cancelCapture() {
    cancelCaptureCalls++;
    state = state.copyWith(
      isCapturing: false,
      captureCancelTick: state.captureCancelTick + 1,
    );
  }

  @override
  void startCapture() {
    state = state.copyWith(isCapturing: true);
  }

  bool get isCapturing => state.isCapturing;
}

class _FakeVocabularyReviewSession extends VocabularyReviewSession {
  _FakeVocabularyReviewSession({ReviewSessionState? initial})
    : _seed = initial ?? const ReviewSessionState(queue: []);

  final ReviewSessionState _seed;

  var clearPracticeCalls = 0;

  @override
  ReviewSessionState build() => _seed;

  @override
  Future<void> clearPractice() async {
    clearPracticeCalls++;
    final s = state;
    if (s.practicePhase == ReviewPracticePhase.none) return;
    state = s.copyWith(
      practicePhase: ReviewPracticePhase.none,
      clearMediaError: true,
    );
  }
}

class _FakePlayerController extends PlayerController {
  @override
  PlaybackSession? build() => null;
}

class _FakePlayerInteractions extends PlayerInteractions {
  _FakePlayerInteractions(super.ref);
}

class _FakePlayerPreferencesCtrl extends PlayerPreferencesCtrl {
  @override
  player_settings.PlayerPreferences build() =>
      player_settings.PlayerPreferences.defaults;
}

/// Resets `debugDefaultTargetPlatformOverride` at the right moment
/// (see [PlatformResetter in the listener suite] — when the framework
/// replaces the widget tree with the post-test message).
class _PlatformResetter extends StatefulWidget {
  const _PlatformResetter({required this.child});

  final Widget child;

  @override
  State<_PlatformResetter> createState() => _PlatformResetterState();
}

class _PlatformResetterState extends State<_PlatformResetter> {
  @override
  void dispose() {
    debugDefaultTargetPlatformOverride = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _EscapeHotkeysCtrl extends HotkeysCtrl {
  @override
  Future<Map<String, String>> build() async => const {};

  @override
  String effectiveKeys(String actionId) => actionId == 'modal.close'
      ? hotkeyDefinitionMap['modal.close']!.defaultKeys
      : '';
}

Future<
  ({
    ProviderContainer container,
    _FakeShadowReadingHotkeyBus shadowBus,
    _FakeCraftController craftCtrl,
    _FakeVocabularyReviewSession vocabSession,
    _FakeWindowFullscreen fullscreen,
  })
>
_mountHarness(
  WidgetTester tester, {
  String initialLocation = '/library',
  bool fullscreen = false,
  ReviewSessionState? vocabState,
}) async {
  hotkeysCheatsheetOpen.value = false;
  addTearDown(() => hotkeysCheatsheetOpen.value = false);

  debugDefaultTargetPlatformOverride = TargetPlatform.windows;

  final fakeFullscreen = _FakeWindowFullscreen(fullscreen: fullscreen);
  final fakeShadow = _FakeShadowReadingHotkeyBus();
  final fakeCraft = _FakeCraftController();
  final fakeVocab = _FakeVocabularyReviewSession(initial: vocabState);

  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'test-root');
  late GoRouter router;
  router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        navigatorKey: enjoyShellNavigatorKey,
        builder: (context, state, child) => Scaffold(body: child),
        routes: [
          GoRoute(
            path: '/library',
            builder: (_, _) => const Scaffold(body: Text('library')),
          ),
          GoRoute(
            path: '/player/:mediaId',
            builder: (_, _) => const Scaffold(body: Text('player')),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      hotkeysCtrlProvider.overrideWith(() => _EscapeHotkeysCtrl()),
      windowFullscreenProvider.overrideWith(() => fakeFullscreen),
      shadowReadingHotkeyBusProvider.overrideWith(() => fakeShadow),
      craftControllerProvider.overrideWith(() => fakeCraft),
      vocabularyReviewSessionProvider.overrideWith(() => fakeVocab),
      playerControllerProvider.overrideWith(() => _FakePlayerController()),
      playerInteractionsProvider.overrideWith(
        (ref) => _FakePlayerInteractions(ref),
      ),
      playerPreferencesCtrlProvider.overrideWith(
        () => _FakePlayerPreferencesCtrl(),
      ),
      appRouterProvider.overrideWithValue(router),
    ],
  );
  addTearDown(container.dispose);

  // Warm up every override so the listeners can read `state` synchronously
  // inside `_resolve` and the dispatch arms.
  container.read(hotkeysCtrlProvider.notifier);
  container.read(windowFullscreenProvider.notifier);
  container.read(shadowReadingHotkeyBusProvider.notifier);
  container.read(craftControllerProvider.notifier);
  container.read(vocabularyReviewSessionProvider.notifier);
  container.read(playerControllerProvider.notifier);
  container.read(playerInteractionsProvider);
  container.read(playerPreferencesCtrlProvider.notifier);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _PlatformResetter(child: MaterialApp.router(routerConfig: router)),
    ),
  );
  await tester.pumpAndSettle();

  return (
    container: container,
    shadowBus: fakeShadow,
    craftCtrl: fakeCraft,
    vocabSession: fakeVocab,
    fullscreen: fakeFullscreen,
  );
}

void main() {
  testWidgets('nothing to dismiss → canExecute false (key falls through)', (
    tester,
  ) async {
    final h = await _mountHarness(tester);
    final ctx = HotkeyCtx(read: h.container.read, listenerContext: null);
    expect(const ModalCloseHotkeyCommand().canExecute(ctx), isFalse);
  });

  testWidgets('cheatsheet open → closeCheatsheet pops root navigator', (
    tester,
  ) async {
    final h = await _mountHarness(tester);
    hotkeysCheatsheetOpen.value = true;
    const ModalCloseHotkeyCommand().execute(
      HotkeyCtx(read: h.container.read, listenerContext: null),
    );
    await tester.pump();
    expect(h.shadowBus.recordingCancelPulses, 0);
    expect(h.fullscreen.setFullscreenCalls, isEmpty);
  });

  testWidgets('fullscreen on desktop → exitFullscreen', (tester) async {
    final h = await _mountHarness(tester, fullscreen: true);
    expect(h.fullscreen.state, isTrue);
    const ModalCloseHotkeyCommand().execute(
      HotkeyCtx(read: h.container.read, listenerContext: null),
    );
    await tester.pumpAndSettle();
    expect(h.fullscreen.setFullscreenCalls, contains(false));
  });

  testWidgets('craft recording active → cancelCapture', (tester) async {
    final h = await _mountHarness(tester);
    h.craftCtrl.startCapture();
    expect(h.craftCtrl.isCapturing, isTrue);
    const ModalCloseHotkeyCommand().execute(
      HotkeyCtx(read: h.container.read, listenerContext: null),
    );
    await tester.pump();
    expect(h.craftCtrl.cancelCaptureCalls, 1);
  });

  testWidgets('shadow-reading recording active → pulseRecordingCancel', (
    tester,
  ) async {
    final h = await _mountHarness(tester);
    h.container
        .read(shadowReadingHotkeyBusProvider.notifier)
        .setRecordingActive(true);
    const ModalCloseHotkeyCommand().execute(
      HotkeyCtx(read: h.container.read, listenerContext: null),
    );
    await tester.pump();
    expect(h.shadowBus.recordingCancelPulses, 1);
  });

  testWidgets('shell popup → popShellPopup', (tester) async {
    final h = await _mountHarness(tester);
    final shellState = enjoyShellNavigatorKey.currentState;
    expect(shellState, isNotNull);
    unawaited(
      shellState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('pushed-page')),
          fullscreenDialog: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('pushed-page'), findsOneWidget);

    const ModalCloseHotkeyCommand().execute(
      HotkeyCtx(read: h.container.read, listenerContext: null),
    );
    await tester.pumpAndSettle();
    expect(find.text('pushed-page'), findsNothing);
    expect(find.text('library'), findsOneWidget);
    expect(h.shadowBus.recordingCancelPulses, 0);
  });

  testWidgets(
    'idle player route → noopOnPlayer (command still claims the key)',
    (tester) async {
      final h = await _mountHarness(tester, initialLocation: '/player/abc');
      expect(find.text('player'), findsOneWidget);
      final ctx = HotkeyCtx(read: h.container.read, listenerContext: null);
      final command = const ModalCloseHotkeyCommand();
      expect(command.canExecute(ctx), isTrue);
      command.execute(ctx);
      await tester.pumpAndSettle();
      expect(find.text('player'), findsOneWidget);
      expect(h.fullscreen.setFullscreenCalls, isEmpty);
    },
  );

  testWidgets('vocabulary practice open → clearPractice', (tester) async {
    final h = await _mountHarness(
      tester,
      vocabState: const ReviewSessionState(
        queue: [],
        practicePhase: ReviewPracticePhase.clipOpening,
      ),
    );
    const ModalCloseHotkeyCommand().execute(
      HotkeyCtx(read: h.container.read, listenerContext: null),
    );
    await tester.pumpAndSettle();
    expect(h.vocabSession.clearPracticeCalls, 1);
  });
}
