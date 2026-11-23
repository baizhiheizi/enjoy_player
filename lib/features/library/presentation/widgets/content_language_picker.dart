/// Pick content language during import or edit.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/language_choice_sheet.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Shows language picker; returns canonical media tag or `null` if dismissed.
Future<String?> showContentLanguagePicker({
  required BuildContext context,
  required WidgetRef ref,
  String? selectedValue,
  String? title,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final prefs = ref.read(appPreferencesCtrlProvider);
  final prefsState = prefs.whenOrNull(data: (s) => s);
  final defaultTag = canonicalMediaLanguageTag(
    selectedValue ?? prefsState?.effectiveLearningLanguage,
  );
  final opts = mediaLanguageChoices(l10n)
      .map((e) => LanguageChoiceOption(value: e.value, label: e.label))
      .toList(growable: false);
  final picked = await showLanguageChoiceSheet(
    context: context,
    title: title ?? l10n.mediaLanguagePickerTitle,
    options: opts,
    selectedValue: defaultTag,
  );
  if (picked == null) return null;
  return canonicalMediaLanguageTag(picked);
}

/// Shows focus learning language picker.
Future<String?> showFocusLanguagePicker({
  required BuildContext context,
  required String selectedValue,
  String? title,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final opts = focusLanguageChoices(l10n)
      .map((e) => LanguageChoiceOption(value: e.value, label: e.label))
      .toList(growable: false);
  return showLanguageChoiceSheet(
    context: context,
    title: title ?? l10n.settingsLanguagePickerTitleLearning,
    options: opts,
    selectedValue: canonicalFocusLanguageTag(selectedValue),
  );
}
