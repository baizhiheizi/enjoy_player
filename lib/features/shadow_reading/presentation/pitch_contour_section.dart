/// Collapsible pitch contour with analysis — mirrors web `PitchContourSection`.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    super.key,
  });

  final String mediaPath;
  final double startSec;
  final double endSec;
  final double? currentTimeRelativeSec;
  final String? selectedRecordingPath;
  final int? selectedRecordingDurationMs;

  @override
  ConsumerState<PitchContourSection> createState() => _PitchContourSectionState();
}

class _PitchContourSectionState extends ConsumerState<PitchContourSection> {
  bool _expanded = false;
  EchoRegionAnalysisResult? _reference;
  EchoRegionAnalysisResult? _user;
  Object? _error;
  bool _loading = false;
  PitchContourVisibility _vis = const PitchContourVisibility();

  @override
  void didUpdateWidget(covariant PitchContourSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaPath != widget.mediaPath ||
        oldWidget.startSec != widget.startSec ||
        oldWidget.endSec != widget.endSec) {
      _reference = null;
      _user = null;
      _error = null;
    }
    if (oldWidget.selectedRecordingPath != widget.selectedRecordingPath ||
        oldWidget.selectedRecordingDurationMs != widget.selectedRecordingDurationMs) {
      _user = null;
      if (_expanded && widget.selectedRecordingPath != null) {
        _loadUser();
      }
    }
  }

  Future<void> _loadReference() async {
    if (_loading) return;
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
      if (!mounted) return;
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadUser() async {
    final path = widget.selectedRecordingPath;
    if (path == null || path.isEmpty) {
      setState(() => _user = null);
      return;
    }
    try {
      final u = await analyzeMediaFileFull(mediaPath: path);
      if (!mounted) return;
      setState(() => _user = u);
    } catch (_) {
      if (!mounted) return;
      setState(() => _user = null);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => unawaited(_toggleExpanded()),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
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
        if (_expanded) ...[
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
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
        ],
      ],
    );
  }
}
