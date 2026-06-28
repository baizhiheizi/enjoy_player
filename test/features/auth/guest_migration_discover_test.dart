import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/application/guest_migration_providers.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuthSignedInCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(id: 'test-user', email: 't@example.com', name: 'Test'),
  );
}

void main() {
  test(
    'guest migration copies discover subscriptions and feed cache',
    () async {
      final guest = AppDatabase(executor: NativeDatabase.memory());
      final user = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(guest.close);
      addTearDown(user.close);

      const channelId = 'UCAuUUnT6oDeKwE6v1NGQxug';
      final now = DateTime.utc(2024, 3, 1);
      await guest.youtubeChannelSubscriptionDao.upsert(
        YoutubeChannelSubscriptionRow(
          channelId: channelId,
          displayName: 'TED',
          source: YoutubeSubscriptionSource.recommended,
          subscribedAt: now,
          lastFetchedAt: now,
        ),
      );
      await guest.youtubeFeedEntryDao.upsertEntry(
        YoutubeFeedEntryRow(
          videoId: 'videoA123456',
          channelId: channelId,
          title: 'Talk',
          publishedAt: now,
          fetchedAt: now,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          guestAppDatabaseProvider.overrideWithValue(guest),
          appDatabaseProvider.overrideWithValue(user),
          authCtrlProvider.overrideWith(_AuthSignedInCtrl.new),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await container.read(guestMigrationCtrlProvider.notifier).migrate();
      expect(container.read(guestMigrationCtrlProvider).hasError, isFalse);

      final subs = await user.youtubeChannelSubscriptionDao.listAll();
      final feeds = await user.select(user.youtubeFeedEntries).get();
      expect(subs, hasLength(1));
      expect(subs.single.channelId, channelId);
      expect(feeds, hasLength(1));
      expect(feeds.single.videoId, 'videoA123456');
      expect(await guest.select(guest.youtubeFeedEntries).get(), isEmpty);
    },
  );
}
