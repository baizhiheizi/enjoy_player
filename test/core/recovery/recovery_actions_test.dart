import 'dart:io';

import 'package:enjoy_player/core/recovery/recovery_actions.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _MockPathProvider extends PathProviderPlatform {
  _MockPathProvider({required this.supportRoot, required this.docsRoot});
  final Directory supportRoot;
  final Directory docsRoot;

  @override
  Future<String?> getApplicationSupportPath() async => supportRoot.path;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsRoot.path;

  @override
  Future<String?> getTemporaryPath() async => supportRoot.path;
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
      dbDir = Directory(p.join(tmpRoot.path, 'documents'));
      logsDir = Directory(p.join(tmpRoot.path, 'support', 'logs'));
      await dbDir.create(recursive: true);
      await logsDir.create(recursive: true);
      PathProviderPlatform.instance = _MockPathProvider(
        supportRoot: Directory(p.join(tmpRoot.path, 'support')),
        docsRoot: dbDir,
      );
      clipboardCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
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
      final setCalls = clipboardCalls.where(
        (c) => c.method == 'Clipboard.setData',
      );
      expect(setCalls, hasLength(1));
      final args = (setCalls.single.arguments as Map)['text'] as String;
      expect(args, contains('boom'));
      expect(args, contains('Stack trace'));
    });

    test('copyErrorToClipboard returns false on a platform failure', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            throw PlatformException(code: 'fail');
          });
      final ok = await copyErrorToClipboard(Exception('boom'), null);
      expect(ok, isFalse);
    });

    test(
      'backupLocalDatabaseFile copies the device-global DB and returns its path',
      () async {
        final dbFile = File(
          p.join(dbDir.path, '${AppDatabase.deviceGlobalDatabaseName}.sqlite'),
        );
        await dbFile.writeAsString('sqlite-blob');
        final backup = await backupLocalDatabaseFile();
        expect(backup, isNotNull);
        expect(File(backup!).existsSync(), isTrue);
        expect(p.basename(backup), startsWith('enjoy_player_'));
        expect(p.basename(backup), endsWith('.sqlite'));
      },
    );

    test(
      'backupLocalDatabaseFile returns null when the DB is missing',
      () async {
        final backup = await backupLocalDatabaseFile();
        expect(backup, isNull);
      },
    );

    test(
      'wipeLocalDatabaseFiles removes the device-global + wal + shm files',
      () async {
        for (final ext in <String>['', '-wal', '-shm']) {
          await File(
            p.join(
              dbDir.path,
              '${AppDatabase.deviceGlobalDatabaseName}.sqlite$ext',
            ),
          ).writeAsString('x');
        }
        await File(p.join(dbDir.path, 'keepme.txt')).writeAsString('keep');

        await wipeLocalDatabaseFiles();

        for (final ext in <String>['', '-wal', '-shm']) {
          expect(
            File(
              p.join(
                dbDir.path,
                '${AppDatabase.deviceGlobalDatabaseName}.sqlite$ext',
              ),
            ).existsSync(),
            isFalse,
            reason: 'device-global DB $ext should be deleted',
          );
        }
        expect(
          File(p.join(dbDir.path, 'keepme.txt')).existsSync(),
          isTrue,
          reason: 'unrelated files must not be touched',
        );
      },
    );

    test(
      'wipeLocalDatabaseFiles also removes per-user session DB files',
      () async {
        final perUserFile = File(
          p.join(
            dbDir.path,
            '${AppDatabase.deviceGlobalDatabaseName}_abc123.sqlite',
          ),
        );
        await perUserFile.writeAsString('x');

        await wipeLocalDatabaseFiles();

        expect(perUserFile.existsSync(), isFalse);
      },
    );

    test(
      'resetLocalLibraryWithBackup returns backupFailed when no DB exists',
      () async {
        final outcome = await resetLocalLibraryWithBackup();
        expect(outcome, RecoveryResetOutcome.backupFailed);
      },
    );

    test(
      'resetLocalLibraryWithBackup returns success when the DB can be backed up',
      () async {
        await File(
          p.join(dbDir.path, '${AppDatabase.deviceGlobalDatabaseName}.sqlite'),
        ).writeAsString('sqlite-blob');
        final outcome = await resetLocalLibraryWithBackup();
        expect(outcome, RecoveryResetOutcome.success);
        expect(
          File(
            p.join(
              dbDir.path,
              '${AppDatabase.deviceGlobalDatabaseName}.sqlite',
            ),
          ).existsSync(),
          isFalse,
        );
      },
    );

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
        isUnrecoverableDatabaseError(Exception('NoSuchMethodError: bogus')),
        isFalse,
      );
    });

    test(
      'isUnrecoverableDatabaseError matches a real SqliteException.toString()',
      () {
        expect(
          isUnrecoverableDatabaseError(
            Exception(
              'SqliteException(1): while executing, duplicate column '
              'name: duration_seconds, SQL logic error (code 1)',
            ),
          ),
          isTrue,
        );
      },
    );

    test(
      'isUnrecoverableDatabaseError matches stale-schema and disk-corruption '
      'phrasings',
      () {
        expect(
          isUnrecoverableDatabaseError(Exception('no such column: foo')),
          isTrue,
        );
        expect(
          isUnrecoverableDatabaseError(
            Exception('database disk image is malformed'),
          ),
          isTrue,
        );
      },
    );
  });
}
