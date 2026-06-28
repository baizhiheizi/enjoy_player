import 'dart:io';

import 'package:enjoy_player/core/logging/log_file_sink.dart';
import 'package:enjoy_player/core/recovery/recovery_actions.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _MockPathProvider extends PathProviderPlatform {
  _MockPathProvider(this.tmpRoot);
  final Directory tmpRoot;

  @override
  Future<String?> getApplicationSupportPath() async => tmpRoot.path;

  @override
  Future<String?> getTemporaryPath() async => tmpRoot.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('recovery_actions', () {
    late Directory tmpRoot;
    late Directory dbDir;
    late Directory logsDir;
    late List<MethodCall> clipboardCalls;

    setUp(() async {
      tmpRoot = await Directory.systemTemp.createTemp('recovery_actions_');
      dbDir = Directory(p.join(tmpRoot.path, 'databases'));
      logsDir = Directory(p.join(tmpRoot.path, 'logs'));
      await dbDir.create(recursive: true);
      await logsDir.create(recursive: true);
      PathProviderPlatform.instance = _MockPathProvider(tmpRoot);
      clipboardCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        clipboardCalls.add(call);
        if (call.method == 'Clipboard.setData') {
          return null;
        }
        if (call.method == 'Clipboard.getData') {
          return const <String, dynamic>{'text': ''};
        }
        return null;
      });
    });

    tearDown(() async {
      if (tmpRoot.existsSync()) {
        tmpRoot.deleteSync(recursive: true);
      }
    });

    test('copyErrorToClipboard writes the error to the clipboard', () async {
      final ok = await copyErrorToClipboard(
        Exception('boom'),
        StackTrace.fromString('#0 main'),
      );
      expect(ok, isTrue);
      final setCalls = clipboardCalls.where((c) => c.method == 'Clipboard.setData');
      expect(setCalls, hasLength(1));
      final args = (setCalls.single.arguments as Map)['text'] as String;
      expect(args, contains('boom'));
      expect(args, contains('Stack trace'));
    });

    test('copyErrorToClipboard returns false on a platform failure',
        () async {
      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        throw PlatformException(code: 'fail');
      });
      final ok = await copyErrorToClipboard(Exception('boom'), null);
      expect(ok, isFalse);
    });

    test('backupLocalDatabaseFile copies the guest DB and returns its path',
        () async {
      final dbFile = File(
        p.join(dbDir.path, '${AppDatabase.guestDatabaseName}.sqlite'),
      );
      await dbFile.writeAsString('sqlite-blob');
      final backup = await backupLocalDatabaseFile();
      expect(backup, isNotNull);
      expect(File(backup!).existsSync(), isTrue);
      expect(
        p.basename(backup),
        startsWith('enjoy_player_'),
      );
      expect(
        p.basename(backup),
        endsWith('.sqlite'),
      );
    });

    test('backupLocalDatabaseFile returns null when the DB is missing',
        () async {
      final backup = await backupLocalDatabaseFile();
      expect(backup, isNull);
    });

    test('wipeLocalDatabaseFiles removes the guest + wal + shm files',
        () async {
      for (final ext in <String>['', '-wal', '-shm']) {
        await File(
          p.join(
            dbDir.path,
            '${AppDatabase.guestDatabaseName}.sqlite$ext',
          ),
        ).writeAsString('x');
      }
      // Add an unrelated file to make sure we don't over-delete.
      await File(p.join(dbDir.path, 'keepme.txt')).writeAsString('keep');

      await wipeLocalDatabaseFiles();

      for (final ext in <String>['', '-wal', '-shm']) {
        expect(
          File(
            p.join(
              dbDir.path,
              '${AppDatabase.guestDatabaseName}.sqlite$ext',
            ),
          ).existsSync(),
          isFalse,
          reason: 'guest DB $ext should be deleted',
        );
      }
      expect(
        File(p.join(dbDir.path, 'keepme.txt')).existsSync(),
        isTrue,
        reason: 'unrelated files must not be touched',
      );
    });

    test('resetLocalLibraryWithBackup returns backupFailed when no DB exists',
        () async {
      final outcome = await resetLocalLibraryWithBackup();
      expect(outcome, RecoveryResetOutcome.backupFailed);
    });

    test(
        'resetLocalLibraryWithBackup returns success when the DB can be backed up',
        () async {
      await File(
        p.join(dbDir.path, '${AppDatabase.guestDatabaseName}.sqlite'),
      ).writeAsString('sqlite-blob');
      final outcome = await resetLocalLibraryWithBackup();
      expect(outcome, RecoveryResetOutcome.success);
      expect(
        File(
          p.join(
            dbDir.path,
            '${AppDatabase.guestDatabaseName}.sqlite',
          ),
        ).existsSync(),
        isFalse,
      );
    });

    test('isUnrecoverableDatabaseError matches the documented patterns', () {
      expect(
        isUnrecoverableDatabaseError(
          const FormatException('SqliteException: file is not a database'),
        ),
        isTrue,
      );
      expect(
        isUnrecoverableDatabaseError(
          const FormatException('unsupported schema version 6'),
        ),
        isTrue,
      );
      expect(
        isUnrecoverableDatabaseError(
          Exception('NoSuchMethodError: bogus'),
        ),
        isFalse,
      );
    });
  });
}
