import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repository whose `resolveOnOpen` blocks on a per-call gate, so a test can
/// tell a joined caller apart from one that started a second resolve.
class _GatedRepo extends TranscriptRepository {
  _GatedRepo(super.db);

  final List<Completer<void>> gates = [];

  int get callCount => gates.length;

  @override
  Future<TranscriptResolveResult> resolveOnOpen(
    String mediaId, {
    bool forceCloud = false,
    bool fetchCloud = true,
    String? nativeLanguage,
    String? learningLanguage,
  }) async {
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
    return const TranscriptResolveResult(hasTracks: false);
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late _GatedRepo repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = _GatedRepo(db);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        transcriptRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('a concurrent resolve joins the in-flight resolve', () async {
    final ctrl = container.read(
      transcriptFetchCtrlProvider('media-1').notifier,
    );

    final first = ctrl.resolveOnOpen(signedIn: false);
    await pumpEventQueue();
    expect(repo.callCount, 1);

    final second = ctrl.resolveOnOpen(signedIn: false);
    await pumpEventQueue();
    expect(repo.callCount, 1);

    repo.gates.first.complete();
    await first;
    await second;
    expect(repo.callCount, 1);
  });

  test(
    'a resolve started after the in-flight one settles runs again',
    () async {
      final ctrl = container.read(
        transcriptFetchCtrlProvider('media-1').notifier,
      );

      final first = ctrl.resolveOnOpen(signedIn: false);
      await pumpEventQueue();
      repo.gates.first.complete();
      await first;

      final second = ctrl.resolveOnOpen(signedIn: false);
      await pumpEventQueue();
      expect(repo.callCount, 2);

      repo.gates.last.complete();
      await second;
    },
  );

  test('a cloud refresh joins an in-flight resolve', () async {
    final ctrl = container.read(
      transcriptFetchCtrlProvider('media-1').notifier,
    );

    final first = ctrl.resolveOnOpen(signedIn: false);
    await pumpEventQueue();
    expect(repo.callCount, 1);

    final refresh = ctrl.refreshFromCloud(signedIn: false);
    await pumpEventQueue();
    expect(repo.callCount, 1);

    repo.gates.first.complete();
    await first;
    await refresh;
    expect(repo.callCount, 1);
  });
}
