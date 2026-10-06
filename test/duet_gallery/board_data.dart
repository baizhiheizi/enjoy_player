import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/application/profile_practice_stats_provider.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/credits/application/credits_packages_provider.dart';
import 'package:enjoy_player/features/credits/application/credits_summary_provider.dart';
import 'package:enjoy_player/features/credits/application/credits_usage_provider.dart';
import 'package:enjoy_player/features/credits/application/todays_credits_provider.dart';
import 'package:enjoy_player/features/credits/domain/credits_package.dart';
import 'package:enjoy_player/features/credits/domain/credits_summary.dart';
import 'package:enjoy_player/features/credits/domain/credits_usage_log.dart';
import 'package:enjoy_player/features/credits/domain/credits_usage_page.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/features/discover/domain/feed_entry.dart';
import 'package:enjoy_player/features/library/application/library_media_provider.dart';
import 'package:enjoy_player/features/library/domain/learning_statistics.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/library/domain/practice_resume.dart';
import 'package:enjoy_player/features/subscription/application/subscription_plans_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_plan.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_stats.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'fixtures.dart';

/// The boards' sample account: Alex Chen on the Free plan.
class BoardAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(
      id: '10482231',
      email: 'alex@example.com',
      name: 'Alex Chen',
      subscriptionTier: SubscriptionTier.free,
      goal: 15,
    ),
  );
}

final _now = DateTime(2026, 10, 1, 21, 4);

Media _media(
  String id,
  String title, {
  required MediaKind kind,
  required String duration,
  required int daysAgo,
  String language = 'en-US',
  String provider = 'local',
}) {
  final parts = duration.split(':').map(int.parse).toList();
  final seconds = parts.fold(0, (sum, p) => sum * 60 + p);
  final at = _now.subtract(Duration(days: daysAgo));
  return Media(
    id: id,
    kind: kind,
    title: title,
    sourceUri: 'file:///$id',
    durationMs: seconds * 1000,
    language: language,
    contentHash: id,
    fileSize: 1,
    createdAt: at,
    updatedAt: at,
    provider: provider,
  );
}

/// `Library` board: video tab (LV) then audio tab (LA), newest first.
final boardVideos = [
  _media(
    'lv1',
    'How Cities Sound',
    kind: MediaKind.video,
    duration: '48:10',
    daysAgo: 1,
  ),
  _media(
    'lv2',
    'Why we forget what we read',
    kind: MediaKind.video,
    duration: '5:49',
    daysAgo: 2,
    provider: 'youtube',
  ),
  _media(
    'lv3',
    'Morning Market Tour',
    kind: MediaKind.video,
    duration: '6:42',
    daysAgo: 3,
  ),
  _media(
    'lv4',
    '朝の散歩',
    kind: MediaKind.video,
    duration: '3:20',
    daysAgo: 7,
    language: 'ja-JP',
    provider: 'youtube',
  ),
  _media(
    'lv5',
    'Ordering coffee without panicking',
    kind: MediaKind.video,
    duration: '4:12',
    daysAgo: 9,
    provider: 'youtube',
  ),
  _media(
    'lv6',
    'A slow walk through the old harbour',
    kind: MediaKind.video,
    duration: '18:32',
    daysAgo: 11,
    provider: 'youtube',
  ),
  _media(
    'lv7',
    'Harbour interview, part 2',
    kind: MediaKind.video,
    duration: '22:05',
    daysAgo: 13,
  ),
  _media(
    'lv8',
    'Why ice is slippery',
    kind: MediaKind.video,
    duration: '4:51',
    daysAgo: 16,
    provider: 'youtube',
  ),
  _media(
    'lv9',
    'Le marché du dimanche',
    kind: MediaKind.video,
    duration: '8:14',
    daysAgo: 19,
    language: 'fr-FR',
  ),
];

final boardAudios = [
  _media(
    'la1',
    'The Ferry at Six',
    kind: MediaKind.audio,
    duration: '0:56',
    daysAgo: 0,
    provider: 'craft',
  ),
  _media(
    'la2',
    'Slow Science, Episode 8',
    kind: MediaKind.audio,
    duration: '12:48',
    daysAgo: 5,
  ),
  _media(
    'la3',
    'Notes from a Night Train',
    kind: MediaKind.audio,
    duration: '9:30',
    daysAgo: 11,
  ),
  _media(
    'la4',
    'Ferry timetables and other small joys',
    kind: MediaKind.audio,
    duration: '7:02',
    daysAgo: 17,
  ),
  _media(
    'la5',
    'Pronouncing the schwa, slowly',
    kind: MediaKind.audio,
    duration: '1:24',
    daysAgo: 21,
    provider: 'craft',
  ),
  _media(
    'la6',
    '咖啡馆里的对话',
    kind: MediaKind.audio,
    duration: '5:16',
    daysAgo: 23,
    language: 'zh-CN',
  ),
  _media(
    'la7',
    'Bedtime story: the lighthouse cat',
    kind: MediaKind.audio,
    duration: '11:40',
    daysAgo: 29,
  ),
];

/// `Home` board: Recent media order.
List<Media> boardRecents() => [
  boardAudios[0],
  boardVideos[0],
  boardVideos[1],
  boardVideos[2],
  boardAudios[1],
  boardVideos[3],
  boardVideos[4],
  boardAudios[2],
];

final _channelDefs = [
  ('bc1', 'TED'),
  ('bc2', 'City Walks'),
  ('bc3', 'Kitchen Talk'),
  ('bc4', 'Slow Morning English'),
  ('bc5', 'Science Shorts'),
  ('bc6', '散歩日記'),
];

final boardChannels = [
  for (final (id, name) in _channelDefs)
    DiscoverChannel(
      channelId: id,
      displayName: name,
      source: YoutubeSubscriptionSource.recommended,
      subscribedAt: DateTime.utc(2026, 1, 1),
    ),
];

final boardFeed = [
  for (final (i, (title, channel, hoursAgo, duration)) in [
    ('What your morning routine says about attention', 0, 3, 724),
    ('A slow walk through the old harbour', 1, 5, 1112),
    ('The one pan dinner I make every week', 2, 26, 555),
    ('Small talk at the bus stop, slowly', 3, 28, 408),
    ('Why ice is slippery (it is not what you think)', 4, 50, 291),
    ('How to disagree without starting a fight', 0, 74, 867),
    ('雨の日の商店街', 5, 98, 662),
    ('Ten phrases for a hotel check-in', 3, 122, 450),
  ].indexed)
    FeedEntry(
      videoId: 'bv$i',
      channelId: _channelDefs[channel].$1,
      title: title,
      publishedAt: DateTime.now().subtract(Duration(hours: hoursAgo)),
      durationSeconds: duration,
    ),
];

const _ferryLines = [
  'Every morning at six, the ferry leaves before the city wakes up.',
  'I started taking it last spring, mostly by accident.',
  'My usual train was cancelled, and the ferry was the only way across.',
  'The first thing I noticed was how quiet everyone was.',
  'Nobody was on their phone; they were just watching the water.',
  "You don't take the ferry to save time; you take it to slow down.",
  'By the second week, I knew the faces of the regulars.',
  'The man with the thermos always offered me a cup.',
  'We never talked much, but we always nodded.',
  'Somewhere in the middle of the river, the sun comes up behind the bridge.',
  'For about a minute, the whole boat goes gold.',
  "Then the engines change their sound, and we're almost there.",
  "I could take the train again now, but I don't.",
  'Some mornings are worth the long way around.',
];

const boardVocabularyStats = VocabularyStats(
  total: 248,
  due: 24,
  newCount: 31,
  learningCount: 57,
  reviewingCount: 112,
  masteredCount: 48,
);

const _words = [
  (
    'regulars',
    'By the second week, I knew the faces of the regulars.',
    'learning',
    0,
    'en',
  ),
  ('slow down', 'You take it to slow down.', 'new', 0, 'en'),
  (
    'thermos',
    'The man with the thermos always offered me a cup.',
    'reviewing',
    -1,
    'en',
  ),
  (
    'by accident',
    'I started taking it last spring, mostly by accident.',
    'learning',
    1,
    'en',
  ),
  (
    'follow your nose',
    'You don’t read a night market; you follow your nose.',
    'mastered',
    21,
    'en',
  ),
  ('cancelled', 'My usual train was cancelled.', 'reviewing', 3, 'en'),
  (
    'slippery',
    'Why ice is slippery (it is not what you think).',
    'new',
    0,
    'en',
  ),
  ('散歩', '雨の日の散歩も悪くない。', 'learning', 1, 'ja'),
  (
    'nodded',
    'We never talked much, but we always nodded.',
    'mastered',
    34,
    'en',
  ),
];

/// Board-matching rows for the screens that read the database directly.
Future<void> seedBoardData(AppDatabase db) async {
  for (final (i, (word, context, status, dueDays, language))
      in _words.indexed) {
    final at = _now.subtract(Duration(days: i));
    await db
        .into(db.vocabularyItems)
        .insert(
          VocabularyItemsCompanion.insert(
            createdAt: at,
            updatedAt: at,
            id: 'w$i',
            word: word,
            language: language,
            targetLanguage: 'zh-CN',
            status: status,
            easeFactor: 2.5,
            interval: dueDays.abs(),
            nextReviewAt: DateTime.now().add(Duration(days: dueDays)),
            reviewsCount: i,
            contextsCount: 1,
          ),
        );
    await db
        .into(db.vocabularyContexts)
        .insert(
          VocabularyContextsCompanion.insert(
            createdAt: at,
            updatedAt: at,
            id: 'wc$i',
            vocabularyItemId: 'w$i',
            contextText: context,
            sourceType: 'Audio',
            sourceId: 'la1',
            locatorJson: '{"type":"media","start":0,"duration":3000}',
          ),
        );
  }
}

final _creditLog = [
  ('2026-10-01', '13:04', 'assessment', 60, 640, true),
  ('2026-10-01', '12:58', 'translation', 24, 580, true),
  ('2026-10-01', '12:57', 'llm', 120, 556, true),
  ('2026-10-01', '09:12', 'asr', 380, 436, true),
  ('2026-09-30', '22:40', 'tts', 90, 1000, true),
  ('2026-09-30', '22:31', 'assessment', 60, 910, true),
  ('2026-09-30', '22:30', 'assessment', 60, 850, true),
  ('2026-09-29', '23:55', 'asr', 1400, 1000, false),
  ('2026-09-29', '21:10', 'translation', 30, 970, true),
  ('2026-09-29', '21:09', 'llm', 140, 830, true),
];

final boardCreditsPage = CreditsUsagePage(
  hasMore: true,
  logs: [
    for (final (i, (date, time, service, required, after, allowed))
        in _creditLog.indexed)
      CreditsUsageLog.fromJson({
        'id': 'cl$i',
        'userId': '10482231',
        'date': date,
        'timestamp': DateTime.parse('${date}T$time:00Z').millisecondsSinceEpoch,
        'serviceType': service,
        'tier': 'free',
        'required': required,
        'usedBefore': after - required,
        'usedAfter': after,
        'allowed': allowed,
      }),
  ],
);

final boardCreditPackages = [
  for (final (i, (usd, credits)) in [
    (2, 200000),
    (5, 500000),
    (50, 5000000),
  ].indexed)
    CreditsPackage.fromJson({
      'id': 'pk$i',
      'amount': usd,
      'currency': 'USD',
      'credits': credits,
      'rate': {'usd': 1, 'credits': 100000},
    }),
];

final boardSyncQueue = SyncQueueSnapshot(
  retryablePending: 3,
  permanentlyFailed: 1,
  detailRows: [
    for (final (i, (type, id, action, retries)) in [
      ('recording', 'take-4', 'create', 0),
      ('vocabulary_item', 'w0', 'update', 0),
      ('video', 'lv7', 'update', 0),
      ('audio', 'la3', 'create', 5),
    ].indexed)
      SyncQueueRow(
        id: i,
        entityType: type,
        entityId: id,
        action: action,
        retryCount: retries,
        createdAt: _now.subtract(Duration(minutes: i * 2)),
      ),
  ],
);

/// Board data layered over [baseOverrides]; later overrides win.
const _boardStatistics = LearningStatistics(
  today: PeriodStats(recordingDurationMs: 720000, recordingCount: 12),
  week: PeriodStats(recordingDurationMs: 6480000, recordingCount: 88),
  month: PeriodStats(recordingDurationMs: 21720000, recordingCount: 301),
);

/// Board data for every app screen; one override per provider.
List<Override> boardOverrides(AppDatabase db, {AuthCtrl Function()? auth}) => [
  ...baseOverrides(
    db,
    recents: boardRecents(),
    subscription: false,
    auth: auth ?? BoardAuthCtrl.new,
    statistics: _boardStatistics,
    resume: PracticeResume(
      media: boardAudios[0],
      positionMs: 22600,
      echoActive: true,
      lastActiveAt: _now,
      sessionId: 's1',
    ),
  ),
  ...discoverOverrides(
    db,
    channels: boardChannels,
    feed: boardFeed,
    inLibrary: const {'bv1', 'bv4'},
  ),
  subscriptionStatusProvider.overrideWith(
    (ref) async => const SubscriptionStatus(
      subscriptionActive: true,
      subscriptionTier: SubscriptionTier.free,
    ),
  ),
  libraryFilteredListsProvider.overrideWith(
    (ref) => Stream.value((audio: boardAudios, video: boardVideos)),
  ),
  libraryMediaProvider.overrideWith(
    (ref) => Stream.value([...boardVideos, ...boardAudios]),
  ),
  profilePracticeStatsProvider.overrideWith((ref) async => _boardStatistics),
  transcriptLinesForMediaProvider('la1').overrideWith(
    (ref) => Stream.value([
      for (final (i, text) in _ferryLines.indexed)
        TranscriptLine(text: text, startMs: i * 4000, durationMs: 3900),
    ]),
  ),
  vocabularyStatsProvider.overrideWithValue(boardVocabularyStats),
  todaysCreditsUsedProvider.overrideWith((ref) async => 640),
  creditsSummaryProvider.overrideWith(
    (ref) async => const CreditsSummary(
      tier: 'free',
      dailyUsed: 640,
      dailyLimit: 1000,
      dailyRemaining: 360,
      permanentAvailable: 2400,
      resetAt: 0,
    ),
  ),
  creditsPackagesProvider.overrideWith((ref) async => boardCreditPackages),
  creditsUsagePageProvider.overrideWith((ref) async => boardCreditsPage),
  subscriptionPlansProvider.overrideWith(
    (ref) async => const [
      SubscriptionPlan(
        id: 'lite-m',
        tier: 'lite',
        interval: 'month',
        amount: 1.99,
      ),
      SubscriptionPlan(
        id: 'pro-m',
        tier: 'pro',
        interval: 'month',
        amount: 9.99,
      ),
    ],
  ),
  syncQueueSnapshotProvider.overrideWith((ref) => Stream.value(boardSyncQueue)),
  syncLastFullSyncAtProvider.overrideWith(
    (ref) async => _now.toUtc().toIso8601String(),
  ),
];
