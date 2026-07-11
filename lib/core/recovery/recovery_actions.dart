/// Recovery actions for the corrupt / unopenable local database path.
/// Used by [RecoverySurface] in `app.dart` when
/// `appPreferencesCtrlProvider` fails to resolve.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/logging/log_file_sink.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

final _log = logNamed('RecoveryActions');

/// Runs [body] inside a `try`/`catch`. On any thrown error, logs
/// `_log.warning('$name failed', e, st)` and returns [defaultValue] — which
/// lets each caller keep its existing failure marker (`false` for bool
/// "did it succeed" APIs, `null` for `Future<String?>` paths, …).
Future<T> _guarded<T>(
  String name,
  T defaultValue,
  Future<T> Function() body,
) async {
  try {
    return await body();
  } catch (e, st) {
    _log.warning('$name failed', e, st);
    return defaultValue;
  }
}

/// Like [_guarded] but rethrows the error after logging. Used by callers
/// whose own caller logs the failure again with extra context (e.g.
/// [wipeLocalDatabaseFiles] is rethrown into [_resetLocalLibrary]'s
/// outer catch, which logs a different message).
Future<T> _guardedRethrow<T>(String name, Future<T> Function() body) async {
  try {
    return await body();
  } catch (e, st) {
    _log.warning('$name failed', e, st);
    rethrow;
  }
}

/// Best-effort copy of [error] to the system clipboard.
Future<bool> copyErrorToClipboard(Object error, StackTrace? stack) =>
    _guarded('copyErrorToClipboard', false, () async {
      final buf = StringBuffer()
        ..writeln('Enjoy Player — local data recovery')
        ..writeln('Captured: ${DateTime.now().toUtc().toIso8601String()}')
        ..writeln()
        ..writeln('Error:')
        ..writeln(error)
        ..writeln();
      if (stack != null) {
        buf
          ..writeln('Stack trace:')
          ..writeln(stack);
      }
      await Clipboard.setData(ClipboardData(text: buf.toString()));
      return true;
    });

/// Shared clipboard-copy success / failure notice used by both
/// [WidgetErrorSurface] and [RecoverySurface].
Future<void> copyErrorShowNotice(BuildContext context, bool ok) async {
  final l10n = AppLocalizations.of(context)!;
  if (ok) {
    AppNotice.success(context, l10n.recoveryCopiedToClipboard);
  } else {
    AppNotice.error(context, l10n.recoveryCopiedToClipboard);
  }
}

/// Opens the rotating log directory in the platform file explorer.
///
/// Returns `true` if the OS reported a successful launch. The caller
/// should show a user-visible failure notice when this returns `false`.
/// Mobile platforms (Android, iOS) have no generic file-explorer API
/// and always return `false`; the recovery surface still offers
/// "Copy error" as the mobile fallback.
Future<bool> openLogsFolder() => _guarded('openLogsFolder', false, () async {
  final dir = LogFileSink.instance?.directory;
  if (dir == null || !dir.existsSync()) {
    return _openSupportDirFallback();
  }
  return _revealInFileManager(dir.path);
});

Future<bool> _openSupportDirFallback() =>
    _guarded('openLogsFolder fallback', false, () async {
      final support = await getApplicationSupportDirectory();
      final dir = Directory(p.join(support.path, 'logs'));
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return _revealInFileManager(dir.path);
    });

bool _revealInFileManager(String path) {
  if (Platform.isWindows) {
    return _runAndCheck('explorer', <String>[path]);
  }
  if (Platform.isMacOS) {
    return _runAndCheck('open', <String>[path]);
  }
  if (Platform.isLinux) {
    return _runAndCheck('xdg-open', <String>[path]);
  }
  return false;
}

bool _runAndCheck(String exe, List<String> args) {
  try {
    final r = Process.runSync(exe, args);
    return r.exitCode == 0;
  } catch (e, st) {
    _log.fine('reveal $exe failed', e, st);
    return false;
  }
}

/// Directory where `drift_flutter`'s `driftDatabase()` places local SQLite
/// files by default. [AppDatabase] never passes `native:` overrides, so
/// every `.sqlite` file (device-global + per-user) lives directly here — *not*
/// under `getApplicationSupportDirectory()/databases/`, which is a
/// different directory that nothing in this app actually writes SQLite
/// files into.
Future<Directory> _localDatabaseDirectory() =>
    getApplicationDocumentsDirectory();

/// Backs up the on-disk Drift database file (best-effort) before a
/// destructive wipe. Returns the absolute path of the backup, or `null`
/// if the backup failed.
Future<String?> backupLocalDatabaseFile() =>
    _guarded('backupLocalDatabaseFile', null, () async {
      final dbDir = await _localDatabaseDirectory();
      if (!dbDir.existsSync()) {
        return null;
      }
      final stamp = DateTime.now()
          .toUtc()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final support = await getApplicationSupportDirectory();
      final backupDir = Directory(p.join(support.path, 'migrations'));
      if (!backupDir.existsSync()) {
        await backupDir.create(recursive: true);
      }
      final source = File(
        p.join(dbDir.path, '${AppDatabase.deviceGlobalDatabaseName}.sqlite'),
      );
      if (!source.existsSync()) {
        return null;
      }
      final dest = File(p.join(backupDir.path, 'enjoy_player_$stamp.sqlite'));
      await source.copy(dest.path);
      _log.info('backupLocalDatabaseFile: wrote ${dest.path}');
      return dest.path;
    });

/// Closes every per-user Drift database and deletes the on-disk SQLite
/// file. After this, the next read of any `appDatabaseProvider*` will
/// recreate the schema from scratch.
///
/// The auth controller is not reset; signed-in users keep their session
/// in secure storage and will rebuild their per-user database on the
/// next read.
Future<void> wipeLocalDatabaseFiles() =>
    _guardedRethrow('wipeLocalDatabaseFiles', () async {
      final dbDir = await _localDatabaseDirectory();
      if (!dbDir.existsSync()) {
        return;
      }
      final candidates = <String>{
        '${AppDatabase.deviceGlobalDatabaseName}.sqlite',
        '${AppDatabase.deviceGlobalDatabaseName}.sqlite-wal',
        '${AppDatabase.deviceGlobalDatabaseName}.sqlite-shm',
      };
      for (final entity in dbDir.listSync(followLinks: false)) {
        if (entity is! File) continue;
        final base = p.basename(entity.path);
        if (base.endsWith('.sqlite') ||
            base.endsWith('.sqlite-wal') ||
            base.endsWith('.sqlite-shm')) {
          candidates.add(base);
        }
      }
      for (final name in candidates) {
        final f = File(p.join(dbDir.path, name));
        if (f.existsSync()) {
          await f.delete();
          _log.info('wipeLocalDatabaseFiles: deleted $name');
        }
      }
    });

/// Resets the local library: backs up, then wipes. Used by the
/// destructive-migration flow wired in `app.dart`.
Future<RecoveryResetOutcome> resetLocalLibraryWithBackup() async {
  final backupPath = await backupLocalDatabaseFile();
  if (backupPath == null) {
    return RecoveryResetOutcome.backupFailed;
  }
  try {
    await wipeLocalDatabaseFiles();
    return RecoveryResetOutcome.success;
  } catch (e, st) {
    _log.warning('wipe failed after backup', e, st);
    return RecoveryResetOutcome.wipeFailed;
  }
}

enum RecoveryResetOutcome { success, backupFailed, wipeFailed }

/// Tells the caller whether [error] looks like an "unopenable / stale
/// local database" failure (corrupt file, schema-version gap, a migration
/// step that no longer matches the on-disk schema, …) so the caller can
/// route the user to the recovery surface.
bool isUnrecoverableDatabaseError(Object error) {
  final msg = error.toString().toLowerCase();
  return msg.contains('sqliteexception') ||
      msg.contains('database is corrupt') ||
      msg.contains('database disk image is malformed') ||
      msg.contains('file is not a database') ||
      msg.contains('unable to open') ||
      msg.contains('no such table') ||
      msg.contains('no such column') ||
      msg.contains('duplicate column name') ||
      msg.contains('unsupported schema');
}
