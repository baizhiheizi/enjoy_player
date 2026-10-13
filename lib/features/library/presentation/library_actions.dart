/// Shared import flow for Home / Library.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/data/files/media_resolver.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/platform/mobile_platform.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/library/presentation/widgets/content_language_picker.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// After native pickers / activity resume, the navigator can still be locked.
/// Dismiss the blocking dialog on the next frame, then run [then] one frame later
/// so [Navigator.pop] and follow-up navigation (e.g. [openPlayerRoute]) do not hit
/// `!_debugLocked` or pop the wrong route when the dialog was not shown on the same
/// navigator as the dismiss call.
void _dismissBlockingImportDialogThen(BuildContext context, VoidCallback then) {
  if (!context.mounted) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      then();
    });
  });
}

/// Blocking progress dialog shown on the root navigator while a file or YouTube
/// import is in flight. [label] resolves to the localized status string from
/// the [AppLocalizations] exposed inside the dialog's own [BuildContext], so
/// callers pass `(l10n) => l10n.importingMedia` (file) or
/// `(l10n) => l10n.youtubeImporting` (YouTube). Paired with
/// [_dismissBlockingImportDialogThen] in the success / failure branches so the
/// dialog always tears down before navigation.
void _showImportProgressDialog(
  BuildContext context,
  String Function(AppLocalizations) label,
) {
  unawaited(
    showEnjoyDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(width: 24),
                Expanded(child: Text(label(l10n))),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Runs [import] behind the shared blocking-progress scaffold: shows the
/// progress dialog, waits a frame, checks auth, then dismisses the dialog
/// and either opens the player or surfaces an error notice.
Future<void> _runBlockingImport(
  BuildContext context,
  WidgetRef ref, {
  required String Function(AppLocalizations) progressLabel,
  required Future<String> Function(String signedInUserId) import,
  required String Function(AppLocalizations) importFailureLabel,
  required String unsupportedFileLabel,
}) async {
  final l10n = AppLocalizations.of(context)!;
  _showImportProgressDialog(context, progressLabel);
  await WidgetsBinding.instance.endOfFrame;

  try {
    final auth = ref.read(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) return;
    final id = await import(auth.profile.id);
    if (!context.mounted) return;
    _dismissBlockingImportDialogThen(
      context,
      () => openPlayerRoute(context, id),
    );
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    _dismissBlockingImportDialogThen(
      context,
      () => AppNotice.error(
        context,
        e is UnsupportedImportFileFailure ? unsupportedFileLabel : e.message,
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    _dismissBlockingImportDialogThen(
      context,
      () => AppNotice.error(context, importFailureLabel(l10n)),
    );
  }
}

Future<void> importMediaFromPicker(BuildContext context, WidgetRef ref) async {
  final pick = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: kFilePickerLocalImportExtensions,
  );
  if (pick == null) return;
  final path = pick.path;
  if (path == null) return;
  if (!context.mounted) return;

  final contentLanguage = await showContentLanguagePicker(
    context: context,
    ref: ref,
  );
  if (contentLanguage == null || !context.mounted) return;

  await _runBlockingImport(
    context,
    ref,
    progressLabel: (d) => d.importingMedia,
    import: (userId) => ref
        .read(mediaLibraryRepositoryProvider)
        .importMedia(
          XFile(path),
          signedInUserId: userId,
          contentLanguage: contentLanguage,
        ),
    importFailureLabel: (l10n) => l10n.importMediaFailed,
    unsupportedFileLabel: AppLocalizations.of(
      context,
    )!.importUnsupportedFileType,
  );
}

Future<void> confirmAndDeleteMedia(
  BuildContext context,
  WidgetRef ref,
  Media media,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showEnjoyConfirmDialog(
    context: context,
    title: l10n.libraryDeleteMediaTitle,
    message: l10n.libraryDeleteMediaMessage(media.title),
    confirmLabel: MaterialLocalizations.of(context).deleteButtonTooltip,
    destructive: true,
  );
  if (confirmed != true || !context.mounted) return;
  try {
    final session = ref.read(playerControllerProvider);
    await ref.read(mediaLibraryRepositoryProvider).deleteMedia(media.id);
    if (!context.mounted) return;
    if (session?.mediaId == media.id) {
      await ref.read(playerControllerProvider.notifier).clear();
    }
    if (!context.mounted) return;
    final openId = GoRouterState.of(context).pathParameters['mediaId'];
    if (openId == media.id) {
      context.pop();
    }
    if (!context.mounted) return;
    AppNotice.success(context, l10n.libraryMediaDeleted);
  } catch (_) {
    if (context.mounted) {
      AppNotice.error(context, l10n.libraryDeleteFailed);
    }
  }
}

/// Import chooser: file, YouTube URL, or Craft. Desktop windows with an
/// [anchor] (the Import button) get a menu dropped under it; otherwise a
/// bottom sheet.
Future<void> showImportChooser(
  BuildContext context,
  WidgetRef ref, {
  BuildContext? anchor,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final options = <(IconData, String, VoidCallback)>[
    (
      EnjoyIcons.folder,
      l10n.importFromFile,
      () => unawaited(importMediaFromPicker(context, ref)),
    ),
    (
      EnjoyIcons.videoLibrary,
      l10n.importFromYoutube,
      () => unawaited(importYoutubeFromDialog(context, ref)),
    ),
    (
      EnjoyIcons.sparkle,
      l10n.importCraftFromText,
      () => unawaited(context.push('/craft')),
    ),
  ];

  final anchorBox = anchor?.findRenderObject();
  if (!isMobilePlatform && anchorBox is RenderBox && anchorBox.hasSize) {
    final overlay =
        Navigator.of(anchor!).overlay!.context.findRenderObject()! as RenderBox;
    final topLeft = anchorBox.localToGlobal(
      Offset(0, anchorBox.size.height + 6),
      ancestor: overlay,
    );
    final bottomRight = anchorBox.localToGlobal(
      anchorBox.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final picked = await showMenu<int>(
      context: anchor,
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      position: RelativeRect.fromLTRB(
        bottomRight.dx,
        topLeft.dy,
        overlay.size.width - bottomRight.dx,
        overlay.size.height - topLeft.dy,
      ),
      items: [
        for (final (i, (icon, label, _)) in options.indexed)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 12),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
    );
    if (picked != null) options[picked].$3();
    return;
  }

  await showEnjoySheet<void>(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PaddedSheetDragHandle(),
            for (final (icon, label, onTap) in options)
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () {
                  Navigator.pop(ctx);
                  onTap();
                },
              ),
          ],
        ),
      );
    },
  );
}

Future<void> importYoutubeFromDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();

  final submitted = await showEnjoyAlertDialog<String>(
    context: context,
    title: Text(l10n.youtubeImportTitle),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(hintText: l10n.youtubeImportHint),
            autofocus: true,
            maxLines: 3,
            minLines: 1,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final clip = await Clipboard.getData('text/plain');
                final t = clip?.text;
                if (t != null && t.isNotEmpty) {
                  controller.text = t;
                }
              },
              icon: const Icon(EnjoyIcons.paste, size: 18),
              label: Text(l10n.youtubePasteFromClipboard),
            ),
          ),
        ],
      ),
    ),
    actionsBuilder: (ctx) => [
      EnjoyButton.secondary(
        onPressed: () => Navigator.pop(ctx),
        child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
      ),
      EnjoyButton.brand(
        onPressed: () => Navigator.pop(ctx, controller.text.trim()),
        child: Text(l10n.actionImport),
      ),
    ],
  );

  if (submitted == null || submitted.isEmpty) return;
  if (!context.mounted) return;

  final contentLanguage = await showContentLanguagePicker(
    context: context,
    ref: ref,
  );
  if (contentLanguage == null || !context.mounted) return;

  await _runBlockingImport(
    context,
    ref,
    progressLabel: (d) => d.youtubeImporting,
    import: (userId) async {
      final id = await ref
          .read(mediaLibraryRepositoryProvider)
          .importYoutubeVideo(submitted, contentLanguage: contentLanguage);
      ref.invalidate(libraryMediaProvider);
      ref.invalidate(libraryHomeRecentsProvider);
      return id;
    },
    importFailureLabel: (l10n) => l10n.youtubeImportInvalid,
    unsupportedFileLabel: AppLocalizations.of(context)!.youtubeImportInvalid,
  );
}

Future<void> editMediaLanguage(
  BuildContext context,
  WidgetRef ref,
  Media media,
) async {
  final l10n = AppLocalizations.of(context)!;
  final picked = await showContentLanguagePicker(
    context: context,
    ref: ref,
    selectedValue: media.language,
    title: l10n.mediaEditLanguage,
  );
  if (picked == null || !context.mounted) return;
  if (tagsEqual(picked, media.language)) return;

  try {
    await ref
        .read(mediaLibraryRepositoryProvider)
        .updateMediaLanguage(media.id, picked);
    final session = ref.read(playerControllerProvider);
    if (session?.mediaId == media.id) {
      ref
          .read(playerControllerProvider.notifier)
          .applySessionPatch(session!.copyWith(language: picked));
    }
    if (!context.mounted) return;
    AppNotice.success(context, l10n.mediaLanguageUpdated);
  } catch (_) {
    if (context.mounted) {
      AppNotice.error(context, l10n.mediaLanguageUpdateFailed);
    }
  }
}
