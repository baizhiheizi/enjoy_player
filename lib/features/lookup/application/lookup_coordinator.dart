/// Opens the transcript dictionary / translation bottom sheet.
library;

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_focus_policy.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/dictionary_lookup_sheet.dart';

part 'lookup_coordinator.g.dart';

final Logger _log = logNamed('lookup');

@Riverpod(keepAlive: true)
class LookupCoordinator extends _$LookupCoordinator {
  @override
  int build() => 0;

  Future<void> open(BuildContext context, LookupRequest request) async {
    if (!context.mounted) return;
    _log.fine('lookup sheet: "${request.selectedText}"');
    final w = MediaQuery.sizeOf(context).width;
    final compact = EnjoyThemeTokens.of(context).breakpointCompact;
    if (w >= compact) {
      // Duet side margin (ADR-0091): a right-edge drawer route — the surface
      // parks (ADR-0066), Esc closes, and it slides in over motionMargin.
      await Navigator.of(
        context,
        rootNavigator: true,
      ).push(_LookupMarginRoute(request: request));
      releasePrimaryFocusForGlobalHotkeys();
      return;
    }

    await showEnjoySheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (sheetContext) => DictionaryLookupSheet(
        presentation: DictionaryLookupPresentation.bottomSheet,
        request: request,
      ),
    );
    releasePrimaryFocusForGlobalHotkeys();
  }
}

/// The right-edge lookup margin drawer (ADR-0091): 380px raised panel over
/// the scrim, sliding from the right edge.
class _LookupMarginRoute extends PopupRoute<void> {
  _LookupMarginRoute({required this.request});

  final LookupRequest request;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => 'Word lookup';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final t = EnjoyThemeTokens.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: t.marginWidth,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: t.raised,
            shape: RoundedSuperellipseBorder(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
            shadows: t.shadowFloat,
          ),
          child: ClipRSuperellipse(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: true,
              child: DictionaryLookupSheet(
                presentation: DictionaryLookupPresentation.dialog,
                request: request,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}
