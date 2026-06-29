import 'package:enjoy_player/features/discover/data/catalog_channel_ids.dart';
import 'package:enjoy_player/features/discover/data/recommended_channels_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('recommended_channels.json', () {
    final channelIdPattern = RegExp(r'^UC[\w-]{22}$');

    test(
      'lists verified public channels with unique ids and handles',
      () async {
        final channels = await RecommendedChannelsLoader().load();
        expect(channels, hasLength(1));

        final ids = <String>{};
        final handles = <String>{};
        for (final channel in channels) {
          expect(channel.channelId, matches(channelIdPattern));
          expect(ids.add(channel.channelId), isTrue, reason: channel.channelId);
          expect(channel.handle, isNotNull);
          expect(channel.handle, startsWith('@'));
          expect(handles.add(channel.handle!), isTrue, reason: channel.handle);
          expect(
            canonicalCatalogChannelId(channel.channelId),
            channel.channelId,
          );
        }

        expect(channels.map((c) => c.channelId).toList(), [
          'UCAuUUnT6oDeKwE6v1NGQxug',
        ]);
        expect(channels.first.handle, '@TED');
        expect(channels.first.name, 'TED');
      },
    );
  });
}
