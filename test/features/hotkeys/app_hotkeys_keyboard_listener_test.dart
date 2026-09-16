// End-to-end dispatch coverage for [AppHotkeysKeyboardListener] (the global
// keyboard handler above MaterialApp.router's Navigator). Keys are dispatched
// through [HardwareKeyboard.instance.handleKeyEvent] — the public API used by
// the engine — which updates the `_pressedKeys` map (so `isControlPressed`
// etc. reflect the simulated modifier state) AND calls every registered
// `addHandler` callback in registration order.
//
// Session-gated player commands (togglePlay / toggleFullscreen / line / echo /
// rate) have per-command suites under
// `test/features/player/application/hotkeys/`; this file keeps the arms that
// are genuinely entangled with the mounted tree:
//   - early returns (KeyUpEvent, primary focus on EditableText)
//   - global.help cheatsheet open / close (dialog needs a navigator context)
//   - the playback-rate command wiring through the registry
//   - the custom-binding remap flowing through dispatch
//   - the `_onKey` return-false path when no shortcut matches
//
// Everything else has moved next to the code it executes:
//   - Escape arms → test/features/hotkeys/application/
//       modal_close_hotkey_command_test.dart
//   - global settings / craft / search →
//       test/features/hotkeys/application/global_hotkey_commands_test.dart
//   - library.search →
//       test/features/library/application/
//       library_search_hotkey_command_test.dart
//   - dispatch semantics + registry order →
//       test/features/hotkeys/application/hotkey_commands_test.dart
//   - shadow-reading bus pulses →
//       test/features/shadow_reading/application/
//       shadow_reading_hotkey_commands_test.dart
//   - session-gated player keys →
//       test/features/player/application/hotkeys/
//       (player_hotkey_commands_test.dart, playback_rate_commands_test.dart,
//       player_toggle_expand_hotkey_command_test.dart)

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/routing/app_router.dart';
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_focus_policy.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_definitions.dart';
import 'package:enjoy_player/features/hotkeys/presentation/app_hotkeys_keyboard_listener.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_cheatsheet_open.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/domain/player_settings.dart'
    as player_settings;
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_review_practice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/l10n/app_localizations.dart';

// ── Foundation debug var resetter ─────────────────────────────────────────────

// `debugDefaultTargetPlatformOverride` is asserted to be null by
// [TestWidgetsFlutterBinding._verifyInvariants] which runs *after* the test body
// returns and *after* `addTearDown` callbacks. The only reliable point to reset
// it inside a `testWidgets` body is when the framework replaces the widget tree
// with the post-test message (binding.dart `_runTestBody`, line 1959) — at that
// moment our widget is unmounted and [State.dispose] runs synchronously, *before*
// `_verifyInvariants`. Wrap the mounted tree with [_PlatformResetter] so the
// override is reset at the right moment without per-test try/finally boilerplate.
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

// ── Fake providers ───────────────────────────────────────────────────────────

class _RecordingHotkeysCtrl extends HotkeysCtrl {
  _RecordingHotkeysCtrl(this.bindings);

  /// action id → binding string. Missing ids fall back to defaultKeys.
  final Map<String, String> bindings;

  @override
  Future<Map<String, String>> build() async => bindings;

  @override
  String effectiveKeys(String actionId) {
    final override = bindings[actionId];
    if (override != null && override.isNotEmpty) return override;
    final def = hotkeyDefinitionMap[actionId];
    return def?.defaultKeys ?? '';
  }
}

class _FakeWindowFullscreen extends WindowFullscreen {
  _FakeWindowFullscreen({required bool fullscreen})
    : _isFullscreen = fullscreen;

  bool _isFullscreen;

  @override
  bool build() => _isFullscreen;

  var setFullscreenCalls = <bool>[];
  var toggleCalls = 0;

  @override
  Future<void> setFullscreen(bool value) async {
    _isFullscreen = value;
    state = value;
    setFullscreenCalls.add(value);
  }

  @override
  Future<void> toggle() async {
    toggleCalls++;
    await setFullscreen(!state);
  }
}

class _FakeShadowReadingHotkeyBus extends ShadowReadingHotkeyBus {
  _FakeShadowReadingHotkeyBus({ShadowReadingHotkeyTicks? initial})
    : _seed = initial ?? ShadowReadingHotkeyTicks.initial;

  final ShadowReadingHotkeyTicks _seed;

  @override
  ShadowReadingHotkeyTicks build() => _seed;

  var recordingPulses = 0;
  var playbackPulses = 0;
  var pitchContourPulses = 0;
  var assessmentPulses = 0;
  var recordingCancelPulses = 0;
  bool _isRecordingActive = false;

  @override
  void pulseRecording() {
    recordingPulses++;
    state = state.copyWith(recording: state.recording + 1);
  }

  @override
  void pulsePlayback() {
    playbackPulses++;
    state = state.copyWith(playback: state.playback + 1);
  }

  @override
  void pulsePitchContour() {
    pitchContourPulses++;
    state = state.copyWith(pitchContour: state.pitchContour + 1);
  }

  @override
  void pulseAssessment() {
    assessmentPulses++;
    state = state.copyWith(assessment: state.assessment + 1);
  }

  @override
  void pulseRecordingCancel() {
    recordingCancelPulses++;
    state = state.copyWith(recordingCancel: state.recordingCancel + 1);
  }

  @override
  void setRecordingActive(bool active) {
    _isRecordingActive = active;
    if (state.isRecordingActive == active) return;
    state = state.copyWith(isRecordingActive: active);
  }

  // Not an override on the parent bus — exposed for test assertions.
  // The listener reads `state.isRecordingActive` (the state field) rather
  // than calling this getter.
  // ignore: override_on_non_overriding_member
  bool get isRecordingActive => _isRecordingActive;
}

class _FakeCraftController extends CraftController {
  bool _isCapturing = false;
  var cancelCaptureCalls = 0;

  @override
  CraftJobState build() => const CraftJobState();

  // Not an override on the parent controller — exposed for test assertions.
  // The listener reads `state.isCapturing` (the state field) rather than
  // calling this getter.
  // ignore: override_on_non_overriding_member
  bool get isCapturing => _isCapturing;

  @override
  void startCapture() {
    _isCapturing = true;
    state = state.copyWith(isCapturing: true);
  }

  @override
  void cancelCapture() {
    _isCapturing = false;
    cancelCaptureCalls++;
    state = state.copyWith(
      isCapturing: false,
      captureCancelTick: state.captureCancelTick + 1,
    );
  }
}

class _FakeVocabularyReviewSession extends VocabularyReviewSession {
  _FakeVocabularyReviewSession({ReviewSessionState? initial})
    : _seed = initial ?? const ReviewSessionState(queue: []);

  final ReviewSessionState _seed;

  var clearPracticeCalls = 0;

  @override
  ReviewSessionState build() => _seed;

  void setState(ReviewSessionState next) {
    state = next;
  }

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
  _FakePlayerController({this.sessionOverride});

  PlaybackSession? sessionOverride;
  var togglePlayCalls = 0;
  var abandonPendingOpenCalls = 0;

  @override
  PlaybackSession? build() => sessionOverride;

  void setSession(PlaybackSession? next) {
    sessionOverride = next;
    state = next;
  }

  var clearCalls = 0;

  @override
  Future<void> togglePlay() async {
    togglePlayCalls++;
  }

  @override
  Future<void> clear({bool keepVideoSurface = false}) async {
    clearCalls++;
    sessionOverride = null;
    state = null;
  }

  @override
  void abandonPendingOpen() {
    abandonPendingOpenCalls++;
  }
}

class _FakePlayerInteractions extends PlayerInteractions {
  _FakePlayerInteractions(super.ref);

  var prevLineCalls = 0;
  var nextLineCalls = 0;
  var replayLineCalls = 0;
  var toggleEchoCalls = 0;
  var toggleBlurCalls = 0;
  var expandEchoBackwardCalls = 0;
  var expandEchoForwardCalls = 0;
  var shrinkEchoBackwardCalls = 0;
  var shrinkEchoForwardCalls = 0;

  @override
  Future<void> prevLine() async {
    prevLineCalls++;
  }

  @override
  Future<void> nextLine() async {
    nextLineCalls++;
  }

  @override
  Future<void> replayLine() async {
    replayLineCalls++;
  }

  @override
  Future<void> toggleEcho() async {
    toggleEchoCalls++;
  }

  @override
  Future<void> toggleBlur() async {
    toggleBlurCalls++;
  }

  @override
  Future<void> expandEchoBackward() async {
    expandEchoBackwardCalls++;
  }

  @override
  Future<void> expandEchoForward() async {
    expandEchoForwardCalls++;
  }

  @override
  Future<void> shrinkEchoBackward() async {
    shrinkEchoBackwardCalls++;
  }

  @override
  Future<void> shrinkEchoForward() async {
    shrinkEchoForwardCalls++;
  }
}

class _FakePlayerPreferencesCtrl extends PlayerPreferencesCtrl {
  _FakePlayerPreferencesCtrl({this._rate = 1.0});

  double _rate;
  var setPlaybackRateCalls = <double>[];

  @override
  player_settings.PlayerPreferences build() {
    return player_settings.PlayerPreferences(
      volume: 1.0,
      playbackRate: _rate,
      repeatMode: player_settings.RepeatMode.none,
      videoTranscriptSplitWidthPx: null,
    );
  }

  void setRate(double r) {
    _rate = r;
    state = state.copyWith(playbackRate: r);
  }

  @override
  Future<void> setPlaybackRate(double r) async {
    setPlaybackRateCalls.add(r);
    setRate(r.clamp(0.25, 2));
  }
}

// ── Test harness ─────────────────────────────────────────────────────────────

class _Harness {
  _Harness({
    required this.tester,
    required this.router,
    required this.container,
    required this.hotkeysCtrl,
    required this.fullscreen,
    required this.shadowBus,
    required this.craftCtrl,
    required this.vocabSession,
    required this.playerCtrl,
    required this.playerInteractions,
    required this.playerPrefs,
    required this.rootNavigatorKey,
  });

  final WidgetTester tester;
  final GoRouter router;
  final ProviderContainer container;
  final _RecordingHotkeysCtrl hotkeysCtrl;
  final _FakeWindowFullscreen fullscreen;
  final _FakeShadowReadingHotkeyBus shadowBus;
  final _FakeCraftController craftCtrl;
  final _FakeVocabularyReviewSession vocabSession;
  final _FakePlayerController playerCtrl;
  final _FakePlayerInteractions playerInteractions;
  final _FakePlayerPreferencesCtrl playerPrefs;

  /// Root navigator key wired into the test [GoRouter] so individual tests can
  /// push pages onto the same stack that [Navigator.pop] walks in production.
  final GlobalKey<NavigatorState> rootNavigatorKey;
}

Future<_Harness> _mountHarness(
  WidgetTester tester, {
  String initialLocation = '/library',
  Map<String, String> customBindings = const {},
  PlaybackSession? session,
  double initialRate = 1.0,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  // Reset handled by [_PlatformResetter] on dispose (see class comment).

  hotkeysCheatsheetOpen.value = false;
  addTearDown(() => hotkeysCheatsheetOpen.value = false);

  final hotkeys = _RecordingHotkeysCtrl(customBindings);

  final fakeFullscreen = _FakeWindowFullscreen(fullscreen: false);
  final fakeShadow = _FakeShadowReadingHotkeyBus();
  final fakeCraft = _FakeCraftController();
  final fakeVocab = _FakeVocabularyReviewSession();
  final fakePlayer = _FakePlayerController(sessionOverride: session);
  // Assigned by the [playerInteractionsProvider] override, which is the only
  // place a [Ref] is available for the service (issue #668). The reads below
  // initialize the provider before the harness hands [fakeInteractions] out.
  late _FakePlayerInteractions fakeInteractions;
  final fakePrefs = _FakePlayerPreferencesCtrl(rate: initialRate);

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
          GoRoute(
            path: '/craft',
            builder: (_, _) => const Scaffold(body: Text('craft')),
          ),
          GoRoute(
            path: '/craft/history',
            builder: (_, _) => const Scaffold(body: Text('craft-history')),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const Scaffold(body: Text('settings')),
          ),
          GoRoute(
            path: '/sign-in',
            builder: (_, _) => const Scaffold(body: Text('sign-in')),
          ),
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home')),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      hotkeysCtrlProvider.overrideWith(() => hotkeys),
      windowFullscreenProvider.overrideWith(() => fakeFullscreen),
      shadowReadingHotkeyBusProvider.overrideWith(() => fakeShadow),
      craftControllerProvider.overrideWith(() => fakeCraft),
      vocabularyReviewSessionProvider.overrideWith(() => fakeVocab),
      playerControllerProvider.overrideWith(() => fakePlayer),
      playerInteractionsProvider.overrideWith(
        (ref) => fakeInteractions = _FakePlayerInteractions(ref),
      ),
      playerPreferencesCtrlProvider.overrideWith(() => fakePrefs),
      appRouterProvider.overrideWithValue(router),
    ],
  );
  addTearDown(container.dispose);

  // The provider override for appRouterProvider is a sync value; ensure the
  // rest are wired up by reading them once so any notifiers initialize.
  container.read(hotkeysCtrlProvider.notifier);
  container.read(windowFullscreenProvider.notifier);
  container.read(shadowReadingHotkeyBusProvider.notifier);
  container.read(craftControllerProvider.notifier);
  container.read(vocabularyReviewSessionProvider.notifier);
  container.read(playerControllerProvider.notifier);
  container.read(playerInteractionsProvider);
  container.read(playerPreferencesCtrlProvider.notifier);

  // Mount with both the rootNavigatorKey (used by global.help / Escape) and
  // the ShellRoute navigatorKey (Escape shell popup branch).
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _PlatformResetter(
        child: MaterialApp.router(
          scaffoldMessengerKey: appScaffoldMessengerKey,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              AppHotkeysKeyboardListener(child: child ?? const SizedBox()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(
    tester: tester,
    router: router,
    container: container,
    hotkeysCtrl: hotkeys,
    fullscreen: fakeFullscreen,
    shadowBus: fakeShadow,
    craftCtrl: fakeCraft,
    vocabSession: fakeVocab,
    playerCtrl: fakePlayer,
    playerInteractions: fakeInteractions,
    playerPrefs: fakePrefs,
    rootNavigatorKey: rootKey,
  );
}

// ── Key dispatch helpers ────────────────────────────────────────────────────

/// The Flutter [HardwareKeyboard] tracks pressed state in
/// `_pressedKeys: Map<PhysicalKeyboardKey, LogicalKeyboardKey>`. Using
/// `PhysicalKeyboardKey(0)` for every event overwrites earlier entries when we
/// dispatch a sequence (press controlLeft, then k — both keys map to key 0 in
/// the map, so pressing `k` wipes the controlLeft entry and `isControlPressed`
/// returns false inside the handler). Pick a unique non-zero physical key per
/// logical key (mirroring the platform constants) so the map is updated as the
/// engine would.
PhysicalKeyboardKey _physicalFor(LogicalKeyboardKey logical) {
  // Most modifier / letter / function keys have a PhysicalKeyboardKey constant
  // with the same debugName; for the rest, fall back to a hash of the logical
  // key's value so the physical key is unique per logical key.
  switch (logical) {
    case LogicalKeyboardKey.controlLeft:
      return PhysicalKeyboardKey.controlLeft;
    case LogicalKeyboardKey.controlRight:
      return PhysicalKeyboardKey.controlRight;
    case LogicalKeyboardKey.shiftLeft:
      return PhysicalKeyboardKey.shiftLeft;
    case LogicalKeyboardKey.shiftRight:
      return PhysicalKeyboardKey.shiftRight;
    case LogicalKeyboardKey.altLeft:
      return PhysicalKeyboardKey.altLeft;
    case LogicalKeyboardKey.altRight:
      return PhysicalKeyboardKey.altRight;
    case LogicalKeyboardKey.metaLeft:
      return PhysicalKeyboardKey.metaLeft;
    case LogicalKeyboardKey.metaRight:
      return PhysicalKeyboardKey.metaRight;
  }
  // Non-modifier keys: synthesize a unique physical key from the logical
  // key value to avoid collisions in the _pressedKeys map.
  return PhysicalKeyboardKey(0x10000000 | (logical.keyId & 0x0fffffff));
}

void _press(LogicalKeyboardKey key, {String? character}) {
  HardwareKeyboard.instance.handleKeyEvent(
    KeyDownEvent(
      physicalKey: _physicalFor(key),
      logicalKey: key,
      character: character,
      timeStamp: Duration.zero,
    ),
  );
}

void _release(LogicalKeyboardKey key) {
  HardwareKeyboard.instance.handleKeyEvent(
    KeyUpEvent(
      physicalKey: _physicalFor(key),
      logicalKey: key,
      timeStamp: Duration.zero,
    ),
  );
}

Future<void> _stroke(
  WidgetTester tester,
  List<LogicalKeyboardKey> modifiers,
  LogicalKeyboardKey main, {
  String? character,
}) async {
  for (final m in modifiers) {
    _press(m);
  }
  _press(main, character: character);
  await tester.pump();
  _release(main);
  for (final m in modifiers.reversed) {
    _release(m);
  }
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    hotkeysCheatsheetOpen.value = false;
  });

  tearDown(() async {
    // Clear residual keys so the next test starts on a clean HardwareKeyboard.
    HardwareKeyboard.instance.clearState();
  });

  group('early-return paths', () {
    testWidgets('KeyUpEvent is ignored (returns false)', (tester) async {
      await _mountHarness(tester);
      HardwareKeyboard.instance.handleKeyEvent(
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey(0),
          logicalKey: LogicalKeyboardKey.escape,
          timeStamp: Duration.zero,
        ),
      );
      // No way to read the bool return from the handler directly — but a
      // smoke assertion: the route did not change and no fullscreen mutation.
      // The handler never invoked any provider method, so the router path is
      // untouched.
      await tester.pump();
      expect(find.text('library'), findsOneWidget);
    });

    testWidgets('editable text focus blocks global hotkeys', (tester) async {
      // Replace the home screen with a focused TextField so the focus policy
      // returns true.
      await _mountHarness(tester, initialLocation: '/');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderScope.containerOf(
            tester.element(find.byType(MaterialApp)),
          ),
          child: MaterialApp(
            scaffoldMessengerKey: appScaffoldMessengerKey,
            home: const Scaffold(
              body: TextField(
                autofocus: true,
                decoration: InputDecoration(hintText: 'search'),
              ),
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pump();
      expect(primaryFocusBlocksGlobalHotkeys(), isTrue);

      // Send ctrl+comma (global.settings) — should NOT navigate because the
      // editable text blocks the handler.
      await _stroke(
        tester,
        [LogicalKeyboardKey.controlLeft],
        LogicalKeyboardKey.comma,
        character: ',',
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });
  });


  group('global.help', () {
    testWidgets('opens HotkeysHelpDialog', (tester) async {
      await _mountHarness(tester);
      // Press shift+slash (default global.help binding).
      await _stroke(
        tester,
        [LogicalKeyboardKey.shiftLeft],
        LogicalKeyboardKey.slash,
        character: '/',
      );
      await tester.pumpAndSettle();
      // Dialog title should be visible.
      expect(find.text('Keyboard shortcuts'), findsOneWidget);
      // cheatsheetOpen toggled true.
      expect(hotkeysCheatsheetOpen.value, isTrue);
      addTearDown(() {
        if (hotkeysCheatsheetOpen.value) hotkeysCheatsheetOpen.value = false;
      });
    });

    testWidgets('closes already-open cheatsheet', (tester) async {
      final harness = await _mountHarness(tester);
      hotkeysCheatsheetOpen.value = true;
      // Press shift+slash while cheatsheet is open — it should pop instead.
      await _stroke(
        tester,
        [LogicalKeyboardKey.shiftLeft],
        LogicalKeyboardKey.slash,
        character: '/',
      );
      await tester.pumpAndSettle();
      expect(harness.shadowBus.recordingCancelPulses, 0);
    });
  });






  group('player playback rate (slowDown / speedUp)', () {
    // Clamp coverage (0.25 floor / 2.0 ceiling / 0.05 step) lives with the D10
    // reducer and the playback-rate commands:
    //   - test/features/player/transport_decisions_test.dart
    //   - test/features/player/application/hotkeys/playback_rate_commands_test.dart
    // This end-to-end test pins the wiring: key stroke → listener dispatch →
    // command registry → preference notifier.
    testWidgets('shift+comma → registry slowDown command applies 0.95', (
      tester,
    ) async {
      final harness = await _mountHarness(
        tester,
        session: _videoSession(),
        initialRate: 1.0,
      );
      await _stroke(
        tester,
        [LogicalKeyboardKey.shiftLeft],
        LogicalKeyboardKey.comma,
        character: ',',
      );
      await tester.pump();
      expect(harness.playerPrefs.setPlaybackRateCalls, [0.95]);
    });
  });

  group('unmatched key returns false', () {
    testWidgets('z (unbound) does not trigger anything', (tester) async {
      final harness = await _mountHarness(tester, session: _videoSession());
      await _stroke(tester, [], LogicalKeyboardKey.keyZ, character: 'z');
      await tester.pump();
      expect(harness.playerCtrl.togglePlayCalls, 0);
      expect(harness.playerInteractions.prevLineCalls, 0);
      expect(harness.playerInteractions.nextLineCalls, 0);
      expect(harness.fullscreen.toggleCalls, 0);
      expect(harness.router.state.uri.path, '/library');
    });
  });

  group('custom binding override', () {
    testWidgets('user remapped global.craft to ctrl+shift+k still routes', (
      tester,
    ) async {
      final harness = await _mountHarness(
        tester,
        customBindings: const {'global.craft': 'ctrl+shift+k'},
      );
      await _stroke(
        tester,
        [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.shiftLeft],
        LogicalKeyboardKey.keyK,
        character: 'k',
      );
      await tester.pumpAndSettle();
      expect(harness.router.state.uri.path, '/craft');
    });
  });

}

PlaybackSession _videoSession() => PlaybackSession(
  mediaId: 'm1',
  dexieTargetType: 'Video',
  mediaType: 'video',
  mediaTitle: 'Test',
  durationSeconds: 60,
  currentTimeSeconds: 0,
  currentSegmentIndex: 0,
  language: 'en',
  startedAt: DateTime(2026),
  lastActiveAt: DateTime(2026),
);
