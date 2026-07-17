/// Fullscreen vocabulary flashcard review session.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_media.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_flashcard.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class VocabularyReviewSessionScreen extends ConsumerStatefulWidget {
  const VocabularyReviewSessionScreen({super.key});

  @override
  ConsumerState<VocabularyReviewSessionScreen> createState() =>
      _VocabularyReviewSessionScreenState();
}

class _VocabularyReviewSessionScreenState
    extends ConsumerState<VocabularyReviewSessionScreen> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = ref.read(vocabularyReviewSessionProvider);
      if (!session.hasActiveSession) {
        context.go('/vocabulary');
        return;
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _exit() {
    ref.read(vocabularyReviewSessionProvider.notifier).clear();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/vocabulary');
    }
  }

  Future<void> _confirmMediaHandoff({
    required String title,
    required String body,
    required bool activateEcho,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showEnjoyAlertDialog<bool>(
      context: context,
      title: Text(title),
      content: Text(body),
      actionsBuilder: (ctx) => [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.vocabularyCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.vocabularyConfirmContinue),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;

    final handoff = ref
        .read(vocabularyReviewSessionProvider.notifier)
        .takeMediaHandoff(activateEcho: activateEcho);
    if (handoff == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.vocabularyMediaOpenFailed)));
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/vocabulary');
    }
    if (!mounted) return;

    openPlayerRoute(context, handoff.mediaId);
    try {
      await applyVocabularyMediaHandoff(
        player: ref.read(playerControllerProvider.notifier),
        echo: ref.read(echoModeProvider.notifier),
        handoff: handoff,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.vocabularyMediaOpenFailed)));
      context.go('/vocabulary');
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final session = ref.read(vocabularyReviewSessionProvider);
    final notifier = ref.read(vocabularyReviewSessionProvider.notifier);
    if (!session.hasActiveSession) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _exit();
      return KeyEventResult.handled;
    }
    if (session.completed) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      notifier.flip();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      notifier.skip();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      notifier.previous();
      return KeyEventResult.handled;
    }
    if (session.flipped && !session.ratingInFlight) {
      if (event.logicalKey == LogicalKeyboardKey.digit1 ||
          event.logicalKey == LogicalKeyboardKey.numpad1) {
        unawaited(notifier.rate(VocabularyRating.dontKnow));
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit2 ||
          event.logicalKey == LogicalKeyboardKey.numpad2) {
        unawaited(notifier.rate(VocabularyRating.know));
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit3 ||
          event.logicalKey == LogicalKeyboardKey.numpad3) {
        unawaited(notifier.rate(VocabularyRating.knowWell));
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final session = ref.watch(vocabularyReviewSessionProvider);

    if (!session.hasActiveSession) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.vocabularyTitle)),
        body: const SizedBox.shrink(),
      );
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            session.completed
                ? l10n.vocabularyReviewComplete
                : l10n.vocabularyProgress(
                    session.displayCurrent,
                    session.total,
                  ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: _exit,
          ),
          actions: [
            if (session.canUndo)
              EnjoyTappableIcon(
                icon: Icons.undo,
                tooltip: l10n.vocabularyUndo,
                onPressed: () => unawaited(
                  ref.read(vocabularyReviewSessionProvider.notifier).undo(),
                ),
              ),
            if (!session.completed)
              TextButton(
                onPressed: session.ratingInFlight
                    ? null
                    : () => ref
                          .read(vocabularyReviewSessionProvider.notifier)
                          .skip(),
                child: Text(l10n.vocabularySkip),
              ),
          ],
        ),
        body: session.completed
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(t.space24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.vocabularyReviewComplete,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: t.space8),
                      Text(l10n.vocabularyReviewCompleteDescription),
                      SizedBox(height: t.space24),
                      EnjoyButton.primary(
                        onPressed: _exit,
                        child: Text(l10n.vocabularyDone),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: VocabularyFlashcard(
                      item: session.currentItem!,
                      primaryContext: session.currentPrimaryContext,
                      flipped: session.flipped,
                      ratingInFlight: session.ratingInFlight,
                      dictionaryFetchInFlight: session.dictionaryFetchInFlight,
                      contextualFetchInFlight: session.contextualFetchInFlight,
                      clipPlayInFlight: session.clipPlayInFlight,
                      dictionaryError: session.dictionaryError,
                      contextualError: session.contextualError,
                      mediaError: session.mediaError,
                      onFlip: () => ref
                          .read(vocabularyReviewSessionProvider.notifier)
                          .flip(),
                      onRate: (r) => unawaited(
                        ref
                            .read(vocabularyReviewSessionProvider.notifier)
                            .rate(r),
                      ),
                      onFetchDictionary: () => unawaited(
                        ref
                            .read(vocabularyReviewSessionProvider.notifier)
                            .fetchDictionary(),
                      ),
                      onFetchContextual: () => unawaited(
                        ref
                            .read(vocabularyReviewSessionProvider.notifier)
                            .fetchContextualTranslation(),
                      ),
                      onPlayClip: () => unawaited(
                        ref
                            .read(vocabularyReviewSessionProvider.notifier)
                            .playClip(),
                      ),
                      onOpenInPlayer: () => unawaited(
                        _confirmMediaHandoff(
                          title: l10n.vocabularyOpenInPlayer,
                          body: l10n.vocabularyOpenInPlayerDescription,
                          activateEcho: false,
                        ),
                      ),
                      onShadowReading: () => unawaited(
                        _confirmMediaHandoff(
                          title: l10n.vocabularyShadowReading,
                          body: l10n.vocabularyShadowReadingDescription,
                          activateEcho: true,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      t.space16,
                      0,
                      t.space16,
                      t.space16,
                    ),
                    child: Text(
                      l10n.vocabularyKeyboardShortcuts,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
