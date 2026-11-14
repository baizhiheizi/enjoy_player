/// Single transcript cue row with timestamp, markup, and tap target.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/interaction/mouse_tracker_safe.dart';
import 'package:enjoy_player/core/platform/mobile_platform.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/transcript/transcript_lens_metrics.dart';
import 'package:enjoy_player/data/subtitle/current_transcript_word.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/settings/application/ipa_overlay_settings.dart';
import 'package:enjoy_player/features/transcript/application/tap_reveal_hold_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_cue_reveal_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_markup.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_tile_chrome.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_tile_text.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_word_ipa_layer.dart';

@visibleForTesting
int transcriptTileBuildCount = 0;

class TranscriptLineTile extends ConsumerStatefulWidget {
  const TranscriptLineTile({
    required this.line,
    required this.mediaId,
    required this.secondaryText,
    required this.isActive,
    required this.inEcho,
    required this.onTap,
    this.lineIndex = 0,
    this.groupedInEcho = false,
    this.selectable = false,
    this.recordingCount,
    this.loopFontSize,
    this.wavyWordIndexes,
    this.lensDistance = 0,
    this.onLookupRequested,
    this.onRetranslateSecondary,
    this.dimWhenInactive = false,
    super.key,
  });

  final TranscriptLine line;
  final String mediaId;
  final String? secondaryText;
  final bool isActive;
  final bool inEcho;

  /// Index of [line] in the primary track (word seek).
  final int lineIndex;

  /// Echo cues rendered inside the echo-region transcript shell: flat rows.
  final bool groupedInEcho;

  /// When true, cue text is selectable and tap-to-seek is disabled (active / echo lines).
  final bool selectable;

  /// Overlapping shadow-reading take count when known; `null` while loading.
  final int? recordingCount;

  /// Literata size for cues inside the Echo loop (the loop grows in place).
  /// Null outside the loop.
  final double? loopFontSize;

  /// Loop-word indexes with the wavy mispronunciation underline (D3.8).
  final Set<int>? wavyWordIndexes;

  /// 1–3 while the cue sits that many lines outside the echo loop; fades and
  /// shrinks the row through `echoLensOpacity`. 0 outside echo mode.
  final int lensDistance;

  /// Invoked when the user chooses **Look up** in the text selection toolbar
  /// (1–100 characters after trim).
  final ValueChanged<String>? onLookupRequested;

  /// When set (auto-translate active), shows an inline refresh control on the
  /// secondary translation line.
  final VoidCallback? onRetranslateSecondary;

  final VoidCallback onTap;

  /// Lyric-style focus: rest this cue slightly dimmed unless it is active,
  /// in the echo region, or hovered. Set by lists while a cue is playing.
  final bool dimWhenInactive;

  @override
  ConsumerState<TranscriptLineTile> createState() => _TranscriptLineTileState();
}

class _TranscriptLineTileState extends ConsumerState<TranscriptLineTile> {
  final _hover = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  void _handleTap(BuildContext context) {
    Haptics.selection(context);
    if (ref.read(transcriptBlurModeProvider)) {
      ref
          .read(tapRevealHoldCtrlProvider(widget.mediaId).notifier)
          .setHold(
            cueId: cueIdFor(widget.line),
            holdSeconds: kTapRevealHoldSeconds,
          );
    }
    widget.onTap();
  }

  /// Reveal-only tap for selectable (active / echo) cues: starts the
  /// tap-reveal hold without seeking, since selectable cues disable
  /// tap-to-seek. No-op when blur practice is off.
  void _revealHoldOnly() {
    if (!ref.read(transcriptBlurModeProvider)) return;
    ref
        .read(tapRevealHoldCtrlProvider(widget.mediaId).notifier)
        .setHold(
          cueId: cueIdFor(widget.line),
          holdSeconds: kTapRevealHoldSeconds,
        );
  }

  bool _cueRevealed() {
    if (!ref.read(transcriptBlurModeProvider)) return true;
    if (_hover.value) return true;
    return ref.read(
      transcriptCueRevealProvider(widget.mediaId, cueIdFor(widget.line)),
    );
  }

  void _onIpaTap(int wordIndex) {
    if (!_cueRevealed()) return;
    if (wordMediaWindowMs(widget.line, wordIndex) == null) return;
    Haptics.selection(context);
    unawaited(
      ref
          .read(playerInteractionsProvider)
          .seekToWord(widget.line, widget.lineIndex, wordIndex),
    );
  }

  void _setHoverSafe(bool value) {
    runOutsideMouseTrackerIfMounted(
      () => mounted,
      () => setValueNotifierOutsideMouseTracker(_hover, value),
    );
  }

  @override
  Widget build(BuildContext context) {
    transcriptTileBuildCount++;
    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);
    final typography = TranscriptTypographyTokens.of(context);
    final metrics = TranscriptLensMetrics.of(context);
    final loopActive = widget.groupedInEcho && widget.loopFontSize != null;
    final lensDistance = widget.lensDistance.clamp(0, 3);
    final inLens = lensDistance > 0 && !loopActive;
    final defaultFg = scheme.onSurface;

    final timestampText = formatTranscriptTimestampMs(widget.line.startMs);
    final timestampStyle = typography.timestampStyle.copyWith(
      fontSize: metrics.timeFontSize,
      height: 1,
      color: widget.isActive && !inLens ? tok.originalInk : null,
    );

    final primaryPlain = transcriptPlainForSelection(widget.line.text);

    final overlayOn = ref.watch(ipaOverlaySettingsProvider).value == true;
    final words = widget.line.timeline;
    final useAligned =
        overlayOn &&
        !inLens &&
        transcriptWordsHavePhones(words) &&
        words != null;

    WordTextRange? karaokeRange;
    int? karaokeWordIndex;
    if (widget.isActive) {
      karaokeWordIndex = ref
          .watch(transcriptPlaybackHighlightProvider(widget.mediaId))
          .wordIndex;
      if (!useAligned && karaokeWordIndex != null) {
        karaokeRange = wordHighlightRange(
          primaryPlain,
          widget.line.timeline,
          karaokeWordIndex,
        );
      }
    }
    final karaokeFill = karaokeRange == null ? null : tok.original;

    final blurEnabled = ref.watch(transcriptBlurModeProvider);
    final cueId = cueIdFor(widget.line);
    final providerRevealed = ref.watch(
      transcriptCueRevealProvider(widget.mediaId, cueId),
    );

    final resolvedSecondaryText = inLens ? null : widget.secondaryText;

    return ValueListenableBuilder<bool>(
      valueListenable: _hover,
      builder: (context, hover, _) {
        final isRevealed = !blurEnabled || hover || providerRevealed;
        final focused =
            !widget.dimWhenInactive ||
            widget.isActive ||
            widget.inEcho ||
            hover;
        final lineFg = inLens
            ? (hover ? defaultFg : tok.ink3)
            : focused
            ? defaultFg
            : tok.ink3;

        return TranscriptTileChrome(
          timestampText: timestampText,
          timestampStyle: timestampStyle,
          primaryPlain: primaryPlain,
          isActive: widget.isActive,
          inEcho: widget.inEcho,
          groupedInEcho: widget.groupedInEcho,
          inLens: inLens,
          lensDistance: lensDistance,
          selectable: widget.selectable,
          hover: hover,
          recordingCount: widget.recordingCount,
          onTap: () => _handleTap(context),
          onLongPress: isMobilePlatform ? _revealHoldOnly : null,
          onHoverChanged: _setHoverSafe,
          child: TranscriptTileText(
            line: widget.line,
            primaryPlain: primaryPlain,
            secondaryText: resolvedSecondaryText,
            lineFg: lineFg,
            isActive: widget.isActive,
            selectable: widget.selectable,
            useAligned: useAligned,
            isRevealed: isRevealed,
            loopActive: loopActive,
            inLens: inLens,
            lensDistance: lensDistance,
            loopFontSize: widget.loopFontSize,
            karaokeRange: karaokeRange,
            karaokeFill: karaokeFill,
            karaokeWordIndex: karaokeWordIndex,
            wavyWordIndexes: widget.wavyWordIndexes,
            onIpaTap: _onIpaTap,
            onRevealHoldOnly: _revealHoldOnly,
            onLookupRequested: widget.onLookupRequested,
            onRetranslateSecondary: widget.onRetranslateSecondary,
          ),
        );
      },
    );
  }
}
