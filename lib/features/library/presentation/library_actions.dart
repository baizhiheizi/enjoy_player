/// Shared import flow for Home / Library.
library;

import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Future<void> importMediaFromPicker(BuildContext context, WidgetRef ref) async {
  final pick = await FilePicker.pickFiles(type: FileType.media);
  if (pick == null || pick.files.isEmpty) return;
  final path = pick.files.single.path;
  if (path == null) return;
  if (!context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  unawaited(
    showDialog<void>(
      context: context,
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
  // Allow the dialog route to be scheduled before import work runs.
  await Future<void>.delayed(Duration.zero);

  try {
    final auth = ref.read(authCtrlProvider).valueOrNull;
    final userId = auth is AuthSignedIn ? auth.profile.id : null;
    final id = await ref.read(mediaLibraryRepositoryProvider).importMedia(
          XFile(path),
          signedInUserId: userId,
        );
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (context.mounted) {
      context.push('/player/$id');
    }
  } on AppFailure catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importMediaFailed)),
      );
    }
  }
}
