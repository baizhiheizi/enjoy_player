library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/ai/application/ai_cache_fingerprint.dart';
import 'package:enjoy_player/features/ai/application/ai_result_cache.dart';
import 'package:enjoy_player/features/ai/domain/ai_kind.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/ai/presentation/widgets/dictionary_senses_view.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_providers.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/lookup_credits_reporting.dart';
import 'package:enjoy_player/features/lookup/presentation/lookup_section_error_widget.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_expansion_card.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_refresh_icon_button.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_auth_gate.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_shimmer.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class DictionaryLookupSection extends ConsumerWidget {
  const DictionaryLookupSection({required this.request, super.key});

  final LookupRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final params = LookupDictionaryParams(
      text: request.selectedText,
      sourceLanguage: request.sourceLanguage,
      targetLanguage: request.targetLanguage,
    );

    return LookupExpansionCard(
      title: l10n.lookupSectionDictionary,
      initiallyExpanded: false,
      leading: const Icon(EnjoyIcons.book),
      bodyBuilder: (_) => LookupSectionAuthGate(
        surface: AuthRequiredSurface.lookupDictionary,
        child: Builder(
          builder: (_) {
            void forceRefresh() {
              final key = AiCacheFingerprint.fingerprint(
                kind: AiKind.dictionary.wire,
                payload: {
                  'word': params.text,
                  'sourceLanguage': params.sourceLanguage,
                  'targetLanguage': params.targetLanguage,
                },
              );
              unawaited(
                ref
                    .read(aiDictionaryCacheProvider)
                    .invalidate(kind: AiKind.dictionary, key: key),
              );
              ref.invalidate(lookupSheetDictionaryProvider(params));
            }

            final async = ref.watch(lookupSheetDictionaryProvider(params));
            return async.when(
              skipLoadingOnReload: true,
              data: (DictionaryResult d) {
                scheduleLookupCreditsClear(
                  context,
                  ref,
                  LookupSectionId.dictionary,
                );
                return _DictionaryBody(
                  d: d,
                  l10n: l10n,
                  refreshControl: LookupRefreshIconButton(
                    l10n: l10n,
                    isRefreshing: async.isRefreshing,
                    onPressed: forceRefresh,
                  ),
                );
              },
              loading: () => const LookupSectionShimmer(),
              error: (Object e, StackTrace st) => lookupSectionErrorWidget(
                context: context,
                ref: ref,
                l10n: l10n,
                section: LookupSectionId.dictionary,
                surface: AuthRequiredSurface.lookupDictionary,
                error: e,
                onRetry: forceRefresh,
                isRetrying: async.hasError && async.isLoading,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DictionaryBody extends StatelessWidget {
  const _DictionaryBody({
    required this.d,
    required this.l10n,
    required this.refreshControl,
  });

  final DictionaryResult d;
  final AppLocalizations l10n;
  final Widget refreshControl;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final t = EnjoyThemeTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(end: t.space40),
                child: SelectableText(
                  d.word,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              PositionedDirectional(top: 0, end: 0, child: refreshControl),
            ],
          ),
        ),
        SizedBox(height: t.space12),
        DictionarySensesView(result: d, lemmaLabel: l10n.lookupLemma),
      ],
    );
  }
}
