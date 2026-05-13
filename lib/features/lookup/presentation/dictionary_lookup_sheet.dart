/// Bottom sheet: translation, contextual translation, dictionary for a selection.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/sections/contextual_translation_lookup_section.dart';
import 'package:enjoy_player/features/lookup/presentation/sections/dictionary_lookup_section.dart';
import 'package:enjoy_player/features/lookup/presentation/sections/translation_lookup_section.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_language_picker_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class DictionaryLookupSheet extends ConsumerStatefulWidget {
  const DictionaryLookupSheet({required this.request, super.key});

  final LookupRequest request;

  @override
  ConsumerState<DictionaryLookupSheet> createState() =>
      _DictionaryLookupSheetState();
}

class _DictionaryLookupSheetState extends ConsumerState<DictionaryLookupSheet> {
  late String _sourceLanguage;
  late String _targetLanguage;

  @override
  void initState() {
    super.initState();
    _sourceLanguage = widget.request.sourceLanguage;
    _targetLanguage = widget.request.targetLanguage;
  }

  static const double _hPad = 20;

  LookupRequest get _effectiveRequest => LookupRequest(
    selectedText: widget.request.selectedText,
    sourceLanguage: _sourceLanguage,
    targetLanguage: _targetLanguage,
    contextualContext: widget.request.contextualContext,
  );

  Future<void> _copySelection(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: widget.request.selectedText));
    if (!context.mounted) return;
    AppNotice.success(context, l10n.lookupCopySuccess);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollCtrl) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = math.min(
                constraints.maxWidth,
                t.contentMaxWidth + 2 * _hPad,
              );

              Widget constrain(Widget child) => Align(
                alignment: Alignment.topCenter,
                child: SizedBox(width: maxWidth, child: child),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PaddedSheetDragHandle(),
                  // ── Title row ──────────────────────────────────────────
                  constrain(
                    Padding(
                      padding: const EdgeInsets.only(
                        left: _hPad,
                        right: 4,
                        bottom: 6,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              l10n.lookupSheetTitle,
                              style: tt.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              fixedSize: const Size(48, 48),
                              foregroundColor: scheme.onSurfaceVariant,
                            ),
                            tooltip: l10n.lookupClose,
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Selected word ──────────────────────────────────────
                  constrain(
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        _hPad,
                        0,
                        4,
                        0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SelectableText(
                              widget.request.selectedText,
                              style: tt.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 4,
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              fixedSize: const Size(48, 48),
                              foregroundColor: scheme.onSurfaceVariant,
                            ),
                            tooltip: l10n.lookupCopy,
                            onPressed: () => _copySelection(context),
                            icon: const Icon(Icons.copy_all_rounded, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Language picker ────────────────────────────────────
                  constrain(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(_hPad, 10, _hPad, 10),
                      child: LookupLanguagePickerRow(
                        sourceLanguage: _sourceLanguage,
                        targetLanguage: _targetLanguage,
                        onSourceChanged: (v) =>
                            setState(() => _sourceLanguage = v),
                        onTargetChanged: (v) =>
                            setState(() => _targetLanguage = v),
                        onSwap: () {
                          setState(() {
                            final s = _sourceLanguage;
                            _sourceLanguage = _targetLanguage;
                            _targetLanguage = s;
                          });
                        },
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                  // ── Scrollable sections ────────────────────────────────
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: EdgeInsets.fromLTRB(
                        _hPad,
                        t.space12,
                        _hPad,
                        t.space24,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: t.contentMaxWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TranslationLookupSection(
                                  request: _effectiveRequest,
                                ),
                                SizedBox(height: t.space8),
                                ContextualTranslationLookupSection(
                                  request: _effectiveRequest,
                                ),
                                SizedBox(height: t.space8),
                                DictionaryLookupSection(
                                  request: _effectiveRequest,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
