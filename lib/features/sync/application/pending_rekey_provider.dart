/// Live count of media rows waiting for sign-in re-key (see [rekeyLocalRowsOnSignIn]).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/sync/application/rekey_local_rows.dart';

final pendingRekeyRowCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final controller = StreamController<int>();

  Future<void> emit() async {
    controller.add(await countPendingRekeyRows(db));
  }

  final subA =
      (db.select(db.audios)
            ..where((t) => t.syncStatus.equals('local-pending-rekey')))
          .watch()
          .listen((_) => emit());
  final subV =
      (db.select(db.videos)
            ..where((t) => t.syncStatus.equals('local-pending-rekey')))
          .watch()
          .listen((_) => emit());

  ref.onDispose(() {
    subA.cancel();
    subV.cancel();
    controller.close();
  });

  emit();
  return controller.stream;
});
