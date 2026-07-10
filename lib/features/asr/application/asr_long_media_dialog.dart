/// Pre-flight confirmation dialog for ASR generation on long media
/// (FR-008 / QR-008). Surfaces expected duration in minutes and warns
/// about credit consumption. Returns `true` when the learner chooses
/// to continue, `false` or `null` otherwise.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const int _kLongMediaThresholdSeconds = 30 * 60;

Future<bool?> showAsrLongMediaConfirmDialog(
  BuildContext context, {
  required int mediaDurationSeconds,
}) {
  // Only show for media that crosses the threshold.
  if (mediaDurationSeconds < _kLongMediaThresholdSeconds) {
    return Future.value(true);
  }
  final minutes = (mediaDurationSeconds / 60).round();
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      final t = EnjoyThemeTokens.of(ctx);
      return AlertDialog(
        title: Text(l10n.asrLongMediaConfirmTitle),
        content: Text(l10n.asrLongMediaConfirmBody(minutes)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.asrLongMediaConfirmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: t.space8),
              child: Text(l10n.asrLongMediaConfirmContinue),
            ),
          ),
        ],
      );
    },
  );
}
