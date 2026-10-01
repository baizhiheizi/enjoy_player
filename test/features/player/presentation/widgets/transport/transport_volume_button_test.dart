import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_chrome_icon.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_volume_button.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/chrome_icon_finders.dart';
import '../../../../../support/fake_player_engine.dart';

class _SignedInAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(id: 'u1', email: 't@test.com', name: 'Test'),
  );
}

ProviderContainer _containerFor(AppDatabase db, FakePlayerEngine fake) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      deviceGlobalAppDatabaseProvider.overrideWithValue(db),
      authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
      playerEngineTestDoubleProvider.overrideWithValue(fake),
    ],
  );
}

Widget _wrap({required ProviderContainer container, required Widget child}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: child),
    ),
  );
}

Finder _popupCard() => find.byWidgetPredicate(
  (w) => w is SizedBox && w.width == 44 && w.height == 152,
);

Future<void> _hoverVolumeIcon(WidgetTester tester) async {
  final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await hover.addPointer(
    location: tester.getCenter(find.byType(TransportVolumeButton)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  late AppDatabase db;
  late FakePlayerEngine fake;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    fake = FakePlayerEngine();
  });

  tearDown(() async {
    await db.close();
    await fake.dispose();
  });

  testWidgets('TransportVolumeButton renders a volume icon', (tester) async {
    final container = _containerFor(db, fake);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _wrap(container: container, child: const TransportVolumeButton()),
    );
    await tester.pump();

    expect(findChromeIcon(EnjoyChromeGlyph.volume), findsOneWidget);
  });

  testWidgets('TransportVolumeButton shows muted icon when volume is 0', (
    tester,
  ) async {
    final container = _containerFor(db, fake);
    addTearDown(container.dispose);
    await container.read(playerPreferencesCtrlProvider.notifier).setVolume(0);
    await tester.pumpWidget(
      _wrap(container: container, child: const TransportVolumeButton()),
    );
    await tester.pump();

    expect(findChromeIcon(EnjoyChromeGlyph.volumeOff), findsOneWidget);
  });

  testWidgets('tapping volume shows a slider to adjust level', (tester) async {
    final container = _containerFor(db, fake);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _wrap(container: container, child: const TransportVolumeButton()),
    );
    await tester.pump();

    expect(find.byType(Slider), findsNothing);

    await tester.tap(findChromeIcon(EnjoyChromeGlyph.volume));
    await tester.pump();
    await tester.pump();

    expect(find.byType(Slider), findsOneWidget);
    expect(tester.getSize(_popupCard()), const Size(44, 152));

    await tester.tap(findChromeIcon(EnjoyChromeGlyph.volume));
    await tester.pump();
    await tester.pump();

    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('hovering the volume icon shows the popover at popup size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = _containerFor(db, fake);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _wrap(container: container, child: const TransportVolumeButton()),
    );
    await tester.pump();

    await _hoverVolumeIcon(tester);

    expect(find.byType(Slider), findsOneWidget);
    expect(tester.getSize(_popupCard()), const Size(44, 152));
    expect(tester.getSize(find.byType(Slider)), const Size(132, 24));
  });

  testWidgets('hover popover does not swallow taps meant for the app', (
    tester,
  ) async {
    final container = _containerFor(db, fake);
    addTearDown(container.dispose);
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        container: container,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: ElevatedButton(
                onPressed: () => taps++,
                child: const Text('behind'),
              ),
            ),
            const Align(
              alignment: Alignment.bottomRight,
              child: TransportVolumeButton(),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('behind'));
    await tester.pump();
    expect(taps, 1);

    await _hoverVolumeIcon(tester);
    expect(find.byType(Slider), findsOneWidget);

    await tester.tap(find.text('behind'));
    await tester.pump();

    expect(taps, 2);
  });
}
