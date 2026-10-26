/// Library card wiring shared by the home grid and the local library tabs:
/// artwork resolution, provider / sync badges, language chip, duration, and
/// the open / delete / edit-language actions.
library;

import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/theme/widgets/media_card/media_card_provider_badge.dart';
import 'package:enjoy_player/core/theme/widgets/media_card/media_card_sync_badge.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/library/presentation/library_actions.dart';
import 'package:enjoy_player/features/player/application/local_thumbnail_provider.dart';
import 'package:enjoy_player/features/player/application/youtube_warm.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class LibraryMediaTile extends ConsumerWidget {
  const LibraryMediaTile({
    required this.media,
    required this.subtitle,
    required this.isVideo,
    required this.heroArtworkMediaId,
    this.languagePlacement = MediaCardLanguagePlacement.cover,
    super.key,
  });

  final Media media;
  final String subtitle;
  final bool isVideo;
  final String? heroArtworkMediaId;
  final MediaCardLanguagePlacement languagePlacement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = _LibraryMediaCard.resolve(context, ref, media);
    return MediaCardTile(
      title: media.title,
      subtitle: subtitle,
      language: card.language,
      languagePlacement: languagePlacement,
      onLanguageTap: card.editLanguage,
      durationLabel: card.durationLabel,
      thumbnailFile: card.thumbnailFile,
      providerBadge: card.providerBadge,
      cloudSyncBadge: card.cloudSyncBadge,
      thumbnailNetworkUrl: card.thumbnailNetworkUrl,
      coverSeed: media.coverSeed,
      isVideo: isVideo,
      accentColor: card.accentColor,
      heroArtworkMediaId: heroArtworkMediaId,
      deleteTooltip: card.deleteTooltip,
      onDelete: card.onDelete,
      onTap: card.onTap,
    );
  }
}

class LibraryMediaRow extends ConsumerWidget {
  const LibraryMediaRow({
    required this.media,
    required this.subtitle,
    required this.heroArtworkMediaId,
    super.key,
  });

  final Media media;
  final String subtitle;
  final String? heroArtworkMediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = _LibraryMediaCard.resolve(context, ref, media);
    return MediaCardRow(
      title: media.title,
      subtitle: subtitle,
      language: card.language,
      onLanguageTap: card.editLanguage,
      durationLabel: card.durationLabel,
      thumbnailFile: card.thumbnailFile,
      providerBadge: card.providerBadge,
      cloudSyncBadge: card.cloudSyncBadge,
      thumbnailNetworkUrl: card.thumbnailNetworkUrl,
      coverSeed: media.coverSeed,
      accentColor: card.accentColor,
      heroArtworkMediaId: heroArtworkMediaId,
      deleteTooltip: card.deleteTooltip,
      onDelete: card.onDelete,
      onTap: card.onTap,
    );
  }
}

class _LibraryMediaCard {
  const _LibraryMediaCard({
    required this.language,
    required this.durationLabel,
    required this.thumbnailFile,
    required this.thumbnailNetworkUrl,
    required this.accentColor,
    required this.providerBadge,
    required this.cloudSyncBadge,
    required this.deleteTooltip,
    required this.onDelete,
    required this.onTap,
    required this.editLanguage,
  });

  factory _LibraryMediaCard.resolve(
    BuildContext context,
    WidgetRef ref,
    Media media,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final thumbnail = ref
        .watch(localThumbnailFileProvider(localThumbnailPathForMedia(media)))
        .value;
    return _LibraryMediaCard(
      language: languageCodeLabel(media.language),
      durationLabel: media.durationMs > 0
          ? formatDurationHmsMs(media.durationMs)
          : null,
      thumbnailFile: thumbnail,
      thumbnailNetworkUrl: networkThumbnailForMedia(media),
      accentColor: generativeAccentForSeed(media.coverSeed),
      providerBadge: resolveMediaCardProviderBadge(l10n, media.provider),
      cloudSyncBadge: resolveMediaCardSyncBadge(
        provider: media.provider,
        mediaUrl: media.mediaUrl,
        syncStatus: media.syncStatus,
      ),
      deleteTooltip: l10n.libraryDeleteMediaTooltip,
      onDelete: () => confirmAndDeleteMedia(context, ref, media),
      onTap: () {
        warmYoutubeSurfaceIfNeeded(ref, provider: media.provider);
        openPlayerRoute(context, media.id);
      },
      editLanguage: () => editMediaLanguage(context, ref, media),
    );
  }

  final String language;
  final String? durationLabel;
  final File? thumbnailFile;
  final String? thumbnailNetworkUrl;
  final Color accentColor;
  final String? providerBadge;
  final MediaCardSyncBadge? cloudSyncBadge;
  final String deleteTooltip;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback editLanguage;
}
