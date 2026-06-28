/// Bottom sheet for selecting primary + secondary subtitle tracks.
library;

import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'import_subtitle_language_dialog.dart';
import 'transcript_busy_action.dart';
import 'transcript_embedded_extract.dart';
import '../../player/application/player_controller.dart';
import '../application/active_transcript_provider.dart';
import '../application/all_transcripts_provider.dart';
import '../application/transcript_fetch_controller.dart';
import '../application/transcript_repository_provider.dart';
import '../application/video_row_for_media_provider.dart';
import '../domain/transcript_fetch_status.dart';
import '../domain/transcript_track.dart';

/// Horizontal inset aligned with section headers and list rows.
double _sheetHorizontalPadding(EnjoyThemeTokens t) => t.space16 + t.space4;

/// Shared padding for radio rows, import tile, and empty/error bodies.
EdgeInsetsDirectional _sheetRowPadding(EnjoyThemeTokens t) =>
    EdgeInsetsDirectional.fromSTEB(
      _sheetHorizontalPadding(t),
      t.space4,
      t.space8,
      t.space4,
    );

enum SubtitleTrackPickerPresentation { sheet, dialog }

String _providerLabel(AppLocalizations l10n, String source) {
  switch (source) {
    case 'official':
      return l10n.subtitlesProviderOfficial;
    case 'auto':
      return l10n.subtitlesProviderAuto;
    case 'ai':
      return l10n.subtitlesProviderAi;
    case 'user':
      return l10n.subtitlesProviderUser;
    default:
      return source.toUpperCase();
  }
}

({Color bg, Color fg}) _providerBadgeColors(ColorScheme cs, String source) {
  switch (source) {
    case 'official':
      return (bg: cs.primaryContainer, fg: cs.onPrimaryContainer);
    case 'auto':
      return (bg: cs.tertiaryContainer, fg: cs.onTertiaryContainer);
    case 'ai':
      return (bg: cs.secondaryContainer, fg: cs.onSecondaryContainer);
    case 'user':
      return (bg: cs.surfaceContainerHighest, fg: cs.onSurfaceVariant);
    default:
      return (bg: cs.surfaceContainerHigh, fg: cs.onSurfaceVariant);
  }
}

/// Shows a modal bottom sheet (narrow) or centered dialog (wide) for picking subtitles.
Future<void> showSubtitleTrackPicker(
  BuildContext context,
  WidgetRef ref,
  String mediaId,
) {
  final w = MediaQuery.sizeOf(context).width;
  final tokens = EnjoyThemeTokens.of(context);
  if (w >= tokens.breakpointRail) {
    return showEnjoyDialog<void>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final t = EnjoyThemeTokens.of(ctx);
        return Dialog(
          backgroundColor: cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radiusXl),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(t.radiusXl),
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
  return showEnjoySheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SubtitleTrackPickerSheet(
      mediaId: mediaId,
      presentation: SubtitleTrackPickerPresentation.sheet,
    ),
  );
}

class SubtitleTrackPickerSheet extends ConsumerStatefulWidget {
  const SubtitleTrackPickerSheet({
    required this.mediaId,
    this.presentation = SubtitleTrackPickerPresentation.sheet,
    super.key,
  });

  final String mediaId;
  final SubtitleTrackPickerPresentation presentation;

  @override
  ConsumerState<SubtitleTrackPickerSheet> createState() =>
      _SubtitleTrackPickerSheetState();
}

class _SubtitleTrackPickerSheetState
    extends ConsumerState<SubtitleTrackPickerSheet> {
  ScrollController? _dialogScroll;

  @override
  void initState() {
    super.initState();
    if (widget.presentation == SubtitleTrackPickerPresentation.dialog) {
      _dialogScroll = ScrollController();
    }
  }

  @override
  void dispose() {
    _dialogScroll?.dispose();
    super.dispose();
  }

  Future<void> _importFile() async {
    final pick = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['srt', 'vtt'],
    );
    if (pick == null || pick.files.isEmpty) return;
    final f = pick.files.single;
    if (f.path == null) return;

    if (!mounted) return;
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
        .importSubtitle(
          mediaId: widget.mediaId,
          file: XFile(f.path!),
          language: trimmed,
        );
    if (mounted) {
      AppNotice.success(
        context,
        AppLocalizations.of(context)!.importSubtitleSuccess,
      );
    }
  }

  Future<void> _extractEmbedded() async {
    await runEmbeddedSubtitleExtract(
      context: context,
      ref: ref,
      mediaId: widget.mediaId,
    );
  }

  Future<void> _refreshCloud() async {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = ref.read(authCtrlProvider).valueOrNull is AuthSignedIn;
    await ref
        .read(transcriptFetchCtrlProvider(widget.mediaId).notifier)
        .refreshFromCloud(signedIn: signedIn);
    if (mounted) {
      final status = ref.read(transcriptFetchStatusProvider(widget.mediaId));
      if (status.status != TranscriptFetchStatus.error) {
        AppNotice.success(context, l10n.subtitlesRefreshDone);
      }
    }
  }

  Future<void> _deleteTrack(TranscriptTrack track) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showEnjoyAlertDialog<bool>(
      context: context,
      title: Text(l10n.subtitlesDeleteTrack),
      content: Text(track.label.isEmpty ? track.id : track.label),
      actionsBuilder: (ctx) => [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(MaterialLocalizations.of(ctx).deleteButtonTooltip),
        ),
      ],
    );
    if (confirmed != true) return;
    await ref.read(transcriptRepositoryProvider).deleteTranscript(track.id);
  }

  Widget _buildTrackList({
    required BuildContext context,
    required ScrollController scrollCtrl,
    required EnjoyThemeTokens t,
    required AppLocalizations l10n,
    required List<TranscriptTrack> tracks,
    required String? primaryId,
    required String? secondaryId,
    required bool showExtractEmbedded,
    required bool showImportFile,
    required bool isFetching,
  }) {
    final theme = Theme.of(context);

    return ListView(
      controller: scrollCtrl,
      padding: EdgeInsets.only(bottom: t.space16),
      children: [
        if (isFetching)
          Padding(
            padding: EdgeInsets.fromLTRB(
              _sheetHorizontalPadding(t),
              t.space8,
              _sheetHorizontalPadding(t),
              t.space8,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: t.space12),
                Expanded(
                  child: Text(
                    l10n.transcriptFetchingSubtitles,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _SectionHeader(l10n.subtitlesPrimary),
        if (tracks.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(
              _sheetHorizontalPadding(t),
              t.space4,
              _sheetHorizontalPadding(t),
              t.space12,
            ),
            child: Text(
              l10n.noTranscriptHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          )
        else
          RadioGroup<String?>(
            groupValue: primaryId,
            onChanged: (id) {
              if (id == null) return;
              unawaited(
                ref
                    .read(transcriptRepositoryProvider)
                    .setActiveTranscript(widget.mediaId, id),
              );
            },
            child: Column(
              children: tracks
                  .map(
                    (track) => _TrackTile(
                      track: track,
                      contentPadding: _sheetRowPadding(t),
                      onDelete: () => _deleteTrack(track),
                    ),
                  )
                  .toList(),
            ),
          ),
        SizedBox(height: t.space8),
        _SectionHeader(l10n.subtitlesTranslation),
        RadioGroup<String?>(
          groupValue: secondaryId,
          onChanged: (id) => ref
              .read(transcriptRepositoryProvider)
              .setSecondaryTranscript(widget.mediaId, id),
          child: Column(
            children: [
              RadioListTile<String?>(
                contentPadding: _sheetRowPadding(t),
                value: null,
                title: Text(l10n.subtitlesNone),
              ),
              ...tracks.map(
                (track) => _TrackTile(
                  track: track,
                  contentPadding: _sheetRowPadding(t),
                  onDelete: () => _deleteTrack(track),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        if (showExtractEmbedded)
          TranscriptBusyListTile(
            contentPadding: _sheetRowPadding(t),
            icon: Icons.subtitles_outlined,
            title: l10n.subtitlesExtractEmbedded,
            onTap: _extractEmbedded,
          ),
        TranscriptBusyListTile(
          contentPadding: _sheetRowPadding(t),
          icon: Icons.cloud_download_outlined,
          title: l10n.subtitlesRefreshCloud,
          onTap: _refreshCloud,
        ),
        if (showImportFile)
          TranscriptBusyListTile(
            contentPadding: _sheetRowPadding(t),
            icon: Icons.upload_file_rounded,
            title: l10n.subtitlesImportFile,
            onTap: _importFile,
          ),
      ],
    );
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

    final primaryId = primaryIdAsync.value;
    final secondaryId = secondaryIdAsync.value;
    final session = ref.watch(playerControllerProvider);
    final videoRowAsync = ref.watch(videoRowForMediaProvider(widget.mediaId));
    final isYoutube = videoRowAsync.maybeWhen(
      data: (row) => row?.provider == 'youtube',
      orElse: () => false,
    );
    final showExtractEmbedded =
        session != null && session.dexieTargetType == 'Video' && !isYoutube;
    final fetchState = ref.watch(transcriptFetchStatusProvider(widget.mediaId));
    final isFetching = fetchState.status == TranscriptFetchStatus.loading;

    Widget columnBody(ScrollController sc) {
      return Column(
        children: [
          if (widget.presentation == SubtitleTrackPickerPresentation.sheet)
            const PaddedSheetDragHandle()
          else
            SizedBox(height: t.space8),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _sheetHorizontalPadding(t),
            ),
            child: Row(
              children: [
                Text(
                  l10n.subtitles,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    fixedSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: tracksAsync.when(
              data: (tracks) => _buildTrackList(
                context: context,
                scrollCtrl: sc,
                t: t,
                l10n: l10n,
                tracks: tracks,
                primaryId: primaryId,
                secondaryId: secondaryId,
                showExtractEmbedded: showExtractEmbedded,
                showImportFile: !isYoutube,
                isFetching: isFetching,
              ),
              loading: () => SkeletonTranscript(lineCount: 12, controller: sc),
              error: (error, _) => ListView(
                controller: sc,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(_sheetHorizontalPadding(t)),
                children: [
                  SizedBox(height: t.space24),
                  Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  SizedBox(height: t.space12),
                  Text(
                    l10n.transcriptErrorFriendlyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: t.space8),
                  Text(
                    l10n.transcriptErrorFriendlyHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: t.space16),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(
                      allTranscriptsForMediaProvider(widget.mediaId),
                    ),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (widget.presentation == SubtitleTrackPickerPresentation.dialog) {
      return columnBody(_dialogScroll!);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, sc) => columnBody(sc),
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
      padding: EdgeInsets.fromLTRB(
        _sheetHorizontalPadding(t),
        t.space12,
        _sheetHorizontalPadding(t),
        t.space4,
      ),
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
    required this.contentPadding,
    required this.onDelete,
  });

  final TranscriptTrack track;
  final EdgeInsetsGeometry contentPadding;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final providerLabel = _providerLabel(l10n, track.source);
    final badgeColors = _providerBadgeColors(cs, track.source);

    final label = track.label.isNotEmpty ? track.label : track.language;

    return RadioListTile<String>(
      contentPadding: contentPadding,
      value: track.id,
      title: Text(label),
      subtitle: Padding(
        padding: EdgeInsets.only(top: t.space8),
        child: Wrap(
          spacing: t.space8,
          runSpacing: t.space4,
          children: [
            _Badge(
              label: providerLabel,
              background: badgeColors.bg,
              foreground: badgeColors.fg,
            ),
            if (track.language.isNotEmpty && track.language != 'und')
              _Badge(
                label: track.language.toUpperCase(),
                background: cs.surfaceContainerHighest,
                foreground: cs.onSurfaceVariant,
              ),
          ],
        ),
      ),
      secondary: IconButton(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          fixedSize: const Size(48, 48),
        ),
        icon: const Icon(Icons.delete_outline),
        tooltip: l10n.subtitlesDeleteTrack,
        onPressed: onDelete,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.space8, vertical: t.space4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(t.space4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
