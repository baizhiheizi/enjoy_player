<hash>size:4795</hash>

# `lib/data/api/services/ai/youtube_feed_api.dart`

- `YoutubeFeedClient` performs authenticated HTTP GETs for Worker RSSHub JSON feeds.
- Maps HTTP/network/parse failures to typed `WorkerFeedException` values.
- Parses JSON Feed and extracts canonical channel IDs from `home_page_url`.
