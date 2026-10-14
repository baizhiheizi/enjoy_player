/// Widget composition for the subtitle track picker sheet body: header,
/// track lists, loading skeletons, and error state.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import '../application/all_transcripts_provider.dart';
import '../application/transcript_repository_provider.dart';
import '../domain/auto_translate.dart';
import '../domain/transcript_track.dart';
import 'package:enjoy_player/data/subtitle/transcript_display_readiness.dart';
import 'subtitle_track_picker_actions.dart';
import 'subtitle_track_picker_primitives.dart';
import 'transcript_actions.dart';
import 'subtitle_track_picker_helpers.dart';
import 'subtitle_track_picker_sections.dart';
import 'subtitle_track_picker_sheet_action_handlers.dart';
import 'subtitle_track_picker_tiles.dart';
import 'transcript_display_settings_sheet.dart';

String? _autoTranslateBlockedMessage(
  AppLocalizations l10n,
  AutoTranslateUiState state,
) {
  return switch (state.blockReason) {
    AutoTranslateBlockReason.signedOut =>
      l10n.subtitlesAutoTranslateBlockedSignedOut,
    AutoTranslateBlockReason.sameLanguage =>
      l10n.subtitlesAutoTranslateBlockedSameLanguage,
    AutoTranslateBlockReason.noPrimary =>
      l10n.subtitlesAutoTranslateBlockedNoPrimary,
    AutoTranslateBlockReason.credits =>
      state.creditsFailure != null
          ? creditsFailureMessage(state.creditsFailure!, l10n)
          : l10n.subtitlesAutoTranslateBlockedCredits,
    AutoTranslateBlockReason.auth =>
      l10n.subtitlesAutoTranslateBlockedSignedOut,
    AutoTranslateBlockReason.stalePrimary =>
      l10n.subtitlesAutoTranslateBlockedStalePrimary,
    null => null,
  };
}

List<Widget> buildTrackListBody({
  required BuildContext context,
  required WidgetRef ref,
  required String mediaId,
  required EnjoyThemeTokens t,
  required AppLocalizations l10n,
  required List<TranscriptTrack> tracks,
  required String? primaryId,
  required String? secondaryId,
  required bool isFetching,
  required bool inlineExpandedLists,
  required String? autoSelectionId,
  required String targetLanguage,
  required AutoTranslateUiState autoTranslateState,
  required bool signedIn,
  required TranscriptDisplayReadiness readiness,
  required PickerSection? expandedSection,
  required ValueChanged<PickerSection> onToggleSection,
  required VoidCallback onCollapseSection,
  required ValueChanged<String?> onSecondarySelected,
}) {
  final theme = Theme.of(context);
  final translationTracks = tracks
      .where((track) => track.source != 'ai')
      .toList();
  final autoTranslateSelected =
      autoSelectionId != null && secondaryId == autoSelectionId;
  final blockedMessage = _autoTranslateBlockedMessage(l10n, autoTranslateState);

  return [
    Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: EnjoyOverline(l10n.subtitlesSectionSubtitles),
    ),
    if (isFetching)
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Row(
          children: [
            LoadingIcon(size: 18, color: theme.colorScheme.primary),
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
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Text(
          l10n.noTranscriptHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: t.ink2,
            height: 1.45,
          ),
        ),
      )
    else
      CollapsibleTrackSection(
        title: l10n.subtitlesPrimary,
        isExpanded: expandedSection == PickerSection.primary,
        onToggle: () => onToggleSection(PickerSection.primary),
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
            onCollapseSection();
            unawaited(
              ref
                  .read(transcriptRepositoryProvider)
                  .setActiveTranscript(mediaId, id),
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
                      onDelete: () =>
                          confirmAndDeleteTranscriptTrack(context, ref, track),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    CollapsibleTrackSection(
      title: l10n.subtitlesTranslation,
      isExpanded: expandedSection == PickerSection.secondary,
      onToggle: () => onToggleSection(PickerSection.secondary),
      inlineExpandedList: inlineExpandedLists,
      selectionLabel: () {
        if (autoTranslateSelected) {
          return targetLanguage.isEmpty
              ? l10n.subtitlesAutoTranslate
              : '${l10n.subtitlesAutoTranslate} (${targetLanguage.toUpperCase()})';
        }
        if (secondaryId == null) return l10n.subtitlesNone;
        final selected = findTrack(tracks, secondaryId);
        return selected == null
            ? l10n.subtitlesNotSelected
            : trackLabel(selected);
      }(),
      selectedTrack: autoTranslateSelected
          ? null
          : findTrack(tracks, secondaryId),
      child: RadioGroup<String?>(
        groupValue: secondaryId,
        onChanged: (id) {
          onCollapseSection();
          onSecondarySelected(id);
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
              if (autoSelectionId != null)
                AutoTranslateOptionTile(
                  value: autoSelectionId,
                  selected: autoTranslateSelected,
                  padding: trackOptionPadding(t),
                  targetLanguage: targetLanguage,
                  enabled: primaryId != null,
                ),
              if (blockedMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Text(
                    blockedMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              if (autoTranslateState.blockReason ==
                  AutoTranslateBlockReason.credits)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => context.push('/subscription'),
                      child: Text(creditsCtaLabel(l10n)),
                    ),
                  ),
                ),
              if (!signedIn &&
                  autoTranslateState.blockReason ==
                      AutoTranslateBlockReason.signedOut)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: AuthRequiredCallout(
                    surface: AuthRequiredSurface.lookupTranslation,
                  ),
                ),
              ...translationTracks.map(
                (track) => TrackOptionTile<String?>(
                  value: track.id,
                  selected: secondaryId == track.id,
                  track: track,
                  padding: trackOptionPadding(t),
                  onDelete: () =>
                      confirmAndDeleteTranscriptTrack(context, ref, track),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    const SubtitlePanelDivider(),
    TranscriptDisplaySettingsSection(
      mediaId: mediaId,
      readiness: readiness,
      actionsBelow: !inlineExpandedLists,
    ),
    if (inlineExpandedLists)
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Text(
          l10n.subtitlesManageFromMore,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12.5,
            height: 1.45,
            color: t.ink3,
          ),
        ),
      )
    else ...[
      const SubtitlePanelDivider(),
      TranscriptActionsList(
        actions: watchTranscriptActions(ref, l10n, mediaId),
      ),
    ],
  ];
}

Widget buildSheetHeader(BuildContext context, EnjoyThemeTokens t) {
  final l10n = AppLocalizations.of(context)!;
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            l10n.subtitlesPanelTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: t.ink,
            ),
          ),
        ),
        IconButton(
          icon: Icon(EnjoyIcons.close, size: 20, color: t.ink2),
          tooltip: MaterialLocalizations.of(context).closeButtonLabel,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

Widget buildTracksContent({
  required BuildContext context,
  required WidgetRef ref,
  required String mediaId,
  required ScrollController scrollCtrl,
  required EnjoyThemeTokens t,
  required AppLocalizations l10n,
  required AsyncValue<List<TranscriptTrack>> tracksAsync,
  required bool isDialog,
  required bool isFetching,
  required String? primaryId,
  required String? secondaryId,
  required String? autoSelectionId,
  required String targetLanguage,
  required AutoTranslateUiState autoTranslateState,
  required bool signedIn,
  required TranscriptDisplayReadiness readiness,
  required PickerSection? expandedSection,
  required ValueChanged<PickerSection> onToggleSection,
  required VoidCallback onCollapseSection,
  required ValueChanged<String?> onSecondarySelected,
}) {
  final cs = Theme.of(context).colorScheme;

  Widget whenData(List<TranscriptTrack> tracks) {
    final body = buildTrackListBody(
      context: context,
      ref: ref,
      mediaId: mediaId,
      t: t,
      l10n: l10n,
      tracks: tracks,
      primaryId: primaryId,
      secondaryId: secondaryId,
      isFetching: isFetching,
      inlineExpandedLists: isDialog,
      autoSelectionId: autoSelectionId,
      targetLanguage: targetLanguage,
      autoTranslateState: autoTranslateState,
      signedIn: signedIn,
      readiness: readiness,
      expandedSection: expandedSection,
      onToggleSection: onToggleSection,
      onCollapseSection: onCollapseSection,
      onSecondarySelected: onSecondarySelected,
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
        ? buildDialogSkeletonLoading(t)
        : SkeletonTranscript(lineCount: 12, controller: scrollCtrl),
    error: (error, _) {
      final errorBody = [
        SizedBox(height: t.space24),
        Icon(EnjoyIcons.error, size: 40, color: cs.error),
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
        EnjoyButton.tonal(
          onPressed: () =>
              ref.invalidate(allTranscriptsForMediaProvider(mediaId)),
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

Widget buildDialogSkeletonLoading(EnjoyThemeTokens t) {
  return Padding(
    padding: EdgeInsets.all(sheetHorizontalPadding(t)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(4, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: t.space12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton.box(
                width: 44,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
              SizedBox(width: t.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Skeleton.line(width: double.infinity, height: 14),
                    SizedBox(height: t.space8),
                    Skeleton.line(
                      width: i % 2 == 0 ? double.infinity : 200.0,
                      height: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    ),
  );
}
