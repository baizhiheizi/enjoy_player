/// Remote cloud index tab bodies (paginated audio / video).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/core/utils/youtube_video_identity.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/signed_in_gate.dart';
import 'package:enjoy_player/features/cloud/application/cloud_providers.dart';
import 'package:enjoy_player/features/cloud/data/cloud_index_repository.dart';
import 'package:enjoy_player/features/cloud/domain/remote_library_item.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

part 'cloud_library_body_paged_list.dart';
part 'cloud_library_body_paged_media.dart';
part 'cloud_library_body_tiles.dart';

/// Paginated cloud catalog mounted inside the unified Library shell.
class CloudLibraryBody extends ConsumerStatefulWidget {
  const CloudLibraryBody({required this.tabController, super.key});

  final TabController tabController;

  @override
  ConsumerState<CloudLibraryBody> createState() => CloudLibraryBodyState();
}

class CloudLibraryBodyState extends ConsumerState<CloudLibraryBody> {
  final _audios = _CloudPagedList();
  final _videos = _CloudPagedList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadInitial());
    });
  }

  Future<void> _loadInitial() async {
    await Future.wait([
      _loadAudioPage(reset: true),
      _loadVideoPage(reset: true),
    ]);
  }

  Future<void> _loadAudioPage({required bool reset}) {
    return _loadPage(
      page: _audios,
      reset: reset,
      fetch: (cursor) => ref
          .read(cloudIndexRepositoryProvider)
          .fetchAudios(updatedAfter: cursor),
    );
  }

  Future<void> _loadVideoPage({required bool reset}) {
    return _loadPage(
      page: _videos,
      reset: reset,
      fetch: (cursor) => ref
          .read(cloudIndexRepositoryProvider)
          .fetchVideos(updatedAfter: cursor),
    );
  }

  Future<void> _loadPage({
    required _CloudPagedList page,
    required bool reset,
    required Future<List<RemoteLibraryItem>> Function(String? cursor) fetch,
  }) async {
    final auth = ref.read(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) return;
    await page.load(
      reset: reset,
      isMounted: () => mounted,
      setState: setState,
      fetch: fetch,
    );
  }

  /// Refreshes the video or audio tab matching [tabController.index].
  void refreshActiveTab() {
    if (widget.tabController.index == 0) {
      unawaited(_loadVideoPage(reset: true));
    } else {
      unawaited(_loadAudioPage(reset: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SignedInGate(
      surface: AuthRequiredSurface.cloud,
      loading: const SkeletonMediaList(),
      builder: (context, _) => TabBarView(
        controller: widget.tabController,
        children: [
          _CloudPagedMedia(
            page: _videos,
            onLoadMore: () => _loadVideoPage(reset: false),
            onRefresh: () => _loadVideoPage(reset: true),
            skeleton: const SkeletonMediaGrid(),
            emptyTitle: l10n.cloudEmptyVideoTitle,
            emptySubtitle: l10n.cloudEmptyVideoSubtitle,
            contentBuilder: _cloudVideoPageContent,
          ),
          _CloudPagedMedia(
            page: _audios,
            onLoadMore: () => _loadAudioPage(reset: false),
            onRefresh: () => _loadAudioPage(reset: true),
            skeleton: const SkeletonMediaList(),
            emptyTitle: l10n.cloudEmptyAudioTitle,
            emptySubtitle: l10n.cloudEmptyAudioSubtitle,
            contentBuilder: _cloudAudioPageContent,
          ),
        ],
      ),
    );
  }
}

Widget _cloudVideoPageContent(
  BuildContext context,
  ScrollController scroll,
  _CloudPagedList page,
) {
  final t = EnjoyThemeTokens.of(context);
  return LayoutBuilder(
    builder: (context, constraints) {
      final crossAxisExtent = constraints.maxWidth - t.space16 * 2;
      return GridView.builder(
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(t.space16),
        gridDelegate: mediaCardTileGridDelegateForMaxTileWidth(
          crossAxisExtent: crossAxisExtent,
        ),
        itemCount: page.items.length + (page.loading && !page.done ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= page.items.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(t.space24),
                child: Skeleton.circle(diameter: 32),
              ),
            );
          }
          return Align(
            alignment: Alignment.topCenter,
            child: _CloudVideoTile(item: page.items[index]),
          );
        },
      );
    },
  );
}

Widget _cloudAudioPageContent(
  BuildContext context,
  ScrollController scroll,
  _CloudPagedList page,
) {
  final t = EnjoyThemeTokens.of(context);
  return ListView.separated(
    controller: scroll,
    physics: const AlwaysScrollableScrollPhysics(),
    padding: EdgeInsets.fromLTRB(t.space16, t.space8, t.space16, t.space24),
    itemCount: page.items.length + 1,
    separatorBuilder: (_, _) => SizedBox(height: t.space8),
    itemBuilder: (context, index) {
      if (index == page.items.length) {
        if (page.loading) {
          return Padding(
            padding: EdgeInsets.all(t.space16),
            child: Center(child: Skeleton.circle(diameter: 28)),
          );
        }
        return const SizedBox.shrink();
      }
      return _CloudAudioRow(item: page.items[index]);
    },
  );
}
