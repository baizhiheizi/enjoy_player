import 'dart:async';
import 'dart:io';

import 'package:enjoy_player/core/logging/diagnostic_log_config.dart';
import 'package:enjoy_player/core/logging/log_file_sink.dart';
import 'package:enjoy_player/core/logging/setup_logging.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late String supportPath;
  late String documentsPath;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('setup_logging_test_');
    supportPath = p.join(tempRoot.path, 'support');
    documentsPath = p.join(tempRoot.path, 'documents');
    await Directory(supportPath).create(recursive: true);
    await Directory(documentsPath).create(recursive: true);
    PathProviderPlatform.instance = TestPathProvider(
      documentsPath,
      supportPath: supportPath,
    );
    PackageInfo.setMockInitialValues(
      appName: 'Enjoy Player',
      packageName: 'ai.enjoy.player',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
    LogFileSink.debugResetInstance();
    DiagnosticLogConfig.debugResetSessionLoad();
    await debugResetAppLogging();
  });

  tearDown(() async {
    await debugResetAppLogging();
    DiagnosticLogConfig.debugResetSessionLoad();
    LogFileSink.debugResetInstance();
    await closeAndClearAllAppDatabases().timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
    if (tempRoot.existsSync()) {
      try {
        await tempRoot.delete(recursive: true);
      } on FileSystemException {} // ignore: empty_catches
    }
  });

  File logFile() => File(p.join(supportPath, 'logs', kLogFileBaseName));

  Future<String> readLog() async {
    final file = logFile();
    if (!file.existsSync()) return '';
    return file.readAsString();
  }

  Future<void> untilLogContains(String needle) async {
    for (var i = 0; i < 100; i++) {
      if ((await readLog()).contains(needle)) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  test(
    'session banner is the first log line; early records flush after it',
    () async {
      final documentsGate = Completer<void>();
      PathProviderPlatform.instance = _GatedDocumentsPathProvider(
        documentsPath,
        supportPath: supportPath,
        gate: documentsGate.future,
      );

      await setupAppLogging();

      Logger('early').info('early bootstrap line');
      final banner = debugSessionBannerFuture;
      expect(
        banner,
        isNotNull,
        reason: 'banner write must still be pending when setup returns',
      );

      documentsGate.complete();
      await banner!;
      await untilLogContains('early bootstrap line');

      final content = await readLog();
      final lines = content.split('\n').where((l) => l.isNotEmpty).toList();
      expect(lines, isNotEmpty);
      expect(lines.first, contains('[INFO] session:'));
      expect(lines.first, contains('app=1.2.3+42'));
      expect(lines.first, contains('diagnosticVerbose=false'));
      expect(content, contains('[INFO] early: early bootstrap line'));
      expect(lines.indexWhere((l) => l.contains('session:')), 0);
    },
  );

  test(
    'banner awaits the persisted verbose flag before it is written',
    () async {
      await withDeviceGlobalAppDatabaseForBootstrap((db) async {
        await db.settingsDao.writeSetting(
          SettingsKeys.diagnosticsVerboseEnabled,
          true,
        );
      });

      await setupAppLogging();
      await debugSessionBannerFuture!;

      final lines = (await readLog())
          .split('\n')
          .where((l) => l.isNotEmpty)
          .toList();
      expect(lines.first, contains('diagnosticVerbose=true'));

      Logger('sync').fine('verbose tier line');
      await untilLogContains('verbose tier line');
      expect(await readLog(), contains('[FINE] sync: verbose tier line'));
    },
  );

  test(
    'a failed verbose-flag read still writes the banner and flushes records',
    () async {
      PathProviderPlatform.instance = _DocumentsBrokenPathProvider(
        documentsPath,
        supportPath: supportPath,
      );

      await runZonedGuarded(() async {
        await setupAppLogging();
        Logger('early').info('fail-open line');
        await debugSessionBannerFuture!;
        await untilLogContains('fail-open line');
      }, (error, stackTrace) {});

      final lines = (await readLog())
          .split('\n')
          .where((l) => l.isNotEmpty)
          .toList();
      expect(lines.first, contains('diagnosticVerbose=false'));
      expect(lines.first, contains('[INFO] session:'));
      expect(await readLog(), contains('[INFO] early: fail-open line'));
    },
  );

  test(
    'a record emitted while the banner settles lands after flushed records',
    () async {
      final documentsGate = Completer<void>();
      PathProviderPlatform.instance = _GatedDocumentsPathProvider(
        documentsPath,
        supportPath: supportPath,
        gate: documentsGate.future,
      );

      await setupAppLogging();
      Logger('early').info('buffered before banner');
      final banner = debugSessionBannerFuture!;

      documentsGate.complete();
      await untilLogContains('[INFO] session:');
      Logger('settling').info('emitted while banner settles');
      await banner;
      await untilLogContains('emitted while banner settles');

      final lines = (await readLog())
          .split('\n')
          .where((l) => l.isNotEmpty)
          .toList();
      final bannerIndex = lines.indexWhere((l) => l.contains('session:'));
      final bufferedIndex = lines.indexWhere(
        (l) => l.contains('buffered before banner'),
      );
      final settlingIndex = lines.indexWhere(
        (l) => l.contains('emitted while banner settles'),
      );
      expect(bufferedIndex, greaterThan(bannerIndex));
      expect(settlingIndex, greaterThan(bufferedIndex));
    },
  );

  test(
    'reset while the banner is in flight discards its buffered records',
    () async {
      final documentsGate = Completer<void>();
      PathProviderPlatform.instance = _GatedDocumentsPathProvider(
        documentsPath,
        supportPath: supportPath,
        gate: documentsGate.future,
      );

      await setupAppLogging();
      Logger('stale').info('stale pre-banner record');
      final staleBanner = debugSessionBannerFuture!;

      await debugResetAppLogging();
      documentsGate.complete();
      await staleBanner;
      await untilLogContains('[INFO] session:');

      expect(await readLog(), isNot(contains('stale pre-banner record')));

      await setupAppLogging();
      await debugSessionBannerFuture!;

      final content = await readLog();
      expect(content, contains('[INFO] session:'));
      expect(content, isNot(contains('stale pre-banner record')));
    },
  );

  test('pre-banner buffer drops the oldest records beyond capacity', () async {
    final documentsGate = Completer<void>();
    PathProviderPlatform.instance = _GatedDocumentsPathProvider(
      documentsPath,
      supportPath: supportPath,
      gate: documentsGate.future,
    );

    await setupAppLogging();
    for (var i = 0; i < 300; i++) {
      Logger('burst').info('burst record $i');
    }

    documentsGate.complete();
    await debugSessionBannerFuture!;
    await untilLogContains('burst record 299');

    final content = await readLog();
    expect(content, contains('burst record 299'));
    expect(content, contains('burst record 45'));
    expect(content, isNot(contains('burst record 44')));
    expect(content, isNot(contains('burst record 0')));
    expect('capped at'.allMatches(content), hasLength(1));
    expect(
      content.indexOf('[INFO] session:'),
      lessThan(content.indexOf('burst record 45')),
    );
  });
}

class _DocumentsBrokenPathProvider extends TestPathProvider {
  _DocumentsBrokenPathProvider(super.documentsPath, {super.supportPath});

  @override
  Future<String?> getApplicationDocumentsPath() async {
    throw const FileSystemException('synthetic failure for test');
  }
}

class _GatedDocumentsPathProvider extends TestPathProvider {
  _GatedDocumentsPathProvider(
    super.documentsPath, {
    super.supportPath,
    required this.gate,
  });

  final Future<void> gate;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    await gate;
    return documentsPath;
  }
}
