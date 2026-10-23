import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/ai/presentation/widgets/dictionary_senses_view.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/flashcard_soft_error.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class FlashcardDictionaryTab extends ConsumerStatefulWidget {
  const FlashcardDictionaryTab({
    super.key,
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
  ConsumerState<FlashcardDictionaryTab> createState() =>
      _FlashcardDictionaryTabState();
}

class _FlashcardDictionaryTabState
    extends ConsumerState<FlashcardDictionaryTab> {
  var _autoloadRequested = false;

  @override
  void didUpdateWidget(covariant FlashcardDictionaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.explanation != widget.explanation) {
      _autoloadRequested = false;
    }
  }

  void _maybeAutoload({required bool signedIn}) {
    if (!mounted || _autoloadRequested) return;
    if (decodeDictionaryExplanation(widget.explanation) != null) return;
    if (widget.fetchInFlight || widget.error != null) return;
    if (!signedIn) return;
    _autoloadRequested = true;
    widget.onFetch();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final result = decodeDictionaryExplanation(widget.explanation);
    final auth = ref.watch(authCtrlProvider);
    final authLoading = auth.isLoading;
    final signedIn = auth.maybeWhen(
      data: (s) => s is AuthSignedIn,
      orElse: () => false,
    );

    if (result != null) {
      return _DictionaryResultView(result: result);
    }

    if (authLoading) {
      return _DictionaryLoading(label: l10n.vocabularyFetching);
    }

    if (!signedIn) {
      return const AuthRequiredCallout(
        surface: AuthRequiredSurface.lookupDictionary,
        compact: true,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoload(signedIn: signedIn);
    });

    if (widget.fetchInFlight || widget.error == null) {
      return _DictionaryLoading(label: l10n.vocabularyFetching);
    }

    final isCredits = widget.error == 'credits';
    final errorMessage = isCredits
        ? l10n.subscriptionCreditsLimitMessageWithPackages
        : l10n.vocabularyAiFetchFailed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlashcardSoftError(message: errorMessage),
        SizedBox(height: t.space12),
        EnjoyButton.secondary(
          onPressed: widget.onFetch,
          child: Text(l10n.vocabularyFetchDictionary),
        ),
        if (isCredits)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => context.push('/subscription'),
              child: Text(creditsCtaLabel(l10n)),
            ),
          ),
      ],
    );
  }
}

class _DictionaryLoading extends StatelessWidget {
  const _DictionaryLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: t.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.primary,
              ),
            ),
            SizedBox(height: t.space12),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _DictionaryResultView extends StatelessWidget {
  const _DictionaryResultView({required this.result});

  final DictionaryResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (result.senses.isEmpty) {
      return Text(l10n.vocabularyDictionaryNotAvailable);
    }
    return DictionarySensesView(result: result);
  }
}
