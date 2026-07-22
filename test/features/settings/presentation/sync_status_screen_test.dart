import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/settings/presentation/sync_status_screen.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class _SignedInAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(id: 'u1', email: 'a@b.com', name: 'Test'),
  );
}

class _SignedOutAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

Widget _harness({required List<Override> overrides}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7B61FF),
    brightness: Brightness.dark,
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: [EnjoyThemeTokens.build(scheme)],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SyncStatusScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncStatusScreen', () {
    testWidgets('shows auth required callout when signed out', (tester) async {
      await tester.pumpWidget(
        _harness(
          overrides: [
            authCtrlProvider.overrideWith(_SignedOutAuthCtrl.new),
            syncQueueSnapshotProvider.overrideWith(
              (ref) => Stream.value(
                const SyncQueueSnapshot(
                  retryablePending: 0,
                  permanentlyFailed: 0,
                  detailRows: [],
                ),
              ),
            ),
            syncLastFullSyncAtProvider.overrideWith((ref) async => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthRequiredCallout), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows sync stats when signed in with empty queue', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          overrides: [
            authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
            syncQueueSnapshotProvider.overrideWith(
              (ref) => Stream.value(
                const SyncQueueSnapshot(
                  retryablePending: 0,
                  permanentlyFailed: 0,
                  detailRows: [],
                ),
              ),
            ),
            syncLastFullSyncAtProvider.overrideWith((ref) async => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));

      // Last sync label shows "never" when null.
      expect(find.text(l10n.syncScreenLastSyncLabel), findsOneWidget);
      expect(find.text(l10n.syncScreenLastSyncNever), findsOneWidget);

      // Queue stats show zeros.
      expect(find.text(l10n.syncScreenStatRetryable), findsOneWidget);
      expect(find.text(l10n.syncScreenStatFailed), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2));

      // Sync now button is present.
      expect(find.text(l10n.syncScreenSyncNow), findsOneWidget);

      // Retry failed button is present but disabled (0 failed).
      expect(find.text(l10n.syncScreenRetryFailed), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows formatted last sync time when available', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          overrides: [
            authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
            syncQueueSnapshotProvider.overrideWith(
              (ref) => Stream.value(
                const SyncQueueSnapshot(
                  retryablePending: 0,
                  permanentlyFailed: 0,
                  detailRows: [],
                ),
              ),
            ),
            syncLastFullSyncAtProvider.overrideWith(
              (ref) async => '2025-01-15T10:30:00.000Z',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));

      // Should NOT show "never" when a timestamp is available.
      expect(find.text(l10n.syncScreenLastSyncNever), findsNothing);
      // The formatted date should contain the year.
      expect(find.textContaining('2025'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows non-zero queue counts with detail rows', (tester) async {
      final detailRows = [
        SyncQueueRow(
          id: 1,
          entityType: 'vocabulary',
          entityId: 'v-123',
          action: 'upsert',
          retryCount: 2,
          error: 'network timeout',
          createdAt: DateTime(2025, 1, 10),
        ),
        SyncQueueRow(
          id: 2,
          entityType: 'recording',
          entityId: 'r-456',
          action: 'delete',
          retryCount: 5,
          error: null,
          createdAt: DateTime(2025, 1, 11),
        ),
      ];

      await tester.pumpWidget(
        _harness(
          overrides: [
            authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
            syncQueueSnapshotProvider.overrideWith(
              (ref) => Stream.value(
                SyncQueueSnapshot(
                  retryablePending: 3,
                  permanentlyFailed: 2,
                  detailRows: detailRows,
                ),
              ),
            ),
            syncLastFullSyncAtProvider.overrideWith((ref) async => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));

      // Non-zero counts displayed.
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Expansion tile for queue details.
      expect(find.text(l10n.syncQueueDetails), findsOneWidget);

      // Expand the tile to see detail rows.
      await tester.tap(find.text(l10n.syncQueueDetails));
      await tester.pumpAndSettle();

      expect(find.textContaining('vocabulary'), findsOneWidget);
      expect(find.textContaining('recording'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows empty queue message when detail rows are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          overrides: [
            authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
            syncQueueSnapshotProvider.overrideWith(
              (ref) => Stream.value(
                const SyncQueueSnapshot(
                  retryablePending: 0,
                  permanentlyFailed: 0,
                  detailRows: [],
                ),
              ),
            ),
            syncLastFullSyncAtProvider.overrideWith((ref) async => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));

      // Expand the details tile.
      await tester.tap(find.text(l10n.syncQueueDetails));
      await tester.pumpAndSettle();

      expect(find.text(l10n.syncQueueEmpty), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('retry failed button is enabled when permanentlyFailed > 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          overrides: [
            authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
            syncQueueSnapshotProvider.overrideWith(
              (ref) => Stream.value(
                const SyncQueueSnapshot(
                  retryablePending: 1,
                  permanentlyFailed: 4,
                  detailRows: [],
                ),
              ),
            ),
            syncLastFullSyncAtProvider.overrideWith((ref) async => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));

      // Retry button should be enabled (find the OutlinedButton).
      final retryButton = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(l10n.syncScreenRetryFailed),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(retryButton.onPressed, isNotNull);

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows error text when snapshot stream errors', (tester) async {
      await tester.pumpWidget(
        _harness(
          overrides: [
            authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
            syncQueueSnapshotProvider.overrideWith(
              (ref) => Stream.error(Exception('db failure')),
            ),
            syncLastFullSyncAtProvider.overrideWith((ref) async => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l10n.errorGenericLoadFailed), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
