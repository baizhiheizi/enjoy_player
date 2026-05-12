/// Collapsible pitch contour with analysis — mirrors web `PitchContourSection`.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/echo_region_pitch_analyzer.dart';
import '../application/shadow_reading_hotkey_bus.dart';
import '../domain/echo_region_analysis.dart';
import 'pitch_contour_chart.dart';

class PitchContourSection extends ConsumerStatefulWidget {
  const PitchContourSection({
    required this.mediaPath,
    required this.startSec,
    required this.endSec,
    this.currentTimeRelativeSec,
    this.selectedRecordingPath,
    this.selectedRecordingDurationMs,
    /// When non-null, expansion is controlled by the parent ([expanded] drives UI).
    this.expanded,
    /// Called when the section should toggle (header tap or hotkey). Parent updates [expanded].
    this.onToggleExpanded,
    /// When false, only the expandable body (chart + chips) is rendered — no chevron row.
    this.showHeader = true,
    super.key,
  });

  final String mediaPath;
  final double startSec;
  final double endSec;
  final double? currentTimeRelativeSec;
  final String? selectedRecordingPath;
  final int? selectedRecordingDurationMs;

  /// Null: use internal [_expanded]. Non-null: parent-controlled.
  final bool? expanded;

  final VoidCallback? onToggleExpanded;

  final bool showHeader;

  @override
  ConsumerState<PitchContourSection> createState() => _PitchContourSectionState();
}

class _PitchContourSectionState extends ConsumerState<PitchContourSection> {
  bool _expanded = false;
  EchoRegionAnalysisResult? _reference;
  EchoRegionAnalysisResult? _user;
  Object? _error;
  bool _loading = false;
  bool _loadingUser = false;
  int _referenceRequestGen = 0;
  int _userRequestGen = 0;
  PitchContourVisibility _vis = const PitchContourVisibility();

  bool get _effectiveExpanded => widget.expanded ?? _expanded;

  @override
  void initState() {
    super.initState();
    if (_effectiveExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_syncExpandLoads());
      });
    }
  }

  @override
  void didUpdateWidget(covariant PitchContourSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaPath != widget.mediaPath ||
        oldWidget.startSec != widget.startSec ||
        oldWidget.endSec != widget.endSec) {
      _referenceRequestGen++;
      _userRequestGen++;
      _reference = null;
      _user = null;
      _error = null;
      if (_effectiveExpanded) {
        unawaited(_loadReference());
      }
    }
    if (oldWidget.selectedRecordingPath != widget.selectedRecordingPath ||
        oldWidget.selectedRecordingDurationMs != widget.selectedRecordingDurationMs) {
      _userRequestGen++;
      _user = null;
      if (_effectiveExpanded && widget.selectedRecordingPath != null) {
        unawaited(_loadUser());
      }
    }

    if (oldWidget.expanded != widget.expanded && widget.expanded == true) {
      unawaited(_syncExpandLoads());
    }
  }

  /// Loads reference + user when section opens (mirrors expand transition).
  Future<void> _syncExpandLoads() async {
    if (!_effectiveExpanded) return;
    if (_reference == null) {
      await _loadReference();
    }
    if (_effectiveExpanded &&
        widget.selectedRecordingPath != null &&
        _user == null &&
        _reference != null) {
      await _loadUser();
    }
  }

  Future<void> _loadReference() async {
    final gen = ++_referenceRequestGen;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await analyzeMediaTimeRange(
        mediaPath: widget.mediaPath,
        startSec: widget.startSec,
        endSec: widget.endSec,
      );
      if (!mounted || gen != _referenceRequestGen) return;
      if (r == null) {
        setState(() {
          _reference = null;
          _loading = false;
          _error = StateError('pcm');
        });
        return;
      }
      setState(() {
        _reference = r;
        _loading = false;
      });
      if (widget.selectedRecordingPath != null) {
        unawaited(_loadUser());
      }
    } catch (e) {
      if (!mounted || gen != _referenceRequestGen) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadUser() async {
    final path = widget.selectedRecordingPath;
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      setState(() {
        _user = null;
        _loadingUser = false;
      });
      return;
    }
    final gen = ++_userRequestGen;
    if (!mounted) return;
    setState(() => _loadingUser = true);
    try {
      final u = await analyzeMediaFileFull(mediaPath: path);
      if (!mounted || gen != _userRequestGen) return;
      setState(() {
        _user = u;
        _loadingUser = false;
      });
    } catch (_) {
      if (!mounted || gen != _userRequestGen) return;
      setState(() {
        _user = null;
        _loadingUser = false;
      });
    }
  }

  List<EchoRegionSeriesPoint> _merged() {
    final ref = _reference;
    if (ref == null) return [];
    final user = _user;
    final durMs = widget.selectedRecordingDurationMs;
    if (user == null || durMs == null || durMs <= 0) return ref.points;
    final refDur = widget.endSec - widget.startSec;
    final userDur = durMs / 1000.0;
    return mergeUserPitchOntoReference(
      referencePoints: ref.points,
      userPoints: user.points,
      referenceDurationSec: refDur,
      userDurationSec: userDur,
    );
  }

  Future<void> _toggleExpanded() async {
    if (widget.onToggleExpanded != null) {
      widget.onToggleExpanded!();
      return;
    }
    final next = !_expanded;
    setState(() => _expanded = next);
    if (next && _reference == null) {
      await _loadReference();
    }
    if (next &&
        widget.selectedRecordingPath != null &&
        _user == null &&
        _reference != null) {
      await _loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      shadowReadingHotkeyBusProvider.select((s) => s.pitchContour),
      (prev, next) {
        if (prev == next) return;
        unawaited(_toggleExpanded());
      },
    );

    final l10n = AppLocalizations.of(context)!;
    final pitchTooltip =
        hotkeyTooltipLabel(ref, 'player.togglePitchContour', l10n.pitchContourTitle);
    final scheme = Theme.of(context).colorScheme;
    final refColor = scheme.tertiary;
    final userColor = scheme.secondary;

    final merged = _merged();
    final refDur = widget.endSec - widget.startSec;
    double? progress;
    final rel = widget.currentTimeRelativeSec;
    if (rel != null && refDur > 0) {
      progress = (rel / refDur).clamp(0.0, 1.0);
    }

    final body = _effectiveExpanded
        ? [
            if (_loading) ...[
              const _PitchContourChartSkeleton(),
              const SizedBox(height: 8),
              Text(
                l10n.pitchContourAnalyzing,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ] else if (_error != null)
              Text(
                l10n.pitchContourError,
                style: TextStyle(color: scheme.error),
              )
            else ...[
              PitchContourChart(
                points: merged,
                referenceColor: refColor,
                userColor: userColor,
                visibility: _vis,
                progress: progress,
              ),
              if (_loadingUser) ...[
                const SizedBox(height: 6),
                const LinearProgressIndicator(minHeight: 2),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: Text(l10n.pitchContourWaveform),
                    selected: _vis.showWaveform,
                    onSelected: (v) => setState(() {
                      _vis = _vis.copyWith(showWaveform: v);
                    }),
                  ),
                  FilterChip(
                    label: Text(l10n.pitchContourReference),
                    selected: _vis.showReference,
                    onSelected: (v) => setState(() {
                      _vis = _vis.copyWith(showReference: v);
                    }),
                  ),
                  FilterChip(
                    label: Text(l10n.pitchContourUser),
                    selected: _vis.showUser,
                    onSelected: (v) => setState(() {
                      _vis = _vis.copyWith(showUser: v);
                    }),
                  ),
                ],
              ),
            ],
          ]
        : <Widget>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader)
          Tooltip(
            message: pitchTooltip,
            child: InkWell(
              onTap: () => unawaited(_toggleExpanded()),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _effectiveExpanded ? Icons.expand_less : Icons.expand_more,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.pitchContourTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ...body,
      ],
    );
  }
}

/// Placeholder footprint matching [PitchContourChart] height band.
class _PitchContourChartSkeleton extends StatelessWidget {
  const _PitchContourChartSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(painter: _PitchContourSkeletonPainter(baseColor: base)),
    );
  }
}

class _PitchContourSkeletonPainter extends CustomPainter {
  _PitchContourSkeletonPainter({required this.baseColor});

  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = baseColor;
    const n = 44;
    final barW = size.width / n;
    final rnd = math.Random(42);
    for (var i = 0; i < n; i++) {
      final h = barW * (0.45 + rnd.nextDouble() * 1.1);
      final x = i * barW + barW * 0.12;
      final top = size.height * 0.52 + (size.height * 0.42 - h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barW * 0.76, h),
          const Radius.circular(2),
        ),
        paint,
      );
    }
    final linePaint =
        Paint()
          ..color = baseColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
    final path = Path();
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = t * size.width;
      final y = size.height * 0.26 + math.sin(t * math.pi * 5) * size.height * 0.09;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _PitchContourSkeletonPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor;
}
