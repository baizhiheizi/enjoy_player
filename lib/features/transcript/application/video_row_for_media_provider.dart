/// Looks up [VideoRow] for a media id (video items only — audio returns null).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry_provider.dart';

final videoRowForMediaProvider = FutureProvider.autoDispose
    .family<VideoRow?, String>((ref, mediaId) async {
      return ref.watch(mediaRegistryProvider).getVideoById(mediaId);
    });
