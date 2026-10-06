/// Home hero: resume the last practiced item (the `Home` board's Continue
/// practicing card). The cover carries the resume progress; the text column
/// quotes the line playback resumes at.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/library/domain/practice_resume.dart';
import 'package:enjoy_player/features/player/application/local_thumbnail_provider.dart';
import 'package:enjoy_player/features/player/application/youtube_warm.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_markup.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const double _kCoverWidth = 320;
const double _kCoverMinHeight = 230;

/// Index of the line holding [positionMs], or null when [lines] is empty.
int? resumeLineIndex(List<TranscriptLine> lines, int positionMs) {
  if (lines.isEmpty) return null;
  var index = 0;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].startMs <= positionMs) index = i;
  }
  return index;
}

class ContinuePracticeCard extends ConsumerWidget {
  const ContinuePracticeCard({
    super.key,
    required this.resume,
    this.stacked = false,
  });

  final PracticeResume resume;

  /// Cover above the text (phones) instead of beside it.
  final bool stacked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final media = resume.media;
    final lines =
        ref.watch(transcriptLinesForMediaProvider(media.id)).value ??
        const <TranscriptLine>[];
    final lineIndex = resumeLineIndex(lines, resume.positionMs);
    final progress = resume.progress;
    final meta = [
      media.kind == MediaKind.video
          ? l10n.miniPlayerMediaVideo
          : l10n.miniPlayerMediaAudio,
      if (lineIndex != null) l10n.homeContinueLine(lineIndex + 1, lines.length),
      if (resume.echoActive) l10n.homeContinueEchoOn,
      if (progress != null) '${(progress * 100).round()}%',
    ].join(' · ');
    final quote = lineIndex == null
        ? null
        : transcriptPlainForSelection(lines[lineIndex].text);

    void open() {
      warmYoutubeSurfaceIfNeeded(ref, provider: media.provider);
      openPlayerRoute(context, media.id);
    }

    final details = Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: stacked ? MainAxisSize.min : MainAxisSize.max,
        children: [
          EnjoyOverline(l10n.homeContinuePracticing, color: t.brandInk),
          const SizedBox(height: 10),
          Text(
            media.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tt.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.18,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(fontSize: 13, color: t.ink3),
          ),
          if (quote != null && quote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '“$quote”',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: enjoyDisplayStyle(
                context,
                size: 19,
                color: t.ink2,
                height: 1.45,
              ).copyWith(fontWeight: FontWeight.w400),
            ),
          ],
          if (stacked) const SizedBox(height: 16) else const Spacer(),
          const SizedBox(height: 6),
          EnjoyButton.brand(
            icon: EnjoyIcons.play,
            onPressed: open,
            child: Text(l10n.homeContinueAction),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: l10n.homeContinueOpenSemantics(media.title),
      child: EnjoyPressable(
        onTap: open,
        borderRadius: BorderRadius.circular(t.radiusCardLarge),
        showHoverWash: false,
        pressedScale: 0.99,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: t.paper,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(t.radiusCardLarge),
              side: BorderSide(color: t.line),
            ),
          ),
          child: ClipRSuperellipse(
            borderRadius: BorderRadius.circular(t.radiusCardLarge),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _ContinueCover(resume: resume),
                      ),
                      details,
                    ],
                  )
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: _kCoverMinHeight,
                          ),
                          child: SizedBox(
                            width: _kCoverWidth,
                            child: _ContinueCover(
                              resume: resume,
                              width: _kCoverWidth,
                            ),
                          ),
                        ),
                        Expanded(child: details),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ContinueCover extends ConsumerWidget {
  const _ContinueCover({required this.resume, this.width});

  final PracticeResume resume;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = resume.media;
    final cs = Theme.of(context).colorScheme;
    final thumb = ref
        .watch(localThumbnailFileProvider(localThumbnailPathForMedia(media)))
        .value;
    final progress = resume.progress ?? 0;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          MediaCardThumbnail(
            width: width,
            file: thumb,
            networkUrl: networkThumbnailForMedia(media),
            coverSeed: media.coverSeed,
            isVideo: media.kind == MediaKind.video,
            cs: cs,
          ),
          const Center(child: MediaCardPlayGlyph(size: 58)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 4,
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.22),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: const ColoredBox(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
