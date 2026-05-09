/// Shadow-reading stack below echo segment — mirrors web `ShadowReadingPanel`.
library;

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
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
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'pitch_contour_section.dart';

final _log = logNamed('ShadowReadingPanel');

String _shortSaveError(Object e) {
  final s = e.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.length <= 180) return s;
  return '${s.substring(0, 177)}…';
}

RecordingRow? _resolvedSelectedRow(List<RecordingRow> list, String? selectedId) {
  if (list.isEmpty) return null;
  if (selectedId != null) {
    for (final r in list) {
      if (r.id == selectedId) return r;
    }
  }
  return list.first;
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
  String? _selectedRecordingId;
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
    if (oldWidget.mediaId != widget.mediaId ||
        oldWidget.startSec != widget.startSec ||
        oldWidget.endSec != widget.endSec ||
        oldWidget.language != widget.language ||
        oldWidget.targetType != widget.targetType) {
      _selectedRecordingId = null;
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
      await ref
          .read(syncEnqueueProvider)(SyncEntityType.recording, id, SyncAction.create);
      if (mounted) {
        setState(() => _selectedRecordingId = id);
      }
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

  Future<void> _playOrPauseTake(String path) async {
    try {
      await ref.read(recordingPreviewPlayerProvider).playOrPauseTake(path);
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
    await ref
        .read(syncEnqueueProvider)(SyncEntityType.recording, r.id, SyncAction.delete);
    final preview = ref.read(recordingPreviewPlayerProvider);
    final lp = r.localPath;
    if (lp != null && lp.isNotEmpty) {
      try {
        if (preview.loadedPath == File(lp).absolute.path) {
          await preview.stop();
        }
        await File(lp).delete();
      } catch (_) {}
    }
    await ref.read(appDatabaseProvider).recordingDao.deleteId(r.id);
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
    final sel = _resolvedSelectedRow(list, _selectedRecordingId);
    final path = sel?.localPath;
    if (path != null && path.isNotEmpty) {
      await _playOrPauseTake(path);
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
    final ttPlayRecording =
        hotkeyTooltipLabel(ref, 'player.playRecording', l10n.shadowRecordingPlay);
    final ttPauseRecording =
        hotkeyTooltipLabel(ref, 'player.playRecording', l10n.shadowRecordingPause);
    final ttToggleRecording = hotkeyTooltipLabel(
      ref,
      'player.toggleRecording',
      _recording ? l10n.shadowRecordingStop : l10n.shadowRecordingRecord,
    );
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
    final tt = Theme.of(context).textTheme;

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
            final sel = _resolvedSelectedRow(list, _selectedRecordingId);

            return Padding(
              padding: EdgeInsets.only(bottom: tok.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: tok.space12),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: tok.motionFast,
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _recording
                                ? tok.echoActive.withValues(alpha: 0.15)
                                : scheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _recording
                                  ? tok.echoActive.withValues(alpha: 0.6)
                                  : scheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            _recording ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                            size: 20,
                            color: _recording ? tok.echoActive : scheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: tok.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.shadowReadingTitle,
                                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                l10n.shadowReadingHint,
                                style: tt.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section: Pitch
                  if (mediaPath != null && mediaPath.isNotEmpty) ...[
                    _SectionLabel(
                      label: l10n.pitchContourTitle,
                      scheme: scheme,
                      tt: tt,
                    ),
                    SizedBox(height: tok.space8),
                    PitchContourSection(
                      mediaPath: mediaPath,
                      startSec: widget.startSec,
                      endSec: widget.endSec,
                      currentTimeRelativeSec: _relativeSec,
                      selectedRecordingPath: sel?.localPath,
                      selectedRecordingDurationMs: sel?.durationMs,
                    ),
                    SizedBox(height: tok.space16),
                  ],

                  // Section: Your takes
                  _SectionLabel(
                    label: l10n.shadowRecordingExisting,
                    scheme: scheme,
                    tt: tt,
                  ),
                  SizedBox(height: tok.space8),
                  if (list.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: tok.space8),
                      child: Text(
                        l10n.shadowRecordingEmpty,
                        style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    )
                  else if (sel != null)
                    _CompactTakeRow(
                      row: sel,
                      list: list,
                      echoActive: widget.echoActive,
                      scheme: scheme,
                      tok: tok,
                      l10n: l10n,
                      ttPlayRecording: ttPlayRecording,
                      ttPauseRecording: ttPauseRecording,
                      onPlayOrPause: () {
                        final path = sel.localPath;
                        if (path != null && path.isNotEmpty) {
                          unawaited(_playOrPauseTake(path));
                        }
                      },
                      onDelete: () => unawaited(_deleteRecording(sel)),
                      onChooseTake: (id) async {
                        await ref.read(recordingPreviewPlayerProvider).stop();
                        if (mounted) {
                          setState(() => _selectedRecordingId = id);
                        }
                      },
                    ),

                  SizedBox(height: tok.space16),

                  // Section: Record — FAB-style circular button
                  _SectionLabel(
                    label: l10n.shadowRecordingRecord,
                    scheme: scheme,
                    tt: tt,
                  ),
                  SizedBox(height: tok.space12),
                  Center(
                    child: Tooltip(
                      message: ttToggleRecording,
                      child: GestureDetector(
                        onTap: widget.echoActive ? () => _toggleRecord(l10n) : null,
                        child: AnimatedContainer(
                          duration: tok.motionFast,
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _recording ? tok.echoActive : scheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: (_recording ? tok.echoActive : scheme.primary)
                                    .withValues(alpha: 0.35),
                                blurRadius: _recording ? 24 : 14,
                                spreadRadius: _recording ? 2 : 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _recording ? Icons.stop_rounded : Icons.mic_rounded,
                            color: _recording ? Colors.white : scheme.onPrimary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: tok.space4),
                  Center(
                    child: Text(
                      _recording ? l10n.shadowRecordingStop : l10n.shadowRecordingRecord,
                      style: tt.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  SizedBox(height: tok.space8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.scheme,
    required this.tt,
  });

  final String label;
  final ColorScheme scheme;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: tt.labelSmall?.copyWith(
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _CompactTakeRow extends ConsumerWidget {
  const _CompactTakeRow({
    required this.row,
    required this.list,
    required this.echoActive,
    required this.scheme,
    required this.tok,
    required this.l10n,
    required this.ttPlayRecording,
    required this.ttPauseRecording,
    required this.onPlayOrPause,
    required this.onDelete,
    required this.onChooseTake,
  });

  final RecordingRow row;
  final List<RecordingRow> list;
  final bool echoActive;
  final ColorScheme scheme;
  final EnjoyThemeTokens tok;
  final AppLocalizations l10n;
  final String ttPlayRecording;
  final String ttPauseRecording;
  final VoidCallback onPlayOrPause;
  final VoidCallback onDelete;
  final Future<void> Function(String id) onChooseTake;

  int _takeNumber(RecordingRow r) {
    final i = list.indexWhere((e) => e.id == r.id);
    if (i < 0) return list.length;
    return list.length - i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(recordingPreviewPlayerProvider);
    final path = row.localPath;
    final canPlay =
        echoActive &&
        path != null &&
        path.isNotEmpty &&
        !kIsWeb;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tok.radiusMd),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tok.space8, vertical: tok.space4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.shadowRecordingTake} ${_takeNumber(row)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: tok.space4),
                  _TakePreviewTime(row: row),
                ],
              ),
            ),
            if (path != null && path.isNotEmpty)
              StreamBuilder<bool>(
                stream: preview.playing,
                initialData: false,
                builder: (context, playSnap) {
                  final abs = File(path).absolute.path;
                  final playingThis =
                      (playSnap.data ?? false) && preview.loadedPath == abs;
                  return IconButton(
                    tooltip: playingThis ? ttPauseRecording : ttPlayRecording,
                    icon: Icon(
                      playingThis ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    ),
                    onPressed: canPlay ? onPlayOrPause : null,
                  );
                },
              )
            else
              IconButton(
                tooltip: ttPlayRecording,
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: null,
              ),
            IconButton(
              tooltip: l10n.shadowRecordingDelete,
              icon: Icon(
                Icons.delete_outline,
                color: scheme.error,
              ),
              onPressed: echoActive ? onDelete : null,
            ),
            if (list.length > 1)
              PopupMenuButton<String>(
                tooltip: l10n.shadowRecordingChooseTake,
                onSelected: (id) {
                  if (!echoActive) return;
                  unawaited(onChooseTake(id));
                },
                itemBuilder: (context) {
                  return [
                    for (var i = 0; i < list.length; i++)
                      PopupMenuItem<String>(
                        value: list[i].id,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child:
                                  list[i].id == row.id
                                  ? Icon(Icons.check, size: 20, color: scheme.primary)
                                  : const SizedBox.shrink(),
                            ),
                            Expanded(
                              child: Text(
                                '${l10n.shadowRecordingTake} ${list.length - i} · '
                                '${(list[i].durationMs / 1000).toStringAsFixed(1)} s',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ];
                },
                child: Padding(
                  padding: EdgeInsets.all(tok.space8),
                  child: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Take preview time ────────────────────────────────────────────────────────

class _TakePreviewTime extends ConsumerWidget {
  const _TakePreviewTime({required this.row});

  final RecordingRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(recordingPreviewPlayerProvider);
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final lp = row.localPath;
    if (lp == null || lp.isEmpty) {
      return Text(
        '${(row.durationMs / 1000).toStringAsFixed(1)} s',
        style: style,
      );
    }
    final abs = File(lp).absolute.path;
    return StreamBuilder<Duration>(
      stream: preview.position,
      initialData: Duration.zero,
      builder: (context, posSnap) {
        return StreamBuilder<Duration>(
          stream: preview.duration,
          initialData: Duration.zero,
          builder: (context, durSnap) {
            final loaded = preview.loadedPath == abs;
            final pos = posSnap.data ?? Duration.zero;
            var total = durSnap.data ?? Duration.zero;
            if (total <= Duration.zero && row.durationMs > 0) {
              total = Duration(milliseconds: row.durationMs);
            }
            final text = loaded
                ? '${formatDurationHms(pos)} / ${formatDurationHms(total)}'
                : '${formatDurationHms(Duration.zero)} / ${formatDurationHms(total)}';
            return Text(text, style: style);
          },
        );
      },
    );
  }
}
