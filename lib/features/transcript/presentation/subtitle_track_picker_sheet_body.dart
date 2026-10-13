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
  required bool showExtractEmbedded,
  required bool showImportFile,
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
        padding: EdgeInsets.symmetric(horizontal: sheetHorizontalPadding(t)),
        child: DecoratedBox(
          decoration: subtitlePickerCardDecoration(context),
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
    SizedBox(height: t.space12),
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
                  padding: EdgeInsets.fromLTRB(
                    sheetHorizontalPadding(t),
                    t.space4,
                    sheetHorizontalPadding(t),
                    t.space8,
                  ),
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
                  padding: EdgeInsets.fromLTRB(
                    sheetHorizontalPadding(t),
                    0,
                    sheetHorizontalPadding(t),
                    t.space8,
                  ),
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
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: sheetHorizontalPadding(t),
                    vertical: t.space8,
                  ),
                  child: const AuthRequiredCallout(
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
    SizedBox(height: t.space16),
    TranscriptDisplaySettingsSection(
      mediaId: mediaId,
      readiness: readiness,
      horizontalPadding: sheetHorizontalPadding(t),
    ),
    SizedBox(height: t.space16),
    SubtitleActionsSection(
      horizontalPadding: sheetHorizontalPadding(t),
      showExtractEmbedded: showExtractEmbedded,
      showImportFile: showImportFile,
      onExtractEmbedded: () =>
          runExtractEmbeddedSubtitles(context, ref, mediaId),
      onRefreshCloud: () => refreshCloudTranscripts(context, ref, mediaId),
      onImportFile: () => pickAndImportSubtitleFile(context, ref, mediaId),
      onGenerate: () => runGenerateTranscript(context, ref, mediaId),
      showGenerate: showImportFile,
      hasGeneratedTrack: tracks.any((track) => track.source == 'ai'),
    ),
  ];
}

Widget buildSheetHeader(BuildContext context, EnjoyThemeTokens t) {
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
          child: Icon(EnjoyIcons.cc, size: 20, color: cs.primary),
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
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.65),
          ),
          icon: Icon(EnjoyIcons.close, size: 20, color: cs.onSurfaceVariant),
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
  required bool showExtractEmbedded,
  required bool showImportFile,
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
      showExtractEmbedded: showExtractEmbedded,
      showImportFile: showImportFile,
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
