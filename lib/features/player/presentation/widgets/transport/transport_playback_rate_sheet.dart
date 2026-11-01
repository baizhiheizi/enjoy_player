/// The dock's playback-rate preset bottom sheet.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_primitives.dart'
    show formatRateCore;
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_playback_rate.dart'
    show kPlaybackRatePresets, playbackRatesEqual;
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Opens the speed-preset sheet; resolves when the sheet closes.
Future<void> showPlaybackRateSheet({
  required BuildContext context,
  required WidgetRef ref,
}) {
  final t = EnjoyThemeTokens.of(context);
  return showEnjoySheet<void>(
    context: context,
    builder: (sheetCtx) {
      final rate = ref.read(
        playerPreferencesCtrlProvider.select((p) => p.playbackRate),
      );
      final l10n = AppLocalizations.of(sheetCtx)!;
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaddedSheetDragHandle(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.space20,
                  t.space4,
                  t.space20,
                  t.space8,
                ),
                child: Text(
                  l10n.speed,
                  style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final option in kPlaybackRatePresets)
                ListTile(
                  title: Text(l10n.playbackRateTimes(formatRateCore(option))),
                  trailing: playbackRatesEqual(option, rate)
                      ? Icon(EnjoyIcons.check, color: t.brandInk)
                      : null,
                  onTap: () {
                    unawaited(
                      ref
                          .read(playerPreferencesCtrlProvider.notifier)
                          .setPlaybackRate(option),
                    );
                    Navigator.pop(sheetCtx);
                  },
                ),
              SizedBox(height: t.space16),
            ],
          ),
        ),
      );
    },
  );
}
