/// Sentence ruler (ADR-0093) — the dock's seek bar: original played track on
/// sunk, a tick per transcript line, the Echo loop bracket in you, practiced
/// dots over lines with takes, mono times, and an original thumb ring.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show Listenable, ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/interaction/mouse_tracker_safe.dart';
import 'package:enjoy_player/core/platform/mobile_platform.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/application/position_buckets.dart';
import 'package:enjoy_player/features/player/application/ruler_geometry.dart';
import 'package:enjoy_player/features/player/application/transport_slider_position_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_recording_counts_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';

/// The dock's ruler row: mono elapsed · track · mono total, hit height 34.
class SentenceRuler extends ConsumerStatefulWidget {
  const SentenceRuler({required this.chrome, super.key});

  final PlaybackChrome chrome;

  @override
  ConsumerState<SentenceRuler> createState() => _SentenceRulerState();
}

class _SentenceRulerState extends ConsumerState<SentenceRuler> {
  static const Duration _pendingSeekHold = Duration(milliseconds: 1500);

  final _fraction = ValueNotifier<double>(0);
  final _hovered = ValueNotifier<bool>(false);
  final _elapsedText = ValueNotifier<String>('0:00');

  double? _dragFraction;
  double? _pendingSeekFraction;
  Timer? _pendingSeekTimer;
  int? _scrubSecond;

  Duration _lastPosition = Duration.zero;
  double _durationSec = 1;
  double _trackWidth = 300;

  RulerGeometry? _geometry;
  List<TranscriptLine>? _geometryLines;
  EchoState? _geometryEcho;
  Map<int, int>? _geometryPracticed;

  bool get _hapticScrub => isMobilePlatform;

  @override
  void initState() {
    super.initState();
    _durationSec = widget.chrome.durationSeconds > 0
        ? widget.chrome.durationSeconds
        : 1.0;
    ref.listenManual(transportSliderPositionProvider, (previous, next) {
      final pos = next.valueOrNull;
      if (pos != null) _onPosition(pos);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _pendingSeekTimer?.cancel();
    _fraction.dispose();
    _hovered.dispose();
    _elapsedText.dispose();
    super.dispose();
  }

  bool _streamCaughtUp(Duration pos) {
    final pending = _pendingSeekFraction;
    if (pending == null) return false;
    final targetMs = (pending * _durationSec * 1000).round();
    return (pos.inMilliseconds - targetMs).abs() <= kPositionBucketScrubberMs;
  }

  void _onPosition(Duration pos) {
    _lastPosition = pos;
    if (_pendingSeekFraction != null && _streamCaughtUp(pos)) {
      _pendingSeekTimer?.cancel();
      _pendingSeekTimer = null;
      _pendingSeekFraction = null;
    }
    _applyFraction();
    _updateElapsedText();
  }

  void _applyFraction() {
    final hold = _dragFraction ?? _pendingSeekFraction;
    if (hold != null) {
      if (_fraction.value != hold) _fraction.value = hold;
      return;
    }
    final raw = (_lastPosition.inMilliseconds / 1000 / _durationSec).clamp(
      0.0,
      1.0,
    );
    final step = 1 / (_trackWidth <= 1 ? 300.0 : _trackWidth);
    final quantized = ((raw / step).round() * step).clamp(0.0, 1.0);
    if (_fraction.value != quantized) _fraction.value = quantized;
  }

  void _updateElapsedText() {
    final hold = _dragFraction ?? _pendingSeekFraction;
    final shown = hold != null
        ? Duration(milliseconds: (hold * _durationSec * 1000).round())
        : _lastPosition;
    final text = formatDurationHms(shown);
    if (text != _elapsedText.value) _elapsedText.value = text;
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
    _pendingSeekFraction = null;
    _applyFraction();
    _updateElapsedText();
  }

  RulerGeometry _geometryFor({
    required List<TranscriptLine> lines,
    required EchoState echo,
    required Map<int, int> practicedCounts,
    required double durationSec,
  }) {
    final cached = _geometry;
    if (cached != null &&
        cached.durationSec == durationSec &&
        identical(lines, _geometryLines) &&
        echo == _geometryEcho &&
        identical(practicedCounts, _geometryPracticed)) {
      return cached;
    }
    final geometry = RulerGeometry.from(
      lines: lines,
      echo: echo,
      practicedCounts: practicedCounts,
      durationSec: durationSec,
    );
    _geometry = geometry;
    _geometryLines = lines;
    _geometryEcho = echo;
    _geometryPracticed = practicedCounts;
    return geometry;
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    _durationSec = widget.chrome.durationSeconds > 0
        ? widget.chrome.durationSeconds
        : 1.0;

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
    final geometry = _geometryFor(
      lines: lines,
      echo: echo,
      practicedCounts: practicedCounts,
      durationSec: _durationSec,
    );

    final timeStyle = enjoyMonoStyle(context, size: 12.5, color: t.ink3);

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: SizedBox(
        height: t.rulerHitHeight,
        child: Row(
          children: [
            ValueListenableBuilder<String>(
              valueListenable: _elapsedText,
              builder: (context, text, _) => Text(text, style: timeStyle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth.clamp(
                    1.0,
                    double.infinity,
                  );
                  _trackWidth = width;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) =>
                        _seekTo((details.localPosition.dx / width).clamp(0, 1)),
                    onHorizontalDragStart: (details) => _startDrag(
                      (details.localPosition.dx / width).clamp(0, 1),
                    ),
                    onHorizontalDragUpdate: (details) => _updateDrag(
                      (details.localPosition.dx / width).clamp(0, 1),
                    ),
                    onHorizontalDragEnd: (_) => _endDrag(),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _RulerProgressPainter(
                            tokens: t,
                            fraction: _fraction,
                          ),
                        ),
                        RepaintBoundary(
                          child: CustomPaint(
                            painter: _RulerTickPainter(
                              tokens: t,
                              geometry: geometry,
                            ),
                          ),
                        ),
                        CustomPaint(
                          painter: _RulerThumbPainter(
                            tokens: t,
                            fraction: _fraction,
                            hovered: _hovered,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Text(formatDurationHmsSeconds(_durationSec), style: timeStyle),
          ],
        ),
      ),
    );
  }

  void _seekTo(double fraction) {
    unawaited(
      ref.read(playerInteractionsProvider).seekToProgressFraction(fraction),
    );
  }

  void _startDrag(double fraction) {
    _scrubSecond = null;
    _pendingSeekTimer?.cancel();
    _pendingSeekTimer = null;
    _pendingSeekFraction = null;
    _dragFraction = fraction;
    _fraction.value = fraction;
    _updateElapsedText();
  }

  void _updateDrag(double fraction) {
    if (_hapticScrub) {
      final sec = (fraction * widget.chrome.durationSeconds).floor();
      if (_scrubSecond != sec) {
        _scrubSecond = sec;
        Haptics.selection(context);
      }
    }
    _dragFraction = fraction;
    _fraction.value = fraction;
    _updateElapsedText();
  }

  void _endDrag() {
    final fraction = _dragFraction;
    if (fraction == null) return;
    _dragFraction = null;
    _holdPendingSeek(fraction);
    _updateElapsedText();
    _seekTo(fraction);
  }

  void _setHovered(bool v) {
    if (_hovered.value == v) return;
    runOutsideMouseTrackerIfMounted(() => mounted, () {
      if (!mounted) return;
      _hovered.value = v;
    });
  }
}

/// The sunk track and the played fill that rides it; repaints on every
/// playhead step, so it draws nothing that depends on the transcript.
class _RulerProgressPainter extends CustomPainter {
  _RulerProgressPainter({required this.tokens, required this.fraction})
    : super(repaint: fraction);

  final EnjoyThemeTokens tokens;
  final ValueListenable<double> fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final t = tokens;
    final trackTop = size.height / 2 - t.strokeRulerTrack / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, trackTop, size.width, t.strokeRulerTrack),
        const Radius.circular(2),
      ),
      Paint()..color = t.sunk,
    );

    final playedWidth = size.width * fraction.value.clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, trackTop, playedWidth, t.strokeRulerTrack),
        const Radius.circular(2),
      ),
      Paint()..color = t.original,
    );
  }

  @override
  bool shouldRepaint(_RulerProgressPainter old) => old.tokens != tokens;
}

/// Ticks, the Echo loop bracket and the practiced dots. Painted above the
/// progress fill so they stay visible across the played span, and isolated in
/// a [RepaintBoundary] so a playhead step never repaints them.
class _RulerTickPainter extends CustomPainter {
  _RulerTickPainter({required this.tokens, required this.geometry});

  final EnjoyThemeTokens tokens;
  final RulerGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    final t = tokens;
    final trackTop = size.height / 2 - t.strokeRulerTrack / 2;

    final tickPaint = Paint()
      ..color = t.tick
      ..strokeWidth = 1;
    for (final f in geometry.lineStartFractions) {
      final x = size.width * f;
      canvas.drawLine(
        Offset(x, trackTop - 4),
        Offset(x, trackTop + t.strokeRulerTrack + 4),
        tickPaint,
      );
    }

    if (geometry.loopStart != null && geometry.loopEnd != null) {
      final x0 = size.width * geometry.loopStart!.clamp(0.0, 1.0);
      final x1 = size.width * geometry.loopEnd!.clamp(0.0, 1.0);
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
    for (final index in geometry.practicedLineIndexes) {
      if (index < 0 || index >= geometry.lineStartFractions.length) continue;
      final x = size.width * geometry.lineStartFractions[index];
      canvas.drawCircle(Offset(x, trackTop - 8), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_RulerTickPainter old) =>
      old.tokens != tokens || old.geometry != geometry;
}

/// The original thumb ring, drawn above the ticks so a tick crossing the
/// playhead never cuts through it.
class _RulerThumbPainter extends CustomPainter {
  _RulerThumbPainter({
    required this.tokens,
    required this.fraction,
    required this.hovered,
  }) : super(repaint: Listenable.merge([fraction, hovered]));

  final EnjoyThemeTokens tokens;
  final ValueListenable<double> fraction;
  final ValueListenable<bool> hovered;

  @override
  void paint(Canvas canvas, Size size) {
    final t = tokens;
    final playedWidth = size.width * fraction.value.clamp(0.0, 1.0);
    final thumbRadius = hovered.value ? 8.0 : 6.0;
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
  bool shouldRepaint(_RulerThumbPainter old) => old.tokens != tokens;
}
