/// Audio stage: preview player + save/loop/practice actions.
///
/// Shows a collapsed summary of the previous stages (language pair, style,
/// truncated target text), an inline audio preview player, a collapsible
/// voice chip, and two primary actions: "Say something else" (loop) and
/// "Practice now" (navigate to player).
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/azure_voice.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/word_boundary_segmenter.dart';
import 'package:enjoy_player/features/craft/presentation/craft_solid_transcript_stt_hint.dart';
import 'package:enjoy_player/features/craft/presentation/voice_picker.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Audio stage for the Express flow.
class AudioStage extends ConsumerStatefulWidget {
  const AudioStage({super.key});

  @override
  ConsumerState<AudioStage> createState() => _AudioStageState();
}

class _AudioStageState extends ConsumerState<AudioStage> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _completeSub;
  bool _voiceExpanded = false;

  @override
  void dispose() {
    _cancelStreams();
    unawaited(_player?.dispose());
    super.dispose();
  }

  void _cancelStreams() {
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(_completeSub?.cancel());
    _positionSub = null;
    _durationSub = null;
    _completeSub = null;
  }

  Future<void> _togglePlay() async {
    final bytes = ref.read(craftControllerProvider).previewAudioBytes;
    if (bytes == null) return;

    _player ??= AudioPlayer();

    if (_isPlaying) {
      await _player!.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      // Subscribe to streams on first play.
      if (_positionSub == null) {
        _positionSub = _player!.onPositionChanged.listen((pos) {
          if (!mounted) return;
          setState(() {
            // Clamp: player callbacks can report position past duration.
            _position = _duration > Duration.zero && pos > _duration
                ? _duration
                : pos;
          });
        });
        _durationSub = _player!.onDurationChanged.listen((dur) {
          if (!mounted) return;
          setState(() {
            _duration = dur;
            if (_position > dur) _position = dur;
          });
        });
        _completeSub = _player!.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _position = Duration.zero;
            });
          }
        });
      }

      if (_position == _duration && _duration > Duration.zero) {
        await _player!.seek(Duration.zero);
      }
      await _player!.play(BytesSource(bytes));
      if (mounted) setState(() => _isPlaying = true);
    }
  }

  Future<void> _saveAndCaptureNext() async {
    final hadSolid =
        buildCraftPrimaryTimelineJson(
          ref.read(craftControllerProvider).previewWordBoundaries,
        ) !=
        null;
    await ref.read(craftControllerProvider.notifier).saveAndCaptureNext();
    if (!mounted) return;
    // If save failed, don't show success snackbar or tear down the player —
    // the failure card will be shown by the build method instead.
    final failure = ref.read(craftControllerProvider).failure;
    if (failure != null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.craftSavedToLibrary),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    maybeShowCraftSolidTranscriptSttHint(context, savedSolidTimeline: hadSolid);
    // Reset playback state for the next capture.
    _cancelStreams();
    unawaited(_player?.dispose());
    _player = null;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
  }

  Future<void> _saveAndPractice() async {
    final hadSolid =
        buildCraftPrimaryTimelineJson(
          ref.read(craftControllerProvider).previewWordBoundaries,
        ) !=
        null;
    final mediaId = await ref
        .read(craftControllerProvider.notifier)
        .saveAndPractice();
    if (!mounted || mediaId == null) return;

    maybeShowCraftSolidTranscriptSttHint(context, savedSolidTimeline: hadSolid);
    final state = ref.read(craftControllerProvider);
    final targetId = state.dedupedExistingId ?? mediaId;
    if (mounted) openPlayerRoute(context, targetId);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(craftControllerProvider);
    final theme = Theme.of(context);

    // Re-synth (voice change) replaces preview bytes — reset the local player.
    ref.listen<Uint8List?>(
      craftControllerProvider.select((s) => s.previewAudioBytes),
      (prev, next) {
        if (prev == next) return;
        _cancelStreams();
        unawaited(_player?.dispose());
        _player = null;
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
            _duration = Duration.zero;
          });
        }
      },
    );

    if (state.isSynthesizing) {
      return _LoadingView(l10n: l10n);
    }

    if (state.failure != null) {
      return _FailureCard(
        failure: state.failure!,
        l10n: l10n,
        onRetry: () =>
            ref.read(craftControllerProvider.notifier).generateAudio(),
      );
    }

    if (!state.hasPreview) {
      // No audio — shouldn't normally happen, but show a fallback.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.craftAudioPreview, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(craftControllerProvider.notifier).generateAudio(),
                child: Text(l10n.craftRewriteGenerateAudio),
              ),
            ],
          ),
        ),
      );
    }

    final sourceLang = state.sourceLanguage?.toUpperCase() ?? '—';
    final targetLang = state.targetLanguage.toUpperCase();
    final previewText = (state.translatedText ?? state.synthText);
    final truncatedText = previewText.length > 100
        ? '${previewText.substring(0, 100)}…'
        : previewText;

    final voiceLabel = _voiceDisplayLabel(state.selectedVoice);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SummaryBlock(
                sourceLang: sourceLang,
                targetLang: targetLang,
                text: truncatedText,
                voice: voiceLabel,
                theme: theme,
              ),
              const SizedBox(height: 20),
              _PreviewPlayer(
                isPlaying: _isPlaying,
                position: _position,
                duration: _duration,
                onToggle: _togglePlay,
                onSeek: (pos) async {
                  await _player?.seek(pos);
                  if (mounted) setState(() => _position = pos);
                },
                fmt: _fmt,
                theme: theme,
              ),
              const SizedBox(height: 16),
              _VoiceChip(
                expanded: _voiceExpanded,
                synthLanguage: state.synthLanguage,
                selectedVoice: state.selectedVoice,
                voiceLabel: voiceLabel,
                theme: theme,
                onToggle: () {
                  setState(() => _voiceExpanded = !_voiceExpanded);
                },
                onVoiceChanged: (voice) {
                  ref
                      .read(craftControllerProvider.notifier)
                      .setSelectedVoice(voice);
                  unawaited(
                    ref.read(craftControllerProvider.notifier).generateAudio(),
                  );
                },
              ),
              const SizedBox(height: 24),
              if (state.isSaving)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton.icon(
                  onPressed: _saveAndPractice,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.craftAudioPracticeNow),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _saveAndCaptureNext,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.craftAudioSaySomethingElse),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String? _voiceDisplayLabel(String? voiceId) {
  if (voiceId == null || voiceId.isEmpty) return null;
  for (final v in kAzureVoices) {
    if (v.id == voiceId) return v.label;
  }
  return voiceId;
}

// === Sub-widgets ===

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.l10n});

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
            l10n.craftLoadingSynthesizing,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.sourceLang,
    required this.targetLang,
    required this.text,
    required this.voice,
    required this.theme,
  });

  final String sourceLang;
  final String targetLang;
  final String text;
  final String? voice;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language pair.
          Text(
            '$sourceLang  →  $targetLang',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Truncated target text.
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (voice != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.record_voice_over_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    voice!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceChip extends StatelessWidget {
  const _VoiceChip({
    required this.expanded,
    required this.synthLanguage,
    required this.selectedVoice,
    required this.voiceLabel,
    required this.theme,
    required this.onToggle,
    required this.onVoiceChanged,
  });

  final bool expanded;
  final String synthLanguage;
  final String? selectedVoice;
  final String? voiceLabel;
  final ThemeData theme;
  final VoidCallback onToggle;
  final void Function(String) onVoiceChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.record_voice_over_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.craftVoiceLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      voiceLabel ?? l10n.craftVoiceLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            VoicePicker(
              language: synthLanguage,
              selectedVoice: selectedVoice,
              onChanged: onVoiceChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewPlayer extends StatelessWidget {
  const _PreviewPlayer({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onToggle,
    required this.onSeek,
    required this.fmt,
    required this.theme,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggle;
  final ValueChanged<Duration> onSeek;
  final String Function(Duration) fmt;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 32,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                // Position can briefly overshoot duration from the player
                // stream; Slider asserts if value > max.
                Slider(
                  value: position.inMilliseconds.toDouble().clamp(
                    0.0,
                    duration.inMilliseconds.toDouble().clamp(
                      1.0,
                      double.infinity,
                    ),
                  ),
                  max: duration.inMilliseconds.toDouble().clamp(
                    1.0,
                    double.infinity,
                  ),
                  onChanged: duration > Duration.zero
                      ? (v) => onSeek(Duration(milliseconds: v.round()))
                      : null,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fmt(
                        position > duration && duration > Duration.zero
                            ? duration
                            : position,
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      fmt(duration),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
