/// Shadow-reading stack below echo segment — mirrors web `ShadowReadingPanel`.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/audio/recording_preview_player_provider.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/text_normalization.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/features/player/application/display_position_provider.dart';
import 'package:enjoy_player/features/player/application/local_media_path_provider.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_controller.dart';
import 'package:enjoy_player/core/analytics/analytics_events.dart';
import 'package:enjoy_player/core/analytics/analytics_provider.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_take_providers.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_take_store.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/recording_assessment_flow.dart';
import 'package:enjoy_player/features/share_poster/presentation/share_practice_poster_button.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'pitch_contour_section.dart';
import 'widgets/shadow_record_fab.dart';
import 'widgets/shadow_recording_live.dart';
import 'widgets/shadow_reading_toolbar_row.dart';
import 'widgets/shadow_takes_toolbar_actions.dart';

final _log = logNamed('ShadowReadingPanel');

String _shortSaveError(Object e) {
  final s = collapseWhitespace(e.toString());
  if (s.length <= 180) return s;
  return '${s.substring(0, 177)}…';
}

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

  /// Analytics `surface` tag (spec 046 catalog) — the panel is embedded both
  /// in the player transcript (default) and vocabulary flashcard practice.
  final String analyticsSurface;

  @override
  ConsumerState<ShadowReadingPanel> createState() => _ShadowReadingPanelState();
}

/// Capture config aligned with the web client and Azure Speech expectations
/// lives in [buildShadowRecordConfig] (shadow_take_store.dart).

class _ShadowReadingPanelState extends ConsumerState<ShadowReadingPanel> {
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

  /// Captured on first write so [dispose] can reset the shared bus without
  /// touching `ref` mid-teardown (flutter_riverpod 3.x throws on provider
  /// access from a disposing `ConsumerState`). The reset itself is deferred
  /// onto the event loop because riverpod also forbids mutating a provider
  /// from a widget lifecycle — its documented remedy for exactly this shape.
  ShadowReadingHotkeyBus? _hotkeyBusInstance;

  bool _recording = false;
  bool _recordingPending = false;
  String? _selectedRecordingId;

  bool _pitchExpanded = false;

  @override
  void didUpdateWidget(covariant ShadowReadingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId ||
        oldWidget.startSec != widget.startSec ||
        oldWidget.endSec != widget.endSec ||
        oldWidget.language != widget.language ||
        oldWidget.targetType != widget.targetType) {
      _selectedRecordingId = null;
    }
  }

  ShadowReadingHotkeyBus get _hotkeyBus {
    _hotkeyBusInstance ??= ref.read(shadowReadingHotkeyBusProvider.notifier);
    return _hotkeyBusInstance!;
  }

  void _setRecordingActiveOnBus(bool active) {
    _hotkeyBus.setRecordingActive(active);
  }

  /// Discard in-progress capture (Escape); does not persist to the library.
  Future<void> _cancelRecording() async {
    if (!_recording && !_recordingPending) return;
    if (_recordingPending && !_recording) {
      _recordingPending = false;
      _setRecordingActiveOnBus(false);
      if (mounted) setState(() {});
      return;
    }
    await _takeStore.cancel();
    _recording = false;
    _recordingPending = false;
    _setRecordingActiveOnBus(false);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final bus = _hotkeyBusInstance;
    if ((_recording || _recordingPending) && bus != null) {
      _recording = false;
      _recordingPending = false;
      unawaited(Future(() => bus.setRecordingActive(false)));
    }
    final store = _takeStoreInstance;
    if (store != null) {
      unawaited(store.dispose());
    }
    super.dispose();
  }

  Future<void> _toggleRecord(AppLocalizations l10n) async {
    if (!widget.echoActive) return;
    if (_recording) {
      _recording = false;
      _recordingPending = false;
      _setRecordingActiveOnBus(false);
      setState(() {});
      TakePersistResult outcome;
      try {
        outcome = await _takeStore.stopAndPersist(region: _takeRegion);
      } catch (e) {
        if (mounted) {
          final message = e is TakeFileMissingException
              ? l10n.shadowRecordingFileNotFound
              : l10n.shadowRecordingSaveFailed(_shortSaveError(e));
          AppNotice.error(context, message);
        }
        return;
      }
      if (!mounted) return;
      if (outcome.looksSilent) {
        AppNotice.warning(context, l10n.shadowRecordingSilentWarning);
      }
      setState(() => _selectedRecordingId = outcome.row.id);
      ref
          .read(analyticsProvider)
          .capture(
            AnalyticsEvents.practiceSessionCompleted,
            properties: AnalyticsEvents.practiceCompleted(
              surface: widget.analyticsSurface,
              durationSeconds: (outcome.row.duration / 1000).round(),
              itemsCompleted: 1,
            ),
          );
      return;
    }

    await ref.read(localMediaPathProvider(widget.mediaId).future);

    _setRecordingActiveOnBus(true);
    _recordingPending = true;

    await ref.read(recordingInputDeviceCtrlProvider.notifier).refresh();
    final deviceState = ref.read(recordingInputDeviceCtrlProvider).valueOrNull;
    final selectedDevice = deviceState?.selectedDevice;

    try {
      await _takeStore.start(device: selectedDevice);
    } on MicPermissionDeniedException {
      _recordingPending = false;
      _setRecordingActiveOnBus(false);
      if (mounted) {
        AppNotice.warning(context, l10n.shadowRecordingMicDenied);
      }
      return;
    } catch (e, st) {
      _log.warning('take start failed', e, st);
      _recordingPending = false;
      _setRecordingActiveOnBus(false);
      if (mounted) setState(() {});
      if (mounted) {
        AppNotice.error(
          context,
          l10n.shadowRecordingSaveFailed(_shortSaveError(e)),
        );
      }
      return;
    }
    _log.fine(
      'take start device="${selectedDevice?.label ?? "<os-default>"}"'
      '${deviceState?.autoPicked == false ? " (user)" : " (auto)"}',
    );
    _recording = true;
    _recordingPending = false;
    _pitchExpanded = false;
    setState(() {});
    ref
        .read(analyticsProvider)
        .capture(
          AnalyticsEvents.practiceSessionStarted,
          properties: AnalyticsEvents.practiceStarted(
            surface: widget.analyticsSurface,
            itemCount: 1,
          ),
        );
  }

  TakeRegion get _takeRegion => TakeRegion(
    targetType: widget.targetType,
    targetId: widget.mediaId,
    language: widget.language,
    referenceText: widget.referenceText,
    startSec: widget.startSec,
    endSec: widget.endSec,
  );

  Future<void> _playOrPauseTake(String path) async {
    try {
      await ref.read(recordingPreviewPlayerProvider).playOrPauseTake(path);
    } catch (e, st) {
      _log.warning('shadow take playback failed', e, st);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      AppNotice.error(context, l10n.shadowRecordingPlaybackFailed);
    }
  }

  Future<void> _deleteRecording(RecordingRow r) async {
    final preview = ref.read(recordingPreviewPlayerProvider);
    final lp = r.localPath;
    if (lp != null && lp.isNotEmpty) {
      try {
        if (preview.loadedPath == File(lp).absolute.path) {
          await preview.stop();
        }
      } catch (_) {}
    }
    await _takeStore.deleteTake(r);
    if (mounted) {
      setState(() => _selectedRecordingId = null);
    }
  }

  Future<void> _onHotkeyRecordingPulse(AppLocalizations l10n) async {
    if (!widget.echoActive) return;
    await _toggleRecord(l10n);
  }

  Future<void> _onHotkeyPlaybackPulse() async {
    if (!widget.echoActive) return;
    final list = await ref.read(
      echoRegionRecordingsOnceProvider(_regionQuery).future,
    );
    if (!mounted) return;
    if (list.isEmpty) return;
    final sel = _resolvedSelectedRow(list, _selectedRecordingId);
    final path = sel?.localPath;
    if (path != null && path.isNotEmpty) {
      await _playOrPauseTake(path);
    }
  }

  void _onHotkeyAssessmentPulse() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    unawaited(_onHotkeyAssessmentRun(l10n));
  }

  Future<void> _onHotkeyAssessmentRun(AppLocalizations l10n) async {
    if (!widget.echoActive) return;
    final list = await ref.read(
      echoRegionRecordingsOnceProvider(_regionQuery).future,
    );
    if (!mounted) return;
    if (list.isEmpty) return;
    final sel = _resolvedSelectedRow(list, _selectedRecordingId);
    if (sel == null) return;
    await triggerRecordingAssessment(
      context: context,
      ref: ref,
      l10n: l10n,
      row: sel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ttToggleRecording = hotkeyTooltipLabel(
      ref,
      'player.toggleRecording',
      _recording ? l10n.shadowRecordingStop : l10n.shadowRecordingRecord,
    );
    final pitchContourTooltip = hotkeyTooltipLabel(
      ref,
      'player.togglePitchContour',
      l10n.pitchContourTitle,
    );
    final recordFabTooltip = '$ttToggleRecording\n${l10n.shadowReadingHint}';
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

    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;

    final targetSec = (widget.endSec - widget.startSec).clamp(
      0.0,
      double.infinity,
    );

    final mediaPath = ref
        .watch(localMediaPathProvider(widget.mediaId))
        .valueOrNull;
    final recordings = ref.watch(echoRegionRecordingsProvider(_regionQuery));

    return StreamBuilder(
      stream: recordings,
      builder: (context, recSnap) {
        final list = recSnap.data ?? [];
        final sel = _resolvedSelectedRow(list, _selectedRecordingId);

        if (_recording) {
          return ShadowRecordingLive(
            targetSec: targetSec,
            echoActive: widget.echoActive,
            stopTooltip: ttToggleRecording,
            onStop: () => _toggleRecord(l10n),
            l10n: l10n,
            tt: tt,
            scheme: scheme,
            tok: tok,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShadowReadingToolbarRow(
              tok: tok,
              scheme: scheme,
              pitchExpanded: _pitchExpanded,
              pitchTooltip: pitchContourTooltip,
              hasMediaPath: mediaPath != null && mediaPath.isNotEmpty,
              onPitchTap: () =>
                  setState(() => _pitchExpanded = !_pitchExpanded),
              leadingShare: SharePracticePosterButton(
                mediaId: widget.mediaId,
                iconColor: scheme.onSurface,
              ),
              takesActions: list.isNotEmpty && sel != null
                  ? ShadowTakesToolbarActions(
                      row: sel,
                      list: list,
                      echoActive: widget.echoActive,
                      scheme: scheme,
                      tok: tok,
                      l10n: l10n,
                      onPlayOrPause: () {
                        final path = sel.localPath;
                        if (path != null && path.isNotEmpty) {
                          unawaited(_playOrPauseTake(path));
                        }
                      },
                      onDeleteCurrent: () => unawaited(_deleteRecording(sel)),
                      onChooseTake: (id) async {
                        await ref.read(recordingPreviewPlayerProvider).stop();
                        if (mounted) {
                          setState(() => _selectedRecordingId = id);
                        }
                      },
                    )
                  : null,
              recordFab: Tooltip(
                message: recordFabTooltip,
                child: ShadowRecordFab(
                  recording: false,
                  echoActive: widget.echoActive,
                  ringProgress: 0,
                  overTarget: false,
                  overPulseHigh: false,
                  showProgressArc: false,
                  onTap: () => _toggleRecord(l10n),
                  scheme: scheme,
                  tok: tok,
                ),
              ),
            ),
            if (mediaPath != null && mediaPath.isNotEmpty) ...[
              if (_pitchExpanded) SizedBox(height: tok.space8),
              Consumer(
                builder: (context, ref, _) {
                  double? relativeSec;
                  if (widget.showLiveProgress && _pitchExpanded) {
                    final posSec =
                        (ref.watch(displayPositionProvider).valueOrNull ??
                                Duration.zero)
                            .inMilliseconds /
                        1000.0;
                    relativeSec = (posSec - widget.startSec).clamp(
                      0.0,
                      widget.endSec - widget.startSec,
                    );
                  }
                  return PitchContourSection(
                    mediaPath: mediaPath,
                    startSec: widget.startSec,
                    endSec: widget.endSec,
                    currentTimeRelativeSec: relativeSec,
                    selectedRecordingPath: sel?.localPath,
                    selectedRecordingDurationMs: sel?.duration,
                    expanded: _pitchExpanded,
                    onToggleExpanded: () =>
                        setState(() => _pitchExpanded = !_pitchExpanded),
                    showHeader: false,
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
