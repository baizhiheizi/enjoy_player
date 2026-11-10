/// Whether [secondaryId] is the auto-translate AI track for [mediaId].
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/application/app_preferences_provider.dart';
import '../../../core/riverpod/async_value_x.dart';
import '../../../data/db/app_database_provider.dart';
import '../../../data/db/media_target_resolver.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../domain/auto_translate.dart';
import 'transcript_repository_provider.dart';

part 'auto_translate_selection_providers.g.dart';

/// Whether [secondaryId] is the auto-translate AI track for [mediaId].
@riverpod
Future<bool> isAutoTranslateSecondary(
  Ref ref,
  String mediaId,
  String? secondaryId,
) async {
  if (secondaryId == null) return false;
  final row = await ref
      .read(transcriptRepositoryProvider)
      .transcriptRowById(secondaryId);
  return row?.source == 'ai';
}

/// Predicted AI track id for picker radio value (may not exist in DB yet).
@riverpod
Future<String?> autoTranslateSelectionId(Ref ref, String mediaId) async {
  final auth = ref.watch(authCtrlProvider).valueOrNull;
  if (auth is! AuthSignedIn) return null;
  final native = ref
      .watch(appPreferencesCtrlProvider)
      .valueOrNull
      ?.effectiveNativeLanguage;
  if (native == null || native.isEmpty) return null;

  final db = ref.read(appDatabaseProvider);
  final tt = await dexieTargetTypeForId(db, mediaId);
  if (tt == null) return null;

  return autoTranslateAiTrackId(
    targetType: tt,
    mediaId: mediaId,
    targetLanguage: native,
  );
}
