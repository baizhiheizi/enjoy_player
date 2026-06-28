/// Riverpod providers for Discover feeds.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/discover/data/discover_repository.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/features/discover/domain/feed_entry.dart';
import 'package:enjoy_player/features/discover/domain/recommended_channel.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';

part 'discover_providers.g.dart';

final _log = logNamed('discover');

@Riverpod(keepAlive: true)
DiscoverRepository discoverRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = DiscoverRepository(db);
  repo.bindLibraryRepository(ref.watch(mediaLibraryRepositoryProvider));
  return repo;
}

@Riverpod(keepAlive: true)
Future<List<RecommendedChannel>> recommendedChannels(Ref ref) {
  return ref.watch(discoverRepositoryProvider).loadRecommendedChannels();
}

@Riverpod(keepAlive: true)
Stream<List<DiscoverChannel>> discoverSubscriptions(Ref ref) {
  return ref.watch(discoverRepositoryProvider).watchSubscriptions();
}

@Riverpod(keepAlive: true)
Stream<List<FeedEntry>> discoverTimeline(Ref ref) {
  return ref.watch(discoverRepositoryProvider).watchTimeline();
}

@Riverpod(keepAlive: true)
Stream<List<FeedEntry>> discoverChannelFeed(Ref ref, String channelId) {
  return ref.watch(discoverRepositoryProvider).watchChannelFeed(channelId);
}

/// Active Discover feed filter: `null` = all subscribed channels, else one channel.
@Riverpod(keepAlive: true)
class DiscoverSelectedChannel extends _$DiscoverSelectedChannel {
  @override
  String? build() {
    ref.listen(discoverSubscriptionsProvider, (previous, next) {
      final selected = state;
      if (selected == null) return;
      final subs = next.valueOrNull;
      if (subs == null) return;
      final stillSubscribed = subs.any((s) => s.channelId == selected);
      if (!stillSubscribed) {
        state = null;
      }
    });
    return null;
  }

  void select(String? channelId) {
    state = channelId;
  }
}

/// Channel profile photo for recommended row: subscription avatar, bundled
/// URL, then a one-time fetch from the public channel page.
@Riverpod(keepAlive: true)
Future<String?> recommendedChannelAvatar(Ref ref, String channelId) async {
  ref.watch(discoverSubscriptionsProvider);

  final subs = ref.watch(discoverSubscriptionsProvider).valueOrNull ?? const [];
  for (final sub in subs) {
    if (sub.channelId == channelId &&
        isRemoteThumbnailUrl(sub.thumbnailUrl) &&
        !DiscoverRepository.looksLikeVideoThumbnail(sub.thumbnailUrl)) {
      return sub.thumbnailUrl;
    }
  }

  final recommended = await ref.watch(recommendedChannelsProvider.future);
  for (final channel in recommended) {
    if (channel.channelId == channelId &&
        isRemoteThumbnailUrl(channel.thumbnailUrl)) {
      return channel.thumbnailUrl;
    }
  }

  return ref.read(discoverRepositoryProvider).fetchChannelAvatarUrl(channelId);
}

@Riverpod(keepAlive: true)
class DiscoverRefreshState extends _$DiscoverRefreshState {
  @override
  bool build() => false;

  Future<DiscoverRefreshResult> refresh({bool force = false}) async {
    state = true;
    try {
      return await ref
          .read(discoverRepositoryProvider)
          .refreshFeeds(force: force);
    } finally {
      state = false;
    }
  }
}

@Riverpod(keepAlive: true)
class DiscoverFeedRefreshScheduler extends _$DiscoverFeedRefreshScheduler {
  Timer? _periodic;
  var _launchScheduled = false;

  @override
  int build() {
    ref.onDispose(() {
      _periodic?.cancel();
      _periodic = null;
      _launchScheduled = false;
    });

    // Only arm the timer when there is at least one subscription;
    // otherwise the periodic refresh would be a no-op (the repo
    // returns immediately when the subscription list is empty) but
    // would still wake the app every 8 hours.
    final subList = ref.watch(discoverSubscriptionsProvider).valueOrNull;
    if (subList != null && subList.isNotEmpty) {
      _periodic ??= Timer.periodic(const Duration(hours: 8), (_) {
        if (_isAppResumed) {
          unawaited(_launchRefresh());
        } else {
          _log.fine(
            'discover feed refresh tick skipped: app is not in foreground',
          );
        }
      });

      if (!_launchScheduled) {
        _launchScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isAppResumed) {
            unawaited(_launchRefresh());
          }
        });
      }
    } else {
      _periodic?.cancel();
      _periodic = null;
      // Allow the post-frame initial refresh to run again after the user
      // re-subscribes following an empty subscription list.
      _launchScheduled = false;
    }

    return 0;
  }

  /// Whether the app is currently in the foreground. Reads
  /// [WidgetsBinding.lifecycleState] (the global binding) which is
  /// kept current by the host platform's lifecycle callback bridge.
  /// `null` is treated as "resumed" so we do not silently skip the
  /// first refresh on platforms that do not publish a state.
  bool get _isAppResumed {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  Future<void> _launchRefresh() async {
    try {
      await ref.read(discoverRefreshStateProvider.notifier).refresh();
    } catch (e, st) {
      _log.warning('discover feed refresh failed', e, st);
    }
  }
}

Future<String> addDiscoverFeedEntryToLibrary(
  WidgetRef ref,
  FeedEntry entry,
) async {
  final auth = ref.read(authCtrlProvider).valueOrNull;
  final userId = auth is AuthSignedIn ? auth.profile.id : null;
  return ref
      .read(discoverRepositoryProvider)
      .addFeedEntryToLibrary(entry, signedInUserId: userId);
}

Future<bool> discoverVideoInLibrary(WidgetRef ref, String videoId) {
  return ref.read(discoverRepositoryProvider).isVideoInLibrary(videoId);
}
