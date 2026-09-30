/// Capture stage: voice-first input for the Craft Express flow.
///
/// Owns the [AudioRecorder] instance (recreated after each stop, mirroring
/// the proven pattern from `ShadowReadingPanel`). Provides a large mic button
/// for recording and a "type instead" text fallback.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_failure_card.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_loading_view.dart';
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

  /// Recreated after every `stop()` — `record` on Windows can keep stale
  /// Media Foundation state on the same instance.
  AudioRecorder _recorder = AudioRecorder();
  bool _recordingPending = false;
  bool _textMode = false;

  /// True while this widget owns an in-flight capture on [CraftController].
  /// Tracked locally so [dispose] can clear the session flag without [ref].
  bool _sessionCapturing = false;
  CraftController? _craft;

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
  }

  @override
  void dispose() {
    _stopElapsedTimer();
    _cancelAmplitudeStream();
    _textController.dispose();
    _focusNode.dispose();
    if (_sessionCapturing) {
      _craft?.cancelCapture();
      _sessionCapturing = false;
    }
    unawaited(() async {
      try {
        await _recorder.stop();
      } catch (_) {}
      try {
        await _recorder.dispose();
      } catch (_) {}
    }());
    super.dispose();
  }

  void _cancelAmplitudeStream() {
    unawaited(_amplitudeSub?.cancel());
    _amplitudeSub = null;
  }

  RecordConfig _buildConfig() => const RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 16000,
    numChannels: 1,
  );

  Future<void> _startRecording() async {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.read(craftControllerProvider);

    if (state.isBusy) return;
    _recordingPending = true;

    bool granted;
    try {
      granted = await _recorder.hasPermission();
    } catch (e, st) {
      _log.warning('hasPermission failed', e, st);
      _recordingPending = false;
      if (mounted) setState(() {});
      return;
    }
    if (!granted) {
      _recordingPending = false;
      if (mounted) {
        AppNotice.warning(context, l10n.craftRecordingMicDenied);
      }
      return;
    }

    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/craft_recordings');
    await dir.create(recursive: true);
    final outPath =
        '${dir.path}/craft_${DateTime.now().millisecondsSinceEpoch}.wav';

    try {
      await _recorder.start(_buildConfig(), path: outPath);
    } catch (e, st) {
      _log.warning('recorder.start failed', e, st);
      _recordingPending = false;
      await _resetRecorderInstance();
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
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e, st) {
      _log.warning('recorder.stop failed', e, st);
    }
    _stopElapsedTimer();
    _cancelAmplitudeStream();
    _recordingStartedAt = null;
    _amplitudeWriteIndex = 0;
    _amplitudeCount = 0;
    _recordingPending = false;

    await _resetRecorderInstance();

    if (path == null || path.isEmpty) {
      _log.warning('recorder.stop returned no path');
      _sessionCapturing = false;
      ref.read(craftControllerProvider.notifier).cancelCapture();
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
      await ref.read(craftControllerProvider.notifier).stopCapture(bytes);
    } else {
      _sessionCapturing = false;
      ref.read(craftControllerProvider.notifier).cancelCapture();
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

    String? path;
    try {
      path = await _recorder.stop();
    } catch (e, st) {
      _log.warning('recorder.stop on cancel failed', e, st);
    }
    await _resetRecorderInstance();

    if (path != null && path.isNotEmpty) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  /// Discard the current recording without committing to ASR.
  Future<void> _cancelRecording() async {
    await _discardMicOnly();
    _sessionCapturing = false;
    ref.read(craftControllerProvider.notifier).cancelCapture();
  }

  Future<void> _resetRecorderInstance() async {
    final old = _recorder;
    _recorder = AudioRecorder();
    try {
      await old.dispose();
    } catch (e, st) {
      _log.fine('recorder dispose after stop', e, st);
    }
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
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
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
      return _TextFallback(
        controller: _textController,
        focusNode: _focusNode,
        l10n: l10n,
        onSubmit: _submitText,
        onBack: () => setState(() => _textMode = false),
      );
    }

    if (state.isCapturing) {
      return _RecordingView(
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

    return _IdleView(
      state: state,
      l10n: l10n,
      theme: theme,
      isTablet: isTablet,
      onMicTap: _startRecording,
      onTypeInstead: () => setState(() => _textMode = true),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.state,
    required this.l10n,
    required this.theme,
    required this.isTablet,
    required this.onMicTap,
    required this.onTypeInstead,
  });

  final CraftJobState state;
  final AppLocalizations l10n;
  final ThemeData theme;
  final bool isTablet;
  final VoidCallback onMicTap;
  final VoidCallback onTypeInstead;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final scheme = theme.colorScheme;
    final buttonSize = isTablet ? 88.0 : 72.0;
    final sourceLang = state.sourceLanguage?.toUpperCase() ?? '—';
    final targetLang = state.targetLanguage.toUpperCase();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: ShapeDecoration(
              color: t.fill,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(t.radiusFull),
                side: BorderSide(color: t.hairline),
              ),
            ),
            child: Text(
              '$sourceLang  →  $targetLang',
              style: enjoyMonoStyle(
                context,
                size: 13,
                weight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: t.space24),
          Text(
            l10n.craftCaptureTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: t.space8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              l10n.craftCaptureSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: t.space48),
          SizedBox(
            width: buttonSize * 2.2,
            height: buttonSize * 2.2,
            child: Center(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: const CircleBorder(),
                  gradient: RadialGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.28),
                      scheme.primary.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.35, 0.7, 1],
                  ),
                ),
                child: EnjoyPressable(
                  onTap: onMicTap,
                  borderRadius: BorderRadius.circular(buttonSize / 2),
                  pressedScale: 0.95,
                  semanticsLabel: l10n.craftCaptureTitle,
                  child: AnimatedContainer(
                    duration: t.motionFast,
                    width: buttonSize,
                    height: buttonSize,
                    decoration: enjoyLitFillDecoration(
                      base: scheme.primary,
                      shape: CircleBorder(
                        side: enjoyLitHighlightSide(alpha: 0.16),
                      ),
                      shadow: enjoyLitShadow(
                        scheme.primary,
                        alpha: 0.36,
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ),
                    child: Icon(
                      EnjoyIcons.micFill,
                      color: scheme.onPrimary,
                      size: buttonSize * 0.46,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: t.space24),
          EnjoyButton.ghost(
            onPressed: onTypeInstead,
            icon: EnjoyIcons.keyboard,
            child: Text(l10n.craftCaptureTypeInstead),
          ),
        ],
      ),
    );
  }
}

class _RecordingView extends StatefulWidget {
  const _RecordingView({
    required this.elapsed,
    required this.amplitudeBuffer,
    required this.amplitudeCount,
    required this.amplitudeWriteIndex,
    required this.l10n,
    required this.theme,
    required this.onStop,
    required this.onCancel,
  });

  final Duration elapsed;
  final Float32List amplitudeBuffer;
  final int amplitudeCount;
  final int amplitudeWriteIndex;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  @override
  State<_RecordingView> createState() => _RecordingViewState();
}

class _RecordingViewState extends State<_RecordingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    unawaited(_pulse.repeat(reverse: true));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final theme = widget.theme;
    final scheme = theme.colorScheme;
    final count = widget.amplitudeCount;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatDurationHms(widget.elapsed),
            style: enjoyMonoStyle(
              context,
              size: 34,
              weight: FontWeight.w600,
              color: scheme.error,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: t.space24),
          Center(
            child: SizedBox(
              width: _AmplitudeBarsPainter.trackWidthFor(
                widget.amplitudeBuffer.length,
              ),
              height: 56,
              child: CustomPaint(
                painter: _AmplitudeBarsPainter(
                  buffer: widget.amplitudeBuffer,
                  count: count,
                  writeIndex: widget.amplitudeWriteIndex,
                  color: t.accentInk,
                ),
              ),
            ),
          ),
          SizedBox(height: t.space40),
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final v = _pulse.value;
              return SizedBox(
                width: 96 + v * 8,
                height: 96 + v * 8,
                child: Center(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: const CircleBorder(),
                      color: scheme.error.withValues(alpha: 0.12 + v * 0.08),
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: EnjoyPressable(
              onTap: widget.onStop,
              borderRadius: BorderRadius.circular(40),
              pressedScale: 0.95,
              semanticsLabel: widget.l10n.craftCaptureStop,
              child: AnimatedContainer(
                duration: t.motionFast,
                width: 80,
                height: 80,
                decoration: enjoyLitFillDecoration(
                  base: scheme.error,
                  shape: CircleBorder(side: enjoyLitHighlightSide(alpha: 0.16)),
                  shadow: enjoyLitShadow(
                    scheme.error,
                    alpha: 0.38,
                    blurRadius: 18,
                    spreadRadius: 0,
                  ),
                ),
                child: Icon(EnjoyIcons.stop, size: 40, color: scheme.onError),
              ),
            ),
          ),
          SizedBox(height: t.space12),
          Text(
            widget.l10n.craftCaptureStop,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: t.space8),
          EnjoyButton.ghost(
            onPressed: widget.onCancel,
            child: Text(widget.l10n.craftCaptureCancel),
          ),
        ],
      ),
    );
  }
}

class _AmplitudeBarsPainter extends CustomPainter {
  const _AmplitudeBarsPainter({
    required this.buffer,
    required this.count,
    required this.writeIndex,
    required this.color,
  });

  static const double _barWidth = 3.5;
  static const double _spacing = 3.0;

  /// Width of a fixed [barCount]-slot amplitude track.
  static double trackWidthFor(int barCount) =>
      barCount * _barWidth + (barCount - 1) * _spacing;

  final Float32List buffer;
  final int count;
  final int writeIndex;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const minHeight = 6.0;
    final maxHeight = size.height;
    final radius = const Radius.circular(2);
    final trackWidth = trackWidthFor(buffer.length);
    final startX = (size.width - trackWidth) / 2;

    if (count == 0) {
      const placeholderCount = 12;
      final placeholderWidth = trackWidthFor(placeholderCount);
      final placeholderStart = startX + (trackWidth - placeholderWidth) / 2;
      for (var i = 0; i < placeholderCount; i++) {
        final h = 10 + (i % 3) * 6.0;
        final x = placeholderStart + i * (_barWidth + _spacing);
        paint.color = color.withValues(alpha: 0.25);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, (maxHeight - h) / 2, _barWidth, h),
            radius,
          ),
          paint,
        );
      }
      return;
    }

    for (var i = 0; i < count; i++) {
      final readIndex =
          (writeIndex - count + i + buffer.length) % buffer.length;
      final level = buffer[readIndex];
      final h = (level * maxHeight).clamp(minHeight, maxHeight);
      final x = startX + i * (_barWidth + _spacing);
      paint.color = Color.lerp(color.withValues(alpha: 0.45), color, level)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (maxHeight - h) / 2, _barWidth, h),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmplitudeBarsPainter old) {
    return old.count != count ||
        old.writeIndex != writeIndex ||
        old.color != color;
  }
}

class _TextFallback extends StatelessWidget {
  const _TextFallback({
    required this.controller,
    required this.focusNode,
    required this.l10n,
    required this.onSubmit,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final AppLocalizations l10n;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: EnjoyButton.ghost(
            onPressed: onBack,
            icon: EnjoyIcons.mic,
            child: Text(l10n.craftCaptureTitle),
          ),
        ),
        SizedBox(height: t.space16),
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          maxLines: 5,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            hintText: l10n.craftTextInputHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radiusLg),
            ),
          ),
        ),
        SizedBox(height: t.space16),
        EnjoyButton.primary(
          onPressed: onSubmit,
          icon: EnjoyIcons.arrowRight,
          expand: true,
          child: Text(l10n.craftRewriteGenerateAudio),
        ),
      ],
    );
  }
}
