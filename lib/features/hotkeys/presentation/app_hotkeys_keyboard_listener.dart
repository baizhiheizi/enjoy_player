/// Global keyboard shortcuts (web hotkeys parity).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/routing/app_router.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/features/hotkeys/application/escape_dismissal.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_focus_policy.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/player/application/player_collapse.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_chord.dart';
import 'package:enjoy_player/features/library/application/library_search_focus.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
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
  /// Use GoRouter's root key for overlays, dialogs, and imperative pops.
  BuildContext? _routerNavigatorContext() =>
      ref.read(appRouterProvider).configuration.navigatorKey.currentContext;

  bool _onKey(KeyEvent event) {
    if (!mounted) return false;
    if (event is! KeyDownEvent) return false;
    if (primaryFocusBlocksGlobalHotkeys()) return false;

    final ctrl = ref.read(hotkeysCtrlProvider.notifier);
    final goRouter = ref.read(appRouterProvider);
    final navCtx = _routerNavigatorContext();

    // Modal.close (Escape): dismiss transient UI only — never collapse the
    // player route as a fallback (see escape_dismissal.dart).
    if (_matches(event, ctrl, 'modal.close')) {
      final path = goRouter.state.uri.path;
      NavigatorState? leafNav;
      NavigatorState? rootNav;
      if (navCtx != null) {
        leafNav = Navigator.of(navCtx, rootNavigator: false);
        rootNav = Navigator.of(navCtx, rootNavigator: true);
      }
      final action = resolveEscapeDismissal(
        EscapeDismissalContext(
          cheatsheetOpen: hotkeysCheatsheetOpen.value,
          windowFullscreen: ref.read(windowFullscreenProvider),
          isRecordingActive: ref
              .read(shadowReadingHotkeyBusProvider)
              .isRecordingActive,
          leafNavigatorCanPop: leafNav?.canPop() ?? false,
          rootNavigatorCanPop: rootNav?.canPop() ?? false,
          leafAndRootNavIdentical: identical(leafNav, rootNav),
          goRouterCanPop: goRouter.canPop(),
          path: path,
          isDesktop: isDesktop,
        ),
      );
      switch (action) {
        case EscapeDismissalAction.closeCheatsheet:
          if (navCtx != null) {
            unawaited(Navigator.of(navCtx, rootNavigator: true).maybePop());
          }
          return true;
        case EscapeDismissalAction.exitFullscreen:
          unawaited(
            ref.read(windowFullscreenProvider.notifier).setFullscreen(false),
          );
          return true;
        case EscapeDismissalAction.cancelRecording:
          ref
              .read(shadowReadingHotkeyBusProvider.notifier)
              .pulseRecordingCancel();
          return true;
        case EscapeDismissalAction.popNavigatorOverlay:
          if (leafNav?.canPop() ?? false) {
            leafNav!.pop();
          } else if (rootNav?.canPop() ?? false) {
            rootNav!.pop();
          }
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
        unawaited(Navigator.of(navCtx, rootNavigator: true).maybePop());
        return true;
      }
      unawaited(showHotkeysHelpDialog(navCtx));
      return true;
    }

    if (_matches(event, ctrl, 'global.settings')) {
      goRouter.go('/settings');
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
    if (session != null) {
      if (_matches(event, ctrl, 'player.togglePlay')) {
        unawaited(ref.read(playerControllerProvider.notifier).togglePlay());
        return true;
      }

      if (_matches(event, ctrl, 'player.toggleExpand')) {
        final onPlayer = path.startsWith('/player/');
        if (onPlayer) {
          final ctx = navCtx ?? context;
          unawaited(collapseExpandedPlayer(ref, ctx));
        } else {
          openPlayerRoute(context, session.mediaId);
        }
        return true;
      }

      if (_matches(event, ctrl, 'player.toggleFullscreen') &&
          isDesktop &&
          session.mediaType == 'video') {
        unawaited(ref.read(windowFullscreenProvider.notifier).toggle());
        return true;
      }

      if (_matches(event, ctrl, 'player.prevLine')) {
        unawaited(ref.read(playerInteractionsProvider.notifier).prevLine());
        return true;
      }
      if (_matches(event, ctrl, 'player.nextLine')) {
        unawaited(ref.read(playerInteractionsProvider.notifier).nextLine());
        return true;
      }
      if (_matches(event, ctrl, 'player.replayLine')) {
        unawaited(ref.read(playerInteractionsProvider.notifier).replayLine());
        return true;
      }
      if (_matches(event, ctrl, 'player.toggleEchoMode')) {
        unawaited(ref.read(playerInteractionsProvider.notifier).toggleEcho());
        return true;
      }
      if (_matches(event, ctrl, 'player.toggleDictationMode')) {
        _log.fine('dictation hotkey (not implemented)');
        return true;
      }
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

      if (_matches(event, ctrl, 'player.slowDown')) {
        final rate = ref.read(playerPreferencesCtrlProvider).playbackRate;
        final next = math.max(0.25, rate - 0.05);
        unawaited(
          ref
              .read(playerPreferencesCtrlProvider.notifier)
              .setPlaybackRate(next),
        );
        return true;
      }
      if (_matches(event, ctrl, 'player.speedUp')) {
        final rate = ref.read(playerPreferencesCtrlProvider).playbackRate;
        final next = math.min(2.0, rate + 0.05);
        unawaited(
          ref
              .read(playerPreferencesCtrlProvider.notifier)
              .setPlaybackRate(next),
        );
        return true;
      }

      if (_matches(event, ctrl, 'player.expandEchoBackward')) {
        unawaited(
          ref.read(playerInteractionsProvider.notifier).expandEchoBackward(),
        );
        return true;
      }
      if (_matches(event, ctrl, 'player.expandEchoForward')) {
        unawaited(
          ref.read(playerInteractionsProvider.notifier).expandEchoForward(),
        );
        return true;
      }
      if (_matches(event, ctrl, 'player.shrinkEchoBackward')) {
        unawaited(
          ref.read(playerInteractionsProvider.notifier).shrinkEchoBackward(),
        );
        return true;
      }
      if (_matches(event, ctrl, 'player.shrinkEchoForward')) {
        unawaited(
          ref.read(playerInteractionsProvider.notifier).shrinkEchoForward(),
        );
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
