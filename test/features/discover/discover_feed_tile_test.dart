import 'package:drift/native.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/data/discover_repository.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/features/discover/domain/feed_entry.dart';
import 'package:enjoy_player/features/discover/presentation/discover_feed_tile.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _ThrowingLibraryRepository extends MediaLibraryRepository {
  _ThrowingLibraryRepository(super.db, super.storage);

  @override
  Future<String> importYoutubeVideo(
    String rawInput, {
    String? signedInUserId,
  }) async {
    throw Exception('import failed');
  }
}

void main() {
  testWidgets('DiscoverFeedTile shows In library for imported video', (
    tester,
  ) async {    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);

    const videoId = 'dQw4w9WgXcQ';
    final now = DateTime.now();
    await db.videoDao.insertRow(
      VideoRow(
        id: enjoyVideoId(provider: 'youtube', vid: videoId),
        vid: videoId,
        provider: 'youtube',
        title: 'Test',
        durationSeconds: 0,
        mediaUrl: 'https://www.youtube.com/watch?v=$videoId',
        language: 'und',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final entry = FeedEntry(
      videoId: videoId,
      channelId: 'UCAuUUnT6oDeKwE6v1NGQxug',
      title: 'Never Gonna Give You Up',
      publishedAt: now,
    );

    final repo = DiscoverRepository(db);
    repo.bindLibraryRepository(MediaLibraryRepository(db, FileStorage()));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          discoverRepositoryProvider.overrideWithValue(repo),
          discoverSubscriptionsProvider.overrideWith(
            (ref) => Stream.value(const <DiscoverChannel>[]),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: DiscoverFeedTile(entry: entry)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('In library'), findsNothing);
  });

  testWidgets('DiscoverFeedTile does not open player when import fails on play', (
    tester,
  ) async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);

    const videoId = 'dQw4w9WgXcQ';
    final now = DateTime.now();
    await db.videoDao.insertRow(
      VideoRow(
        id: enjoyVideoId(provider: 'youtube', vid: videoId),
        vid: videoId,
        provider: 'youtube',
        title: 'Test',
        durationSeconds: 0,
        mediaUrl: 'https://www.youtube.com/watch?v=$videoId',
        language: 'und',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final entry = FeedEntry(
      videoId: videoId,
      channelId: 'UCAuUUnT6oDeKwE6v1NGQxug',
      title: 'Never Gonna Give You Up',
      publishedAt: now,
    );

    final repo = DiscoverRepository(db);
    repo.bindLibraryRepository(_ThrowingLibraryRepository(db, FileStorage()));

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: DiscoverFeedTile(entry: entry),
          ),
        ),
        GoRoute(
          path: '/player/:mediaId',
          builder: (context, state) => const Scaffold(
            body: Text('player-open'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          discoverRepositoryProvider.overrideWithValue(repo),
          discoverSubscriptionsProvider.overrideWith(
            (ref) => Stream.value(const <DiscoverChannel>[]),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await db.delete(db.videos).go();

    await tester.tap(find.byType(DiscoverFeedTile));
    await tester.pumpAndSettle();

    expect(find.text('player-open'), findsNothing);
    expect(router.state.uri.path, '/');
  });
}