/// Scrollable transcript with tap-to-seek and echo-aware highlighting.
library;

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import '../../../data/subtitle/transcript_line.dart';
import '../../../l10n/app_localizations.dart';
import '../../player/application/display_position_provider.dart';
import '../../player/application/echo_mode_provider.dart';
import '../../player/application/player_interactions.dart';
import '../application/active_transcript_provider.dart';
import '../application/all_transcripts_provider.dart';
import '../application/transcript_lines_provider.dart';
import '../application/transcript_repository_provider.dart';
import 'subtitle_track_picker_sheet.dart';

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

    await ref
        .read(transcriptRepositoryProvider)
        .importSubtitle(mediaId: mediaId, file: XFile(path));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.importSubtitleSuccess),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final linesAsync = ref.watch(transcriptLinesForMediaProvider(mediaId));
    final tracksAsync = ref.watch(allTranscriptsForMediaProvider(mediaId));
    final activeIdAsync = ref.watch(activeTranscriptIdProvider(mediaId));

    final tracks = tracksAsync.value ?? [];
    final activeId = activeIdAsync.value;
    final activeTrack = tracks.where((t) => t.id == activeId).firstOrNull;
    final activeLabel =
        (activeTrack?.label.isNotEmpty == true) ? activeTrack!.label : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(t.space8, t.space8, t.space8, t.space4),
          child: Row(
            children: [
              // Active track chip — tap to open picker
              if (tracks.isNotEmpty)
                ActionChip(
                  avatar: const Icon(Icons.closed_caption_outlined, size: 16),
                  label: Text(
                    activeLabel ?? l10n.subtitles,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed:
                      () => showSubtitleTrackPicker(context, ref, mediaId),
                )
              else
                Text(
                  l10n.transcript,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _import(context, ref),
                icon: const Icon(Icons.upload_file),
                label: Text(l10n.importSubtitle),
              ),
            ],
          ),
        ),
        Expanded(
          child: linesAsync.when(
            data: (lines) {
              if (lines.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(t.space24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.noTranscript,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noTranscriptHint,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: t.space16),
                        FilledButton.icon(
                          onPressed: () => _import(context, ref),
                          icon: const Icon(Icons.upload_file),
                          label: Text(l10n.importSubtitle),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return _TranscriptBody(mediaId: mediaId, lines: lines);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('${l10n.error}: $e')),
          ),
        ),
      ],
    );
  }
}

class _TranscriptBody extends ConsumerWidget {
  const _TranscriptBody({required this.mediaId, required this.lines});

  final String mediaId;
  final List<TranscriptLine> lines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final echo = ref.watch(echoModeProvider);
    final posAsync = ref.watch(displayPositionProvider);
    final tok = EnjoyThemeTokens.of(context);
    final secondaryAsync = ref.watch(
      secondaryTranscriptLinesForMediaProvider(mediaId),
    );
    final secondaryLines = secondaryAsync.value ?? <TranscriptLine>[];

    final timeSec = switch (posAsync) {
      AsyncData(:final value) => value.inMilliseconds / 1000.0,
      _ => 0.0,
    };
    final active = _activeIndex(lines, timeSec);

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: tok.space12, vertical: tok.space8),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        final isActive = index == active;
        final inEcho =
            echo.active &&
            index >= echo.startLineIndex &&
            index <= echo.endLineIndex;
        final bg =
            inEcho
                ? tok.echoActive.withValues(alpha: 0.22)
                : isActive
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : null;

        final secondaryText = _matchSecondary(line, secondaryLines)?.text;

        return Padding(
          padding: EdgeInsets.only(bottom: tok.space8),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(tok.radiusSm),
            child: InkWell(
              borderRadius: BorderRadius.circular(tok.radiusSm),
              onTap:
                  () => ref
                      .read(playerInteractionsProvider.notifier)
                      .seekToLine(line, index),
              child: Padding(
                padding: tok.transcriptLinePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (secondaryText != null) ...[
                      SizedBox(height: tok.space4),
                      Text(
                        secondaryText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _activeIndex(List<TranscriptLine> lines, double t) {
    for (var i = 0; i < lines.length; i++) {
      if (t >= lines[i].startSeconds && t < lines[i].endSeconds) return i;
    }
    for (var i = lines.length - 1; i >= 0; i--) {
      if (t >= lines[i].startSeconds) return i;
    }
    return -1;
  }

  /// Returns the secondary line whose midpoint falls within [primary]'s range,
  /// or the nearest secondary line if none overlaps.
  TranscriptLine? _matchSecondary(
    TranscriptLine primary,
    List<TranscriptLine> secondary,
  ) {
    if (secondary.isEmpty) return null;
    final pStart = primary.startSeconds;
    final pEnd = primary.endSeconds;

    // 1. Prefer a line whose midpoint is inside the primary range.
    for (final s in secondary) {
      final mid = s.startSeconds + (s.endSeconds - s.startSeconds) / 2;
      if (mid >= pStart && mid < pEnd) return s;
    }

    // 2. Fall back to the last secondary line that started before primary ends.
    TranscriptLine? best;
    for (final s in secondary) {
      if (s.startSeconds < pEnd) best = s;
    }
    return best;
  }
}
