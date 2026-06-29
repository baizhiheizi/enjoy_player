/// Tests for the [findSliverIndexByPrefixedId] helper.
///
/// The helper backs `SliverChildBuilderDelegate.findChildIndexCallback`
/// on the home recents grid and the discover / channel feed grids. Its
/// contract: given a `ValueKey<String>('$prefix${item.id}')` produced
/// by the itemBuilder, return the item's index in the current data
/// list (or null for any key shape that doesn't belong to this
/// delegate). The sliver framework relies on the callback to map
/// existing child Keys to indices when the data list reorders.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/utils/sliver_key_index.dart';

void main() {
  group('findSliverIndexByPrefixedId', () {
    final items = <_Item>[const _Item('a'), const _Item('b'), const _Item('c')];

    test('returns the index when a matching key is given', () {
      final found = findSliverIndexByPrefixedId<_Item>(
        items: items,
        key: const ValueKey<String>('home-media-b'),
        prefix: 'home-media-',
        idOf: (i) => i.id,
      );
      expect(found, 1);
    });

    test(
      'returns the first index on duplicate ids (callers must use unique ids)',
      () {
        final dup = <_Item>[const _Item('a'), const _Item('a')];
        final found = findSliverIndexByPrefixedId<_Item>(
          items: dup,
          key: const ValueKey<String>('p-a'),
          prefix: 'p-',
          idOf: (i) => i.id,
        );
        expect(found, 0);
      },
    );

    test('returns null when no item matches the key id', () {
      final found = findSliverIndexByPrefixedId<_Item>(
        items: items,
        key: const ValueKey<String>('home-media-missing'),
        prefix: 'home-media-',
        idOf: (i) => i.id,
      );
      expect(found, isNull);
    });

    test('returns null when the key has the wrong prefix', () {
      final found = findSliverIndexByPrefixedId<_Item>(
        items: items,
        key: const ValueKey<String>('other-b'),
        prefix: 'home-media-',
        idOf: (i) => i.id,
      );
      expect(found, isNull);
    });

    test(
      'returns null when the key has the prefix as a substring but not a prefix',
      () {
        // "home-media-" should not match "xhome-media-b".
        final found = findSliverIndexByPrefixedId<_Item>(
          items: items,
          key: const ValueKey<String>('xhome-media-b'),
          prefix: 'home-media-',
          idOf: (i) => i.id,
        );
        expect(found, isNull);
      },
    );

    test('returns null for non-ValueKey keys', () {
      final found = findSliverIndexByPrefixedId<_Item>(
        items: items,
        key: const ObjectKey('a'),
        prefix: 'home-media-',
        idOf: (i) => i.id,
      );
      expect(found, isNull);
    });

    test('returns null for ValueKey<int> (wrong value type)', () {
      final found = findSliverIndexByPrefixedId<_Item>(
        items: items,
        key: const ValueKey<int>(42),
        prefix: 'home-media-',
        idOf: (i) => i.id,
      );
      expect(found, isNull);
    });

    test('returns null on an empty list', () {
      final found = findSliverIndexByPrefixedId<_Item>(
        items: const <_Item>[],
        key: const ValueKey<String>('home-media-a'),
        prefix: 'home-media-',
        idOf: (i) => i.id,
      );
      expect(found, isNull);
    });

    test('handles ids that contain the prefix substring', () {
      // `home-media-` is a prefix; an item id of `home-media-x` should
      // still match because we slice off exactly the prefix.
      final tricky = <_Item>[const _Item('home-media-x')];
      final found = findSliverIndexByPrefixedId<_Item>(
        items: tricky,
        key: const ValueKey<String>('home-media-home-media-x'),
        prefix: 'home-media-',
        idOf: (i) => i.id,
      );
      expect(found, 0);
    });

    test('handles ids that are empty strings', () {
      final weird = <_Item>[const _Item(''), const _Item('b')];
      final found = findSliverIndexByPrefixedId<_Item>(
        items: weird,
        key: const ValueKey<String>('p-'),
        prefix: 'p-',
        idOf: (i) => i.id,
      );
      expect(found, 0);
    });
  });
}

class _Item {
  const _Item(this.id);
  final String id;
}
