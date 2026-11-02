part of 'shadow_reading_panel.dart';

final _log = logNamed('ShadowReadingPanel');

String _shortSaveError(Object e) {
  final s = collapseWhitespace(e.toString());
  if (s.length <= 180) return s;
  return '${s.substring(0, 177)}…';
}

/// Recording lifecycle and take actions for the shadow-reading panel:
/// start/stop/persist, cancel, playback, deletion, the takes sheet/margin,
/// and the four hotkey pulse handlers.
mixin ShadowReadingPanelRecording on ShadowReadingPanelBase {
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
      _selectTake(outcome.row.id);
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

    await ref.read(mediaAnalysisInputProvider(widget.mediaId).future);

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
    ref.read(loopPitchVisibleProvider.notifier).hide();
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
    if (mounted) _selectTake(null);
  }

  Future<void> _openTakesList() async {
    final l10n = AppLocalizations.of(context)!;
    Widget panel(VoidCallback close) => ShadowTakesListPanel(
      query: _regionQuery,
      onClose: close,
      onPlayOrPause: (row) {
        final path = row.localPath;
        if (path != null && path.isNotEmpty) {
          unawaited(_playOrPauseTake(path));
        }
      },
      onDelete: _deleteRecording,
    );
    final t = EnjoyThemeTokens.of(context);
    if (MediaQuery.sizeOf(context).width < t.breakpointCompact) {
      await showEnjoySheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) =>
            panel(() => Navigator.of(sheetContext).pop()),
      );
      return;
    }
    await openPlayerMargin(
      context,
      PlayerMarginEntry(
        id: 'takes',
        label: l10n.takesMarginTitleClick,
        echoOnly: true,
        builder: (context, close) => panel(close),
      ),
    );
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
      marginWhenWide: true,
    );
  }
}
