import 'package:drift/native.dart';
import 'package:enjoy_player/core/network/proxy/proxy_config.dart';
import 'package:enjoy_player/core/network/proxy/proxy_http_overrides.dart';
import 'package:enjoy_player/core/network/proxy/proxy_providers.dart';
import 'package:enjoy_player/core/network/proxy/resolved_proxy.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/network_section.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SystemProxyCoordinator coordinator;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    coordinator = SystemProxyCoordinator(
      reader: () async => const ResolvedProxy(
        http: ProxyEndpoint('127.0.0.1', 7890),
        source: 'scutil',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
    final container = ProviderContainer(
      overrides: [
        deviceGlobalAppDatabaseProvider.overrideWithValue(db),
        systemProxyCoordinatorProvider.overrideWithValue(coordinator),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: scheme,
            extensions: [EnjoyThemeTokens.build(scheme)],
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: SingleChildScrollView(child: NetworkSectionBody()),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => container.read(networkProxySettingsProvider.future),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the resolved system proxy as the effective proxy', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('127.0.0.1:7890 (scutil)'), findsOneWidget);
    expect(find.text('Proxy address'), findsNothing);
  });

  testWidgets('manual mode validates then persists the address', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();
    expect(find.text('Proxy address'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'socks5://h:1');
    await tester.tap(find.text('Save proxy'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('SOCKS proxies are not supported'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '10.1.1.1:3128');
    await tester.tap(find.text('Save proxy'));
    await settle(tester);

    final mode = await tester.runAsync(
      () => db.settingsDao.readSetting(SettingsKeys.networkProxyMode),
    );
    final url = await tester.runAsync(
      () => db.settingsDao.readSetting(SettingsKeys.networkProxyUrl),
    );
    expect(mode, 'manual');
    expect(url, '10.1.1.1:3128');
    expect(coordinator.config.mode, ProxyMode.manual);
    expect(find.text('10.1.1.1:3128 (manual)'), findsOneWidget);
  });

  testWidgets('direct mode persists and shows direct', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Direct'));
    await settle(tester);
    expect(find.text('Direct (no proxy)'), findsWidgets);
    final mode = await tester.runAsync(
      () => db.settingsDao.readSetting(SettingsKeys.networkProxyMode),
    );
    expect(mode, 'direct');
  });

  testWidgets(
    'switching between manual, direct, and manual preserves settings',
    (tester) async {
      await pump(tester);
      await tester.tap(find.text('Manual'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '10.1.1.1:3128');
      await tester.tap(find.text('Save proxy'));
      await settle(tester);
      expect(coordinator.config.mode, ProxyMode.manual);

      await tester.tap(find.text('Direct'));
      await settle(tester);
      final directMode = await tester.runAsync(
        () => db.settingsDao.readSetting(SettingsKeys.networkProxyMode),
      );
      expect(directMode, 'direct');
      expect(coordinator.config.mode, ProxyMode.direct);

      await tester.tap(find.text('Manual'));
      await settle(tester);
      final manualMode = await tester.runAsync(
        () => db.settingsDao.readSetting(SettingsKeys.networkProxyMode),
      );
      expect(manualMode, 'manual');
      expect(coordinator.config.mode, ProxyMode.manual);
      expect(find.text('10.1.1.1:3128 (manual)'), findsOneWidget);
    },
  );
}
