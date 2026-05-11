/// Post-open work that is not required for immediate playback (transcripts, sync).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';

void schedulePlayerOpenSideEffects(
  Ref ref, {
  required String mediaId,
  required String dexieTargetType,
}) {
  unawaited(
    ref.read(transcriptRepositoryProvider).fetchCloudTranscripts(mediaId),
  );

  final auth = ref.read(authCtrlProvider).valueOrNull;
  if (auth is AuthSignedIn) {
    unawaited(
      ref.read(recordingTargetSyncServiceProvider).pullRecordingsForTarget(
            targetType: dexieTargetType,
            targetId: mediaId,
          ),
    );
  }
}
