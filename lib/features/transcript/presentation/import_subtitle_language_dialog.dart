/// Shared dialog: choose BCP-47 language before importing a subtitle file.
library;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Guess BCP-47-ish code from filename (e.g. `movie.en.srt` → `en`).
String languageHintFromSubtitleFileName(String fileName) {
  final base = p.basenameWithoutExtension(fileName).toLowerCase();
  final m = RegExp(
    r'(?:^|[._-])([a-z]{2}(?:-[a-z]{2,4})?)(?:[._-]|$)',
    caseSensitive: false,
  ).firstMatch(base);
  if (m != null) return m.group(1)!;
  return 'und';
}

/// Returns trimmed language code, or null if cancelled.
Future<String?> showImportSubtitleLanguageDialog(
  BuildContext context, {
  required String initialLanguage,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final ctrl = TextEditingController(text: initialLanguage);
  return showDialog<String>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(l10n.subtitlesImportLanguageTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.subtitlesImportLanguageHint,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: EnjoyThemeTokens.of(ctx).space12),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
            ),
          ],
        ),
  );
}
