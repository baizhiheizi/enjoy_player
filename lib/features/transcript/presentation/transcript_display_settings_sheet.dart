/// The Display section of the Subtitles & display panel (canvas v30):
/// transcript type, spoken-word highlight, IPA, and word-timing progress.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/data/subtitle/transcript_display_readiness.dart';
import 'package:enjoy_player/features/settings/application/ipa_overlay_settings.dart';
import 'package:enjoy_player/features/settings/application/karaoke_highlight_settings.dart';
import 'package:enjoy_player/features/settings/application/transcript_typeface_settings.dart';
import 'package:enjoy_player/features/transcript/application/transcript_enrichment_controller.dart';
import 'package:enjoy_player/features/transcript/presentation/subtitle_track_picker_primitives.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Switch **value** is preference && capability; gated switches do not write
/// SettingsDao false.
class TranscriptDisplaySettingsSection extends ConsumerWidget {
  const TranscriptDisplaySettingsSection({
    required this.mediaId,
    required this.readiness,
    this.actionsBelow = false,
    super.key,
  });

  final String mediaId;
  final TranscriptDisplayReadiness readiness;

  /// True in the phone sheet, where the transcript actions follow this
  /// section instead of living in ⋯ More.
  final bool actionsBelow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final karaokePref =
        ref.watch(karaokeHighlightSettingsProvider).valueOrNull ?? false;
    final ipaPref = ref.watch(ipaOverlaySettingsProvider).valueOrNull ?? false;
    final enrich = ref.watch(transcriptEnrichmentControllerProvider(mediaId));
    final needsTimings = actionsBelow
        ? l10n.subtitlesNeedsWordTimingsBelow
        : l10n.subtitlesNeedsWordTimingsMore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: EnjoyOverline(l10n.subtitlesSectionDisplay),
        ),
        const TranscriptTypefacePicker(),
        SubtitleToggleTile(
          key: const ValueKey('display-highlight-spoken-word'),
          title: l10n.subtitlesHighlightSpokenWord,
          subtitle: readiness.karaokeSwitchEnabled
              ? l10n.subtitlesHighlightSpokenWordHint
              : readiness.canTrustWordTimes
              ? needsTimings
              : l10n.transcriptKaraokeUnavailableRemoteHint,
          value: karaokePref && readiness.karaokeSwitchEnabled,
          onChanged: readiness.karaokeSwitchEnabled
              ? (value) => unawaited(
                  ref
                      .read(karaokeHighlightSettingsProvider.notifier)
                      .setEnabled(value),
                )
              : null,
        ),
        SubtitleToggleTile(
          key: const ValueKey('display-ipa-under-words'),
          title: l10n.subtitlesIpaUnderWords,
          subtitle: readiness.ipaSwitchEnabled
              ? l10n.subtitlesIpaUnderWordsHint
              : needsTimings,
          value: ipaPref && readiness.ipaSwitchEnabled,
          onChanged: readiness.ipaSwitchEnabled
              ? (value) => unawaited(
                  ref
                      .read(ipaOverlaySettingsProvider.notifier)
                      .setEnabled(value),
                )
              : null,
        ),
        if (readiness.showEnrich && (enrich.isRunning || enrich.isFailed))
          TranscriptEnrichmentCard(
            mediaId: mediaId,
            owned: readiness.canTrustWordTimes,
          ),
      ],
    );
  }
}

class TranscriptTypefacePicker extends ConsumerWidget {
  const TranscriptTypefacePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected =
        ref.watch(transcriptTypefaceSettingsProvider).valueOrNull ??
        TranscriptTypeface.book;
    void select(TranscriptTypeface typeface) => unawaited(
      ref.read(transcriptTypefaceSettingsProvider.notifier).select(typeface),
    );

    return Semantics(
      label: l10n.transcriptTypefaceLabel,
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: _TypefaceTile(
                key: const ValueKey('typeface-book'),
                label: l10n.transcriptTypefaceBook,
                serif: true,
                selected: selected == TranscriptTypeface.book,
                onTap: () => select(TranscriptTypeface.book),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _TypefaceTile(
                key: const ValueKey('typeface-clean'),
                label: l10n.transcriptTypefaceClean,
                serif: false,
                selected: selected == TranscriptTypeface.clean,
                onTap: () => select(TranscriptTypeface.clean),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypefaceTile extends StatelessWidget {
  const _TypefaceTile({
    required this.label,
    required this.serif,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool serif;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: selected ? t.original : t.line, width: 1.5),
    );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: EnjoyPressable(
        onTap: onTap,
        shape: shape,
        pressedScale: 0.98,
        washColor: t.sunk,
        selected: selected,
        semanticsLabel: label,
        child: Container(
          height: 58,
          decoration: ShapeDecoration(shape: shape),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ag',
                style: TextStyle(
                  fontFamily: serif ? kLiterataFamily : kGeistFamily,
                  fontSize: 22,
                  height: 1.1,
                  color: t.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontSize: 12, color: t.ink2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Word-timing generation in progress (with Cancel) or failed (with retry).
class TranscriptEnrichmentCard extends ConsumerWidget {
  const TranscriptEnrichmentCard({
    required this.mediaId,
    required this.owned,
    super.key,
  });

  final String mediaId;
  final bool owned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final enrich = ref.watch(transcriptEnrichmentControllerProvider(mediaId));
    TranscriptEnrichmentController ctrl() =>
        ref.read(transcriptEnrichmentControllerProvider(mediaId).notifier);
    final running = enrich.isRunning;

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: running ? t.originalSoft : t.sunk,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  running
                      ? (owned
                            ? l10n.transcriptEnrichRunningOwned
                            : l10n.transcriptEnrichRunningYoutube)
                      : l10n.transcriptEnrichFailed,
                  style: tt.labelLarge?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
              ),
              if (running && enrich.total > 0) ...[
                const SizedBox(width: 12),
                Text(
                  l10n.transcriptEnrichProgress(enrich.completed, enrich.total),
                  style: enjoyMonoStyle(
                    context,
                    size: 12.5,
                    color: t.originalInk,
                  ),
                ),
              ],
            ],
          ),
          if (running) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: enrich.total > 0 ? enrich.fraction : null,
                minHeight: 4,
                color: t.original,
                backgroundColor: t.paper,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  owned
                      ? l10n.transcriptEnrichOwnedSubtitle
                      : l10n.transcriptEnrichYoutubeSubtitle,
                  style: tt.bodySmall?.copyWith(fontSize: 12.5, color: t.ink2),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: running ? t.originalInk : t.ink,
                  textStyle: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: running
                    ? () => ctrl().cancel()
                    : () => unawaited(ctrl().run()),
                child: Text(
                  running
                      ? l10n.transcriptEnrichCancel
                      : l10n.transcriptEnrichRetry,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
