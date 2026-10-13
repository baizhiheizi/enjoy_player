/// Scrollable transcript with tap-to-seek and echo-aware highlighting.
library;

import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/asr/presentation/asr_generation_launcher.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'package:enjoy_player/features/onboarding/application/practice_tip_trigger.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/settings/application/ipa_overlay_settings.dart';
import 'package:enjoy_player/features/settings/application/karaoke_highlight_settings.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:enjoy_player/features/transcript/application/video_row_for_media_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/dictate_hint_pill.dart';
import 'package:enjoy_player/features/transcript/presentation/import_subtitle_file.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_empty_state.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_embedded_extract.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_scrollable_list.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_typeface_scope.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:go_router/go_router.dart';

class TranscriptPanel extends ConsumerStatefulWidget {
  const TranscriptPanel({required this.mediaId, super.key});

  final String mediaId;

  @override
  ConsumerState<TranscriptPanel> createState() => _TranscriptPanelState();
}

class _TranscriptPanelState extends ConsumerState<TranscriptPanel> {
  String get mediaId => widget.mediaId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTipsIfSettled());
  }

  /// One settled trigger attempt — the query-resolution / fetch-status gates
  /// and the practice context live in [PracticeTipTrigger].
  void _startTipsIfSettled() {
    if (!mounted) return;
    ref
        .read(practiceTipTriggerProvider)
        .startEmptyTranscriptIfSettled(
          mediaId: mediaId,
          routePath: GoRouterState.of(context).uri.path,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(karaokeHighlightSettingsProvider);
    ref.watch(ipaOverlaySettingsProvider);
    final linesAsync = ref.watch(transcriptLinesForMediaProvider(mediaId));
    final fetchState = ref.watch(transcriptFetchStatusProvider(mediaId));

    final videoRowAsync = ref.watch(videoRowForMediaProvider(mediaId));
    final isYoutube = videoRowAsync.maybeWhen(
      data: (row) => row?.provider == 'youtube',
      orElse: () => false,
    );
    final showLocalActions = !isYoutube;
    final dexieTargetType = ref.watch(
      playerControllerProvider.select((s) => s?.dexieTargetType),
    );
    final showExtractButton = dexieTargetType == 'Video' && showLocalActions;

    final signedIn = ref.watch(authIsSignedInProvider);

    ref.listen(transcriptLinesForMediaProvider(mediaId), (prev, next) {
      final lines = next.asData?.value;
      if (lines != null && lines.isNotEmpty) {
        ref
            .read(practiceTipTriggerProvider)
            .markTranscriptAvailable(mediaId: mediaId);
      } else if (lines != null && lines.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _startTipsIfSettled(),
        );
      }
    });

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
                      EnjoyIcons.error,
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
                    EnjoyButton.tonal(
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
            onImport: () => pickAndImportSubtitleFile(context, ref, mediaId),
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
            onFetchYoutube: isYoutube
                ? () => ref
                      .read(transcriptFetchCtrlProvider(mediaId).notifier)
                      .refreshFromCloud(signedIn: signedIn)
                : null,
            showImportButton: showLocalActions,
            showExtractButton: showExtractButton,
            showGenerateButton: showLocalActions,
            showFetchYoutubeButton: isYoutube,
          );
        }
        final list = TranscriptTypefaceScope(
          child: TranscriptScrollableList(mediaId: mediaId, lines: lines),
        );
        if (!ref.watch(transcriptBlurModeProvider)) return list;
        return Stack(
          children: [
            list,
            const Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: IgnorePointer(child: Center(child: DictateHintPill())),
            ),
          ],
        );
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
