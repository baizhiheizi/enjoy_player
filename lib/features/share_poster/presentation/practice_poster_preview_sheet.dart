/// Preview sheet and orchestration for practice poster share flow.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine_provider.dart';
import 'package:enjoy_player/features/share_poster/application/practice_poster_builder.dart';
import 'package:enjoy_player/features/share_poster/application/practice_poster_echo_frame_capture.dart';
import 'package:enjoy_player/features/share_poster/application/practice_poster_export.dart';
import 'package:enjoy_player/features/share_poster/domain/practice_poster_data.dart';
import 'package:enjoy_player/features/share_poster/presentation/practice_poster_widget.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Future<void> showPracticePosterPreviewSheet(
  BuildContext context,
  WidgetRef ref, {
  required String mediaId,
}) {
  return showEnjoySheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _PracticePosterPreviewSheet(mediaId: mediaId),
  );
}

class _PracticePosterPreviewSheet extends ConsumerStatefulWidget {
  const _PracticePosterPreviewSheet({required this.mediaId});

  final String mediaId;

  @override
  ConsumerState<_PracticePosterPreviewSheet> createState() =>
      _PracticePosterPreviewSheetState();
}

class _PracticePosterPreviewSheetState
    extends ConsumerState<_PracticePosterPreviewSheet> {
  final _captureKey = GlobalKey();
  PracticePosterData? _data;
  Object? _loadError;
  var _coverReady = false;
  var _exporting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final session = ref.read(playerControllerProvider);
      final echo = session?.mediaId == widget.mediaId
          ? ref.read(echoModeProvider)
          : EchoState.inactive;
      final echoCoverBytes = await capturePracticePosterEchoFrame(
        engine: ref.read(playerEngineProvider),
        echo: echo,
        session: session,
        mediaId: widget.mediaId,
      );
      final data = await buildPracticePosterData(
        db: ref.read(appDatabaseProvider),
        library: ref.read(mediaLibraryRepositoryProvider),
        transcriptRepo: ref.read(transcriptRepositoryProvider),
        mediaId: widget.mediaId,
        echo: echo,
        echoCoverBytes: echoCoverBytes,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loadError = data == null ? StateError('no practice') : null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  PracticePosterLabels _labels(AppLocalizations l10n) {
    return PracticePosterLabels(
      tagline: l10n.practicePosterTagline,
      takesLabel: l10n.practicePosterStatTakes,
      sentencesLabel: l10n.practicePosterStatSentences,
      spokenLabel: l10n.practicePosterStatSpoken,
      qrHint: l10n.practicePosterQrHint,
    );
  }

  bool get _canExport =>
      _data != null && _coverReady && !_exporting && _loadError == null;

  Future<void> _onExport() async {
    if (!_canExport) return;
    setState(() => _exporting = true);

    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final bytes = await captureRepaintBoundaryPng(_captureKey);
    if (!mounted) return;
    setState(() => _exporting = false);

    final l10n = AppLocalizations.of(context)!;
    if (bytes == null) {
      AppNotice.error(context, l10n.practicePosterExportError);
      return;
    }

    final outcome = await exportPracticePosterPng(bytes);
    if (!mounted) return;

    switch (outcome) {
      case PracticePosterExportOutcome.shared:
        AppNotice.success(context, l10n.practicePosterShareSuccess);
        Navigator.of(context).pop();
      case PracticePosterExportOutcome.saved:
        AppNotice.success(context, l10n.practicePosterSaveSuccess);
        Navigator.of(context).pop();
      case PracticePosterExportOutcome.cancelled:
        break;
      case PracticePosterExportOutcome.failed:
        AppNotice.error(context, l10n.practicePosterExportError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final data = _data;
    final sheetMaxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          t.space16,
          t.space8,
          t.space16,
          t.space16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: sheetMaxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: SheetDragHandle()),
              SizedBox(height: t.space12),
              Text(
                l10n.practicePosterPreviewTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: t.space16),
              if (_loadError != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: t.space24),
                  child: Text(
                    l10n.practicePosterLoadError,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.error),
                  ),
                )
              else if (data == null)
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: cs.primary,
                      ),
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: t.space12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final widthScale =
                            constraints.maxWidth / practicePosterLogicalWidth;
                        final scale = math.min(1.0, widthScale);

                        return Center(
                          child: Transform.scale(
                            scale: scale,
                            alignment: Alignment.topCenter,
                            child: RepaintBoundary(
                              key: _captureKey,
                              child: PracticePosterWidget(
                                data: data,
                                labels: _labels(l10n),
                                onCoverReady: () {
                                  if (!mounted || _coverReady) return;
                                  setState(() => _coverReady = true);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: t.space12),
                EnjoyButton.primary(
                  onPressed: _canExport ? _onExport : null,
                  child: _exporting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : Text(l10n.practicePosterShareAction),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
