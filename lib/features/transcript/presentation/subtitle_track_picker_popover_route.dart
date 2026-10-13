/// The wide-screen Subtitles & display popover route (ADR-0093).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'subtitle_track_picker_sheet.dart';

/// The wide Subtitles & display popover (ADR-0093): a 384px raised card
/// anchored under the top bar's Subtitles button, pushed as a PopupRoute so
/// the player surface parks (ADR-0066).
class SubtitlesPopoverRoute extends PopupRoute<void> {
  SubtitlesPopoverRoute({required this.mediaId});

  final String mediaId;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => 'Subtitles and display';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 160);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final t = EnjoyThemeTokens.of(context);
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 66, right: 14),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: t.raised,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: t.line),
            ),
            shadows: t.shadowFloat,
          ),
          child: ClipRSuperellipse(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 384,
              height: double.infinity,
              child: SubtitleTrackPickerSheet(
                mediaId: mediaId,
                presentation: SubtitleTrackPickerPresentation.dialog,
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
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}
