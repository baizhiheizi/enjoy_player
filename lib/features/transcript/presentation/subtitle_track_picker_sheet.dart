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
import 'subtitle_track_picker_actions.dart';
import 'subtitle_track_picker_helpers.dart';
import 'subtitle_track_picker_sections.dart';
import 'subtitle_track_picker_tiles.dart';
import 'import_subtitle_language_dialog.dart';
import 'transcript_embedded_extract.dart';
import '../../player/application/player_controller.dart';
import '../application/active_transcript_provider.dart';
import '../application/all_transcripts_provider.dart';
import '../application/transcript_fetch_controller.dart';
import '../application/transcript_repository_provider.dart';
import '../application/video_row_for_media_provider.dart';
import '../domain/transcript_fetch_status.dart';
import '../domain/transcript_track.dart';

enum SubtitleTrackPickerPresentation { sheet, dialog }

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
          insetPadding: EdgeInsets.symmetric(
            horizontal: t.desktopGutter,
            vertical: t.space32,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: t.modalMaxWidthLarge),
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
  PickerSection? _expandedSection;

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

  void _toggleSection(PickerSection section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  void _collapseSection() {
    if (_expandedSection != null) {
      setState(() => _expandedSection = null);
    }
  }

  List<Widget> _buildTrackListBody({
    required BuildContext context,
    required EnjoyThemeTokens t,
    required AppLocalizations l10n,
    required List<TranscriptTrack> tracks,
    required String? primaryId,
    required String? secondaryId,
    required bool showExtractEmbedded,
    required bool showImportFile,
    required bool isFetching,
    required bool inlineExpandedLists,
  }) {
    final theme = Theme.of(context);

    return [
      if (isFetching)
        Padding(
          padding: EdgeInsets.fromLTRB(
            sheetHorizontalPadding(t),
            t.space8,
            sheetHorizontalPadding(t),
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
      if (tracks.isEmpty)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sheetHorizontalPadding(t)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow.withValues(
                alpha: 0.92,
              ),
              borderRadius: BorderRadius.circular(t.radiusLg),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.16),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(t.space16),
              child: Text(
                l10n.noTranscriptHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          ),
        )
      else
        CollapsibleTrackSection(
          title: l10n.subtitlesPrimary,
          isExpanded: _expandedSection == PickerSection.primary,
          onToggle: () => _toggleSection(PickerSection.primary),
          inlineExpandedList: inlineExpandedLists,
          selectionLabel: () {
            final selected = findTrack(tracks, primaryId);
            return selected == null
                ? l10n.subtitlesNotSelected
                : trackLabel(selected);
          }(),
          selectedTrack: findTrack(tracks, primaryId),
          child: RadioGroup<String>(
            groupValue: primaryId,
            onChanged: (id) {
              if (id == null) return;
              _collapseSection();
              unawaited(
                ref
                    .read(transcriptRepositoryProvider)
                    .setActiveTranscript(widget.mediaId, id),
              );
            },
            child: Theme(
              data: trackPickerRadioTheme(context),
              child: Column(
                children: tracks
                    .map(
                      (track) => TrackOptionTile<String>(
                        value: track.id,
                        selected: primaryId == track.id,
                        track: track,
                        padding: trackOptionPadding(t),
                        onDelete: () => _deleteTrack(track),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      SizedBox(height: t.space12),
      CollapsibleTrackSection(
        title: l10n.subtitlesTranslation,
        isExpanded: _expandedSection == PickerSection.secondary,
        onToggle: () => _toggleSection(PickerSection.secondary),
        inlineExpandedList: inlineExpandedLists,
        selectionLabel: () {
          if (secondaryId == null) return l10n.subtitlesNone;
          final selected = findTrack(tracks, secondaryId);
          return selected == null
              ? l10n.subtitlesNotSelected
              : trackLabel(selected);
        }(),
        selectedTrack: findTrack(tracks, secondaryId),
        child: RadioGroup<String?>(
          groupValue: secondaryId,
          onChanged: (id) {
            _collapseSection();
            unawaited(
              ref
                  .read(transcriptRepositoryProvider)
                  .setSecondaryTranscript(widget.mediaId, id),
            );
          },
          child: Theme(
            data: trackPickerRadioTheme(context),
            child: Column(
              children: [
                NoneOptionTile(
                  padding: trackOptionPadding(t),
                  label: l10n.subtitlesNone,
                  selected: secondaryId == null,
                ),
                ...tracks.map(
                  (track) => TrackOptionTile<String?>(
                    value: track.id,
                    selected: secondaryId == track.id,
                    track: track,
                    padding: trackOptionPadding(t),
                    onDelete: () => _deleteTrack(track),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      SizedBox(height: t.space16),
      SubtitleActionsSection(
        horizontalPadding: sheetHorizontalPadding(t),
        showExtractEmbedded: showExtractEmbedded,
        showImportFile: showImportFile,
        onExtractEmbedded: _extractEmbedded,
        onRefreshCloud: _refreshCloud,
        onImportFile: _importFile,
      ),
    ];
  }

  Widget _buildSheetHeader(BuildContext context, EnjoyThemeTokens t) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        sheetHorizontalPadding(t),
        t.space4,
        sheetHorizontalPadding(t),
        t.space4,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(t.radiusSm),
            ),
            child: Icon(
              Icons.closed_caption_rounded,
              size: 20,
              color: cs.primary,
            ),
          ),
          SizedBox(width: t.space12),
          Expanded(
            child: Text(
              l10n.subtitles,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          IconButton(
            style: IconButton.styleFrom(
              minimumSize: const Size(40, 40),
              fixedSize: const Size(40, 40),
              backgroundColor: cs.surfaceContainerHighest.withValues(
                alpha: 0.65,
              ),
            ),
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksContent({
    required BuildContext context,
    required ScrollController scrollCtrl,
    required EnjoyThemeTokens t,
    required AppLocalizations l10n,
    required AsyncValue<List<TranscriptTrack>> tracksAsync,
    required bool isDialog,
    required bool showExtractEmbedded,
    required bool showImportFile,
    required bool isFetching,
    required String? primaryId,
    required String? secondaryId,
  }) {
    final cs = Theme.of(context).colorScheme;

    Widget whenData(List<TranscriptTrack> tracks) {
      final body = _buildTrackListBody(
        context: context,
        t: t,
        l10n: l10n,
        tracks: tracks,
        primaryId: primaryId,
        secondaryId: secondaryId,
        showExtractEmbedded: showExtractEmbedded,
        showImportFile: showImportFile,
        isFetching: isFetching,
        inlineExpandedLists: isDialog,
      );

      if (isDialog) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: body,
        );
      }

      return ListView(
        controller: scrollCtrl,
        padding: EdgeInsets.only(bottom: t.space16),
        children: body,
      );
    }

    return tracksAsync.when(
      data: whenData,
      loading: () => isDialog
          ? Padding(
              padding: EdgeInsets.all(sheetHorizontalPadding(t)),
              child: const SkeletonTranscript(lineCount: 4),
            )
          : SkeletonTranscript(lineCount: 12, controller: scrollCtrl),
      error: (error, _) {
        final errorBody = [
          SizedBox(height: t.space24),
          Icon(Icons.error_outline_rounded, size: 40, color: cs.error),
          SizedBox(height: t.space12),
          Text(
            l10n.transcriptErrorFriendlyTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: t.space8),
          Text(
            l10n.transcriptErrorFriendlyHint,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: t.space16),
          FilledButton.tonal(
            onPressed: () =>
                ref.invalidate(allTranscriptsForMediaProvider(widget.mediaId)),
            child: Text(l10n.retry),
          ),
        ];

        if (isDialog) {
          return Padding(
            padding: EdgeInsets.all(sheetHorizontalPadding(t)),
            child: Column(mainAxisSize: MainAxisSize.min, children: errorBody),
          );
        }

        return ListView(
          controller: scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(sheetHorizontalPadding(t)),
          children: errorBody,
        );
      },
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
      final isDialog =
          widget.presentation == SubtitleTrackPickerPresentation.dialog;
      final divider = Divider(
        height: 1,
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.18),
      );
      final tracksContent = _buildTracksContent(
        context: context,
        scrollCtrl: sc,
        t: t,
        l10n: l10n,
        tracksAsync: tracksAsync,
        isDialog: isDialog,
        showExtractEmbedded: showExtractEmbedded,
        showImportFile: !isYoutube,
        isFetching: isFetching,
        primaryId: primaryId,
        secondaryId: secondaryId,
      );

      if (isDialog) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            controller: sc,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: t.space20),
                _buildSheetHeader(context, t),
                divider,
                tracksContent,
                SizedBox(height: t.space20),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          const PaddedSheetDragHandle(),
          _buildSheetHeader(context, t),
          divider,
          Expanded(child: tracksContent),
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
