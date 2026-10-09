import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/lookup/application/lookup_credits_exhausted_provider.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/dictionary_lookup_sheet.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class _AuthSignedOutCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

class _SeededLookupCredits extends LookupCreditsExhausted {
  @override
  Map<LookupSectionId, String> build() => const {
    LookupSectionId.translation: 'AI credits are exhausted for today.',
  };
}

Widget _harness({required List<Override> overrides, required Widget child}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  const request = LookupRequest(
    selectedText: 'hello world',
    sourceLanguage: 'en-US',
    targetLanguage: 'zh-CN',
  );

  List<Override> baseOverrides() => [
    authCtrlProvider.overrideWith(_AuthSignedOutCtrl.new),
    appDatabaseProvider.overrideWithValue(db),
  ];

  group('DictionaryLookupSheet (bottomSheet)', () {
    testWidgets('renders selected text, title, and language picker', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _harness(
          overrides: baseOverrides(),
          child: const SizedBox(
            height: 600,
            child: DictionaryLookupSheet(request: request),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('hello world'), findsOneWidget);

      expect(find.text('Look up'), findsOneWidget);

      expect(find.text('English'), findsOneWidget);
      expect(find.text('中文'), findsOneWidget);

      expect(find.byIcon(EnjoyIcons.close), findsOneWidget);

      expect(find.byIcon(EnjoyIcons.copy), findsOneWidget);
    });

    testWidgets('close button pops the navigator', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var popped = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: baseOverrides(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    unawaited(
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => const Scaffold(
                                body: SizedBox(
                                  height: 600,
                                  child: DictionaryLookupSheet(
                                    request: request,
                                    key: Key('sheet'),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .then((_) => popped = true),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sheet')), findsOneWidget);

      await tester.tap(find.byIcon(EnjoyIcons.close));
      await tester.pumpAndSettle();
      expect(popped, isTrue);
    });

    testWidgets('header row orders pronounce → copy → close by x', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _harness(
          overrides: baseOverrides(),
          child: const SizedBox(
            height: 600,
            child: DictionaryLookupSheet(request: request),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pronounceX = tester.getCenter(find.byIcon(EnjoyIcons.volume)).dx;
      final copyX = tester.getCenter(find.byIcon(EnjoyIcons.copy)).dx;
      final closeX = tester.getCenter(find.byIcon(EnjoyIcons.close)).dx;

      expect(pronounceX, lessThan(copyX));
      expect(copyX, lessThan(closeX));
    });

    testWidgets('swap button swaps source and target languages', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _harness(
          overrides: baseOverrides(),
          child: const SizedBox(
            height: 600,
            child: DictionaryLookupSheet(request: request),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('中文'), findsOneWidget);

      await tester.tap(find.byIcon(EnjoyIcons.swap));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('中文'), findsOneWidget);
    });

    testWidgets('shows one credits banner with a single plans CTA', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _harness(
          overrides: [
            ...baseOverrides(),
            lookupCreditsExhaustedProvider.overrideWith(
              _SeededLookupCredits.new,
            ),
          ],
          child: const SizedBox(
            height: 600,
            child: DictionaryLookupSheet(request: request),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI credits are exhausted for today.'), findsOneWidget);
      expect(
        find.text(
          lookupAppLocalizations(
            const Locale('en'),
          ).subscriptionViewPlansAndPackages,
        ),
        findsOneWidget,
      );
    });
  });

  group('DictionaryLookupSheet (dialog)', () {
    testWidgets('renders in dialog presentation without drag handle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          overrides: baseOverrides(),
          child: const SizedBox(
            height: 600,
            child: DictionaryLookupSheet(
              request: request,
              presentation: DictionaryLookupPresentation.dialog,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('hello world'), findsOneWidget);

      expect(find.text('Look up'), findsOneWidget);

      expect(find.byType(DraggableScrollableSheet), findsNothing);
    });
  });
}
