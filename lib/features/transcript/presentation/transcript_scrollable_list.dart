/// Scrollable transcript list with auto-scroll (active cue, or echo block in echo mode).
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';

import 'package:enjoy_player/core/transcript/transcript_density.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/transcript/application/active_transcript_provider.dart';
import 'package:enjoy_player/features/transcript/application/auto_translate_controller.dart';
import 'package:enjoy_player/features/transcript/application/echo_region_bounds.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_alignment.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_recording_counts_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_virtual_items.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_auto_scroll_controller.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_item_builder.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Off-screen pre-build window for the transcript list (px above + below the
/// viewport).
const double kTranscriptScrollCacheExtentPx = 1400;

/// Shrunk pre-build window while blur practice mode is on (issue #810 G):
/// every cached blurred cue is a GPU saveLayer, and cached blurred text is
/// unreadable until revealed anyway.
const double kTranscriptBlurPracticeCacheExtentPx = 200;

class TranscriptScrollableList extends ConsumerStatefulWidget {
  const TranscriptScrollableList({
    required this.mediaId,
    required this.lines,
    super.key,
  });

  final String mediaId;
  final List<TranscriptLine> lines;

  @override
  ConsumerState<TranscriptScrollableList> createState() =>
      _TranscriptScrollableListState();
}

class _TranscriptScrollableListState
    extends ConsumerState<TranscriptScrollableList> {
  late final TranscriptAutoScrollController _autoScroll =
      TranscriptAutoScrollController(
        isMounted: () => mounted,
        ref: () => ref,
        context: () => context,
        mediaId: () => widget.mediaId,
        lineCount: () => widget.lines.length,
      );

  List<TranscriptVirtualItem> _cachedVirtualItems = const [];
  List<TranscriptLine>? _cachedLinesRef;
  EchoState? _cachedEchoForItems;

  TranscriptSecondaryMatcher? _secondaryMatcher;
  List<TranscriptLine>? _cachedSecondaryRef;

  @override
  void dispose() {
    _autoScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TranscriptScrollableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) {
      _autoScroll.resetForMediaChange();
      _cachedVirtualItems = const [];
      _cachedLinesRef = null;
      _cachedEchoForItems = null;
      _secondaryMatcher = null;
      _cachedSecondaryRef = null;
    }
  }

  List<TranscriptVirtualItem> _virtualItems(EchoState echo) {
    if (!identical(widget.lines, _cachedLinesRef) ||
        _cachedEchoForItems == null ||
        _cachedEchoForItems! != echo) {
      _cachedLinesRef = widget.lines;
      _cachedEchoForItems = echo;
      _cachedVirtualItems = buildTranscriptVirtualItems(widget.lines, echo);
    }
    return _cachedVirtualItems;
  }

  TranscriptSecondaryMatcher _matcherFor(List<TranscriptLine> secondary) {
    if (!identical(secondary, _cachedSecondaryRef) ||
        _secondaryMatcher == null) {
      _cachedSecondaryRef = secondary;
      _secondaryMatcher = TranscriptSecondaryMatcher.from(secondary);
    }
    return _secondaryMatcher!;
  }

  @override
  Widget build(BuildContext context) {
    final echo =
        activeEchoForTranscript(
          ref.watch(echoModeProvider),
          widget.lines.length,
        ) ??
        EchoState.inactive;
    final recordingTake = ref.watch(
      shadowReadingHotkeyBusProvider.select((b) => b.isRecordingActive),
    );
    final activeForUi = ref.watch(
      transcriptPlaybackHighlightProvider(
        widget.mediaId,
      ).select((h) => h.cueIndex),
    );
    final density = transcriptDensityOf(context);
    final secondaryAsync = ref.watch(
      secondaryTranscriptLinesForMediaProvider(widget.mediaId),
    );
    final secondaryLines = secondaryAsync.value ?? <TranscriptLine>[];
    final secondaryMatcher = _matcherFor(secondaryLines);
    final autoTranslateMode = ref.watch(
      autoTranslateCtrlProvider(widget.mediaId).select(
        (s) => (
          isActive: s.isActive,
          aiTranscriptId: s.aiTranscriptId,
          sourceLanguage: s.sourceLanguage,
          targetLanguage: s.targetLanguage,
        ),
      ),
    );
    final secondaryId = ref
        .watch(secondaryTranscriptIdProvider(widget.mediaId))
        .value;
    final autoTranslateActive =
        autoTranslateMode.isActive &&
        autoTranslateMode.aiTranscriptId != null &&
        secondaryId == autoTranslateMode.aiTranscriptId;
    final l10n = AppLocalizations.of(context);
    final blurPractice = ref.watch(transcriptBlurModeProvider);
    final items = _virtualItems(echo);
    final lineRecordingCounts = ref.watch(
      transcriptLineRecordingCountsProvider(widget.mediaId),
    );

    final autoTranslateCtrl = ref.read(
      autoTranslateCtrlProvider(widget.mediaId),
    );

    final scope = TranscriptListItemScope(
      ref: ref,
      scroll: _autoScroll,
      mediaId: widget.mediaId,
      lines: widget.lines,
      echo: echo,
      activeCueIndex: activeForUi,
      recordingTake: recordingTake,
      secondaryLines: secondaryLines,
      secondaryMatcher: secondaryMatcher,
      autoTranslateActive: autoTranslateActive,
      sourceLanguage: autoTranslateMode.sourceLanguage,
      targetLanguage: autoTranslateMode.targetLanguage,
      autoTranslateCtrl: autoTranslateCtrl,
      l10n: l10n,
      lineRecordingCounts: lineRecordingCounts,
      density: density,
    );

    ref.listen(
      transcriptPlaybackHighlightProvider(
        widget.mediaId,
      ).select((h) => h.cueIndex),
      (prev, next) {
        if (prev == next) return;
        final echoNow = ref.read(echoModeProvider);
        if (echoNow.active &&
            (next < echoNow.startLineIndex || next > echoNow.endLineIndex)) {
          return;
        }
        if (prev == null || (next - prev).abs() > 1) {
          _autoScroll.resumeAutoFollow();
        }
        _autoScroll.scheduleScrollIntoView(force: true);
      },
    );
    ref.listen(playerIsPlayingProvider, (_, _) {
      _autoScroll.scheduleScrollIntoView(force: true);
    });
    ref.listen(
      echoModeProvider.select(
        (e) => (e.active, e.startLineIndex, e.endLineIndex),
      ),
      (prev, next) {
        if (prev == next) return;
        _autoScroll.resumeAutoFollow();
        _autoScroll.scheduleScrollIntoView(force: true);
      },
    );

    return Semantics(
      explicitChildNodes: true,
      label:
          AppLocalizations.of(context)?.transcriptAccessibilityTranscriptList ??
          'Transcript',
      child: NotificationListener<ScrollNotification>(
        onNotification: _autoScroll.handleScrollNotification,
        child: ListView.builder(
          scrollCacheExtent: ScrollCacheExtent.pixels(
            blurPractice
                ? kTranscriptBlurPracticeCacheExtentPx
                : kTranscriptScrollCacheExtentPx,
          ),
          controller: _autoScroll.scrollController,
          padding: EdgeInsets.fromLTRB(
            density.listHorizontalPadding,
            density.listVerticalPadding,
            density.listHorizontalPadding,
            density.listVerticalPadding + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              buildTranscriptListItem(context, scope, items[index]),
        ),
      ),
    );
  }
}
