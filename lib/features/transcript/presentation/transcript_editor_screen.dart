/// Full-page transcript editor: line text plus start / duration timing per
/// cue, saved through the transcript repository's timeline replacement so the
/// player's transcript views update from their existing watches.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_line_editing.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

final _log = logNamed('TranscriptEditor');

class TranscriptEditorScreen extends ConsumerStatefulWidget {
  const TranscriptEditorScreen({required this.mediaId, super.key});

  final String mediaId;

  @override
  ConsumerState<TranscriptEditorScreen> createState() =>
      _TranscriptEditorScreenState();
}

class _LineEdits {
  _LineEdits({
    required this.line,
    required this.text,
    required this.start,
    required this.duration,
  });

  final TranscriptLine line;
  final TextEditingController text;
  final TextEditingController start;
  final TextEditingController duration;

  void dispose() {
    text.dispose();
    start.dispose();
    duration.dispose();
  }
}

class _TranscriptEditorScreenState
    extends ConsumerState<TranscriptEditorScreen> {
  String? _transcriptId;
  List<_LineEdits>? _edits;
  bool _failed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final edit in _edits ?? const <_LineEdits>[]) {
      edit.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(transcriptRepositoryProvider);
      final row = await _resolveRow(repo);
      if (!mounted) return;
      if (row == null) {
        setState(() => _edits = const []);
        return;
      }
      final lines = await repo.linesForRowPreloaded(row);
      if (!mounted) return;
      setState(() {
        _transcriptId = row.id;
        _edits = [
          for (final line in lines)
            _LineEdits(
              line: line,
              text: TextEditingController(text: line.text),
              start: TextEditingController(
                text: formatTranscriptTimingMs(line.startMs),
              ),
              duration: TextEditingController(
                text: formatTranscriptTimingMs(line.durationMs),
              ),
            ),
        ];
      });
    } on Object catch (error) {
      _log.warning('transcript editor load failed: $error');
      if (!mounted) return;
      setState(() {
        _edits = const [];
        _failed = true;
      });
    }
  }

  Future<TranscriptRow?> _resolveRow(TranscriptRepository repo) async {
    final primary = await repo.primaryTranscriptRowForMedia(widget.mediaId);
    if (primary != null) return primary;
    final tracks = await repo.watchTracks(widget.mediaId).first;
    for (final track in tracks) {
      final row = await repo.transcriptRowById(track.id);
      if (row != null) return row;
    }
    return null;
  }

  Future<void> _save() async {
    final edits = _edits;
    final transcriptId = _transcriptId;
    if (edits == null || transcriptId == null || _saving) return;
    final l10n = AppLocalizations.of(context)!;
    final lines = <TranscriptLine>[];
    for (final edit in edits) {
      final startMs = parseTranscriptTimingMs(edit.start.text);
      final durationMs = parseTranscriptTimingMs(edit.duration.text);
      if (startMs == null || durationMs == null) {
        AppNotice.error(context, l10n.transcriptEditorInvalidTiming);
        return;
      }
      lines.add(
        editedTranscriptLine(
          edit.line,
          text: edit.text.text.trim(),
          startMs: startMs,
          durationMs: durationMs,
        ),
      );
    }
    setState(() => _saving = true);
    var saved = false;
    try {
      saved = await ref
          .read(transcriptRepositoryProvider)
          .replaceTimeline(transcriptId: transcriptId, lines: lines);
    } on Object catch (error) {
      _log.warning('transcript editor save failed: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    if (!saved) {
      AppNotice.error(context, l10n.transcriptEditorSaveFailed);
      return;
    }
    AppNotice.success(context, l10n.transcriptEditorSaved);
    await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final edits = _edits;

    return EnjoyPage(
      kind: EnjoyPageKind.form,
      title: l10n.transcriptEditorTitle,
      showBack: true,
      actions: [
        TextButton(
          key: const ValueKey('transcript-editor-save'),
          onPressed: _saving || edits == null || edits.isEmpty ? null : _save,
          child: Text(l10n.transcriptEditorSave),
        ),
      ],
      body: (context, metrics) {
        if (edits == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (edits.isEmpty || _failed) {
          return Center(
            child: Padding(
              padding: metrics.padding(),
              child: Text(
                _failed
                    ? l10n.errorGenericLoadFailed
                    : l10n.transcriptEditorEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: t.ink2),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: metrics.padding(top: t.space16, bottom: t.space32),
          itemCount: edits.length,
          itemBuilder: (context, index) =>
              _LineCard(edits: edits[index], index: index + 1, saving: _saving),
        );
      },
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.edits,
    required this.index,
    required this.saving,
  });

  final _LineEdits edits;
  final int index;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: EdgeInsets.only(bottom: t.space12),
      padding: EdgeInsets.all(t.space16),
      decoration: ShapeDecoration(
        color: t.paper,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: t.line),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.transcriptEditorLineLabel(index),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: t.ink3,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: t.space8),
          TextFormField(
            key: ValueKey('transcript-editor-text-$index'),
            controller: edits.text,
            enabled: !saving,
            minLines: 1,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
          ),
          SizedBox(height: t.space12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('transcript-editor-start-$index'),
                  controller: edits.start,
                  enabled: !saving,
                  decoration: InputDecoration(
                    labelText: l10n.transcriptEditorFieldStart,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]+')),
                  ],
                ),
              ),
              SizedBox(width: t.space12),
              Expanded(
                child: TextFormField(
                  key: ValueKey('transcript-editor-duration-$index'),
                  controller: edits.duration,
                  enabled: !saving,
                  decoration: InputDecoration(
                    labelText: l10n.transcriptEditorFieldDuration,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]+')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
