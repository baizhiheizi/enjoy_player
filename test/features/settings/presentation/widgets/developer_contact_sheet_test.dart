import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:enjoy_player/core/application/app_links.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/about_section_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:enjoy_player/l10n/l10n_delegates.dart';

Widget _harness({required AppDatabase db}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );
  return ProviderScope(
    overrides: [
      deviceGlobalAppDatabaseProvider.overrideWithValue(db),
      appDatabaseProvider.overrideWithValue(db),
    ],
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en', 'US'),
      home: const Scaffold(
        body: SingleChildScrollView(child: AboutSectionCard()),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late List<MethodCall> clipboardCalls;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Enjoy Player',
      packageName: 'com.enjoy.player.test',
      version: '0.3.1',
      buildNumber: '2',
      buildSignature: 'test',
    );
    db = AppDatabase(executor: NativeDatabase.memory());
    clipboardCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          clipboardCalls.add(call);
          return null;
        });
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'tapping the "Contact the developer" row opens a bottom sheet listing '
    'Email, WeChat, and Mixin',
    (tester) async {
      await tester.pumpWidget(_harness(db: db));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(
        const Locale('en', 'US'),
      );

      expect(find.byType(PaddedSheetDragHandle), findsNothing);

      await tester.tap(find.text(l10n.settingsAboutContactTitle));
      await tester.pumpAndSettle();

      expect(find.byType(PaddedSheetDragHandle), findsOneWidget);
      expect(find.text(l10n.settingsAboutContactEmailLabel), findsOneWidget);
      expect(find.text(l10n.settingsAboutContactWeChatLabel), findsOneWidget);
      expect(find.text(l10n.settingsAboutContactMixinLabel), findsOneWidget);
      expect(find.text(kDeveloperContactEmail), findsOneWidget);
      expect(find.text(kDeveloperContactWeChatId), findsOneWidget);
      expect(find.text(kDeveloperContactMixinId), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping the email row inside the sheet copies the address and shows a '
    'success notice',
    (tester) async {
      await tester.pumpWidget(_harness(db: db));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(
        const Locale('en', 'US'),
      );

      await tester.tap(find.text(l10n.settingsAboutContactTitle));
      await tester.pumpAndSettle();

      await tester.tap(find.text(kDeveloperContactEmail));
      await tester.pump();
      await tester.pump();

      final setCalls = clipboardCalls.where(
        (c) => c.method == 'Clipboard.setData',
      );
      expect(setCalls, hasLength(1));
      expect(
        (setCalls.single.arguments as Map)['text'],
        kDeveloperContactEmail,
      );
      expect(find.text(l10n.settingsAboutContactCopiedEmail), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping the WeChat row inside the sheet copies the id and shows a '
    'success notice',
    (tester) async {
      await tester.pumpWidget(_harness(db: db));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(
        const Locale('en', 'US'),
      );

      await tester.tap(find.text(l10n.settingsAboutContactTitle));
      await tester.pumpAndSettle();

      await tester.tap(find.text(kDeveloperContactWeChatId));
      await tester.pump();
      await tester.pump();

      final setCalls = clipboardCalls.where(
        (c) => c.method == 'Clipboard.setData',
      );
      expect(setCalls, hasLength(1));
      expect(
        (setCalls.single.arguments as Map)['text'],
        kDeveloperContactWeChatId,
      );
      expect(find.text(l10n.settingsAboutContactCopiedWeChat), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping the Mixin row inside the sheet copies the id and shows a '
    'success notice',
    (tester) async {
      await tester.pumpWidget(_harness(db: db));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(
        const Locale('en', 'US'),
      );

      await tester.tap(find.text(l10n.settingsAboutContactTitle));
      await tester.pumpAndSettle();

      await tester.tap(find.text(kDeveloperContactMixinId));
      await tester.pump();
      await tester.pump();

      final setCalls = clipboardCalls.where(
        (c) => c.method == 'Clipboard.setData',
      );
      expect(setCalls, hasLength(1));
      expect(
        (setCalls.single.arguments as Map)['text'],
        kDeveloperContactMixinId,
      );
      expect(find.text(l10n.settingsAboutContactCopiedMixin), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
