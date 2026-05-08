/// Shadow-reading stack below echo segment — mirrors web `ShadowReadingPanel`.
library;

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import 'package:enjoy_player/core/audio/recording_preview_player_provider.dart';
import 'package:enjoy_player/core/audio/wav_duration_ms.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'pitch_contour_section.dart';

final _log = logNamed('ShadowReadingPanel');

String _shortSaveError(Object e) {
  final s = e.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.length <= 180) return s;
  return '${s.substring(0, 177)}…';
}

class ShadowReadingPanel extends ConsumerStatefulWidget {
  const ShadowReadingPanel({
    required this.mediaId,
    required this.targetType,
    required this.language,
    required this.startSec,
    required this.endSec,
    required this.referenceText,
    required this.echoActive,
    this.currentTimeSec,
    super.key,
  });

  final String mediaId;
  final String targetType;
  final String language;
  final double startSec;
  final double endSec;
  final String referenceText;
  final bool echoActive;
  final double? currentTimeSec;

  @override
  ConsumerState<ShadowReadingPanel> createState() => _ShadowReadingPanelState();
}

class _ShadowReadingPanelState extends ConsumerState<ShadowReadingPanel> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  int? _selectedIdx;
  String? _mediaPath;
  Future<String?>? _mediaPathFuture;

  Future<String?> _mediaPathFutureOnce() {
    return _mediaPathFuture ??= () async {
      _mediaPath ??= await _resolveMediaPath();
      return _mediaPath;
    }();
  }

  @override
  void didUpdateWidget(covariant ShadowReadingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) {
      _mediaPath = null;
      _mediaPathFuture = null;
    }
  }

  @override
  void dispose() {
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<String?> _resolveMediaPath() async {
    final db = ref.read(appDatabaseProvider);
    final v = await db.videoDao.getById(widget.mediaId);
    final a = v == null ? await db.audioDao.getById(widget.mediaId) : null;
    final uri = v?.localUri ?? a?.localUri;
    if (uri == null || uri.isEmpty) return null;
    try {
      return Uri.parse(uri).toFilePath();
    } catch (_) {
      return uri;
    }
  }

  double? get _relativeSec {
    final t = widget.currentTimeSec;
    if (t == null) return null;
    return (t - widget.startSec).clamp(0.0, widget.endSec - widget.startSec);
  }

  Future<void> _toggleRecord(AppLocalizations l10n) async {
    if (!widget.echoActive) return;
    if (_recording) {
      String? path;
      try {
        path = await _recorder.stop();
      } catch (e, st) {
        _log.warning('microphone stop failed', e, st);
        _recording = false;
        if (mounted) setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.shadowRecordingSaveFailed(_shortSaveError(e)),
              ),
            ),
          );
        }
        return;
      }
      _recording = false;
      setState(() {});
      if (path == null || path.isEmpty) {
        _log.warning('recorder.stop returned no path');
        return;
      }
      await _persistRecording(path, l10n);
      return;
    }

    await _mediaPathFutureOnce();

    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'recordings'));
    await dir.create(recursive: true);
    final id = const Uuid().v4();
    final outPath = p.join(dir.path, '$id.wav');

    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shadowRecordingMicDenied)),
        );
      }
      return;
    }

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: outPath,
    );
    _recording = true;
    setState(() {});
  }

  Future<void> _persistRecording(String wavPath, AppLocalizations l10n) async {
    try {
      final file = File(wavPath);
      if (!await file.exists()) {
        _log.warning('recording wav missing at path: $wavPath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.shadowRecordingSaveFailed('Recorded file was not found.'),
              ),
            ),
          );
        }
        return;
      }
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();

      final parsedMs = wavDurationMsFromBytes(bytes);
      final durationMs = parsedMs ?? 0;
      if (parsedMs == null && bytes.isNotEmpty) {
        _log.warning(
          'could not parse WAV duration ($wavPath, ${bytes.length} bytes)',
        );
      }

      final db = ref.read(appDatabaseProvider);
      final id = p.basenameWithoutExtension(wavPath);
      final now = DateTime.now();
      final startMs = (widget.startSec * 1000).round();
      final durMs = ((widget.endSec - widget.startSec) * 1000).round();
      final row = RecordingRow(
        id: id,
        targetType: widget.targetType,
        targetId: widget.mediaId,
        referenceStartMs: startMs,
        referenceDurationMs: durMs,
        referenceText: widget.referenceText,
        language: widget.language,
        durationMs: durationMs,
        md5: hash,
        audioUrl: null,
        pronunciationScore: null,
        assessmentJson: null,
        localPath: wavPath,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      await db.recordingDao.insertRow(row);
    } catch (e, st) {
      _log.warning('save recording failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shadowRecordingSaveFailed(_shortSaveError(e))),
          ),
        );
      }
    }
  }

  Future<void> _playRecording(String path) async {
    try {
      await ref.read(recordingPreviewPlayerProvider).play(path);
    } catch (e, st) {
      _log.warning('shadow take playback failed', e, st);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shadowRecordingPlaybackFailed)),
      );
    }
  }

  Future<void> _deleteRecording(RecordingRow r) async {
    final lp = r.localPath;
    if (lp != null && lp.isNotEmpty) {
      try {
        await File(lp).delete();
      } catch (_) {}
    }
    await ref.read(appDatabaseProvider).recordingDao.deleteId(r.id);
    setState(() => _selectedIdx = null);
  }

  Future<void> _onHotkeyRecordingPulse(AppLocalizations l10n) async {
    if (!widget.echoActive) return;
    await _toggleRecord(l10n);
  }

  Future<void> _onHotkeyPlaybackPulse() async {
    if (!widget.echoActive) return;
    final db = ref.read(appDatabaseProvider);
    final list = await db.recordingDao.listByEchoRegion(
      targetType: widget.targetType,
      targetId: widget.mediaId,
      language: widget.language,
      echoStartMs: (widget.startSec * 1000).round(),
      echoEndMs: (widget.endSec * 1000).round(),
    );
    if (!mounted) return;
    if (list.isEmpty) return;
    final i = _selectedIdx ?? 0;
    final safe = i >= 0 && i < list.length ? i : 0;
    final path = list[safe].localPath;
    if (path != null && path.isNotEmpty) {
      await _playRecording(path);
    }
  }

  void _onHotkeyAssessmentPulse() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.hotkeysStubAssessment)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<int>(
      shadowReadingHotkeyBusProvider.select((s) => s.recording),
      (prev, next) {
        if (prev == next) return;
        unawaited(_onHotkeyRecordingPulse(l10n));
      },
    );
    ref.listen<int>(
      shadowReadingHotkeyBusProvider.select((s) => s.playback),
      (prev, next) {
        if (prev == next) return;
        unawaited(_onHotkeyPlaybackPulse());
      },
    );
    ref.listen<int>(
      shadowReadingHotkeyBusProvider.select((s) => s.assessment),
      (prev, next) {
        if (prev == next) return;
        _onHotkeyAssessmentPulse();
      },
    );

    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);

    return FutureBuilder<String?>(
      future: _mediaPathFutureOnce(),
      builder: (context, snap) {
        final mediaPath = snap.data;
        final db = ref.watch(appDatabaseProvider);
        final echoStartMs = (widget.startSec * 1000).round();
        final echoEndMs = (widget.endSec * 1000).round();

        return StreamBuilder<List<RecordingRow>>(
          stream: db.recordingDao.watchByEchoRegion(
            targetType: widget.targetType,
            targetId: widget.mediaId,
            language: widget.language,
            echoStartMs: echoStartMs,
            echoEndMs: echoEndMs,
          ),
          builder: (context, recSnap) {
            final list = recSnap.data ?? [];
            final sel =
                _selectedIdx != null &&
                    _selectedIdx! >= 0 &&
                    _selectedIdx! < list.length
                ? list[_selectedIdx!]
                : null;

            return Padding(
              padding: EdgeInsets.only(bottom: tok.space8),
              child: Material(
                color: Color.lerp(
                  tok.echoActive.withValues(alpha: 0.22),
                  scheme.surfaceContainerHighest,
                  0.50,
                ),
                borderRadius: BorderRadius.circular(tok.radiusMd),
                child: Padding(
                  padding: EdgeInsets.all(tok.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mic_none_rounded, color: scheme.tertiary),
                          SizedBox(width: tok.space8),
                          Expanded(
                            child: Text(
                              l10n.shadowReadingTitle,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: tok.space8),
                      Text(
                        l10n.shadowReadingHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      if (mediaPath != null && mediaPath.isNotEmpty) ...[
                        SizedBox(height: tok.space12),
                        PitchContourSection(
                          mediaPath: mediaPath,
                          startSec: widget.startSec,
                          endSec: widget.endSec,
                          currentTimeRelativeSec: _relativeSec,
                          selectedRecordingPath: sel?.localPath,
                          selectedRecordingDurationMs: sel?.durationMs,
                        ),
                      ],
                      SizedBox(height: tok.space12),
                      Text(
                        l10n.shadowRecordingExisting,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      SizedBox(height: tok.space8),
                      if (list.isEmpty)
                        Text(
                          l10n.shadowRecordingEmpty,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: list.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: tok.space8),
                          itemBuilder: (context, i) {
                            final r = list[i];
                            final selected = _selectedIdx == i;
                            return Material(
                              color:
                                  selected
                                      ? scheme.primary.withValues(alpha: 0.12)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(tok.radiusSm),
                              child: ListTile(
                                dense: true,
                                selected: selected,
                                title: Text(
                                  '${l10n.shadowRecordingTake} ${list.length - i}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                subtitle: Text(
                                  '${(r.durationMs / 1000).toStringAsFixed(1)} s',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: l10n.shadowRecordingPlay,
                                      icon: const Icon(Icons.play_arrow),
                                      onPressed:
                                          widget.echoActive && r.localPath != null
                                          ? () => _playRecording(r.localPath!)
                                          : null,
                                    ),
                                    IconButton(
                                      tooltip: l10n.shadowRecordingDelete,
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: scheme.error,
                                      ),
                                      onPressed:
                                          widget.echoActive
                                          ? () => _deleteRecording(r)
                                          : null,
                                    ),
                                  ],
                                ),
                                onTap:
                                    widget.echoActive
                                    ? () => setState(() => _selectedIdx = i)
                                    : null,
                              ),
                            );
                          },
                        ),
                      SizedBox(height: tok.space12),
                      FilledButton.icon(
                        onPressed:
                            widget.echoActive
                            ? () => _toggleRecord(l10n)
                            : null,
                        icon: Icon(_recording ? Icons.stop : Icons.mic),
                        label: Text(
                          _recording ? l10n.shadowRecordingStop : l10n.shadowRecordingRecord,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
