import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_identity.dart';
import 'package:enjoy_player/features/player/application/player_engine_rev.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_player_engine.dart';

void main() {
  late ProviderContainer container;
  late List<FakePlayerEngine> fakes;
  late PlayerEngine? testDouble;
  late int allocations;
  late PlayerEngineIdentity identity;

  FakePlayerEngine makeFake() {
    final fake = FakePlayerEngine();
    fakes.add(fake);
    return fake;
  }

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    fakes = [];
    addTearDown(() async {
      for (final fake in fakes) {
        await fake.dispose();
      }
    });
    testDouble = null;
    allocations = 0;
    // The module owns the slot now — only the things it cannot own are
    // injected: the live test-double provider read, the lazy-default
    // allocator, the disposed check, and the rev-bump action.
    identity = PlayerEngineIdentity(
      bumpRev: () => container.read(playerEngineRevProvider.notifier).bump(),
      testDouble: () => testDouble,
      allocateDefault: () {
        allocations++;
        return makeFake();
      },
      isDisposed: () => false,
    );
  });

  test('precedence: test double wins over owned; owned is the fallback', () {
    final doubleEngine = makeFake();
    final ownedEngine = makeFake();
    testDouble = doubleEngine;
    identity.setOwned(ownedEngine);

    expect(identical(identity.resolve(), doubleEngine), isTrue);
    expect(identical(identity.resolveOrNull(), doubleEngine), isTrue);

    testDouble = null;
    expect(identical(identity.resolve(), ownedEngine), isTrue);
    expect(identical(identity.resolveOrNull(), ownedEngine), isTrue);
    expect(allocations, 0, reason: 'owned present — no lazy default');
  });

  test('resolveOrNull stops before the allocating tail (widget builds)', () {
    expect(identity.resolveOrNull(), isNull);
    expect(
      identity.owned,
      isNull,
      reason: 'must not allocate during a widget build',
    );
    expect(allocations, 0);
    expect(container.read(playerEngineRevProvider), 0);
  });

  test('resolve allocates the lazy default once and bumps deferred', () async {
    final first = identity.resolve();
    expect(identical(identity.owned, first), isTrue);
    expect(allocations, 1);
    // Microtask discipline (the old _ensureDefaultMediaKitEngine hack,
    // relocated into the module): never notify synchronously from a path
    // that can run inside another provider's build.
    expect(container.read(playerEngineRevProvider), 0);
    await pumpEventQueue();
    expect(container.read(playerEngineRevProvider), 1);

    final second = identity.resolve();
    expect(identical(second, first), isTrue);
    expect(allocations, 1);
    await pumpEventQueue();
    expect(
      container.read(playerEngineRevProvider),
      1,
      reason: 'no identity change — no bump',
    );
  });

  test('the lazy tail never allocates over a test double', () {
    final doubleEngine = makeFake();
    testDouble = doubleEngine;

    expect(identical(identity.resolve(), doubleEngine), isTrue);
    expect(allocations, 0);
    expect(identity.owned, isNull);
  });

  test('setOwned bumps synchronously only when the slot actually changes', () {
    final first = makeFake();
    final second = makeFake();

    identity.setOwned(first);
    expect(container.read(playerEngineRevProvider), 1);

    identity.setOwned(first); // identical instance — not a change
    expect(container.read(playerEngineRevProvider), 1);

    identity.setOwned(second);
    expect(container.read(playerEngineRevProvider), 2);
  });

  test('the raw owned seam writes the slot without bumping the rev', () {
    final seam = makeFake();

    identity.owned = seam;

    expect(identical(identity.owned, seam), isTrue);
    expect(
      container.read(playerEngineRevProvider),
      0,
      reason: 'mirrors the controller.ownedEngine = … test seam',
    );
  });

  test('the deferred bump never fires after the owner is disposed', () async {
    final disposedIdentity = PlayerEngineIdentity(
      bumpRev: () => container.read(playerEngineRevProvider.notifier).bump(),
      testDouble: () => testDouble,
      allocateDefault: makeFake,
      isDisposed: () => true,
    );

    disposedIdentity.resolve();
    await pumpEventQueue();
    expect(
      container.read(playerEngineRevProvider),
      0,
      reason: 'touching Ref after dispose would assert',
    );
  });
}
