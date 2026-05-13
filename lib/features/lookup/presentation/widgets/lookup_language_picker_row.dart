/// Source / target language pills + swap for the dictionary lookup sheet.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/language_choice_sheet.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class LookupLanguagePickerRow extends StatelessWidget {
  const LookupLanguagePickerRow({
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.onSourceChanged,
    required this.onTargetChanged,
    required this.onSwap,
    super.key,
  });

  final String sourceLanguage;
  final String targetLanguage;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String> onTargetChanged;
  final VoidCallback onSwap;

  String _label(String tag) =>
      kLookupLanguageLabels[normalizeBcp47Tag(tag)] ?? normalizeBcp47Tag(tag);

  Future<void> _pickSource(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final options = kSupportedNativeLanguageTags
        .map((v) => LanguageChoiceOption(value: v, label: _label(v)))
        .toList(growable: false);
    final picked = await showLanguageChoiceSheet(
      context: context,
      title: l10n.lookupPickSourceTitle,
      options: options,
      selectedValue: sourceLanguage,
    );
    if (picked != null && !tagsEqual(picked, sourceLanguage)) {
      onSourceChanged(picked);
      if (tagsEqual(picked, targetLanguage)) {
        final other = kSupportedNativeLanguageTags.firstWhere(
          (t) => !tagsEqual(t, picked),
          orElse: () => targetLanguage,
        );
        if (!tagsEqual(other, targetLanguage)) onTargetChanged(other);
      }
    }
  }

  Future<void> _pickTarget(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final allowed = kSupportedNativeLanguageTags
        .where((t) => !tagsEqual(t, sourceLanguage))
        .toList(growable: false);
    if (allowed.isEmpty) return;
    final options = allowed
        .map((v) => LanguageChoiceOption(value: v, label: _label(v)))
        .toList(growable: false);
    final picked = await showLanguageChoiceSheet(
      context: context,
      title: l10n.lookupPickTargetTitle,
      options: options,
      selectedValue: targetLanguage,
    );
    if (picked != null && !tagsEqual(picked, targetLanguage)) {
      onTargetChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final canSwap = !tagsEqual(sourceLanguage, targetLanguage);
    final targetChoices = kSupportedNativeLanguageTags
        .where((x) => !tagsEqual(x, sourceLanguage))
        .toList(growable: false);

    final outerRadius = BorderRadius.circular(t.radiusMd);
    final r = t.radiusMd;

    Widget verticalRule() {
      return Container(
        width: 1,
        margin: EdgeInsets.symmetric(vertical: t.space8),
        color: scheme.outlineVariant.withValues(alpha: 0.28),
      );
    }

    Widget segment({
      required BorderRadius borderRadius,
      required String semanticsLabel,
      required String text,
      required VoidCallback? onTap,
    }) {
      return EnjoyTappableSurface(
        borderRadius: borderRadius,
        onTap: onTap,
        semanticsLabel: semanticsLabel,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: t.space12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(width: t.space4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: outerRadius,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: ClipRRect(
        borderRadius: outerRadius,
        child: SizedBox(
          height: 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: segment(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(r),
                    bottomLeft: Radius.circular(r),
                  ),
                  semanticsLabel: l10n.lookupSourceLanguage,
                  text: _label(sourceLanguage),
                  onTap: () => _pickSource(context),
                ),
              ),
              verticalRule(),
              Tooltip(
                message: l10n.lookupSwapLanguages,
                child: EnjoyTappableSurface(
                  borderRadius: BorderRadius.zero,
                  onTap: canSwap ? onSwap : null,
                  semanticsLabel: l10n.lookupSwapLanguages,
                  child: SizedBox(
                    width: 44,
                    child: Center(
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        size: 22,
                        color: canSwap
                            ? scheme.primary
                            : scheme.onSurfaceVariant.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),
              verticalRule(),
              Expanded(
                child: segment(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(r),
                    bottomRight: Radius.circular(r),
                  ),
                  semanticsLabel: l10n.lookupTargetLanguage,
                  text: _label(targetLanguage),
                  onTap: targetChoices.isEmpty
                      ? null
                      : () => _pickTarget(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
