/// Flashcard front/back with Context / Dictionary / Notes tabs.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_media.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VocabularyFlashcard extends ConsumerWidget {
  const VocabularyFlashcard({
    super.key,
    required this.item,
    required this.primaryContext,
    required this.flipped,
    required this.ratingInFlight,
    required this.dictionaryFetchInFlight,
    required this.contextualFetchInFlight,
    required this.clipPlayInFlight,
    this.dictionaryError,
    this.contextualError,
    this.mediaError,
    required this.onFlip,
    required this.onRate,
    required this.onFetchDictionary,
    required this.onFetchContextual,
    required this.onPlayClip,
    required this.onOpenInPlayer,
    required this.onShadowReading,
  });

  final VocabularyItem item;
  final VocabularyContext? primaryContext;
  final bool flipped;
  final bool ratingInFlight;
  final bool dictionaryFetchInFlight;
  final bool contextualFetchInFlight;
  final bool clipPlayInFlight;
  final String? dictionaryError;
  final String? contextualError;
  final String? mediaError;
  final VoidCallback onFlip;
  final ValueChanged<VocabularyRating> onRate;
  final VoidCallback onFetchDictionary;
  final VoidCallback onFetchContextual;
  final VoidCallback onPlayClip;
  final VoidCallback onOpenInPlayer;
  final VoidCallback onShadowReading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final contextText = primaryContext?.text;

    if (!flipped) {
      return EnjoyTappableSurface(
        borderRadius: BorderRadius.circular(t.radiusLg),
        onTap: onFlip,
        child: Padding(
          padding: EdgeInsets.all(t.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.word,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: t.space16),
              if (contextText != null && contextText.isNotEmpty)
                Text(
                  contextText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Text(
                  l10n.vocabularyNoContextAvailable,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              SizedBox(height: t.space24),
              Text(
                l10n.vocabularyFlipHint,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.vocabularyContext),
              Tab(text: l10n.vocabularyDictionary),
              Tab(text: l10n.vocabularyNotes),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TabBody(
                  child: _ContextBody(
                    primaryContext: primaryContext,
                    contextualFetchInFlight: contextualFetchInFlight,
                    clipPlayInFlight: clipPlayInFlight,
                    contextualError: contextualError,
                    mediaError: mediaError,
                    onFetchContextual: onFetchContextual,
                    onPlayClip: onPlayClip,
                    onOpenInPlayer: onOpenInPlayer,
                    onShadowReading: onShadowReading,
                  ),
                ),
                _TabBody(
                  child: _DictionaryBody(
                    explanation: item.explanation,
                    fetchInFlight: dictionaryFetchInFlight,
                    error: dictionaryError,
                    onFetch: onFetchDictionary,
                  ),
                ),
                _TabBody(child: Text(l10n.vocabularyNotesPlaceholder)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(t.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.vocabularyHowWellDoYouKnow,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: t.space12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: t.space8,
                  runSpacing: t.space8,
                  children: [
                    EnjoyButton.secondary(
                      onPressed: ratingInFlight
                          ? null
                          : () => onRate(VocabularyRating.dontKnow),
                      child: Text(l10n.vocabularyDontKnow),
                    ),
                    EnjoyButton.primary(
                      onPressed: ratingInFlight
                          ? null
                          : () => onRate(VocabularyRating.know),
                      child: Text(l10n.vocabularyKnow),
                    ),
                    EnjoyButton.secondary(
                      onPressed: ratingInFlight
                          ? null
                          : () => onRate(VocabularyRating.knowWell),
                      child: Text(l10n.vocabularyKnowWell),
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

class _TabBody extends StatelessWidget {
  const _TabBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(t.space16),
      child: child,
    );
  }
}

class _ContextBody extends ConsumerWidget {
  const _ContextBody({
    required this.primaryContext,
    required this.contextualFetchInFlight,
    required this.clipPlayInFlight,
    required this.contextualError,
    required this.mediaError,
    required this.onFetchContextual,
    required this.onPlayClip,
    required this.onOpenInPlayer,
    required this.onShadowReading,
  });

  final VocabularyContext? primaryContext;
  final bool contextualFetchInFlight;
  final bool clipPlayInFlight;
  final String? contextualError;
  final String? mediaError;
  final VoidCallback onFetchContextual;
  final VoidCallback onPlayClip;
  final VoidCallback onOpenInPlayer;
  final VoidCallback onShadowReading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final ctx = primaryContext;
    if (ctx == null || ctx.text.isEmpty) {
      return Text(l10n.vocabularyNoContextAvailable);
    }

    final translation = decodeContextualExplanation(ctx.explanation);
    final canMedia = vocabularyContextSupportsMediaActions(ctx);
    final locator = ctx.locator;
    final auth = ref.watch(authCtrlProvider);
    final signedIn = auth.maybeWhen(
      data: (s) => s is AuthSignedIn,
      orElse: () => false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ctx.text, style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: t.space12),
        Text(
          '${l10n.vocabularySourceLabel}: ${ctx.sourceId}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (locator != null) ...[
          SizedBox(height: t.space4),
          Text(
            l10n.vocabularyLocatorLabel(
              (locator.start / 1000).toStringAsFixed(1),
              (locator.duration / 1000).toStringAsFixed(1),
            ),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        SizedBox(height: t.space16),
        Text(
          l10n.vocabularyContextualTranslation,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SizedBox(height: t.space8),
        if (translation != null)
          Text(translation.translatedText)
        else if (!signedIn)
          const AuthRequiredCallout(
            surface: AuthRequiredSurface.lookupContextual,
            compact: true,
          )
        else ...[
          if (contextualError != null)
            Padding(
              padding: EdgeInsets.only(bottom: t.space8),
              child: Text(
                l10n.vocabularyAiFetchFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          EnjoyButton.secondary(
            onPressed: contextualFetchInFlight ? null : onFetchContextual,
            child: Text(
              contextualFetchInFlight
                  ? l10n.vocabularyFetching
                  : l10n.vocabularyFetchContextual,
            ),
          ),
        ],
        if (canMedia) ...[
          SizedBox(height: t.space16),
          Wrap(
            spacing: t.space8,
            runSpacing: t.space8,
            children: [
              EnjoyButton.secondary(
                onPressed: clipPlayInFlight ? null : onPlayClip,
                child: Text(
                  clipPlayInFlight
                      ? l10n.vocabularyFetching
                      : l10n.vocabularyPlaySegment,
                ),
              ),
              EnjoyButton.secondary(
                onPressed: onOpenInPlayer,
                child: Text(l10n.vocabularyOpenInPlayer),
              ),
              EnjoyButton.secondary(
                onPressed: onShadowReading,
                child: Text(l10n.vocabularyShadowReading),
              ),
            ],
          ),
        ] else ...[
          SizedBox(height: t.space12),
          Text(
            l10n.vocabularyMediaUnavailable,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (mediaError != null) ...[
          SizedBox(height: t.space8),
          Text(
            l10n.vocabularyMediaPlayFailed,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _DictionaryBody extends ConsumerWidget {
  const _DictionaryBody({
    required this.explanation,
    required this.fetchInFlight,
    required this.error,
    required this.onFetch,
  });

  final String? explanation;
  final bool fetchInFlight;
  final String? error;
  final VoidCallback onFetch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final result = decodeDictionaryExplanation(explanation);
    final auth = ref.watch(authCtrlProvider);
    final signedIn = auth.maybeWhen(
      data: (s) => s is AuthSignedIn,
      orElse: () => false,
    );

    if (result != null) {
      return _DictionaryResultView(result: result);
    }

    if (!signedIn) {
      return const AuthRequiredCallout(
        surface: AuthRequiredSurface.lookupDictionary,
        compact: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.vocabularyDictionaryNotAvailable),
        if (error != null) ...[
          SizedBox(height: t.space8),
          Text(
            l10n.vocabularyAiFetchFailed,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        SizedBox(height: t.space12),
        EnjoyButton.secondary(
          onPressed: fetchInFlight ? null : onFetch,
          child: Text(
            fetchInFlight
                ? l10n.vocabularyFetching
                : l10n.vocabularyFetchDictionary,
          ),
        ),
      ],
    );
  }
}

class _DictionaryResultView extends StatelessWidget {
  const _DictionaryResultView({required this.result});

  final DictionaryResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final senses = result.senses
        .map((s) {
          final parts = <String>[s.definition];
          if (s.translation != null && s.translation!.isNotEmpty) {
            parts.add(s.translation!);
          }
          return parts.join(' — ');
        })
        .join('\n');
    final header = [
      if (result.ipa != null && result.ipa!.isNotEmpty) '/${result.ipa}/',
      if (result.lemma != null && result.lemma!.isNotEmpty) result.lemma!,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header.isNotEmpty) ...[
          Text(header, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
        ],
        Text(senses.isEmpty ? l10n.vocabularyDictionaryNotAvailable : senses),
      ],
    );
  }
}
