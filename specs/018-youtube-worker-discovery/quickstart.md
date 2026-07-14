# Quickstart: YouTube Worker Discovery

**Feature**: 018-youtube-worker-discovery  
**Date**: 2026-07-14

Validation scenarios for verifying the feature end-to-end.

## Prerequisites

- Flutter SDK installed (`flutter --version`)
- Project dependencies: `flutter pub get`
- Worker RSSHub proxy running (for integration tests, stub with mock HTTP)

## Verification Commands

### 1. Code Generation

```bash
dart run build_runner build
```

Runs after any Drift/Riverpod annotation changes (schema migration, new providers).

### 2. Static Analysis

```bash
flutter analyze
```

Must pass with zero errors.

### 3. Unit Tests

```bash
flutter test test/features/discover/
```

Key test files:

| Test file | What it validates |
|-----------|-------------------|
| `youtube_url_parser_test.dart` | URL parsing for all 3 source types, invalid URLs, canonical ID extraction |
| `json_feed_parser_test.dart` | JSON Feed v1.1 parsing, video ID extraction from `items[].id`, field mapping |
| `worker_feed_client_test.dart` | HTTP GET to worker URLs, error status handling, handle-to-ID canonicalization |
| `discover_repository_test.dart` | Full integration: subscribe → fetch → cache, append-only upsert, cooldown, error handling |
| `discover_dedupe_test.dart` | Domain model equality, duplicate prevention |

### 4. Format Check

```bash
bash .github/scripts/check_dart_format.sh
```

### 5. Full CI Gates

```bash
bash .github/scripts/validate_ci_gates.sh
```

## Manual Verification Scenarios

### Scenario A: Subscribe to a channel

1. Launch app → navigate to Discover tab
2. Tap "Subscribe" → enter `https://youtube.com/@TED` → confirm
3. **Expected**: Subscription created, TED channel avatar + name visible, video entries appear in timeline within 5 seconds
4. **Verify**: "Add to library" works on any video; tapping plays the video

### Scenario B: Subscribe to a playlist

1. Enter `https://youtube.com/playlist?list=PL...` → confirm
2. **Expected**: Playlist subscription created with playlist icon indicator, videos in playlist order
3. **Verify**: Video order matches YouTube's playlist order

### Scenario C: Duplicate prevention

1. Subscribe via `https://youtube.com/@TED` → succeeds
2. Subscribe via `https://youtube.com/channel/UCAuUUnT6...` (TED's channel ID) → fails
3. **Expected**: "Already subscribed to this channel" message

### Scenario D: Refresh

1. Subscribe to 3+ channels
2. Wait for automatic refresh OR pull-to-refresh manually
3. **Expected**: New videos append to timeline, no duplicates, `last updated` timestamp advances

### Scenario E: Offline resilience

1. Subscribe to a channel and let feed load
2. Turn off network
3. Navigate to Discover → cached videos are visible
4. Try to subscribe to a new channel → error shown, no subscription created
5. Unsubscribe from an existing channel → works locally (no network needed)

### Scenario F: Error handling

1. Enter a URL to a deleted/private channel
2. **Expected**: "This source is no longer available" localized error
3. Enter a single video URL
4. **Expected**: "Unsupported URL" validation error (no worker call made)

### Scenario G: Multi-device sync (requires signed-in account)

1. Subscribe to a channel on device A
2. Sign into same account on device B, wait for cloud sync
3. **Expected**: Subscription appears on device B, feed loads from worker

## Expected Artifacts After Implementation

- `lib/features/discover/data/worker_feed_client.dart` — HTTP GET to RSSHub proxy
- `lib/features/discover/data/json_feed_parser.dart` — JSON Feed v1.1 parser
- `lib/features/discover/data/youtube_url_parser.dart` — URL validation + canonical ID extraction
- `lib/features/discover/data/discover_repository.dart` — rewritten refresh pipeline
- `lib/data/db/tables/youtube_channel_subscriptions.dart` — schema migration (new columns)
- `docs/features/discover.md` — updated documentation
- `docs/decisions/0049-youtube-worker-discovery.md` — new ADR
