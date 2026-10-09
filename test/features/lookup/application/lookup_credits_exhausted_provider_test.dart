import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('report, clear, and clearAll track section credits state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final keepAlive = container.listen(
      lookupCreditsExhaustedProvider,
      (_, _) {},
    );
    addTearDown(keepAlive.close);
    final notifier = container.read(lookupCreditsExhaustedProvider.notifier);

    expect(container.read(lookupCreditsExhaustedProvider), isEmpty);

    notifier.report(LookupSectionId.translation, 'exhausted');
    notifier.report(LookupSectionId.dictionary, 'exhausted');
    expect(
      container.read(lookupCreditsExhaustedProvider).keys,
      unorderedEquals([
        LookupSectionId.translation,
        LookupSectionId.dictionary,
      ]),
    );

    notifier.report(LookupSectionId.translation, 'still exhausted');
    expect(
      container.read(
        lookupCreditsExhaustedProvider,
      )[LookupSectionId.translation],
      'still exhausted',
    );

    notifier.clear(LookupSectionId.translation);
    expect(
      container
          .read(lookupCreditsExhaustedProvider)
          .containsKey(LookupSectionId.translation),
      isFalse,
    );

    notifier.clearAll();
    expect(container.read(lookupCreditsExhaustedProvider), isEmpty);
  });
}
