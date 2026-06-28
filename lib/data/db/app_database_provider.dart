/// Provides [AppDatabase] for the current auth session (per-user SQLite file).
library;

import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';

import 'app_database.dart';

part 'app_database_provider.g.dart';

/// Maximum number of per-user [AppDatabase] instances kept open simultaneously.
///
/// Only the guest DB and the most recently used per-user DB need to be live at
/// the same time — signing in as a new user closes the previous one. Two is
/// enough because the guest DB is owned by [guestAppDatabaseProvider] (a
/// separate keep-alive provider with its own onDispose), and only one
/// per-user DB is "current" at a time. Anything older is evicted.
const int _kMaxUserSessionDatabases = 2;

/// One [AppDatabase] per signed-in session name — avoids constructing a new
/// [AppDatabase] on every [appDatabase] rebuild (Drift multiple-instances warning).
///
/// Bounded to [_kMaxUserSessionDatabases] entries; the oldest is evicted (and
/// closed) before inserting a new one.
final LinkedHashMap<String, AppDatabase> _userSessionDatabases =
    LinkedHashMap<String, AppDatabase>();

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
  final sessionName = ref.watch(authCtrlProvider.select(_sessionDbBaseName));

  if (sessionName == AppDatabase.guestDatabaseName) {
    return ref.watch(guestAppDatabaseProvider);
  }

  // Re-inserting an existing key moves it to the end (most recently used) so
  // the eviction loop below drops the truly idle DBs first.
  final existing = _userSessionDatabases.remove(sessionName);
  if (existing != null) {
    _userSessionDatabases[sessionName] = existing;
    ref.onDispose(() {
      _userSessionDatabases.remove(sessionName)?.close();
    });
    return existing;
  }

  while (_userSessionDatabases.length >= _kMaxUserSessionDatabases) {
    final oldestKey = _userSessionDatabases.keys.first;
    final oldest = _userSessionDatabases.remove(oldestKey);
    unawaited(oldest?.close());
  }

  final db = AppDatabase(name: sessionName);
  _userSessionDatabases[sessionName] = db;
  ref.onDispose(() {
    _userSessionDatabases.remove(sessionName)?.close();
  });
  return db;
}

String _sanitizeUserIdForDbName(String id) =>
    id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
