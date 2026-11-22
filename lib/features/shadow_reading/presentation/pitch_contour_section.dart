/// Collapsible pitch contour with analysis — mirrors web `PitchContourSection`.
library;

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/echo_pitch_analysis_service.dart';
import '../application/shadow_reading_hotkey_bus.dart';
import '../domain/echo_region_analysis.dart';
import 'pitch_contour_chart.dart';
import 'pitch_contour_legend.dart';
import 'pitch_contour_skeleton.dart';

class PitchContourSection extends ConsumerStatefulWidget {
  const PitchContourSection({
    required this.mediaPath,
    required this.startSec,
    required this.endSec,
    this.currentTimeRelativeSec,
    this.currentTimeRelativeSecListenable,
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
  final ValueListenable<double?>? currentTimeRelativeSecListenable;
  final String? selectedRecordingPath;
  final int? selectedRecordingDurationMs;

  /// Null: use internal [_expanded]. Non-null: parent-controlled.
  final bool? expanded;

  final VoidCallback? onToggleExpanded;

  final bool showHeader;

  @override
  ConsumerState<PitchContourSection> createState() =>
      _PitchContourSectionState();
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
  final _mergedMemo = EchoMergedSeriesMemo();
  final ValueNotifier<double?> _progressNotifier = ValueNotifier<double?>(null);

  bool get _effectiveExpanded => widget.expanded ?? _expanded;

  void _syncProgressFromListenable() {
    final rel = widget.currentTimeRelativeSecListenable?.value;
    final refDur = widget.endSec - widget.startSec;
    if (rel == null || refDur <= 0) {
      _progressNotifier.value = null;
    } else {
      _progressNotifier.value = (rel / refDur).clamp(0.0, 1.0);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.currentTimeRelativeSecListenable?.addListener(
      _syncProgressFromListenable,
    );
    _syncProgressFromListenable();
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
    if (oldWidget.currentTimeRelativeSecListenable !=
        widget.currentTimeRelativeSecListenable) {
      oldWidget.currentTimeRelativeSecListenable?.removeListener(
        _syncProgressFromListenable,
      );
      widget.currentTimeRelativeSecListenable?.addListener(
        _syncProgressFromListenable,
      );
      _syncProgressFromListenable();
    } else if (oldWidget.startSec != widget.startSec ||
        oldWidget.endSec != widget.endSec) {
      _syncProgressFromListenable();
    }
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
        oldWidget.selectedRecordingDurationMs !=
            widget.selectedRecordingDurationMs) {
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

  @override
  void dispose() {
    widget.currentTimeRelativeSecListenable?.removeListener(
      _syncProgressFromListenable,
    );
    _progressNotifier.dispose();
    super.dispose();
  }

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
      final r = await ref
          .read(echoPitchAnalysisServiceProvider)
          .analyzeReference(
            mediaPath: widget.mediaPath,
            startSec: widget.startSec,
            endSec: widget.endSec,
          );
      if (!mounted || gen != _referenceRequestGen) return;
      if (r == null) return;
      setState(() {
        _reference = r;
        _loading = false;
        _mergedMemo.invalidate();
      });
      if (widget.selectedRecordingPath != null) {
        unawaited(_loadUser());
      }
    } catch (e) {
      if (!mounted || gen != _referenceRequestGen) return;
      setState(() {
        _reference = null;
        _error = e;
        _loading = false;
        _mergedMemo.invalidate();
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
        _mergedMemo.invalidate();
      });
      return;
    }
    final gen = ++_userRequestGen;
    if (!mounted) return;
    setState(() => _loadingUser = true);
    try {
      final u = await ref
          .read(echoPitchAnalysisServiceProvider)
          .analyzeUser(mediaPath: path);
      if (!mounted || gen != _userRequestGen) return;
      if (u == null) return;
      setState(() {
        _user = u;
        _loadingUser = false;
        _mergedMemo.invalidate();
      });
    } catch (_) {
      if (!mounted || gen != _userRequestGen) return;
      setState(() {
        _user = null;
        _loadingUser = false;
        _mergedMemo.invalidate();
      });
    }
  }

  List<EchoRegionSeriesPoint> _merged() {
    final durMs = widget.selectedRecordingDurationMs;
    return _mergedMemo.resolve(
      reference: _reference,
      user: _user,
      referenceDurationSec: widget.endSec - widget.startSec,
      userDurationSec: durMs == null ? 0 : durMs / 1000.0,
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
    final pitchTooltip = hotkeyTooltipLabel(
      ref,
      'player.togglePitchContour',
      l10n.pitchContourTitle,
    );
    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);
    final refColor = tok.original.withValues(alpha: 0.35);
    final userColor = tok.you;

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
              const PitchContourChartSkeleton(),
              const SizedBox(height: 8),
              Text(
                l10n.pitchContourAnalyzing,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
                progressListenable:
                    widget.currentTimeRelativeSecListenable != null
                    ? _progressNotifier
                    : null,
              ),
              if (_loadingUser) ...[
                const SizedBox(height: 6),
                const LinearProgressIndicator(minHeight: 2),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  PitchContourLegendToggle(
                    label: l10n.pitchContourReference,
                    swatch: PitchContourLegendSwatch.band(tok.original),
                    selected: _vis.showReference,
                    onTap: () => setState(() {
                      _vis = _vis.copyWith(showReference: !_vis.showReference);
                    }),
                  ),
                  PitchContourLegendToggle(
                    label: l10n.pitchContourUser,
                    swatch: PitchContourLegendSwatch.line(tok.you),
                    selected: _vis.showUser,
                    onTap: () => setState(() {
                      _vis = _vis.copyWith(showUser: !_vis.showUser);
                    }),
                  ),
                  PitchContourLegendToggle(
                    label: l10n.pitchContourWaveform,
                    swatch: PitchContourLegendSwatch.envelope(tok.original),
                    selected: _vis.showWaveform,
                    onTap: () => setState(() {
                      _vis = _vis.copyWith(showWaveform: !_vis.showWaveform);
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
            child: EnjoyPressable(
              onTap: () => unawaited(_toggleExpanded()),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _effectiveExpanded
                          ? EnjoyIcons.chevronUp
                          : EnjoyIcons.chevronDown,
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
