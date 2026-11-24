import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_auto_scroll_controller.dart';

const _mediaId = 'm1';
const _lineCount = 200;
const _itemExtent = 40.0;
const _viewportHeight = 400.0;
const _maxScrollExtent = _lineCount * _itemExtent - _viewportHeight;

double _estimateFor(int line, double alignment) =>
    ((line / _lineCount) * _maxScrollExtent -
            alignment * _viewportHeight * kTranscriptScrollEstimateFactor)
        .clamp(0.0, _maxScrollExtent);

final _cueProvider = NotifierProvider<_CueNotifier, int>(_CueNotifier.new);

class _CueNotifier extends Notifier<int> {
  @override
  int build() => 8;

  void set(int value) => state = value;
}

class _MutableEchoMode extends EchoMode {}

class _Harness extends ConsumerStatefulWidget {
  const _Harness({required super.key});

  @override
  ConsumerState<_Harness> createState() => _HarnessState();
}

class _HarnessState extends ConsumerState<_Harness> {
  late final TranscriptAutoScrollController autoScroll =
      TranscriptAutoScrollController(
        isMounted: () => mounted,
        ref: () => ref,
        context: () => context,
        mediaId: () => _mediaId,
        lineCount: () => _lineCount,
      );

  @override
  void dispose() {
    autoScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(playerIsPlayingProvider);
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 300,
        height: _viewportHeight,
        child: NotificationListener<ScrollNotification>(
          onNotification: autoScroll.handleScrollNotification,
          child: ListView.builder(
            controller: autoScroll.scrollController,
            itemExtent: _itemExtent,
            itemCount: _lineCount,
            itemBuilder: (context, index) => Text('line $index'),
          ),
        ),
      ),
    );
  }
}

void _dispatchUserScroll(
  WidgetTester tester,
  _HarnessState state,
  ScrollDirection direction,
) {
  final controller = state.autoScroll.scrollController;
  final context = tester.element(find.byType(ListView));
  context.dispatchNotification(
    UserScrollNotification(
      metrics: controller.position,
      context: context,
      direction: direction,
    ),
  );
}

Future<(_HarnessState, _MutableEchoMode, ProviderContainer)> _pumpHarness(
  WidgetTester tester, {
  bool playing = true,
}) async {
  final echoCtrl = _MutableEchoMode();
  late ProviderContainer container;
  final key = GlobalKey<_HarnessState>();
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerIsPlayingProvider.overrideWith((ref) => Stream.value(playing)),
        echoModeProvider.overrideWith(() => echoCtrl),
        transcriptPlaybackHighlightProvider(_mediaId).overrideWith(
          (ref) => (cueIndex: ref.watch(_cueProvider), wordIndex: null),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          extensions: [EnjoyThemeTokens.build(scheme)],
        ),
        home: Scaffold(body: _Harness(key: key)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  container = ProviderScope.containerOf(tester.element(find.byType(_Harness)));
  return (key.currentState!, echoCtrl, container);
}

Future<void> _pumpScrollFrame(WidgetTester tester) async {
  tester.binding.scheduleFrame();
  await tester.pump();
}

void main() {
  testWidgets('scheduleScrollIntoView does nothing while playback is paused', (
    tester,
  ) async {
    final (state, _, _) = await _pumpHarness(tester, playing: false);
    state.autoScroll.scheduleScrollIntoView(force: true);
    await tester.pump();
    expect(state.autoScroll.scrollController.offset, 0);
  });

  testWidgets('follows the active cue once and re-follows on cue change', (
    tester,
  ) async {
    final (state, _, container) = await _pumpHarness(tester);
    state.autoScroll.scheduleScrollIntoView();
    await _pumpScrollFrame(tester);
    expect(
      state.autoScroll.scrollController.offset,
      closeTo(_estimateFor(8, kTranscriptScrollAlignment), 0.5),
    );

    state.autoScroll.scrollController.jumpTo(2000);
    state.autoScroll.scheduleScrollIntoView();
    await _pumpScrollFrame(tester);
    expect(state.autoScroll.scrollController.offset, 2000);

    container.read(_cueProvider.notifier).set(20);
    state.autoScroll.scheduleScrollIntoView();
    await _pumpScrollFrame(tester);
    expect(
      state.autoScroll.scrollController.offset,
      closeTo(_estimateFor(20, kTranscriptScrollAlignment), 0.5),
    );
  });

  testWidgets('force re-follows the same cue after scrolling away', (
    tester,
  ) async {
    final (state, _, _) = await _pumpHarness(tester);
    state.autoScroll.scheduleScrollIntoView();
    await _pumpScrollFrame(tester);

    state.autoScroll.scrollController.jumpTo(2000);
    state.autoScroll.scheduleScrollIntoView(force: true);
    await _pumpScrollFrame(tester);
    expect(
      state.autoScroll.scrollController.offset,
      closeTo(_estimateFor(8, kTranscriptScrollAlignment), 0.5),
    );
  });

  testWidgets('user scroll suppresses forced follow until resume', (
    tester,
  ) async {
    final (state, _, _) = await _pumpHarness(tester);
    state.autoScroll.scheduleScrollIntoView();
    await _pumpScrollFrame(tester);

    _dispatchUserScroll(tester, state, ScrollDirection.forward);
    state.autoScroll.scrollController.jumpTo(3000);
    state.autoScroll.scheduleScrollIntoView(force: true);
    await _pumpScrollFrame(tester);
    expect(state.autoScroll.scrollController.offset, 3000);

    state.autoScroll.resumeAutoFollow();
    state.autoScroll.scheduleScrollIntoView(force: true);
    await _pumpScrollFrame(tester);
    expect(
      state.autoScroll.scrollController.offset,
      closeTo(_estimateFor(8, kTranscriptScrollAlignment), 0.5),
    );
  });

  testWidgets('idle user scroll re-arms follow when the cue is off-screen', (
    tester,
  ) async {
    final (state, _, _) = await _pumpHarness(tester);
    state.autoScroll.scheduleScrollIntoView();
    await _pumpScrollFrame(tester);

    _dispatchUserScroll(tester, state, ScrollDirection.forward);
    state.autoScroll.scrollController.jumpTo(3000);
    _dispatchUserScroll(tester, state, ScrollDirection.idle);
    await _pumpScrollFrame(tester);

    state.autoScroll.scheduleScrollIntoView(force: true);
    await _pumpScrollFrame(tester);
    expect(
      state.autoScroll.scrollController.offset,
      closeTo(_estimateFor(8, kTranscriptScrollAlignment), 0.5),
    );
  });

  testWidgets('scroll-target keys rotate on index or bounds change and reset', (
    tester,
  ) async {
    final (state, _, _) = await _pumpHarness(tester);
    final lineKey = state.autoScroll.scrollKeyForActiveLine(5);
    expect(
      identical(state.autoScroll.scrollKeyForActiveLine(5), lineKey),
      isTrue,
    );
    expect(
      identical(state.autoScroll.scrollKeyForActiveLine(6), lineKey),
      isFalse,
    );

    const echoA = EchoState(
      active: true,
      startLineIndex: 10,
      endLineIndex: 14,
      startTimeSeconds: 10,
      endTimeSeconds: 14,
    );
    const echoB = EchoState(
      active: true,
      startLineIndex: 20,
      endLineIndex: 24,
      startTimeSeconds: 20,
      endTimeSeconds: 24,
    );
    final echoKey = state.autoScroll.scrollKeyForEcho(echoA);
    expect(
      identical(state.autoScroll.scrollKeyForEcho(echoA), echoKey),
      isTrue,
    );
    expect(
      identical(state.autoScroll.scrollKeyForEcho(echoB), echoKey),
      isFalse,
    );

    state.autoScroll.resetForMediaChange();
    expect(
      identical(state.autoScroll.scrollKeyForActiveLine(5), lineKey),
      isFalse,
    );
    expect(
      identical(state.autoScroll.scrollKeyForEcho(echoA), echoKey),
      isFalse,
    );
  });

  testWidgets('echo follow deduplicates per bounds and re-follows on change', (
    tester,
  ) async {
    final (state, echoCtrl, container) = await _pumpHarness(tester);
    container.read(echoModeProvider.notifier);
    echoCtrl.activate(
      startLineIndex: 10,
      endLineIndex: 14,
      startTimeSeconds: 10,
      endTimeSeconds: 14,
    );
    state.autoScroll.scheduleScrollIntoView();
    await _pumpScrollFrame(tester);
    expect(
      state.autoScroll.scrollController.offset,
      closeTo(_estimateFor(10, 0), 0.5),
    );

    state.autoScroll.scrollController.jumpTo(0);
    state.autoScroll.scheduleScrollIntoView();
    await _pumpScrollFrame(tester);
    expect(state.autoScroll.scrollController.offset, 0);

    echoCtrl.activate(
      startLineIndex: 20,
      endLineIndex: 24,
      startTimeSeconds: 20,
      endTimeSeconds: 24,
    );
    state.autoScroll.scheduleScrollIntoView();
    await _pumpScrollFrame(tester);
    expect(
      state.autoScroll.scrollController.offset,
      closeTo(_estimateFor(20, 0), 0.5),
    );
  });

  testWidgets('dispose drops a pending scheduled scroll', (tester) async {
    final (state, _, _) = await _pumpHarness(tester);
    state.autoScroll.scheduleScrollIntoView();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
