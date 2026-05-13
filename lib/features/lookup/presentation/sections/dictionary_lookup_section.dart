library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/theme/colors.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/lookup/application/lookup_section_providers.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_error_row.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_expansion_card.dart';
import 'package:enjoy_player/features/lookup/presentation/widgets/lookup_section_shimmer.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class DictionaryLookupSection extends ConsumerWidget {
  const DictionaryLookupSection({required this.request, super.key});

  final LookupRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final params = LookupDictionaryParams(
      word: request.selectedText,
      sourceLanguage: request.sourceLanguage,
      targetLanguage: request.targetLanguage,
    );

    return LookupExpansionCard(
      title: l10n.lookupSectionDictionary,
      initiallyExpanded: false,
      leading: const Icon(Icons.menu_book_outlined),
      bodyBuilder: (ctx) {
        final async = ref.watch(lookupSheetDictionaryProvider(params));
        return async.when(
          data: (DictionaryResult d) => _DictionaryBody(d: d, l10n: l10n),
          loading: () => const LookupSectionShimmer(),
          error: (e, _) => LookupErrorRow(
            message: e is AppFailure ? e.message : e.toString(),
            onRetry: () =>
                ref.invalidate(lookupSheetDictionaryProvider(params)),
          ),
        );
      },
    );
  }
}

class _DictionaryBody extends StatelessWidget {
  const _DictionaryBody({required this.d, required this.l10n});

  final DictionaryResult d;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final t = EnjoyThemeTokens.of(context);
    final lemmaTrim = d.lemma?.trim();
    final showLemma =
        lemmaTrim != null && lemmaTrim.isNotEmpty && lemmaTrim != d.word.trim();
    final ipaTrim = d.ipa?.trim();
    final hasIpa = ipaTrim != null && ipaTrim.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Headword + IPA/lemma ─────────────────────────────────────
        SelectableText(
          d.word,
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        if (hasIpa || showLemma) ...[
          SizedBox(height: t.space4),
          Wrap(
            spacing: t.space8,
            runSpacing: t.space4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hasIpa)
                Text(
                  ipaTrim,
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              if (showLemma)
                Text(
                  '${l10n.lookupLemma} · $lemmaTrim',
                  style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ],
        // ── Senses ───────────────────────────────────────────────────
        SizedBox(height: t.space12),
        for (var i = 0; i < d.senses.length; i++) ...[
          if (i > 0) ...[
            SizedBox(height: t.space4),
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.2),
            ),
            SizedBox(height: t.space4),
          ],
          _SenseTile(sense: d.senses[i], l10n: l10n),
        ],
      ],
    );
  }
}

class _SenseTile extends StatelessWidget {
  const _SenseTile({required this.sense, required this.l10n});

  final DictionarySense sense;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final t = EnjoyThemeTokens.of(context);
    final pos = sense.partOfSpeech?.trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final translationColor = isDark ? AppColors.brandOnDark : scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pos != null && pos.isNotEmpty) ...[
          Text(
            pos,
            style: tt.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: t.space4),
        ],
        if (sense.definition.trim().isNotEmpty)
          SelectableText(
            sense.definition,
            style: tt.bodyMedium?.copyWith(height: 1.4),
          ),
        if (sense.translation != null &&
            sense.translation!.trim().isNotEmpty) ...[
          SizedBox(height: t.space4),
          SelectableText(
            sense.translation!,
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: translationColor,
            ),
          ),
        ],
        if (sense.examples != null && sense.examples!.isNotEmpty) ...[
          SizedBox(height: t.space8),
          for (final ex in sense.examples!)
            Padding(
              padding: EdgeInsets.only(bottom: t.space8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 2,
                      color: scheme.primary.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                padding: EdgeInsetsDirectional.only(start: t.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      ex.source,
                      style: tt.bodySmall?.copyWith(height: 1.4),
                    ),
                    if (ex.target != null && ex.target!.trim().isNotEmpty) ...[
                      SizedBox(height: t.space4),
                      SelectableText(
                        ex.target!,
                        style: tt.bodySmall?.copyWith(
                          height: 1.4,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
        if (sense.notes != null && sense.notes!.trim().isNotEmpty) ...[
          SizedBox(height: t.space4),
          Text(
            sense.notes!,
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
