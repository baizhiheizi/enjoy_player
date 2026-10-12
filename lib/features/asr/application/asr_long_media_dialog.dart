/// Pre-flight confirmation dialog for ASR generation on long media
/// (FR-008 / QR-008). Surfaces expected duration in minutes and warns
/// about credit consumption. Returns `true` when the learner chooses
/// to continue, `false` or `null` otherwise.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_constants.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Future<bool?> showAsrLongMediaConfirmDialog(
  BuildContext context, {
  required int mediaDurationSeconds,
}) {
  if (mediaDurationSeconds < kLongFormMinDurationSeconds) {
    return Future.value(true);
  }
  final minutes = (mediaDurationSeconds / 60).round();
  final l10n = AppLocalizations.of(context)!;
  return showEnjoyConfirmDialog(
    context: context,
    title: l10n.asrLongMediaConfirmTitle,
    message: l10n.asrLongMediaConfirmBody(minutes),
    confirmLabel: l10n.asrLongMediaConfirmContinue,
    cancelLabel: l10n.asrLongMediaConfirmCancel,
  );
}
