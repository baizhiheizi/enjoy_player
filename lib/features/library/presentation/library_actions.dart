/// Shared import flow for Home / Library.
library;

import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
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

Future<void> importMediaFromPicker(BuildContext context, WidgetRef ref) async {
  final pick = await FilePicker.pickFiles(type: FileType.media);
  if (pick == null || pick.files.isEmpty) return;
  final path = pick.files.single.path;
  if (path == null) return;
  if (!context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  unawaited(
    showEnjoyDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) {
        final d = AppLocalizations.of(dialogContext)!;
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
                Expanded(child: Text(d.importingMedia)),
              ],
            ),
          ),
        );
      },
    ),
  );
  // Let the modal route build and paint before starting import (Duration.zero is not enough).
  await WidgetsBinding.instance.endOfFrame;

  try {
    final auth = ref.read(authCtrlProvider).valueOrNull;
    final userId = auth is AuthSignedIn ? auth.profile.id : null;
    final id = await ref
        .read(mediaLibraryRepositoryProvider)
        .importMedia(XFile(path), signedInUserId: userId);
    if (!context.mounted) return;
    _dismissBlockingImportDialogThen(
      context,
      () => openPlayerRoute(context, id),
    );
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    _dismissBlockingImportDialogThen(
      context,
      () => AppNotice.error(context, e.message),
    );
  } catch (_) {
    if (!context.mounted) return;
    _dismissBlockingImportDialogThen(
      context,
      () => AppNotice.error(context, l10n.importMediaFailed),
    );
  }
}

Future<void> confirmAndDeleteMedia(
  BuildContext context,
  WidgetRef ref,
  Media media,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showEnjoyAlertDialog<bool>(
    context: context,
    title: Text(l10n.libraryDeleteMediaTitle),
    content: Text(l10n.libraryDeleteMediaMessage(media.title)),
    actionsBuilder: (ctx) => [
      TextButton(
        onPressed: () => Navigator.pop(ctx, false),
        child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
      ),
      TextButton(
        onPressed: () => Navigator.pop(ctx, true),
        child: Text(MaterialLocalizations.of(ctx).deleteButtonTooltip),
      ),
    ],
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref.read(mediaLibraryRepositoryProvider).deleteMedia(media.id);
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

/// Bottom sheet: choose file import vs YouTube URL.
Future<void> showImportChooser(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  await showEnjoySheet<void>(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PaddedSheetDragHandle(),
            ListTile(
              leading: const Icon(Icons.folder_open_rounded),
              title: Text(l10n.importFromFile),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(importMediaFromPicker(context, ref));
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: Text(l10n.importFromYoutube),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(importYoutubeFromDialog(context, ref));
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
              icon: const Icon(Icons.paste_rounded, size: 18),
              label: Text(l10n.youtubePasteFromClipboard),
            ),
          ),
        ],
      ),
    ),
    actionsBuilder: (ctx) => [
      TextButton(
        onPressed: () => Navigator.pop(ctx),
        child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(ctx, controller.text.trim()),
        child: Text(l10n.actionImport),
      ),
    ],
  );

  if (submitted == null || submitted.isEmpty) return;
  if (!context.mounted) return;

  unawaited(
    showEnjoyDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) {
        final d = AppLocalizations.of(dialogContext)!;
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
                Expanded(child: Text(d.youtubeImporting)),
              ],
            ),
          ),
        );
      },
    ),
  );
  // Let the modal route build and paint before starting import.
  await WidgetsBinding.instance.endOfFrame;

  try {
    final auth = ref.read(authCtrlProvider).valueOrNull;
    final userId = auth is AuthSignedIn ? auth.profile.id : null;
    final id = await ref
        .read(mediaLibraryRepositoryProvider)
        .importYoutubeVideo(submitted, signedInUserId: userId);
    if (!context.mounted) return;
    _dismissBlockingImportDialogThen(
      context,
      () => openPlayerRoute(context, id),
    );
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    _dismissBlockingImportDialogThen(
      context,
      () => AppNotice.error(context, e.message),
    );
  } catch (_) {
    if (!context.mounted) return;
    _dismissBlockingImportDialogThen(
      context,
      () => AppNotice.error(context, l10n.youtubeImportInvalid),
    );
  }
}
