/// `modal.close` (Escape) hotkey command (issue #719) — the execution arms of
/// the pure escape policy.
library;

import 'dart:async';

import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/hotkeys/application/escape_dismissal.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_cheatsheet_open.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';

/// Escape: dismiss transient UI only — never collapse the player route as a
/// fallback. Priority resolution stays pure in [resolveEscapeDismissal]
/// (`escape_dismissal.dart`); this command gathers the state into the context
/// and applies the chosen arm. Registered first — the highest-priority
/// command in the registry.
class ModalCloseHotkeyCommand extends HotkeyCommand {
  const ModalCloseHotkeyCommand();

  @override
  String get actionId => 'modal.close';

  /// Whether any dismissal arm applies. `null` from the policy means nothing
  /// to dismiss — dispatch then falls through to the lower-priority commands.
  @override
  bool canExecute(HotkeyCtx ctx) => _resolve(ctx) != null;

  @override
  void execute(HotkeyCtx ctx) {
    switch (_resolve(ctx)!) {
      case EscapeDismissalAction.closeCheatsheet:
        final rootNav = ctx.rootNavigatorState;
        if (rootNav != null) unawaited(rootNav.maybePop());
      case EscapeDismissalAction.exitFullscreen:
        unawaited(
          ctx.read(windowFullscreenProvider.notifier).setFullscreen(false),
        );
      case EscapeDismissalAction.cancelRecording:
        if (ctx.read(craftControllerProvider).isCapturing) {
          ctx.read(craftControllerProvider.notifier).cancelCapture();
        }
        if (ctx.read(shadowReadingHotkeyBusProvider).isRecordingActive) {
          ctx
              .read(shadowReadingHotkeyBusProvider.notifier)
              .pulseRecordingCancel();
        }
      case EscapeDismissalAction.popShellPopup:
        final shellNav = ctx.shellNavigatorState;
        if (shellNav != null) unawaited(shellNav.maybePop());
      case EscapeDismissalAction.popRootPopup:
        final rootNav = ctx.rootNavigatorState;
        if (rootNav != null) unawaited(rootNav.maybePop());
      case EscapeDismissalAction.clearVocabularyPractice:
        unawaited(
          ctx.read(vocabularyReviewSessionProvider.notifier).clearPractice(),
        );
      case EscapeDismissalAction.popGoRouter:
        ctx.router.pop();
      case EscapeDismissalAction.noopOnPlayer:
        break;
    }
  }

  EscapeDismissalAction? _resolve(HotkeyCtx ctx) {
    return resolveEscapeDismissal(
      EscapeDismissalContext(
        cheatsheetOpen: hotkeysCheatsheetOpen.value,
        windowFullscreen: ctx.read(windowFullscreenProvider),
        isRecordingActive:
            ctx.read(shadowReadingHotkeyBusProvider).isRecordingActive ||
            ctx.read(craftControllerProvider).isCapturing,
        shellHasPopupRoute: navigatorHasTopPopupRoute(ctx.shellNavigatorState),
        rootHasPopupRoute: navigatorHasTopPopupRoute(ctx.rootNavigatorState),
        vocabularyPracticeOpen: ctx
            .read(vocabularyReviewSessionProvider)
            .practiceSheetOpen,
        goRouterCanPop: ctx.router.canPop(),
        path: ctx.path,
        isDesktop: isDesktop,
      ),
    );
  }
}
