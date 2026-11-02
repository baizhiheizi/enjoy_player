/// Shadow-reading stack below echo segment — mirrors web `ShadowReadingPanel`.
///
/// Composition root: shared run state lives in [ShadowReadingPanelBase]; the
/// recording/take concern lives in `shadow_reading_panel_recording.dart`, and
/// the render branches live in `widgets/` (`ShadowTakesInLoopRow`,
/// `ShadowIdlePanelColumn`, `ShadowPitchContourTile`).
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/analytics/analytics_events.dart';
import 'package:enjoy_player/core/analytics/analytics_provider.dart';
import 'package:enjoy_player/core/audio/recording_preview_player_provider.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/utils/text_normalization.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/features/player/application/media_analysis_input_provider.dart';
import 'package:enjoy_player/features/player/application/player_margin_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_margin.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_controller.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_take_providers.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_take_store.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_takes_ui_state.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/recording_assessment_flow.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_idle_panel_column.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_recording_live.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_takes_in_loop_row.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_takes_list_panel.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

part 'shadow_reading_panel_recording.dart';

/// `@visibleForTesting` wrapper around the private [_shortSaveError] so
/// tests can exercise the helper without spinning up the full widget
/// tree. See `test/features/shadow_reading/presentation/shadow_reading_panel_helpers_test.dart`.
@visibleForTesting
String shortSaveErrorForTest(Object e) => _shortSaveError(e);

RecordingRow? _resolvedSelectedRow(
  List<RecordingRow> list,
  String? selectedId,
) {
  if (list.isEmpty) return null;
  if (selectedId != null) {
    for (final r in list) {
      if (r.id == selectedId) return r;
    }
  }
  return list.first;
}

/// `@visibleForTesting` wrapper around the private [_resolvedSelectedRow].
/// See `test/features/shadow_reading/presentation/shadow_reading_panel_helpers_test.dart`.
@visibleForTesting
RecordingRow? resolvedSelectedRowForTest(
  List<RecordingRow> list,
  String? selectedId,
) => _resolvedSelectedRow(list, selectedId);

class ShadowReadingPanel extends ConsumerStatefulWidget {
  const ShadowReadingPanel({
    required this.mediaId,
    required this.targetType,
    required this.language,
    required this.startSec,
    required this.endSec,
    required this.referenceText,
    required this.echoActive,
    this.showLiveProgress = false,
    this.takesRowInLoop = false,
    this.analyticsSurface = AnalyticsEvents.surfaceShadowReading,
    super.key,
  });

  final String mediaId;
  final String targetType;
  final String language;
  final double startSec;
  final double endSec;
  final String referenceText;
  final bool echoActive;

  /// Whether the pitch contour tracks the live player position. The
  /// player-transcript embed sets this; the vocabulary recorder embed has no
  /// open player, so its contour renders without a progress marker.
  final bool showLiveProgress;

  /// Player-embed presentation: takes render as a chip strip under the loop
  /// (the dock owns record / cancel / stop), instead of the toolbar row used
  /// by the vocabulary embed.
  final bool takesRowInLoop;

  /// Analytics `surface` tag (spec 046 catalog) — the panel is embedded both
  /// in the player transcript (default) and vocabulary flashcard practice.
  final String analyticsSurface;

  @override
  ConsumerState<ShadowReadingPanel> createState() => _ShadowReadingPanelState();
}

/// Capture config aligned with the web client and Azure Speech expectations
/// lives in [buildShadowRecordConfig] (shadow_take_store.dart).

/// Run state shared across the panel's concern mixins.
mixin ShadowReadingPanelBase on ConsumerState<ShadowReadingPanel> {
  ShadowTakeStore? _takeStoreInstance;

  /// The take window this panel renders and acts on, as an application-layer
  /// query key so no call site rebuilds the five-field shape by hand.
  EchoRegionRecordingsQuery get _regionQuery => EchoRegionRecordingsQuery(
    targetType: widget.targetType,
    targetId: widget.mediaId,
    language: widget.language,
    echoStartMs: (widget.startSec * 1000).round(),
    echoEndMs: (widget.endSec * 1000).round(),
  );

  ShadowTakeStore get _takeStore =>
      _takeStoreInstance ??= ref.read(shadowTakeStoreFactoryProvider)();

  /// Captured on first write so teardown can reset the shared bus without
  /// touching `ref` mid-dispose (flutter_riverpod 3.x throws on provider
  /// access from a disposing `ConsumerState`). The reset itself is deferred
  /// onto the event loop because riverpod also forbids mutating a provider
  /// from a widget lifecycle — its documented remedy for exactly this shape.
  ShadowReadingHotkeyBus? _hotkeyBusInstance;

  bool _recording = false;
  bool _recordingPending = false;
  String? get _selectedRecordingId => ref.read(selectedTakeProvider);

  void _selectTake(String? id) =>
      ref.read(selectedTakeProvider.notifier).select(id);

  void _togglePitch() => ref.read(loopPitchVisibleProvider.notifier).toggle();

  ShadowReadingHotkeyBus get _hotkeyBus {
    _hotkeyBusInstance ??= ref.read(shadowReadingHotkeyBusProvider.notifier);
    return _hotkeyBusInstance!;
  }

  void _setRecordingActiveOnBus(bool active) {
    _hotkeyBus.setRecordingActive(active);
  }
}

class _ShadowReadingPanelState extends ConsumerState<ShadowReadingPanel>
    with ShadowReadingPanelBase, ShadowReadingPanelRecording {
  @override
  void didUpdateWidget(covariant ShadowReadingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId ||
        oldWidget.startSec != widget.startSec ||
        oldWidget.endSec != widget.endSec ||
        oldWidget.language != widget.language ||
        oldWidget.targetType != widget.targetType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectTake(null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<int>(shadowReadingHotkeyBusProvider.select((s) => s.recording), (
      prev,
      next,
    ) {
      if (prev == next) return;
      unawaited(_onHotkeyRecordingPulse(l10n));
    });
    ref.listen<int>(
      shadowReadingHotkeyBusProvider.select((s) => s.recordingCancel),
      (prev, next) {
        if (prev == next) return;
        if (!_recording && !_recordingPending) return;
        unawaited(_cancelRecording());
      },
    );
    ref.listen<int>(shadowReadingHotkeyBusProvider.select((s) => s.playback), (
      prev,
      next,
    ) {
      if (prev == next) return;
      unawaited(_onHotkeyPlaybackPulse());
    });
    ref.listen<int>(
      shadowReadingHotkeyBusProvider.select((s) => s.assessment),
      (prev, next) {
        if (prev == next) return;
        _onHotkeyAssessmentPulse();
      },
    );

    final selectedId = ref.watch(selectedTakeProvider);
    final pitchExpanded = ref.watch(loopPitchVisibleProvider);
    final mediaPath = ref
        .watch(mediaAnalysisInputProvider(widget.mediaId))
        .valueOrNull;
    final recordings = ref.watch(echoRegionRecordingsProvider(_regionQuery));

    return StreamBuilder(
      stream: recordings,
      builder: (context, recSnap) {
        final list = recSnap.data ?? [];
        final sel = _resolvedSelectedRow(list, selectedId);

        if (_recording && widget.takesRowInLoop) {
          return const SizedBox.shrink();
        }

        if (widget.takesRowInLoop) {
          return ShadowTakesInLoopRow(
            takes: list,
            selected: sel,
            mediaPath: mediaPath,
            startSec: widget.startSec,
            endSec: widget.endSec,
            showLiveProgress: widget.showLiveProgress,
            pitchExpanded: pitchExpanded,
            onPlayOrPause: (row) {
              final path = row.localPath;
              if (path != null && path.isNotEmpty) {
                unawaited(_playOrPauseTake(path));
              }
            },
            onOpenList: () => unawaited(_openTakesList()),
            onTogglePitch: _togglePitch,
          );
        }

        if (_recording) {
          final targetSec = (widget.endSec - widget.startSec).clamp(
            0.0,
            double.infinity,
          );
          return ShadowRecordingLive(
            targetSec: targetSec,
            echoActive: widget.echoActive,
            stopTooltip: hotkeyTooltipLabel(
              ref,
              'player.toggleRecording',
              l10n.shadowRecordingStop,
            ),
            onStop: () => _toggleRecord(l10n),
            l10n: l10n,
            tt: Theme.of(context).textTheme,
            scheme: Theme.of(context).colorScheme,
            tok: EnjoyThemeTokens.of(context),
          );
        }

        return ShadowIdlePanelColumn(
          mediaId: widget.mediaId,
          echoActive: widget.echoActive,
          mediaPath: mediaPath,
          startSec: widget.startSec,
          endSec: widget.endSec,
          showLiveProgress: widget.showLiveProgress,
          pitchExpanded: pitchExpanded,
          takes: list,
          selected: sel,
          onToggleRecord: () => _toggleRecord(l10n),
          onPlayOrPause: _playOrPauseTake,
          onDeleteTake: _deleteRecording,
          onChooseTake: (id) async {
            await ref.read(recordingPreviewPlayerProvider).stop();
            if (mounted) _selectTake(id);
          },
          onTogglePitch: _togglePitch,
        );
      },
    );
  }
}
