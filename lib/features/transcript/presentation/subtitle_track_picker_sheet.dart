/// Bottom sheet for selecting primary + secondary subtitle tracks.
// ignore_for_file: deprecated_member_use
library;

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/active_transcript_provider.dart';
import '../application/all_transcripts_provider.dart';
import '../application/transcript_repository_provider.dart';
import '../domain/transcript_track.dart';

/// Shows a modal bottom sheet for picking primary + secondary subtitles.
Future<void> showSubtitleTrackPicker(
  BuildContext context,
  WidgetRef ref,
  String mediaId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(EnjoyThemeTokens.of(context).radiusLg),
      ),
    ),
    builder: (_) => SubtitleTrackPickerSheet(mediaId: mediaId),
  );
}

class SubtitleTrackPickerSheet extends ConsumerStatefulWidget {
  const SubtitleTrackPickerSheet({required this.mediaId, super.key});

  final String mediaId;

  @override
  ConsumerState<SubtitleTrackPickerSheet> createState() =>
      _SubtitleTrackPickerSheetState();
}

class _SubtitleTrackPickerSheetState
    extends ConsumerState<SubtitleTrackPickerSheet> {
  bool _importing = false;

  Future<void> _importFile() async {
    final pick = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['srt', 'vtt'],
    );
    if (pick == null || pick.files.isEmpty) return;
    final f = pick.files.single;
    if (f.path == null) return;

    setState(() => _importing = true);
    try {
      await ref
          .read(transcriptRepositoryProvider)
          .importSubtitle(mediaId: widget.mediaId, file: XFile(f.path!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.importSubtitleSuccess),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _deleteTrack(TranscriptTrack track) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.subtitlesDeleteTrack),
            content: Text(track.label.isEmpty ? track.id : track.label),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(MaterialLocalizations.of(ctx).deleteButtonTooltip),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    await ref.read(transcriptRepositoryProvider).deleteTranscript(track.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tracksAsync = ref.watch(
      allTranscriptsForMediaProvider(widget.mediaId),
    );
    final primaryIdAsync = ref.watch(
      activeTranscriptIdProvider(widget.mediaId),
    );
    final secondaryIdAsync = ref.watch(
      secondaryTranscriptIdProvider(widget.mediaId),
    );

    final tracks = tracksAsync.value ?? <TranscriptTrack>[];
    final primaryId = primaryIdAsync.value;
    final secondaryId = secondaryIdAsync.value;

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder:
            (ctx, scrollCtrl) => Column(
              children: [
                // Drag handle
                Padding(
                  padding: EdgeInsets.symmetric(vertical: t.space12),
                  child: const _DragHandle(),
                ),
                // Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: t.space16 + t.space4),
                  child: Row(
                    children: [
                      Text(
                        l10n.subtitles,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Track list
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: EdgeInsets.only(bottom: t.space16),
                    children: [
                      _SectionHeader(l10n.subtitlesPrimary),
                      ...tracks.map(
                        (track) => _TrackTile(
                          track: track,
                          selected: track.id == primaryId,
                          isSecondary: false,
                          onTap:
                              () => ref
                                  .read(transcriptRepositoryProvider)
                                  .setActiveTranscript(widget.mediaId, track.id),
                          onDelete:
                              track.isEmbedded ? null : () => _deleteTrack(track),
                        ),
                      ),
                      SizedBox(height: t.space8),
                      _SectionHeader(l10n.subtitlesTranslation),
                      // "None" option
                      RadioListTile<String?>(
                        value: null,
                        groupValue: secondaryId,
                        onChanged:
                            (_) => ref
                                .read(transcriptRepositoryProvider)
                                .setSecondaryTranscript(widget.mediaId, null),
                        title: Text(l10n.subtitlesNone),
                      ),
                      ...tracks.map(
                        (track) => _TrackTile(
                          track: track,
                          selected: track.id == secondaryId,
                          isSecondary: true,
                          onTap:
                              () => ref
                                  .read(transcriptRepositoryProvider)
                                  .setSecondaryTranscript(
                                    widget.mediaId,
                                    track.id,
                                  ),
                          onDelete: null, // delete only from primary section
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading:
                            _importing
                                ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                )
                                : const Icon(Icons.upload_file_rounded),
                        title: Text(l10n.subtitlesImportFile),
                        onTap: _importing ? null : _importFile,
                      ),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(t.space16 + t.space4, t.space12, t.space16 + t.space4, t.space4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          letterSpacing: 0.9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.selected,
    required this.isSecondary,
    required this.onTap,
    required this.onDelete,
  });

  final TranscriptTrack track;
  final bool selected;
  final bool isSecondary;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sourceBadge =
        track.isEmbedded ? l10n.subtitlesEmbedded : l10n.subtitlesImported;

    final label = track.label.isNotEmpty ? track.label : track.language;

    return RadioListTile<String>(
      value: track.id,
      groupValue: selected ? track.id : null,
      onChanged: (_) => onTap(),
      title: Text(label),
      subtitle: Row(
        children: [
          _Badge(sourceBadge, isEmbedded: track.isEmbedded),
          if (track.language.isNotEmpty && track.language != 'und') ...[
            const SizedBox(width: 6),
            _Badge(track.language.toUpperCase(), isEmbedded: false),
          ],
        ],
      ),
      secondary:
          onDelete != null
              ? IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.subtitlesDeleteTrack,
                onPressed: onDelete,
              )
              : null,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {required this.isEmbedded});

  final String label;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = EnjoyThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isEmbedded ? cs.secondaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(t.space4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isEmbedded ? cs.onSecondaryContainer : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
