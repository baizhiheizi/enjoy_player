/// Scrollable transcript list with auto-scroll (active cue, or echo block in echo mode).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_alignment.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/features/lookup/application/transcript_lookup_open.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_echo_region_merged_card.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';

sealed class _TranscriptVirtualItem {
  const _TranscriptVirtualItem();
}

class _VirtualEcho extends _TranscriptVirtualItem {
  const _VirtualEcho(this.startLineIndex, this.endLineIndex);
  final int startLineIndex;
  final int endLineIndex;
}

class _VirtualLine extends _TranscriptVirtualItem {
  const _VirtualLine(this.lineIndex);
  final int lineIndex;
}

List<_TranscriptVirtualItem> _buildVirtualItems(
  List<TranscriptLine> lines,
  EchoState echo,
) {
  final out = <_TranscriptVirtualItem>[];
  var i = 0;
  while (i < lines.length) {
    if (echo.active && i == echo.startLineIndex) {
      out.add(_VirtualEcho(echo.startLineIndex, echo.endLineIndex));
      i = echo.endLineIndex + 1;
      continue;
    }
    out.add(_VirtualLine(i));
    i++;
  }
  return out;
}

bool _echoLayoutEqual(EchoState a, EchoState b) {
  return a.active == b.active &&
      a.startLineIndex == b.startLineIndex &&
      a.endLineIndex == b.endLineIndex;
}

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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activeLineKey = GlobalKey();
  final GlobalKey _echoRegionKey = GlobalKey();
  int _lastScrolledIndex = -1;
  int _lastEchoScrollStart = -999;
  int _lastEchoScrollEnd = -999;

  List<_TranscriptVirtualItem> _cachedVirtualItems = const [];
  List<TranscriptLine>? _cachedLinesRef;
  EchoState? _cachedEchoForItems;

  TranscriptSecondaryMatcher? _secondaryMatcher;
  List<TranscriptLine>? _cachedSecondaryRef;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TranscriptScrollableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) {
      _lastScrolledIndex = -1;
      _lastEchoScrollStart = -999;
      _lastEchoScrollEnd = -999;
      _cachedVirtualItems = const [];
      _cachedLinesRef = null;
      _cachedEchoForItems = null;
      _secondaryMatcher = null;
      _cachedSecondaryRef = null;
    }
  }

  List<_TranscriptVirtualItem> _virtualItems(EchoState echo) {
    if (!identical(widget.lines, _cachedLinesRef) ||
        _cachedEchoForItems == null ||
        !_echoLayoutEqual(echo, _cachedEchoForItems!)) {
      _cachedLinesRef = widget.lines;
      _cachedEchoForItems = echo;
      _cachedVirtualItems = _buildVirtualItems(widget.lines, echo);
    }
    return _cachedVirtualItems;
  }

  TranscriptSecondaryMatcher _matcherFor(List<TranscriptLine> secondary) {
    if (!identical(secondary, _cachedSecondaryRef) || _secondaryMatcher == null) {
      _cachedSecondaryRef = secondary;
      _secondaryMatcher = TranscriptSecondaryMatcher.from(secondary);
    }
    return _secondaryMatcher!;
  }

  void _scheduleTranscriptScrollIntoView({bool force = false}) {
    final playingAsync = ref.read(playerIsPlayingProvider);
    final playing = switch (playingAsync) {
      AsyncData(:final value) => value,
      _ => false,
    };
    if (!playing) return;

    final echo = ref.read(echoModeProvider);
    final activeForUi = ref.read(
      transcriptPlaybackHighlightProvider(widget.mediaId),
    );

    if (echo.active) {
      if (!force &&
          echo.startLineIndex == _lastEchoScrollStart &&
          echo.endLineIndex == _lastEchoScrollEnd) {
        return;
      }
      _lastEchoScrollStart = echo.startLineIndex;
      _lastEchoScrollEnd = echo.endLineIndex;
    } else {
      if (activeForUi < 0) return;
      if (!force && activeForUi == _lastScrolledIndex) return;
      _lastScrolledIndex = activeForUi;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final echoNow = ref.read(echoModeProvider);
      final tok = EnjoyThemeTokens.of(context);

      if (echoNow.active) {
        final ctx = _echoRegionKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.0,
            duration: tok.motionStandard,
            curve: Curves.easeOutCubic,
          );
          return;
        }

        if (!_scrollController.hasClients) return;
        final pos = _scrollController.position;
        final items = _virtualItems(echoNow);
        final len = items.length;
        final echoItemIndex = items.indexWhere(
          (e) => e is _VirtualEcho && e.startLineIndex == echoNow.startLineIndex,
        );
        final ratio = len > 0 && echoItemIndex >= 0 ? echoItemIndex / len : 0.0;
        final estimated = ratio * pos.maxScrollExtent;
        _scrollController.jumpTo(estimated.clamp(0.0, pos.maxScrollExtent));

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final ctx2 = _echoRegionKey.currentContext;
          if (ctx2 == null) return;
          Scrollable.ensureVisible(
            ctx2,
            alignment: 0.0,
            duration: tok.motionStandard,
            curve: Curves.easeOutCubic,
          );
        });
        return;
      }

      final active = ref.read(
        transcriptPlaybackHighlightProvider(widget.mediaId),
      );
      if (active < 0) return;

      final ctx = _activeLineKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.42,
          duration: tok.motionStandard,
          curve: Curves.easeOutCubic,
        );
        return;
      }

      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      final items = _virtualItems(echoNow);
      final len = items.length;
      final lineItemIndex = items.indexWhere(
        (e) => e is _VirtualLine && e.lineIndex == active,
      );
      final ratio = len > 0 && lineItemIndex >= 0 ? lineItemIndex / len : 0.0;
      final estimated = ratio * pos.maxScrollExtent;
      _scrollController.jumpTo(estimated.clamp(0.0, pos.maxScrollExtent));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx2 = _activeLineKey.currentContext;
        if (ctx2 == null) return;
        Scrollable.ensureVisible(
          ctx2,
          alignment: 0.42,
          duration: tok.motionStandard,
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final echo = ref.watch(echoModeProvider);
    final activeForUi = ref.watch(
      transcriptPlaybackHighlightProvider(widget.mediaId).select((i) => i),
    );
    final tok = EnjoyThemeTokens.of(context);
    final secondaryAsync = ref.watch(
      secondaryTranscriptLinesForMediaProvider(widget.mediaId),
    );
    final secondaryLines = secondaryAsync.value ?? <TranscriptLine>[];
    final secondaryMatcher = _matcherFor(secondaryLines);
    final items = _virtualItems(echo);

    ref.listen(transcriptPlaybackHighlightProvider(widget.mediaId), (
      prev,
      next,
    ) {
      if (prev == next) return;
      _scheduleTranscriptScrollIntoView(force: true);
    });
    ref.listen(playerIsPlayingProvider, (_, _) {
      _scheduleTranscriptScrollIntoView(force: true);
    });
    ref.listen(
      echoModeProvider.select(
        (e) => (e.active, e.startLineIndex, e.endLineIndex),
      ),
      (prev, next) {
        if (prev == next) return;
        _scheduleTranscriptScrollIntoView(force: true);
      },
    );

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: tok.space12,
        vertical: tok.space8,
      ),
      // Keep active cue / echo card buildable for [GlobalKey] + ensureVisible.
      cacheExtent: 1400,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        switch (item) {
          case _VirtualEcho e:
            return Padding(
              key: ValueKey<String>('echo-${e.startLineIndex}-${e.endLineIndex}'),
              padding: EdgeInsets.only(bottom: tok.space8),
              child: KeyedSubtree(
                key: _echoRegionKey,
                child: EchoRegionMergedCard(
                  mediaId: widget.mediaId,
                  lines: widget.lines,
                  echo: echo,
                  activeCueIndex: activeForUi,
                  secondaryLines: secondaryLines,
                  secondaryMatcher: secondaryMatcher,
                ),
              ),
            );
          case _VirtualLine vl:
            final lineIndex = vl.lineIndex;
            final line = widget.lines[lineIndex];
            final isActive = lineIndex == activeForUi;
            final inEcho =
                echo.active &&
                lineIndex >= echo.startLineIndex &&
                lineIndex <= echo.endLineIndex;
            final secondaryText = secondaryMatcher.match(line)?.text;

            final selectable = isActive || inEcho;
            Widget tile = TranscriptLineTile(
              line: line,
              secondaryText: secondaryText,
              isActive: isActive,
              inEcho: inEcho,
              groupedInEcho: false,
              selectable: selectable,
              onLookupRequested: selectable
                  ? (t) => openTranscriptLookup(
                      ref: ref,
                      context: context,
                      selectedText: t,
                      lines: widget.lines,
                    )
                  : null,
              onTap: () => ref
                  .read(playerInteractionsProvider.notifier)
                  .seekToLine(line, lineIndex),
            );

            if (isActive) {
              tile = KeyedSubtree(key: _activeLineKey, child: tile);
            }

            return Padding(
              key: ValueKey<String>('line-$lineIndex'),
              padding: EdgeInsets.only(bottom: tok.space8),
              child: tile,
            );
        }
      },
    );
  }
}
