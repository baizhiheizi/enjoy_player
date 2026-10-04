import 'package:drift/native.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/community/application/active_users_provider.dart';
import 'package:enjoy_player/features/community/domain/active_user.dart';
import 'package:enjoy_player/features/discover/application/discover_feed_join.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/data/discover_repository.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/features/discover/domain/feed_entry.dart';
import 'package:enjoy_player/features/library/application/continue_practice_provider.dart';
import 'package:enjoy_player/features/library/application/learning_statistics_provider.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/features/library/domain/learning_statistics.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/onboarding/application/onboarding_controller.dart';
import 'package:enjoy_player/features/onboarding/domain/tip_eligibility.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:enjoy_player/features/sync/application/sync_controller.dart';
import 'package:enjoy_player/features/update/application/update_controller.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

class SignedInAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(
      id: 'u1',
      email: 'an.lee@example.com',
      name: 'An Lee',
      subscriptionTier: SubscriptionTier.pro,
    ),
  );
}

class _FakePrefsCtrl extends AppPreferencesCtrl {
  @override
  Future<AppPreferencesState> build() async => AppPreferencesState.initial;
}

class _FakeVocabSession extends VocabularyReviewSession {
  @override
  ReviewSessionState build() => const ReviewSessionState(queue: []);
}

class _NoOnboarding extends OnboardingController {
  @override
  int build() => 0;
  @override
  Future<void> tryStartHomeEntries(TriggerContext ctx) async {}
  @override
  Future<void> tryStartEmptyTranscript(TriggerContext ctx) async {}
  @override
  Future<void> tryStartPracticeChain(TriggerContext ctx) async {}
}

class _NullPlayerController extends PlayerController {
  @override
  PlaybackSession? build() => null;
}

Media sampleMedia(
  String id,
  String title, {
  MediaKind kind = MediaKind.video,
  int durationMs = 349000,
  String provider = 'local',
  String language = 'en-US',
}) {
  final ts = DateTime.utc(2026, 9, 1);
  return Media(
    id: id,
    kind: kind,
    title: title,
    sourceUri: 'file:///$id',
    durationMs: durationMs,
    language: language,
    contentHash: id,
    fileSize: 1,
    createdAt: ts,
    updatedAt: ts,
    provider: provider,
  );
}

List<Media> sampleRecents() => [
  sampleMedia(
    'm1',
    'The missing ingredient in how we learn',
    provider: 'youtube',
  ),
  sampleMedia('m2', 'Is this the best way to learn?', provider: 'youtube'),
  sampleMedia(
    'm3',
    'Save It to Your Desktop! | Alan Resnick | TED',
    durationMs: 634000,
  ),
  sampleMedia(
    'm4',
    'All Ears English — Episode 1942',
    kind: MediaKind.audio,
    durationMs: 1284000,
  ),
  sampleMedia(
    'm5',
    'Le Petit Prince — chapitre 1',
    kind: MediaKind.audio,
    durationMs: 612000,
    language: 'fr-FR',
  ),
  sampleMedia('m6', 'How to speak so that people want to listen'),
];

List<Override> baseOverrides(
  AppDatabase db, {
  List<Media>? recents,
  bool subscription = true,
  PlayerController Function()? playerController,
}) => [
  appDatabaseProvider.overrideWithValue(db),
  deviceGlobalAppDatabaseProvider.overrideWithValue(db),
  authCtrlProvider.overrideWith(SignedInAuthCtrl.new),
  appPreferencesCtrlProvider.overrideWith(_FakePrefsCtrl.new),
  continuePracticeResumeProvider.overrideWith((ref) => null),
  onboardingControllerProvider.overrideWith(_NoOnboarding.new),
  syncCtrlProvider.overrideWithValue(0),
  discoverFeedRefreshSchedulerProvider.overrideWithValue(0),
  updateAvailableBadgeProvider.overrideWithValue(false),
  if (subscription)
    subscriptionStatusProvider.overrideWith(
      (ref) async => const SubscriptionStatus(
        subscriptionActive: true,
        subscriptionTier: SubscriptionTier.pro,
      ),
    ),
  vocabularyReviewSessionProvider.overrideWith(_FakeVocabSession.new),
  playerControllerProvider.overrideWith(
    playerController ?? _NullPlayerController.new,
  ),
  libraryHomeRecentsProvider.overrideWith(
    (ref) => Stream.value(recents ?? sampleRecents()),
  ),
  learningStatisticsProvider.overrideWith(
    (ref) async => const LearningStatistics(
      today: PeriodStats(recordingDurationMs: 142000, recordingCount: 12),
      week: PeriodStats(recordingDurationMs: 2400000, recordingCount: 88),
      month: PeriodStats(recordingDurationMs: 9400000, recordingCount: 301),
    ),
  ),
  activeUsersProvider.overrideWith(
    (ref) async => const ActiveUsersResponse(
      users: [
        ActiveUser(id: '1', name: 'Mia'),
        ActiveUser(id: '2', name: 'Kenji'),
        ActiveUser(id: '3', name: 'Lucía'),
      ],
      count: 3,
      recordingsCountToday: 1703,
      recordingsDurationToday: 9060000,
    ),
  ),
];

AppDatabase memoryDb() => AppDatabase(executor: NativeDatabase.memory());

Widget sceneApp({
  required GoRouter router,
  required List<Override> overrides,
  Brightness brightness = Brightness.dark,
  Locale locale = const Locale('en', 'US'),
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

class _FakeDiscoverRepository extends DiscoverRepository {
  _FakeDiscoverRepository(super.db, {required super.libraryRepository});

  @override
  Stream<List<DiscoverChannel>> watchSubscriptions() => const Stream.empty();

  @override
  Stream<List<FeedEntry>> watchTimeline() => const Stream.empty();

  @override
  Stream<List<FeedEntry>> watchChannelFeed(String channelId) =>
      const Stream.empty();
}

class _FakeRefreshState extends DiscoverRefreshState {
  @override
  bool build() => false;

  @override
  Future<DiscoverRefreshResult> refresh({bool force = false}) async =>
      const DiscoverRefreshResult(refreshedChannels: 0, failedChannelIds: []);
}

final sampleChannels = [
  for (final (id, name) in [
    ('c1', 'TED'),
    ('c2', 'TED-Ed'),
    ('c3', 'Kurzgesagt'),
    ('c4', 'BBC Learning English'),
    ('c5', 'Veritasium'),
  ])
    DiscoverChannel(
      channelId: id,
      displayName: name,
      source: YoutubeSubscriptionSource.recommended,
      subscribedAt: DateTime.utc(2024, 1, 1),
    ),
];

final sampleFeed = [
  for (final (i, title) in [
    'How to speak so that people want to listen',
    'The science of learning a new language — fast',
    'Why the brain loves stories',
    '6 Minute English: Is it OK to be lazy?',
    'The surprising habits of original thinkers',
    'What happens when you learn two languages at once',
    'Inside the mind of a master procrastinator',
    'The power of vulnerability',
  ].indexed)
    FeedEntry(
      videoId: 'v$i',
      channelId: 'c${(i % 5) + 1}',
      title: title,
      publishedAt: DateTime.now().subtract(Duration(days: i * 2, hours: 3)),
      durationSeconds: 300 + i * 97,
    ),
];

List<Override> discoverOverrides(AppDatabase db) => [
  discoverRepositoryProvider.overrideWithValue(
    _FakeDiscoverRepository(
      db,
      libraryRepository: MediaLibraryRepository(db, FileStorage()),
    ),
  ),
  discoverSubscriptionsProvider.overrideWith(
    (ref) => Stream.value(sampleChannels),
  ),
  discoverFeedItemsProvider.overrideWith(
    (ref) => Stream.value(
      projectDiscoverFeedItems(sampleFeed, const <String>{
        'v1',
      }, sampleChannels),
    ),
  ),
  discoverChannelFeedItemsProvider.overrideWith(
    (ref, channelId) => Stream.value(
      projectDiscoverFeedItems(sampleFeed, const <String>{}, sampleChannels),
    ),
  ),
  discoverRefreshStateProvider.overrideWith(_FakeRefreshState.new),
];

List<Override> libraryOverrides() {
  final all = sampleRecents();
  final audio = all.where((m) => m.kind == MediaKind.audio).toList();
  final video = all.where((m) => m.kind == MediaKind.video).toList();
  return [
    libraryFilteredListsProvider.overrideWith(
      (ref) => Stream.value((audio: audio, video: video)),
    ),
    libraryMediaProvider.overrideWith((ref) => Stream.value(all)),
  ];
}
