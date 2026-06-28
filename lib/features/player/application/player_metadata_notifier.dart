/// Patches in-flight [PlaybackSession] title/thumbnail after lazy metadata fetch.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/player/application/player_controller.dart';

part 'player_metadata_notifier.g.dart';

@Riverpod(keepAlive: true)
class PlayerMetadataNotifier extends _$PlayerMetadataNotifier {
  @override
  void build() {}

  /// Updates session chrome when [openGeneration] and [mediaId] still match.
  void patchIfCurrent({
    required String mediaId,
    required int openGeneration,
    required String title,
    String? thumbnailUrl,
  }) {
    final controller = ref.read(playerControllerProvider.notifier);
    if (controller.openGeneration != openGeneration) return;
    final session = ref.read(playerControllerProvider);
    if (session?.mediaId != mediaId) return;
    controller.applySessionPatch(
      session!.copyWith(
        mediaTitle: title,
        thumbnailUrl: thumbnailUrl ?? session.thumbnailUrl,
      ),
    );
  }
}
