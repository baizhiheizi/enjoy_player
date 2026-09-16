/// Global keyboard shortcuts (web hotkeys parity).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/routing/app_router.dart';
import 'package:enjoy_player/features/hotkeys/application/escape_dismissal.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_commands.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_focus_policy.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/application/shadow_reading_hotkey_policy.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_chord.dart';
import 'package:enjoy_player/features/library/application/library_search_focus.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_review_practice.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'hotkeys_cheatsheet_open.dart';
import 'hotkeys_help_dialog.dart';

final _log = logNamed('AppHotkeys');

class AppHotkeysKeyboardListener extends ConsumerStatefulWidget {
  const AppHotkeysKeyboardListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppHotkeysKeyboardListener> createState() =>
      _AppHotkeysKeyboardListenerState();
}

class _AppHotkeysKeyboardListenerState
    extends ConsumerState<AppHotkeysKeyboardListener> {
  late final bool Function(KeyEvent event) _handler = _onKey;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handler);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handler);
    super.dispose();
  }

  bool _matches(KeyEvent event, HotkeysCtrl ctrl, String actionId) {
    final binding = ctrl.effectiveKeys(actionId);
    if (binding.isEmpty) return false;
    return hotkeyMatchesBinding(event, binding);
  }

  /// [AppHotkeysKeyboardListener] is built in [MaterialApp.router]'s `builder`
  /// above the [Navigator], so [context] here does not include a [Navigator].
  /// Prefer [GlobalKey.currentState] / [GlobalKey.currentContext] on the
  /// router keys — not [Navigator.of] on the key's context (that walks
  /// ancestors and misses the keyed navigator itself).
  BuildContext? _routerNavigatorContext() =>
      ref.read(appRouterProvider).configuration.navigatorKey.currentContext;

  NavigatorState? _rootNavigatorState() =>
      ref.read(appRouterProvider).configuration.navigatorKey.currentState;

  NavigatorState? _shellNavigatorState() => enjoyShellNavigatorKey.currentState;

  bool _onKey(KeyEvent event) {
    if (!mounted) return false;
    if (event is! KeyDownEvent) return false;
    if (primaryFocusBlocksGlobalHotkeys()) return false;

    final ctrl = ref.read(hotkeysCtrlProvider.notifier);
    final goRouter = ref.read(appRouterProvider);
    final navCtx = _routerNavigatorContext();
    final shellNav = _shellNavigatorState();
    final rootNav = _rootNavigatorState();

    // Modal.close (Escape): dismiss transient UI only — never collapse the
    // player route as a fallback (see escape_dismissal.dart).
    if (_matches(event, ctrl, 'modal.close')) {
      final path = goRouter.state.uri.path;
      final action = resolveEscapeDismissal(
        EscapeDismissalContext(
          cheatsheetOpen: hotkeysCheatsheetOpen.value,
          windowFullscreen: ref.read(windowFullscreenProvider),
          isRecordingActive:
              ref.read(shadowReadingHotkeyBusProvider).isRecordingActive ||
              ref.read(craftControllerProvider).isCapturing,
          shellHasPopupRoute: navigatorHasTopPopupRoute(shellNav),
          rootHasPopupRoute: navigatorHasTopPopupRoute(rootNav),
          vocabularyPracticeOpen: ref
              .read(vocabularyReviewSessionProvider)
              .practiceSheetOpen,
          goRouterCanPop: goRouter.canPop(),
          path: path,
          isDesktop: isDesktop,
        ),
      );
      switch (action) {
        case EscapeDismissalAction.closeCheatsheet:
          if (rootNav != null) unawaited(rootNav.maybePop());
          return true;
        case EscapeDismissalAction.exitFullscreen:
          unawaited(
            ref.read(windowFullscreenProvider.notifier).setFullscreen(false),
          );
          return true;
        case EscapeDismissalAction.cancelRecording:
          if (ref.read(craftControllerProvider).isCapturing) {
            ref.read(craftControllerProvider.notifier).cancelCapture();
          }
          if (ref.read(shadowReadingHotkeyBusProvider).isRecordingActive) {
            ref
                .read(shadowReadingHotkeyBusProvider.notifier)
                .pulseRecordingCancel();
          }
          return true;
        case EscapeDismissalAction.popShellPopup:
          if (shellNav != null) unawaited(shellNav.maybePop());
          return true;
        case EscapeDismissalAction.popRootPopup:
          if (rootNav != null) unawaited(rootNav.maybePop());
          return true;
        case EscapeDismissalAction.clearVocabularyPractice:
          unawaited(
            ref.read(vocabularyReviewSessionProvider.notifier).clearPractice(),
          );
          return true;
        case EscapeDismissalAction.popGoRouter:
          goRouter.pop();
          return true;
        case EscapeDismissalAction.noopOnPlayer:
          return true;
        case null:
          break;
      }
    }

    if (_matches(event, ctrl, 'global.help')) {
      if (navCtx == null) return false;
      if (hotkeysCheatsheetOpen.value) {
        if (rootNav != null) unawaited(rootNav.maybePop());
        return true;
      }
      unawaited(showHotkeysHelpDialog(navCtx));
      return true;
    }

    if (_matches(event, ctrl, 'global.settings')) {
      goRouter.go('/settings');
      return true;
    }

    if (_matches(event, ctrl, 'global.craft')) {
      final craftPath = goRouter.state.uri.path;
      if (craftPath == '/craft' || craftPath.startsWith('/craft/')) {
        return true;
      }
      goRouter.go('/craft');
      return true;
    }

    if (_matches(event, ctrl, 'global.search')) {
      if (navCtx != null) {
        final l10n = AppLocalizations.of(navCtx);
        if (l10n != null) {
          AppNotice.info(navCtx, l10n.hotkeysStubSearch);
        }
      }
      _log.fine('global search hotkey (stub)');
      return true;
    }

    final path = goRouter.state.uri.path;
    if (librarySearchHotkeyEnabledForPath(path) &&
        _matches(event, ctrl, 'library.search')) {
      requestLibrarySearchFocus(ref);
      return true;
    }

    final session = ref.read(playerControllerProvider);
    final vocabularyEchoPracticeOpen =
        ref.read(vocabularyReviewSessionProvider).practiceMode ==
        ReviewPracticeMode.echo;
    // Vocabulary echo practice is recorder-only (no player session), but still
    // mounts ShadowReadingPanel which listens on the shared hotkey bus.
    if (shadowReadingBusHotkeysEnabled(
      hasPlayerSession: session != null,
      vocabularyEchoPracticeOpen: vocabularyEchoPracticeOpen,
    )) {
      if (_matches(event, ctrl, 'player.toggleRecording')) {
        ref.read(shadowReadingHotkeyBusProvider.notifier).pulseRecording();
        return true;
      }
      if (_matches(event, ctrl, 'player.playRecording')) {
        ref.read(shadowReadingHotkeyBusProvider.notifier).pulsePlayback();
        return true;
      }
      if (_matches(event, ctrl, 'player.togglePitchContour')) {
        ref.read(shadowReadingHotkeyBusProvider.notifier).pulsePitchContour();
        return true;
      }
      if (_matches(event, ctrl, 'player.toggleAssessment')) {
        ref.read(shadowReadingHotkeyBusProvider.notifier).pulseAssessment();
        return true;
      }
    }

    // Session-gated player keys route through the command registry
    // (issue #719); each command's gate absorbs the old `session != null`
    // and platform / media-type checks. This call sits at the session
    // block's old chain position, so the registry's order and the remaining
    // if-chain stay one total order.
    if (dispatchHotkey(
      event: event,
      ctrl: ctrl,
      ctx: HotkeyCtx(read: ref.read, listenerContext: context),
    )) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
