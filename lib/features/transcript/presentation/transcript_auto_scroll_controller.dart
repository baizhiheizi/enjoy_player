/// Auto-follow scroll engine for the scrollable transcript list: keeps the
/// active cue — or the echo region while echo mode is on — inside the
/// viewport, and stays out of the way while the user scrolls manually.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/platform/mobile_platform.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/transcript/application/echo_region_bounds.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';

/// Viewport alignment used by [Scrollable.ensureVisible] and the bootstrap
/// jump estimate so the active cue sits roughly 42 % from the top of the list.
const double kTranscriptScrollAlignment = 0.42;

/// Fraction of the viewport height subtracted from the jump estimate to avoid
/// overshoot when the active cue is bootstrapped via raw line index (single-line
/// tile height) rather than the actual widget height.
const double kTranscriptScrollEstimateFactor = 0.85;

/// Owns the [ScrollController] and the follow logic for one
/// [TranscriptScrollableList] element lifetime. Host access is injected as
/// accessors so every read resolves the host's current value.
final class TranscriptAutoScrollController {
  TranscriptAutoScrollController({
    required this.isMounted,
    required this.ref,
    required this.context,
    required this.mediaId,
    required this.lineCount,
  });

  final bool Function() isMounted;
  final WidgetRef Function() ref;
  final BuildContext Function() context;
  final String Function() mediaId;
  final int Function() lineCount;

  final ScrollController _scrollController = ScrollController();
  int _lastScrolledIndex = -1;
  int _lastEchoScrollStart = -999;
  int _lastEchoScrollEnd = -999;

  /// Bumped on each scroll request and in [dispose] to drop stale callbacks.
  int _scrollGeneration = 0;

  /// Scroll-target keys are rotated when the target line/echo bounds change so
  /// the same [GlobalKey] is never reparented across [ListView] slots.
  GlobalKey? _echoRegionScrollKey;
  (int start, int end)? _echoRegionScrollKeyBounds;
  GlobalKey? _activeLineScrollKey;
  int _activeLineScrollKeyIndex = -1;

  /// When true, the user is manually scrolling and auto-follow should not
  /// force-scroll the viewport back to the active cue.
  bool _suppressAutoScroll = false;

  ScrollController get scrollController => _scrollController;

  void dispose() {
    _scrollGeneration++;
    _scrollController.dispose();
  }

  /// Drops follow dedup state and scroll-target keys when the host list is
  /// repurposed for a different media item.
  void resetForMediaChange() {
    _lastScrolledIndex = -1;
    _lastEchoScrollStart = -999;
    _lastEchoScrollEnd = -999;
    _scrollGeneration++;
    _resetScrollTargetKeys();
  }

  /// Re-enables auto-follow after the user manually scrolled away.
  void resumeAutoFollow() {
    _suppressAutoScroll = false;
  }

  GlobalKey scrollKeyForEcho(EchoState echo) {
    final bounds = (echo.startLineIndex, echo.endLineIndex);
    if (_echoRegionScrollKeyBounds != bounds) {
      _echoRegionScrollKeyBounds = bounds;
      _echoRegionScrollKey = GlobalKey();
    }
    return _echoRegionScrollKey!;
  }

  GlobalKey scrollKeyForActiveLine(int lineIndex) {
    if (_activeLineScrollKeyIndex != lineIndex) {
      _activeLineScrollKeyIndex = lineIndex;
      _activeLineScrollKey = GlobalKey();
    }
    return _activeLineScrollKey!;
  }

  /// Estimated cue index at the current scroll offset (manual scroll focus).
  int scrollFocusLineIndex() {
    final lineCount = this.lineCount();
    if (lineCount <= 0) return 0;
    if (!_scrollController.hasClients) return 0;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return 0;
    final ratio = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
    return (ratio * (lineCount - 1)).round();
  }

  bool handleScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isMounted()) return;
          final activeIdx = ref()
              .read(transcriptPlaybackHighlightProvider(mediaId()))
              .cueIndex;
          if (!_isActiveCueVisible(activeIdx)) {
            _suppressAutoScroll = false;
          }
        });
      } else {
        _suppressAutoScroll = true;
      }
    }
    return false;
  }

  void scheduleScrollIntoView({bool force = false}) {
    final playingAsync = ref().read(playerIsPlayingProvider);
    final playing = switch (playingAsync) {
      AsyncData(:final value) => value,
      _ => false,
    };
    if (!playing) return;

    final echo =
        activeEchoForTranscript(ref().read(echoModeProvider), lineCount()) ??
        EchoState.inactive;
    final activeForUi = ref()
        .read(transcriptPlaybackHighlightProvider(mediaId()))
        .cueIndex;

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

    if (force && _suppressAutoScroll) return;

    _scrollGeneration++;
    final generation = _scrollGeneration;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted() || generation != _scrollGeneration) return;
      _performTranscriptScroll(generation: generation);
    });
  }

  /// Whether the active cue line is roughly within the visible viewport.
  bool _isActiveCueVisible(int activeLineIndex) {
    if (!_scrollController.hasClients) return true;
    final focus = scrollFocusLineIndex();
    return (activeLineIndex - focus).abs() <= 2;
  }

  /// Conservative bootstrap scroll before the scroll-target widget is built.
  ///
  /// Uses raw line index (single-line tile height) so tall echo cards do not
  /// inflate the estimate and overshoot off-screen.
  void _jumpToLineIndexEstimate(int lineIndex, {required double alignment}) {
    if (!_scrollController.hasClients || lineIndex < 0) return;

    final lineCount = this.lineCount();
    if (lineCount <= 0) return;

    final pos = _scrollController.position;
    final ratio = lineIndex / lineCount;
    final estimated = ratio * pos.maxScrollExtent;
    final alignmentAdjust =
        alignment * pos.viewportDimension * kTranscriptScrollEstimateFactor;
    _scrollController.jumpTo(
      (estimated - alignmentAdjust).clamp(0.0, pos.maxScrollExtent),
    );
  }

  void _ensureVisible(
    BuildContext ctx, {
    required double alignment,
    required Duration duration,
    required Curve curve,
    required int generation,
  }) {
    if (!isMounted() || generation != _scrollGeneration) return;
    try {
      unawaited(
        Scrollable.ensureVisible(
          ctx,
          alignment: alignment,
          duration: duration,
          curve: curve,
        ),
      );
    } catch (_) {}
  }

  /// Scrolls [key] into view now when built, otherwise bootstraps with a
  /// line-index estimate and retries once on the next frame.
  void _ensureTargetVisible(
    GlobalKey key, {
    required int estimateLineIndex,
    required double alignment,
    required Duration duration,
    required int generation,
  }) {
    final ctx = key.currentContext;
    if (ctx != null) {
      _ensureVisible(
        ctx,
        alignment: alignment,
        duration: duration,
        curve: Curves.easeOutCubic,
        generation: generation,
      );
      return;
    }

    _jumpToLineIndexEstimate(estimateLineIndex, alignment: alignment);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted() || generation != _scrollGeneration) return;
      final ctx2 = key.currentContext;
      if (ctx2 == null) return;
      _ensureVisible(
        ctx2,
        alignment: alignment,
        duration: duration,
        curve: Curves.easeOutCubic,
        generation: generation,
      );
    });
  }

  void _performTranscriptScroll({required int generation}) {
    if (!isMounted() || generation != _scrollGeneration) return;

    final echo =
        activeEchoForTranscript(ref().read(echoModeProvider), lineCount()) ??
        EchoState.inactive;
    final duration = EnjoyThemeTokens.of(context()).motionStandard;

    if (echo.active) {
      // Phone boards park the loop in the upper third (context above, takes
      // below); desktop parks it at the top.
      _ensureTargetVisible(
        scrollKeyForEcho(echo),
        estimateLineIndex: echo.startLineIndex,
        alignment: isMobilePlatform ? 0.18 : 0.0,
        duration: duration,
        generation: generation,
      );
      return;
    }

    final active = ref()
        .read(transcriptPlaybackHighlightProvider(mediaId()))
        .cueIndex;
    if (active < 0) return;

    _ensureTargetVisible(
      scrollKeyForActiveLine(active),
      estimateLineIndex: active,
      alignment: kTranscriptScrollAlignment,
      duration: duration,
      generation: generation,
    );
  }

  void _resetScrollTargetKeys() {
    _echoRegionScrollKey = null;
    _echoRegionScrollKeyBounds = null;
    _activeLineScrollKey = null;
    _activeLineScrollKeyIndex = -1;
  }
}
