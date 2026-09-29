import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/player/player_surface_overlay_coordinator.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget host({
    GlobalKey<ScaffoldMessengerState>? messengerKey,
    Widget? child,
    ProviderContainer? container,
  }) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
    final app = MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      scaffoldMessengerKey: messengerKey,
      home: Scaffold(
        body: Builder(
          builder: (context) =>
              child ?? Center(child: Text('host-${context.mounted}')),
        ),
      ),
    );
    if (container == null) return app;
    return UncontrolledProviderScope(container: container, child: app);
  }

  group('AppNotice', () {
    testWidgets('success shows an Aurora toast via global key', (tester) async {
      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(host(messengerKey: messengerKey));

      final ctx = tester.element(find.byType(Scaffold));
      AppNotice.success(ctx, 'hello success');

      await tester.pump();
      await tester.pump();

      expect(find.text('hello success'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(
        snackBar.backgroundColor,
        appNoticeBackground(Theme.of(ctx).brightness),
      );
      expect(find.byIcon(EnjoyIcons.checkCircleFill), findsOneWidget);
    });

    testWidgets('error uses the toast surface and clears existing snackbars', (
      tester,
    ) async {
      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(host(messengerKey: messengerKey));
      final ctx = tester.element(find.byType(Scaffold));

      AppNotice.error(ctx, 'oops');
      await tester.pump();
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(
        snackBar.backgroundColor,
        appNoticeBackground(Theme.of(ctx).brightness),
      );
      expect(find.byIcon(EnjoyIcons.errorFill), findsOneWidget);
      expect(snackBar.showCloseIcon, isNull);
      expect(find.byIcon(EnjoyIcons.close), findsOneWidget);
    });

    testWidgets('info uses the toast surface without close icon', (
      tester,
    ) async {
      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(host(messengerKey: messengerKey));
      final ctx = tester.element(find.byType(Scaffold));

      AppNotice.info(ctx, 'FYI');
      await tester.pump();
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(
        snackBar.backgroundColor,
        appNoticeBackground(Theme.of(ctx).brightness),
      );
      expect(find.byIcon(EnjoyIcons.infoFill), findsOneWidget);
      expect(snackBar.showCloseIcon, isNull);
      expect(find.byIcon(EnjoyIcons.close), findsNothing);
    });

    testWidgets('warning uses the toast surface with close icon', (
      tester,
    ) async {
      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(host(messengerKey: messengerKey));
      final ctx = tester.element(find.byType(Scaffold));

      AppNotice.warning(ctx, 'careful');
      await tester.pump();
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(
        snackBar.backgroundColor,
        appNoticeBackground(Theme.of(ctx).brightness),
      );
      expect(find.byIcon(EnjoyIcons.warning), findsOneWidget);
      expect(snackBar.showCloseIcon, isNull);
      expect(find.byIcon(EnjoyIcons.close), findsOneWidget);
    });

    testWidgets(
      'falls back to ScaffoldMessenger.maybeOf when global key is empty',
      (tester) async {
        await tester.pumpWidget(host());
        final ctx = tester.element(find.byType(Scaffold));

        AppNotice.success(ctx, 'local only');
        await tester.pump();
        await tester.pump();

        expect(find.text('local only'), findsOneWidget);
      },
    );

    testWidgets('no-op when no ScaffoldMessenger is available', (tester) async {
      late BuildContext bareContext;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            bareContext = context;
            return const SizedBox.shrink();
          },
        ),
      );
      AppNotice.success(bareContext, 'should be skipped');
      await tester.pump();
      await tester.pump();
      expect(find.text('should be skipped'), findsNothing);
    });

    testWidgets(
      'success acquires overlay park token and releases when snackbar closes',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final messengerKey = GlobalKey<ScaffoldMessengerState>();
        await tester.pumpWidget(
          host(messengerKey: messengerKey, container: container),
        );

        final ctx = tester.element(find.byType(Scaffold));
        expect(
          container.read(playerSurfaceShouldParkForOverlayProvider),
          isFalse,
        );

        AppNotice.success(ctx, 'parked notice');
        await tester.pump();
        await tester.pump();

        expect(find.text('parked notice'), findsOneWidget);
        expect(
          container.read(playerSurfaceShouldParkForOverlayProvider),
          isTrue,
        );

        messengerKey.currentState!.hideCurrentSnackBar();
        await tester.pumpAndSettle();

        expect(find.text('parked notice'), findsNothing);
        expect(
          container.read(playerSurfaceShouldParkForOverlayProvider),
          isFalse,
        );
      },
    );

    testWidgets('clamps leaked bottom padding to the view inset', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(392.7 * 3, 850.9 * 3);
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(
        left: 0,
        top: 72,
        right: 0,
        bottom: 102,
      );
      tester.view.viewPadding = const FakeViewPadding(
        left: 0,
        top: 72,
        right: 0,
        bottom: 102,
      );
      addTearDown(tester.view.reset);

      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: scheme,
            extensions: [EnjoyThemeTokens.build(scheme)],
          ),
          scaffoldMessengerKey: messengerKey,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(392.7, 850.9),
              padding: EdgeInsets.only(bottom: 850.9),
              viewPadding: EdgeInsets.only(bottom: 34),
            ),
            child: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: TextButton(
                    onPressed: () => AppNotice.success(context, 'clamped'),
                    child: const Text('show'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.margin, const EdgeInsets.fromLTRB(16, 0, 16, 50));
      final box = tester.renderObject<RenderBox>(find.byType(SnackBar));
      expect(box.size.height, lessThan(200));
      expect(tester.takeException(), isNull);
    });

    testWidgets('action notice keeps the message at full inner width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 3, 851 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(host(messengerKey: messengerKey));
      final ctx = tester.element(find.byType(Scaffold));

      const message =
          'AI credits limit reached. Upgrade to Pro or buy a credits '
          'package to continue.';
      var tapped = 0;
      AppNotice.error(
        ctx,
        message,
        action: (label: 'View plans & packages', onPressed: () => tapped++),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final barWidth = tester
          .getSize(
            find
                .descendant(
                  of: find.byType(SnackBar),
                  matching: find.byType(Material),
                )
                .first,
          )
          .width;
      final textWidth = tester.getSize(find.text(message)).width;
      expect(textWidth, greaterThan(barWidth * 0.75));
      expect(tester.widget<SnackBar>(find.byType(SnackBar)).persist, isTrue);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('View plans & packages'));
      expect(tapped, 1);
      await tester.pumpAndSettle();
      expect(find.text(message), findsNothing);
    });

    testWidgets('body close button dismisses a notice without an action', (
      tester,
    ) async {
      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(host(messengerKey: messengerKey));
      final ctx = tester.element(find.byType(Scaffold));

      AppNotice.warning(ctx, 'careful');
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(EnjoyIcons.close));
      await tester.pumpAndSettle();

      expect(find.text('careful'), findsNothing);
    });

    testWidgets('dismiss-only notice keeps the single-line height', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 3, 851 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(host(messengerKey: messengerKey));
      final ctx = tester.element(find.byType(Scaffold));

      AppNotice.error(ctx, 'one line');
      await tester.pump();
      await tester.pumpAndSettle();

      final bar = tester.renderObject<RenderBox>(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(bar.size.height, lessThan(60));
      expect(tester.takeException(), isNull);
    });

    testWidgets('long action label ellipsizes instead of wrapping', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(host(messengerKey: messengerKey));
      final ctx = tester.element(find.byType(Scaffold));

      const label =
          'View plans & packages and manage your subscription settings';
      AppNotice.error(
        ctx,
        'limit reached',
        action: (label: label, onPressed: () {}),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.getSize(find.text(label)).height, lessThan(24));
      expect(tester.takeException(), isNull);
    });
  });
}
