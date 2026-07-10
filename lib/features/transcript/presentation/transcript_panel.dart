/// Scrollable transcript with tap-to-seek and echo-aware highlighting.
library;

import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/asr/presentation/asr_generation_launcher.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:enjoy_player/features/transcript/application/video_row_for_media_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/import_subtitle_language_dialog.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_empty_state.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_embedded_extract.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_scrollable_list.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';

class TranscriptPanel extends ConsumerWidget {
  const TranscriptPanel({required this.mediaId, super.key});

  final String mediaId;

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final pick = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['srt', 'vtt'],
    );
    if (pick == null || pick.files.isEmpty) return;
    final f = pick.files.single;
    final path = f.path;
    if (path == null) return;
    if (!context.mounted) return;

    final hint = languageHintFromSubtitleFileName(f.name);
    final lang = await showImportSubtitleLanguageDialog(
      context,
      initialLanguage: hint,
    );
    if (lang == null) return;
    final trimmed = lang.trim();
    if (trimmed.isEmpty) return;

    await ref
        .read(transcriptRepositoryProvider)
        .importSubtitle(mediaId: mediaId, file: XFile(path), language: trimmed);
    if (context.mounted) {
      AppNotice.success(
        context,
        AppLocalizations.of(context)!.importSubtitleSuccess,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final linesAsync = ref.watch(transcriptLinesForMediaProvider(mediaId));
    final fetchState = ref.watch(transcriptFetchStatusProvider(mediaId));

    final videoRowAsync = ref.watch(videoRowForMediaProvider(mediaId));
    final isYoutube = videoRowAsync.maybeWhen(
      data: (row) => row?.provider == 'youtube',
      orElse: () => false,
    );
    final showLocalActions = !isYoutube;
    final session = ref.watch(playerControllerProvider);
    final showExtractButton =
        session != null &&
        session.dexieTargetType == 'Video' &&
        showLocalActions;

    final signedIn = ref.watch(authCtrlProvider).valueOrNull is AuthSignedIn;

    // Layout parents size this panel; Expanded here is invalid under DecoratedBox.
    return linesAsync.when(
      data: (lines) {
        if (lines.isEmpty) {
          if (fetchState.status == TranscriptFetchStatus.loading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.transcriptFetchingSubtitles,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          if (fetchState.status == TranscriptFetchStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.transcriptErrorFriendlyTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.transcriptErrorFriendlyHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => ref
                          .read(transcriptFetchCtrlProvider(mediaId).notifier)
                          .refreshFromCloud(signedIn: signedIn),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          return TranscriptEmptyState(
            onImport: () => _import(context, ref),
            onExtract: showExtractButton
                ? () => runEmbeddedSubtitleExtract(
                    context: context,
                    ref: ref,
                    mediaId: mediaId,
                  )
                : null,
            onGenerate: showLocalActions
                ? () => launchAsrGeneration(context, ref, mediaId: mediaId)
                : null,
            showImportButton: showLocalActions,
            showExtractButton: showExtractButton,
            showGenerateButton: showLocalActions,
          );
        }
        return TranscriptScrollableList(mediaId: mediaId, lines: lines);
      },
      loading: () => const SkeletonTranscript(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.transcriptErrorFriendlyTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.transcriptErrorFriendlyHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
