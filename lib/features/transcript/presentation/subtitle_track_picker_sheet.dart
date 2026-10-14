/// The Subtitles & display panel: a popover under the top bar's Subtitles
/// chip on wide windows, a bottom sheet on narrow ones.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import '../application/active_transcript_provider.dart';
import '../application/all_transcripts_provider.dart';
import '../application/auto_translate_controller.dart';
import '../application/transcript_display_readiness_provider.dart';
import '../application/transcript_fetch_controller.dart';
import '../application/transcript_repository_provider.dart';
import '../domain/transcript_fetch_status.dart';
import 'subtitle_track_picker_helpers.dart';
import 'subtitle_track_picker_popover_route.dart';
import 'subtitle_track_picker_sheet_body.dart';

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
    return Navigator.of(
      context,
      rootNavigator: true,
    ).push(SubtitlesPopoverRoute(mediaId: mediaId));
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

  Future<void> _onSecondarySelectionChanged(
    String? id,
    String? autoSelectionId,
  ) async {
    final ctrl = ref.read(autoTranslateCtrlProvider(widget.mediaId).notifier);
    if (id == null) {
      await ref
          .read(transcriptRepositoryProvider)
          .setSecondaryTranscript(widget.mediaId, null);
      return;
    }
    if (autoSelectionId != null && id == autoSelectionId) {
      await ctrl.selectAutoTranslate();
      return;
    }
    await ref
        .read(transcriptRepositoryProvider)
        .setSecondaryTranscript(widget.mediaId, id);
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
    final fetchState = ref.watch(transcriptFetchStatusProvider(widget.mediaId));
    final isFetching = fetchState.status == TranscriptFetchStatus.loading;
    final autoTranslateState = ref.watch(
      autoTranslateCtrlProvider(widget.mediaId),
    );
    final autoSelectionAsync = ref.watch(
      autoTranslateSelectionIdProvider(widget.mediaId),
    );
    final autoSelectionId = autoSelectionAsync.valueOrNull;
    final targetLanguage =
        ref
            .watch(appPreferencesCtrlProvider)
            .valueOrNull
            ?.effectiveNativeLanguage ??
        '';
    final signedIn = ref.watch(authIsSignedInProvider);
    final readiness = ref.watch(
      transcriptDisplayReadinessForMediaProvider(widget.mediaId),
    );

    Widget columnBody(ScrollController sc) {
      final isDialog =
          widget.presentation == SubtitleTrackPickerPresentation.dialog;
      final divider = Divider(height: 1, color: t.line);
      final tracksContent = buildTracksContent(
        context: context,
        ref: ref,
        mediaId: widget.mediaId,
        scrollCtrl: sc,
        t: t,
        l10n: l10n,
        tracksAsync: tracksAsync,
        isDialog: isDialog,
        isFetching: isFetching,
        primaryId: primaryId,
        secondaryId: secondaryId,
        autoSelectionId: autoSelectionId,
        targetLanguage: targetLanguage,
        autoTranslateState: autoTranslateState,
        signedIn: signedIn,
        readiness: readiness,
        expandedSection: _expandedSection,
        onToggleSection: _toggleSection,
        onCollapseSection: _collapseSection,
        onSecondarySelected: (id) =>
            unawaited(_onSecondarySelectionChanged(id, autoSelectionId)),
      );

      if (isDialog) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
        return Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              controller: sc,
              padding: const EdgeInsets.all(8),
              child: tracksContent,
            ),
          ),
        );
      }

      return Column(
        children: [
          const PaddedSheetDragHandle(),
          buildSheetHeader(context, t),
          divider,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: tracksContent,
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
