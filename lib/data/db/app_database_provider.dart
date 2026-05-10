/// Provides [AppDatabase] for the current auth session (per-user SQLite file).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';

import 'app_database.dart';

part 'app_database_provider.g.dart';

/// Drift file base name for the current auth session (guest vs per-user).
///
/// Used with [AuthCtrl] `.select` so [appDatabase] does not rebuild on every
/// profile refresh — otherwise a second [AppDatabase] can wrap the same
/// `driftDatabase` executor and trigger Drift's multiple-databases warning.
String _sessionDbBaseName(AsyncValue<AuthState> auth) {
  return auth.when(
    data: (state) {
      if (state is AuthSignedIn && state.profile.id.isNotEmpty) {
        final safe = _sanitizeUserIdForDbName(state.profile.id);
        return '${AppDatabase.guestDatabaseName}_$safe';
      }
      return AppDatabase.guestDatabaseName;
    },
    loading: () => AppDatabase.guestDatabaseName,
    error: (Object? error, StackTrace stackTrace) =>
        AppDatabase.guestDatabaseName,
  );
}

/// Device-global Drift DB (`enjoy_player`) — API base URL and other non-user data.
///
/// Kept separate from [appDatabaseProvider] so [ApiBaseUrl] does not depend on
/// auth-scoped DB (avoids Riverpod cycles with [authCtrlProvider]).
@Riverpod(keepAlive: true)
AppDatabase guestAppDatabase(Ref ref) {
  final db = AppDatabase(name: AppDatabase.guestDatabaseName);
  ref.onDispose(db.close);
  return db;
}

/// Per-session library + prefs: guest file when signed out; `enjoy_player_<userId>` when signed in.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final sessionName = ref.watch(
    authCtrlProvider.select(_sessionDbBaseName),
  );

  if (sessionName == AppDatabase.guestDatabaseName) {
    return ref.watch(guestAppDatabaseProvider);
  }

  final db = AppDatabase(name: sessionName);
  ref.onDispose(db.close);
  return db;
}

String _sanitizeUserIdForDbName(String id) =>
    id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
