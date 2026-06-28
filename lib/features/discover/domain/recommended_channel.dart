/// Bundled recommended channel from assets catalog.
library;

class RecommendedChannel {
  factory RecommendedChannel.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    return RecommendedChannel(
      channelId: json['channelId'] as String,
      name: json['name'] as String,
      handle: json['handle'] as String?,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      language: json['language'] as String? ?? 'en',
      tags: tagsRaw is List
          ? tagsRaw.map((e) => e.toString()).toList(growable: false)
          : const [],
    );
  }
  const RecommendedChannel({
    required this.channelId,
    required this.name,
    this.handle,
    this.description,
    this.thumbnailUrl,
    required this.language,
    this.tags = const [],
  });

  final String channelId;
  final String name;
  final String? handle;
  final String? description;
  final String? thumbnailUrl;
  final String language;
  final List<String> tags;
}
