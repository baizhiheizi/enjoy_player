import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/ai/presentation/widgets/dictionary_senses_view.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/flashcard_ai_error_retry.dart';
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
    final result = decodeDictionaryExplanation(widget.explanation);
    final authLoading = ref.watch(
      authCtrlProvider.select((auth) => auth.isLoading),
    );
    final signedIn = ref.watch(authIsSignedInProvider);

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

    return FlashcardAiErrorRetry(
      error: widget.error,
      onRetry: widget.onFetch,
      retryLabel: l10n.vocabularyFetchDictionary,
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
