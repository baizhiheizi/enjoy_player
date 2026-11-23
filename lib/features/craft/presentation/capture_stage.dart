/// Capture stage: voice-first input for the Craft Express flow.
///
/// The microphone lifecycle (permission, the shared 16 kHz mono WAV config,
/// the user's chosen device, the recreate-after-stop workaround) lives in
/// [MicCaptureSession]; this widget owns the elapsed readout, the amplitude
/// ring buffer, and the [CraftController] hand-off.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' show InputDevice;

import 'package:enjoy_player/core/audio/mic_capture_session.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/presentation/capture_stage_idle_view.dart';
import 'package:enjoy_player/features/craft/presentation/capture_stage_recording_view.dart';
import 'package:enjoy_player/features/craft/presentation/capture_stage_text_fallback.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_failure_card.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_loading_view.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Voice capture stage for the Express flow.
class CaptureStage extends ConsumerStatefulWidget {
  const CaptureStage({super.key});

  @override
  ConsumerState<CaptureStage> createState() => _CaptureStageState();
}

class _CaptureStageState extends ConsumerState<CaptureStage> {
  static final _log = logNamed('craft.capture');

  static const _maxAmplitudeBars = 40;

  bool _recordingPending = false;
  bool _textMode = false;

  /// True while this widget owns an in-flight capture on [CraftController].
  /// Tracked locally so [dispose] can clear the session flag without [ref].
  bool _sessionCapturing = false;
  CraftController? _craft;
  MicCaptureSession? _micSession;

  DateTime? _recordingStartedAt;
  Duration _elapsed = Duration.zero;
  Timer? _elapsedTimer;

  /// Ring-buffer for amplitude samples — avoids per-tick list allocation.
  late final Float32List _amplitudeBuffer = Float32List(_maxAmplitudeBars);
  int _amplitudeWriteIndex = 0;
  int _amplitudeCount = 0;
  StreamSubscription? _amplitudeSub;

  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _craft ??= ref.read(craftControllerProvider.notifier);
    _micSession ??= ref.read(micCaptureSessionFactoryProvider)();
  }

  MicCaptureSession get _session => _micSession!;

  @override
  void dispose() {
    _stopElapsedTimer();
    _cancelAmplitudeStream();
    _textController.dispose();
    _focusNode.dispose();
    if (_sessionCapturing) {
      _sessionCapturing = false;
      final craft = _craft;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        craft?.cancelCapture();
      });
    }
    unawaited(_micSession?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  void _cancelAmplitudeStream() {
    unawaited(_amplitudeSub?.cancel());
    _amplitudeSub = null;
  }

  Future<void> _startRecording() async {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.read(craftControllerProvider);

    if (state.isBusy) return;
    _recordingPending = true;

    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/craft_recordings');

    InputDevice? device;
    try {
      device = await ref
          .read(recordingInputDeviceCtrlProvider.future)
          .then((state) => state.selectedDevice);
    } catch (e, st) {
      _log.fine('mic device state unavailable, using the OS default', e, st);
    }

    try {
      await _session.start(
        directory: dir,
        filename: 'craft_${DateTime.now().millisecondsSinceEpoch}.wav',
        device: device,
      );
    } on MicPermissionDeniedException {
      _recordingPending = false;
      if (mounted) {
        AppNotice.warning(context, l10n.craftRecordingMicDenied);
      }
      return;
    } catch (e, st) {
      _log.warning('mic capture start failed', e, st);
      _recordingPending = false;
      if (mounted) setState(() {});
      return;
    }

    _recordingPending = false;
    _recordingStartedAt = DateTime.now();
    _elapsed = Duration.zero;
    _amplitudeWriteIndex = 0;
    _amplitudeCount = 0;
    _startElapsedTimer();
    _startAmplitudeStream();

    ref.read(craftControllerProvider.notifier).startCapture();
    _sessionCapturing = true;
    if (mounted) setState(() {});
  }

  Future<void> _stopRecording() async {
    final controller = ref.read(craftControllerProvider.notifier);
    String? path;
    try {
      path = await _session.stop();
    } catch (e, st) {
      _log.warning('mic capture stop failed', e, st);
    }
    _stopElapsedTimer();
    _cancelAmplitudeStream();
    _recordingStartedAt = null;
    _amplitudeWriteIndex = 0;
    _amplitudeCount = 0;
    _recordingPending = false;

    if (path == null || path.isEmpty) {
      _log.warning('mic capture stop returned no path');
      _sessionCapturing = false;
      controller.cancelCapture();
      if (mounted) setState(() {});
      return;
    }

    Uint8List? bytes;
    try {
      bytes = await File(path).readAsBytes();
      await File(path).delete();
    } catch (e, st) {
      _log.warning('read/delete recording file failed', e, st);
    }

    if (bytes != null && bytes.isNotEmpty) {
      _sessionCapturing = false;
      await controller.stopCapture(bytes);
    } else {
      _sessionCapturing = false;
      controller.cancelCapture();
    }
    if (mounted) setState(() {});
  }

  /// Stop the mic and discard any temp file. Does not touch controller state
  /// (used when [cancelCapture] already ran, e.g. via Escape).
  Future<void> _discardMicOnly() async {
    if (_recordingStartedAt == null && !_recordingPending) return;

    _stopElapsedTimer();
    _cancelAmplitudeStream();
    _recordingStartedAt = null;
    _amplitudeWriteIndex = 0;
    _amplitudeCount = 0;
    _recordingPending = false;

    await _session.cancel();
    if (mounted) setState(() {});
  }

  /// Discard the current recording without committing to ASR.
  Future<void> _cancelRecording() async {
    final controller = ref.read(craftControllerProvider.notifier);
    await _discardMicOnly();
    _sessionCapturing = false;
    controller.cancelCapture();
  }

  /// 1 Hz timer for the `m:ss` label — avoids 60 fps ticker rebuilds.
  void _startElapsedTimer() {
    _stopElapsedTimer();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recordingStartedAt == null) return;
      final elapsed = DateTime.now().difference(_recordingStartedAt!);
      if (mounted) setState(() => _elapsed = elapsed);
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  void _startAmplitudeStream() {
    _cancelAmplitudeStream();
    _amplitudeSub = _session
        .amplitudeEvents(const Duration(milliseconds: 100))
        .listen((amp) {
          final level = ((amp.current + 40) / 40).clamp(0.05, 1.0);
          if (mounted) {
            setState(() {
              _amplitudeBuffer[_amplitudeWriteIndex] = level;
              _amplitudeWriteIndex =
                  (_amplitudeWriteIndex + 1) % _maxAmplitudeBars;
              if (_amplitudeCount < _maxAmplitudeBars) _amplitudeCount++;
            });
          }
        });
  }

  Future<void> _submitText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    await ref.read(craftControllerProvider.notifier).useTextInput(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(craftControllerProvider);
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    ref.listen<int>(
      craftControllerProvider.select((s) => s.captureCancelTick),
      (prev, next) {
        if (prev != null && next > prev) {
          _sessionCapturing = false;
          unawaited(_discardMicOnly());
        }
      },
    );

    if (state.isTranscribing) {
      return CraftLoadingView(message: l10n.craftLoadingTranscribing);
    }

    if (state.failure != null) {
      return CraftFailureCard(
        failure: state.failure!,
        l10n: l10n,
        onRetry: _startRecording,
      );
    }

    if (_textMode) {
      return CaptureTextFallback(
        controller: _textController,
        focusNode: _focusNode,
        l10n: l10n,
        onSubmit: _submitText,
        onBack: () => setState(() => _textMode = false),
      );
    }

    if (state.isCapturing) {
      return CaptureRecordingView(
        elapsed: _elapsed,
        amplitudeBuffer: _amplitudeBuffer,
        amplitudeCount: _amplitudeCount,
        amplitudeWriteIndex: _amplitudeWriteIndex,
        l10n: l10n,
        theme: theme,
        onStop: _stopRecording,
        onCancel: _cancelRecording,
      );
    }

    if (_recordingPending) {
      return const Center(child: LoadingIcon(size: 28, strokeWidth: 2.5));
    }

    return CaptureIdleView(
      state: state,
      l10n: l10n,
      theme: theme,
      isTablet: isTablet,
      onMicTap: _startRecording,
      onTypeInstead: () => setState(() => _textMode = true),
    );
  }
}
