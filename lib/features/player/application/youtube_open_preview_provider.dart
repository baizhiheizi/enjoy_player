/// Thumbnail preview for YouTube rows while [openMediaActionProvider] resolves.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';

typedef YoutubeOpenPreview = ({String videoId, String? thumbnailUrl});

final youtubeOpenPreviewProvider = FutureProvider.autoDispose
    .family<YoutubeOpenPreview?, String>((ref, mediaId) async {
      final row = await ref.read(appDatabaseProvider).videoDao.getById(mediaId);
      if (row == null || row.provider.toLowerCase() != 'youtube') {
        return null;
      }
      final thumb = remoteThumbnailForCard(
        row.thumbnailUrl,
        youtubeVideoId: row.vid,
        mediaUrl: row.mediaUrl,
      );
      return (videoId: row.vid, thumbnailUrl: thumb);
    });
