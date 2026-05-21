import 'package:enjoy_player/features/hotkeys/application/escape_dismissal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveEscapeDismissal', () {
    const base = EscapeDismissalContext(
      cheatsheetOpen: false,
      windowFullscreen: false,
      isRecordingActive: false,
      leafNavigatorCanPop: false,
      rootNavigatorCanPop: false,
      leafAndRootNavIdentical: true,
      goRouterCanPop: true,
      path: '/player/media-1',
      isDesktop: true,
    );

    test('cheatsheet open closes cheatsheet first', () {
      expect(
        resolveEscapeDismissal(base.copyWith(cheatsheetOpen: true)),
        EscapeDismissalAction.closeCheatsheet,
      );
    });

    test('fullscreen exits before overlays on desktop', () {
      expect(
        resolveEscapeDismissal(base.copyWith(windowFullscreen: true)),
        EscapeDismissalAction.exitFullscreen,
      );
    });

    test('active recording cancels before route navigation', () {
      expect(
        resolveEscapeDismissal(base.copyWith(isRecordingActive: true)),
        EscapeDismissalAction.cancelRecording,
      );
    });

    test('navigator overlay pops without collapsing player route', () {
      expect(
        resolveEscapeDismissal(
          base.copyWith(leafNavigatorCanPop: true, goRouterCanPop: true),
        ),
        EscapeDismissalAction.popNavigatorOverlay,
      );
    });

    test('idle player route is a no-op', () {
      expect(resolveEscapeDismissal(base), EscapeDismissalAction.noopOnPlayer);
    });

    test('non-player route pops GoRouter when no overlay', () {
      expect(
        resolveEscapeDismissal(
          base.copyWith(path: '/library', goRouterCanPop: true),
        ),
        EscapeDismissalAction.popGoRouter,
      );
    });

    test('returns null when nothing applies on non-player route', () {
      expect(
        resolveEscapeDismissal(
          base.copyWith(path: '/library', goRouterCanPop: false),
        ),
        isNull,
      );
    });
  });
}

extension on EscapeDismissalContext {
  EscapeDismissalContext copyWith({
    bool? cheatsheetOpen,
    bool? windowFullscreen,
    bool? isRecordingActive,
    bool? leafNavigatorCanPop,
    bool? rootNavigatorCanPop,
    bool? leafAndRootNavIdentical,
    bool? goRouterCanPop,
    String? path,
    bool? isDesktop,
  }) {
    return EscapeDismissalContext(
      cheatsheetOpen: cheatsheetOpen ?? this.cheatsheetOpen,
      windowFullscreen: windowFullscreen ?? this.windowFullscreen,
      isRecordingActive: isRecordingActive ?? this.isRecordingActive,
      leafNavigatorCanPop: leafNavigatorCanPop ?? this.leafNavigatorCanPop,
      rootNavigatorCanPop: rootNavigatorCanPop ?? this.rootNavigatorCanPop,
      leafAndRootNavIdentical:
          leafAndRootNavIdentical ?? this.leafAndRootNavIdentical,
      goRouterCanPop: goRouterCanPop ?? this.goRouterCanPop,
      path: path ?? this.path,
      isDesktop: isDesktop ?? this.isDesktop,
    );
  }
}
