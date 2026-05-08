/// Global keyboard shortcuts (web hotkeys parity).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/domain/hotkey_chord.dart';
import 'package:enjoy_player/features/library/application/library_search_focus_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/application/player_ui_provider.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

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

  bool _primaryFocusIsEditable() {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context;
    if (ctx == null) return false;
    return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _matches(KeyEvent event, HotkeysCtrl ctrl, String actionId) {
    final binding = ctrl.effectiveKeys(actionId);
    if (binding.isEmpty) return false;
    return hotkeyMatchesBinding(event, binding);
  }

  bool _onKey(KeyEvent event) {
    if (!mounted) return false;
    if (event is! KeyDownEvent) return false;
    if (_primaryFocusIsEditable()) return false;

    final ctrl = ref.read(hotkeysCtrlProvider.notifier);

    // Modal: Escape closes nested routes (dialogs, sheets).
    if (_matches(event, ctrl, 'modal.close')) {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
        return true;
      }
    }

    if (_matches(event, ctrl, 'global.help')) {
      unawaited(
        showDialog<void>(
          context: context,
          builder: (ctx) => const HotkeysHelpDialog(),
        ),
      );
      return true;
    }

    if (_matches(event, ctrl, 'global.settings')) {
      context.go('/settings');
      return true;
    }

    if (_matches(event, ctrl, 'global.search')) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.hotkeysStubSearch)),
        );
      }
      _log.fine('global search hotkey (stub)');
      return true;
    }

    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/library') && _matches(event, ctrl, 'library.search')) {
      ref.read(librarySearchFocusNodeProvider).requestFocus();
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
          ref.read(playerUiProvider.notifier).collapse();
          context.pop();
        } else {
          context.push('/player/${session.mediaId}');
        }
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
          ref.read(playerPreferencesCtrlProvider.notifier).setPlaybackRate(next),
        );
        return true;
      }
      if (_matches(event, ctrl, 'player.speedUp')) {
        final rate = ref.read(playerPreferencesCtrlProvider).playbackRate;
        final next = math.min(2.0, rate + 0.05);
        unawaited(
          ref.read(playerPreferencesCtrlProvider.notifier).setPlaybackRate(next),
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
