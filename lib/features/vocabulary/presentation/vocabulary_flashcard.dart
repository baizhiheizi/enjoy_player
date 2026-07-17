/// Flashcard front/back with Context / Dictionary / Notes tabs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/theme/colors.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/lookup_markdown_style.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_media.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_source_title.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_text_style.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Formats IPA with a single leading/trailing slash pair.
@visibleForTesting
String formatVocabularyIpa(String raw) {
  var s = raw.trim();
  while (s.startsWith('/')) {
    s = s.substring(1);
  }
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  s = s.trim();
  return s.isEmpty ? '' : '/$s/';
}

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
    required this.onUnflip,
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
  final VoidCallback onUnflip;
  final ValueChanged<VocabularyRating> onRate;
  final VoidCallback onFetchDictionary;
  final VoidCallback onFetchContextual;
  final VoidCallback onPlayClip;
  final VoidCallback onOpenInPlayer;
  final VoidCallback onShadowReading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);

    return AnimatedSwitcher(
      duration: t.motionStandard,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: <Widget>[...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: flipped
          ? KeyedSubtree(
              key: const ValueKey('back'),
              child: _FlashcardBack(
                item: item,
                primaryContext: primaryContext,
                ratingInFlight: ratingInFlight,
                dictionaryFetchInFlight: dictionaryFetchInFlight,
                contextualFetchInFlight: contextualFetchInFlight,
                clipPlayInFlight: clipPlayInFlight,
                dictionaryError: dictionaryError,
                contextualError: contextualError,
                mediaError: mediaError,
                onUnflip: onUnflip,
                onRate: onRate,
                onFetchDictionary: onFetchDictionary,
                onFetchContextual: onFetchContextual,
                onPlayClip: onPlayClip,
                onOpenInPlayer: onOpenInPlayer,
                onShadowReading: onShadowReading,
              ),
            )
          : KeyedSubtree(
              key: const ValueKey('front'),
              child: _FlashcardFront(
                word: item.word,
                contextText: primaryContext?.text,
                onFlip: onFlip,
              ),
            ),
    );
  }
}

class _FlashcardFront extends StatelessWidget {
  const _FlashcardFront({
    required this.word,
    required this.contextText,
    required this.onFlip,
  });

  final String word;
  final String? contextText;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final contextBase = tt.bodyMedium?.copyWith(
      color: cs.onSurfaceVariant.withValues(alpha: 0.9),
      height: 1.45,
    );
    final contextHighlight = contextBase?.copyWith(
      color: cs.onSurface,
      fontWeight: FontWeight.w700,
      backgroundColor: cs.primary.withValues(alpha: 0.18),
    );

    return SizedBox.expand(
      child: EnjoyCard(
        child: EnjoyTappableSurface(
          borderRadius: BorderRadius.circular(t.radiusLg),
          semanticsLabel: l10n.vocabularyFlipHint,
          onTap: onFlip,
          child: Padding(
            padding: EdgeInsets.all(t.space24),
            child: Column(
              children: [
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        word,
                        textAlign: TextAlign.center,
                        style: tt.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.0,
                          height: 1.1,
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: t.space20),
                      if (contextText != null && contextText!.isNotEmpty)
                        Text.rich(
                          TextSpan(
                            children: highlightVocabularyWord(
                              text: contextText!,
                              word: word,
                              base: contextBase ?? const TextStyle(),
                              highlight: contextHighlight ?? const TextStyle(),
                            ),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          l10n.vocabularyNoContextAvailable,
                          textAlign: TextAlign.center,
                          style: contextBase,
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(t.radiusFull),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: t.space20,
                      vertical: t.space12,
                    ),
                    child: Text(
                      l10n.vocabularyFlipHint,
                      style: tt.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlashcardBack extends StatelessWidget {
  const _FlashcardBack({
    required this.item,
    required this.primaryContext,
    required this.ratingInFlight,
    required this.dictionaryFetchInFlight,
    required this.contextualFetchInFlight,
    required this.clipPlayInFlight,
    this.dictionaryError,
    this.contextualError,
    this.mediaError,
    required this.onUnflip,
    required this.onRate,
    required this.onFetchDictionary,
    required this.onFetchContextual,
    required this.onPlayClip,
    required this.onOpenInPlayer,
    required this.onShadowReading,
  });

  final VocabularyItem item;
  final VocabularyContext? primaryContext;
  final bool ratingInFlight;
  final bool dictionaryFetchInFlight;
  final bool contextualFetchInFlight;
  final bool clipPlayInFlight;
  final String? dictionaryError;
  final String? contextualError;
  final String? mediaError;
  final VoidCallback onUnflip;
  final ValueChanged<VocabularyRating> onRate;
  final VoidCallback onFetchDictionary;
  final VoidCallback onFetchContextual;
  final VoidCallback onPlayClip;
  final VoidCallback onOpenInPlayer;
  final VoidCallback onShadowReading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SizedBox.expand(
      child: EnjoyCard(
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.space24,
                  t.space20,
                  t.space24,
                  0,
                ),
                child: Text(
                  item.word,
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              SizedBox(height: t.space12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.space24),
                child: Material(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(t.radiusMd),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(t.radiusSm),
                    ),
                    labelColor: cs.onSurface,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    labelStyle: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: tt.labelMedium,
                    labelPadding: EdgeInsets.symmetric(horizontal: t.space8),
                    tabs: [
                      Tab(height: 40, text: l10n.vocabularyContext),
                      Tab(height: 40, text: l10n.vocabularyDictionary),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ScrollbarTheme(
                  data: ScrollbarThemeData(
                    thickness: WidgetStateProperty.all(4),
                    radius: Radius.circular(t.radiusFull),
                    thumbColor: WidgetStateProperty.all(
                      cs.onSurfaceVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: TabBarView(
                    children: [
                      _TabBody(
                        child: _ContextBody(
                          word: item.word,
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
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.28),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    t.space12,
                    t.space8,
                    t.space12,
                    t.space8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.vocabularyHowWellDoYouKnow,
                        textAlign: TextAlign.center,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: t.space8),
                      _RatingBar(
                        ratingInFlight: ratingInFlight,
                        onRate: onRate,
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 36),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.symmetric(horizontal: t.space12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: ratingInFlight
                            ? null
                            : () {
                                Haptics.selection(context);
                                onUnflip();
                              },
                        child: Text(l10n.vocabularyFlipBack),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact rating pills — sized for small screens, capped on wide layouts.
class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.ratingInFlight, required this.onRate});

  static const double _maxWidth = 360;

  final bool ratingInFlight;
  final ValueChanged<VocabularyRating> onRate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final gap = MediaQuery.sizeOf(context).width < 360 ? t.space4 : t.space8;

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Row(
          children: [
            Expanded(
              child: _RatingChip(
                label: l10n.vocabularyDontKnow,
                icon: Icons.close_rounded,
                background: cs.error.withValues(alpha: 0.12),
                foreground: cs.error,
                border: cs.error.withValues(alpha: 0.35),
                emphasized: false,
                onPressed: ratingInFlight
                    ? null
                    : () => onRate(VocabularyRating.dontKnow),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _RatingChip(
                label: l10n.vocabularyKnow,
                icon: Icons.check_rounded,
                background: cs.primary.withValues(alpha: 0.18),
                foreground: cs.primary,
                border: cs.primary.withValues(alpha: 0.45),
                emphasized: true,
                onPressed: ratingInFlight
                    ? null
                    : () => onRate(VocabularyRating.know),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _RatingChip(
                label: l10n.vocabularyKnowWell,
                icon: Icons.check_circle_rounded,
                background: cs.tertiary.withValues(alpha: 0.16),
                foreground: cs.tertiary,
                border: cs.tertiary.withValues(alpha: 0.45),
                emphasized: false,
                onPressed: ratingInFlight
                    ? null
                    : () => onRate(VocabularyRating.knowWell),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact outlined rating pill (~36px tall).
class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.border,
    required this.emphasized,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color border;
  final bool emphasized;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(t.radiusFull);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: enabled ? background : background.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: enabled ? border : border.withValues(alpha: 0.25),
            width: emphasized ? 1.25 : 1,
          ),
        ),
        child: InkWell(
          onTap: enabled
              ? () {
                  Haptics.selection(context);
                  onPressed!();
                }
              : null,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.space8,
              vertical: t.space8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: foreground),
                SizedBox(width: t.space4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    return Scrollbar(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          t.space24,
          t.space16,
          t.space24,
          t.space24,
        ),
        child: child,
      ),
    );
  }
}

/// Top-level section heading with icon (Context / Source / Contextual translation).
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary.withValues(alpha: 0.9)),
        SizedBox(width: t.space8),
        Expanded(
          child: Text(
            label,
            style: tt.titleSmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Nested label inside contextual markdown (e.g. part of speech).
class _DetailLabel extends StatelessWidget {
  const _DetailLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: cs.onSurfaceVariant.withValues(alpha: 0.75),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.35,
        height: 1.2,
      ),
    );
  }
}

class _MediaAction extends StatelessWidget {
  const _MediaAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return TextButton.icon(
      onPressed: onPressed == null
          ? null
          : () {
              Haptics.selection(context);
              onPressed!();
            },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.symmetric(horizontal: t.space12),
      ),
    );
  }
}

class _StructuredContextualMarkdown extends StatelessWidget {
  const _StructuredContextualMarkdown({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final doc = parseContextualMarkdownDocument(markdown);
    final bodyStyle = buildLookupMarkdownStyleSheet(theme, t).copyWith(
      p: theme.textTheme.bodyMedium?.copyWith(
        height: 1.55,
        color: cs.onSurface.withValues(alpha: 0.92),
      ),
      blockSpacing: t.space8,
      h1: theme.textTheme.bodyMedium,
      h2: theme.textTheme.bodyMedium,
      h3: theme.textTheme.bodyMedium,
      h4: theme.textTheme.bodyMedium,
      h1Padding: EdgeInsets.zero,
      h2Padding: EdgeInsets.zero,
      h3Padding: EdgeInsets.zero,
      h4Padding: EdgeInsets.zero,
    );
    final translationStyle = bodyStyle.copyWith(
      p: theme.textTheme.bodyLarge?.copyWith(
        height: 1.5,
        color: cs.onSurface,
        fontWeight: FontWeight.w500,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (doc.preamble.isNotEmpty)
          MarkdownBody(
            data: doc.preamble,
            selectable: true,
            styleSheet: translationStyle,
          ),
        for (final section in doc.sections) ...[
          SizedBox(height: doc.preamble.isNotEmpty ? t.space20 : t.space12),
          _DetailLabel(section.title),
          SizedBox(height: t.space8),
          MarkdownBody(
            data: section.body,
            selectable: true,
            styleSheet: bodyStyle,
          ),
        ],
      ],
    );
  }
}

class _ContextBody extends ConsumerWidget {
  const _ContextBody({
    required this.word,
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

  final String word;
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
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
    final titleAsync = ref.watch(vocabularySourceTitleProvider(ctx.sourceId));
    final sourceTitle =
        titleAsync.asData?.value ??
        (titleAsync.isLoading ? null : l10n.vocabularyUnknownSource);
    final contextBase = tt.bodyLarge?.copyWith(
      height: 1.55,
      color: cs.onSurface.withValues(alpha: 0.92),
    );
    final contextHighlight = contextBase?.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
      backgroundColor: cs.primary.withValues(alpha: 0.18),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(
          icon: Icons.format_quote_rounded,
          label: l10n.vocabularyContext,
        ),
        SizedBox(height: t.space16),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 3,
                color: cs.primary.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: t.space16),
            child: Text.rich(
              TextSpan(
                children: highlightVocabularyWord(
                  text: ctx.text,
                  word: word,
                  base: contextBase ?? const TextStyle(),
                  highlight: contextHighlight ?? const TextStyle(),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: t.space32),
        _SectionHeading(
          icon: Icons.movie_outlined,
          label: l10n.vocabularySourceLabel,
        ),
        SizedBox(height: t.space16),
        if (titleAsync.isLoading && sourceTitle == null)
          Text('…', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
        else
          Text(
            sourceTitle ?? l10n.vocabularyUnknownSource,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: tt.bodyLarge?.copyWith(
              color: cs.onSurface,
              height: 1.4,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        if (locator != null) ...[
          SizedBox(height: t.space8),
          Text(
            l10n.vocabularyLocatorLabel(
              (locator.start / 1000).toStringAsFixed(1),
              (locator.duration / 1000).toStringAsFixed(1),
            ),
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.85),
              letterSpacing: 0.1,
            ),
          ),
        ],
        if (canMedia) ...[
          SizedBox(height: t.space8),
          Wrap(
            spacing: t.space4,
            runSpacing: t.space4,
            children: [
              _MediaAction(
                icon: Icons.play_arrow_rounded,
                label: clipPlayInFlight
                    ? l10n.vocabularyFetching
                    : l10n.vocabularyPlaySegment,
                onPressed: clipPlayInFlight ? null : onPlayClip,
              ),
              _MediaAction(
                icon: Icons.open_in_new_rounded,
                label: l10n.vocabularyOpenInPlayer,
                onPressed: onOpenInPlayer,
              ),
              _MediaAction(
                icon: Icons.record_voice_over_rounded,
                label: l10n.vocabularyShadowReading,
                onPressed: onShadowReading,
              ),
            ],
          ),
        ] else ...[
          SizedBox(height: t.space12),
          Text(
            l10n.vocabularyMediaUnavailable,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
        if (mediaError != null) ...[
          SizedBox(height: t.space8),
          _SoftError(message: l10n.vocabularyMediaPlayFailed),
        ],
        SizedBox(height: t.space32),
        _SectionHeading(
          icon: Icons.translate_rounded,
          label: l10n.vocabularyContextualTranslation,
        ),
        SizedBox(height: t.space16),
        if (translation != null)
          _StructuredContextualMarkdown(markdown: translation.translatedText)
        else if (!signedIn)
          const AuthRequiredCallout(
            surface: AuthRequiredSurface.lookupContextual,
            compact: true,
          )
        else if (contextualFetchInFlight)
          Padding(
            padding: EdgeInsets.symmetric(vertical: t.space8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary.withValues(alpha: 0.85),
                  ),
                ),
                SizedBox(width: t.space12),
                Text(
                  l10n.vocabularyFetching,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          )
        else ...[
          if (contextualError != null)
            Padding(
              padding: EdgeInsets.only(bottom: t.space8),
              child: _SoftError(message: l10n.vocabularyAiFetchFailed),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: EnjoyButton.secondary(
              onPressed: onFetchContextual,
              child: Text(l10n.vocabularyFetchContextual),
            ),
          ),
        ],
      ],
    );
  }
}

class _SoftError extends StatelessWidget {
  const _SoftError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(t.radiusSm),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: t.space12,
          vertical: t.space8,
        ),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onErrorContainer,
            height: 1.35,
          ),
        ),
      ),
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
          _SoftError(message: l10n.vocabularyAiFetchFailed),
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
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final lemmaTrim = result.lemma?.trim();
    final showLemma =
        lemmaTrim != null &&
        lemmaTrim.isNotEmpty &&
        lemmaTrim != result.word.trim();
    final ipaFormatted = result.ipa == null
        ? ''
        : formatVocabularyIpa(result.ipa!);
    final hasIpa = ipaFormatted.isNotEmpty;

    if (result.senses.isEmpty) {
      return Text(l10n.vocabularyDictionaryNotAvailable);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasIpa || showLemma) ...[
          Wrap(
            spacing: t.space8,
            runSpacing: t.space4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hasIpa)
                Text(
                  ipaFormatted,
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              if (showLemma)
                Text(
                  lemmaTrim,
                  style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
          SizedBox(height: t.space16),
        ],
        for (var i = 0; i < result.senses.length; i++) ...[
          if (i > 0) ...[
            SizedBox(height: t.space12),
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.18),
            ),
            SizedBox(height: t.space12),
          ],
          _SenseTile(sense: result.senses[i]),
        ],
      ],
    );
  }
}

class _SenseTile extends StatelessWidget {
  const _SenseTile({required this.sense});

  final DictionarySense sense;

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
            style: tt.bodyMedium?.copyWith(height: 1.45),
          ),
        if (sense.translation != null &&
            sense.translation!.trim().isNotEmpty) ...[
          SizedBox(height: t.space4),
          SelectableText(
            sense.translation!,
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: translationColor,
              height: 1.4,
            ),
          ),
        ],
        if (sense.examples != null && sense.examples!.isNotEmpty) ...[
          SizedBox(height: t.space12),
          for (final ex in sense.examples!)
            Padding(
              padding: EdgeInsets.only(bottom: t.space8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 2,
                      color: scheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                padding: EdgeInsetsDirectional.only(start: t.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      ex.source,
                      style: tt.bodySmall?.copyWith(
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (ex.target != null && ex.target!.trim().isNotEmpty) ...[
                      SizedBox(height: t.space4),
                      SelectableText(
                        ex.target!,
                        style: tt.bodySmall?.copyWith(
                          height: 1.4,
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.85,
                          ),
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
