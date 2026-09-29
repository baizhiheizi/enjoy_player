/// Shared UI entry point for local-file ASR generation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/media_registry_provider.dart';
import 'package:enjoy_player/data/db/media_target_resolver.dart';
import 'package:enjoy_player/features/asr/application/asr_failure_messages.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_controller.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_job.dart';
import 'package:enjoy_player/features/asr/application/asr_long_media_dialog.dart';
import 'package:enjoy_player/features/asr/data/asr_audio_extractor.dart';
import 'package:enjoy_player/features/library/domain/media.dart'
    as library_media;
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';
import 'package:enjoy_player/features/transcript/presentation/import_subtitle_language_dialog.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Starts ASR only for a local library file and surfaces the terminal outcome.
Future<void> launchAsrGeneration(
  BuildContext context,
  WidgetRef ref, {
  required String mediaId,
}) async {
  final db = ref.read(appDatabaseProvider);
  final media = await ref.read(mediaRegistryProvider).getById(mediaId);
  final source = await resolvePlayableSource(db, mediaId);
  if (media == null || source is! LocalFilePlayableSource) {
    if (context.mounted) {
      AppNotice.error(
        context,
        asrMessageForKey(
          AppLocalizations.of(context)!,
          'asrErrorUnsupportedSource',
        ),
      );
    }
    return;
  }

  final kind = media.kind == library_media.MediaKind.video
      ? MediaKind.video
      : MediaKind.audio;
  final storedLanguage = media.language;
  if (!context.mounted) return;
  final language = await showAsrLanguageDialog(
    context,
    initialLanguage: storedLanguage,
  );
  if (language == null) return;
  if (!context.mounted) return;
  final refreshed = await ref.read(mediaRegistryProvider).getById(mediaId);
  if (refreshed == null) {
    if (context.mounted) {
      AppNotice.error(
        context,
        asrMessageForKey(
          AppLocalizations.of(context)!,
          'asrErrorUnsupportedSource',
        ),
      );
    }
    return;
  }
  final durationSeconds = refreshed.durationMs ~/ 1000;
  if (!context.mounted) return;
  final confirmed = await showAsrLongMediaConfirmDialog(
    context,
    mediaDurationSeconds: durationSeconds,
  );
  if (confirmed != true) return;

  await ref
      .read(asrGenerationControllerProvider(mediaId).notifier)
      .generateTranscript(
        mediaSourceUri: source.uri,
        kind: kind,
        language: language.language,
        autoDetect: language.language == null,
      );
  if (!context.mounted) return;

  final job = ref.read(asrGenerationControllerProvider(mediaId)).valueOrNull;
  if (job?.phase == AsrGenerationPhase.success) {
    AppNotice.success(
      context,
      asrMessageForKey(AppLocalizations.of(context)!, 'asrStatusSuccess'),
    );
  } else if (job?.phase == AsrGenerationPhase.error) {
    final l10n = AppLocalizations.of(context)!;
    final failure = job!.creditsFailure;
    final router = GoRouter.of(context);
    AppNotice.error(
      context,
      failure != null && failure.requiredCredits != null
          ? creditsFailureMessage(failure, l10n)
          : asrMessageForKey(l10n, job.errorMessage),
      action: failure == null
          ? null
          : (
              label: creditsCtaLabel(l10n),
              onPressed: () => router.push('/subscription'),
            ),
    );
  }
}
