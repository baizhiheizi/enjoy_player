library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/models/contextual_translation_result.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_params.dart';
import 'package:enjoy_player/features/lookup/application/lookup_sheet_result_cache.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_error_row.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_expansion_card.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_refresh_icon_button.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_shimmer.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

final Logger _log = logNamed('lookup.contextual');

class ContextualTranslationLookupSection extends ConsumerWidget {
  const ContextualTranslationLookupSection({required this.request, super.key});

  final LookupRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final params = LookupContextualParams(
      text: request.selectedText,
      sourceLanguage: request.sourceLanguage,
      targetLanguage: request.targetLanguage,
      context: request.contextualContext,
    );
    final theme = Theme.of(context);
    final t = EnjoyThemeTokens.of(context);
    final mdStyle = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
      blockSpacing: t.space8,
      h1: theme.textTheme.headlineSmall,
      h2: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      h2Padding: EdgeInsets.only(top: t.space8, bottom: t.space4),
      h3: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      h3Padding: EdgeInsets.only(top: t.space8, bottom: t.space4),
    );

    return LookupExpansionCard(
      title: l10n.lookupSectionContextualTranslation,
      initiallyExpanded: false,
      leading: const Icon(Icons.article_outlined),
      bodyBuilder: (ctx) => _ContextualFetchBody(
        params: params,
        theme: theme,
        mdStyle: mdStyle,
        l10n: l10n,
      ),
    );
  }
}

/// Loads contextual translation outside an autoDispose [FutureProvider].
///
/// Riverpod can dispose/cancel an autoDispose future while the HTTP/LLM call is
/// still running; when the response arrives, state is never applied and the UI
/// stays on the loading shimmer. This widget keeps a single [Future] tied to
/// [ConsumerState] instead. Completed values are stored in [LookupSheetResultCache].
class _ContextualFetchBody extends ConsumerStatefulWidget {
  const _ContextualFetchBody({
    required this.params,
    required this.theme,
    required this.mdStyle,
    required this.l10n,
  });

  final LookupContextualParams params;
  final ThemeData theme;
  final MarkdownStyleSheet mdStyle;
  final AppLocalizations l10n;

  @override
  ConsumerState<_ContextualFetchBody> createState() => _ContextualFetchBodyState();
}

class _ContextualFetchBodyState extends ConsumerState<_ContextualFetchBody> {
  static const Duration _timeout = Duration(seconds: 120);

  Future<ContextualTranslationResult>? _future;

  @override
  void initState() {
    super.initState();
    _beginFetch(forceRefresh: false);
  }

  @override
  void didUpdateWidget(covariant _ContextualFetchBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _beginFetch(forceRefresh: false);
    }
  }

  void _beginFetch({required bool forceRefresh}) {
    final p = widget.params;
    final cache = ref.read(lookupSheetResultCacheProvider);

    if (forceRefresh) {
      cache.evictContextual(p);
    } else {
      final hit = cache.peekContextual(p);
      if (hit != null) {
        _log.fine(
          'contextual translation cache hit '
          'src=${p.sourceLanguage} tgt=${p.targetLanguage}',
        );
        _future = Future.value(hit);
        _deferSetState();
        return;
      }
    }

    _log.info(
      'contextual translation request '
      'src=${p.sourceLanguage} tgt=${p.targetLanguage} '
      'textLen=${p.text.length} ctxLen=${p.context?.length ?? 0}',
    );
    final svc = ref.read(contextualTranslationServiceProvider);
    _future = () async {
      try {
        final r = await svc
            .translate(
              text: p.text,
              sourceLanguage: p.sourceLanguage,
              targetLanguage: p.targetLanguage,
              context: p.context,
            )
            .timeout(
              _timeout,
              onTimeout: () {
                throw TimeoutException(
                  'Contextual translation timed out after '
                  '${_timeout.inSeconds}s',
                );
              },
            );
        cache.rememberContextual(p, r);
        _log.info(
          'contextual translation ok outChars=${r.translatedText.length}',
        );
        return r;
      } catch (e, st) {
        _log.warning('contextual translation request failed', e, st);
        rethrow;
      }
    }();
    _deferSetState();
  }

  void _deferSetState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _retryAfterError() {
    _beginFetch(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return const LookupSectionShimmer();
    }
    return FutureBuilder<ContextualTranslationResult>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LookupSectionShimmer();
        }
        if (snapshot.hasError) {
          final e = snapshot.error!;
          return LookupErrorRow(
            message: e is AppFailure ? e.message : e.toString(),
            onRetry: _retryAfterError,
          );
        }
        final d = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LookupRefreshIconButton(
              l10n: widget.l10n,
              onPressed: () => _beginFetch(forceRefresh: true),
            ),
            if (d.translatedText.trim().isEmpty)
              Text(
                widget.l10n.lookupEmpty,
                style: widget.theme.textTheme.bodyMedium,
              )
            else
              MarkdownBody(
                data: d.translatedText,
                selectable: true,
                styleSheet: widget.mdStyle,
              ),
          ],
        );
      },
    );
  }
}
