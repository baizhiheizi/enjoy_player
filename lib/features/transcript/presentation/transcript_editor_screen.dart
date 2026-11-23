/// Full-page transcript editor: line text plus start / duration timing per
/// cue, saved through the transcript repository's timeline replacement so the
/// player's transcript views update from their existing watches.
library;

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_line_editing.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

final _log = logNamed('TranscriptEditor');

final _timingSecondsPattern = RegExp(r'^\d*\.?\d*$');

final _timingInputFormatters = [
  TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        _timingSecondsPattern.hasMatch(newValue.text) ? newValue : oldValue,
  ),
];

class TranscriptEditorScreen extends ConsumerStatefulWidget {
  const TranscriptEditorScreen({required this.mediaId, super.key});

  final String mediaId;

  @override
  ConsumerState<TranscriptEditorScreen> createState() =>
      _TranscriptEditorScreenState();
}

class _CueDraft {
  _CueDraft({
    required this.line,
    required this.text,
    required this.start,
    required this.duration,
  });

  final TranscriptLine line;
  String text;
  String start;
  String duration;
}

class _TranscriptEditorScreenState
    extends ConsumerState<TranscriptEditorScreen> {
  String? _transcriptId;
  List<_CueDraft>? _edits;
  bool _rowMissing = false;
  bool _failed = false;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  void _markDirty() => _dirty = true;

  Future<void> _load() async {
    try {
      final repo = ref.read(transcriptRepositoryProvider);
      final row = await _resolveRow(repo);
      if (!mounted) return;
      if (row == null) {
        setState(() {
          _edits = const [];
          _rowMissing = true;
        });
        return;
      }
      final lines = await repo.linesForRowPreloaded(row);
      if (!mounted) return;
      setState(() {
        _transcriptId = row.id;
        _edits = [
          for (final line in lines)
            _CueDraft(
              line: line,
              text: line.text,
              start: formatTranscriptTimingMs(line.startMs),
              duration: formatTranscriptTimingMs(line.durationMs),
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
    final rows = await repo.transcriptRowsForMedia(widget.mediaId);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> _leave() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final discard = await showEnjoyConfirmDialog(
      context: context,
      title: l10n.transcriptEditorDiscardTitle,
      message: l10n.transcriptEditorDiscardMessage,
      confirmLabel: l10n.transcriptEditorDiscardConfirm,
      destructive: true,
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    final edits = _edits;
    final transcriptId = _transcriptId;
    if (edits == null || transcriptId == null || _saving) return;
    final l10n = AppLocalizations.of(context)!;
    final lines = <TranscriptLine>[];
    for (final edit in edits) {
      final startMs = parseTranscriptTimingMs(edit.start);
      final durationMs = parseTranscriptTimingMs(edit.duration);
      if (startMs == null || durationMs == null) {
        AppNotice.error(context, l10n.transcriptEditorInvalidTiming);
        return;
      }
      lines.add(
        editedTranscriptLine(
          edit.line,
          text: edit.text.trim(),
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
    _dirty = false;
    AppNotice.success(context, l10n.transcriptEditorSaved);
    await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final edits = _edits;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_leave());
      },
      child: EnjoyPage(
        kind: EnjoyPageKind.form,
        title: l10n.transcriptEditorTitle,
        showBack: true,
        onBack: () => unawaited(_leave()),
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
                      : (_rowMissing
                            ? l10n.transcriptEditorEmpty
                            : l10n.transcriptEditorNoCues),
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
            itemBuilder: (context, index) => _LineCard(
              key: ValueKey('transcript-editor-card-${index + 1}'),
              draft: edits[index],
              index: index + 1,
              saving: _saving,
              onChanged: _markDirty,
            ),
          );
        },
      ),
    );
  }
}

class _LineCard extends StatefulWidget {
  const _LineCard({
    required this.draft,
    required this.index,
    required this.saving,
    required this.onChanged,
    super.key,
  });

  final _CueDraft draft;
  final int index;
  final bool saving;
  final VoidCallback onChanged;

  @override
  State<_LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<_LineCard> {
  late final TextEditingController _textController;
  late final TextEditingController _startController;
  late final TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.draft.text)
      ..addListener(_onTextChanged);
    _startController = TextEditingController(text: widget.draft.start)
      ..addListener(_onStartChanged);
    _durationController = TextEditingController(text: widget.draft.duration)
      ..addListener(_onDurationChanged);
  }

  @override
  void didUpdateWidget(_LineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.draft, widget.draft)) {
      _syncController(_textController, widget.draft.text);
      _syncController(_startController, widget.draft.start);
      _syncController(_durationController, widget.draft.duration);
    }
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  void _onTextChanged() {
    final text = _textController.text;
    if (widget.draft.text == text) return;
    widget.draft.text = text;
    widget.onChanged();
  }

  void _onStartChanged() {
    final text = _startController.text;
    if (widget.draft.start == text) return;
    widget.draft.start = text;
    widget.onChanged();
  }

  void _onDurationChanged() {
    final text = _durationController.text;
    if (widget.draft.duration == text) return;
    widget.draft.duration = text;
    widget.onChanged();
  }

  @override
  void dispose() {
    _textController.dispose();
    _startController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final index = widget.index;
    final saving = widget.saving;
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
            controller: _textController,
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
                  controller: _startController,
                  enabled: !saving,
                  decoration: InputDecoration(
                    labelText: l10n.transcriptEditorFieldStart,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: _timingInputFormatters,
                ),
              ),
              SizedBox(width: t.space12),
              Expanded(
                child: TextFormField(
                  key: ValueKey('transcript-editor-duration-$index'),
                  controller: _durationController,
                  enabled: !saving,
                  decoration: InputDecoration(
                    labelText: l10n.transcriptEditorFieldDuration,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: _timingInputFormatters,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
