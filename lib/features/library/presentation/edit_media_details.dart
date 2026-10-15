/// Edit-details dialog for a library media item: rename + content language.
/// Reached from the player's ⋯ More → Media → Edit details and reusable from
/// library surfaces that already hold the [Media].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/data/db/media_registry_provider.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/library/presentation/widgets/content_language_picker.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// The two fields Edit details edits, as saved.
typedef MediaDetails = ({String title, String language});

/// Opens Edit details for the media holding [mediaId] — the player ⋯ More
/// entry point, which only has the id at hand. A row deleted while the player
/// is open surfaces an error notice instead of the dialog.
Future<void> editMediaDetailsForId(
  BuildContext context,
  WidgetRef ref,
  String mediaId,
) async {
  final l10n = AppLocalizations.of(context)!;
  final media = await ref.read(mediaRegistryProvider).getById(mediaId);
  if (!context.mounted) return;
  if (media == null) {
    AppNotice.error(context, l10n.mediaDetailsMissing);
    return;
  }
  await editMediaDetails(context, ref, media);
}

/// Shows the Edit details dialog for [media]; saves through the repository
/// and patches the open player session (title + language) so the player top
/// bar and lookup language reflect the change without reopening the media.
Future<void> editMediaDetails(
  BuildContext context,
  WidgetRef ref,
  Media media,
) async {
  final l10n = AppLocalizations.of(context)!;
  final details = await _showEditDetailsDialog(context, ref, media);
  if (details == null || !context.mounted) return;

  final originalTitle = media.title.trim();
  final titleChanged = details.title != originalTitle;
  final languageChanged = !tagsEqual(details.language, media.language);
  if (!titleChanged && !languageChanged) return;

  try {
    if (titleChanged) {
      await ref
          .read(mediaLibraryRepositoryProvider)
          .updateMediaTitle(media.id, details.title);
    }
    if (languageChanged) {
      await ref
          .read(mediaLibraryRepositoryProvider)
          .updateMediaLanguage(media.id, details.language);
    }
    final session = ref.read(playerControllerProvider);
    if (session?.mediaId == media.id) {
      ref
          .read(playerControllerProvider.notifier)
          .applySessionPatch(
            session!.copyWith(
              mediaTitle: titleChanged ? details.title : null,
              language: languageChanged ? details.language : null,
            ),
          );
    }
    if (!context.mounted) return;
    AppNotice.success(context, l10n.mediaDetailsUpdated);
  } catch (_) {
    if (context.mounted) {
      AppNotice.error(context, l10n.mediaDetailsUpdateFailed);
    }
  }
}

Future<MediaDetails?> _showEditDetailsDialog(
  BuildContext context,
  WidgetRef ref,
  Media media,
) {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: media.title);
  var language = canonicalMediaLanguageTag(media.language);

  return showEnjoyAlertDialog<MediaDetails>(
    context: context,
    title: Text(l10n.mediaEditDetails),
    content: StatefulBuilder(
      builder: (dialogContext, setState) {
        final t = EnjoyThemeTokens.of(dialogContext);

        Future<void> pickLanguage() async {
          final picked = await showContentLanguagePicker(
            context: dialogContext,
            ref: ref,
            selectedValue: language,
            title: l10n.mediaLanguagePickerTitle,
          );
          if (!dialogContext.mounted || picked == null) return;
          setState(() => language = picked);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.mediaDetailsTitleLabel,
              ),
            ),
            SizedBox(height: t.space12),
            EnjoyPressable(
              borderRadius: BorderRadius.circular(t.radiusMd),
              pressedScale: 1,
              washColor: t.sunk,
              semanticsLabel: l10n.mediaLanguagePickerTitle,
              onTap: Haptics.wrapTap(dialogContext, pickLanguage),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: t.space12,
                  vertical: t.space12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.mediaLanguagePickerTitle,
                            style: Theme.of(
                              dialogContext,
                            ).textTheme.labelSmall?.copyWith(color: t.ink2),
                          ),
                          SizedBox(height: t.space4),
                          Text(
                            focusLanguageLabel(l10n, language),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(dialogContext).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    Icon(EnjoyIcons.chevronRight, size: 18, color: t.ink3),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
    actionsBuilder: (dialogContext) => [
      EnjoyButton.secondary(
        onPressed: () => Navigator.pop(dialogContext),
        child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
      ),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final title = value.text.trim();
          return EnjoyButton.brand(
            onPressed: title.isEmpty
                ? null
                : () => Navigator.pop(dialogContext, (
                    title: title,
                    language: language,
                  )),
            child: Text(l10n.mediaDetailsSave),
          );
        },
      ),
    ],
  );
}
