/// Sentence ruler (ADR-0093) — the dock's seek bar: original played track on
/// sunk, a tick per transcript line, the Echo loop bracket in you, practiced
/// dots over lines with takes, mono times, and an original thumb ring.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/interaction/mouse_tracker_safe.dart';
import 'package:enjoy_player/core/platform/mobile_platform.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_recording_counts_provider.dart';
import 'package:enjoy_player/features/player/application/position_buckets.dart';
import 'package:enjoy_player/features/player/application/transport_slider_position_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';

/// The dock's ruler row: mono elapsed · track · mono total, hit height 34.
class SentenceRuler extends ConsumerStatefulWidget {
  const SentenceRuler({required this.chrome, super.key});

  final PlaybackChrome chrome;

  @override
  ConsumerState<SentenceRuler> createState() => _SentenceRulerState();
}

class _SentenceRulerState extends ConsumerState<SentenceRuler> {
  double? _dragFraction;
  double? _pendingSeekFraction;
  static const Duration _pendingSeekHold = Duration(milliseconds: 1500);
  Timer? _pendingSeekTimer;
  bool _hovered = false;
  int? _scrubSecond;

  bool get _hapticScrub => isMobilePlatform;

  bool _streamCaughtUp(Duration pos, double durationSec) {
    final pending = _pendingSeekFraction;
    if (pending == null) return false;
    final targetMs = (pending * durationSec * 1000).round();
    return (pos.inMilliseconds - targetMs).abs() <= kPositionBucketScrubberMs;
  }

  void _holdPendingSeek(double fraction) {
    _pendingSeekFraction = fraction;
    _pendingSeekTimer?.cancel();
    _pendingSeekTimer = Timer(_pendingSeekHold, _releasePendingSeek);
  }

  void _releasePendingSeek() {
    _pendingSeekTimer?.cancel();
    _pendingSeekTimer = null;
    if (!mounted || _pendingSeekFraction == null) return;
    setState(() => _pendingSeekFraction = null);
  }

  @override
  void dispose() {
    _pendingSeekTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final durationSec = widget.chrome.durationSeconds > 0
        ? widget.chrome.durationSeconds
        : 1.0;

    final posAsync = ref.watch(transportSliderPositionProvider);
    final pos = switch (posAsync) {
      AsyncData(:final value) => value,
      _ => Duration.zero,
    };
    final streamFraction = durationSec > 0
        ? pos.inMilliseconds / 1000 / durationSec
        : 0.0;
    final holdFraction = _dragFraction ?? _pendingSeekFraction;
    final fraction = holdFraction ?? streamFraction.clamp(0.0, 1.0);

    if (_streamCaughtUp(pos, durationSec)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _releasePendingSeek();
      });
    }

    final lines =
        ref
            .watch(transcriptLinesForMediaProvider(widget.chrome.mediaId))
            .value ??
        const <TranscriptLine>[];
    final echo = ref.watch(echoModeProvider);
    final practicedCounts =
        ref.watch(
          transcriptLineRecordingCountsProvider(widget.chrome.mediaId),
        ) ??
        const <int, int>{};

    final timeStyle = enjoyMonoStyle(context, size: 12.5, color: t.ink3);

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: SizedBox(
        height: t.rulerHitHeight,
        child: Row(
          children: [
            Text(
              formatDurationHms(
                holdFraction != null
                    ? Duration(
                        milliseconds: (holdFraction * durationSec * 1000)
                            .round(),
                      )
                    : pos,
              ),
              style: timeStyle,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _seekTo(
                  (details.localPosition.dx / constraintsForWidth(context))
                      .clamp(0.0, 1.0),
                ),
                onHorizontalDragStart: (details) => _startDrag(
                  (details.localPosition.dx / constraintsForWidth(context))
                      .clamp(0.0, 1.0),
                ),
                onHorizontalDragUpdate: (details) => _updateDrag(
                  (details.localPosition.dx / constraintsForWidth(context))
                      .clamp(0.0, 1.0),
                ),
                onHorizontalDragEnd: (_) => _endDrag(),
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size.fromHeight(t.rulerHitHeight),
                    painter: SentenceRulerPainter(
                      tokens: t,
                      fraction: fraction.clamp(0.0, 1.0),
                      durationSec: durationSec,
                      lineStartFractions: [
                        for (final line in lines)
                          (line.startMs / 1000 / durationSec).clamp(0.0, 1.0),
                      ],
                      practicedLineIndexes: [
                        for (final entry in practicedCounts.keys) entry,
                      ],
                      loopStart: echo.active
                          ? (echo.startTimeSeconds / durationSec).clamp(
                              0.0,
                              1.0,
                            )
                          : null,
                      loopEnd: echo.active
                          ? (echo.endTimeSeconds / durationSec).clamp(0.0, 1.0)
                          : null,
                      hovered: _hovered,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(formatDurationHmsSeconds(durationSec), style: timeStyle),
          ],
        ),
      ),
    );
  }

  double constraintsForWidth(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    return box.size.width.clamp(1.0, double.infinity);
  }

  void _seekTo(double fraction) {
    unawaited(
      ref.read(playerInteractionsProvider).seekToProgressFraction(fraction),
    );
  }

  void _startDrag(double fraction) {
    _scrubSecond = null;
    _pendingSeekTimer?.cancel();
    _pendingSeekFraction = null;
    setState(() => _dragFraction = fraction);
  }

  void _updateDrag(double fraction) {
    if (_hapticScrub) {
      final sec = (fraction * widget.chrome.durationSeconds).floor();
      if (_scrubSecond != sec) {
        _scrubSecond = sec;
        Haptics.selection(context);
      }
    }
    setState(() => _dragFraction = fraction);
  }

  void _endDrag() {
    final fraction = _dragFraction;
    if (fraction == null) return;
    setState(() {
      _dragFraction = null;
      _holdPendingSeek(fraction);
    });
    _seekTo(fraction);
  }

  void _setHovered(bool v) {
    if (_hovered == v) return;
    runOutsideMouseTrackerIfMounted(() => mounted, () {
      if (_hovered == v) return;
      setState(() => _hovered = v);
    });
  }
}

/// One CustomPainter for the whole ruler; tick and dot positions arrive
/// precomputed so a repaint only walks cached lists.
class SentenceRulerPainter extends CustomPainter {
  SentenceRulerPainter({
    required this.tokens,
    required this.fraction,
    required this.durationSec,
    required this.lineStartFractions,
    required this.practicedLineIndexes,
    required this.loopStart,
    required this.loopEnd,
    required this.hovered,
  });

  final EnjoyThemeTokens tokens;
  final double fraction;
  final double durationSec;
  final List<double> lineStartFractions;
  final List<int> practicedLineIndexes;
  final double? loopStart;
  final double? loopEnd;
  final bool hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final t = tokens;
    final trackTop = size.height / 2 - t.strokeRulerTrack / 2;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, trackTop, size.width, t.strokeRulerTrack),
      const Radius.circular(2),
    );
    canvas.drawRRect(trackRect, Paint()..color = t.sunk);

    final playedWidth = size.width * fraction;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, trackTop, playedWidth, t.strokeRulerTrack),
        const Radius.circular(2),
      ),
      Paint()..color = t.original,
    );

    final tickPaint = Paint()
      ..color = t.tick
      ..strokeWidth = 1;
    for (final f in lineStartFractions) {
      final x = size.width * f;
      canvas.drawLine(
        Offset(x, trackTop - 4),
        Offset(x, trackTop + t.strokeRulerTrack + 4),
        tickPaint,
      );
    }

    if (loopStart != null && loopEnd != null) {
      final x0 = size.width * loopStart!.clamp(0.0, 1.0);
      final x1 = size.width * loopEnd!.clamp(0.0, 1.0);
      if (x1 > x0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x0, trackTop, x1 - x0, t.strokeRulerTrack),
            const Radius.circular(2),
          ),
          Paint()..color = t.you.withValues(alpha: 0.18),
        );
        const bracketHeight = 7;
        final bracketPaint = Paint()
          ..color = t.you
          ..style = PaintingStyle.stroke
          ..strokeWidth = t.strokeLoopBracket
          ..strokeCap = StrokeCap.round;
        final path = Path()
          ..moveTo(x0, trackTop - 2)
          ..lineTo(x0, trackTop - 2 - bracketHeight)
          ..lineTo(x1, trackTop - 2 - bracketHeight)
          ..lineTo(x1, trackTop - 2);
        canvas.drawPath(path, bracketPaint);
      }
    }

    final dotPaint = Paint()..color = t.you;
    for (final index in practicedLineIndexes) {
      if (index < 0 || index >= lineStartFractions.length) continue;
      final x = size.width * lineStartFractions[index];
      canvas.drawCircle(Offset(x, trackTop - 8), 2.5, dotPaint);
    }

    final thumbRadius = hovered ? 8.0 : 6.0;
    final thumbCenter = Offset(playedWidth, size.height / 2);
    canvas.drawCircle(thumbCenter, thumbRadius, Paint()..color = t.paper);
    canvas.drawCircle(
      thumbCenter,
      thumbRadius,
      Paint()
        ..color = t.original
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(SentenceRulerPainter old) =>
      old.fraction != fraction ||
      old.durationSec != durationSec ||
      old.hovered != hovered ||
      old.loopStart != loopStart ||
      old.loopEnd != loopEnd ||
      !listEquals(old.lineStartFractions, lineStartFractions) ||
      !listEquals(old.practicedLineIndexes, practicedLineIndexes);
}
