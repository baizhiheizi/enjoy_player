/// Capture stage: voice-first input for the Craft Express flow.
///
/// Owns the [AudioRecorder] instance (recreated after each stop, mirroring
/// the proven pattern from `ShadowReadingPanel`). Provides a large mic button
/// for recording and a "type instead" text fallback.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Voice capture stage for the Express flow.
class CaptureStage extends ConsumerStatefulWidget {
  const CaptureStage({super.key});

  @override
  ConsumerState<CaptureStage> createState() => _CaptureStageState();
}

class _CaptureStageState extends ConsumerState<CaptureStage>
    with TickerProviderStateMixin {
  static final _log = logNamed('craft.capture');

  /// Recreated after every `stop()` — `record` on Windows can keep stale
  /// Media Foundation state on the same instance.
  AudioRecorder _recorder = AudioRecorder();
  bool _recordingPending = false;
  bool _textMode = false;
  bool _prefsSeeded = false;

  DateTime? _recordingStartedAt;
  Duration _elapsed = Duration.zero;
  Ticker? _ticker;
  List<double> _amplitudeLevels = const [];
  StreamSubscription? _amplitudeSub;

  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _stopTicker();
    _cancelAmplitudeStream();
    _textController.dispose();
    _focusNode.dispose();
    unawaited(() async {
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

    // Seed source/target language from prefs on first entry (mirrors
    // TranslateTool's initState so the Express flow has a valid source lang).
    if (!_prefsSeeded) {
      _prefsSeeded = true;
      final prefs = ref.read(appPreferencesCtrlProvider);
      final prefsState = prefs.whenOrNull(data: (s) => s);
      final nativeLang = canonicalMediaLanguageTag(
        prefsState?.effectiveNativeLanguage ?? 'en',
      );
      final learnLang = canonicalMediaLanguageTag(
        prefsState?.effectiveLearningLanguage ?? 'en',
      );
      ref.read(craftControllerProvider.notifier)
        ..setSourceLanguage(nativeLang)
        ..setTargetLanguage(learnLang);
    }

    // Permission check.
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.craftRecordingMicDenied)));
      }
      return;
    }

    // Temp output path.
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
    _amplitudeLevels = [];
    _startTicker();
    _startAmplitudeStream();

    ref.read(craftControllerProvider.notifier).startCapture();
    if (mounted) setState(() {});
  }

  Future<void> _stopRecording() async {
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e, st) {
      _log.warning('recorder.stop failed', e, st);
    }
    _stopTicker();
    _cancelAmplitudeStream();
    _recordingStartedAt = null;
    _amplitudeLevels = [];

    await _resetRecorderInstance();

    if (path == null || path.isEmpty) {
      _log.warning('recorder.stop returned no path');
      return;
    }

    // Read the WAV bytes.
    Uint8List? bytes;
    try {
      bytes = await File(path).readAsBytes();
      await File(path).delete();
    } catch (e, st) {
      _log.warning('read/delete recording file failed', e, st);
    }

    if (bytes != null && bytes.isNotEmpty) {
      await ref.read(craftControllerProvider.notifier).stopCapture(bytes);
    }
    if (mounted) setState(() {});
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

  void _startTicker() {
    _stopTicker();
    _ticker = createTicker((_) {
      if (_recordingStartedAt == null) return;
      final elapsed = DateTime.now().difference(_recordingStartedAt!);
      if (mounted) setState(() => _elapsed = elapsed);
    });
    unawaited(_ticker!.start());
  }

  void _stopTicker() {
    _ticker?.stop();
    _ticker = null;
  }

  void _startAmplitudeStream() {
    _cancelAmplitudeStream();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
          // Normalize dBFS to 0..1 range for bar visualization.
          // Typical speech is roughly -20 to 0 dBFS.
          final level = ((amp.current + 40) / 40).clamp(0.05, 1.0);
          if (mounted) {
            setState(() {
              _amplitudeLevels = [..._amplitudeLevels, level];
              // Keep last 40 bars.
              if (_amplitudeLevels.length > 40) {
                _amplitudeLevels = _amplitudeLevels.sublist(
                  _amplitudeLevels.length - 40,
                );
              }
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

    // Show transcribing indicator.
    if (state.isTranscribing) {
      return _TranscribingIndicator(l10n: l10n);
    }

    // Show failure card if any.
    if (state.failure != null) {
      return _FailureCard(
        failure: state.failure!,
        l10n: l10n,
        onRetry: _startRecording,
      );
    }

    // Text fallback mode.
    if (_textMode) {
      return _TextFallback(
        controller: _textController,
        focusNode: _focusNode,
        l10n: l10n,
        onSubmit: _submitText,
        onBack: () => setState(() => _textMode = false),
      );
    }

    // Recording active.
    if (state.isCapturing) {
      return _RecordingView(
        elapsed: _elapsed,
        levels: _amplitudeLevels,
        l10n: l10n,
        theme: theme,
        onStop: _stopRecording,
      );
    }

    // Recording pending (permission check).
    if (_recordingPending) {
      return const Center(child: CircularProgressIndicator());
    }

    // Idle state.
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

// === Sub-widgets ===

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
    final buttonSize = isTablet ? 88.0 : 72.0;
    final sourceLang = state.sourceLanguage?.toUpperCase() ?? '—';
    final targetLang = state.targetLanguage.toUpperCase();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Language pair.
          Text(
            '$sourceLang  →  $targetLang',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),

          // Title + subtitle.
          Text(
            l10n.craftCaptureTitle,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.craftCaptureSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Mic button.
          GestureDetector(
            onTap: onMicTap,
            child: Container(
              width: buttonSize * 2,
              height: buttonSize * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
              ),
              child: Center(
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    size: buttonSize * 0.5,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Type instead link.
          TextButton.icon(
            onPressed: onTypeInstead,
            icon: const Icon(Icons.keyboard_rounded, size: 18),
            label: Text(l10n.craftCaptureTypeInstead),
          ),
        ],
      ),
    );
  }
}

class _RecordingView extends StatelessWidget {
  const _RecordingView({
    required this.elapsed,
    required this.levels,
    required this.l10n,
    required this.theme,
    required this.onStop,
  });

  final Duration elapsed;
  final List<double> levels;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onStop;

  String get _timeString {
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer.
          Text(
            _timeString,
            style: theme.textTheme.displaySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),

          // Waveform animation.
          SizedBox(
            height: 48,
            child: levels.isEmpty
                ? Center(
                    child: Text(
                      '...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: levels.map((level) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 4,
                        height: (level * 48).clamp(4.0, 48.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 32),

          // Stop button.
          GestureDetector(
            onTap: onStop,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.error,
              ),
              child: Icon(
                Icons.stop_rounded,
                size: 40,
                color: theme.colorScheme.onError,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.craftCaptureStop,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscribingIndicator extends StatelessWidget {
  const _TranscribingIndicator({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '…',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.mic_rounded, size: 18),
              label: Text(l10n.craftCaptureTitle),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          maxLines: 5,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            hintText: l10n.craftTextInputHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(l10n.craftRewriteGenerateAudio),
        ),
      ],
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({
    required this.failure,
    required this.l10n,
    required this.onRetry,
  });

  final CraftFailure failure;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  String _actionLabel() {
    switch (failure.action) {
      case CraftFailureAction.openAiSettings:
        return l10n.craftOpenAiSettings;
      case CraftFailureAction.signIn:
        return l10n.craftSignInRequired;
      default:
        return l10n.craftRetry;
    }
  }

  void _handleAction(BuildContext context) {
    switch (failure.action) {
      case CraftFailureAction.openAiSettings:
        unawaited(context.push('/settings/ai-providers'));
      case CraftFailureAction.signIn:
        unawaited(context.push('/sign-in'));
      default:
        onRetry();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              failure.message(l10n),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _handleAction(context),
              child: Text(_actionLabel()),
            ),
          ],
        ),
      ),
    );
  }
}
