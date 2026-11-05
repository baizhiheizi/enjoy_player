/// The wide-screen Subtitles & display popover route (ADR-0093).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/anchored_popover_route.dart';
import 'subtitle_track_picker_sheet.dart';

/// The wide Subtitles & display popover (ADR-0093): a 384px raised card
/// anchored under the top bar's Subtitles button, pushed as a PopupRoute so
/// the player surface parks (ADR-0066).
AnchoredPopoverRoute<void> subtitlesPopoverRoute({required String mediaId}) {
  return AnchoredPopoverRoute<void>(
    barrierLabel: 'Subtitles and display',
    transitionDuration: const Duration(milliseconds: 160),
    reverseTransitionDuration: const Duration(milliseconds: 120),
    insets: (context) =>
        EdgeInsets.only(top: _subtitlesTopInset(context), right: 14),
    builder: (context) {
      final t = EnjoyThemeTokens.of(context);
      final top = _subtitlesTopInset(context);
      return DecoratedBox(
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
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(
              width: 384,
            ).copyWith(maxHeight: MediaQuery.sizeOf(context).height - top - 10),
            child: SubtitleTrackPickerSheet(
              mediaId: mediaId,
              presentation: SubtitleTrackPickerPresentation.dialog,
            ),
          ),
        ),
      );
    },
  );
}

double _subtitlesTopInset(BuildContext context) =>
    EnjoyThemeTokens.of(context).playerTopBarHeight + 10;
